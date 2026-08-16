local wezterm = require 'wezterm'
local config = wezterm.config_builder()

--------------------------------------------------------------------------------
-- OS-Specific Configuration
--------------------------------------------------------------------------------
-- Windows-Specific Launch menu
--------------------------------------------------------------------------------
if wezterm.target_triple:find("windows") then
  config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
  config.integrated_title_buttons = { 'Hide', 'Maximize', 'Close' }
  config.integrated_title_button_style = "Windows"
  config.integrated_title_button_alignment = "Right"
  config.default_prog = { 'wsl.exe', '-d', 'NixOS', '--cd', '~' }
  config.font_size = 13.5


    config.launch_menu = {
    {
      label = 'NixOS stable',
      args = { 'wsl.exe', '-d', 'NixOS', '--cd', '~' },
    },
    {
      label = 'Ubuntu 24.04',
      args = { 'wsl.exe', '-d', 'Ubuntu_24.04', '--cd', '~' },
    },
    {
      label = 'Ubuntu 26.04',
      args = { 'wsl.exe', '-d', 'Ubuntu_26.04', '--cd', '~' },
    },
    {
      label = 'PowerShell',
      args = { 'powershell.exe', '-NoLogo' },
    },
  }

--------------------------------------------------------------------------------
-- Linux-Specific Launch menu
--------------------------------------------------------------------------------
elseif wezterm.target_triple:find("linux") then
  config.default_prog = { 'tmux', 'new-session', '-A', '-s', 'mgmt' }
  config.font_size = 16

  -- Keep Wayland enabled
  config.enable_wayland = true

  -- Completely disable title bar and window decorations
  config.window_decorations = "NONE"
  config.integrated_title_buttons = {}

  config.use_fancy_tab_bar = false
  config.enable_tab_bar = false
  config.enable_scroll_bar = false
end
--------------------------------------------------------------------------------
-- Performance & Low Latency
--------------------------------------------------------------------------------
config.front_end = "WebGpu"
config.webgpu_power_preference = "LowPower"
config.animation_fps = 1
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"
config.check_for_updates = false

--------------------------------------------------------------------------------
-- Appearance 
--------------------------------------------------------------------------------
config.color_scheme = 'Catppuccin Macchiato'

-- config.use_fancy_tab_bar = false
-- config.enable_tab_bar = true
-- config.enable_scroll_bar = true

config.scrollback_lines = 5000
config.audible_bell = "Disabled"
config.window_padding = {
  left = 6,
  right = 6,
  top = 6,
  bottom = 6,
}

--------------------------------------------------------------------------------
-- Font Configuration
--------------------------------------------------------------------------------
config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }

config.font = wezterm.font_with_fallback({
  { family = 'JetBrains Mono', weight = 'Regular' },
  { family = 'Symbols Nerd Font Mono' },
})

--------------------------------------------------------------------------------
-- Keybindings (Minimalist - Let tmux handle the rest)
--------------------------------------------------------------------------------
-- Keeping default OS pass-throughs; add full-screen toggles or font zoom if needed
config.keys = {
  -- Example: Toggle fullscreen window
  { key = 'F11', mods = 'NONE', action = wezterm.action.ToggleFullScreen },
}

-- Add platform-specific keys
if wezterm.target_triple:find("windows") then
  table.insert(config.keys, {
    key = 'i', mods = 'ALT', action = wezterm.action.ShowLauncher,
  })
end

return config
