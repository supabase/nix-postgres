#!/usr/bin/env bash

[ ! -z "$DEBUG" ] && set -x

# first argument is the old version; a path, or 14 or 15
if [[ $1 == /nix/store* ]]; then
    if [ ! -L "$1/receipt.json" ] || [ ! -e "$1/receipt.json" ]; then
        echo "ERROR: $1 does not look like a valid Postgres install"
        exit 1
    fi
    OLDVER="$1"
elif [ "$1" == "14" ]; then
    PSQL14=$(nix build --quiet --no-link --print-out-paths .#"psql_14/bin")
    OLDVER="$PSQL14"
elif [ "$1" == "15" ]; then
    PSQL15=$(nix build --quiet --no-link --print-out-paths .#"psql_15/bin")
    OLDVER="$PSQL15"
else
    echo "Please provide a valid Postgres version (14 or 15), or a /nix/store path"
    exit 1
fi

# second argument is the new version; 14 or 15
if [[ $1 == /nix/store* ]]; then
    if [ ! -L "$1/receipt.json" ] || [ ! -e "$1/receipt.json" ]; then
        echo "ERROR: $1 does not look like a valid Postgres install"
        exit 1
    fi
    NEWVER="$1"
elif [ "$2" == "14" ]; then
    PSQL14=$(nix build --quiet --no-link --print-out-paths .#"psql_14/bin")
    NEWVER="$PSQL14"
elif [ "$2" == "15" ]; then
    PSQL15=$(nix build --quiet --no-link --print-out-paths .#"psql_15/bin")
    NEWVER="$PSQL15"
else
    echo "Please provide a valid Postgres version (14 or 15), or a /nix/store path"
    exit 1
fi

echo "Old server build: PSQL $1"
echo "New server build: PSQL $2"

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
PSQL_CONF_FILE=$PWD/tests/postgresql.conf
PGSODIUM_GETKEY_SCRIPT=$PWD/tests/util/pgsodium_getkey.sh
echo "NOTE: patching postgresql.conf files"
for x in "$DATDIR" "$NEWDAT"; do
  sed \
    "s#@PGSODIUM_GETKEY_SCRIPT@#$PGSODIUM_GETKEY_SCRIPT#g" \
    $PSQL_CONF_FILE > "$x/postgresql.conf"
done

echo "NOTE: Starting old server (v${1}) for temporary server to load data into the system"
$OLDVER/bin/pg_ctl start -D "$DATDIR"

PRIMING_SCRIPT=$PWD/tests/prime.sql
MIGRATION_DATA=$PWD/tests/migrations/data.sql

$OLDVER/bin/psql -h localhost -d postgres -Xf "$PRIMING_SCRIPT"
$OLDVER/bin/psql -h localhost -d postgres -Xf "$MIGRATION_DATA"

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
rm -f delete_old_cluster.sh # we don't need this
