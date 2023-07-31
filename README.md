# prototype nix package for supabase postgres

This repository contains **experimental code** to package PostgreSQL using
**[Nix]**, and tooling and infrastructure for deploying it.

Don't know Nix? Want to understand some of the thinking here? To learn about Nix
and some of the design constraints this repository are under, please see the
[`docs/`](./docs/) directory which should help get you up to speed.

If you want to install Nix and play along quickly, check out the
[Start Here](./docs/00-START-HERE.md) page.

[Nix]: https://nixos.org

## Quick start

NIH. Will come a little later. Read docs or ask me questions directly in the
mean time.

## Other notes

- This repository should work "in perpetuity" (assuming Nix doesn't horribly
  break years down the line), but will probably be migrated elsewhere if it's
  successful, so don't get too cozy or familiar.
- Austin uses **[jujutsu]** to develop this repository; but you don't have to
  (you should try it, though!) The workflow used for this repo is "linear
  commits, no merges." If you submit PRs, they'll be rebased on top of the
  existing history to match that. (YMMV but I prefer this style.)
