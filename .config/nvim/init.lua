-- ~/.config/nvim/init.lua
-- Performance-optimized Neovim configuration with lazy.nvim

-- ============================================================
-- Core Settings & Bootstrap
-- ============================================================

-- System detection
local function is_ubuntu()
  local f = io.open("/etc/os-release", "r")
  if not f then return false end
  local content = f:read("*all")
  f:close()
  return content:find("Ubuntu") ~= nil
end

local function is_wsl()
  if vim.fn.has("unix") == 1 and vim.fn.has("mac") == 0 then
    local distro_name = vim.env.WSL_DISTRO_NAME
    local interop = vim.env.WSL_INTEROP
    return (distro_name ~= nil and distro_name ~= "") or (interop ~= nil and interop ~= "")
  end
  return false
end

-- Package installer for Ubuntu
local function ensure_apt_packages(packages)
  if not is_ubuntu() then return true end

  local missing = {}
  for _, pkg in ipairs(packages) do
    local handle = io.popen("dpkg -l " .. pkg .. " 2>/dev/null | grep -c '^ii'")
    local result = handle:read("*a")
    handle:close()
    if tonumber(result) == 0 then
      table.insert(missing, pkg)
    end
  end

  if #missing > 0 then
    vim.notify("Installing: " .. table.concat(missing, ", "), vim.log.levels.INFO)
    vim.fn.system("sudo apt-get update && sudo apt-get install -y " .. table.concat(missing, " "))
    return vim.v.shell_error == 0
  end
  return true
end

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ============================================================
-- Helper Functions
-- ============================================================

local function mode_intersect(mode_list)
  local config_modes = vim.g.vim_confi_option and vim.g.vim_confi_option.mode or {}
  if type(config_modes) == "string" then
    config_modes = { config_modes }
  end
  for _, m in ipairs(mode_list) do
    for _, cm in ipairs(config_modes) do
      if m == cm then return true end
    end
  end
  return false
end

local function cond(mode_list)
  if vim.tbl_contains(vim.g.vim_confi_option.mode, "all") then
    return true
  end
  return mode_intersect(mode_list)
end

-- Plugin existence check (compatible with vimscript)
_G.HasPlug = function(name)
  local plugin = require("lazy.core.config").plugins[name]
  return plugin ~= nil
end

_G.HasNoPlug = function(name)
  local plugin = require("lazy.core.config").plugins[name]
  return plugin == nil
end

-- Symlink builder for external repos
local function symlink_repo(target_path)
  return function(plugin)
    local target = vim.fn.expand(target_path)
    if vim.fn.getftype(target) == "" then
      local ok, err = vim.loop.fs_symlink(plugin.dir, target)
      if ok then
        print("Repo symlinked to: " .. target)
      else
        print("Symlink failed: " .. tostring(err))
      end
    end
  end
end

-- ============================================================
-- Global Configuration
-- ============================================================

vim.cmd([[
  let g:vim_confi_option = {
        \ 'mode': ['basic', 'theme', 'local', 'editor', 'admin', 'coder', 'log', 'c', 'markdown', 'git', 'script', 'tool'],
        \ 'remap_leader': 1,
        \ 'theme': 1,
        \ 'conf': 1,
        \ 'verbose': 0,
        \ 'debug': 0,
        \ 'upper_keyfixes': 1,
        \ 'enable_map_basic': 1,
        \ 'enable_map_useful': 1,
        \ 'auto_chdir': 0,
        \ 'auto_save': 1,
        \ 'auto_restore_cursor': 1,
        \ 'keywordprg_filetype': 1,
        \ 'modeline': 0,
        \ 'view_folding': 0,
        \ 'show_number': 0,
        \ 'wrapline': 0,
        \ 'indentline': 0,
        \ 'help_keys': 1,
        \ 'alt_shortcut': 1,
        \ 'wiki_dirs': ['~/dotwiki', '~/wiki', '~/dotfiles'],
        \ 'tmp_file': '/tmp/vim.tmp',
        \}

  if !empty($mode)
      let g:vim_confi_option.mode = [$mode]
  endif

  if !empty($debug)
      let g:vim_confi_option.debug = 1
  endif

  if g:vim_confi_option.remap_leader
      let mapleader = "\<Space>"
      let maplocalleader="\<Space>"
      map Q <Nop>
  endif
]])

-- ============================================================
-- Plugin Specifications
-- ============================================================

local plugins = {
  -- ============================================================
  -- Others tools/repo manage through plugin
  -- ============================================================
  { "huawenyu/dotfiles", lazy = true, build = symlink_repo("~/dotfiles") },
  { "huawenyu/zsh-local", lazy = true, build = symlink_repo("~/.oh-my-zsh/custom/plugins/zsh-local") },
  { "zsh-users/zsh-completions", lazy = true, build = symlink_repo("~/.oh-my-zsh/custom/plugins/zsh-completions") },
  { "dooblem/bsync", lazy = true, build = symlink_repo("~/bin/repo-bsync") },

  -- ============================================================
  -- Basic / Core
  -- ============================================================
  { "tpope/vim-sensible", enabled = cond({ "basic", "log", "editor" }), lazy = false },
  {
    "huawenyu/vim-basic",
    enabled = cond({ "basic", "log", "editor" }),
    lazy = false,
    config = function()
      -- ============================================================
      -- vim-basic extracted configurations
      -- ============================================================

      -- Basic settings from plugin/config.vim
      vim.opt.formatoptions:append("m")
      vim.opt.formatoptions:append("B")
      vim.opt.fileformats = "unix,dos,mac"
      vim.opt.clipboard:prepend("unnamed,unnamedplus")

      -- Terminal setup for neovim
      vim.api.nvim_create_augroup("terminal_setup", { clear = true })
      vim.api.nvim_create_autocmd("TermOpen", {
        group = "terminal_setup",
        callback = function()
          vim.keymap.set("n", "<LeftRelease>", "<LeftRelease>i", { buffer = true })
          vim.cmd("startinsert")
        end,
      })
      vim.api.nvim_create_autocmd("TermOpen", {
        group = "terminal_setup",
        callback = function()
          vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { buffer = true })
        end,
      })
      vim.api.nvim_create_autocmd("FileType", {
        group = "terminal_setup",
        pattern = "fzf",
        callback = function()
          vim.cmd("tunmap <Esc><Esc>")
        end,
      })

      -- Yank from cursor to end of line (consistent with C and D)
      vim.keymap.set('n', 'Y', 'y$', { desc = "Yank to end of line" })

      -- Copy text to tmpfile
      vim.keymap.set('v', '<leader>yy', function()
        vim.cmd('call utils#GetSelected("v", "/tmp/vim.yank")')
      end, { silent = true, desc = "Copy text to tmpfile" })

      vim.keymap.set('n', '<leader>yy', function()
        vim.cmd('call vimuxscript#Copy()')
      end, { silent = true, desc = "Copy text to tmpfile" })

      -- Paste text from tmpfile
      vim.keymap.set('n', '<leader>yp', function()
        vim.cmd('r! cat /tmp/vim.yank')
      end, { silent = true, desc = "Paste text from tmpfile" })

      -- vim search with visual selection
      vim.keymap.set('v', '//', function()
        vim.fn.execute('y')
        vim.cmd(':vim /\\<' .. vim.fn.getreg('"') .. '\\C/gj %')
      end, { desc = "Search visual selection with :vim" })

      -- File open with gf
      vim.keymap.set("n", "gf", function()
        vim.cmd("call utils#GotoFileWithLineNum(0)")
      end, { desc = "Open file under cursor" })

      vim.keymap.set("n", "<leader>gf", function()
        vim.cmd("call <SID>GuessLink('n')")
      end, { silent = true, desc = "(tool) Goto file" })

      vim.keymap.set("x", "<leader>gf", function()
        vim.cmd("call <SID>GuessLink('v')")
      end, { silent = true, desc = "(tool) Goto file" })
    end,
  },
  {
    "huawenyu/vimConfig",
    enabled = cond({ "basic", "log", "editor" }),
    lazy = false,
    dependencies = {
      "huawenyu/vim-motion",
      "huawenyu/vim-basic",
    },
    keys = {
      -- conf_cmd.vim keymaps
      { "<leader>vr", mode = { "n", "v" }, desc = "Replace" },
      { "<leader>mk", desc = "Make wad" },
      { "<leader>ma", desc = "Make all" },
      { "<leader>mw", desc = "Dictionary" },
      { "<leader>mf", desc = "Quickfix filter" },
      { "<leader>mc", desc = "Quickfix add caller" },
      { ";q", desc = "SmartClose" },
    },
    config = function()
      -- ============================================================
      -- vimConfig extracted configurations
      -- ============================================================

      -- Auto-save removed (caused slow :qa)

      -- Commands
      vim.api.nvim_create_user_command("R", function(opts)
        vim.cmd("NeomakeRun! " .. opts.args)
      end, { nargs = "+", bang = true, complete = "shellcmd" })
      vim.api.nvim_create_user_command("Grep", function(opts)
        vim.cmd("call utilgrep#_Grep('grep" .. (opts.bang and "!" or "") .. "'," .. opts.args .. ")")
      end, { nargs = "*", bang = true, complete = "file" })
      vim.api.nvim_create_user_command("GrepAdd", function(opts)
        vim.cmd("call utilgrep#_Grep('grepadd" .. (opts.bang and "!" or "") .. "'," .. opts.args .. ")")
      end, { nargs = "*", bang = true, complete = "file" })
      vim.api.nvim_create_user_command("LGrep", function(opts)
        vim.cmd("call utilgrep#_Grep('lgrep" .. (opts.bang and "!" or "") .. "'," .. opts.args .. ")")
      end, { nargs = "*", bang = true, complete = "file" })
      vim.api.nvim_create_user_command("LGrepAdd", function(opts)
        vim.cmd("call utilgrep#_Grep('lgrepadd" .. (opts.bang and "!" or "") .. "'," .. opts.args .. ")")
      end, { nargs = "*", bang = true, complete = "file" })
      vim.api.nvim_create_user_command("SmartClose", function(opts)
        local function is_auxiliary(buffer)
          return not vim.bo[buffer].modifiable or not vim.bo[buffer].buflisted or vim.bo[buffer].buftype ~= ""
        end
        local current_buffer = vim.api.nvim_get_current_buf()
        if opts.bang or is_auxiliary(current_buffer) then
          vim.cmd("q")
        else
          local auxiliary_buffer = 0
          for _, b in ipairs(vim.api.nvim_list_bufs()) do
            if is_auxiliary(b) and b > auxiliary_buffer then
              auxiliary_buffer = b
            end
          end
          if auxiliary_buffer > 0 then
            vim.cmd(string.format("noautocmd %d wincmd w", vim.fn.bufwinnr(auxiliary_buffer)))
            vim.cmd("noautocmd q")
            vim.cmd(string.format("noautocmd %d wincmd w", vim.fn.bufwinnr(current_buffer)))
          else
            vim.cmd("q")
          end
        end
      end, { bang = true, nargs = 0 })

      -- Functions
      local function selected_replace(mode)
        local save_cursor = vim.fn.getcurpos()
        local sel_str = vim.fn["hw#misc#GetWord"](mode)
        local nr = vim.fn.winnr()
        if vim.fn.getwinvar(nr, '&syntax') == 'qf' then
          vim.fn.setpos('.', save_cursor)
          return "%s/\\<" .. sel_str .. "\\>/" .. sel_str .. "/gI"
        else
          vim.cmd("delmarks un")
          vim.cmd("normal [[mu%mn")
          vim.cmd("redraw")
          return "'u,'ns/\\<" .. sel_str .. "\\>/" .. sel_str .. "/gI"
        end
      end

      -- Keymaps from conf_cmd.vim
      vim.keymap.set("n", "<leader>vr", function()
        vim.cmd(selected_replace('n'))
      end, { silent = true, desc = "Replace" })
      vim.keymap.set("v", "<leader>vr", function()
        vim.cmd(selected_replace('v'))
      end, { silent = true, desc = "Replace" })
      vim.keymap.set("n", "<leader>mk", ":AsyncStop! <bar> AsyncTask! wad<CR>", { silent = true, desc = "Make wad" })
      vim.keymap.set("n", "<leader>ma", ":AsyncStop! <bar> AsyncTask! sysinit<CR>", { silent = true, desc = "Make all" })
      vim.keymap.set("n", "<leader>mw", ":R! ~/tools/dict <C-R>=expand('<cword>')<cr>", { silent = true, desc = "Dictionary" })
      vim.keymap.set("n", "<leader>mf", ":call utilquickfix#QuickFixFilter()<CR>", { silent = true, desc = "Quickfix filter" })
      vim.keymap.set("n", "<leader>mc", ":call utilquickfix#QuickFixFunction()<CR>", { silent = true, desc = "Quickfix add caller" })
      vim.keymap.set("n", ";q", ":SmartClose<CR>", { silent = true, desc = "SmartClose" })

      -- vimConfig/conf_map.vim: Upper keyfixes
      if vim.g.vim_confi_option.upper_keyfixes then
        vim.api.nvim_create_user_command("E", function(opts)
          vim.cmd("e" .. (opts.bang and "!" or "") .. " " .. (opts.args or ""))
        end, { bang = true, nargs = "*" })
        vim.api.nvim_create_user_command("W", function(opts)
          vim.cmd("w" .. (opts.bang and "!" or "") .. " " .. (opts.args or ""))
        end, { bang = true, nargs = "*" })
        vim.api.nvim_create_user_command("Wq", function(opts)
          vim.cmd("wq" .. (opts.bang and "!" or ""))
        end, { bang = true, nargs = "?" })
        vim.api.nvim_create_user_command("WQ", function(opts)
          vim.cmd("wq" .. (opts.bang and "!" or ""))
        end, { bang = true, nargs = "?" })
        vim.api.nvim_create_user_command("Wa", function(opts)
          vim.cmd("wa" .. (opts.bang and "!" or ""))
        end, { bang = true })
        vim.api.nvim_create_user_command("WA", function(opts)
          vim.cmd("wa" .. (opts.bang and "!" or ""))
        end, { bang = true })
        vim.api.nvim_create_user_command("Q", function(opts)
          vim.cmd("q" .. (opts.bang and "!" or ""))
        end, { bang = true })
        vim.api.nvim_create_user_command("QA", function(opts)
          vim.cmd("qa" .. (opts.bang and "!" or ""))
        end, { bang = true })
        vim.api.nvim_create_user_command("Qa", function(opts)
          vim.cmd("qa" .. (opts.bang and "!" or ""))
        end, { bang = true })
      end

      -- vimConfig/conf_map.vim: Alt shortcuts
      if vim.g.vim_confi_option.alt_shortcut then
        vim.keymap.set("n", "<a-e>", "<leader>ve")
        vim.keymap.set("n", "<a-w>", "<leader>vw")
        vim.keymap.set("n", "<a-t>", "<leader>vt")
        vim.keymap.set("n", "<a-b>", "<leader>vb")
        vim.keymap.set("n", "<a-g>", "<leader>vg")
        vim.keymap.set("n", "<a-q>", "<leader>vq")
        vim.keymap.set("n", "<a-f>", ";fs")
        vim.keymap.set("n", "<a-s>", "<leader>g1")
        vim.keymap.set("n", "<a-/>", ":TodoLocList<cr>")
        vim.keymap.set("n", "<a-:>", ":AsyncTask tag4one<cr>")
        vim.keymap.set("n", "<a-'>", ":AsyncTask run<cr>")
        vim.keymap.set("n", ";w", ":wall<cr>", { desc = "Save all buffers" })
        vim.keymap.set("x", ";w", ":<c-U>wall<cr>")
        if HasPlug("vim-motion") then
          vim.keymap.set("n", "<a-,>", "<Plug>_JumpPrevIndent")
          vim.keymap.set("n", "<a-.>", "<Plug>_JumpNextIndent")
          vim.keymap.set("x", "<a-.>", "<Plug>_JumpPrevIndent")
          vim.keymap.set("x", "<a-,>", "<Plug>_JumpNextIndent")
          vim.keymap.set("o", "<a-,>", "<Plug>_JumpPrevIndent")
          vim.keymap.set("o", "<a-.>", "<Plug>_JumpNextIndent")
        end
        vim.keymap.set("i", "<a-i>", '<c-r>"')
      end

      -- vimConfig/conf_map.vim: Basic mappings
      if vim.g.vim_confi_option.enable_map_basic then
        vim.keymap.set("n", "<C-c>", "<C-c>")
        vim.keymap.set("n", "<leader>q", function() vim.cmd("qa") end, { silent = true, desc = "Exit all" })
        vim.keymap.set("x", "<leader>q", function() vim.cmd("qa") end, { silent = true })
        vim.keymap.set("i", "<S-Tab>", "<C-v><Tab>")

        vim.keymap.set({ "n", "x" }, "j", "gj")
        vim.keymap.set({ "n", "x" }, "k", "gk")
        vim.keymap.set("x", ">", ">gv")
        vim.keymap.set("x", "<", "<gv")

        vim.keymap.set('n', '<Return>', function()
          -- Only clear highlights if we are NOT in a quickfix window
          if vim.bo.buftype ~= 'quickfix' then
            vim.cmd("nohls")
            vim.cmd("nohls")
          end

          -- Always return the actual Enter key behavior
          return '<CR>'
        end, { expr = true, silent = true, desc = "Clear search highlight" })


        vim.keymap.set("n", ";#", ":<c-u><c-u>%s///gn<cr>", { desc = "Count search pattern" })
        vim.keymap.set("n", ";^", ":<c-u>g//p<cr>", { desc = "Popup search pattern" })
        vim.keymap.set("n", ";*", ":cexpr []<cr> | :<c-u>g//caddexpr expand('%') ..':' ..line('.') ..':0:' .. getline('.')<cr> | :copen<cr>", { desc = "Quickfix sink search" })
        vim.keymap.set("n", "<F1>", ":%s///gc<cr>", { desc = "Continue replace all search" })
        vim.keymap.set("n", ";.", ":%s//<C-R>\"/gc<cr>", { desc = "Continue replace all search" })
        vim.keymap.set("n", "<leader>.", "@@", { desc = "Repeat macro" })
        vim.keymap.set("n", "<Esc>", ":nohlsearch<CR><Esc>", { silent = true })
      end

      -- vimConfig/conf_map.vim: Useful mappings
      if vim.g.vim_confi_option.enable_map_useful then
        vim.api.nvim_create_autocmd("FileType", {
          pattern = { "c", "cpp" },
          callback = function()
            vim.keymap.set("n", "<leader>fa", function()
              vim.cmd("call JumpToCorrespondingFile()")
            end, { buffer = true, silent = true, desc = "Toggle source/header" })
          end,
        })

        vim.keymap.set("n", "<leader>h", "<c-w>h", { desc = "Window left" })
        vim.keymap.set("n", "<leader>j", "<c-w>j", { desc = "Window down" })
        vim.keymap.set("n", "<leader>k", "<c-w>k", { desc = "Window up" })
        vim.keymap.set("n", "<leader>l", "<c-w>l", { desc = "Window right" })

        vim.keymap.set("n", "<c-n>", "<cmd>silent! cnext<cr>", { desc = "Next quickfix" })
        vim.keymap.set("n", "<c-p>", "<cmd>silent! cprev<cr>", { desc = "Previous quickfix" })
        vim.keymap.set("n", "<a-n>", "<cmd>silent! lne<cr>", { desc = "Next locallist" })
        vim.keymap.set("n", "<a-p>", "<cmd>silent! lp<cr>", { desc = "Previous locallist" })

        vim.keymap.set("t", "<c-h>", "<C-\\><C-n><C-w>h")
        vim.keymap.set("t", "<c-j>", "<C-\\><C-n><C-w>j")
        vim.keymap.set("t", "<c-k>", "<C-\\><C-n><C-w>k")
        vim.keymap.set("t", "<c-l>", "<C-\\><C-n><C-w>l")

        vim.keymap.set("n", "p", "p`]", { desc = "Paste and jump to end" })
        vim.keymap.set("x", "p", function()
          return "pgv\"" .. vim.v.register .. "y"
        end, { expr = true, desc = "Paste over selection" })

        vim.keymap.set("n", "<leader>vR", "gD:%s/<C-R>///g<left><left>", { desc = "Replace all" })

        vim.keymap.set("n", "<leader>o", "<C-o>", { desc = "Jump to older position" })
        vim.keymap.set("n", "<leader>i", "<C-i>", { desc = "Jump to newer position" })
      end

      -- Tab navigation
      vim.keymap.set('n', ';1', '1gt', { silent = true, desc = "Go to tab 1" })
      vim.keymap.set('n', ';2', '2gt', { silent = true, desc = "Go to tab 2" })
      vim.keymap.set('n', ';3', '3gt', { silent = true, desc = "Go to tab 3" })
      vim.keymap.set('n', ';4', '4gt', { silent = true, desc = "Go to tab 4" })
      vim.keymap.set('n', ';5', '5gt', { silent = true, desc = "Go to tab 5" })
      vim.keymap.set('n', ';6', '6gt', { silent = true, desc = "Go to tab 6" })
      vim.keymap.set('n', ';7', '7gt', { silent = true, desc = "Go to tab 7" })
      vim.keymap.set('n', ';8', '8gt', { silent = true, desc = "Go to tab 8" })
      vim.keymap.set('n', ';9', '9gt', { silent = true, desc = "Go to tab 9" })
      vim.keymap.set('n', ';0', ':tabonly<CR>', { silent = true, desc = "Close other tabs" })

      vim.keymap.set({'n', 'v'}, ';tt', function()
        local bufnr = vim.api.nvim_get_current_buf()
        local vtag = vim.fn["utils#GetSelected"]('') -- lets auto mode

        if vtag == "" then
          vim.cmd('silent! tab sb ' .. bufnr)
        else
          vim.cmd('silent! tab tag ' .. vtag)
        end
      end, { silent = true, desc = "Tag word into new tab" })
    end,
  },

  -- ============================================================
  -- Color Themes
  -- ============================================================
  { "huawenyu/jellybeans.vim", enabled = cond({ "log", "editor" }), lazy = false },

  -- ============================================================
  -- Coder Plugins
  -- ============================================================
  { "tpope/vim-commentary", enabled = cond({ "coder" }), lazy = false },
  {
    "huawenyu/nerdcommenter",
    enabled = cond({ "coder" }),
    config = function()
      vim.g.NERDCreateDefaultMappings = 0
      vim.g.NERDCompactSexyComs = 1
      vim.g.NERDSpaceDelims = 1
      vim.g.NERDDefaultAlign = 'left'
      vim.g.NERDCustomDelimiters = { c = { left = '/**', right = '*/' } }
      vim.g.NERDAltDelims_java = 1
      vim.g.NERDCommentEmptyLines = 1
      vim.g.NERDTrimTrailingWhitespace = 1
      vim.g.NERDToggleCheckAllLines = 1

      vim.keymap.set('n', '<c-_>', function() vim.fn['nerdcommenter#Comment']('n', 'Sexy') end, { silent = true })
      vim.keymap.set('x', '<c-_>', function()
        vim.fn['nerdcommenter#Comment']('x', 'Sexy')
        vim.cmd('normal! gv')
      end, { silent = true })
    end,
  },
  { "Chiel92/vim-autoformat", enabled = cond({ "coder" }) },
  { "vim-scripts/iptables", enabled = cond({ "coder" }) },
  { "tenfyzhong/CompleteParameter.vim", enabled = cond({ "coder", "extra" }) },
  { "FooSoft/vim-argwrap", enabled = cond({ "coder", "extra" }) },
  { "ericcurtin/CurtineIncSw.vim", enabled = cond({ "coder" }) },
  { "huawenyu/neogdb2.vim", enabled = cond({ "coder" }) },
  { "chrisbra/vim-diff-enhanced", enabled = cond({ "editor" }) },
  { "fidian/hexmode", enabled = cond({ "editor" }), cmd = "Hexmode" },

  -- Language Specific
  { "huawenyu/vim-linux-coding-style", enabled = cond({ "coder", "c" }), ft = { "c", "cpp" } },
  { "octol/vim-cpp-enhanced-highlight", enabled = cond({ "coder", "c" }), ft = { "c", "cpp" } },
  { "bfrg/vim-cpp-modern", enabled = vim.fn.has("nvim") == 1, ft = { "c", "cpp" }, dependencies = { "vim-cpp-enhanced-highlight" } },
  {
    "python-mode/python-mode",
    branch = "develop",
    enabled = cond({ "coder", "python" }),
    ft = "python",
    cond = function()
      local handle = io.popen("which python3")
      local result = handle:read("*a")
      handle:close()
      return result ~= ""
    end,
    config = function()
      vim.g.pymode = 1
      vim.g.pymode_rope = 0
      vim.g.pymode_run = 1
      vim.g.pymode_run_bind = '<leader>rr'
      vim.g.pymode_doc = 1
      vim.g.pymode_doc_key = 'K'
      vim.g.pymode_lint = 0
      vim.g.pymode_lint_checker = "pyflakes,pep8"
      vim.g.pymode_lint_write = 1
      vim.g.pymode_virtualenv = 1
      vim.g.pymode_breakpoint = 1
      vim.g.pymode_breakpoint_bind = '<leader>b'
      vim.g.pymode_syntax = 1
      vim.g.pymode_syntax_all = 1
      vim.g.pymode_syntax_indent_errors = vim.g.pymode_syntax_all
      vim.g.pymode_syntax_space_errors = vim.g.pymode_syntax_all
      vim.g.pymode_folding = 0
    end,
  },
  { "davidhalter/jedi-vim", enabled = cond({ "coder", "python" }), ft = "python" },
  { "pangloss/vim-javascript", enabled = cond({ "coder", "javascript" }), ft = { "javascript", "typescript" } },
  {
    "fatih/vim-go",
    enabled = cond({ "coder", "golang" }),
    ft = "go",
    config = function()
      -- vimConfig/conf_map.vim: vim-go mappings
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "go",
        callback = function()
          vim.keymap.set("n", "<leader>gr", "<Plug>(go-run)", { buffer = true })
          vim.keymap.set("n", "<leader>gb", "<Plug>(go-build)", { buffer = true })
          vim.keymap.set("n", "<leader>gt", "<Plug>(go-test)", { buffer = true })
          vim.keymap.set("n", "<leader>gc", "<Plug>(go-coverage)", { buffer = true })
          vim.keymap.set("n", "<leader>gd", "<Plug>(go-doc)", { buffer = true })
          vim.keymap.set("n", "<leader>gi", "<Plug>(go-info)", { buffer = true })
          vim.keymap.set("n", "<leader>ge", "<Plug>(go-rename)", { buffer = true })
          vim.keymap.set("n", "<leader>gg", "<Plug>(go-def-vertical)", { buffer = true })
        end,
      })
    end,
  },
  { "racer-rust/vim-racer", enabled = cond({ "coder", "rust" }), ft = "rust" },
  { "rust-lang/rust.vim", enabled = cond({ "coder", "rust" }), ft = "rust" },
  { "timonv/vim-cargo", enabled = cond({ "coder", "rust" }), ft = "rust" },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    version = "*",
    enabled = not is_wsl() and cond({ "coder" }),
    cmd = "Telescope",
    keys = {
      -- { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>vr", "<cmd>Telescope resume<cr>", desc = "Resume" },
      { "<leader>vp", "<cmd>Telescope pickers<cr>", desc = "Picker" },
      { "<leader>vg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
      { "<leader>vb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>vs", "<cmd>Telescope search_history<cr>", desc = "Search" },
      { "<leader>vc", "<cmd>Telescope command_history<cr>", desc = "Command" },
      { "<leader>vz", "<cmd>Telescope oldfiles<cr>", desc = "Old files" },
      { "<leader>vq", "<cmd>Telescope quickfix<cr>", desc = "Quick fix" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make", cond = function() return vim.fn.executable("make") == 1 end },
      "nvim-telescope/telescope-hop.nvim",
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          layout_config = { scroll_speed = 2 },
          mappings = {
            i = {
              ["<a-p>"] = require("telescope.actions").preview_scrolling_up,
              ["<a-n>"] = require("telescope.actions").preview_scrolling_down,
              [";;"] = function(prompt_bufnr) require("telescope").extensions.hop.hop(prompt_bufnr) end,
            },
            n = {
              ["<a-p>"] = require("telescope.actions").preview_scrolling_up,
              ["<a-n>"] = require("telescope.actions").preview_scrolling_down,
            },
          },
        },
        extensions = {
          fzf = { fuzzy = true, override_generic_sorter = true, override_file_sorter = true, case_mode = "smart_case" },
          hop = {
            keys = { "a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "q", "w", "e", "r", "t", "y", "u", "i", "o", "p" },
            sign_hl = { "WarningMsg", "Title" },
            line_hl = { "CursorLine", "Normal" },
            clear_selection_hl = false,
            trace_entry = true,
            reset_selection = true,
          },
        },
      })
      -- telescope.load_extension("fzf")
      -- telescope.load_extension("hop")

      vim.keymap.set('n', ';vF', '<cmd>Telescope find_files<cr>', { silent = true, desc = "All files" })
      vim.keymap.set('n', ';vy', '<cmd>Telescope yank_history<cr>', { silent = true, desc = "Yanks" })
      vim.keymap.set('n', ';va', '<cmd>Telescope autocommands<cr>', { silent = true, desc = "Auto commands" })
      vim.keymap.set('n', ';vb', '<cmd>Telescope buffers<cr>', { silent = true, desc = "Buffers" })
      vim.keymap.set('n', ';vC', '<cmd>Telescope git_commits<cr>', { silent = true, desc = "Git commits" })
      vim.keymap.set('n', ';vm', '<cmd>Telescope marks<cr>', { silent = true, desc = "Marks" })
      vim.keymap.set('n', ';vM', '<cmd>Telescope keymaps<cr>', { silent = true, desc = "Key maps" })
      vim.keymap.set('n', ';vj', '<cmd>Telescope jumplist<cr>', { silent = true, desc = "Jumps" })
      vim.keymap.set('n', '<leader>fl', '<cmd>Telescope current_buffer_fuzzy_find<cr>', { silent = true, desc = "Lines" })
      vim.keymap.set('n', '<leader>fL', '<cmd>Telescope live_grep<cr>', { silent = true, desc = "Live grep" })
      vim.keymap.set('n', ';vd', '<cmd>Telescope diagnostics<cr>', { silent = true, desc = "Diagnostics" })
      vim.keymap.set('n', ';vq', '<cmd>Telescope quickfix<cr>', { silent = true, desc = "Quickfix" })
      vim.keymap.set('n', ';vQ', '<cmd>Telescope quickfixhistory<cr>', { silent = true, desc = "Quickfix History" })
      vim.keymap.set('n', ';v/', '<cmd>Telescope search_history<cr>', { silent = true, desc = "History /" })
      vim.keymap.set('n', ';v:', '<cmd>Telescope commands<cr>', { silent = true, desc = "Commands" })
      vim.keymap.set('n', ';v;', '<cmd>Telescope command_history<cr>', { silent = true, desc = "Command History" })
    end,
  },

  -- Markdown
  { "preservim/vim-markdown", enabled = cond({ "editor", "markdown" }), ft = "markdown" },
  {
    "epwalsh/obsidian.nvim",
    version = "*",
    lazy = true,
    event = "VeryLazy",
    ft = "markdown",
    dependencies = { "nvim-lua/plenary.nvim", "ibhagwan/fzf-lua", "nvim-telescope/telescope.nvim" },
    keys = {
      { "<leader>on", "<cmd>ObsidianNew<cr>", desc = "Obsidian: New note" },
      { "<leader>of", "<cmd>ObsidianQuickSwitch<cr>", desc = "Obsidian: Quick switch" },
      { "<leader>os", "<cmd>ObsidianSearch<cr>", desc = "Obsidian: Search" },
    },
    config = function()
      local function find_first_existing_vault(paths)
        for _, path in ipairs(paths) do
          local expanded_path = vim.fn.expand(path)
          if vim.fn.isdirectory(expanded_path) == 1 then
            return expanded_path
          end
        end
        return paths[1]
      end

      local vault_dir = find_first_existing_vault({ "~/Document/dotwiki", "~/dotwiki" })
      local ret = vim.fn.isdirectory(vault_dir)
      if ret ~= 1 then
        vim.notify("Obsidian dir not exist: " .. vault_dir .. " ret=" .. ret, vim.log.levels.WARN)
        return
      end

      require("obsidian").setup({
        dir = vault_dir,
        notes_subdir = "notes",
        ui = { enable = false },
        workspaces = { { name = "dotWiki", path = vault_dir } },
        daily_notes = { folder = "notes/dailies", date_format = "%Y-%m-%d", alias_format = "%B %-d, %Y" },
        completion = { nvim_cmp = false, blink = true, min_chars = 2 },
        legacy_commands = false,
        picker = { name = "telescope.nvim" },
      })
    end,
  },
  { "ellisonleao/glow.nvim", enabled = cond({ "editor", "markdown" }), cmd = "Glow", ft = "markdown" },

  -- ============================================================
  -- Facade / UI
  -- ============================================================
  {
    "nvim-lualine/lualine.nvim",
    enabled = cond({ "coder" }),
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      -- 1. Define your custom line counter function
      local function line_info()
        local current = vim.fn.line('.')
        local column = vim.fn.col('.')
        local total = vim.fn.line('$')
        -- Format: "Line:Col / Total"
        return string.format("%d:%d/%d", current, column, total)
      end

      -- 2. Setup lualine with the function in lualine_z
      require('lualine').setup({
        options = {
          icons_enabled = true,
          theme = 'auto',
          component_separators = { left = '⋮', right = '⋮' },
          section_separators = { left = '▌', right = '▐' },
          disabled_filetypes = { 'tpipeline', statusline = {}, winbar = {} },
          always_divide_middle = true,
          always_show_tabline = false,
          globalstatus = true,
        },
        sections = {
          lualine_z = { line_info }
        },
        inactive_sections = {
          lualine_a = {}, lualine_b = {}, lualine_c = { 'filename' },
          lualine_x = { 'location' }, lualine_y = {}, lualine_z = {}
        },
        extensions = { 'fugitive' }
      })
    end,
  },
  {
    "vimpostor/vim-tpipeline",
    lazy = false,
    dependencies = { "nvim-lualine/lualine.nvim" },
    init = function()
      vim.g.tpipeline_autoembed = 0
      vim.opt.laststatus = 0
    end,
  },
  {
    "huawenyu/vim-mark",
    enabled = cond({ "editor" }),
    keys = {
      { "<leader>mm", function()
        vim.cmd('silent! call mark#MarkCurrentWord(expand("<cword>"))')
      end, mode = "n", silent = true, desc = "Colorize current word" },

      { "<leader>mm", function()
        vim.cmd('silent! call mark#GetVisualSelection()')
      end, mode = "v", silent = true, desc = "Colorize visual selection" },

      { "<leader>mx", function()
        vim.cmd('silent! call mark#ClearAll()')
      end, mode = "n", silent = true, desc = "Clear all colorized words" },
    },
    init = function()
      vim.g.mw_no_mappings = 1
    end,
    config = function()
      -- vim.g.mw_no_mappings = 1
      vim.g.mwDefaultHighlightingPalette = 'extended'
      vim.g.mwHistAdd = '/@'
      vim.g.mwAutoSaveMarks = 0
      vim.g.mwMaxMatchPriority = -10
    end,
  },
  { "huawenyu/vim-signature", enabled = cond({ "editor" }) },
  {
    "lukas-reineke/indent-blankline.nvim",
    enabled = cond({ "editor" }) and (vim.g.vim_confi_option.indentline == 1),
    event = "VeryLazy",
    config = function() require("indent_blankline").setup({ enabled = true, indent = { char = "│" } }) end,
  },
  {
    "folke/which-key.nvim",
    enabled = cond({ "editor" }) and (vim.g.vim_confi_option.help_keys == 1),
    event = "VeryLazy",
    config = function()
      vim.g.which_key_preferred_mappings = 1
      require("which-key").setup({
        plugins = {
          marks = false,
          registers = false,
          spelling = { enabled = false, suggestions = 20 },
          presets = {
            operators = false, motions = false, text_objects = false,
            windows = true, nav = true, z = true, g = true,
          },
        },
        replace = { ["<leader>"] = "SPC" },
        delay = 700,
        layout = { height = { min = 4, max = 25 }, width = { min = 20, max = 30 }, spacing = 4, align = "left" },
      })
    end,
  },
  { "chrisbra/NrrwRgn", enabled = cond({ "editor" }), cmd = { "NR", "NRV" } },
  { -- UI: pretty tab
    "fweep/vim-tabber",
    lazy = false,
    init = function()
      -- Use dots, not colons; use semicolons or newlines, not commas
      vim.g.tabber_filename_style = 'filename'
      vim.g.tabber_divider_style = 'unicode'
      -- vim.g.tabber_divider_char = '┃'
      -- vim.g.tabber_selected_marker = '▶' -- Example additional marker
      -- vim.g.tabber_selected_marker = '👉'
    end,
    config = function()
      -- A "stronger" function to force the Red color
      local function force_red_tabs()
        -- Change bg to '#FF0000' for Red, or '#FFFF00' for Yellow
        vim.cmd('highlight! TabLineSel guifg=#FFFFFF guibg=#FF0000 gui=bold')
        -- Force standard inactive tabs to be dark
        vim.cmd('highlight! TabLine guifg=#BCBCBC guibg=#202020 gui=NONE')
      end

      -- 1. Run it now
      force_red_tabs()

      -- 2. Run it again slightly later to beat plugin internal overrides
      vim.schedule(force_red_tabs)

      -- 3. Run it every time you switch themes
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = force_red_tabs,
      })
    end,
  },

  -- { "romgrk/barbar.nvim", enabled = cond({ "editor" }), lazy = false, config = true, }, -- UI: pretty tab
  -- ============================================================
  -- Syntax
  -- ============================================================
  { "justinmk/vim-syntax-extra", enabled = cond({ "coder" }), ft = "vim" },
  { "huawenyu/vim-log-syntax", enabled = cond({ "editor", "log" }), ft = "log" },
  { "huawenyu/vim-autotest-syntax", enabled = cond({ "editor", "log" }), ft = "case" },
  { "nickhutchinson/vim-cmake-syntax", enabled = cond({ "editor" }), ft = "cmake" },
  { "xuhdev/syntax-dosini.vim", enabled = cond({ "editor" }), ft = "dosini" },
  { "tmux-plugins/vim-tmux", enabled = cond({ "editor" }), ft = "tmux" },

  -- ============================================================
  -- Fuzzy Finder & Search
  -- ============================================================
  { "junegunn/fzf", enabled = cond({ "editor" }), build = "./install --all" },
  {
    "junegunn/fzf.vim",
    enabled = cond({ "editor" }),
    lazy = false,
    dependencies = { "junegunn/fzf" },
    config = function()
      vim.g.fzf_prefer_tmux = 1
      vim.g.fzf_history_dir = '~/.local/share/fzf-history'
      vim.g.fzf_colors = {
        fg = { 'fg', 'Normal' }, bg = { 'bg', 'Normal' }, hl = { 'fg', 'Function' },
        ['fg+'] = { 'fg', 'CursorLine', 'CursorColumn', 'Normal' },
        ['bg+'] = { 'bg', 'CursorLine', 'CursorColumn' }, ['hl+'] = { 'fg', 'Statement' },
        info = { 'fg', 'PreProc' }, border = { 'fg', 'Ignore' }, prompt = { 'fg', 'Conditional' },
        pointer = { 'fg', 'Exception' }, marker = { 'fg', 'Keyword' }, spinner = { 'fg', 'Label' }, header = { 'fg', 'Comment' }
      }

      vim.api.nvim_create_user_command('FilePre',
        function(opts)
          local args = opts.args or ''
          local bang = opts.bang
          vim.cmd('call fzf#vim#files(' .. vim.fn.quote(args) .. ', fzf#vim#with_preview(), ' .. (bang and 1 or 0) .. ')')
        end,
        { bang = true, nargs = '?', complete = 'dir' }
      )

      vim.api.nvim_create_user_command('RgType',
        function(opts)
          local args = opts.args or ''
          local bang = opts.bang
          local preview = bang and 'up:60%' or 'right:50%:hidden'
          vim.cmd('call fzf#vim#grep("rg --column --line-number --no-heading --color=always --smart-case -t c ' ..
            vim.fn.shellescape(args) .. '", 1, fzf#vim#with_preview("' .. preview .. '", "?"), ' .. (bang and 1 or 0) .. ')')
        end,
        { bang = true, nargs = '*' }
      )

      vim.keymap.set('n', ';vc', '<c-U>FZFChange<cr>', { silent = true, desc = "Changes" })
      vim.keymap.set('n', ';vt', '<c-U>BTags<cr>', { silent = true, desc = "BTags" })
      vim.keymap.set('n', ';vw', '<c-U>FZFWindows<cr>', { silent = true, desc = "Windows" })
      vim.keymap.set('n', ';vh', '<c-U>FZFHistory<cr>', { silent = true, desc = "History" })
    end,
  },

  -- ============================================================
  -- Clipboard / Yank
  -- ============================================================
  {
    "ojroques/vim-oscyank",
    enabled = cond({ "editor" }),
    lazy = false,
    enabled = cond({ "editor" }),
    keys = {
      { "Y", "<cmd>OSCYank<cr>", mode = "v", desc = "Yank to OSC52" },
      -- { "Y", "<cmd>call YankOSC52(getreg('+'))<cr>", mode = "v", desc = "Yank to OSC52" },
    },
    config = function()
      vim.g.oscyank_max_length = 1
      -- let g:oscyank_term = 'tmux'  " or 'screen', 'kitty', 'default'
      vim.g.oscyank_term = 'tmux'
      vim.g.mwHistAdd = '/@'
      vim.g.mwAutoSaveMarks = 0
      vim.g.mwMaxMatchPriority = -10
    end,
  },

  -- ============================================================
  -- Search / Jump / Motion
  -- ============================================================
  { "huawenyu/vim-grepper", enabled = cond({ "editor" }), cmd = { "Grepper", "GrepperAg", "GrepperGit", "GrepperGrep", "GrepperRg" } },
  {
    "dhananjaylatkar/cscope_maps.nvim",
    enabled = cond({ "coder" }),
    lazy = true,
    cmd = { "Cscope", "CscopeDbAdd" },
    keys = {
      { "<leader>fs", desc = "Find references" },
      { "<leader>fd", desc = "Find definition" },
      { "<leader>fc", desc = "Find callers" },
      { "<leader>fC", desc = "Find callees" },
      { "<leader>fw", desc = "Find assignments" },
      { "<leader>fe", desc = "Egrep pattern" },
      { "<leader>ff", desc = "Find file" },
      { "<leader>fb", desc = "Build cscope db" },
      { "<leader>fr", desc = "Reload cscope db" },
      { "<leader>fz", desc = "Debug cscope" },
      { ";<leader>ff", desc = "Find file (rg)" },
      { "<leader>fs", mode = "v", desc = "Find references (visual)" },
    },
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    opts = {
      disable_maps = true,
      disable_telescope = false,
      cscope = {
        exec = "cscope",
        picker = "telescope",
        skip_picker_for_single_result = true,
        project_rooter = {
          enable = true,
          change_cwd = false,
        },
      },
    },
    config = function(_, opts)
      local cscope_module = require("cscope_maps")
      cscope_module.setup(opts)

      -- Find git root directory
      local function find_git_root()
        local handle = io.popen("git rev-parse --show-toplevel 2>/dev/null")
        local result = handle:read("*a")
        handle:close()
        result = result:gsub("%s+", "")
        return result ~= "" and result or nil
      end

      -- Find all cscope databases from current dir to git root
      local function find_cscope_databases()
        local dbs = {}
        local current_dir = vim.fn.getcwd()
        local git_root = find_git_root()
        local stop_dir = git_root or vim.fn.expand("~")

        local search_dir = current_dir
        while search_dir and search_dir ~= stop_dir and #search_dir > 1 do
          local cscope_file = search_dir .. "/cscope.out"
          if vim.fn.filereadable(cscope_file) == 1 then
            table.insert(dbs, cscope_file)
          end

          local patterns = { "cscope.*.out", "*.cscope.out", ".cscope/cscope.out", "tags/cscope.out" }
          for _, pattern in ipairs(patterns) do
            local found = vim.fn.globpath(search_dir, pattern, false, true)
            for _, db in ipairs(found) do
              if vim.fn.filereadable(db) == 1 then
                table.insert(dbs, db)
              end
            end
          end

          local parent = vim.fn.fnamemodify(search_dir, ":h")
          if parent == search_dir then break end
          search_dir = parent
        end

        if git_root and git_root ~= current_dir then
          local git_cscope = git_root .. "/cscope.out"
          if vim.fn.filereadable(git_cscope) == 1 then
            table.insert(dbs, git_cscope)
          end
        end

        local seen = {}
        local unique_dbs = {}
        for _, db in ipairs(dbs) do
          if not seen[db] then
            seen[db] = true
            table.insert(unique_dbs, db)
          end
        end
        return unique_dbs
      end

      local function load_databases()
        local dbs = find_cscope_databases()
        if #dbs == 0 then
          vim.notify("No cscope databases found", vim.log.levels.WARN)
          return {}
        end
        opts.cscope.db_file = dbs[1]
        cscope_module.setup(opts)
        for i = 2, #dbs do
          vim.cmd("Cscope db add " .. dbs[i])
        end
        vim.notify("Loaded " .. #dbs .. " cscope database(s)", vim.log.levels.INFO)
        return dbs
      end

      local function get_visual_selection()
        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")
        local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)
        if #lines == 0 then return "" end
        lines[1] = lines[1]:sub(start_pos[3], -1)
        if #lines > 1 then
          lines[#lines] = lines[#lines]:sub(1, end_pos[3])
        end
        return table.concat(lines, "\n")
      end

      local map_opts = { silent = true, noremap = true }

      vim.keymap.set('n', '<leader>fs', ":Cscope find s <C-r><C-w><CR>",
        vim.tbl_extend("force", map_opts, { desc = "Find references (Telescope)" }))
      vim.keymap.set('n', '<leader>fd', ":Cscope find g <C-r><C-w><CR>",
        vim.tbl_extend("force", map_opts, { desc = "Find definition (Telescope)" }))
      vim.keymap.set('n', '<leader>fc', ":Cscope find c <C-r><C-w><CR>",
        vim.tbl_extend("force", map_opts, { desc = "Find callers (Telescope)" }))
      vim.keymap.set('n', '<leader>fC', ":Cscope find d <C-r><C-w><CR>",
        vim.tbl_extend("force", map_opts, { desc = "Find callees (Telescope)" }))
      vim.keymap.set('n', '<leader>fw', ":Cscope find a <C-r><C-w><CR>",
        vim.tbl_extend("force", map_opts, { desc = "Find assignments (Telescope)" }))
      vim.keymap.set('n', '<leader>fe', function()
        vim.ui.input({ prompt = "Egrep pattern: " }, function(input)
          if input and input ~= "" then vim.cmd("Cscope find e " .. input) end
        end)
      end, vim.tbl_extend("force", map_opts, { desc = "Egrep pattern (Telescope)" }))
      vim.keymap.set('n', '<leader>fb', ":Cscope db build<CR>",
        vim.tbl_extend("force", map_opts, { desc = "Build cscope database" }))
      vim.keymap.set('v', '<leader>fs', function()
        local selection = get_visual_selection()
        if selection ~= "" then vim.cmd("Cscope find s " .. selection) end
      end, vim.tbl_extend("force", map_opts, { desc = "Find references (visual/Telescope)" }))
      vim.keymap.set('n', '<leader>fr', function() load_databases() end,
        vim.tbl_extend("force", map_opts, { desc = "Reload cscope databases" }))
      vim.keymap.set('n', '<leader>fz', function()
        local dbs = find_cscope_databases()
        vim.notify("Found " .. #dbs .. " cscope databases:\n" .. table.concat(dbs, "\n"), vim.log.levels.INFO)
      end, vim.tbl_extend("force", map_opts, { desc = "Debug: Show found databases" }))

      -- Find file via telescope
      vim.keymap.set('n', '<leader>ff', function()
        require('telescope.builtin').find_files({
          prompt_title = "Find(rg) File List",
          find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
        })
      end, vim.tbl_extend("force", map_opts, { desc = "Find file (Telescope)" }))
      vim.keymap.set('n', ';ff', function()
        require('telescope.builtin').find_files({
          prompt_title = "Find(rg) File List",
          find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
        })
      end, vim.tbl_extend("force", map_opts, { desc = "Find file (Telescope)" }))

      -- Initial load
      load_databases()

      -- Auto-reload on directory change
      vim.api.nvim_create_autocmd("DirChanged", {
        pattern = "*",
        callback = function() load_databases() end,
      })
    end,
  },
  {
    "huawenyu/c-utils.vim",
    enabled = cond({ "coder" }),
    lazy = true,
    keys = {
      { "<leader><leader>", mode = { "n", "v" }, desc = "Preview Tag" },
      { ";bb", desc = "Search rg all" },
      { "<leader>bb", desc = "Search rg all" },
      { "<leader>gg", mode = { "n", "v" }, desc = "Search to quickfix" },
      { ";gg", mode = { "n", "v" }, desc = "Search to loclist" },
      { "<leader>vv", mode = { "n", "v" }, desc = "Search all to quickfix" },
      { ";vv", mode = { "n", "v" }, desc = "Search all to loclist" },
    },
    config = function()
      local g = vim.g
      local home = os.getenv("HOME")

      g.tlTokenList = { "FIXME @wilson", "TODO @wilson", "XXX @wilson" }
      g.ctrlsf_mapping = { next = "n", prev = "N" }
      g.utilquickfix_file = home .. "/.vim/vim.quickfix"
      g.c_utils_map = g.c_utils_map or 1
      g.c_utils_prefer_dir = g.c_utils_prefer_dir or ""

      local function get_prefer_dir() return (g.c_utils_prefer_dir ~= "") and g.c_utils_prefer_dir or "daemon/wad" end

      vim.keymap.set('n', '<leader><leader>', function() vim.fn["VimMotionPreview"]() end, { silent = true, desc = "Preview Tag" })
      vim.keymap.set('v', '<leader><leader>', function() vim.fn["VimMotionPreview"]() end, { silent = true, desc = "Preview Tag" })

      local function prepare_grep(is_visual, dir, to_qf)
        vim.cmd("let g:grepper = {}")

        -- 1. Sync the visual marks to the current selection
        if is_visual == 1 then
          -- This "kicks" Neovim to update the '< and '> marks
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>gv<Esc>", true, false, true), "nx", false)
        end

        local target_dir = ""
        if dir == "prefer" then
          -- Check if it's a global vim function or a script function
          target_dir = get_prefer_dir()
        end

        -- 2. Get the command string
        local cmd = vim.fn["utilgrep#Grep"](0, is_visual, target_dir, to_qf)

        -- 3. Feed to command line without Enter
        local prefix = is_visual == 1 and ":<C-u>" or ":"
        local keys = vim.api.nvim_replace_termcodes(prefix .. cmd, true, false, true)
        vim.api.nvim_feedkeys(keys, "n", false)
      end


      -- Grep in Preferred Directory
      vim.keymap.set('n', '<leader>gg', function() prepare_grep(0, "prefer", 1) end, { desc = "Search to QF (edit)" })
      vim.keymap.set('n', ';gg',        function() prepare_grep(0, "prefer", 0) end, { desc = "Search to Loc (edit)" })
      vim.keymap.set('v', '<leader>gg', function() prepare_grep(1, "prefer", 1) end, { desc = "Search selection to QF (edit)" })
      vim.keymap.set('v', ';gg',        function() prepare_grep(1, "prefer", 0) end, { desc = "Search selection to Loc (edit)" })

      -- Grep All (Empty Directory)
      vim.keymap.set('n', '<leader>vv', function() prepare_grep(0, "", 1) end, { desc = "Search all to QF (edit)" })
      vim.keymap.set('n', ';vv',        function() prepare_grep(0, "", 0) end, { desc = "Search all to Loc (edit)" })
      vim.keymap.set('v', '<leader>vv', function() prepare_grep(1, "", 1) end, { desc = "Search all selection to QF (edit)" })
      vim.keymap.set('v', ';vv',        function() prepare_grep(1, "", 0) end, { desc = "Search all selection to Loc (edit)" })
    end,
  },
  {
    "chengzeyi/fzf-preview.vim",
    enabled = cond({ "editor" }),
    lazy = false,
    dependencies = { "junegunn/fzf.vim" },
  },
  {
    "huawenyu/fzf-cscope.vim",
    enabled = false and cond({ "editor" }),
    dependencies = { "chengzeyi/fzf-preview.vim", "huawenyu/vim-basic" },
    keys = {
      -- File commands
      { "<leader>ff", "<cmd>CSFileFilter<cr>", desc = "Find files" },
      { ";ff", "<cmd>CSFileFilter!<cr>", desc = "Find files (all)" },

      -- Symbol/References
      { "<leader>fs", "<cmd>call cscope#preview('0', 'n', 0, 0)<cr>", desc = "Find references" },
      { "<leader>fS", "<cmd>call cscope#preview('0', 'n', 0, 1)<cr>", desc = "Find references (advanced)" },

      -- Function calls
      { "<leader>fc", "<cmd>call cscope#preview('3', 'n', 1, 0)<cr>", desc = "Find callers" },
      { "<leader>fC", "<cmd>call cscope#preview('2', 'n', 1, 0)<cr>", desc = "Find callees" },

      -- Assignment
      { "<leader>fw", "<cmd>call cscope#preview('9', 'n', 0, 0)<cr>", desc = "Find assignments" },
      { "<leader>fW", "<cmd>call cscope#preview('9', 'n', 0, 1)<cr>", desc = "Find assignments (advanced)" },

      -- Text search
      { "<leader>fe", "<cmd>call utilgrep#Grep(0, 0, '', 1)<cr>", desc = "Search project" },
      { "<leader>f1", "<cmd>call utilgrep#Grep(0, 0, 'daemon/wad', 1)<cr>", desc = "Search in wad" },
      { "<leader>f2", "<cmd>call utilgrep#Grep(0, 0, 'cmf/plugin', 1)<cr>", desc = "Search in cmf" },
    },
    init = function()
      -- These run before the plugin loads
      ensure_apt_packages({ "ripgrep", "fd-find", "cscope", "universal-ctags", "bat", "gawk" })
    end,
    config = function()
      -- Configuration that runs after plugin loads
      vim.g.fzf_cscope_map = vim.g.fzf_cscope_map or 1
      vim.g.fzfCscopeFilter = vim.g.fzfCscopeFilter or "daemon/wad/"
    end,
  },
  -- vim-cool and vim-searchlight may conflict with improved-search, disable them
  { "romainl/vim-cool", enabled = false },
  { "PeterRincker/vim-searchlight", enabled = false },
  {
    "huawenyu/improved-search.nvim",
    enabled = cond({ "editor" }),
    lazy = false,
    config = function()
      local search = require("improved-search")

      -- We don't necessarily need the 'search' variable if we use Neovim's internal yank
      vim.keymap.set("x", "*", function()
        -- 1. Grab visual selection
        vim.cmd('noau normal! "vy')
        local text = vim.fn.getreg('v')

        if type(text) ~= "string" or text == "" then return end

        -- 2. Escape for literal search
        local escaped = vim.fn.escape(text, '/\\^$*.~[]')

        -- 3. Use 'feedkeys' with 't' flag (simulate real typing)
        -- <C-u> clears the range ('<,'>) that appears when pressing '/' in visual mode
        local keys = vim.api.nvim_replace_termcodes("<Esc>/<C-u>" .. escaped, true, false, true)
        vim.fn.feedkeys(keys, "n")
      end, { desc = "Search selection - edit before enter" })
    end,
  },
  {
    "kwkarlwang/bufjump.nvim",
    enabled = cond({ "editor" }),
    event = "VeryLazy",
    config = function()
      require("bufjump").setup({
        forward_key = ";i",
        backward_key = ";o",
        on_success = function() vim.cmd([[normal! g`"zz]]) end,
      })
    end,
  },
  { "huawenyu/vim-windowswap", enabled = cond({ "editor" }) },
  {
    "preservim/tagbar",
    enabled = cond({ "coder" }),
    cmd = { "TagbarToggle", "Tagbar", "TagbarOpen" },
    keys = { { "<leader>vt", "<cmd>TagbarToggle<cr>", desc = "Toggle Tagbar" } },
    config = function()
      vim.g.tagbar_autofocus = 0
      vim.g.tagbar_position = 'left'
      vim.g.tagbar_sort = 0
      vim.g.tagbar_width = 40
      vim.g.tagbar_compact = 1
      vim.g.tagbar_silent = 1
      vim.g.tagbar_indent = 2
      vim.g.tagbar_foldlevel = 4
      vim.g.tagbar_iconchars = { '+', '-' }
      vim.g.tagbar_map_hidenonpublic = "`"
      vim.g.tagbar_map_close = "q"

      if vim.fn.executable('ctags') == 1 then
        local path_ctags = vim.fn.systemlist("which ctags")[1]
        vim.g.rust_use_custom_ctags_defs = 1
        vim.g.tagbar_type_rust = {
          ctagsbin = path_ctags, ctagstype = 'rust',
          kinds = { 'n:modules', 's:structures:1', 'i:interfaces', 'c:implementations', 'f:functions:1', 'g:enumerations:1', 't:type aliases:1:0', 'v:constants:1:0', 'M:macros:1', 'm:fields:1:0', 'e:enum variants:1:0', 'P:methods:1' },
          sro = '::',
          kind2scope = { n = 'module', s = 'struct', i = 'interface', c = 'implementation', f = 'function', g = 'enum', t = 'typedef', v = 'variable', M = 'macro', m = 'field', e = 'enumerator', P = 'method' },
        }
      end

      if vim.fn.executable('tag4md.py') == 1 then
        local path_mdctags = vim.fn.systemlist("which tag4md.py")[1]
        vim.g.markdown_use_custom_ctags_defs = 1
        vim.g.tagbar_type_markdown = {
          ctagsbin = path_mdctags, ctagstype = 'markdown', ctagsargs = '-f - --sort=yes --sro=»',
          kinds = { 'n:modules', 's:sections', 'i:images' }, sro = '»', kind2scope = { n = 'module', s = 'section' }, sort = 0,
        }
      end

      if vim.fn.executable('tag4log') == 1 then
        local path_logctags = vim.fn.systemlist("which tag4log")[1]
        vim.g.log_use_custom_ctags_defs = 1
        vim.g.tagbar_type_log = {
          ctagsbin = path_logctags, ctagstype = 'log',
          kinds = { 'n:modules', 's:sections', 'i:images' }, sro = '»', kind2scope = { n = 'module', s = 'section' }, sort = 0,
        }
      end
    end,
  },

  -- { "huawenyu/quickfix-reflector.vim", enabled = cond({ "editor" }) }, -- Disable it for it confuse neovim and create multiple-quickfix window
  {
    'stevearc/quicker.nvim',
    enabled = cond({ "editor" }),
    ft = "qf",
    ---@module "quicker"
    ---@type quicker.SetupOptions
    opts = {},
  },

  {
    "folke/todo-comments.nvim",
    enabled = cond({ "editor" }),
    cmd = { "TodoLocList", "TodoQuickFix", "TodoTelescope" },
    dependencies = { "nvim-telescope/telescope.nvim" },
    keys = {
      { "<leader>vl", "<cmd>TodoLocList<cr>", desc = "Todo Location List" },
      { "<leader>vt", "<cmd>TodoTelescope<cr>", desc = "Todo Telescope" },
    },
    config = function()
      require("todo-comments").setup()
      vim.keymap.set('n', '<leader>vT', function() require("telescope").extensions.todo_comments.todo_comments() end, { silent = true, desc = "Telescope Todo" })
    end,
  },
  { "windwp/nvim-autopairs", enabled = cond({ "editor" }), event = "InsertEnter" },
  { "tpope/vim-surround", enabled = cond({ "editor" }) },
  { "tpope/vim-rsi", enabled = cond({ "editor" }) },
  { "ciaranm/securemodelines", enabled = cond({ "editor" }) },
  {
    "huawenyu/vim-unimpaired",
    enabled = cond({ "editor" }),
    lazy = false,
    init = function()
      -- Configure unimpaired
      vim.g.unimpaired_listchar = 0

      -- Map F12 to toggle listchars
      vim.keymap.set('n', '<F12>', '<Plug>(SwitchListchars)', { noremap = true, silent = true, desc = "Toggle listchars" })
    end,
  },
  {
    "christoomey/vim-tmux-navigator",
    enabled = cond({ "basic", "editor" }) and vim.env.TMUX_PANE ~= nil,
    lazy = false,
    keys = {
      { "<a-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate left (Alt)" },
      { "<a-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate down (Alt)" },
      { "<a-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate up (Alt)" },
      { "<a-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate right (Alt)" },
      { "<a-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Navigate previous" },
    },
    init = function()
      vim.g.tmux_navigator_disable_when_zoomed = 1
      vim.g.tmux_navigator_no_mappings = 1
      vim.keymap.set('n', '<c-h>', '<c-w>h', { noremap = true, silent = true })
      vim.keymap.set('n', '<c-j>', '<c-w>j', { noremap = true, silent = true })
      vim.keymap.set('n', '<c-k>', '<c-w>k', { noremap = true, silent = true })
      vim.keymap.set('n', '<c-l>', '<c-w>l', { noremap = true, silent = true })
    end
  },
  { "mg979/vim-visual-multi", enabled = cond({ "editor" }) },
  {
    "phaazon/hop.nvim",
    enabled = cond({ "editor" }),
    keys = {
      { ";s", "<cmd>HopChar1CurrentLine<cr>", desc = "Hop to char (current line)" },
      { ";;", "<cmd>HopChar2<cr>", desc = "Hop to 2-char sequence" },
    },
    config = function() require("hop").setup({ keys = "asdfghjklqwertyuiopzxcvbnm" }) end,
  },
  { "tpope/vim-abolish", enabled = cond({ "editor" }) },
  { "tpope/vim-repeat", enabled = cond({ "editor" }) },
  { "rhysd/clever-f.vim", enabled = cond({ "editor" }) },
  {
    "huawenyu/vim-motion",
    enabled = cond({ "editor" }),
    dependencies = { "skywind3000/vim-preview" },
    keys = {
      { "<leader>;",  function() vim.cmd('call VimMotionTag()') end, mode = "n", silent = true, desc = "Jump Tag" },
      { "<leader><leader>", function() vim.cmd('call VimMotionPreview()') end, mode = { "n", "v" }, desc = "Preview Tag" },
    },
  },
  {
    "junegunn/vim-easy-align",
    enabled = cond({ "editor" }),
    event = "VeryLazy",
    cmd = "EasyAlign",
    keys = {
      { "<leader>ga", mode = "v" },
      { "<leader>cc", mode = "v" },
      { "<leader>cc", mode = "n" },
    },
    opts = {
      ignore_comment = false,
    },
    config = function()
      vim.g.easy_align_delimiters = {
        [">"] = { pattern = ">>\\|=>\\|>" },
        ["/"] = {
          pattern = "//\\+\\|/\\*\\|\\*/",
          delimiter_align = "l",
          ignore_groups = { "!Comment" },
        },
        ["]"] = {
          pattern = "[[\\]]",
          left_margin = 0,
          right_margin = 0,
          stick_to_left = 0,
        },
        [")"] = {
          pattern = "[()]",
          left_margin = 0,
          right_margin = 0,
          stick_to_left = 0,
        },
        d = {
          pattern = " \\(\\S\\+\\s*[;=]\\)\\@=",
          left_margin = 0,
          right_margin = 0,
        },
        m = {
          pattern = "/\\\\$/",
          stick_to_left = 0,
          left_margin = 2,
          right_margin = 0,
        },
      }
    end,
  },

  -- ============================================================
  -- Auto Completion
  -- ============================================================
  { "rafamadriz/friendly-snippets", enabled = cond({ "editor" }) and vim.loop.os_uname().sysname == "Linux" },
  {
    "saghen/blink.cmp",
    enabled = cond({ "editor" }) and vim.loop.os_uname().sysname == "Linux",
    version = "1.*",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
      require('blink.cmp').setup({
        appearance = { nerd_font_variant = 'normal' },
        completion = {
          documentation = { auto_show = false, window = { border = 'single' } },
          ghost_text = { enabled = true }
        },
        sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
        fuzzy = { implementation = "lua", prebuilt_binaries = { download = false } },
      })
    end,
  },
  {
    "gelguy/wilder.nvim",
    enabled = cond({ "editor" }),
    build = ":UpdateRemotePlugins",
    config = function()
      local wilder = require("wilder")
      wilder.setup({ modes = { ":", "/", "?" }, enable_cmdline_enter = 0 })
      wilder.set_option("renderer", wilder.popupmenu_renderer({
        highlighter = wilder.basic_highlighter(),
        highlights = { accent = wilder.make_hl("WilderAccent", "Pmenu", { { {}, {}, { foreground = "#f4468f" } } }) },
      }))
      vim.api.nvim_set_keymap("c", "<Tab>", "<Cmd>call wilder#main#start()<CR>", { noremap = true, silent = true })
    end,
  },

  { "nvim-treesitter/nvim-treesitter", enabled = cond({ "editor" }), build = ":TSUpdate", lazy = false },
  {
    "nvim-treesitter/nvim-treesitter-context",
    enabled = cond({ "coder" }),
    event = "BufReadPost", -- Loads when you start reading a file
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
      max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
      -- ... other config
    },
  },
  {
    "neovim/nvim-lspconfig",
    enabled = cond({ "coder" }),
    event = "VeryLazy",
    dependencies = { "ojroques/nvim-lspfuzzy", "williamboman/nvim-lsp-installer" },
    config = function()
      vim.lsp.config('clangd', {})
      vim.lsp.config('rust_analyzer', {})
      vim.lsp.config('lua_ls', {})
      vim.lsp.enable({ 'lua_ls', 'clangd', 'rust_analyzer' })
      require('lspfuzzy').setup({})

      local opts = { noremap = true, silent = true }
      -- Use Telescope for searching Definitions, References, and Diagnostics
      vim.api.nvim_set_keymap('n', ';fd', '<cmd>Telescope lsp_definitions<CR>', vim.tbl_extend("force", opts, { desc = "Telescope: Goto Definition" }))
      vim.api.nvim_set_keymap('n', ';fs', '<cmd>Telescope lsp_references<CR>', vim.tbl_extend("force", opts, { desc = "Telescope: References" }))
      vim.api.nvim_set_keymap('n', ';fN', '<cmd>Telescope diagnostics<CR>', vim.tbl_extend("force", opts, { desc = "Telescope: Diagnostics" }))

      -- Rename and Goto Next/Prev stay as standard LSP (no Telescope picker exists for these)
      vim.api.nvim_set_keymap('n', ';fr', '<cmd>lua vim.lsp.buf.rename()<CR>', vim.tbl_extend("force", opts, { desc = "Refactor rename" }))

      vim.api.nvim_set_keymap('n', ';fn', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', vim.tbl_extend("force", opts, { desc = "Diag prev" }))
      vim.api.nvim_set_keymap('n', ';fp', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', vim.tbl_extend("force", opts, { desc = "Diag next" }))

      vim.lsp.handlers["textDocument/publishDiagnostics"] = function() end
      vim.cmd([[ command! Format execute 'lua vim.lsp.buf.formatting()' ]])
    end,
  },

  -- ============================================================
  -- Text Objects
  -- ============================================================
  { "wellle/targets.vim", enabled = cond({ "editor" }) },
  {
    "terryma/vim-expand-region",
    enabled = cond({ "editor" }),
    keys = {
      { "W", "<Plug>(expand_region_expand)", mode = { "n", "v" }, desc = "Expand region" },
      { "B", "<Plug>(expand_region_shrink)", mode = { "n", "v" }, desc = "Shrink region" },
    },
  },
  {
    "kana/vim-textobj-user",
    enabled = cond({ "editor" }),
    dependencies = {
      "michaeljsmith/vim-indent-object", "glts/vim-textobj-indblock", "kana/vim-textobj-entire",
      "mattn/vim-textobj-url", "kana/vim-textobj-diff", "Julian/vim-textobj-brace",
      "whatyouhide/vim-textobj-xmlattr", "pocke/vim-textobj-markdown", "glts/vim-textobj-comment",
      "preservim/vim-textobj-sentence", "kana/vim-textobj-function",
    },
  },

  -- ============================================================
  -- Tools
  -- ============================================================

  { "tpope/vim-eunuch", enabled = cond({ "admin" }) },
  {
    "voldikss/vim-floaterm",
    enabled = cond({ "editor" }),
    event = "VeryLazy",
    cmd = { "FloatermKill", "FloatermNew", "FloatermShow", "FloatermUpdate" },
    opts = {
      autoinsert = true,
      shell = "/bin/bash",
    },
    config = function()
      local compile_run_swap = 0

      local function compile_run(mode)
        local command = ":FloatermNew --name=repl --wintype=split --position=bottom --autoclose=0 height=0.4 --width=0.6 --title=Repl-" .. vim.bo.filetype

        local fname_org = vim.fn.expand("%")
        local fname, fname_bin, fpath_bin

        if mode == "v" then
          fname = vim.fn.expand("%")
          fname_bin = vim.fn.expand("%:r")
          fpath_bin = "./" .. vim.fn.expand("%:r")
        else
          fname = "/tmp/vim.out" .. compile_run_swap
          fname_bin = "/tmp/vim.out" .. compile_run_swap
          fpath_bin = "/tmp/vim.out" .. compile_run_swap
        end

        local ft = vim.bo.filetype
        if ft == "c" then
          command = command .. string.format("  gcc -pthread -lrt -g -O0 -finstrument-functions -fms-extensions -o %s %s && %s", fname_bin, fname_org, fpath_bin)
        elseif ft == "cpp" then
          command = command .. string.format("  g++ -pthread -lrt -g -O0 -finstrument-functions -fms-extensions -o %s %s && %s", fname_bin, fname_org, fpath_bin)
        elseif ft == "rust" then
          if mode == "v" then
            local fname_bin_t = vim.fn.fnamemodify(fname_bin, ":t")
            command = command .. string.format("  cargo test '%s::test::' -- --nocapture", fname_bin_t)
          else
            command = command .. string.format("  rust-script %s", fname_org)
          end
        elseif ft == "java" then
          command = command .. string.format("  java %s", fname_org)
        elseif ft == "javascript" then
          command = command .. string.format("  node %s", fname_org)
        elseif ft == "python" then
          command = command .. string.format("  python %s", fname_org)
        elseif ft == "tcl" then
          command = command .. string.format("  expect %s", fname_org)
        elseif ft == "awk" then
          command = command .. string.format("  LC_ALL=C awk -f %s", fname_org)
        elseif ft == "sh" then
          command = command .. string.format("  LC_ALL=C bash %s", fname_org)
        elseif ft == "markdown" then
          vim.cmd(string.format("!rm -rf %s", fname_bin))
          vim.cmd("AsyncStop!")
          command = string.format("!pandoc -f markdown --standalone --to man %s -o %s", fname_org, fname_bin)
          vim.cmd(command)
          command = string.format("  Snman %s", fname_bin)
        elseif ft == "nroff" then
          command = string.format("  Snman %s", fname_org)
        else
          vim.notify("Not support filetype: " .. ft, vim.log.levels.WARN)
          return
        end

        vim.cmd("echomsg 'Debug: " .. command .. "'")
        vim.cmd("silent execute '" .. command .. "'")
      end

      local function is_git_repo()
        local output = vim.fn.system("git rev-parse --is-inside-work-tree 2>/dev/null")
        return vim.v.shell_error == 0 and vim.trim(output) == "true"
      end

      local function is_git_sha(word)
        return word:match("^%x{40}$") ~= nil
      end

      local function get_man_word()
        local col = vim.fn.col(".")
        local line = vim.fn.getline(".")
        local char = line:sub(col, col)

        -- Loose mode: word includes alphanumeric, underscore, ., -
        if char:match("%w") or char:match("[.-]") then
          local saved_iskeyword = vim.bo.iskeyword
          for _, key in ipairs({ 2, 1, 0 }) do
            vim.bo.iskeyword = saved_iskeyword
            if key == 2 then
              vim.bo.iskeyword = saved_iskeyword .. ",.,-"
            elseif key == 1 then
              vim.bo.iskeyword = saved_iskeyword .. ",-"
            end
            local the_word = vim.fn.expand("<cword>")

            -- Check git-SHA
            if the_word:match("^%x{7,40}$") then
              vim.bo.iskeyword = saved_iskeyword
              return { "Git", the_word }
            end

            -- Check man
            if vim.fn.system("man -w " .. the_word) then
              vim.bo.iskeyword = saved_iskeyword
              return { "Man", the_word }
            end

            -- Check tldr
            if vim.fn.system("tldr --list | grep -e '^" .. the_word .. "$'") == 0 then
              vim.bo.iskeyword = saved_iskeyword
              return { "Tldr", the_word }
            end

            the_word = ""
          end
          vim.bo.iskeyword = saved_iskeyword
        end

        -- Strict mode: only alphanumeric and underscore
        if char:match("%w") then
          return { "none", vim.fn.expand("<cword>") }
        end
        return { "none", "" }
      end

      local function man_show(mode)
        local cmd = ""
        local subcmd = ""
        local word = ""

        if mode == "k" then
          local words = get_man_word()
          if not words[2] or words[2] == "" then
            word = vim.fn.expand("<cword>")
          else
            word = words[2]
            if words[1] == "Man" then
              vim.cmd(string.format("Man %s", word))
              return
            elseif words[1] == "Git" then
              vim.fn.system(string.format("git show --stat -p %s > /tmp/vim_a.diff", words[2]))
              if vim.v.shell_error == 0 then
                cmd = "PreviewFile /tmp/vim_a.diff"
              end
            end
          end
        end

        if cmd == "" then
          cmd = ":FloatermNew --name=Help --wintype=split --position=bottom --autoclose=1 --height=0.4 width=0.6 --title=Man-" .. vim.bo.filetype

          if word == "" then
            -- Use hw#misc#getWord equivalent
            word = vim.fn.expand("<cword>")
          end

          subcmd = string.format("tldr %s -e", word)
          cmd = cmd .. " " .. subcmd
        end

        vim.cmd("silent execute '" .. cmd .. "'")
      end

      local function toggle_terminal(mode)
        local command = ":FloatermNew --name=Shell --wintype=split --position=bottom --autoclose=0 height=0.4 --width=0.6 --title=Shell bash"
        vim.cmd("silent execute '" .. command .. "'")
      end

      -- Keymaps
      vim.keymap.set("n", "<leader>ee", function()
        vim.cmd("w")
        compile_run("n")
      end, { desc = "(*repl) Run me" })

      vim.keymap.set("v", "<leader>ee", function()
        vim.cmd("'<,'>w! /tmp/vim.out")
        compile_run("v")
      end, { desc = "(*repl) Run me" })

      vim.keymap.set("v", ";ee", function()
        vim.cmd("make " .. vim.fn.expand("%:t:r"))
        vim.cmd("copen")
        vim.cmd("wincmd p")
      end, { desc = "(diag) Make buffer" })

      vim.keymap.set("n", "K", function()
        man_show("k")
      end, { desc = "(Man) Show help" })

      vim.keymap.set("n", "<leader>K", function()
        man_show("n")
      end, { desc = "(Man) Tldr" })

      vim.keymap.set("v", "<leader>K", function()
        man_show("v")
      end, { desc = "(Man) Tldr" })

      -- Terminal toggle (only if no vim-floaterm-repl or toggleterm)
      vim.keymap.set({ "n", "v" }, "<C-\\>", function()
        toggle_terminal("n")
      end, { desc = "(Tool) Terminal" })

      vim.keymap.set("i", "<C-\\>", function()
        vim.cmd("silent execute ':FloatermNew --name=Shell --wintype=split --position=bottom --autoclose=0 height=0.4 --width=0.6 --title=Shell bash'")
      end, { desc = "(Tool) Terminal" })

      -- Custom Tldr command
      vim.api.nvim_create_user_command("Tldr", function(opts)
        vim.cmd(string.format("FloatermNew --name=Help --wintype=split --position=bottom --autoclose=1 height=0.4 --width=0.6 --title=Tldr tldr -e %s", opts.args))
      end, { nargs = 1 })
    end,
  },
  { "huawenyu/vim-floaterm-repl", enabled = cond({ "editor" }), cmd = "FloatermRepl" },
  {
    "huawenyu/vim-floaterm-repl",
    enabled = cond({ "editor" }),
    cmd = "FloatermRepl",
    ft = "markdown",
    keys = {
      { ";ee", "<cmd>FloatermRepl<cr>", ft = "markdown", desc = "(repl) Run me" },
    },
  },

  { -- Open file:line
    "wsdjeg/vim-fetch",
    enabled = cond({ "editor" }),
    lazy = false,
    config = function()
      -- Initialize the table if it doesn't exist to avoid overwriting defaults
      vim.g.fetch_patterns = vim.g.fetch_patterns or {}

      -- Append the new pattern to the existing list
      table.insert(vim.g.fetch_patterns, {
        pattern = "%f line %l",
        column = 0
      })
    end,
  },

  { "nhooyr/neoman.vim", enabled = cond({ "editor" }), cmd = { "Nman", "Snman", }, },

  {
    "akinsho/toggleterm.nvim",
    enabled = cond({ "admin" }),
    config = function()
      require("toggleterm").setup({ open_mapping = [[<c-\>]], size = 20, direction = "float", start_in_insert = true })
      vim.keymap.set('n', '<c-\\>', '<cmd>ToggleTerm<cr>', { silent = true, desc = "Toggle Terminal" })
    end,
  },
  {
    "huawenyu/asyncrun.vim",
    enabled = cond({ "admin" }),
    config = function()
      -- Mappings
      vim.keymap.set('n', '<leader>gc', ':AsyncStop! <bar> AsyncTask gitclean-dryrun<CR>', { desc = "(git)clean-dryrun" })
      vim.keymap.set('n', '<leader>gx', ':AsyncStop! <bar> AsyncTask gitclean<CR>', { desc = "(git)clean" })
      vim.keymap.set('n', '<leader>f]', ':AsyncRun! tagme<CR>', { desc = "(tool)Auto generate tags" })

      -- Settings
      vim.g.asyncrun_silent = 1
      vim.g.asyncrun_open = 8
      vim.g.asyncrun_rootmarks = { '.git', '.svn', '.root', '.project', '.hg' }
      vim.g.asynctasks_term_reuse = 1
      vim.g.asynctasks_term_focus = 1
      vim.g.asynctasks_term_pos = 'bottom'

      -- Link tasks file if needed
      vim.fn.system('ln -sf ~/.vim_tasks.ini ~/.vim/tasks.ini')

      -- Template
      vim.g.asynctasks_template = {}
      vim.g.asynctasks_template.cargo = {
        "[project-init]",
        "command=cargo update",
        "cwd=<root>",
        "",
        "[project-build]",
        "command=cargo build",
        "cwd=<root>",
        "errorformat=%. %#--> %f:%l:%c",
        "",
        "[project-run]",
        "command=cargo run",
        "cwd=<root>",
        "output=terminal",
      }
    end,
  },
  {
    "folke/edgy.nvim",
    enabled = cond({ "coder" }),
    event = "VeryLazy",
    config = function()
      require("which-key").setup({
        left = {
          { title = "Explore-legacy", ft = "nerdtree", pinned = false, open = "NERDTree", close = "NERDTreeClose", size = { height = 0.4 } },
          { title = "Functions", ft = "tagbar", pinned = false, open = "TagbarOpen", close = "TagbarClose", size = { height = 0.4 } },
          { title = "Explore-neo", ft = "neo-tree", pinned = false, filter = function(buf) return vim.b[buf].neo_tree_source == "filesystem" end, size = { height = 0.4 } },
          { title = "Buffers", ft = "neo-tree", filter = function(buf) return vim.b[buf].neo_tree_source == "buffers" end, pinned = false, collapsed = false, open = "Neotree position=top buffers", size = { height = 0.25 } },
          { title = "Git-status", ft = "neo-tree", filter = function(buf) return vim.b[buf].neo_tree_source == "git_status" end, pinned = false, collapsed = false, open = "Neotree position=top git_status", size = { height = 0.25 } },
          { title = function() return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0) or "[No Name]", ":t") end, ft = "Outline", pinned = false, open = "SymbolsOutlineOpen" },
          { title = "Outline", ft = "voomtree", pinned = false, open = "VoomToggle", size = { height = 0.5 } },
          "neo-tree",
        },
        bottom = {
          { ft = "toggleterm", size = { height = 0.3 }, filter = function(buf, win) return vim.api.nvim_buf_get_name(buf):match("term://") end },
          { ft = "lazyterm", title = "LazyTerm", size = { height = 0.4 }, filter = function(buf) return not vim.b[buf].lazyterm_cmd end },
          "Trouble",
          { ft = "qf", buftype = 'quickfix', title = 'QuickFix', pinned = true, open = "copen" },
          { ft = "help", size = { height = 20 }, filter = function(buf) return vim.bo[buf].buftype == "help" end },
          { ft = "spectre_panel", size = { height = 0.4 } },
        },
        open_files_do_not_replace_types = { "terminal", "Trouble", "qf", "edgy" },
        animate = { enabled = false, fps = 100, cps = 120, on_begin = function() vim.g.minianimate_disable = true end, on_end = function() vim.g.minianimate_disable = false end, spinner = { frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }, interval = 80 } },
        exit_when_last = false,
        close_when_all_hidden = true,
        wo = { winbar = true, winfixwidth = true, winfixheight = false, winhighlight = "WinBar:EdgyWinBar,Normal:EdgyNormal", spell = false, signcolumn = "no" },
        icons = { closed = " ", open = " " },
        fix_win_height = vim.fn.has("nvim-0.10.0") == 0,
      })
    end
  },
  { "sk1418/blockit", enabled = cond({ "editor" }), cmd = "Block" },
  {
    "rmagatti/auto-session",
    enabled = false and cond({ "editor" }),
    lazy = false,
    config = function()
      local session_dir = vim.fn.expand('~/.vim/tmp-sessions')
      if vim.fn.isdirectory(session_dir) == 0 then vim.fn.mkdir(session_dir, 'p') end
      vim.g.auto_session_root_dir = session_dir
      require('auto-session').setup({
        log_level = 'error', auto_save = true, auto_create = true, auto_restore = false,
        auto_restore_last_session = false, auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
        allowed_dirs = { "~/work", "~/workref" },
      })
      vim.o.sessionoptions = "blank,buffers,curdir,folds,tabpages,winsize,winpos,terminal,localoptions"
      vim.keymap.set('n', '<leader>sr', '<cmd>SessionRestore<cr>', { silent = true, desc = "Restore workspace session" })
      vim.keymap.set('n', '<leader>ss', '<cmd>SessionSave<cr>', { silent = true, desc = "Save workspace session" })
    end,
  },
  {
    "preservim/nerdtree",
    cmd = { "NERDTreeToggle", "NERDTreeFind", "NERDTree" },
    keys = {
      { "<leader>ve", "<cmd>NERDTreeToggle<CR>", desc = "Toggle NERDTree" },
      { "<leader>vf", "<cmd>NERDTreeFocus<CR>", desc = "Focus NERDTree" },
    },
    init = function()
      vim.g.NERDTreeMapMenu = 'M'
      vim.g.NERDTreeMapJumpNextSibling = 'gJ'
      vim.g.NERDTreeMapJumpPrevSibling = 'gK'
      vim.g.NERDTreeMapOpenInTab = 'gT'
      vim.g.NERDTreeMouseMode = 3
      vim.g.NERDTreeMinimalUI = 1
      vim.g.NERDTreeDirArrows = 1
      vim.g.NERDTreeRespectWildIgnore = 1
      vim.g.NERDTreeShowBookmarks = 0
      vim.g.NERDTreeFileLines = 0
      vim.g.NERDTreeShowHidden = 1
      vim.g.NERDTreeQuitOnOpen = 0
      vim.g.NERDTreeStatusline = 0
      vim.g.NERDTreeWinSize = 25
      vim.g.NERDTreeIgnore = {
        '^.git$', '^.DS_Store$', 'null', ".DS_Store", "thumbs.db", '^.idea$', '__pycache__$',
        '^.vscode$', 'tags', '.tags', '.tagx', '.cscope.files', 'cscope.in.out', 'cscope.out', 'cscope.po.out',
        '.jshintrc', '.jscsrc', '.eslintignore', '.eslintrc.json', '.gitattributes', '.git',
        '.ccls-cache', '.devops', '.arcconfig', '.vscode',
      }
      vim.g.NERDTreeHighlightCursorline = 1
      vim.g.NERDSpaceDelims = 1
      vim.g.NERDCompactSexyComs = 1
      vim.g.NERDDefaultAlign = 'left'
      vim.g.NERDAltDelims_java = 1
      vim.g.NERDCommentEmptyLines = 1

      -- vim.api.nvim_create_autocmd("BufEnter", { pattern = "NERD_tree_*", callback = function() if vim.fn.winnr("$") == 1 then vim.cmd("q") end end })
      -- vim.api.nvim_create_autocmd("VimEnter", { callback = function() if vim.fn.argc() == 0 and vim.fn.isdirectory(vim.fn.expand("%")) == 0 then vim.cmd("NERDTree") end end })
    end,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    enabled = cond({ "editor" }),
    cmd = "Neotree",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
    config = function()
      require("neo-tree").setup({
        default_component_configs = {
          indent = { indent_size = 2, padding = 1, with_expanders = true },
          icon = { folder_closed = "", folder_open = "", folder_empty = "", default = "" },
          git_status = { symbols = { added = "✚", modified = "", deleted = "", renamed = "➜", untracked = "★", ignored = "◌", unstaged = "✗", staged = "✓" } },
        },
        filesystem = {
          auto_open = false, follow_current_file = true, close_folders_on_open = false,
          hijack_netrw = true, use_libuv_file_watcher = true, group_empty_dirs = true,
          filtered_items = {
            visible = false, hide_dotfiles = true, hide_gitignored = true,
            hide_by_name = { ".DS_Store", "thumbs.db", "tags", '.tags', '.tagx', '.cscope.files', 'cscope.in.out', 'cscope.out', 'cscope.po.out', '.jshintrc', '.jscsrc', '.eslintignore', '.eslintrc.json', '.gitattributes', '.git', '.ccls-cache', '.devops', '.arcconfig', '.vscode' },
          },
          follow_current_file = { enabled = true, leave_dirs_open = true },
        },
        window = {
          mappings = {
            ["<TAB>"] = "toggle_node", ["z"] = "collapse_all", ["o"] = "open",
            ["O"] = function(state) print("Pls expand_all by search: /*") end,
            ["<C-f>"] = "scroll_down", ["<C-b>"] = "scroll_up",
          },
        },
      })
      vim.keymap.set('n', '<leader>vE', '<c-U>Neotree toggle<cr>', { silent = true, desc = "Explore File (Toggle)" })
      vim.keymap.set('n', '<leader>vF', '<c-U>Neotree reveal<cr>', { silent = true, desc = "Explore Focus (Reveal)" })
    end
  },
  {
    "huawenyu/VOoM",
    enabled = cond({ "editor", "log" }),
    cmd = { "VoomToggle", "Voom" },
    keys = {
      { "<leader>vo", "<cmd>VoomToggle<cr>", mode = "n", silent = true, desc = "Toggle Voom outline" },
      { "<leader>v0", "<cmd>VoomToggle fmr<cr>", mode = "n", silent = true, desc = "Toggle Voom outline (fmr)" },
    },
  },

  -- ============================================================
  -- Git Integration
  -- ============================================================
  {
    "tpope/vim-fugitive",
    enabled = cond({ "editor", "git" }),
    -- cmd is still useful for commands not covered by keys
    cmd = { "Git", "Gstatus", "Gvdiff" },
    keys = {
      { "<leader>gl", "<cmd>GV<cr>", desc = "Git Log side by side" },
      { "<leader>gd", "<cmd>Gvdiff<cr>", desc = "Git Diff review" },
      { "<leader>gD", "<cmd>DiffReview git show<cr>", desc = "Git Diff review tabs" },
      { "<leader>gb", "<cmd>Git blame<cr>", desc = "Git Blame" },
      { "<leader>bb", "<cmd>Git blame<cr>", desc = "Git Blame" },
      { "<leader>gs", "<cmd>Gstatus<cr>", desc = "Git Status" },
    },
    config = function()
      vim.g.fugitive_legacy_commands = 0
      vim.g.fugitive_git_executable = 'git'
    end
  },
  {
    "junegunn/gv.vim",
    enabled = cond({ "editor" }),
    cmd = "GV",
    dependencies = { "tpope/vim-fugitive" },
    keys = {
      { "<leader>gl", "<cmd>GV<cr>", desc = "Git Log side by side" },
    },
  },
  { -- will hide some importance output message, don't use it
    "folke/noice.nvim",
    enabled = false and cond({ "editor" }),
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      -- Optional: "rcarriga/nvim-notify" (only if you want other notifications to look pretty)
    },
    opts = {
      routes = {
        -- 1. Silence specific search messages
        {
          filter = {
            event = "msg_show",
            any = {
              { find = "Search hit BOTTOM" },
              { find = "Search hit TOP" },
            },
          },
          opts = { skip = true },
        },
        -- 2. Route tall or verbose messages to a split
        {
          filter = {
            event = "msg_show",
            any = {
              { find = "Last set from" }, -- Catch verbose output
              { min_height = 5 },        -- Catch any tall message
            },
          },
          view = "split",
        },
        -- 3. Route errors to split
        {
          filter = {
            event = { "msg_show", "emsg", "notification" },
            kind = "error",
          },
          view = "split",
        },
        -- 4. Route E### errors to split
        {
          filter = {
            event = "notification",
            any = {
              { find = "E%d+" },
            },
          },
          view = "split",
        },
      },
      -- Basic presets to keep it from taking over your UI too much
      presets = {
        bottom_search = true, -- puts search at the bottom
        command_palette = true, -- positions the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
      },
    },
  },
  { "mhinz/vim-signify", enabled = false, },
  { "mattn/gist-vim", enabled = cond({ "editor", "extra" }), cmd = "Gist" },
  {
    "airblade/vim-gitgutter",
    enabled = false, -- better: gitsigns.nvim
    cmd = "GitGutterToggle",
    dependencies = { "tpope/vim-fugitive" },
    event = "BufReadPre",
    config = function()
      local function is_git_repo()
        local handle = io.popen("git rev-parse --is-inside-work-tree 2>/dev/null")
        local result = handle:read("*a")
        handle:close()
        return result:gsub("%s+", "") == "true"
      end
      vim.g.gitgutter_enabled = is_git_repo() and 1 or 0
      vim.g.gitgutter_map_keys = 0
      vim.g.gitgutter_max_signs = 500
      vim.g.gitgutter_show_msg_on_hunk_jumping = 0
      vim.g.gitgutter_override_sign_column_highlight = 1
      vim.g.gitgutter_highlight_lines = 1
      vim.g.gitgutter_preview_win_floating = 1
      vim.g.gitgutter_diff_relative_to = 'index'
      vim.g.gitgutter_sign_added = '+'
      vim.g.gitgutter_sign_modified = '>'
      vim.g.gitgutter_sign_removed = '-'
      vim.g.gitgutter_sign_removed_first_line = '^'
      vim.g.gitgutter_sign_modified_removed = '<'

      vim.keymap.set('n', ';gv', '<c-U>GitGutterToggle<cr>', { silent = true, desc = "Git Gutter Toggle" })
      vim.keymap.set('n', ';gr', '<c-U>GitGutter<cr>', { silent = true, desc = "Git Gutter" })
      vim.keymap.set('n', ';gn', '<Plug>(GitGutterNextHunk)', { silent = true, desc = "Next Hunk" })
      vim.keymap.set('n', ';gp', '<Plug>(GitGutterPrevHunk)', { silent = true, desc = "Previous Hunk" })
      vim.keymap.set('n', ';ga', '<Plug>(GitGutterStageHunk)', { silent = true, desc = "Stage Hunk" })
      vim.keymap.set('n', ';gu', '<Plug>(GitGutterUndoHunk)', { silent = true, desc = "Undo Hunk" })
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    enabled = cond({ "editor" }),
    event = "BufReadPre",
    config = function()
      local function is_yadm_repo()
        local handle = io.popen("yadm rev-parse --is-inside-work-tree 2>/dev/null")
        local result = handle:read("*a")
      end
      local function is_me_yadm_repo()
        local handle = io.popen("me-yadm rev-parse --is-inside-work-tree 2>/dev/null")
        local result = handle:read("*a")
        handle:close()
        return result:gsub("%s+", "") == "true"
      end
      require('gitsigns').setup({
        signs = { add = { text = '+' }, change = { text = '>' }, delete = { text = '-' }, topdelete = { text = '^' }, changedelete = { text = '<' } },
        signcolumn = true, numhl = false, linehl = true, word_diff = false,
        watch_gitdir = { follow_files = true }, auto_attach = true, attach_to_untracked = false,
        current_line_blame = false, sign_priority = 6, update_debounce = 100, max_file_length = 40000,
        on_attach = function(bufnr)
          local gs = require('gitsigns')
          if is_yadm_repo() then vim.b.gitsigns_git_command = "yadm"
          elseif is_me_yadm_repo() then vim.b.gitsigns_git_command = "me-yadm" end
          vim.keymap.set('n', ';gn', gs.next_hunk, { buffer = bufnr, desc = "Next Hunk" })
          vim.keymap.set('n', ';gp', gs.prev_hunk, { buffer = bufnr, desc = "Previous Hunk" })
          vim.keymap.set('n', ';ga', gs.stage_hunk, { buffer = bufnr, desc = "Stage Hunk" })
          vim.keymap.set('n', ';gu', gs.undo_stage_hunk, { buffer = bufnr, desc = "Undo Hunk" })
          vim.keymap.set('n', ';gv', gs.toggle_signs, { buffer = bufnr, desc = "Toggle GitGutter" })
          vim.keymap.set('n', ';gr', function() gs.preview_hunk() end, { buffer = bufnr, desc = "Preview Hunk" })
          vim.keymap.set({ 'o', 'x' }, 'ih', ':Gitsigns select_hunk<CR>', { buffer = bufnr })
        end,
      })
    end,
  },

  -- ============================================================
  -- Other Utilities
  -- ============================================================
  { "huawenyu/tldr.nvim", enabled = not is_wsl() and vim.fn.executable("tldr") == 1 and cond({ "editor" }) },
  { "s1n7ax/nvim-window-picker", enabled = cond({ "editor", "tool" }) },

  -- ============================================================
  -- Libraries
  -- ============================================================
  { "vim-jp/vital.vim", enabled = cond({ "coder", "library" }) },
  { "google/vim-maktaba", enabled = cond({ "coder", "library" }) },
  { "tomtom/tlib_vim", enabled = cond({ "coder", "library" }) },

  -- ============================================================
  -- Debug
  -- ============================================================
  {
    "huawenyu/vimlogger",
    enabled = cond({ "admin", "coder" }),
    config = function()
      if vim.g.vim_confi_option.debug == 1 then
        vim.cmd("silent! call logger#init('ALL', ['/tmp/vim.log'])")
      end
    end
  },
}

-- ============================================================
-- Lazy.nvim Setup
-- ============================================================

require("lazy").setup({
  spec = plugins,
  defaults = { lazy = true },
  install = { colorscheme = { "jellybeans" } },
  checker = { enabled = false },
  performance = {
    rtp = {
      disabled_plugins = { "gzip", "matchit", "matchparen", "netrwPlugin", "tarPlugin", "tohtml", "tutor", "zipPlugin" },
    },
  },
})

-- ============================================================
-- Post-Setup & Autocommands
-- ============================================================

-- Set colorscheme AFTER lazy setup
vim.cmd.colorscheme("jellybeans")

-- Search highlight: background color instead of underline
vim.api.nvim_set_hl(0, 'Search', { bg = '#f0a0c0', fg = '#302028', ctermbg = 217, ctermfg = 16, cterm = nil, gui = nil })


local function load_vimscript_config()
  local after_file = vim.fn.expand("~/.vimrc.after")
  if vim.fn.filereadable(after_file) == 1 then
    vim.cmd("source " .. after_file)
  end
end

load_vimscript_config()

if cond({ "coder" }) then
  pcall(function() require("nvim_utils") end)
end

-- Autocommands
if cond({ "coder" }) then
  vim.api.nvim_create_augroup("ugly_set", { clear = true })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = "ugly_set",
    pattern = "*",
    callback = function()
      if vim.fn.has("cscope") == 1 then pcall(vim.cmd, "call cscope#LoadCscope()") end
      vim.opt.lazyredraw = false
      vim.cmd("redraw!")
    end,
  })

  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    group = "ugly_set",
    pattern = "*",
    callback = function() vim.opt.signcolumn = "yes" end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = "ugly_set",
    pattern = { "tagbar", "nerdtree", "voomtree", "qf" },
    callback = function() vim.opt_local.signcolumn = "no" end,
  })

  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      vim.defer_fn(function() vim.cmd("redrawstatus") end, 500)
    end,
  })

  local function messages_to_quickfix()
    local messages = vim.fn.execute("messages")
    local qf_entries = {}
    for line in messages:gmatch("[^\r\n]+") do
      table.insert(qf_entries, { text = line })
    end
    vim.fn.setqflist(qf_entries)
    vim.cmd("copen")
  end

  vim.api.nvim_create_user_command("Messages", messages_to_quickfix, {})
end

