{ lib, stdenv, fetchFromGitHub, postgresql, buildPgrxExtension }:

buildPgrxExtension rec {
  pname = "pg_graphql";
  version = "unstable-2023-08-01";
  inherit postgresql;

  src = fetchFromGitHub {
    owner  = "supabase";
    repo   = pname;
    rev    = "4ac0ca1c0c94f4a9ceccb4ffe81a6dedcd4c3686";
    hash   = "sha256-bAsb3/CFjWw9xUhKJD5/S/VBiSnFL6A8H0z5c4eB6GQ=";
  };

  cargoHash = "sha256-DOTujO3KH7AawB7qwHvWg6OeWTzWj3FxbRUQfapEJf4=";

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
