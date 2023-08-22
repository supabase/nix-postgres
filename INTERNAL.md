# Nix Postgres Prototype

This repository contains **experimental code** to package PostgreSQL using nix.

## Install Nix
Follow installation guide at [installation](./docs/start-here.md).

# Evaluation Criteria

## Building multiple versions of PostgreSQL: 14, 15 and future versions

Supported major versions of Postgres are defined in [flake.nix basePackages](https://github.com/supabase/nix-postgres/blob/648e31bc7b629c6644b07ad378d04d3334403d78/flake.nix#L245-L246).

Each major version can be built independently.
```bash
nix build .#psql_14/bin -o result-14
nix build .#psql_15/bin -o result-15
```

Builds Postgres 14 & 15 with all of our extensions and symlinks the resulting build artifaces e.g. `psql`, `pg_dump` etc at `result-14` and `result-15` respectively.


On first run these commands will take a long time to complete. Intermediate results are cached and reused leading to significantly reduced built times on subsequent runs.

The Postgres build itself is defined upstream in [nixpkgs#postgresqlXX](https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/sql/postgresql/default.nix). That distribution is frequently updated and historically has released minor and major updates within 10 days. We can optionally override the version number or vendor the derivation to support additional versions.

Note that nixpkgs supports 1 minor version (the most recent) for each major version.


To launch a psql repl with the built version, first start the server:

```bash
nix run .#start-server 15
```
Next, launch the psql client.

```bash
nix run .#start-client 15
```

Both commands are defined in [flake.nix](./flake.nix)

## Building multiple versions of an extension: e.g. pgvector

Extensions included with the Postgres distribution come from two sources:

- Upstream in [nixpkgs](https://github.com/NixOS/nixpkgs/tree/a996f7185eaaa8ae261adbc6b772761d62869796/pkgs/servers/sql/postgresql/ext)
- Locally in [./ext](./ext)

Each extension has a default version that can be easily updated or overriden. Multiple versions can be managed on git branches or concurrently with unique names e.g. `supautils-1.1`, `supautils-1.2`.

## Testing

### Extension Tests

Extension pgTap tests are defined in [`./tests/smoke`](./tests/smoke) and can be run via:

```
nix flake check
```

Tests execute against Postgres 14 and 15.

### Upgrade Tests

The nix command `migration-test` supports testing across arbitrary versions (major and minor) using `pg_upgrade` and `pg_dumpall`

It takes the form:
```
nix run .#migration-test <old_version> <new_version> <upgrade_method>
```

For example, to test `pg_upgrade` as the method for upgrading between the current version of pg14 and current version of pg15, you can run:

```
nix run .#migration-test 14 15 pg_upgrade
```

The files that define the test database to be migrated are:

- [postgresql.conf](./tests/postgresql.conf)
- [prime.sql](./tests/prime.sql)
- [data.sql](./tests/migrations/data.sql)

Since nix allows refering to derivations defined on github, we can test upgrades between any arbitrary prior commits

For example, to upgrade from the postgres 14 version defined in commit 388659fcc3c857f2c45eeb397f67b5b7bf9a1b84 to the current version of postgres 14, run:
```
nix run github:supabase/nix-postgres#migration-test \
  $(nix build github:supabase/nix-postgres/388659fcc3c857f2c45eeb397f67b5b7bf9a1b84#psql_14/bin
  14
```

The `data.sql` file is currently very minimal. We would extend that to exercise large parts of a complex schema to ensure tests have significant coverage.


## Integrated with Github CI workflows

GitHub Actions produces:
- [builds](https://github.com/supabase/nix-postgres/blob/main/.github/workflows/nix-build.yml)
- [docker images](https://github.com/supabase/nix-postgres/blob/main/.github/workflows/docker.yml)
- [reusable cache artifacs in s3](https://github.com/supabase/nix-postgres/blob/main/.github/workflows/cache-upload.yml)

## Produce an AWS AMI

(Not yet implemented)

The working plan for AMIs is to use `nix copy` to move CI build artifacts from s3 to the AMI. There is a detailed write-up in [issue 17](https://github.com/supabase/nix-postgres/issues/17)


## Produce a Docker image

Docker images can be produced from the binary assets generated with `nix build`

Locally, you can produce a docker image using:

```shell
nix build .#psql_15/docker -o result-15
docker load -i ./result-15
```

Which creates an image named `postgresql-15:latest` tagged in local image
registry.

You can run that image with:

```shell
docker run --rm \
 --name supa_nix_local \
  -p 5441:5432 \
  -d \
  -e POSTGRES_DB=postgres \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_USER=postgres \
  -d postgresql-15:latest 
```

and connect through psql 
```shell
docker exec -it supa_nix_local psql -U postgres
```


## Workflows:

### A developer adds a new version of an extension, CI builds it and runs tests

[ref](https://github.com/supabase/nix-postgres/pull/16/files)

### A developers adds a new version of PostgreSQL, CI builds it and runs tests.

Once available upstream, new versions can be added [here](https://github.com/supabase/nix-postgres/blob/648e31bc7b629c6644b07ad378d04d3334403d78/flake.nix#L245-L246)

### A pushed git tag produces an AWS AMI + docker image.

Not in prototype functional

## Consider that we have the following PostgreSQL targets

### Supported PostgreSQL versions (14), these are older versions not yet migrated to latest

Builtin and runs in CI

```shell
nix build .#psql_14/bin -o result-14
```

### Latest PostgreSQL version (15)

Builtin and runs in CI

```shell
nix build .#psql_15/bin -o result-15
```

### Future major PostgreSQL version (e.g. 16 beta 2)

Support pending upstream merge of [PR](https://github.com/NixOS/nixpkgs/pull/249030) or can be vendored.

### Future patch PostgreSQL version (14.x, 15.y)

These occur upstream. If we want to stay on the outdated version we can add an overlay to this repo.

### Each version will be tested against all extensions

Builtin and runs in CI

## Limitations

### Lack of darwin-arm support

This is blocked by pgrx extensions. Everything except those extensions is functional.

## Other

### Nix binary cache

There is a nix binary cache located at the following URL:

- https://nix-postgres-artifacts.s3.amazonaws.com/

Binaries are signed with the public key:

- `nix-cache.supabase.com-1:ZfEc7Qb7SN+qOTJGMtCz54rnVQ1W2ZI2ROCSSD6YQYc=`
