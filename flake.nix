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
          "pgtap"
          "pgaudit"
        ];

        makePostgres = version:
          pkgs."postgresql_${version}".withPackages (ps:
            map (ext: ps."${ext}") psqlExtensions
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
            coreutils
          ];
        };
      }
    );
}
