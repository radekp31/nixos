{
  pkgs,
  ...
}: {
  programs.dircolors = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -alFh";
    };
    sessionVariables = {
      C = "/mnt/c";
    };
    bashrcExtra = ''
      export C='/mnt/c'
      export NIXPKGS_ALLOW_UNFREE=1
      export EDITOR='nvim'
      export VISUAL='nvim'
      export C='/mnt/c'

      fastfetch --config ${pkgs.fastfetch}/share/fastfetch/presets/examples/3.jsonc

      nixpush() {
         local message="$1"

         # Format
         nix fmt && git add -A

         if git diff --cached --quiet; then
           echo "✅ No changes to commit"
           return 0
         fi

         # Count unpushed commits
         local unpushed=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo "0")

         if [ "$unpushed" -gt 0 ]; then
           # Squash all unpushed commits + new changes
           echo "🔄 Squashing $unpushed unpushed commit(s) + new changes..."
           git reset --soft @{upstream} 2>/dev/null || {
             echo "⚠️  No upstream branch, creating fresh commit..."
             git reset --soft HEAD~''${unpushed}
           }
           git commit -m "$message"
           echo "✅ Force pushing..."
           git push --force-with-lease
         else
           # Normal push (first commit or already pushed)
           echo "✅ Creating new commit..."
           git commit -m "$message" && git push
         fi
       }

      parse_git_branch() {
          # Quick check if we're in a git repo
          git rev-parse --is-inside-work-tree &>/dev/null || return

          local branch=$(git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
          if [ -n "$branch" ]; then
            # Check for changes with 200ms timeout
            if timeout 0.2s git diff --quiet 2>/dev/null && timeout 0.2s git diff --cached --quiet 2>/dev/null; then
              echo "($branch)"
            else
              echo "($branch*)"
            fi
          fi
        }

        PS1='\[\033[01;36m\]\u\[\033[00m\]@\[\033[01;32m\]\h\[\033[00m\] \[\033[01;34m\]\w\[\033[00m\] \[\033[01;33m\]$(parse_git_branch)\[\033[00m\]\n\[\033[01;31m\]\$\[\033[00m\] '
      ## GENERAL OPTIONS ##

      # Prevent file overwrite on stdout redirection
      # Use `>|` to force redirection to an existing file
      set -o noclobber

      # Update window size after every command
      shopt -s checkwinsize

      # Automatically trim long paths in the prompt (requires Bash 4.x)
      PROMPT_DIRTRIM=2

      # Enable history expansion with space
      # E.g. typing !!<space> will replace the !! with your last command
      bind Space:magic-space

      # Turn on recursive globbing (enables ** to recurse all directories)
      shopt -s globstar 2> /dev/null

      ## SMARTER TAB-COMPLETION (Readline bindings) ##

      # Perform file completion in a case insensitive fashion
      bind "set completion-ignore-case on"

      # Treat hyphens and underscores as equivalent
      bind "set completion-map-case on"

      # Display matches for ambiguous patterns at first tab press
      bind "set show-all-if-ambiguous on"

      # Immediately add a trailing slash when autocompleting symlinks to directories
      bind "set mark-symlinked-directories on"

      ## SANE HISTORY DEFAULTS ##

      # Append to the history file, don't overwrite it
      shopt -s histappend

      # Save multi-line commands as one command
      shopt -s cmdhist

      # Record each line as it gets issued
      PROMPT_COMMAND='history -a'

      # Huge history. Doesn't appear to slow things down, so why not?
      HISTSIZE=500000
      HISTFILESIZE=100000

      # Avoid duplicate entries
      HISTCONTROL="erasedups:ignoreboth"

      # Don't record some commands
      export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"

      # Use standard ISO 8601 timestamp
      # %F equivalent to %Y-%m-%d
      # %T equivalent to %H:%M:%S (24-hours format)
      HISTTIMEFORMAT='%F %T '

      # Enable incremental history search with up/down arrows
      bind '"\e[A": history-search-backward'
      bind '"\e[B": history-search-forward'
      bind '"\e[C": forward-char'
      bind '"\e[D": backward-char'

      ## BETTER DIRECTORY NAVIGATION ##

      # Prepend cd to directory names automatically
      shopt -s autocd 2> /dev/null
      # Correct spelling errors during tab-completion
      shopt -s dirspell 2> /dev/null
      # Correct spelling errors in arguments supplied to cd
      shopt -s cdspell 2> /dev/null

      # This defines where cd looks for targets
      # Add the directories you want to have fast access to, separated by colon
      # Ex: CDPATH=".:~:~/projects" will look for targets in the current working directory, in home and in the ~/projects folder
      CDPATH="."

      # This allows you to bookmark your favorite places across the file system
      # Define a variable containing a path and you will be able to cd into it regardless of the directory you're in
      shopt -s cdable_vars
    '';
  };
}
