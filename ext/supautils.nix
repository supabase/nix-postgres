{ lib, stdenv, fetchFromGitHub, postgresql }:

stdenv.mkDerivation rec {
  pname = "supautils";
  version = "1.7.3";

  buildInputs = [ postgresql ];

  src = fetchFromGitHub {
    owner  = "supabase";
    repo   = pname;
    rev    = "refs/tags/v${version}";
    hash   = "sha256-bkuqF83XRIOl7CuKOh16G7QekPSmt1EdoG0c1W0xFKY=";
  };

  installPhase = ''
    mkdir -p $out/lib

    install -D supautils.so -t $out/lib
  '';

  meta = with lib; {
    description = "PostgreSQL extension for enhanced security";
    homepage    = "https://github.com/supabase/${pname}";
    maintainers = with maintainers; [ steve-chavez ];
    platforms   = postgresql.meta.platforms;
    license     = licenses.postgresql;
  };
}
