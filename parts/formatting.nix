{ inputs, ... }: {
  perSystem = { pkgs, ... }: {
    # flake-parts naturally exposes 'formatter' and 'checks' at the system level
    formatter = (inputs.treefmt-nix.lib.evalModule pkgs {
      imports = [ ../treefmt.nix ];
      programs.alejandra.package = pkgs.alejandra;
    }).config.build.wrapper;

    checks.formatting = (inputs.treefmt-nix.lib.evalModule pkgs {
      imports = [ ../treefmt.nix ];
      programs.alejandra.package = pkgs.alejandra;
    }).config.build.check inputs.self;
  };
}
