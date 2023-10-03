{ lib, stdenv, fetchFromGitHub, postgresql, buildPgrxExtension }:

buildPgrxExtension rec {
  pname = "pg_jsonschema";
  version = "unstable-0.2.0";
  inherit postgresql;

  src = fetchFromGitHub {
    owner  = "supabase";
    repo   = pname;
    rev    = "v0.2.0";
    hash   = "sha256-57gZbUVi8P4EB8T0P19JBVXcetQcr6IxuIx96NNFA/0=";
  };

  cargoHash = "sha256-GXzoAOwDwGbHNWOJvaGdOvkU8L/ei703590ClkrDN+Y=";

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
