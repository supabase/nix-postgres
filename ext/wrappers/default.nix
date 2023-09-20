{ lib, stdenv, fetchFromGitHub, openssl, pkg-config
, postgresql, buildPgrxExtension_0_9_8
}:

buildPgrxExtension_0_9_8 rec {
  pname = "supabase-wrappers";
  version = "unstable-2023-09-20";
  inherit postgresql;

  src = fetchFromGitHub {
    owner  = "supabase";
    repo   = "wrappers";
    rev    = "b749a4928ab8b85afdce45eb005596a90c7ef0ed";
    hash   = "sha256-53QOv6q5dw3X53InMiJxd5GcQl9J2y8u1aGMtiIdN1Q=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  # Needed to get openssl-sys to use pkg-config.
  OPENSSL_NO_VENDOR = 1;

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "clickhouse-rs-1.0.0-alpha.1" = "sha256-0zmoUo/GLyCKDLkpBsnLAyGs1xz6cubJhn+eVqMEMaw=";
    };
  };
  postPatch = "cp ${./Cargo.lock} Cargo.lock";

  buildAndTestSubdir = "wrappers";
  buildFeatures = [
    "helloworld_fdw"
    "bigquery_fdw"
    "clickhouse_fdw"
    "stripe_fdw"
    "firebase_fdw"
    "s3_fdw"
    "airtable_fdw"
    "logflare_fdw"
  ];

  # FIXME (aseipp): disable the tests since they try to install .control
  # files into the wrong spot, aside from that the one main test seems
  # to work, though
  doCheck = false;

  meta = with lib; {
    description = "Various Foreign Data Wrappers (FDWs) for PostreSQL";
    homepage    = "https://github.com/supabase/wrappers";
    maintainers = with maintainers; [ thoughtpolice ];
    platforms   = postgresql.meta.platforms;
    license     = licenses.postgresql;
  };
}
