{ lib, curl, lz4, zstd, krb5, icu, stdenv, fetchFromGitHub, postgresql }:

stdenv.mkDerivation rec {
  pname = "citus";
  version = "12.0.0";

  buildInputs = [ curl lz4 zstd krb5 icu.dev postgresql];

  src = fetchFromGitHub {
    owner  = "citusdata";
    repo   = pname;
    rev    = "refs/tags/v${version}";
    hash   = "sha256-HH9/slsCRe2yIVIqwR8sDyqXFonf8BHhJhLzHNv1CF0=";
  };

  installPhase = ''
    mkdir -p $out/{lib,share/postgresql/extension}

    cp *.so      $out/lib
    cp *.sql     $out/share/postgresql/extension
    cp *.control $out/share/postgresql/extension
  '';

  meta = with lib; {
    description = "Distributed PostgreSQL as an extension";
    homepage    = "https://github.com/citusdata/${pname}";
    maintainers = with maintainers; [ olirice ];
    platforms   = postgresql.meta.platforms;
    license     = licenses.agpl3Plus;
  };
}
