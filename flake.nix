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

      in {
        packages = {

          # PostgreSQL 14 + extensions
          psql_14 = pkgs.postgresql_14.withPackages (ps:
            map (ext: ps."${ext}") psqlExtensions
          );

          # PostgreSQL 15 + extensions
          psql_15 = pkgs.postgresql_15.withPackages (ps:
            map (ext: ps."${ext}") psqlExtensions
          );

        };
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            coreutils
          ];
        };
      }
    );
}
