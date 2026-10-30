# Use WayPoint on mobile data

**This is experimental.** First make sure start and restore both work on Wi-Fi using the [iPhone setup guide](docs/IPHONE-SETUP.md). Cellular use has not been verified on iOS 27.0.1.

## Prepare while you have internet

1. In Waypoint, open **Setup > Download support for cellular use**. Wait until the files are saved.
2. Make sure you have already completed **Connect and prepare** and the first start/restore test on Wi-Fi. Downloading the files alone does not finish setup.
3. Keep LocalDevVPN connected. Select the place you want while map search has internet.

## Start without Wi-Fi

1. Turn Wi-Fi off in the iPhone's Settings. The computer can stay switched off.
2. In Waypoint's **Location** tab, tap **Cellular start**.
3. Open Control Center, turn **Cellular Data off**, wait about two seconds, and return to Waypoint.
4. Tap **Data is off · connect and apply**. Wait until Waypoint tells you to restore data.
5. Turn **Cellular Data on** again. Leave Wi-Fi off and return to Waypoint.
6. Tap **Data is back on · verify connection**. Wait for the result, then check your location in Apple Maps.
7. Return to Waypoint, choose a different place, and tap **Apply new location** with cellular data still on. Check Maps again.
8. Tap **Restore real location** and check that your real position returns.

The second location change checks that the connection still works after mobile data comes back. A connected VPN icon alone does not prove that it works.

If a step fails or you cancel, turn Cellular Data back on. Check LocalDevVPN and retry only after the first Wi-Fi setup works. If the connection is lost later, you may need to repeat these steps. See [Troubleshooting](docs/TROUBLESHOOTING.md) if your real location does not return.
