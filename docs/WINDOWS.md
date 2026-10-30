# Set up on Windows

You need your iPhone, its USB cable, your Apple account, and Wi-Fi. Keep the phone unlocked during setup.

## 1. Download the app and installer

1. Open [WayPoint Releases](https://github.com/waypoint-location-spoofer/waypoint/releases). Under **Assets**, download **Waypoint-unsigned.ipa**. Do not choose Source code.
2. Download the Windows version of [Sideloadly](https://sideloadly.io/). Install and open it.
3. Install the Apple drivers or iTunes components listed in Sideloadly's Windows instructions. The pairing tool also lists [Apple's Windows iTunes download](https://apple.com/itunes/download/win64) as a requirement.

If your download is **Waypoint-IPA.zip**, right-click it, choose **Extract All**, and use the `.ipa` file inside.

## 2. Install on your iPhone

1. Connect the iPhone by USB. Unlock it and tap **Trust** if asked.
2. In Sideloadly, select your iPhone. Drag **Waypoint-unsigned.ipa** into the app.
3. Enter your Apple account and click **Start**. Complete any Apple sign-in prompts. Use your own account, not the app creator's.
4. Wait for installation to finish. Waypoint should appear on your iPhone's Home Screen.
5. If iOS says the developer is not trusted, open **Settings > General > VPN & Device Management**, select your Apple account, and trust it.
6. Open **Settings > Privacy & Security > Developer Mode**. Turn it on, restart if asked, and confirm after the restart. If the option is missing, check again after installation.

## 3. Create a pairing file

This file lets WayPoint connect to your own phone. Keep it private.

1. Download and open [idevice_pair for Windows](https://github.com/jkcoxson/idevice_pair/releases/latest/download/idevice_pair--windows-x86_64.exe).
2. Keep the iPhone connected and unlocked. Select it in the device list.
3. Choose **Remote pairing**, not Lockdown. Click **Create**, or **Load** if a remote record already exists. Use **Validate** if offered.
4. Click **Save to file** and save the file somewhere you can find it.
5. Upload it to your own iCloud Drive using [iCloud.com](https://www.icloud.com/iclouddrive/). On your iPhone, open **Files > Browse > iCloud Drive** and check that the file appears. Do not create a public sharing link.

Now follow **[Finish setup on your iPhone](IPHONE-SETUP.md)**. Keep the cable connected until that guide tells you to disconnect.

If the phone is not detected, see [Troubleshooting](TROUBLESHOOTING.md). You will need to [renew the app weekly](RENEW.md) with a free Apple account.
