# Fix a setup problem

## The computer cannot find my iPhone

Unlock the phone, reconnect the USB cable, and tap **Trust**. Try a different data cable or USB port. On Windows, check the Apple driver requirements on the Sideloadly website and the idevice_pair download page.

## The IPA will not open when I tap it

That is expected. Use Sideloadly on your computer to install it. If it is inside a ZIP, extract the ZIP first. Follow the [Windows](WINDOWS.md) or [Mac](MAC.md) guide.

## The app says it is not trusted or will not open

Check **Settings > General > VPN & Device Management** and trust your developer identity if prompted. Turn on **Settings > Privacy & Security > Developer Mode**. If it worked last week, [renew the app](RENEW.md).

## WayPoint cannot connect

Start on Wi-Fi, keep the phone unlocked, and check that LocalDevVPN is connected. Another VPN may conflict. Open **Setup > Connect and prepare** and wait for it to finish.

If the error mentions pairing, `public_key`, or the file format, create a fresh **Remote pairing** file. A Lockdown file will not work. Import the new file in Setup. Leave advanced address and port settings at their defaults unless you intentionally changed your LocalDevVPN configuration.

## It fails after I turn mobile data off

Turn data back on. Complete the first Wi-Fi setup, then download the support files before retrying the [cellular steps](../CELLULAR-TEST.md). Cellular use is experimental and may fail on your phone.

## My real location has not returned

Keep LocalDevVPN connected, reopen WayPoint, and tap **Restore real location**. If needed, reconnect from Setup and try again. If it still fails, restart the iPhone and check Apple Maps. Closing WayPoint alone does not confirm a restore.

## It stops working when I lock the phone

iOS can suspend the app or interrupt its connection. Reopen LocalDevVPN and WayPoint, reconnect, and check the location again. Reliable locked-screen operation has not been verified.

## Report a problem

Open an issue in this repository. Include the step that failed, the visible error, your iPhone model, iOS version, and whether you used Wi-Fi or cellular. Never upload your pairing file, Apple password, or unedited logs containing private information. Hide personal details in screenshots.
