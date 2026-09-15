# Every constant this configuration repeats lives here, and only here.
#
# This module DECLARES the options and their defaults. It sets no host value.
# Each hosts/<host>/variables.nix sets only what that host overrides.
# hosts/common/default.nix imports this file, so every host has every option
# and no consumer needs to guard the read.
{
  lib,
  config,
  ...
}: {
  options.my = {
    user = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "radekp";
        description = "The login name of the primary user.";
      };

      fullName = lib.mkOption {
        type = lib.types.str;
        default = "Radek Polasek";
        description = "The full name of the primary user. One name for every identity.";
      };

      email = lib.mkOption {
        type = lib.types.str;
        default = "polasek.31@seznam.cz";
        description = "The personal email address of the primary user.";
      };

      workEmail = lib.mkOption {
        type = lib.types.str;
        default = "radek.polasek@dynatrace.com";
        description = "The work email address of the primary user.";
      };

      home = lib.mkOption {
        type = lib.types.str;
        default = "/home/${config.my.user.name}";
        defaultText = lib.literalExpression ''"/home/''${config.my.user.name}"'';
        description = "The home directory of the primary user. Derived from the name.";
      };
    };

    repo = {
      owner = lib.mkOption {
        type = lib.types.str;
        default = "radekp31";
        description = "The GitHub account that owns this configuration.";
      };

      name = lib.mkOption {
        type = lib.types.str;
        default = "nixos";
        description = "The GitHub repository name of this configuration.";
      };

      url = lib.mkOption {
        type = lib.types.str;
        default = "https://github.com/${config.my.repo.owner}/${config.my.repo.name}.git";
        defaultText = lib.literalExpression ''"https://github.com/''${config.my.repo.owner}/''${config.my.repo.name}.git"'';
        description = "The clone URL of this configuration. Derived from the owner and the name.";
      };
    };

    theme.catppuccin = lib.mkOption {
      # 'latte', 'frappe' and 'mocha' do not work in foot.
      type = lib.types.enum ["latte" "frappe" "macchiato" "mocha"];
      default = "macchiato";
      description = "The Catppuccin flavor for this host.";
    };
  };
}
