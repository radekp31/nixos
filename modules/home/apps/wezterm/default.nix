{...}: {
  #move to separate module
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    extraConfig = ''
      local wezterm = require 'wezterm'
      local act = wezterm.action
      local config = {}

      if wezterm.config_builder
      then
        config = wezterm.config_builder()
        config:set_strict_mode(true)
      end

      -- General settings

      config.max_fps = 144
      config.animation_fps = 144
      config.webgpu_power_preference = "HighPerformance"
      config.audible_bell = "Disabled"

      -- Appearance
        config.color_scheme = 'Dracula (Official)'
      config.window_decorations = "RESIZE"
      config.use_fancy_tab_bar = false
      config.window_frame = {
        font_size = 16.5
      }
        config.font_size = 16
        config.window_decorations = "NONE"
        config.use_fancy_tab_bar = false
        config.enable_scroll_bar = false
        config.scrollback_lines = 3000

        -- Performance & Rendering
        config.front_end = "OpenGL"

        -- FONT
        config.font = wezterm.font_with_fallback({
          {
            family = 'JetBrains Mono',
            weight = 'Regular',
            -- Disabling harfbuzz features (ligatures) drastically speeds up rendering
            harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }
          },
          'Symbols Nerd Font Mono', -- Fallback for icons
        })

       -- Lazy loading

       config.tab_bar_at_bottom = false
       config.scrollback_lines = 5000 -- Limit scrollback to reduce memory
       config.enable_scroll_bar = false -- Disable scroll bar for performance
       config.harfbuzz_features = {} -- Minimal font features initially

      -- Keymaps
      config.keys = {

        -- Pane splitting
        {
          key = 'mapped:+',
          mods = 'SHIFT|ALT',
          action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
        },
        {
          key = 'mapped:_',
          mods = 'SHIFT|ALT',
          action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
        },
        -- Pane focus movement
        {
          key = 'LeftArrow',
          mods = 'ALT',
          action = act.ActivatePaneDirection 'Left'
        },
        {
          key = 'RightArrow',
          mods = 'ALT',
          action = act.ActivatePaneDirection 'Right'
        },
        {
          key = 'UpArrow',
          mods = 'ALT',
          action = act.ActivatePaneDirection 'Up'
        },
        {
          key = 'DownArrow',
          mods = 'ALT',
          action = act.ActivatePaneDirection 'Down'
        },

        -- Pane movement
        {
          key = 'LeftArrow',
          mods = 'SHIFT|ALT',
          action = act.RotatePanes 'CounterClockwise',
        },
        { key = 'RightArrow',
          mods = 'SHIFT|ALT',
          action = act.RotatePanes 'Clockwise'
        },

        -- Lanch launch_menu
        {
          key = 'l',
          mods = 'ALT',
          action = wezterm.action.ShowLauncher
        },
      }

      -- Right click Copy

      config.mouse_bindings = {
        {
         event = { Down = { streak = 1, button = "Right" } },
         mods = "NONE",
         action = wezterm.action_callback(function(window, pane)
           local has_selection = window:get_selection_text_for_pane(pane) ~= ""
           if has_selection then
             window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
             window:perform_action(act.ClearSelection, pane)
           else
             window:perform_action(act({ PasteFrom = "Clipboard" }), pane)
           end
         end),
        },
       }

      -- Adding lanch menu items
      config.launch_menu = {
        {
          -- Optional label to show in the launcher. If omitted, a label
          -- is derived from the `args`
          -- label = 'PowerShell',
          -- The argument array to spawn.  If omitted the default program
          -- will be used as described in the documentation above

          -- args = { 'pwsh.exe' },

          -- You can specify an alternative current working directory;
          -- if you don't specify one then a default based on the OSC 7
          -- escape sequence will be used (see the Shell Integration
          -- docs), falling back to the home directory.

          -- cwd = { 'C:\\' },

          -- You can override environment variables just for this command
          -- by setting this here.  It has the same semantics as the main
          -- set_environment_variables configuration option described above
          -- set_environment_variables = { FOO = "bar" },
        }
      }
      return config
    '';
  };
}
