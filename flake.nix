{
  description = "Prototype tooling for deploying PostgreSQL";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

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
          /* pg_graphql */
          ./ext/pg_stat_monitor.nix
          /* pg_jsonschema */
          ./ext/vault.nix
          ./ext/hypopg.nix
          /* pg_tle */
        ];

        makePostgresBin = version:
          let postgresql = pkgs."postgresql_${version}";
          in postgresql.withPackages (ps:
            (map (ext: ps."${ext}") psqlExtensions) ++
            (map (path: pkgs.callPackage path { inherit postgresql; }) ourExtensions)
          );

        makePostgresDocker = version: binPackage:
          pkgs.dockerTools.buildImage {
            name = "postgresql-${version}";
            tag = "latest";
            copyToRoot = pkgs.buildEnv {
              name = "postgresql-${version}-env";
              paths = with pkgs; [ coreutils bash binPackage ];
              pathsToLink = [ "/bin" ];
            };

            runAsRoot = ''
              #!${pkgs.runtimeShell}
              mkdir -p /data
            '';
          
            config = {
              Cmd = [ "/bin/postgres" ];
              ExposedPorts = { "5432/tcp" = {}; };
              WorkingDir = "/data";
              Volumes = { "/data" = { }; };
            };
          
            diskSize = 1024;
            buildVMMemorySize = 1024;
          };

        makePostgres = version: (rec {
          bin = makePostgresBin version;
          docker = makePostgresDocker version bin;
          recurseForDerivations = true;
        });

      in {
        packages = flake-utils.lib.flattenTree {
          psql_14 = makePostgres "14";
          psql_15 = makePostgres "15";
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            coreutils just
          ];
        };
      }
    );
}
