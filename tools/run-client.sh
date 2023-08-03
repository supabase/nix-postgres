#!/usr/bin/env bash
# shellcheck shell=bash

[ ! -z "$DEBUG" ] && set -x

# first argument should be '14' or '15' for the version
if [ "$1" == "14" ]; then
    echo "Starting server for PSQL 14"
elif [ "$1" == "15" ]; then
    echo "Starting server for PSQL 15"
else
    echo "Please provide a valid Postgres version (14 or 15)"
    exit 1
fi

BINDIR=$(nix build --quiet --no-link --print-out-paths .#"psql_$1/bin")

exec $BINDIR/bin/psql -h localhost postgres
