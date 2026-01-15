{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    #nixvim.nixosModules.nixvim
    inputs.nixvim.nixosModules.nixvim
  ];

  programs.nixvim = {
    #Includes functions get_bufnrs
    enable = true;
    #colorschemes.tokyonight = {
    #  enable = true;
    #  settings = {
    #    #style = "moon";
    #    style = "night";
    #  };
    #};
    colorschemes.dracula = {
      enable = true;
    };
    clipboard = {
      register = "unnamedplus";
      providers.wl-copy.enable = true;
    };
    plugins = {
      lualine = {
        enable = true;
        settings = {
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
