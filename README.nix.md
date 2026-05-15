# Nix setup

This repository carries a sidecar Nix workflow so the fork can stay close to
upstream while still providing a reproducible local developer environment.

## Enter the development shell

```bash
nix develop
```

The shell provides Python 3.13 and `uv`. Python package resolution remains
split across the existing project files:

- `pyproject.toml` declares the acceptable dependency ranges.
- `uv.lock` pins the reproducible install snapshot used by the Nix sidecar.

## Install locked dependencies

```bash
uv sync --frozen
```

Use the upstream README for API keys, CLI usage, Docker, and provider-specific
configuration.

## Run the CLI

```bash
nix run .#cli
```

Pass CLI arguments after `--`, for example:

```bash
nix run .#cli -- --help
```

The Nix CLI command uses the pinned lockfile environment and adds the SQLite
checkpoint package that upstream currently declares in `pyproject.toml` but
does not include in `uv.lock`.

Bare `python -m cli.main` uses the Nix-provided interpreter, not the project
virtual environment, so it will not see packages installed into `.venv`.

## Verify a fresh checkout

```bash
nix run .#verify
```

The verification command syncs the locked project environment, supplies the
test runner required by the existing suite, adds the SQLite checkpoint package
that upstream currently declares but does not include in `uv.lock`, and runs
`pytest`.
