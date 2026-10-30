# Finish setup on your iPhone

Start here after the [Windows](WINDOWS.md) or [Mac](MAC.md) guide. Waypoint should be installed, Developer Mode should be on, and your pairing file should be available in Files.

## Connect for the first time

1. Connect your iPhone to Wi-Fi.
2. Install [LocalDevVPN from the App Store](https://apps.apple.com/us/app/localdevvpn/id6755608044). Open it, allow it to add its VPN configuration, and connect. Keep it connected while using WayPoint.
3. Open **Waypoint** from your Home Screen. Go to **Setup > Import pairing file** and select the file you saved.
4. Tap **Connect and prepare**. Allow local network access if asked. The first download can take several minutes. Wait for **Developer connection ready** and **Location service prepared**.

## Check that it works

1. Open the **Location** tab. Search for a place or tap the map.
2. Tap **Start simulation**. Open Apple Maps and check your location.
3. Return to WayPoint. Tap **Restore real location** and check Maps again. It may take a little time to get a fresh GPS position.
4. If both checks work, disconnect the cable and switch off the computer. Repeat the start and restore checks from your phone.

The app is designed to work without a running computer after setup. This release still needs testing on real phones, so verify both checks before relying on it.

## Each time you use it

Keep LocalDevVPN connected. Open WayPoint, choose a place, and tap **Start simulation**. To change places, choose another location and tap **Apply new location**. Moving the pin by itself does not change your phone's location.

When finished, tap **Restore real location**. Closing the app is not a confirmed restore.

For mobile data, follow the [cellular guide](../CELLULAR-TEST.md). For problems, use [Troubleshooting](TROUBLESHOOTING.md).

Some version 0.2 screens mention a Mac even when you installed from Windows. The same pairing and connection steps apply. The computer may be needed again for weekly renewal or to replace an expired pairing file.
