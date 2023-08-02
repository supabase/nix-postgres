#!/usr/bin/env -S just --justfile
# ^ A shebang isn't required, but allows a justfile to be executed
#   like a script, with `./justfile test`, for example.

default:
    @{{ just_executable() }} --choose

alias b := build-all
alias c := check

build-all:
    nix build .#psql_14/bin .#psql_14/docker
    nix build .#psql_15/bin .#psql_15/docker

check:
    nix flake check -L
