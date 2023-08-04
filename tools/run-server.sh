#!/usr/bin/env bash
# shellcheck shell=bash

[ ! -z "$DEBUG" ] && set -x

PSQL14=$(nix build --quiet --no-link --print-out-paths .#"psql_14/bin")/bin
PSQL15=$(nix build --quiet --no-link --print-out-paths .#"psql_14/bin")/bin

# first argument should be '14' or '15' for the version
if [ "$1" == "14" ]; then
    echo "Starting server for PSQL 14"
    BINDIR="$PSQL14"
elif [ "$1" == "15" ]; then
    echo "Starting server for PSQL 15"
    BINDIR="$PSQL15"
else
    echo "Please provide a valid Postgres version (14 or 15)"
    exit 1
fi

PORTNO="${2:-5432}"
DATDIR=$(mktemp -d)
mkdir -p "$DATDIR"

echo "NOTE: using port $PORTNO for server"
echo "NOTE: using temporary directory $DATDIR for data, which will not be removed"
echo "NOTE: you are free to re-use this data directory at will"
echo 

export PATH=$BINDIR/bin:$PATH

initdb -D "$DATDIR" --locale=C
exec postgres -p "$PORTNO" -D "$DATDIR" -k /tmp
