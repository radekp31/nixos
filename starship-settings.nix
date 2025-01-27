# starship-settings.nix

{
  settings = {
    add_newline = false;
    format = [
      ""
      "
      $username\
      $hostname\
      $directory\
      $git_branch\
      $git_state\
      $git_status\
      $cmd_duration\
      $line_break\
      $python\
      $character"
      ""
    ];
    scan_timeout = 10;
    character = {
      success_symbol = "[ ](bold green)";
      error_symbol = "[ ](red)";
    };
    continuation_prompt = "[ ](bold green)";
    directory = {
      style = "purple";
    };
    git_branch = {
      format = "[$branch]($style)";
      style = "bright-black";
    };
    git_status = {
      format = " ($ahead_behind$stashed)]($style)";
      style = "cyan";
      conflicted = "​";
      untracked = "​";
      modified = "​";
      staged = "​";
      renamed = "​";
      deleted = "​";
      stashed = "≡";
    };
    git_state = {
      format = "\\([$state( $progress_current/$progress_total)]($style)\\) ";
      style = "bright-black";
    };
    cmd_duration = {
      format = "[$duration]($style) ";
      style = "yellow";
    };
    python = {
      format = "[$virtualenv]($style) ";
      style = "bright-black";
    };
  };
}

