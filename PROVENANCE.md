# Source, credits, and build status

WayPoint is a modified version of [StikDebug](https://github.com/StikDebug/StikDebug), based on commit `17b1e1d90d602a228de663a10efa987a9f9e547b` (version 3.1.15).

The original copyright notices and [AGPL-3.0 license](LICENSE) are retained. WayPoint modifications are also AGPL-3.0. The [upstream README](UPSTREAM-README.md) is kept for attribution and historical reference; use this project's setup guides for WayPoint.

## Dependencies

- The native library and header are unchanged from the pinned StikDebug commit. They are based on [idevice](https://github.com/jkcoxson/idevice). The exact Rust revision and build recipe for that prebuilt archive have not been reconstructed here.
- Swift package versions are recorded in `StikDebug.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.
- Original upstream images and icons are retained. This is not an official StikDebug release.

## Changes in WayPoint

- Location screen with map search, coordinates, saved places, start, change, and restore controls.
- Setup screen with manual remote pairing import and developer support preparation.
- Serialized location commands, refresh handling, and recovery after interrupted sessions.
- Experimental cellular flow with a manual data toggle and a fresh connection check after data returns.
- App name, bundle identifier defaults, build scripts, and setup guides.
- Twelve behavioral tests using a fake backend.

## What has been checked

Swift syntax and Xcode project structure were checked on Windows. Plist, XML, and JSON files were parsed, and build-script syntax was checked. These checks do not replace Swift compilation or device testing.

On October 29, 2026, a GitHub Actions macOS build succeeded. The supplied IPA matches that run's artifact by SHA-256. It identifies itself as version 0.2.0, build 1, with minimum iOS 17.4, built using Xcode 26.6 and the iOS 26.5 SDK. Publication preparation changes documentation, ignore rules, and checksums, not app source or build inputs.

Signing, installation, test execution, location changes, restoration, locked-screen behavior, and iOS 27.0.1 compatibility have not been independently tested. Cellular use remains experimental.

## Cellular research

[Geovo's guide](https://geovo.app/guides/cellular-and-airplane-mode) describes briefly disabling cellular data when starting a session. [Wander](https://github.com/faisal-nabulsi/Wander) describes retaining a developer session after restoring connectivity. [LocalDevVPN issue 31](https://github.com/jkcoxson/LocalDevVPN/issues/31) reports cellular connection problems. These are reports from other projects, not proof of WayPoint compatibility. No Wander or Vanish code was copied.
