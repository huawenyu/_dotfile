-- vim: set ft=lua autoindent cindent expandtab tabstop=2 shiftwidth=2 softtabstop=2:
-- Usage: NVIM_APPNAME=nvim-mini nvim -u ~/.config/nvim/init_mini.lua
-- Minimal Neovim config for Linux with lazy.nvim
-- Run: nvim --headless -c "lua for k,v in pairs(require('lazy.core.config').spec.plugins) do if v.lazy==false then print(k) end end" -c qa!

-- ============================================================
-- Bootstrap lazy.nvim
-- ============================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ============================================================
-- Global Config
-- ============================================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- vim-confi options for cond() function used by vimConfig
vim.g.vim_confi_option = {
  mode = { 'basic', 'theme', 'local', 'editor', 'admin', 'coder', 'log', 'c', 'markdown', 'git', 'script', 'tool' },
  remap_leader = 1,
  theme = 1,
  conf = 1,
  verbose = 0,
  debug = 0,
  upper_keyfixes = 1,
  enable_map_basic = 1,
  enable_map_useful = 1,
  auto_chdir = 0,
  auto_save = 1,
  auto_restore_cursor = 1,
  keywordprg_filetype = 1,
  modeline = 0,
  view_folding = 0,
  show_number = 0,
  wrapline = 0,
  indentline = 0,
  help_keys = 1,
  alt_shortcut = 1,
}

-- Plugin guards (defined before lazy.setup for vimConfig compatibility)
_G.HasPlug = function(name)
  local ok, config = pcall(require, "lazy.core.config")
  local plugin = ok and config.plugins[name]
  return plugin ~= nil
end

_G.HasNoPlug = function(name)
  local ok, config = pcall(require, "lazy.core.config")
  local plugin = ok and config.plugins[name]
  return plugin == nil
end

vim.cmd([[
  function! HasPlug(name) abort
    return luaeval('_G.HasPlug(_A)', a:name)
  endfunction
  function! HasNoPlug(name) abort
    return luaeval('_G.HasNoPlug(_A)', a:name)
  endfunction
]])

-- ============================================================
-- Plugin Specifications (Linux only, loaded plugins from your config)
-- ============================================================
local plugins = {
  -- Foundation (loaded at startup)
  { "tpope/vim-sensible", lazy = false },
  { "huawenyu/vim-basic", lazy = false },
  {
    "huawenyu/vimConfig",
    lazy = false,
    dependencies = { "huawenyu/vim-motion", "huawenyu/vim-basic" },
  },

  -- Color theme
  { "huawenyu/jellybeans.vim", lazy = false },

  -- Navigation (loaded)
  { "chentoast/marks.nvim", lazy = false },

  -- Repeat enhancement (loaded)
  { "tpope/vim-repeat", lazy = false },
  { "tpope/vim-abolish", lazy = false },

  -- Edit enhancements (loaded)
  { "vim-scripts/genutils", lazy = false },

  -- Search (loaded - used by vimConfig)
  { "huawenyu/vim-grepper", lazy = false },
  { "huawenyu/improved-search.nvim", lazy = false },

  -- Markdown (loaded - vimConfig depends on vim-markdown)
  { "preservim/vim-markdown", lazy = false, ft = "markdown" },

  -- C/C++ Development (loaded via cond)
  { "nvim-treesitter/nvim-treesitter", lazy = false },
  {
    "huawenyu/c-utils.vim",
    lazy = false,
    config = function() require("c-utils").setup() end,
  },

  -- UI (loaded)
  { "vimpostor/vim-tpipeline", lazy = false },

  -- Task runner (loaded)
  {
    'skywind3000/asynctasks.vim',
    lazy = false,
    dependencies = { "skywind3000/asyncrun.vim" },
    init = function()
      local vimrc = vim.env.MYVIMRC or vim.fn.expand('<sfile>:p')
      local tasks_file = vim.fn.fnamemodify(vimrc, ':p:h') .. "/tasks.ini"
      if vim.fn.filereadable(tasks_file) ~= 1 then return end
      local dst = vim.fn.fnamemodify(vimrc, ':p:h') .. "/tasks.ini"
      local src = vim.fn.expand("~/.vim_tasks.ini")
      if vim.fn.filereadable(src) == 1 and vim.fn.getftype(dst) == '' then
        vim.fn.system('ln -sf ' .. src .. ' ' .. dst)
      end
    end,
  },

  -- Optional: Fuzzy Finder
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "[find] Find file" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "[find] Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "[picker] Buffers" },
    },
  },

  -- Optional: LSP
  {
    "neovim/nvim-lspconfig",
    event = "VeryLazy",
    dependencies = { "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim" },
    config = function()
      vim.lsp.config('clangd', {})
      vim.lsp.enable('clangd')
    end,
  },

  -- Optional: Git
  { "tpope/vim-fugitive", cmd = { "Git", "Gstatus" } },
  { "huawenyu/gitsigns.nvim", event = "BufReadPre" },

  -- Optional: Completion
  {
    "saghen/blink.cmp",
    version = "1.*",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
      require('blink.cmp').setup({
        completion = { documentation = { auto_show = false } },
        sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
      })
    end,
  },

  -- Optional: Edit helpers
  { "tpope/vim-surround", lazy = false },
  { "tpope/vim-commentary", keys = { { "gcc", "gcc", mode = "n" }, { "gc", "gc", mode = "v" } } },
  { "windwp/nvim-autopairs", event = "InsertEnter" },

  -- Optional: File tree
  {
    "nvim-neo-tree/neo-tree.nvim",
    cmd = "Neotree",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
    config = function()
      require("neo-tree").setup({ filesystem = { auto_open = false, follow_current_file = true } })
    end,
  },

  -- Optional: Terminal
  {
    "akinsho/toggleterm.nvim",
    config = function()
      require("toggleterm").setup({ open_mapping = [[<c-\>]], direction = "float" })
    end,
  },
}

-- ============================================================
-- Lazy.nvim Setup
-- ============================================================
require("lazy").setup({
  spec = plugins,
  defaults = { lazy = true },
  install = { colorscheme = { "jellybeans" } },
  performance = {
    rtp = {
      disabled_plugins = { "gzip", "matchit", "matchparen", "netrwPlugin", "tarPlugin", "tohtml", "tutor", "zipPlugin" },
    },
  },
})

-- ============================================================
-- Basic Options
-- ============================================================
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.smartindent = true
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"
vim.opt.swapfile = false

-- Colorscheme
vim.cmd.colorscheme("jellybeans")

-- Keymaps
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { silent = true })

-- vim-confi options for cond() function used by vimConfig
vim.g.vim_confi_option = {
  mode = { 'basic', 'theme', 'local', 'editor', 'admin', 'coder', 'log', 'c', 'markdown', 'git', 'script', 'tool' },
  remap_leader = 1,
  theme = 1,
  conf = 1,
}

-- Plugin guards (used by vimConfig's conf_local.vim)
_G.HasPlug = function(name)
  local plugin = require("lazy.core.config").plugins[name]
  return plugin ~= nil
end

_G.HasNoPlug = function(name)
  local plugin = require("lazy.core.config").plugins[name]
  return plugin == nil
end

vim.cmd([[
  function! HasPlug(name) abort
    return luaeval('_G.HasPlug(_A)', a:name)
  endfunction
  function! HasNoPlug(name) abort
    return luaeval('_G.HasNoPlug(_A)', a:name)
  endfunction
]])
