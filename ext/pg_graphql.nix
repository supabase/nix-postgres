{ lib, stdenv, fetchFromGitHub, postgresql, buildPgrxExtension }:

buildPgrxExtension rec {
  pname = "pg_graphql";
  version = "unstable-1.4.0";
  inherit postgresql;

  src = fetchFromGitHub {
    owner  = "supabase";
    repo   = pname;
    rev    = "v1.4.0";
    hash   = "sha256-vpMNN7xKCFCqCsMHNOpWbeNYfUCREszBLSxPl3iBFLM=";
  };

  cargoHash = "sha256-jB5cV6r4sf3TBlR9Zsrb7hZp25fIc0DcKvIetYut2ZU=";

  # FIXME (aseipp): disable the tests since they try to install .control
  # files into the wrong spot, aside from that the one main test seems
  # to work, though
  doCheck = false;

  meta = with lib; {
    description = "GraphQL support for PostreSQL";
    homepage    = "https://github.com/supabase/${pname}";
    maintainers = with maintainers; [ thoughtpolice ];
    platforms   = postgresql.meta.platforms;
    license     = licenses.postgresql;
  };
}
