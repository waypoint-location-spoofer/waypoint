# Renew the app after seven days

With a free Apple account, Apple's permission to run the installed app expires after seven days. Renewing it does not require paying for WayPoint.

## If you installed with Sideloadly

1. Connect your iPhone to the same computer and unlock it.
2. Open Sideloadly and select your iPhone.
3. Load **Waypoint-unsigned.ipa** and use the same Apple account as before.
4. Keep the same app identifier and installation settings. Click **Start** to install over the existing copy.
5. Open Waypoint from the iPhone's Home Screen and check that it connects.

Do not delete the app first. Keeping the same app identity helps preserve saved places and setup. Sideloadly can offer automatic refresh, but that needs a suitable running computer; these instructions use manual renewal.

## If you installed with Xcode

Connect the phone, open the project, select the same signing team and bundle identifier, and click **Run** again. Stop the Xcode run, then open Waypoint from the Home Screen.

## If renewal succeeds but connection fails

Signing and pairing are separate. You may need a new remote pairing file after an update, reset, or pairing failure. Repeat the pairing section in the [Windows](WINDOWS.md) or [Mac](MAC.md) guide, then import the new file in Waypoint.

[Apple's Personal Team limits](https://developer.apple.com/help/account/basics/about-your-developer-account)
