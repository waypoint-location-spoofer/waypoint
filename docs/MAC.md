# Set up on Mac

You need your iPhone, its USB cable, your Apple account, and Wi-Fi. You do not need Xcode for these steps.

## 1. Download the app and installer

1. Open [WayPoint Releases](https://github.com/waypoint-location-spoofer/waypoint/releases). Under **Assets**, download **Waypoint-unsigned.ipa**. Do not choose Source code.
2. Download the Mac version of [Sideloadly](https://sideloadly.io/). Install and open it using the instructions on its website.

If your download is **Waypoint-IPA.zip**, double-click it and use the `.ipa` file inside.

## 2. Install on your iPhone

1. Connect the iPhone by USB. Unlock it and tap **Trust** if asked. If Finder also asks you to trust the phone, accept there too.
2. In Sideloadly, select your iPhone as the device. Drag **Waypoint-unsigned.ipa** into the app.
3. Enter your Apple account and click **Start**. Complete any Apple sign-in prompts.
4. Wait for installation to finish. Waypoint should appear on your iPhone's Home Screen.
5. If iOS says the developer is not trusted, open **Settings > General > VPN & Device Management**, select your Apple account, and trust it.
6. Open **Settings > Privacy & Security > Developer Mode**. Turn it on, restart if asked, and confirm after the restart. If the option is missing, check again after installation.

## 3. Create a pairing file

This file lets WayPoint connect to your own phone. Keep it private.

1. Download [idevice_pair for Mac](https://github.com/jkcoxson/idevice_pair/releases/latest/download/idevice_pair--macos-universal.dmg). Open the download, drag the app to **Applications**, then open it.
2. Keep the iPhone connected and unlocked. Select it in the device list.
3. Choose **Remote pairing**, not Lockdown. Click **Create**, or **Load** if a remote record already exists. Use **Validate** if offered.
4. Click **Save to file** and save the file somewhere you can find it.
5. AirDrop the file to your iPhone and save it in **Files**. You can also put it in your own iCloud Drive and open **Files > Browse > iCloud Drive** on the phone. Do not share it publicly.

Now follow **[Finish setup on your iPhone](IPHONE-SETUP.md)**. Keep the cable connected until that guide tells you to disconnect.

Prefer to build the code yourself? Use the separate [Xcode guide](BUILD.md). With either method, a free Apple account needs [weekly renewal](RENEW.md).
