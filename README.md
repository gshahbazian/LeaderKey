# Leader Key

Fork of https://github.com/mikker/LeaderKey which seems to be dead.

Removes the settings UI and simplifies.

## Building

Compile with Swift Package Manager:

```sh
swift build
swift build -c release
```

Run the XCTest suite without launching the app:

```sh
swift test
```

Requires Xcode with Swift 6.1 or newer and targets macOS 15 or newer, using Swift 5
language mode. Dependencies are pinned in `Package.resolved`. There is no Xcode
project; the scripts use Xcode's asset compiler to package the icons.

Build a signed app bundle at `build/Leader Key.app` (release by default):

```sh
scripts/bundle.sh
scripts/bundle.sh --debug
open 'build/Leader Key.app'
```

Bundling defaults to ad-hoc signing. Set `IDENTITY` to an Apple Development signing
identity for a consistent identity across rebuilds. `VERSION` and `BUILD` override
the default version `0.0.1` and build number `1`.

Build, back up any installed app, install to `/Applications`, and launch:

```sh
security find-identity -v -p codesigning
IDENTITY='Apple Development: Your Name (TEAMID)' scripts/install-local.sh
```

The installer also accepts `--debug` and requires an explicit signing identity.
These scripts build for the current Mac; they do not notarize or publish releases.

Format or lint Swift sources directly:

```sh
swift format --parallel --in-place --recursive 'Leader Key' 'Leader KeyTests' Package.swift
swift format lint --parallel --strict --recursive 'Leader Key' 'Leader KeyTests' Package.swift
```
