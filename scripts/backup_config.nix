{ config, pkgs, ...}:

{

	environment.etc."nixos/scripts/upload-dotfiles.sh".text = ''
	  #!/usr/bin/env bash
	  cd ${dotfilesDir}

	  # Initialize the repository if .git does not exist
	  if [ ! -d .git ]; then
	    ${pkgs.git}/bin/git init
	    ${pkgs.git}/bin/git remote add origin ${gitHubRepo}

	    # Ensure there is an initial commit, even if the directory is empty
	    ${pkgs.git}/bin/git add .
	    ${pkgs.git}/bin/git commit -m "Initial commit" || true
	  fi

	  # Create or switch to the auto-update branch
	  ${pkgs.git}/bin/git checkout -B auto-update

	  # Add any new changes, commit, and push to the auto-update branch
	  ${pkgs.git}/bin/git add .
	  ${pkgs.git}/bin/git commit -m "Auto-update: $(date)" || true

	  # Run git push and capture stderr output
	  git_push_status=$(sudo -u radekp ${pkgs.git}/bin/git push -u origin auto-update 2>/tmp/nixos_backup_error.>

	  # Check if stderr is empty
	  if [ $? -eq 0 ]; then
	  # If no error, display a success notification
	  sudo -u $(who | awk '{print $1}' | sort | uniq) DISPLAY=:0 dunstify -u normal -t 2500 "NixOS config backup>

	  else

	  # If there's an error, display a critical notification
	  sudo -u $(who | awk '{print $1}' | sort | uniq) DISPLAY=:0 dunstify -u critical -t 2500 "NixOS config back>
	  fi
	  '';
};
