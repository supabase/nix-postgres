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

# now, the second argument needs to be a directory which we'll store
# all the data in (we don't do it ourselves or blow it away after, in
# case people want to manually do more work with it)
if [ -z "$2" ]; then
    echo "Please provide a directory to store the data in"
    exit
fi

# if the directory $2 exists, then warn the user and bail
if [ -d "$2" ]; then
    echo "Directory $2 already exists, please remove it first"
    exit 1
fi


BINDIR=$(nix build --quiet --no-link --print-out-paths .#"psql_$1/bin")

mkdir "$2"
$BINDIR/bin/initdb -D "$2" --locale=C

# -k /tmp will make sure the socket file goes to /tmp instead of /run/postgres,
# which probably doesn't exist or is owned by systemd
exec $BINDIR/bin/postgres -D "$2" -k /tmp
