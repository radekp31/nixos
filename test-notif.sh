busctl --user call \
  org.freedesktop.Notifications \
  /org/freedesktop/Notifications \
  org.freedesktop.Notifications \
  Notify \
  susssasa{sv}i \
  -- "NixOS" 0 "nix-snowflake" "Working!" "No more unfinished commands." 0 0 -1
