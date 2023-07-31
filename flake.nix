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
          /* pgsql-http */
          "plpgsql_check"
          "pg_safeupdate"
          "wal2json"
          /* pl/java */
          "plv8"
          /* pg_plan_filter */
          /* pg_net */
          "rum"
          /* pgsodium */
          /* pg_stat_monitor */
          "pgvector"
          "pg_repack"
        ];

        ourExtensions = [
          ./ext/pg_hashids.nix
        ];

        makePostgres = version:
          let postgresql = pkgs."postgresql_${version}";
          in postgresql.withPackages (ps:
            (map (ext: ps."${ext}") psqlExtensions) ++
            (map (path: pkgs.callPackage path { inherit postgresql; }) ourExtensions)
          );

      in {
        packages = {
          # PostgreSQL 14 + extensions
          psql_14 = makePostgres "14";

          # PostgreSQL 15 + extensions
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
