{pkgs, ...}: {
  home.packages = with pkgs; [
    powershell
    fzf
    oh-my-posh
  ];

  xdg.configFile."powershell/Microsoft.PowerShell_profile.ps1".text = ''
    # Load PSReadLine before tools that configure its key handlers
    Import-Module PSReadLine

    # Install Oh-my-Posh: https://ohmyposh.dev/docs/installation
    # Initialize Oh My Posh
    oh-my-posh init pwsh --eval --config 'powerlevel10k_lean' |
        Invoke-Expression

    # Initialize PSFzf
    Import-Module PSFzf

    Set-PsFzfOption `
        -PSReadlineChordProvider 'Ctrl+t' `
        -PSReadlineChordReverseHistory 'Ctrl+r' `
        -TabCompletionPreviewWindow 'hidden|down|right|hidden'

    function Invoke-HybridTabCompletion {
        $line = $null
        $cursor = 0

        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState(
            [ref]$line,
            [ref]$cursor
        )

        $textBeforeCursor = $line.Substring(0, $cursor)

        # Keep native semantic completion outside command position.
        if ($textBeforeCursor -notmatch '^\s*\S*$') {
            [Microsoft.PowerShell.PSConsoleReadLine]::Complete()
            return
        }

        $completion = [System.Management.Automation.CommandCompletion]::CompleteInput(
            $line,
            $cursor,
            $null
        )

        $matches = @($completion.CompletionMatches)

        if ($matches.Count -eq 0) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Ding()
            return
        }

        # Avoid opening fzf when PowerShell found exactly one candidate.
        if ($matches.Count -eq 1) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
                $completion.ReplacementIndex,
                $completion.ReplacementLength,
                $matches[0].CompletionText
            )
            return
        }

        $selectedText = $matches |
            ForEach-Object { $_.ListItemText } |
            Invoke-Fzf -Prompt 'Command> '

        # Escape leaves the existing command line unchanged.
        if ([string]::IsNullOrWhiteSpace($selectedText)) {
            return
        }

        $selectedMatch = $matches |
            Where-Object { $_.ListItemText -eq $selectedText } |
            Select-Object -First 1

        if ($null -eq $selectedMatch) {
            return
        }

        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
            $completion.ReplacementIndex,
            $completion.ReplacementLength,
            $selectedMatch.CompletionText
        )
    }

    # Hybrid Tab behavior:
    # - Command position: fuzzy selection
    # - Parameters, values, and paths: native completion
    Set-PSReadLineKeyHandler `
        -Key Tab `
        -ScriptBlock { Invoke-HybridTabCompletion }

    # Explicit PSFzf completion for any token
    Set-PSReadLineKeyHandler `
        -Key 'Ctrl+Spacebar' `
        -ScriptBlock { Invoke-FzfTabCompletion }

  '';
}
