{
  pkgs,
  inputs,
  config,
  ...
}: {
  imports = [
    inputs.nixvim.nixosModules.nixvim
  ];

  environment.variables = {
    MANPAGER = "nvim +Man!";
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  programs.nixvim = {
    #Includes functions get_bufnrs
    enable = true;

    extraConfigLuaPre = ''
      vim.g.netrw_sort_by = "time"
      vim.g.netrw_liststyle = 1
      vim.g.netrw_sort_direction = "reverse"
    '';

    nixpkgs.source = inputs.nixpkgs;
    keymaps = [
      {
        mode = "n";
        key = "<leader>b";
        action = "<cmd>lua vim.lsp.buf.format()<CR>";
        options.desc = "Format current buffer";
      }
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
        # Taerminal colors from alacritty-theme (themes/taerminal.toml).
        # Taerminal has only 16 terminal colors. Slots marked "invented" have no taerminal value.
        # `all` applies to each flavour, so my.theme.catppuccin does not change these colors.
        color_overrides.all = {
          # Grays, from dark to light
          crust = "#161718"; # invented
          mantle = "#1c1d1f"; # invented: the tmux status bar color; floats, status line
          base = "#26282a"; # background
          surface0 = "#303234"; # invented: cursor line
          surface1 = "#3c3e41"; # invented: selection, line numbers
          surface2 = "#4a4c4f"; # invented
          overlay0 = "#58595b"; # invented
          overlay1 = "#646566"; # invented
          overlay2 = "#6f6f6f"; # bright black: comments, brackets
          subtext0 = "#a8a8a8"; # invented
          subtext1 = "#c8c8c8"; # invented
          text = "#f0f0f0"; # foreground
          # Accents
          red = "#ff8878"; # red: builtin variables, errors
          maroon = "#fe978b"; # bright red: parameters
          flamingo = "#fe978b"; # bright red
          peach = "#ffb88a"; # invented orange: numbers, constants, booleans
          yellow = "#fffcb7"; # yellow: types, modules
          rosewater = "#fffed5"; # bright yellow
          green = "#b4fb73"; # green: strings
          teal = "#d6fcba"; # bright green: characters
          sky = "#a2e1f8"; # cyan: operators
          sapphire = "#c0e9f8"; # bright cyan: labels
          blue = "#8bbce5"; # blue: functions
          lavender = "#c2e3ff"; # bright blue: properties, attribute names
          mauve = "#ffb2fe"; # magenta: keywords, conditionals
          pink = "#ffc6ff"; # bright magenta: escapes, special
        };
        #disable_underline = true;
        flavour = config.my.theme.catppuccin;

        integrations = {
          cmp = true;
          diffview = true;
          gitsigns = true;
          mini = {
            enabled = true;
            indentscope_color = "";
          };
          notify = false;
          nvimtree = true;
          snacks.enabled = true;
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
    # The same taerminal colors in base16. This variant has no bold, no italics,
    # and no snacks colors.
    #colorschemes.base16 = {
    #  enable = true;
    #  colorscheme = {
    #    base00 = "#26282a"; # background
    #    base01 = "#303234"; # invented: cursor line, status line
    #    base02 = "#3c3e41"; # invented: selection
    #    base03 = "#6f6f6f"; # comments (bright black)
    #    base04 = "#a8a8a8"; # invented: line numbers
    #    base05 = "#f0f0f0"; # text
    #    base06 = "#f1f1f1"; # white
    #    base07 = "#ffffff"; # bright white
    #    base08 = "#ff8878"; # red
    #    base09 = "#ffb88a"; # invented: orange
    #    base0A = "#fffcb7"; # yellow
    #    base0B = "#b4fb73"; # green
    #    base0C = "#a2e1f8"; # cyan
    #    base0D = "#8bbce5"; # blue
    #    base0E = "#ffb2fe"; # magenta
    #    base0F = "#d69a8a"; # invented: brown
    #  };
    #};
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
              #nixpkgs.expr = "import <nixpkgs> { }";
            };
          };
          clangd = {
            enable = true;
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
