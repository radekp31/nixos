#!/usr/bin/env bash

#this sends notification to current dekstop session:

#busctl --user call \
#  org.freedesktop.Notifications \
#  /org/freedesktop/Notifications \
#  org.freedesktop.Notifications \
#  Notify \
#  susssasa{sv}i \
#  -- "NixOS" 0 "" "Upgrade Ready" "Please reboot your system." 0 0 -1
#
#
#Also this works 
#busctl --user call \
#  org.freedesktop.Notifications \
#  /org/freedesktop/Notifications \
#  org.freedesktop.Notifications \
#  Notify \
#  susssasa{sv}i \
#  -- "NixOS" 0 "nix-snowflake" "Working!" "No more unfinished commands." 0 0 -1
 

# If SERVICE_RESULT is not set (like when running manually), default to "success"
# You can test failure by running: SERVICE_RESULT=fail ./notify.sh
RESULT=${SERVICE_RESULT:-success}

for SID in $(loginctl list-sessions --no-legend | awk '$6 != "manager" {print $1}'); do
    USER_NAME=$(loginctl show-session "$SID" -p Name --value)
    USER_ID=$(id -u "$USER_NAME")
    BUS="unix:path=/run/user/$USER_ID/bus"

    if [ "$RESULT" = "success" ]; then
        # SUCCESS TOAST
        sudo -u "$USER_NAME" DBUS_SESSION_BUS_ADDRESS=$BUS \
          busctl --user call \
            org.freedesktop.Notifications /org/freedesktop/Notifications \
            org.freedesktop.Notifications Notify \
            susssasa{sv}i \
            -- "NixOS" 0 "nix-snowflake" \
            "Update Successful" "System updated. Reboot to apply." \
            0 0 -1
    else
        # FAILURE TOAST 
        sudo -u "$USER_NAME" DBUS_SESSION_BUS_ADDRESS=$BUS \
          busctl --user call \
            org.freedesktop.Notifications /org/freedesktop/Notifications \
            org.freedesktop.Notifications Notify \
            susssasa{sv}i \
            -- "NixOS" 0 "nix-snowflake" \
            "Update Failed!" "Check journalctl -u nixos-upgrade" \
            0 0 -1
    fi
done
