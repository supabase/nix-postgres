#!/usr/bin/env bash
# shellcheck shell=bash

[ ! -z "$DEBUG" ] && set -x

# first argument should be '14' or '15' for the version
if [ "$1" == "14" ]; then
    true
elif [ "$1" == "15" ]; then
    true
else
    echo "Please provide a valid Postgres version (14 or 15)"
    exit 1
fi

echo "Using PSQL v$1 tools for 'pg_dumpall' and 'psql'"

# the 2nd argument should be two port numbers in the form 'from:to' where
# from is the server to dumpall from, and 'to' is the server to load the
# data into. error if it is not provided
if [ -z "$2" ]; then
    echo "Please provide a port number to dumpall from and a port number to load into"
    exit 1
fi

# split the 2nd argument into two variables
IFS=':' read -r -a PORTS <<< "$2"

BINDIR=$(nix build --quiet --no-link --print-out-paths .#"psql_$1/bin")
export PATH=$BINDIR/bin:$PATH

echo "Loading a lot of data into the first server on port ${PORTS[0]}"
psql -h localhost -p ${PORTS[0]} -d postgres -Xf ./tests/prime.sql
psql -h localhost -p ${PORTS[0]} -d postgres -Xf ./tests/migrations/data.sql

echo "Migrating data from server on port ${PORTS[0]} to server on port ${PORTS[1]}"
pg_dumpall -h localhost -p ${PORTS[0]} | psql -h localhost -d postgres -p ${PORTS[1]}
