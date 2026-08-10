local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

--------------------------------------------------------------------------------
-- OS-Specific Configuration
--------------------------------------------------------------------------------
if wezterm.target_triple:find("windows") then
  config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
  config.integrated_title_buttons = { 'Hide', 'Maximize', 'Close' }
  config.integrated_title_button_style = "Windows"
  config.integrated_title_button_alignment = "Right"
  config.default_prog = { 'wsl.exe', '-d', 'NixOS', '--cd', '~' }
config.font_size = 13.5
else
  config.window_decorations = "NONE"
config.font_size = 16
end

--------------------------------------------------------------------------------
-- Performance & Low Latency
--------------------------------------------------------------------------------
-- WebGpu provides cleaner rendering and broader hardware driver compatibility
config.front_end = "WebGpu"
config.webgpu_power_preference = "LowPower"

-- Disable animations to prevent unnecessary GPU redraw cycles
config.animation_fps = 1
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

-- Disable update/reload background checks for instant startup
config.check_for_updates = false

--------------------------------------------------------------------------------
-- Appearance & Window Layout
--------------------------------------------------------------------------------
config.color_scheme = 'Catppuccin Macchiato'

-- Tab bar setup
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.enable_scroll_bar = true

-- UI behavior
config.scrollback_lines = 5000
config.audible_bell = "Disabled"
config.window_padding = {
  left = 8,
  right = 8,
  top = 8,
  bottom = 8,
}

--------------------------------------------------------------------------------
-- Font Configuration
--------------------------------------------------------------------------------
-- Apply HarfBuzz feature flags globally for maximum rendering speed
config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }

config.font = wezterm.font_with_fallback({
  {
    family = 'JetBrains Mono',
    weight = 'Regular',
  },
  { family = 'Symbols Nerd Font Mono' },
})

--------------------------------------------------------------------------------
-- Keybindings
--------------------------------------------------------------------------------
config.keys = {
  -- Pane Splitting
  { key = 'mapped:+', mods = 'SHIFT|ALT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'mapped:_', mods = 'SHIFT|ALT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- Directional Pane Navigation
  { key = 'LeftArrow',  mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },
  { key = 'UpArrow',    mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'DownArrow',  mods = 'ALT', action = act.ActivatePaneDirection 'Down' },

  -- Directional Pane Resizing
  { key = 'LeftArrow',  mods = 'SHIFT|ALT', action = act.AdjustPaneSize { 'Left', 5 } },
  { key = 'RightArrow', mods = 'SHIFT|ALT', action = act.AdjustPaneSize { 'Right', 5 } },
  { key = 'UpArrow',    mods = 'SHIFT|ALT', action = act.AdjustPaneSize { 'Up', 5 } },
  { key = 'DownArrow',  mods = 'SHIFT|ALT', action = act.AdjustPaneSize { 'Down', 5 } },

  -- Quick Pane Zoom / Toggle Fullscreen Pane
  { key = 'z', mods = 'SHIFT|ALT', action = act.TogglePaneZoomState },

  -- Tab Management
  { key = 't', mods = 'SHIFT|ALT', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'SHIFT|ALT', action = act.CloseCurrentPane { confirm = true } },
}

return config
