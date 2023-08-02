{
  description = "Prototype tooling for deploying PostgreSQL";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let ourSystems = with flake-utils.lib; [
      system.x86_64-linux
      system.aarch64-linux
    ]; in flake-utils.lib.eachSystem ourSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (import ./overlays/cargo-pgrx.nix)
          ];
        };

        # FIXME (aseipp): pg_prove is yet another perl program that needs
        # LOCALE_ARCHIVE set in non-NixOS environments. upstream this.
        pg_prove = pkgs.runCommand "pg_prove" {
          nativeBuildInputs = [ pkgs.makeWrapper ];
        } ''
          mkdir -p $out/bin
          for x in pg_prove pg_tapgen; do
            makeWrapper "${pkgs.perlPackages.TAPParserSourceHandlerpgTAP}/bin/$x" "$out/bin/$x" \
              --set LOCALE_ARCHIVE "${pkgs.glibcLocales}/lib/locale/locale-archive"
          done
        '';

        psqlExtensions = [
          "postgis"
          "pgrouting"
          "pgtap"
          "pg_cron"
          "pgaudit"
          "pgjwt"
          "plpgsql_check"
          "pg_safeupdate"
          "timescaledb"
          "wal2json"
          /* pljava */
          /* plv8 -- FIXME (aseipp): nixos/nixpkgs#246702 */
          "rum"
          "pgvector"
          "pg_repack"
          "pgroonga"
        ];

        ourExtensions = [
          ./ext/pgsql-http.nix
          ./ext/pg_plan_filter.nix
          ./ext/pg_net.nix
          ./ext/pg_hashids.nix
          ./ext/pgsodium.nix
          ./ext/pg_graphql.nix
          ./ext/pg_stat_monitor.nix
          ./ext/pg_jsonschema.nix
          ./ext/vault.nix
          ./ext/hypopg.nix
          ./ext/pg_tle.nix
          ./ext/wrappers/default.nix
        ];

        makePostgresPkgs = version:
          let postgresql = pkgs."postgresql_${version}";
          in map (path: pkgs.callPackage path { inherit postgresql; }) ourExtensions;
        
        makePostgresPkgsSet = version:
          (builtins.listToAttrs (map (drv:
            { name = drv.pname; value = drv; }
          ) (makePostgresPkgs version)))
          // { recurseForDerivations = true; };

        makePostgresBin = version:
          let postgresql = pkgs."postgresql_${version}";
          in postgresql.withPackages (ps:
            (map (ext: ps."${ext}") psqlExtensions) ++ (makePostgresPkgs version)
          );

        makePostgresDocker = version: binPackage:
          pkgs.dockerTools.buildLayeredImage {
            name = "postgresql-${version}";
            tag = "latest";
            contents = with pkgs; [ coreutils bash binPackage ];

            config = {
              Cmd = [ "/bin/postgres" ];
              ExposedPorts = { "5432/tcp" = {}; };
              WorkingDir = "/data";
              Volumes = { "/data" = { }; };
            };
          };

        makePostgres = version: (rec {
          bin = makePostgresBin version;
          exts = makePostgresPkgsSet version;
          docker = makePostgresDocker version bin;
          recurseForDerivations = true;
        });

        basePackages = {
          psql_14 = makePostgres "14";
          psql_15 = makePostgres "15";
        };

        makeCheckHarness = pgpkg:
          let
            sqlTests = ./tests/smoke;
          in pkgs.runCommand "postgres-${pgpkg.version}-check-harness" {
            nativeBuildInputs = [ pgpkg pg_prove pkgs.procps ];
          } ''
            export PGDATA=/tmp/pgdata
            mkdir -p $PGDATA
            initdb --locale=C
            postgres -k /tmp >logfile 2>&1 &
            sleep 2

            createdb -h localhost testing

            psql -h localhost -d testing -Xaf ${./tests/prime.sql}
            pg_prove -h localhost -d testing ${sqlTests}/*.sql

            pkill postgres
            mv logfile $out
          '';

      in rec {
        packages = flake-utils.lib.flattenTree basePackages // {
          inherit (pkgs) cargo-pgrx_0_9_7;
        };

        checks = {
          psql_14 = makeCheckHarness basePackages.psql_14.bin;
          psql_15 = makeCheckHarness basePackages.psql_15.bin;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            coreutils just nix-update
            pg_prove
          ];
        };
      }
    );
}
