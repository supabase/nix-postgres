# prototype nix package for supabase postgres

This repository contains **experimental code** to package PostgreSQL using
**[Nix]**, and tooling and infrastructure for deploying it. Read the rest of
this README for some basic overview of the high level components.

Don't know Nix? Want to understand some of the thinking here? To learn about Nix
and some of the design constraints this repository are under, please see the
[`docs/`](./docs/) directory which should help get you up to speed.

If you want to install Nix and play along quickly, check out the
[Start Here](./docs/start-here.md) page.

> ⚠️ 🚧 **NOTE** 🚧 ⚠️ &mdash; This repository is **EXPERIMENTAL**. It is not an
> official Supabase project, and may be abandoned or changed at any moment;
> there is no commitment to any kind of external third party support at this
> time.

[Nix]: https://nixos.org

## Fundamental components of this repository

This repository contains a few major high level components, which are outlined below.

### PostgreSQL Binary Distributions

The following PostgreSQL releases are packaged up, along with extensions (read
below) in order to create "fully self contained" binary distributions. In order to get ahold of them, you can use `nix build`:

```
nix build .#psql_14/bin -o result-14
nix build .#psql_15/bin -o result-15
```

This will create two symlinks named `result-14` (resp. `result-15`). You can use the resulting symlinks as a binary distribution; as if they were unpacked tarballs.

### PostgreSQL Docker Images

From the binary images generated by `nix build`, we also create Docker images. You can create
and load an image like so:

```
nix build .#psql_15/docker -o result-15
docker load -i ./result-15
```

There will then be an image named `postgresql-15:latest` tagged in local image
registry.

This repository also provides pre-packaged docker images hosted via GitHub Packages; simply download them with:

```
docker pull ghcr.io/supabase/nix-postgres-14:latest
docker pull ghcr.io/supabase/nix-postgres-15:latest
```

### A full suite of extensions

The binary distributions have many extensions enabled; these include:

- postgis
- pgrouting
- pgtap
- pg_cron
- pgaudit
- pgjwt
- plpgsql_check
- pg_safeupdate
- timescaledb
- wal2json
- plv8
- rum
- pgvector
- pg_repack
- pgroonga
- pgsql
- pg_plan_filter
- pg_net
- pg_hashids
- pgsodium
- pg_graphql
- pg_stat_monitor
- pg_jsonschema
- vault
- hypopg
- pg_tle
- wrappers
- supautils
- citus

You can just use `CREATE EXTENSION` to enable most of these. Some may require
tweaks to [postgresql.conf](./tests/postgresql.conf.in) to enable.

### Helpful development utilities

Want to start a postgresql-15 server with a bunch of extensions? You don't even
need to download this repository; just use `nix run`:

```
nix run github:supabase/nix-postgres#start-server 15
```

This will start PostgreSQL 15 on port `5435` on localhost with a temporary directory created by `mktemp -d`. Connect to it:

```
austin@GANON:~$ nix run github:supabase/nix-postgres#start-client 14
Starting server for PSQL 14
psql (14.8, server 15.3)
WARNING: psql major version 14, server major version 15.
         Some psql features might not work.
Type "help" for help.

postgres=#
```

The first argument of both commands simply specifies `14` or `15` to get the
major version. This will be expanded in the future.

### Migration testing tools

You can test database migrations (using some artificial data schemas);
it uses the following data to set up the database:

- [postgresql.conf](./tests/postgresql.conf.in)
- [prime.sql](./tests/prime.sql)
- [data.sql](./tests/migrations/data.sql)

Then, run the following:

```
nix run github:supabase/nix-postgres#migration-test 14 15
```

This will do a migration between versions 14 and 15, at the time of the latest commit to the `nix-postgres` repository.

You can also test arbitrary `/nix/store` paths; for example the following works:

```
nix run github:supabase/nix-postgres#migration-test \
  $(nix build github:supabase/nix-postgres#psql_14/bin --no-link --print-out-paths) \
  $(nix build github:supabase/nix-postgres#psql_15/bin --no-link --print-out-paths)
```

Thus, you can arbitrarily mix and match various versions that might have been
built in CI, and test their upgrade paths.

Note that the `data.sql` files and whatnot aren't complete; tweaks are very
welcome to cover as many edge cases as possible.

### Nix binary cache

There is a nix binary cache located at the following URL:

- https://nix-postgres-artifacts.s3.amazonaws.com/

Binaries are signed with the public key:

- `nix-cache.supabase.com-1:ZfEc7Qb7SN+qOTJGMtCz54rnVQ1W2ZI2ROCSSD6YQYc=`

## Other notes

- This repository should work "in perpetuity" (assuming Nix doesn't horribly
  break years down the line), but will probably be migrated elsewhere if it's
  successful, so don't get too cozy or familiar.
- Austin uses **[jujutsu]** to develop this repository; but you don't have to
  (you should try it, though!) The workflow used for this repo is "linear
  commits, no merges." If you submit PRs, they'll be rebased on top of the
  existing history to match that. (YMMV but I prefer this style.)

[jujutsu]: https://github.com/martinvonz/jj
