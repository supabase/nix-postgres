#!/usr/bin/env bash

PSQL14=$(nix build --quiet --no-link --print-out-paths .#"psql_14/bin")
PSQL15=$(nix build --quiet --no-link --print-out-paths .#"psql_15/bin")

# first argument is the old version; 14 or 15
if [ "$1" == "14" ]; then
    OLDVER="$PSQL14"
elif [ "$1" == "15" ]; then
    OLDVER="$PSQL15"
else
    echo "Please provide a valid Postgres version (14 or 15)"
    exit 1
fi

# second argument is the new version; 14 or 15
if [ "$2" == "14" ]; then
    NEWVER="$PSQL14"
elif [ "$2" == "15" ]; then
    NEWVER="$PSQL15"
else
    echo "Please provide a valid Postgres version (14 or 15)"
    exit 1
fi

echo "Old server build: PSQL $1"
echo "New server build: PSQL $2"

if [[ $2 -lt $1 ]]; then
    echo "ERROR: You can't upgrade from a newer version ($1) to an older version ($2)"
    exit 1
fi

PORTNO="${2:-5432}"
DATDIR=$(mktemp -d)
NEWDAT=$(mktemp -d)
mkdir -p "$DATDIR" "$NEWDAT"

echo "NOTE: using temporary directory $DATDIR for PSQL $1 data, which will not be removed"
echo "NOTE: you are free to re-use this data directory at will"
echo 

$OLDVER/bin/initdb -D "$DATDIR" --locale=C
$NEWVER/bin/initdb -D "$NEWDAT" --locale=C

# NOTE (aseipp): we need to patch postgresql.conf to have the right pgsodium_getkey script
echo "NOTE: patching postgresql.conf files"
for x in "$DATDIR" "$NEWDAT"; do
  cp ./tests/postgresql.conf "$x/postgresql.conf"
  sed -i \
    "s#@PGSODIUM_GETKEY_SCRIPT@#$PWD/tests/util/pgsodium_getkey.sh#g" \
    "$x/postgresql.conf"
done

echo "NOTE: Starting old server (v${1}) for temporary server to load data into the system"
$OLDVER/bin/pg_ctl start -D "$DATDIR"

$OLDVER/bin/psql -h localhost -d postgres -Xf ./tests/prime.sql
$OLDVER/bin/psql -h localhost -d postgres -Xf ./tests/migrations/data.sql

echo "NOTE: Stopping old server (v${1}) to prepare for migration"
$OLDVER/bin/pg_ctl stop -D "$DATDIR"

echo "NOTE: Migrating old data $DATDIR to $NEWDAT using pg_upgrade"

export PGDATAOLD="$DATDIR"
export PGDATANEW="$NEWDAT"
export PGBINOLD="$OLDVER/bin"
export PGBINNEW="$NEWVER/bin"

if ! $NEWVER/bin/pg_upgrade --check; then
    echo "ERROR: pg_upgrade check failed"
    exit 1
fi

echo "NOTE: pg_upgrade check passed, proceeding with migration"
$NEWVER/bin/pg_upgrade
