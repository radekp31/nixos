local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- OS specific
if wezterm.target_triple:find("windows") then
  config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
  config.integrated_title_buttons = { 'Hide', 'Maximize', 'Close' }
  config.integrated_title_button_style = "Windows"
  config.integrated_title_button_alignment = "Right"
  config.default_prog = { 'wsl.exe', '-d', 'NixOS', '--cd', '~' }
else
  config.window_decorations = "NONE"
end

-- Appearance
config.color_scheme = 'Catppuccin Macchiato'
config.font_size = 13.5
config.use_fancy_tab_bar = false
config.enable_scroll_bar = false
config.scrollback_lines = 5000
config.audible_bell = "Disabled"

-- Performance
config.front_end = "OpenGL"

-- Font
config.font = wezterm.font_with_fallback({
  {
    family = 'JetBrains Mono',
    weight = 'Regular',
    harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' },
  },
  'Symbols Nerd Font Mono',
})

-- Keymaps
config.keys = {
  { key = 'mapped:+', mods = 'SHIFT|ALT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'mapped:_', mods = 'SHIFT|ALT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = 'LeftArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },
  { key = 'UpArrow', mods = 'ALT', action = act.Activ
