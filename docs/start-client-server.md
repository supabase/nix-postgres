If you want to run a postgres server, just do this from the root of the
repository:

```
nix run .#start-server 14
```

Replace the `14` with a `15`, and you'll be using a different version.

This always uses port 5432.

Actually, you don't even need the repository. You can do this from arbitrary
directories, if the left-hand side of the hash character (`.` in this case) is a
valid "flake reference":

```
# from any arbitrary directory
nix run github:supabase/nix-postgres#start-server 14
```

## Arbitrary versions at arbitrary git revisions

Let's say you want to use a PostgreSQL build from a specific version of the
repository. You can change the syntax of the above to use _any_ version of the
repository, at any time, by adding the commit hash after the repository name:

```
# use postgresql 15 build at commit a9989d4800dd6038827afed27456f19ba4b2ae0a
nix run github:supabase/nix-postgres/a9989d4800dd6038827afed27456f19ba4b2ae0a#start-server 15
```

## Running the client

All of the same rules apply, but try using `start-client` on the right-hand side
of the hash character, instead. For example:

```
nix run github:supabase/nix-postgres#start-server 14 &
sleep 5
nix run github:supabase/nix-postgres#start-client 15
```
