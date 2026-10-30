# WayPoint

Choose a location on your iPhone, change it, and restore your real location when you are done.

**Experimental release:** the app builds successfully. Installation, location changes, and cellular use still need testing on real phones, including iOS 27.0.1.

## Get started

1. Open [Releases](https://github.com/waypoint-location-spoofer/waypoint/releases) and download **Waypoint-unsigned.ipa** under **Assets**. This is the app file. You do not need the source ZIP to install it.
2. Follow the guide for your computer: **[Windows](docs/WINDOWS.md)** or **[Mac](docs/MAC.md)**.
3. Finish [the iPhone setup](docs/IPHONE-SETUP.md).

You need an iPhone, a USB cable, a Mac or Windows computer, and your own Apple account. Use Wi-Fi for the first setup. No paid Apple developer account is needed for personal signing.

The computer is needed to install and renew the app. Once setup works, the app is designed to run with the computer disconnected and switched off. Free Apple signing lasts seven days, so plan to reconnect and renew weekly. Reboots or updates may also require pairing again.

## Using the app

Open **Location**, choose a place, then tap **Start simulation**. To move again, select another place and tap **Apply new location**. Tap **Restore real location** when finished. Keep LocalDevVPN connected and check the result in Apple Maps.

Using mobile data? Read the [cellular guide](CELLULAR-TEST.md) after the Wi-Fi setup works.

## Help and source code

- [Fix a setup problem](docs/TROUBLESHOOTING.md)
- [Renew the app after seven days](docs/RENEW.md)
- [Build from source with Xcode](docs/BUILD.md)
- [License and credits](PROVENANCE.md)

WayPoint is based on [StikDebug](https://github.com/StikDebug/StikDebug) and uses [idevice](https://github.com/jkcoxson/idevice). The code is licensed under [AGPL-3.0](LICENSE). This project is not affiliated with Apple or the upstream projects.
