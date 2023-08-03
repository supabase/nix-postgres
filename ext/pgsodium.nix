{ lib, stdenv, fetchFromGitHub, libsodium, postgresql }:

stdenv.mkDerivation rec {
  pname = "pgsodium";
  version = "3.1.8";

  buildInputs = [ libsodium postgresql ];

  src = fetchFromGitHub {
    owner  = "michelp";
    repo   = pname;
    rev    = "refs/tags/v${version}";
    hash   = "sha256-kD7K5la7DNBe+JI1C/5E3AJdl0lRcWbxFizQqvToPnc=";
  };

  installPhase = ''
    mkdir -p $out/{lib,share/postgresql/extension}

    cp *.so      $out/lib
    cp sql/*.sql $out/share/postgresql/extension
    cp *.control $out/share/postgresql/extension
  '';

  meta = with lib; {
    description = "Modern cryptography for PostgreSQL";
    homepage    = "https://github.com/michelp/${pname}";
    maintainers = with maintainers; [ thoughtpolice ];
    platforms   = postgresql.meta.platforms;
    license     = licenses.postgresql;
  };
}
