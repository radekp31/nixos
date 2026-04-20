{lib, ...}: {
  options.programs.opencode.tui = lib.mkOption {
    type = lib.types.attrs;
    default = {};
    description = "OpenCode TUI configuration";
  };
}
