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

Both package launchers set `BITGARTH_CHANNEL=homebrew` for their own process.
The web server already reads this value. The v0.4.0 CLI does not yet read or
report it; the variable is available for future CLI support. A client's channel
does not change its paired server's channel. Directly executing the internal
binary instead of the installed launcher bypasses these package settings.

## Starting and stopping the server

Installing `bitgarth-web` does not start it or enable automatic startup. Choose
one of the following modes; do not run multiple instances against the same
data directory or port.

| Command | Behavior |
| --- | --- |
| `bitgarth-web` | Runs in the foreground; stop it with Ctrl+C. |
| `brew services run ferntrail/tap/bitgarth-web` | Runs in the background without registering automatic startup. |
| `brew services start ferntrail/tap/bitgarth-web` | Starts immediately in the background and registers startup at user login. |
| `brew services stop ferntrail/tap/bitgarth-web` | Stops the background service and disables its automatic startup. |

Run these Homebrew commands as your normal user. Homebrew uses launchd on macOS
and systemd on Linux. The service manager keeps the server running and restarts
it if it exits. Logs go to `$(brew --prefix)/var/log/bitgarth-web.log`.

Check status or restart after changing settings:

```sh
brew services info ferntrail/tap/bitgarth-web
brew services restart ferntrail/tap/bitgarth-web
```

`restart` also registers automatic startup. Use `stop` followed by `run` if
you want to restart a background instance without enabling startup at login.

### User-service settings: `bitgarth-web.env`

Background services do not automatically inherit your interactive shell's
environment. Current Homebrew supports a per-service environment file at
`~/.homebrew/services/bitgarth-web.env`, or
`$HOMEBREW_USER_CONFIG_HOME/services/bitgarth-web.env` if that variable is set.

Create its directory:

```sh
mkdir -p "${HOMEBREW_USER_CONFIG_HOME:-$HOME/.homebrew}/services"
```

Create `bitgarth-web.env` in that directory. For example, to make the server
accessible on all IPv4 network interfaces:

```ini
IP=0.0.0.0
PORT=8080
# Optional: use an absolute path to your persistent data directory.
# BITGARTH_PROJECT_DIR=/absolute/path/to/bitgarth-data
```

Use one `KEY=value` per line. Blank lines and lines beginning with `#` are
ignored. Values are literal: do not use `export`, surrounding quotes, `~`,
`$HOME`, or command substitutions. Omit settings to keep the package defaults.
Changing `BITGARTH_PROJECT_DIR` selects a different data directory; it does not
move your existing data.

Restrict access to the file, then apply the settings:

```sh
chmod 600 "${HOMEBREW_USER_CONFIG_HOME:-$HOME/.homebrew}/services/bitgarth-web.env"
brew services restart ferntrail/tap/bitgarth-web
```

Homebrew ignores group- or world-writable environment files. Settings persist
across package upgrades. The file applies to Homebrew user services, not direct
`bitgarth-web` invocations or services managed with `sudo`. The launcher always
sets `BITGARTH_CHANNEL=homebrew`, regardless of this file.

### Start at boot without logging in

**Linux with systemd:** keep the service running as your normal user and enable
lingering for that account:

```sh
sudo loginctl enable-linger "$(id -un)"
brew services start ferntrail/tap/bitgarth-web
```

The user service manager then starts at boot and remains active after logout.
This preserves support for `bitgarth-web.env`. Lingering applies to the whole
user account, not just BitGarth; `sudo loginctl disable-linger "$(id -un)"`
reverses it.

**macOS:** stop any user service, then register a boot service that runs as your
normal account:

```sh
brew services stop ferntrail/tap/bitgarth-web
sudo "$(command -v brew)" services start ferntrail/tap/bitgarth-web --sudo-service-user="$(id -un)"
```

The selected account must be able to read the installed package and write to
the data and log directories. Manage this boot service with `sudo` thereafter,
including when stopping it before an upgrade or uninstalling it. For example:

```sh
sudo "$(command -v brew)" services stop ferntrail/tap/bitgarth-web
```

Homebrew skips user environment files when invoked as root, including with
`--sudo-service-user`. This boot-service example therefore uses the package
defaults, including localhost-only access. For custom boot-service settings on
macOS, use a launchd definition with explicit environment variables and the
installed `bitgarth-web` launcher; Homebrew accepts a custom service definition
with `--file`. On Linux, `sudo brew services start` is also a system-service
option, but a user service with lingering avoids running BitGarth as root.

See the [Homebrew services reference](https://docs.brew.sh/Manpage#services-subcommand),
[Homebrew's environment-file handling](https://github.com/Homebrew/brew/blob/7.0.4/Library/Homebrew/service.rb),
and [systemd's lingering documentation](https://www.freedesktop.org/software/systemd/man/latest/loginctl.html).

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

These commands assume a user service. For a macOS boot service, use the `sudo`
stop/start commands above, keeping the same service account. Stop a foreground
instance with Ctrl+C before upgrading it.

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
