# FernTrail Homebrew tap

Homebrew packages for applications published by [FernTrail](https://ferntrail.tech/).

## Install

```sh
brew tap ferntrail/tap
brew install ferntrail/tap/bitgarth-cli
```

The CLI provides the `bitgarth` command. Pair it with an existing server:

```sh
bitgarth pair https://your-bitgarth.example.com/
```

To run your own BitGarth server, install the separate web package:

```sh
brew install ferntrail/tap/bitgarth-web
bitgarth-web
```

Open <http://127.0.0.1:8080> in your browser. You can install both packages on
the same computer, or install the server on a home server and the CLI on your
personal computer. Neither package depends on the other.

| Package | Command | Purpose |
| --- | --- | --- |
| `bitgarth-cli` | `bitgarth` | Client paired with a BitGarth server |
| `bitgarth-web` | `bitgarth-web` | Server and its browser assets |

## Supported platforms

- macOS on Apple Silicon (the binaries target macOS 11 or newer; Homebrew's
  own operating-system support requirements also apply).
- Linux on x86-64 with **system glibc 2.39 or newer**, such as Ubuntu 24.04.
  The server also installs Homebrew's OpenSSL 3 dependency.

The current releases do not include Intel Mac or ARM Linux binaries. These
formulae install the existing, checksum-verified
[BitGarth release archives](https://github.com/BitGarth/bitgarth/releases).
The macOS binaries are signed and notarized by FernTrail B.V.

## Server configuration

The launcher keeps the server and its assets together and works from any
working directory. Defaults:

- Address: `127.0.0.1:8080` (only accessible from this computer).
- Data: `$(brew --prefix)/var/bitgarth`, outside the versioned package directory.
- New data files and directories are restricted to the account running the server.

For a foreground server, set environment variables when starting it:

```sh
BITGARTH_PROJECT_DIR="$HOME/bitgarth-data" PORT=8081 bitgarth-web
```

To allow access from other computers on your trusted local network, choose
the server's LAN address with `IP`, or use `IP=0.0.0.0` to listen on all IPv4
interfaces. Use HTTPS through a reverse proxy for remote access. Review the
[server environment variables](https://github.com/BitGarth/bitgarth/blob/main/docs/user/environment-variables.md)
and [security documentation](https://github.com/BitGarth/bitgarth/blob/main/docs/user/security.md)
before exposing the server.

To run the server in the background with its defaults:

```sh
brew services start ferntrail/tap/bitgarth-web
brew services stop ferntrail/tap/bitgarth-web
```

Run these as your normal user. Homebrew registers a user service; on macOS it
starts at login. Logs go to `$(brew --prefix)/var/log/bitgarth-web.log`.
Services do not automatically inherit variables from your interactive shell.
For custom service settings, use your own launchd/systemd service definition
that sets the environment and runs `$(brew --prefix)/bin/bitgarth-web`.

Both package launchers set `BITGARTH_CHANNEL=homebrew` for their own process.
The web server already reads this value. The v0.4.0 CLI does not yet read or
report it; the variable is available for future CLI support. A client's channel
does not change its paired server's channel. Directly executing the internal
binary instead of the installed launcher bypasses these package settings.

## Updates and removal

```sh
brew update
brew upgrade ferntrail/tap/bitgarth-cli
```

Before upgrading the server, stop it and back up its **entire data directory**,
including session secrets and SQLite WAL files. Then upgrade and restart:

```sh
brew services stop ferntrail/tap/bitgarth-web
# Back up your data directory here.
brew upgrade ferntrail/tap/bitgarth-web
brew services start ferntrail/tap/bitgarth-web
```

The data directory survives package upgrades and uninstallation. Remove it
separately only if you intend to delete your instance. To uninstall the server,
stop its service first, then run `brew uninstall bitgarth-web`. The CLI can be
removed with `brew uninstall bitgarth-cli`.

Homebrew updates this tap during `brew update`, including definitions for any
future FernTrail applications. Adding a package to the tap does not install it
automatically. A future desktop app can be added as a cask in this repository.

## Maintaining the tap

For a new BitGarth release, update each formula's release URLs and platform SHA-256
values from the published `SHA256SUMS`, and the tag in its license resource URL.
Update the license resource checksum if the license file changed. Never
substitute an archive without updating its checksum.

Run the same checks as CI:

```sh
brew style Formula/*.rb
brew install ferntrail/tap/bitgarth-cli ferntrail/tap/bitgarth-web
brew test ferntrail/tap/bitgarth-cli
brew test ferntrail/tap/bitgarth-web
```

The web test starts a temporary instance on a random localhost port, checks
health, HTML and WASM delivery, and verifies the launcher's channel and storage.
CI runs on Apple Silicon macOS and Ubuntu 24.04 x86-64.

## License and support

BitGarth retains its [FSL-1.1-ALv2 license](https://github.com/BitGarth/bitgarth/blob/main/LICENSE.md).
Each formula installs the license from the corresponding release tag.

Use this repository's issues for packaging problems. Application information
and support are at [bitgarth.app](https://bitgarth.app/).
