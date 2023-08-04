{
  description = "Prototype tooling for deploying PostgreSQL";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: let
    gitRev = "vcs=${self.shortRev or "dirty"}+${builtins.substring 0 8 (self.lastModifiedDate or self.lastModified or "19700101")}";

    ourSystems = with flake-utils.lib; [
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
          "plv8"
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
          ./ext/supautils.nix
        ];

        makeReceipt = pgbin: upstreamExts: ourExts: pkgs.writeTextFile {
          name = "receipt";
          destination = "/receipt.json";
          text = builtins.toJSON {
            revision = gitRev;
            psql-version = pgbin.version;
            nixpkgs = {
              revision = nixpkgs.rev;
              extensions = upstreamExts;
            };
            extensions = ourExts;
          };
        };

        makePostgresPkgs = version:
          let postgresql = pkgs."postgresql_${version}";
          in map (path: pkgs.callPackage path { inherit postgresql; }) ourExtensions;

        makePostgresPkgsSet = version:
          (builtins.listToAttrs (map (drv:
            { name = drv.pname; value = drv; }
          ) (makePostgresPkgs version)))
          // { recurseForDerivations = true; };

        makePostgresBin = version:
          let
            postgresql = pkgs."postgresql_${version}";
            upstreamExts = map (ext: {
              name = postgresql.pkgs."${ext}".pname;
              version = postgresql.pkgs."${ext}".version;
            }) psqlExtensions;
            ourExts = map (ext: { name = ext.pname; version = ext.version; }) (makePostgresPkgs version);

            pgbin = postgresql.withPackages (ps:
              (map (ext: ps."${ext}") psqlExtensions) ++ (makePostgresPkgs version)
            );
          in pkgs.symlinkJoin {
            inherit (pgbin) name version;
            paths = [ pgbin (makeReceipt pgbin upstreamExts ourExts) ];
          };

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
          
          start-server = pkgs.runCommand "start-postgres-server" {} ''
            mkdir -p $out/bin
            substitute ${./tools/run-server.sh} $out/bin/start-postgres-server \
              --replace 'PSQL14=' 'PSQL14=${basePackages.psql_14.bin} #' \
              --replace 'PSQL15=' 'PSQL15=${basePackages.psql_15.bin} #'
            chmod +x $out/bin/start-postgres-server
          '';

          start-client = pkgs.runCommand "start-postgres-client" {} ''
            mkdir -p $out/bin
            substitute ${./tools/run-client.sh} $out/bin/start-postgres-client \
              --replace 'PSQL14=' 'PSQL14=${basePackages.psql_14.bin} #'
            chmod +x $out/bin/start-postgres-client
          '';
        };

        makeCheckHarness = pgpkg:
          let
            sqlTests = ./tests/smoke;
          in pkgs.runCommand "postgres-${pgpkg.version}-check-harness" {
            nativeBuildInputs = with pkgs; [ coreutils bash pgpkg pg_prove procps ];
          } ''
            export PGDATA=/tmp/pgdata
            mkdir -p $PGDATA
            initdb --locale=C

            substitute ${./tests/postgresql.conf} $PGDATA/postgresql.conf \
              --subst-var-by PGSODIUM_GETKEY_SCRIPT "${./tests/util/pgsodium_getkey.sh}"

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

        apps = {
          start-server = {
            type = "app";
            program = "${basePackages.start-server}/bin/start-postgres-server";
          };

          start-client = {
            type = "app";
            program = "${basePackages.start-client}/bin/start-postgres-client";
          };
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            coreutils just nix-update
            pg_prove shellcheck

            basePackages.start-server
            basePackages.start-client
          ];
        };
      }
    );
}
