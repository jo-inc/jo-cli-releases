# Jo CLI

Command line access to Jo memory and brain for terminals, scripts, and other agents.

Use it to let another coding agent or automation read and write the same context you keep in Jo.

## Install

```bash
curl -fsSL https://github.com/jo-inc/jo-cli-releases/releases/latest/download/install.sh | sh
```

Then verify the command is available:

```bash
jo --help
```

If `jo` is not found, add `~/.local/bin` to your PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Sign in

Use browser login:

```bash
jo login
```

Or provide an access key:

```bash
jo login --api-key <jo-api-key>
```

To avoid saving the key in shell history, pass it through stdin:

```bash
printf '%s' "$JO_API_KEY" | jo login --api-key -
```

Check the signed-in account:

```bash
jo whoami
```

Remove locally stored credentials:

```bash
jo logout
```

Update the CLI:

```bash
jo update
```

## Use Jo memory

Remember something:

```bash
jo brain remember "The release checklist is in the project docs"
```

Pipe text into Jo:

```bash
echo "Use the project docs for release steps" | jo
```

Search memory:

```bash
jo brain recall "release checklist" --limit 5
```

Ask using remembered context:

```bash
jo brain ask "what should i check before shipping?"
```

Import notes:

```bash
jo brain import ./notes.md
jo brain import ./notes-folder
```

## Agent usage

For another agent or script, set an API key in the environment:

```bash
export JO_API_KEY=<jo-api-key>
jo brain recall "project constraints" --json
```

Useful commands for agent tools:

```bash
jo brain remember "..."
jo brain recall "..." --json
jo brain ask "..." --json
jo brain import ./path/to/notes
```

## Notes

- The CLI stores local auth in `~/.jo/config.json`; protect this file like a bearer token and avoid syncing it into dotfiles.
- Imports are capped at 10 MB per file by default. Override with `JO_MAX_IMPORT_BYTES` if needed.
- Jo checks for CLI updates at most once per day. Set `JO_CLI_NO_UPDATE_CHECK=1` to disable this.
- Use `--json` when calling from scripts or agents.
- Do not save secrets unless you intentionally want Jo to remember them.

## Release assets

Each release includes:

- `install.sh`
- `jo-cli-<version>.tar.gz`
- `jo-cli-latest.tar.gz`
- `SHA256SUMS`

The installer downloads the latest tarball, verifies it against `SHA256SUMS`, validates archive paths, and installs `jo` into `~/.local/bin`.
