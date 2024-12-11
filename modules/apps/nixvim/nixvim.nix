{config, pkgs, lib, input, ...}:

let

        nixvim = import (builtins.fetchGit {
          url = "https://github.com/nix-community/nixvim";
          ref = "nixos-24.05";
        });

        get_bufnrs.__raw = ''
          function()
            local buf_size_limit = 1024 * 1024
            local bufs = vim.api.nvim_list_bufs()
            local valid_bufs = {}
            for _, buf in ipairs(bufs) do
              if vim.api.nvim_buf_is_loaded(buf) and vmi.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf)) < buf_size_limit then table.insert(valid_bufs, buf)
              end
            end
            return valid_bufs
          end
        '';
  in

{

  imports = [
    nixvim.nixosModules.nixvim
  ];

    programs.nixvim = {
  #Includes functions get_bufnrs
    enable = true;
    colorschemes.tokyonight.enable = true;
    plugins.lualine.enable = true;
    clipboard = {
      register = "unnamedplus";
      providers.xclip.enable = true;
    };
    plugins = {
     lsp = {
       enable = true;
       servers = {
         nixd = {
           enable = true;
           settings = {
             formatting.command = [ "nixpkgs-fmt" ];
             nixpkgs.expr = "import <nixpkgs> { }";
           };
         };
       };
     };

     lspkind = {
       enable = true;
       cmp = {
         enable = true;
         menu = {
           buffer = "[buffer]";
           nvim_lsp = "[LSP]";
           path = "[path]";
         };
       };
     };
      cmp = {
        enable = true;
        autoEnableSources = true;
          settings = {
          sources  = [
          {
            name = "nvim_lsp";
            priority = 1000;
            option = {
              inherit get_bufnrs;
            };
          
          }
          {
            name = "nixd";
            priority = 1000;
            option = {
              inherit get_bufnrs;
            };
          }
          {
            name = "buffer";
          }
          ];
          mapping = {
            "<C-Left>" = "cmp.mapping.select_prev_item()";
            "<C-Right>" = "cmp.mapping.select_next_item()";
            "<C-Esc>" = "cmp.mapping.abort()";
            "<C-CR>" = "cmp.mapping.confirm({select = true})";
            "<C-Space>" = "cmp.mapping(cmp.mapping.complete(), { \"i\", \"c\" })";
            "<C-Up>" = "cmp.mapping.scroll_docs(4)";
            "<C-Down>" = "cmp.mapping.scroll_docs(-4)";
          };
        };
      };
      cmp-buffer = {
        enable = true;
      };
      treesitter = {
        enable = true;
      };
    };  
    extraPlugins = [
      pkgs.vimPlugins.nvim-lspconfig
    ];
    extraPackages = [ pkgs.wl-clipboard pkgs.xsel ];
    };



}
