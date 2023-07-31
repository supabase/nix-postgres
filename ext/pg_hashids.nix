{ lib, stdenv, fetchFromGitHub, postgresql }:

stdenv.mkDerivation rec {
  pname = "pg_hashids";
  version = "unstable-2020-05-14";

  buildInputs = [ postgresql ];

  src = fetchFromGitHub {
    owner  = "iCyberon";
    repo   = pname;
    rev    = "83398bcbb616aac2970f5e77d93a3200f0f28e74";
    hash   = "sha256-ykX+UGLCD0wYp6kJjQugFzKkyJzfO9jO1Yr1fTqS0HI=";
  };

  installPhase = ''
    mkdir -p $out/{lib,share/postgresql/extension}

    cp *.so      $out/lib
    cp *.sql     $out/share/postgresql/extension
    cp *.control $out/share/postgresql/extension
  '';

  meta = with lib; {
    description = "Generate short unique IDs in PostgreSQL";
    homepage    = "https://github.com/iCyberon/pg_hashids";
    maintainers = with maintainers; [ thoughtpolice ];
    platforms   = postgresql.meta.platforms;
    license     = licenses.postgresql;
  };
}
