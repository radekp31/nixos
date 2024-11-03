vim.cmd('colorscheme tokyonight-night')
vim.opt.number = true
vim.opt.relativenumber = true
vim.api.nvim_create_autocmd("VimLeave", { command = "!clear" })
