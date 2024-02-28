{ lib, stdenv, fetchFromGitHub, postgresql, buildPgrxExtension }:

buildPgrxExtension rec {
  pname = "pg_jsonschema";
  version = "unstable-e8c331f106a7970eaa406b844c83c259ff2f0e84";
  inherit postgresql;

  src = fetchFromGitHub {
    owner  = "supabase";
    repo   = pname;
    rev    = "e8c331f106a7970eaa406b844c83c259ff2f0e84";
    hash   = "sha256-Z88cKMhkCkLKaeP5oFMJNxojIPfrOyPTBfCM0TKOi0E=";
  };

  cargoHash = "sha256-i05gkqyBIH+xkAognSKouyA08B2kKZ/W94t5QgG/BHA=";

  # FIXME (aseipp): testsuite tries to write files into /nix/store; we'll have
  # to fix this a bit later.
  doCheck = false;

  meta = with lib; {
    description = "JSON Schema Validation for PostgreSQL";
    homepage    = "https://github.com/supabase/${pname}";
    maintainers = with maintainers; [ thoughtpolice ];
    platforms   = postgresql.meta.platforms;
    license     = licenses.postgresql;
  };
}
