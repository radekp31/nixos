
      if [ $(ls -A /media/WDRED/OneDrive | wc -l) -eq 0 ]; then
      nohup rclone cmount --vfs-cache-mode writes onedrive: /media/WDRED/OneDrive > /dev/null 2>&1 < /dev/null &! disown > /dev/null 2>&1
      fi
