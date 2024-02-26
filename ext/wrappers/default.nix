{ lib, stdenv, fetchFromGitHub, openssl, pkg-config
, postgresql, buildPgrxExtension_0_11_2
}:

buildPgrxExtension_0_11_2 rec {
  pname = "supabase-wrappers";
  version = "unstable-2024-02-26";
  inherit postgresql;

  src = fetchFromGitHub {
    owner  = "samrose";
    repo   = "wrappers";
    #rev pinned for now to the HEAD of the main branch to achieve cargo-pgrx 0.11.2 compat
    rev    = "lock-resolution"; 
    hash   = "sha256-xzquqZqLxHzCbzCUZ0SlD+ObpJsaLJ9KFERtE+SOtdM=";
  };
 
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  # Needed to get openssl-sys to use pkg-config.
  OPENSSL_NO_VENDOR = 1;

  cargoLock = {
    lockFile = "${src}/wrappers/Cargo.lock";
    outputHashes = {
      "clickhouse-rs-1.0.0-alpha.1" = "sha256-0zmoUo/GLyCKDLkpBsnLAyGs1xz6cubJhn+eVqMEMaw=";
    };
  };
  postPatch = "cp ${cargoLock.lockFile} Cargo.lock";

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
