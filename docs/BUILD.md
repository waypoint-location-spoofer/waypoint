# Build from source on a Mac

Most users should follow the [Mac IPA guide](MAC.md). These steps are for people who want to compile the source with Xcode.

1. Install Xcode from the Mac App Store. Open it once and finish installing its components. Use a version that supports your iPhone's iOS version.
2. Download the source ZIP from this project's release and extract it.
3. Open **StikDebug.xcodeproj**. The project keeps its original internal name; the installed app is called Waypoint.
4. In **Xcode > Settings > Accounts**, add your Apple account.
5. Select the blue project, then the **StikDebug** app target. Under **Signing & Capabilities**, enable automatic signing and choose your team.
6. Set a unique bundle identifier, for example `dev.waypoint.yourchosenalias`. Keep it the same for future installs.
7. Connect and unlock your iPhone. Trust the computer, enable Developer Mode if prompted, and select the iPhone as the run destination.
8. Click **Run**. After installation, stop the Xcode run and open Waypoint directly from the phone's Home Screen.
9. Follow the pairing section of the [Mac guide](MAC.md), then [iPhone setup](IPHONE-SETUP.md).

## Build an unsigned IPA

On a Mac with Xcode installed, open Terminal in the extracted source folder and run:

```sh
bash "Build IPA.command"
```

The script puts the unsigned IPA inside a new folder under `build/`. Sign it before installing. Do not distribute your signing certificate, provisioning profile, or pairing file with it.

To build using GitHub instead, open **Actions > Build Waypoint IPA > Run workflow** in your own copy of the repository. After it succeeds, download **Waypoint-IPA** from the run's Artifacts section and extract it. No Apple signing secrets are needed. GitHub artifact downloads require signing in; public releases are the normal download route for users.

## Tests and build status

The original version 0.2.0 IPA was built successfully in GitHub Actions with Xcode 26.6 and the iOS 26.5 SDK. This does not verify iOS 27 compatibility or on-device behavior.

There are 12 Waypoint behavioral tests using a fake backend. They have not been executed here. Select a connected iPhone and run **WaypointTests** in Xcode's Test navigator; set the test target's signing team if needed. The bundled native library targets real iOS devices, so the simulator is not the supported test path.

Before marking a release stable, test location start, a second location, restore, cable removal, locked-screen behavior, VPN interruption, app relaunch, and signing renewal. Test cellular separately using CELLULAR-TEST.md.
