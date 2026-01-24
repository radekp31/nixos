{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: {
  imports = [
    #nixvim.nixosModules.nixvim
    inputs.nixvim.nixosModules.nixvim
  ];

  programs.nixvim = {
    #Includes functions get_bufnrs
    enable = true;
    keymaps = [
      {
        mode = "n";
        key = "gl";
        action = "<cmd>lua vim.diagnostic.open_float()<cr>";
        options.desc = "Explain Error";
      }
      {
        mode = "n";
        key = "]d";
        action = "<cmd>lua vim.diagnostic.goto_next()<cr>";
        options.desc = "Next Error";
      }
      {
        mode = "n";
        key = "[d";
        action = "<cmd>lua vim.diagnostic.goto_prev()<cr>";
        options.desc = "Previous Error";
      }
      {
        mode = "n";
        key = "<leader>ca";
        action = "<cmd>lua vim.lsp.buf.code_action()<cr>";
        options = {
          desc = "LSP Code Actions (Quick Fix)";
        };
      }
    ];
    #colorschemes.tokyonight = {
    #  enable = true;
    #  settings = {
    #    #style = "moon";
    #    style = "night";
    #  };
    #};
    #colorschemes.dracula = {
    #  enable = true;
    #};
    colorschemes.catppuccin = {
      enable = true;
      settings = {
        #color_overrides = {
        #  mocha = {
        #    base = "#1e1e2f";
        #  };
        #};
        #disable_underline = true;
        flavour =
          if (config ? catppuccinTheme)
          then config.catppuccinTheme
          else "macchiato";

        integrations = {
          cmp = true;
          gitsigns = true;
          mini = {
            enabled = true;
            indentscope_color = "";
          };
          notify = false;
          nvimtree = true;
          treesitter = true;
        };
        styles = {
          booleans = [
            "bold"
            "italic"
          ];
          conditionals = [
            "bold"
          ];
        };
        term_colors = true;
      };
    };
    clipboard = {
      register = "unnamedplus";
      providers.wl-copy.enable = true;
    };
    plugins = {
      lualine = {
        enable = true;
        settings = {
          options = {
            icons_enabled = true;
            colorcheme = "catppuccin";
          };
          sections = {
            lualine_c = [
              {
                __unkeyed-1 = "filename";
                path = 3;
              }
              "diff"
            ];
          };
        };
      };
      telescope = {
        enable = true;
        extensions = {
          live-grep-args = {
            settings = {
              search_dirs = ["/etc/mnt" "~"];
            };
          };
          fzf-native.enable = true; # For fast searching
          ui-select.enable = true; # For pretty LSP code-action menus
          file-browser.enable = true; # To use telescope as a file explorer
        };
        keymaps = {
          "<leader>ff" = {
            action = "find_files";
            options = {
              desc = "Telescope Files";
            };
          };
          "<leader>fg" = {
            action = "live_grep";
            options = {
              desc = "Telescope Live Grep";
            };
          };
          "<leader>fb" = {
            action = "buffers";
            options = {
              desc = "Telescope Buffers";
            };
          };
          "<leader>fh" = {
            action = "help_tags";
            options = {
              desc = "Telescope Help";
            };
          };
        };
        settings = {
          defaults = {
            file_ignore_patterns = [
              "^.git/"
              "^.mypy_cache/"
              "^__pycache__/"
              "^output/"
              "^data/"
              "%.ipynb"
              "^result"
            ];
            layout_config = {
              prompt_position = "bottom";
            };
            #mappings = {
            #  i = {
            #    "<A-j>" = {
            #      __raw = "require('telescope.actions').move_selection_next";
            #    };
            #    "<A-k>" = {
            #      __raw = "require('telescope.actions').move_selection_previous";
            #    };
            #  };
            #};
            selection_caret = "> ";
            set_env = {
              COLORTERM = "truecolor";
            };
            sorting_strategy = "ascending";
          };
        };
      };
      lightline = {
        enable = true;
        settings = {
          colorcheme = "Tommorow_Night_Blue";
        };
      };
      lsp = {
        enable = true;
        # I need to figure this out
        #keymaps = {
        #  extra = [
        #    {
        #      action = {
        #        __raw = "vim.lsp.buf.format()";
        #      };
        #      key = "fm";
        #    }
        #  ];
        #};
        servers = {
          nixd = {
            enable = true;
            settings = {
              formatting.command = ["nixpkgs-fmt"];
              nixpkgs.expr = "import <nixpkgs> { }";
            };
          };
          gopls = {
            enable = true;
            #settings = {};
          };
          terraformls = {
            enable = true;
          };
          bashls = {
            enable = true;
          };
          dockerls = {
            enable = true;
          };
          jsonls = {
            enable = true;
          };
          lua_ls = {
            enable = true;
            settings = {
              Lua = {
                diagnostics = {
                  globals = ["vim"]; # Stops the "Undefined global: vim" error
                };
                workspace = {
                  library = [
                    # This makes the LSP aware of Neovim's built-in functions
                    #(lib.nixvim.mkRaw "vim.api.nvim_get_runtime_file('', true)")
                    "vim.api.nvim_get_runtime_file('', true)"
                  ];
                  checkThirdParty = false;
                };
                telemetry.enable = false; # Keep it private
              };
            };
          };
          pyright = {
            enable = true;
            package = pkgs.basedpyright;
            cmd = ["basedpyright-langserver" "--stdio"];
            settings = {
              basedpyright.analysis = {
                typeCheckingMode = "strict"; # or "standard"
                diagnosticMode = "workspace";
              };
              python.analysis.inlayHints = {
                variableTypes = true;
                functionReturnTypes = true;
                callArgumentNames = true;
                parameterTypes = true;
              };
            };
          };
          stylua = {
            enable = true;
          };
          yamlls = {
            enable = true;
          };
          # Switch to taplo if issues
          tombi = {
            enable = true;
          };
        };
      };

      lspkind = {
        enable = true;
        settings = {
          cmp = {
            enable = true;
            menu = {
              buffer = "[buffer]";
              nvim_lsp = "[LSP]";
              path = "[path]";
            };
          };
        };
      };
      luasnip = {
        enable = true;
        fromVscode = [
          {}
        ];
      };

      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          snippet = {
            expand = "function(args) require('luasnip').lsp_expand(args.body) end";
          };
          sources = [
            {
              name = "nvim_lsp";
              priority = 1000;
            }
            {
              name = "nixd";
              priority = 1000;
            }
            {
              name = "luasnip";
              priority = 750;
            }
            {
              name = "path";
              priority = 500;
            }
            {
              name = "buffer";
              priority = 250;
            }
          ];
          mapping = {
            "<C-b>" = "cmp.mapping.scroll_docs(-4)";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-e>" = "cmp.mapping.abort()";
            "<CR>" = "cmp.mapping.confirm({select = true})";
            "<Tab>" = {
              __raw = ''
                function(fallback)
                  local cmp = require('cmp')
                  local luasnip = require('luasnip')
                  if cmp.visible() then
                    cmp.select_next_item()
                  elseif luasnip.expand_or_jumpable() then
                    luasnip.expand_or_jump()
                  else
                    fallback()
                  end
                end
              '';
              modes = ["i" "s"];
            };
            "<S-Tab>" = {
              __raw = ''
                function(fallback)
                  local cmp = require('cmp')
                  local luasnip = require('luasnip')
                  if cmp.visible() then
                    cmp.select_prev_item()
                  elseif luasnip.jumpable(-1) then
                    luasnip.jump(-1)
                  else
                    fallback()
                  end
                end
              '';
              modes = ["i" "s"];
            };
          };
        };
      };

      cmp-buffer = {
        enable = true;
      };

      #cmp-fuzzy-buffer = {
      #  enable = true;
      #};

      #cmp-fuzzy-path = {
      #  enable = true;
      #};

      treesitter = {
        enable = true;
      };

      web-devicons = {
        enable = true;
      };

      cmp_luasnip = {
        enable = true;
      };

      cmp-nvim-lsp = {
        enable = true;
      };

      cmp-path = {
        enable = true;
      };

      diffview = {
        enable = true;
      };

      snacks = {
        enable = true;
        settings = {
          indent = {
            enabled = true;
            char = "▏"; # or "│" or "┆"
            scope = {
              enabled = true;
              only_current = true;
            };
          };
          bigfile = {
            enabled = true;
          };
          notifier = {
            enabled = true;
            timeout = 3000;
          };
          quickfile = {
            enabled = false;
          };
          statuscolumn = {
            enabled = false;
          };
          words = {
            debounce = 100;
            enabled = true;
          };
        };
      };
    };
    extraConfigLua = ''
    '';
    extraPlugins = [
      pkgs.vimPlugins.nvim-lspconfig
      pkgs.vimPlugins.friendly-snippets
    ];
    extraPackages = [
      pkgs.wl-clipboard
      pkgs.xsel
      pkgs.ripgrep
    ];
  };
}
