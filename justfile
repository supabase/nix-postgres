#!/usr/bin/env -S just --justfile
# ^ A shebang isn't required, but allows a justfile to be executed
#   like a script, with `./justfile test`, for example.

default:
    @{{ just_executable() }} --choose

alias b := build-all

build-all:
    nix build .#psql_14
    nix build .#psql_15
