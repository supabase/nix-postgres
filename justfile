#!/usr/bin/env -S just --justfile
# ^ A shebang isn't required, but allows a justfile to be executed
#   like a script, with `./justfile test`, for example.

default:
    @{{ just_executable() }} --choose

alias b := build-all
alias c := check

build-all:
    nix build .#psql_15/bin .#psql_15/docker
    nix build .#psql_16/bin .#psql_16/docker
    nix build .#psql_orioledb_16/bin .#psql_orioledb_16/docker

check:
    nix flake check -L
