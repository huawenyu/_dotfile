-- vim: set ft=lua autoindent cindent expandtab   tabstop=2 shiftwidth=2 softtabstop=2:

-- ~/.config/nvim/init.lua
-- Performance-optimized Neovim configuration with lazy.nvim
--
-- KEYMAPS  (LEADER = <Space>)
--   Navigation   h/j/k/l=windows  c-n/p=quickfix  a-n/p=loclist  gf=open-file  ;1-9=tabs
--   Find         ff=cscope→git→rg  ;ff=git-ls-files  fd/fs=LSP def/ref  fq=find-word
--                fc/C/w=LSP callers/callees/assign  fl=fuzzy-buf  fL=live-grep
--   Picker       vv=resume  vp=live-grep  vb=buffers  vz=oldfiles  vq=quickfix
--                ;vF=files  ;vC=commits  ;vm=marks  ;vj=jumps  ;vd=diag  ;v/=history
--   View         ve=NERDTree  vE=neo-tree  vt=tagbar  vo=outline  vl=todo
--   Git          gl=log  gd=diff  gb=blame  gs=status  vg/vG=diffview  gn/p=hunk
--   Edit         gcc=comment  ct=trim-ws  ci=indent  cm=rm-^M  cn=collapse-blank
--                ga=align  vr=replace  K=man  ;s/;;=hop  gp=select-pasted
--   Run          ee=compile-run  mk/ma=make-wad/all  gc/gx=git-clean  f]=tags
--   General      q=quit-all  ;q=smart-close  Esc=clear-hl  <leader><leader>=trace
--   Alt          a-e/w/t/b/g/q = NERDTree/window/tagbar/buffers/git/quit
--                a-f=search  a-s=git-status  a-/=todo  a-./,=jump-indent

-- ============================================================
-- Core Settings & Bootstrap
-- ============================================================

-- System detection
local function is_windows()
  return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end

local function is_ubuntu()
  if is_windows() then return false end
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


-- Avoid "SIXEL IMAGE" noise from terminals advertising sixel to Neovim.
-- tmux passes through sixel queries to the outer terminal, which responds
-- positively even though the terminfo (screen-256color/tmux-256color) lacks
-- the capability. xterm-256color has no sixel, so Neovim never negotiates it.
if vim.env.TERM and (vim.env.TERM:find("^tmux") or vim.env.TERM:find("^screen")) then
  vim.env.TERM = "xterm-256color"
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

-- Expose to vimscript (vim-plug compatibility for conf_plug.vim guards)
vim.cmd([[
  function! HasPlug(name) abort
    return luaeval('_G.HasPlug(_A)', a:name)
  endfunction
  function! HasNoPlug(name) abort
    return luaeval('_G.HasNoPlug(_A)', a:name)
  endfunction
]])

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


local function get_visual_or_cword_simple()
  local mode = vim.fn.mode()
  if mode:find("[vV]") then
    vim.cmd([[normal! "vy"]])
    return vim.fn.getreg("v")
  end
  return vim.fn.expand("<cword>")
end

-- ============================================================
-- Global Configuration
-- ============================================================

vim.g.vim_confi_option = {
  mode = is_windows() and {'basic', 'theme', 'local', 'editor', 'log', 'admin'} or {'basic', 'theme', 'local', 'editor', 'admin', 'coder', 'log', 'c', 'markdown', 'git', 'script', 'tool'},
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
  wiki_dirs = {'~/dotwiki', '~/wiki', '~/dotfiles'},
  tmp_file = '/tmp/vim.tmp',
}

if os.getenv("mode") then
  vim.g.vim_confi_option.mode = {os.getenv("mode")}
end

if os.getenv("debug") then
  vim.g.vim_confi_option.debug = 1
end

if vim.g.vim_confi_option.remap_leader == 1 then
  vim.g.mapleader = " "
  vim.g.maplocalleader = " "
  vim.keymap.set('', 'Q', '<Nop>')
end

-- ============================================================
-- Plugin Specifications
-- ============================================================

local plugins = {
  -- ============================================================
  -- Others tools/repo manage through plugin
  -- ============================================================
  { "huawenyu/dotfiles", build = "git switch master", lazy = true, build = symlink_repo("~/dotfiles") },
  { "huawenyu/zsh-local", build = "git switch master", lazy = true, build = symlink_repo("~/.oh-my-zsh/custom/plugins/zsh-local") },
  { "zsh-users/zsh-completions", lazy = true, build = symlink_repo("~/.oh-my-zsh/custom/plugins/zsh-completions") },
  { "dooblem/bsync", lazy = true, build = symlink_repo("~/bin/repo-bsync") },

  -- ============================================================
  -- Basic / Core
  -- ============================================================
  { "tpope/vim-sensible", enabled = cond({ "basic", "log", "editor" }), lazy = false },
  {
    "echasnovski/mini.ai",
    enabled = false and cond({ "basic", "log", "editor" }),
    event = "VeryLazy",
    config = function()
      require("mini.ai").setup({
        -- Table with textobject id as fields, textobject specification as values.
        custom_textobjects = nil,

        mappings = {
          -- Main textobject prefixes
          around = "a",
          inside = "i",

          -- Next/last variants
          around_next = "an",
          inside_next = "in",
          around_last = "al",
          inside_last = "il",

          -- Move cursor to edges of textobject
          goto_left = "g[",
          goto_right = "g]",
        },

        -- Number of lines within which textobject is searched
        n_lines = 50,

        -- Search behavior
        search_method = "cover_or_next",

        -- Silent mode
        silent = false,
      })
    end,
  },
  {
    "huawenyu/vim-basic",
    enabled = cond({ "basic", "log", "editor" }),
    build = "git switch master",
    lazy = false,
    keys = {
      { "<leader>ct", mode = { "n", "x" }, desc = "[misc] Clear trailing whitespace *" },
      { "<leader>ci", mode = { "n", "x" }, desc = "[misc] Fix indentation" },
      { "<leader>cm", mode = { "n", "x" }, desc = "[misc] Remove ^M (Windows line endings) *" },
      { "<leader>cn", mode = { "n", "x" }, desc = "[misc] Collapse blank lines *" },
    },
    config = function()
      require("vim-basic").setup()

      vim.keymap.set('n', '<c-h>', '<c-w>h', { noremap = true, silent = true })
      vim.keymap.set('n', '<c-j>', '<c-w>j', { noremap = true, silent = true })
      vim.keymap.set('n', '<c-k>', '<c-w>k', { noremap = true, silent = true })
      vim.keymap.set('n', '<c-l>', '<c-w>l', { noremap = true, silent = true })
    end,
  },
  {
    "huawenyu/vimConfig",
    enabled = cond({ "basic", "log", "editor" }),
    build = "git switch master",
    lazy = false,
    dependencies = {
      "huawenyu/vim-motion",
      "huawenyu/vim-basic",
    },
    keys = {
      { "<leader>vr", mode = { "n", "v" }, desc = "Replace" },
      { "<leader>mk", desc = "[misc] Make wad *" },
      { "<leader>ma", desc = "[misc] Make all *" },
      { "<leader>mw", desc = "Dictionary" },
      { "<leader>mf", desc = "[qf] Quickfix filter *" },
      { "<leader>mc", desc = "[qf] Quickfix add caller *" },
      { ";q", desc = "SmartClose" },
      { "<leader>gg", mode = { "n", "v" }, desc = "[find] Search to-quickfix *" },
      { ";gg", mode = { "n", "v" }, desc = "[find] Search to-loclist *" },
    },
    config = function()
      require("vimconfig").setup()
      local has_rg = vim.fn.executable("rg") == 1
      local grepper_cmd = has_rg and "GrepperRg" or "Grepper"
      local prefer_dir = vim.g.c_utils_prefer_dir
      if prefer_dir == nil or prefer_dir == "" then prefer_dir = "daemon/wad" end
      local dir_arg = " " .. prefer_dir
      vim.keymap.set("n", "<leader>gg", function()
        local word = vim.fn.expand("<cword>")
        if word == "" then return end
        vim.g["grepper"].quickfix = 1
        local cmd = grepper_cmd .. " -w " .. vim.fn.shellescape(word) .. dir_arg
        vim.fn.feedkeys(":" .. cmd, "n")
      end, { silent = true, desc = "[find] Search to-quickfix *" })
      vim.keymap.set("v", "<leader>gg", function()
        local _, sl, sc = unpack(vim.fn.getpos("'<"))
        local _, el, ec = unpack(vim.fn.getpos("'>"))
        local lines = vim.fn.getline(sl, el)
        if #lines == 0 then return end
        lines[1] = lines[1]:sub(sc)
        lines[#lines] = lines[#lines]:sub(1, ec)
        local text = table.concat(lines, " ")
        if #text < 2 then return end
        vim.g["grepper"].quickfix = 1
        local cmd = grepper_cmd .. " -F -- " .. vim.fn.shellescape(text) .. dir_arg
        vim.fn.feedkeys(":" .. cmd, "n")
      end, { silent = true, desc = "[find] Search to-quickfix *" })
      vim.keymap.set("n", ";gg", function()
        local word = vim.fn.expand("<cword>")
        if word == "" then return end
        vim.g["grepper"].quickfix = 0
        local cmd = grepper_cmd .. " -w " .. vim.fn.shellescape(word)
        vim.fn.feedkeys(":" .. cmd, "n")
      end, { silent = true, desc = "[find] Search to-loclist *" })
      vim.keymap.set("v", ";gg", function()
        local _, sl, sc = unpack(vim.fn.getpos("'<"))
        local _, el, ec = unpack(vim.fn.getpos("'>"))
        local lines = vim.fn.getline(sl, el)
        if #lines == 0 then return end
        lines[1] = lines[1]:sub(sc)
        lines[#lines] = lines[#lines]:sub(1, ec)
        local text = table.concat(lines, " ")
        if #text < 2 then return end
        vim.g["grepper"].quickfix = 0
        local cmd = grepper_cmd .. " -F -- " .. vim.fn.shellescape(text)
        vim.fn.feedkeys(":" .. cmd, "n")
      end, { silent = true, desc = "[find] Search to-loclist *" })
    end,
  },

  -- ============================================================
  -- Color Themes
  -- ============================================================
  { "huawenyu/jellybeans.vim", enabled = cond({ "log", "editor" }), build = "git switch master", lazy = false },

  -- ============================================================
  -- Coder Plugins
  -- ============================================================
  { "tpope/vim-commentary",
    enabled = cond({ "coder" }),
    keys = {
      { "gcc", "gcc", mode = "n", remap = true, desc = "[misc] Comment current line *" },
      { "gc",  "gc",  mode = "v", remap = true, desc = "[misc] Comment selection *" },
    },
  },
  {
    "huawenyu/nerdcommenter",
    enabled = cond({ "coder" }),
    build = "git switch master",
    config = function() require("nerdcommenter").setup() end,
  },
  { "Chiel92/vim-autoformat", enabled = cond({ "coder" }) },
  { "vim-scripts/iptables", enabled = cond({ "coder" }), lazy = false, },
  { "vim-scripts/genutils", enabled = cond({ "coder" }), lazy = false, },
  { "tenfyzhong/CompleteParameter.vim", enabled = cond({ "coder", "extra" }) },
  { "FooSoft/vim-argwrap", enabled = cond({ "coder", "extra" }) },
  { "ericcurtin/CurtineIncSw.vim", enabled = cond({ "coder" }) },
  { "huawenyu/neogdb2.vim", enabled = cond({ "coder" }), build = "git switch master", },
  { "chrisbra/vim-diff-enhanced", enabled = cond({ "editor" }) },
  { "fidian/hexmode", enabled = cond({ "editor" }), cmd = "Hexmode" },

  -- Language Specific
  { "huawenyu/vim-linux-coding-style", enabled = cond({ "coder", "c" }), build = "git switch master", ft = { "c", "cpp" } },
  { "octol/vim-cpp-enhanced-highlight", enabled = cond({ "coder", "c" }), ft = { "c", "cpp" } },
  { "bfrg/vim-cpp-modern", enabled = vim.fn.has("nvim") == 1, ft = { "c", "cpp" }, dependencies = { "vim-cpp-enhanced-highlight" } },
  {
    "python-mode/python-mode",
    branch = "develop",
    enabled = cond({ "coder", "python" }),
    ft = "python",
    pin = true,
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
  { "davidhalter/jedi-vim", enabled = cond({ "coder", "python" }), ft = "python", pin = true, },
  { "pangloss/vim-javascript", enabled = cond({ "coder", "javascript" }), ft = { "javascript", "typescript" }, pin = true, },
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
    enabled = cond({ "editor" }),
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make", cond = function() return vim.fn.executable("make") == 1 end },
      "nvim-telescope/telescope-hop.nvim",
    },
    init = function()
      vim.keymap.set('n', ';vF', '<cmd>Telescope find_files<cr>', { silent = true, desc = "[picker] All files *" })
      vim.keymap.set('n', ';vd', '<cmd>Telescope diagnostics<cr>', { silent = true, desc = "Diagnostics" })

      vim.keymap.set('n', '<leader>vk', function()
        require('telescope.builtin').keymaps({
          default_text = " *$",
          attach_mappings = function(_, map)
            vim.schedule(function()
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Left><Left><Left>", true, false, true), "n", false)
            end)
            return true
          end,
        })
      end, { silent = true, desc = "Key maps (Filtered by endwith-*)" })

      vim.keymap.set('n', '<leader>vv', '<cmd>Telescope resume<cr>', { silent = true, desc = "[picker] Resume *" })
      vim.keymap.set('n', '<leader>vp', '<cmd>Telescope pickers<cr>', { silent = true, desc = "[picker] Picker" })
      vim.keymap.set('n', '<leader>vb', '<cmd>Telescope buffers<cr>', { silent = true, desc = "[picker] Buffers" })
      vim.keymap.set('n', '<leader>vh', '<cmd>Telescope oldfiles<cr>', { silent = true, desc = "[picker] Old files *" })
      vim.keymap.set('n', '<leader>vy', '<cmd>Telescope yank_history<cr>', { silent = true, desc = "[picker] Yanks" })
      -- vim.keymap.set('n', '<leader>va', '<cmd>Telescope autocommands<cr>', { silent = true, desc = "[picker] Auto commands" })
      vim.keymap.set('n', '<leader>vc', '<cmd>Telescope git_commits<cr>', { silent = true, desc = "[picker] Git commits *" })
      vim.keymap.set('n', '<leader>vm', '<cmd>Telescope marks<cr>', { silent = true, desc = "[picker] Marks *" })
      vim.keymap.set('n', '<leader>vj', '<cmd>Telescope jumplist<cr>', { silent = true, desc = "[picker] Jumps *" })

      vim.keymap.set('n', '<leader>vq', '<cmd>Telescope quickfix<cr>', { silent = true, desc = "[qf] Quick fix *" })
      vim.keymap.set('n', '<leader>vQ', '<cmd>Telescope quickfixhistory<cr>', { silent = true, desc = "[qf] Quickfix History" })
      vim.keymap.set('n', '<leader>v/', '<cmd>Telescope search_history<cr>', { silent = true, desc = "[picker] History /" })
      vim.keymap.set('n', '<leader>v:', '<cmd>Telescope commands<cr>', { silent = true, desc = "[picker] Commands" })
      vim.keymap.set('n', '<leader>v;', '<cmd>Telescope command_history<cr>', { silent = true, desc = "[picker] Command History" })

      -- find/files
      vim.keymap.set('n', '<leader>ft', '<cmd>Telescope current_buffer_tags<cr>', { silent = true, desc = "[find] Tags *" })
      vim.keymap.set('n', '<leader>fl', '<cmd>Telescope current_buffer_fuzzy_find<cr>', { silent = true, desc = "[find] Lines *" })
      vim.keymap.set('v', '<leader>fl',
        function()
          require("telescope.builtin").current_buffer_fuzzy_find({
            default_text = "'" .. get_visual_or_cword_simple(),
          })
        end,
        { silent = true, desc = "[find] Lines (Word Under Cursor) *" }
      )
      vim.keymap.set({'n', 'v'}, '<leader>fL',
        function()
          require("telescope.builtin").current_buffer_fuzzy_find({
            default_text = "'" .. get_visual_or_cword_simple(),
          })
        end,
        { silent = true, desc = "[find] Lines (Word Under Cursor) *" }
      )

      vim.keymap.set('n', '<leader>fe', '<cmd>Telescope live_grep<cr>', { silent = true, desc = "[find] Live grep *" })
      vim.keymap.set('v', '<leader>fe',
        function()
          require("telescope.builtin").live_grep({
            default_text = "'" .. get_visual_or_cword_simple(),
          })
        end,
        { silent = true, desc = "[find] Live grep (Word Under Cursor) *" }
      )
      vim.keymap.set({'n', 'v'}, '<leader>fE',
        function()
          require("telescope.builtin").live_grep({
            default_text = "'" .. get_visual_or_cword_simple(),
          })
        end,
        { silent = true, desc = "[find] Live grep (Word Under Cursor) *" }
      )

      vim.keymap.set({'n', 'v'}, '<leader>fF',
        function()
          require("telescope.builtin").find_files({
            default_text = "'" .. get_visual_or_cword_simple(),
          })
        end,
        { silent = true, desc = "[find] Find Files (Word Under Cursor) *" }
      )


      -- Find files using Telescope (Windows-compatible alternative to cscope_maps)
      if is_windows() then
        vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<cr>', { silent = true, desc = "[find] Find file *" })
        vim.keymap.set('n', ';ff', '<cmd>Telescope find_files<cr>', { silent = true, desc = "[find] Find files (all) *" })
      end


      -- Tasks picker via telescope (parse comments as doc, show command in preview)
      local function parse_tasks_with_doc(tasks_file)
        local tasks = {}
        local lines = vim.fn.readfile(tasks_file)
        local pending_doc = {}
        local current_name = nil
        local current_commands = {}
        local first_command_found = false

        for i, line in ipairs(lines) do
          local trimmed = vim.fn.substitute(line, "^\\s*", "", "")

          if vim.fn.match(trimmed, "^\\[[^]]*\\]$") == 0 then
            -- Save previous task with its doc
            if current_name then
              tasks[current_name] = {
                name = current_name,
                doc = table.concat(pending_doc, "\n"),
                commands = current_commands,
              }
              pending_doc = {}  -- Clear for next task's pre-task docs
            end
            -- Start new task
            current_name = string.match(trimmed, "%[(.-)%]")
            current_commands = {}
            first_command_found = false
          elseif current_name then
            -- Inside task body: check if it's a comment or command
            if not first_command_found then
              local hash_idx = line:match("^%s*#%s*(.*)$")
              local semic_idx = line:match("^%s*;%s*(.*)$")
              local comment = semic_idx or hash_idx or ""
              if comment ~= "" and comment ~= trimmed then
                table.insert(pending_doc, comment)
              end
            end
            if trimmed:match("^command[^=]*=") then
              first_command_found = true
              table.insert(current_commands, trimmed)
            end
          else
            -- Before any task: collect comments as pending doc
            local hash_idx = line:match("^%s*#%s*(.*)$")
            local semic_idx = line:match("^%s*;%s*(.*)$")
            local comment = semic_idx or hash_idx or ""
            if comment ~= "" and comment ~= trimmed then
              table.insert(pending_doc, comment)
            end
          end
        end
        -- Save last task
        if current_name then
          tasks[current_name] = {
            name = current_name,
            doc = table.concat(pending_doc, "\n"),
            commands = current_commands,
          }
        end
        return tasks
      end

      local pick_task = (function()
        return function()
          local vimrc = vim.env.MYVIMRC or vim.fn.expand('<sfile>:p')
          local tasks_file = vim.fn.fnamemodify(vimrc, ':p:h') .. "/tasks.ini"
          if vim.fn.filereadable(tasks_file) ~= 1 then
            vim.notify("tasks.ini not found: " .. tasks_file, vim.log.levels.WARN)
            return
          end

          local tasks_map = parse_tasks_with_doc(tasks_file)
          local task_list = vim.tbl_values(tasks_map)
          if #task_list == 0 then
            vim.notify("No tasks found", vim.log.levels.WARN)
            return
          end

          local actions = require("telescope.actions")
          local action_state = require("telescope.actions.state")
          require("telescope.pickers").new({}, {
            prompt_title = "Tasks",
            finder = require("telescope.finders").new_table({
              results = task_list,
              entry_maker = function(entry)
                return {
                  value = entry.name,
                  display = entry.name,
                  commands = entry.commands,
                  doc = entry.doc,
                  ordinal = entry.name .. " " .. table.concat(entry.commands, " ") .. " " .. entry.doc,
                }
              end,
            }),
            sorter = require("telescope.sorters").get_generic_fuzzy_sorter(),
            attach_mappings = function(prompt_bufnr, map)
              actions.select_default:replace(function()
                local selection = action_state.get_selected_entry(prompt_bufnr)
                actions.close(prompt_bufnr)
                if selection then
                  local commands = selection.commands
                  local name = selection.value
                  vim.cmd("vsplit")
                  vim.cmd("enew")
                  local bufnr = vim.api.nvim_get_current_buf()
                  local lines = {
                    "# " .. name,
                    "",
                  }
                  -- Add commands section
                  if #commands > 0 then
                    vim.list_extend(lines, { "**Commands:**", "```sh" })
                    vim.list_extend(lines, commands)
                    vim.list_extend(lines, { "```", "" })
                  end
                  -- Add documentation section
                  if selection.doc ~= "" then
                    vim.list_extend(lines, { "**Documentation:**" })
                    vim.list_extend(lines, vim.split(selection.doc, "\n"))
                    vim.list_extend(lines, { "" })
                  end
                  vim.list_extend(lines, { "", "Press q to close, Enter to run" })
                  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
                  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
                  vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")
                  vim.keymap.set("n", "q", "<cmd>bd!<CR>", { buffer = bufnr })
                  vim.keymap.set("n", "<CR>", function()
                    vim.api.nvim_command("bd!")
                    vim.cmd("AsyncTask " .. name)
                  end, { buffer = bufnr })
                end
              end)
              return true
            end,
          }):find()
        end
      end)()
      vim.keymap.set('n', '<leader>vt', pick_task, { silent = true, desc = "[task] Run task *" })
      vim.keymap.set('n', '<leader>vT', function()
        local vimrc = vim.env.MYVIMRC or vim.fn.expand('<sfile>:p')
        local tasks_file = vim.fn.fnamemodify(vimrc, ':p:h') .. "/tasks.ini"
        vim.cmd("edit " .. tasks_file)
      end, { silent = true, desc = "[task] Edit tasks *" })
    end,

    config = function()
      local actions = require("telescope.actions")
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          layout_config = { scroll_speed = 2 },

          -- Prevent selection from wrapping around when reaching the top or bottom
          cycle_layout_list = false,
          scroll_strategy = "limit",

          -- FORCE THE BUFFER TO KILL TIMEOUT DELAYS IMMEDIATELY
          attach_mappings = function(prompt_bufnr, map)
            -- Force delete any conflicting global insert maps inside the Telescope prompt
            pcall(vim.api.nvim_buf_del_keymap, prompt_bufnr, "i", "<C-p>")
            pcall(vim.api.nvim_buf_del_keymap, prompt_bufnr, "i", "<C-n>")
            return true
          end,

          mappings = {
            i = {
              ["<C-n>"] = actions.move_selection_next,
              ["<C-p>"] = actions.move_selection_previous,
              ["<a-p>"] = actions.preview_scrolling_up,
              ["<a-n>"] = actions.preview_scrolling_down,
              [";;"] = function(prompt_bufnr) require("telescope").extensions.hop.hop(prompt_bufnr) end,
            },
            n = {
              ["<C-n>"] = actions.move_selection_next,
              ["<C-p>"] = actions.move_selection_previous,
              ["<a-p>"] = actions.preview_scrolling_up,
              ["<a-n>"] = actions.preview_scrolling_down,
              [";;"] = function(prompt_bufnr) require("telescope").extensions.hop.hop(prompt_bufnr) end,
            },
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,                    -- Set to false if you want exact matching globally
            override_generic_sorter = true,  -- Override the internal generic sorter
            override_file_sorter = true,     -- Override the internal file sorter
            case_mode = "smart_case",        -- Choose "smart_case", "ignore_case", or "respect_case"
          },
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


      -- Force telescope to load the compiled native extension (fzf only if built)
      local fzf_ok = pcall(require, "telescope._extensions.fzf")
      if fzf_ok then telescope.load_extension("fzf") end
      telescope.load_extension("hop")
    end,

  },

  -- Markdown
  {
    "preservim/vim-markdown",
    lazy = false,
    enabled = cond({ "editor", "markdown" }),
    dependencies = { 'godlygeek/tabular' }, -- Required by vim-markdown
    ft = { "markdown", "wiki" },
    dependencies = { 
      'godlygeek/tabular',
    },
    init = function()
      -- Global colors for headers (Traditional look but colorful)
      -- This defines the text color for # H1, ## H2, etc.
      vim.api.nvim_set_hl(0, 'RenderMarkdownH1', { fg = '#ff5555', bold = true }) -- Red
      vim.api.nvim_set_hl(0, 'RenderMarkdownH2', { fg = '#50fa7b', bold = true }) -- Green
      vim.api.nvim_set_hl(0, 'RenderMarkdownH3', { fg = '#f1fa8c', bold = true }) -- Yellow
      vim.api.nvim_set_hl(0, 'RenderMarkdownH4', { fg = '#bd93f9', bold = true }) -- Purple

      -- Disable the old plugin's "ugly" folding and conceal
      vim.g.vim_markdown_folding_disabled = 1
      vim.g.vim_markdown_conceal = 0
      vim.g.vim_markdown_toc_autofit = 1
      vim.g.vim_markdown_strikethrough = 1
      vim.g.vim_markdown_frontmatter = 1
      vim.g.vim_markdown_json_frontmatter = 1
      -- Lists & Indentation
      vim.g.vim_markdown_new_list_item_indent = 2

      -- Fenced Languages (C, Shell, Java, etc.)
      vim.g.vim_markdown_fenced_languages = {
        'c', 'sh', 'java', 'cs', 'cpp', 'vim',
        'dosini', 'rust'
      }
      -- Apply to the general markdown variable as well
      vim.g.markdown_fenced_languages = vim.g.vim_markdown_fenced_languages
    end,
    config = function()
    end
  },
  -- { "OXY2DEV/markview.nvim", lazy = false, enabled = cond({ "editor", "markdown" }), ft = "markdown" },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    enabled = false and cond({ "editor", "markdown" }),
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons' -- or 'mini.icons'
    },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      file_types = { "markdown", "vimwiki" },
      heading = { position = 'inline' },
      code = {
        style = 'normal',
        border = 'thick',
      },
      -- Better checkboxes
      checkbox = {
        enabled = true,
        unchecked = { icon = '   ' },
        checked = { icon = ' ' },
      },
    },
    ft = { "markdown", "vimwiki" }, -- Lazy load on these filetypes
    config = function(_, opts)
      require('render-markdown').setup(opts)
      -- Required for the icons/styling to "render" properly
      vim.opt.conceallevel = 2
    end,
  },
  {
    "epwalsh/obsidian.nvim",
    version = "*",
    lazy = false,
    enabled = false and cond({ "editor", "markdown" }),
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
  {
    "ethanholz/nvim-lastplace",
    lazy = false,
    enabled = cond({ "editor", "markdown" }),
    config = function()
      require("nvim-lastplace").setup({
        lastplace_ignore_buftype = { "quickfix", "nofile", "help" },
        lastplace_ignore_filetype = { "gitcommit", "gitrebase", "svn", "hgcommit" },
        lastplace_open_folds = true,
      })
    end,
  },
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
    build = "git switch master",
    keys = {
      { "<leader>mm", mode = "n", desc = "[misc] Colorize current word *" },
      { "<leader>mm", mode = "v", desc = "[misc] Colorize visual selection *" },
      { "<leader>mx", mode = "n", desc = "[misc] Clear all colorized words *" },
    },
    init = function() vim.g.mw_no_mappings = 1 end,
    config = function() require("vim-mark").setup() end,
  },
  { "huawenyu/vim-signature", enabled = cond({ "editor" }), build = "git switch master", },
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

  {
    "chrisbra/NrrwRgn",
    enabled = cond({ "editor" }),
    -- Load only when running these specific narrowing commands
    cmd = { "NR", "NrwRgn", "NarrowRegion" },
    keys = {
      -- Map <Leader>nr in visual mode to narrow the selected region
      { "<Leader>cc", ":NR<CR>", mode = "v", desc = "[misc] Narrow selected region *" },
    },
    config = function()
      -- Enable automatic synchronization when leaving the narrowed buffer
      vim.g.nrrw_rgn_write_on_synchronize = 1

      -- Prevent the main original file from being accidentally closed
      vim.g.nrrw_toploaddata = 1

      -- Instruct the plugin to open via standard tabedit commands
      vim.g.nrrw_rgn_wdth = "tabedit"
    end,
  },

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
  { "justinmk/vim-syntax-extra", enabled = cond({ "editor" }), ft = "vim" },
  -- { "huawenyu/vim-log-syntax", enabled = cond({ "editor", "log" }), build = "git switch master", ft = "log" },
  { "fei6409/log-highlight.nvim", enabled = cond({ "editor", "log" }), ft = "log" },
  { "huawenyu/vim-autotest-syntax", enabled = cond({ "editor", "log" }), build = "git switch master", ft = "case" },
  { "nickhutchinson/vim-cmake-syntax", enabled = cond({ "editor" }), ft = "cmake" },
  { "xuhdev/syntax-dosini.vim", enabled = cond({ "editor" }), ft = "dosini" },
  { "tmux-plugins/vim-tmux", enabled = cond({ "editor" }), ft = "tmux" },

  {
    "chentoast/marks.nvim",
    enabled = cond({ "editor" }),
    lazy = false,
    config = function()
      require'marks'.setup {
        -- whether to map keybinds or not. default true
        default_mappings = true,
        -- which builtin marks to show. default {}
        builtin_marks = { ".", "<", ">", "^" },
        -- whether movements cycle back to the beginning/end of buffer. default true
        cyclic = true,
        -- whether the shada file is updated after modifying uppercase marks. default false
        force_write_shada = false,
        -- how often (in ms) to redraw signs/recompute mark positions. 
        -- higher values will have better performance but may cause visual lag, 
        -- while lower values may cause performance penalties. default 150.
        refresh_interval = 250,
        -- sign priorities for each type of mark - builtin marks, uppercase marks, lowercase
        -- marks, and bookmarks.
        -- can be either a table with all/none of the keys, or a single number, in which case
        -- the priority applies to all marks.
        -- default 10.
        sign_priority = { lower=10, upper=15, builtin=8, bookmark=20 },
        -- disables mark tracking for specific filetypes. default {}
        excluded_filetypes = {},
        -- disables mark tracking for specific buftypes. default {}
        excluded_buftypes = {},
        -- marks.nvim allows you to configure up to 10 bookmark groups, each with its own
        -- sign/virttext. Bookmarks can be used to group together positions and quickly move
        -- across multiple buffers. default sign is '!@#$%^&*()' (from 0 to 9), and
        -- default virt_text is "".
        bookmark_0 = {
          sign = "⚑",
          virt_text = "hello world",
          -- explicitly prompt for a virtual line annotation when setting a bookmark from this group.
          -- defaults to false.
          annotate = false,
        },
        mappings = {}
      }
    end
  },

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
    end,
  },

  -- ============================================================
  -- Search / Jump / Motion
  -- ============================================================
  { "huawenyu/vim-grepper", enabled = cond({ "editor" }), build = "git switch master", lazy = false },
  {
    "dhananjaylatkar/cscope_maps.nvim",
    enabled = cond({ "coder" }),
    lazy = true,
    cmd = { "Cscope", "CscopeDbAdd" },
    keys = {
      { "<leader>fs", desc = "[lsp] Find references *" },
      { "<leader>fd", desc = "[lsp] Find definition *" },
      { "<leader>fc", desc = "[lsp] Find callers *" },
      { "<leader>fC", desc = "[lsp] Find callees *" },
      { "<leader>fw", desc = "[lsp] Find assignments *" },
      { "<leader>fe", desc = "[find] Egrep pattern *" },
      { "<leader>ff", desc = "[find] Find file *" },
      { "<leader>fb", desc = "Build cscope db" },
      { "<leader>fr", desc = "Reload cscope db" },
      { "<leader>fz", desc = "Debug cscope" },
      { ";<leader>ff", desc = "[find] Find file (rg) *" },
      { "<leader>fs", mode = "v", desc = "[lsp] Find references (visual) *" },
    },
    dependencies = { "nvim-telescope/telescope.nvim" },
  },
  {
    "huawenyu/c-utils.vim",
    enabled = cond({ "coder" }),
    build = "git switch master",
    lazy = false,
    config = function()
      if not is_wsl() then
        require("c-utils").setup()
      end
    end,
  },
  {
    "chengzeyi/fzf-preview.vim",
    enabled = cond({ "editor" }), lazy = false,
    dependencies = { "junegunn/fzf.vim" },
  },
  {
    "huawenyu/fzf-cscope.vim",
    enabled = false and cond({ "editor" }),
    build = "git switch master",
    dependencies = { "chengzeyi/fzf-preview.vim", "huawenyu/vim-basic" },
    keys = {
      -- File commands
      { "<leader>ff", "<cmd>CSFileFilter<cr>", desc = "[find] Find files *" },
      { ";ff", "<cmd>CSFileFilter!<cr>", desc = "[find] Find files (all) *" },

      -- Symbol/References
      { "<leader>fs", "<cmd>call cscope#preview('0', 'n', 0, 0)<cr>", desc = "[lsp] Find references *" },
      { "<leader>fS", "<cmd>call cscope#preview('0', 'n', 0, 1)<cr>", desc = "[lsp] Find references (advanced) *" },

      -- Function calls
      { "<leader>fc", "<cmd>call cscope#preview('3', 'n', 1, 0)<cr>", desc = "[lsp] Find callers *" },
      { "<leader>fC", "<cmd>call cscope#preview('2', 'n', 1, 0)<cr>", desc = "Find callees" },

      -- Assignment
      { "<leader>fw", "<cmd>call cscope#preview('9', 'n', 0, 0)<cr>", desc = "[lsp] Find assignments *" },
      { "<leader>fW", "<cmd>call cscope#preview('9', 'n', 0, 1)<cr>", desc = "[lsp] Find assignments (advanced) *" },

      -- Text search
      { "<leader>fe", "<cmd>call utilgrep#Grep(0, 0, '', 1)<cr>", desc = "Search project" },
      { "<leader>f1", "<cmd>call utilgrep#Grep(0, 0, 'daemon/wad', 1)<cr>", desc = "[find] Search in wad *" },
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
    build = "git switch main",
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
  { "huawenyu/vim-windowswap", enabled = cond({ "editor" }), build = "git switch master", },
  {
    "preservim/tagbar",
    enabled = cond({ "editor" }),
    cmd = { "TagbarToggle", "Tagbar", "TagbarOpen" },
    keys = { { "<leader>vt", "<cmd>TagbarToggle<cr>", desc = "[view] Tag (tagbar) *" } },
    init = function() require("vimconfig.tagbar").setup() end,
  },

  -- { "huawenyu/quickfix-reflector.vim", enabled = cond({ "editor" }), build = "git switch master", }, -- Disable it for it confuse neovim and create multiple-quickfix window
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
      { "<leader>vT", "<cmd>TodoTelescope<cr>", desc = "[picker] Todo *" },
    },
    config = function()
      require("todo-comments").setup()
      vim.keymap.set('n', '<leader>vf', function() require("telescope").extensions.todo_comments.todo_comments() end, { silent = true, desc = "Telescope Todo" })
    end,
  },
  { "windwp/nvim-autopairs", enabled = cond({ "editor" }), event = "InsertEnter" },
  { "tpope/vim-surround", enabled = cond({ "editor" }) },
  { "tpope/vim-rsi", enabled = cond({ "editor" }) },
  { "ciaranm/securemodelines", enabled = cond({ "editor" }) },
  {
    "huawenyu/vim-unimpaired",
    enabled = cond({ "editor" }),
    build = "git switch master",
    lazy = false,
    init = function() vim.g.unimpaired_listchar = 0 end,
    config = function() require("vim-unimpaired").setup() end,
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
    end
  },
  { "mg979/vim-visual-multi", enabled = cond({ "editor" }) },
  {
    "huawenyu/hop.nvim",
    enabled = cond({ "editor" }),
    build = "git switch master",
    keys = {
      { ";s", "<cmd>HopChar1CurrentLine<cr>", desc = "Hop to char (current line)" },
      { ";;", "<cmd>HopChar2<cr>", desc = "Hop to 2-char sequence" },
    },
    config = function() require("hop").setup({ keys = "asdfghjklqwertyuiopzxcvbnm" }) end,
  },
  { "tpope/vim-abolish", enabled = cond({ "editor" }), lazy = false,  },
  { "tpope/vim-repeat", enabled = cond({ "editor" }), lazy = false, },
  { "rhysd/clever-f.vim", enabled = cond({ "editor" }), lazy = false,  },
  {
    "huawenyu/vim-motion",
    enabled = cond({ "editor" }),
    build = "git switch master",
    dependencies = { "skywind3000/vim-preview" },
    keys = {
      { "<leader>;",  function() vim.cmd('call VimMotionTag()') end, mode = "n", silent = true, desc = "Jump Tag" },
      { "<leader><leader>", function() vim.cmd('call VimMotionPreview()') end, mode = { "n", "v" }, desc = "Preview Tag" },
    },
  },
  {
    "junegunn/vim-easy-align",
    enabled = cond({ "editor" }),
    cmd = "EasyAlign",
    keys = {
      { "<leader>ga", "<Plug>(EasyAlign)", mode = { "n", "x" }, desc = "Easy Align" },
    },
    init = function()
      require("vimconfig.easyalign").setup()
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

  { 
    "nvim-treesitter/nvim-treesitter",
    enabled = cond({ "editor" }),
    build = ":TSUpdate",
    lazy = false,
    config = function()
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    enabled = cond({ "coder" }),
    event = "BufReadPost", -- Loads when you start reading a file
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
      max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
    },
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    enabled = cond({ "basic", "log", "editor" }),
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = "VeryLazy",
  },
  {
    "neovim/nvim-lspconfig",
    enabled = cond({ "coder" }),
    event = "VeryLazy",
    dependencies = {
      "ojroques/nvim-lspfuzzy",
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      vim.lsp.config('clangd', {})
      vim.lsp.config('rust_analyzer', {})
      vim.lsp.config('lua_ls', {})
      vim.lsp.enable('clangd')
      vim.lsp.enable('rust_analyzer')
      vim.lsp.enable('lua_ls')
      require('lspfuzzy').setup({})

      local opts = { noremap = true, silent = true }
      -- Use Telescope for searching Definitions, References, and Diagnostics
      vim.api.nvim_set_keymap('n', ';fd', '<cmd>Telescope lsp_definitions<CR>', vim.tbl_extend("force", opts, { desc = "Telescope: Goto Definition" }))
      vim.api.nvim_set_keymap('n', ';fs', '<cmd>Telescope lsp_references<CR>', vim.tbl_extend("force", opts, { desc = "Telescope: References" }))
      vim.api.nvim_set_keymap('n', ';fN', '<cmd>Telescope diagnostics<CR>', vim.tbl_extend("force", opts, { desc = "Telescope: Diagnostics" }))

      -- Rename and Goto Next/Prev stay as standard LSP (no Telescope picker exists for these)
      vim.api.nvim_set_keymap('n', ';fr', '<cmd>lua vim.lsp.buf.rename()<CR>', vim.tbl_extend("force", opts, { desc = "[lsp] Refactor rename *" }))

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
      { "W", "<Plug>(expand_region_expand)", mode = { "n", "v" }, desc = "[vsel] Expand region *" },
      { "B", "<Plug>(expand_region_shrink)", mode = { "n", "v" }, desc = "[vsel] Shrink region *" },
    },
  },
  {
    "kana/vim-textobj-user",
    enabled = cond({ "editor" }),
    dependencies = {
      "michaeljsmith/vim-indent-object", "glts/vim-textobj-indblock", "kana/vim-textobj-entire",
      "mattn/vim-textobj-url", "kana/vim-textobj-diff", "Julian/vim-textobj-brace",
      "whatyouhide/vim-textobj-xmlattr", "glts/vim-textobj-comment",
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
    config = function() require("vimconfig.floaterm").setup() end,
  },
  {
    "huawenyu/vim-floaterm-repl",
    enabled = cond({ "editor" }), lazy = false,
    build = "git switch master",
    cmd = "FloatermRepl",
    ft = "markdown",
    keys = {
      { ";ee", "<cmd>FloatermRepl<cr>", ft = "markdown", desc = "(repl) Run me *" },
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
      vim.keymap.set('n', '<c-\\>', '<cmd>ToggleTerm<cr>', { silent = true, desc = "[view] Toggle Terminal *" })
    end,
  },
  { "huawenyu/asyncrun.vim", enabled = cond({ "admin" }), build = "git switch master", },
  {
    'skywind3000/asynctasks.vim',
    enabled = cond({ "admin" }),
    lazy = false,
    dependencies = { "huawenyu/asyncrun.vim" },
    init = function()
      local vimrc = vim.env.MYVIMRC or vim.fn.expand('<sfile>:p')
      local config_dir = vim.fn.fnamemodify(vimrc, ':p:h')
      local dst = config_dir .. "/tasks.ini"
      local src = vim.fn.expand("~/.vim_tasks.ini")
      if vim.fn.filereadable(src) == 1 and vim.fn.getftype(dst) == '' then
        vim.fn.system('ln -sf ' .. src .. ' ' .. dst)
      end
    end,
    config = function() require("asyncrun.config").setup() end,
  },
  {
    "folke/edgy.nvim",
    enabled = cond({ "coder" }),
    event = "VeryLazy",

    config = function()
      vim.o.equalalways = false

      local function neo(src)
        return function(buf)
          return vim.b[buf].neo_tree_source == src
        end
      end

      require("edgy").setup({
        left = {
          { title = "Explore-legacy", ft = "nerdtree", open = "NERDTree", close = "NERDTreeClose", size = { height = 0.4 } },
          { title = "Functions", ft = "tagbar", open = "TagbarOpen", close = "TagbarClose", size = { height = 0.4 } },
          { title = "Explore-neo", ft = "neo-tree", filter = neo("filesystem"), size = { height = 0.4 } },
          { title = "Buffers", ft = "neo-tree", filter = neo("buffers"), open = "Neotree position=top buffers", collapsed = false, size = { height = 0.25 } },
          { title = "Git-status", ft = "neo-tree", filter = neo("git_status"), open = "Neotree position=top git_status", collapsed = false, size = { height = 0.25 } },
          { title = function() return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t") end, ft = "Outline", open = "SymbolsOutlineOpen" },
          { title = "Outline", ft = "voomtree", open = "VoomToggle", size = { height = 0.5 } },
          "neo-tree",
        },

        bottom = {
          { ft = "toggleterm", size = { height = 0.3 }, filter = function(buf) return vim.api.nvim_buf_get_name(buf):match("term://") end },
          { ft = "lazyterm", title = "LazyTerm", size = { height = 0.4 }, filter = function(buf) return not vim.b[buf].lazyterm_cmd end },
          "Trouble",
          { ft = "qf", buftype = "quickfix", title = "QuickFix", open = "copen", pinned = true, size = { height = 0.2 }, wo = { winfixheight = true } },
          { ft = "help", size = { height = 20 }, filter = function(buf) return vim.bo[buf].buftype == "help" end },
          { ft = "spectre_panel", size = { height = 0.4 } },
        },

        open_files_do_not_replace_types = { "terminal", "Trouble", "qf", "edgy" },

        animate = {
          enabled = false,
          fps = 100,
          cps = 120,
          on_begin = function() vim.g.minianimate_disable = true end,
          on_end = function() vim.g.minianimate_disable = false end,
        },

        exit_when_last = false,
        close_when_all_hidden = true,

        wo = {
          winbar = true,
          winfixwidth = true,
          winfixheight = true,
          winhighlight = "WinBar:EdgyWinBar,Normal:EdgyNormal",
          spell = false,
          signcolumn = "no",
        },

        icons = { closed = " ", open = " " },
        fix_win_height = vim.fn.has("nvim-0.10.0") == 0,
      })
    end,
  },
  { "sk1418/blockit", enabled = cond({ "editor" }), cmd = "Block" },
  {
    "rmagatti/auto-session",
    enabled = cond({ "coder" }),
    lazy = false,
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
    config = function() require("vimconfig.session").setup() end,
  },
  {
    "preservim/nerdtree",
    cmd = { "NERDTreeToggle", "NERDTreeFind", "NERDTree" },
    keys = {
      { "<leader>ve", "<cmd>NERDTreeToggle<CR>", desc = "[view] Explore (nerdtree) *" },
      { "<leader>vE", "<cmd>NERDTreeFocus<CR>", desc = "[view] Explore - Focus (nerdtree) *" },
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
      vim.keymap.set('n', ';ve', '<c-U>Neotree toggle<cr>', { silent = true, desc = "[view] Explore (neotree) *" })
      vim.keymap.set('n', ';vE', '<c-U>Neotree reveal<cr>', { silent = true, desc = "Explore Focus (Reveal)" })
    end
  },

  {
    "huawenyu/VOoM",
    enabled = cond({ "editor", "log" }),
    build = "git switch master",
    cmd = { "VoomToggle", "Voom" },
    keys = {
      { "<leader>vO", "<cmd>VoomToggle<cr>", mode = "n", silent = true, desc = "[view] Outline (Voom) *" },
      { "<leader>v0", "<cmd>VoomToggle fmr<cr>", mode = "n", silent = true, desc = "[view] Outline (Voom fmr)" },
    },
  },

  {
    "stevearc/aerial.nvim",
    enabled = cond({ "editor", "log" }),
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons"
    },
    -- Only load when calling these commands
    cmd = { "AerialToggle", "AerialOpen", "AerialNavToggle" },
    -- Or load when pressing these keys
    keys = {
      { "<leader>vo", "<cmd>AerialToggle!<cr>", desc = "[view] Outline (Aerial) *" },
    },
    opts = {
      -- Configuration options
      backends = { "lsp", "treesitter", "markdown", "man" },
      layout = {
        -- This forces the sidebar to the left
        default_direction = "left",
        -- Optional: adjust width for the left side
        max_width = { 40, 0.2 },
        min_width = 20,
      },
      highlight_on_hover = true,
      show_guides = true,
      filter_kind = false, -- Show all symbols
      -- Automatically attach to buffers
      attach_mode = "global",

      post_parse_symbol = function(bufnr, item, ctx)
        -- Only apply this logic in markdown files
        if vim.bo[bufnr].filetype ~= "markdown" then
          return true
        end

        -- Get the line text to check for leading whitespace
        local line = vim.api.nvim_buf_get_lines(bufnr, item.lnum - 1, item.lnum, false)[1] or ""

        -- Matches any space or tab (%s+) followed by #
        if line:match("^%s+#") then
          return false
        end

        return true
      end,
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
      { "<leader>gD", "<cmd>DiffReview git show<cr>", desc = "[git] Git Diff review tabs *" },
      { "<leader>gb", "<cmd>Git blame<cr>", desc = "[git] Git Blame *" },
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
      { "<leader>gl", "<cmd>GV<cr>", desc = "[git] Git Log side by side *" },
    },
  },
  {
    "huawenyu/diffview.nvim",
    enabled = cond({ "editor" }),
    build = "git switch main",
    lazy = false,
    cmd = { "DiffviewOpen", "DiffviewLog" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>vg", "<cmd>DiffviewToggle<cr>", desc = "[view,git] Diffview Toggle *", },
      { "<leader>vG", "<cmd>DiffviewFileHistory<cr>", desc = "[view,git] Diffview Log *", },
    },
    config = function()
      local git_cmd = require("vimconfig.git").detect_git_cmd()
      require("diffview").setup({ git_cmd = { git_cmd } })
      vim.api.nvim_create_user_command("DiffGit", function(opts)
        require("diffview").setup({ git_cmd = { "git" } }); vim.cmd("DiffviewOpen " .. opts.args)
      end, { nargs = "*" })
      vim.api.nvim_create_user_command("DiffYadm", function(opts)
        require("diffview").setup({ git_cmd = { "yadm" } }); vim.cmd("DiffviewOpen " .. opts.args)
      end, { nargs = "*" })
      vim.api.nvim_create_user_command("DiffYadme", function(opts)
        require("diffview").setup({ git_cmd = { "yadme" } }); vim.cmd("DiffviewOpen " .. opts.args)
      end, { nargs = "*" })
    end,
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

      vim.keymap.set('n', ';gv', '<c-U>GitGutterToggle<cr>', { silent = true, desc = "[view,git] Git Gutter Toggle *" })
      vim.keymap.set('n', ';gr', '<c-U>GitGutter<cr>', { silent = true, desc = "Git Gutter" })
      vim.keymap.set('n', ';gn', '<Plug>(GitGutterNextHunk)', { silent = true, desc = "Next Hunk" })
      vim.keymap.set('n', ';gp', '<Plug>(GitGutterPrevHunk)', { silent = true, desc = "Previous Hunk" })
      vim.keymap.set('n', ';ga', '<Plug>(GitGutterStageHunk)', { silent = true, desc = "Stage Hunk" })
      vim.keymap.set('n', ';gu', '<Plug>(GitGutterUndoHunk)', { silent = true, desc = "Undo Hunk" })
    end,
  },
  {
    "huawenyu/gitsigns.nvim",
    enabled = cond({ "coder" }),
    build = "git switch main",
    event = "BufReadPre",
    config = function()
      local vcs_dirs = {}
      local default_untracked = false  -- user's default; saved to restore on git switch

      require('gitsigns').setup({
          git_command = require("vimconfig.git").detect_git_cmd(),
          signs = { add = { text = '+' }, change = { text = '>' }, delete = { text = '-' }, topdelete = { text = '^' }, changedelete = { text = '<' } },
        signcolumn = true, numhl = false, linehl = true, word_diff = false,
        watch_gitdir = { follow_files = true }, auto_attach = true, attach_to_untracked = false,
        current_line_blame = false, sign_priority = 6, update_debounce = 100, max_file_length = 40000,
        _on_attach_pre = function(bufnr, callback)
          local target = require("vimconfig.git").detect_git_cmd()
          if target ~= "git" and target ~= "" then
            if not vcs_dirs[target] then
              local lines = vim.fn.systemlist({ target, "introspect", "repo" })
              local git_dir = lines[1] and lines[1] ~= "" and lines[1] or nil
              if git_dir then
                vcs_dirs[target] = { gitdir = git_dir, toplevel = vim.env.HOME or vim.fn.expand("~") }
              end
            end
            local info = vcs_dirs[target]
            if info then
              local cfg = require("gitsigns.config").config
              cfg.git_command = target
              cfg.attach_to_untracked = false
              callback(info)
              return
            end
          else
            -- Restore default when back on git
            require("gitsigns.config").config.attach_to_untracked = default_untracked
          end
          callback(nil)
        end,

        on_attach = function(bufnr)
          local gs = require('gitsigns')

          vim.keymap.set('n', ';gn', gs.next_hunk, { buffer = bufnr, desc = "Next Hunk" })
          vim.keymap.set('n', ';gp', gs.prev_hunk, { buffer = bufnr, desc = "Previous Hunk" })
          vim.keymap.set('n', ';ga', gs.stage_hunk, { buffer = bufnr, desc = "Stage Hunk" })
          vim.keymap.set('n', ';gu', gs.undo_stage_hunk, { buffer = bufnr, desc = "Undo Hunk" })
          vim.keymap.set('n', ';gv', gs.toggle_signs, { buffer = bufnr, desc = "Toggle GitGutter" })
          vim.keymap.set('n', ';gr', function() gs.preview_hunk() end, { buffer = bufnr, desc = "Preview Hunk" })
          vim.keymap.set({ 'o', 'x' }, 'ih', ':Gitsigns select_hunk<CR>', { buffer = bufnr })
        end,
      })

      local function with_vcs(vcs, cmd_args)
        local cfg = require("gitsigns.config").config
        cfg.git_command = vcs
        cfg.attach_to_untracked = (vcs == "git") and default_untracked or false
        -- Resolve gitdir for non-git VCS tools
        if vcs ~= "git" and not vcs_dirs[vcs] then
          local lines = vim.fn.systemlist({ vcs, "introspect", "repo" })
          local git_dir = lines[1] and lines[1] ~= "" and lines[1] or nil
          if git_dir then
            vcs_dirs[vcs] = { gitdir = git_dir, toplevel = vim.env.HOME or vim.fn.expand("~") }
          end
        end
        -- Detach and re-attach with new git_command
        local bufnr = vim.api.nvim_get_current_buf()
        require("gitsigns.attach").detach(bufnr)
        require("gitsigns.actions").attach({ bufnr = bufnr, force = true })
        -- setqflist needs the attach to complete; defer to next event loop tick
        vim.schedule(function()
          vim.cmd("Gitsigns setqflist " .. cmd_args)
        end)
      end
      vim.api.nvim_create_user_command("GitsignGit", function(opts)
        with_vcs("git", opts.args)
      end, { nargs = "*" })
      vim.api.nvim_create_user_command("GitsignYadm", function(opts)
        with_vcs("yadm", opts.args)
      end, { nargs = "*" })
      vim.api.nvim_create_user_command("GitsignsYadme", function(opts)
        with_vcs("yadme", opts.args)
      end, { nargs = "*" })
    end,
  },

  -- ============================================================
  -- Other Utilities
  -- ============================================================
  { "huawenyu/tldr.nvim", enabled = not is_wsl() and vim.fn.executable("tldr") == 1 and cond({ "editor" }), build = "git switch master", },
  { "s1n7ax/nvim-window-picker", enabled = cond({ "editor", "tool" }) },

  -- ============================================================
  -- Libraries
  -- ============================================================
  { "google/vim-maktaba", enabled = cond({ "coder", "library" }) },
  { "tomtom/tlib_vim", enabled = cond({ "coder", "library" }) },

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

-- Override vimConfig's <Esc> mapping to avoid command-line enter/leave events
-- which can cause edgy to re-focus pinned windows (e.g. quickfix)
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { silent = true, desc = "Clear search highlight" })

-- Select High-Contrast Reverse Mode
vim.api.nvim_set_hl(0, 'Visual', { reverse = true })
vim.api.nvim_create_autocmd('ColorScheme', {
  callback = function()
    vim.api.nvim_set_hl(0, 'Visual', { reverse = true })
  end,
})


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

  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "qf" },
    callback = function(ev)
      -- 1. Mappings ONLY for Quickfix
      if ev.match == "qf" then
        vim.keymap.set("n", "<C-o>", "<cmd>colder<CR>", { buffer = true })
        vim.keymap.set("n", "<C-i>", "<cmd>cnewer<CR>", { buffer = true })

        -- Force n/N to standard search for QF only
        vim.keymap.set("n", "n", "n", { buffer = true })
        vim.keymap.set("n", "N", "N", { buffer = true })

        -- Split the previous (main) window, not the qf window
        vim.keymap.set("n", "<C-w>v", "<C-w>p<C-w>v", { buffer = true })
        vim.keymap.set("n", "<C-w>s", "<C-w>p<C-w>s", { buffer = true })
        vim.keymap.set("n", "<C-w><C-v>", "<C-w>p<C-w>v", { buffer = true })
        vim.keymap.set("n", "<C-w><C-s>", "<C-w>p<C-w>s", { buffer = true })
      end

      -- 3. Mappings for ALL types in the pattern list
      vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = true })
    end,
  })


  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      vim.defer_fn(function() vim.cmd("redrawstatus") end, 500)
    end,
  })

  -- Vim-messages to quickfix
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


  -- Last '/' search to quickfix
  vim.keymap.set('n', ';vq', function()
    -- Check if a search pattern actually exists to prevent errors
    local search_pattern = vim.fn.getreg('/')
    if search_pattern == "" then
      vim.notify("Search register is empty!", vim.log.levels.WARN)
      return
    end

    -- Execute project-wide or current-file search. (Using current file here for safety)
    vim.cmd("vimgrep //g %")
    vim.cmd("copen")
  end, { desc = "Push active buffer search matches to Quickfix (help)" })

end

