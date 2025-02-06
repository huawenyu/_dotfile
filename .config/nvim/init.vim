" vim: set expandtab: set tabstop=4: set shiftwidth=4: set softtabstop=4:
"
" QuickStart: vim <leader>    <Space>
" - Install:
"   - update nvim
"          curl -LO https://github.com/neovim/neovim/releases/download/v0.10.4/nvim-linux-x86_64.appimage
"          chmod u+x nvim-linux-x86_64.appimage
"          sudo mv nvim-linux-x86_64.appimage /usr/bin/nvim
"   - Linux
"          curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/huawenyu/_dotfile/ubuntu/.config/nvim/autoload/plug.vim
"          curl -fLo ~/.config/nvim/init.vim          --create-dirs https://raw.githubusercontent.com/huawenyu/_dotfile/ubuntu/.config/nvim/init.vim
"   - Windows (by WSL)
"          curl -fLo /mnt/c/Users/<your-user-name>/AppData/Local/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/huawenyu/_dotfile/ubuntu/.config/nvim/autoload/plug.vim
"          curl -fLo /mnt/c/Users/<your-user-name>/AppData/Local/nvim/init.vim          --create-dirs https://raw.githubusercontent.com/huawenyu/_dotfile/ubuntu/.config/nvim/init.vim
" - Help by 'K':  vim_cheat, vim_maps, vim_config,
"        Buitin:  :vimtutor" for vim, ":Tutor" for neovim
" - Startup without plug:   vim --clean
"       Start other mode:   mode=basic vi <myfile>
"                           mode=basic,test vi <myfile>
"                           mode=all vi <myfile>
" - Update env/plugin:      vim --headless "+PlugUpdate" +qa
"
" =============================================================

let g:vim_confi_option = {
      \ 'mode': ['basic', 'theme', 'local', 'editor', 'admin', 'coder', 'log', 'c', 'markdown', 'git', 'script', 'tool'],
      \ 'remap_leader': 1,
      \ 'theme': 1,
      \ 'conf': 1,
      \ 'verbose': 0,
      \ 'debug': 0,
      \
      \ 'upper_keyfixes': 1,
      \ 'enable_map_basic': 1,
      \ 'enable_map_useful': 1,
      \
      \ 'auto_install_vimplug': 0,
      \ 'auto_install_plugs': 1,
      \ 'auto_install_tools': 0,
      \
      \ 'auto_chdir': 0,
      \ 'auto_save': 1,
      \ 'auto_restore_cursor': 1,
      \
      \ 'keywordprg_filetype': 1,
      \
      \ 'modeline': 0,
      \ 'view_folding': 0,
      \ 'show_number': 0,
      \ 'wrapline': 0,
      \ 'indentline': 0,
      \
      \ 'help_keys': 1,
      \ 'alt_shortcut': 1,
      \
      \ 'wiki_dirs': ['~/dotwiki', '~/wiki', '~/dotfiles', ],
      \ 'tmp_file': '/tmp/vim.tmp',
      \}
" =============================================================

" Plugins {{{1
if g:vim_confi_option.remap_leader
    " Bother when termopen and input space cause a little pause-stop-wait
    let mapleader = "\<Space>"
    let maplocalleader="\<Space>"
    "
    "Bother when in select-mode and use the leader not works, so also provide another leader
    "    Space can be a bit tricky. Why not just map space to <leader>
    "        nmap <space> <leader>
    "    let mapleader = ","
    "nnoremap <Space> <Nop>

    " diable Ex mode
    map Q <Nop>
endif


if !empty($mode)
    let envMode = $mode
    let usrModes = split(envMode, ',')
    let g:vim_confi_option.mode = [$mode]
    "echomsg "UserMode=". $mode
endif

if !empty($debug)
    let g:vim_confi_option.debug = 1
endif

" Environment {{{1
    " Platform identification {
        silent function! OSX()
            return has('macunix')
        endfunction
        silent function! CYGWIN()
            return has('win32unix')
        endfunction
        silent function! LINUX()
            return has('unix') && !has('macunix') && !has('win32unix')
        endfunction
        silent function! WINDOWS()
            return  (has('win16') || has('win32') || has('win64'))
        endfunction
        silent function! UNIXLIKE()
            return !WINDOWS()
        endfunction
        silent function! FREEBSD()
          let s:uname = system("uname -s")
          return (match(s:uname, 'FreeBSD') >= 0)
        endfunction

        if LINUX()
              let s:uname = system("uname -a")
        else
              let s:uname = ""
        endif

        silent function! UBUNTU()
            return (match(s:uname, 'Ubuntu') >= 0)
        endfunction
        "Linux localhost.localdomain 3.10.0-957.el7.x86_64 #1 SMP Thu
        "Linux .*.fc29.x86_64 #
        "Linux .el7.x86_64 #
        silent function! CENTOS()
            " echo match("Linux localhost.localdomain 3.10.0-957.el7.x86_64 #1 SMP Thu", 'Linux .*\.el\d\+x86_64 #')
            return (match(s:uname, 'Linux .*\.el\d\+\.') >= 0)
        endfunction
        silent function! FEDORA()
            " echo match("Linux localhost.localdomain 3.10.0-957.el7.x86_64 #1 SMP Thu", 'Linux .*\.el\d\+x86_64 #')
            return (match(s:uname, 'Linux .*\.fc\d\+\.') >= 0)
        endfunction
    " }

    " Arrow Key Fix {
        " https://github.com/spf13/spf13-vim/issues/780
        if &term[:4] == "xterm" || &term[:5] == 'screen' || &term[:3] == 'rxvt'
            inoremap <silent> <C-[>OC <RIGHT>
        endif
    " }

    " Setup python
    if LINUX()
        let s:uname = system("uname")

        let g:python_host_prog = '/usr/bin/python'
        let g:python3_host_prog = '/usr/bin/python3'

        if s:uname == "Darwin\n"
            let g:python_host_prog='/usr/bin/python'
            let g:python3_host_prog='/usr/bin/python3'
        endif

        " [Using-pyenv](https://github.com/tweekmonster/nvim-python-doctor/wiki/Advanced:-Using-pyenv)
        "   pyenv install 3.6.7
        "   pyenv virtualenv 3.6.7 neovim3
        "   pyenv activate neovim3
        "   pip install neovim
        if !empty(glob($HOME.'/.pyenv/versions/neovim2'))
            let g:python_host_prog = $HOME.'/.pyenv/versions/neovim2/bin/python'
            let g:python3_host_prog = $HOME.'/.pyenv/versions/neovim3/bin/python'
        endif

        " https://github.com/neovim/neovim/issues/2094
        " Test this cause start slow 1~2secs, reproduce by:
        "       $ vi --startuptime /tmp/log.1
        "if !has('python3')
        "    echomsg "AutoInstall: pynvim"
        "    call system("pip3 install --user pynvim")
        "else
        "    call system("pip3 install --user --upgrade pynvim")
        "endif
    endif


    " Plug related:
    function! Cond(cond, ...)
        let opts = get(a:000, 0, {})
        return a:cond ? opts : extend(opts, { 'on': [], 'for': [] })
    endfunction

    function! HasIntersect(list1, list2) abort
        let result = copy(a:list1)
        call filter(result, 'index(a:list2, v:val) >= 0')
        return !empty(result)
    endfunction

    function! Mode(mode) abort
        if index(g:vim_confi_option.mode, 'all') >= 0
            return 1
        endif
        return HasIntersect(a:mode, g:vim_confi_option.mode)
    endfunction

    function! CheckPythonModule(name)
        if !executable('python') | return -1 | endif
        let importStr = system("python -c 'import ". a:name. "'")
        if stridx(importStr, 'No module named') >= 0 | return 0 | endif
        return 1
    endfunction

    " @Note only work with 'vim-plug'
    " @param type  0, Have the plug
    "              1, Select the plug
    "              2, Runtime Loaded the plug
    "        a:0 > 0, negative return
    function! CheckPlug(name, type, ...)
        if (a:0 == 0)
            let has = 1
            let hasno = 0
        else
            let has = 0
            let hasno = 1
        endif

        if (exists("g:plugs") && has_key(g:plugs, a:name) && isdirectory(g:plugs[a:name].dir))
            if a:type == 0
                return has
            elseif a:type == 1
                if has_key(g:plugs[a:name], 'on') && empty(g:plugs[a:name]['on'])
                    return hasno
                else
                    return has
                endif
            elseif a:type == 2
                return stridx(&rtp, g:plugs[a:name].dir) >= 0
            endif
        endif
        return hasno
    endfunction


    " Have and select the plug
    function! HasPlug(name)
        return CheckPlug(a:name, 1)
    endfunction

    " Check a plugin by order
    function! HasNoPlug(name)
        return CheckPlug(a:name, 1, 0)
    endfunction

    " Alias HasNoPlug, only load the plugin in advance.
    function! IfNoPlug(name)
        return CheckPlug(a:name, 1, 0)
    endfunction


    function! HasEnv(name)
        return !empty(a:name)
    endfunction

    function! HasNoEnv(name)
        return empty(a:name)
    endfunction


    function! PlugGetDir(name)
        if (exists("g:plugs") && has_key(g:plugs, a:name) && isdirectory(g:plugs[a:name].dir))
            return g:plugs[a:name].dir
        endif
        return ''
    endfunction


    " @see PlugForce
    function! PlugPatch(info)
        if empty(g:vim_confi_option.plug_patch) | return | endif

        " info is a dictionary with 3 fields
        " - name:   name of the plugin
        " - status: 'installed', 'updated', or 'unchanged'
        " - force:  set on PlugInstall! or PlugUpdate!
        if a:info.status == 'installed' || a:info.force
            !./install.py
        endif
    endfunction


    " Plug Force update with discard local change:
    "   1. git stash after save patch
    "   2. update
    "   3. patch again
    function! PlugForce()
        if !empty(g:vim_confi_option.plug_patch) && CheckPlug(g:vim_confi_option.plug_patch, 1)
            let dir_patch_repo = PlugGetDir(g:vim_confi_option.plug_patch)
            let dir_patch_tmp = dir_patch_repo. "../patch_tmp"
            call system(printf("rm -fr %s && mkdir -p %s", dir_patch_tmp, dir_patch_tmp))
            let dirties = filter(copy(g:plugs),
                  \ {_, v -> len(system(printf("cd %s && git diff --no-ext-diff --name-only", shellescape(v.dir))))})
            if len(dirties)
                call map(copy(dirties),
                      \ {name, v -> system(printf("cd %s && git diff HEAD > %s/%s.patch",
                      \                         shellescape(v.dir),
                      \                         dir_patch_tmp, name))})

                " Add patch to git-repo
                call system(printf("cd %s && rm -fr ./patch && cp -fr %s ./patch && git add ./patch",
                      \         dir_patch_repo, dir_patch_tmp))

                " Discard all local change & update
                call map(values(copy(dirties)),
                      \ {_, v -> system(printf("cd %s && git checkout -f", shellescape(v.dir)))})
                PlugUpdate --sync
                execute 'PlugInstall!' join(keys(dirties))

                " patch backto plugs
                call map(dirties,
                      \ {name, v -> system(printf("cd %s && patch -p1 < %s/%s.patch",
                      \                         shellescape(v.dir),
                      \                         dir_patch_tmp, name))})
                "call system(printf("rm -fr %s", dir_patch_tmp))
                return
            endif
        endif

        PlugUpdate
    endfunction
    command! PlugForce call PlugForce()


" }}}

" Use before config if available {
    if filereadable(expand("~/.vimrc.before"))
        source ~/.vimrc.before
    endif
" }

" Please define our priviate wiki dirs in `~/.vimrc.before`
let g:vim_wiki_dirs = get(g:, "vim_wiki_dirs", g:vim_confi_option.wiki_dirs)

" Auto download the plug
if g:vim_confi_option.auto_install_vimplug
    if LINUX()
        if empty(glob('~/.vim/autoload/plug.vim'))
            echomsg "AutoInstall: download vim-plug; mkdir .vim,.config/nvim; softlink .vimrc to init.vim"

            call system("curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/huawenyu/vim-plug/master/plug.vim")
            call system("curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/huawenyu/vim-plug/master/plug.vim")

            call system("touch ~/.vimrc; mkdir ~/.vim; mkdir ~/.config")
            call system("ln -s ~/.vim ~/.config/nvim")
            call system("ln -s ~/.vimrc ~/.config/nvim/init.vim")

            if UBUNTU()
                call system("sudo apt install -y python3-pip")
                call system("sudo apt install -y python3-distutils")
            elseif CENTOS() || FEDORA()
                call system("sudo yum install -y python3-pip")
                call system("sudo yum install -y python3-distutils")
            endif

            call system("pip3 install --user setuptools")
            call system("pip install --user pynvim")
            call system("pip3 install --user pynvim")

            autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
        endif
    endif
endif


if g:vim_confi_option.auto_install_tools
    if LINUX()
        " https://github.com/Kuniwak/vint/
        if !CheckPythonModule('vim-vint')
            " https://github.com/mattn/efm-langserver
            " https://github.com/neoclide/coc.nvim/wiki/Language-servers
            " https://github.com/igorshubovych/markdownlint-cli
            "
            echomsg "Installing vim-vint"
            call system("pip install --user vim-vint")
        endif

        if !executable('efm-langserver') && executable('brew')
            echomsg "Installing go,efm-langserver"
            if !executable('go')
                call system("brew install go")
            endif
            call system("go get github.com/mattn/efm-langserver")
        endif

    endif
endif


" Plugins {{{1}}}
" more-plugins?
if WINDOWS()
call plug#begin('~/AppData/Local/nvim/plugged')
else
call plug#begin('~/.config/nvim/bundle')
endif

" Using vimplug as multiple repo manager: other not vim-plugins repos {{{2
    Plug 'huawenyu/dotfiles',           {'dir': '~/dotfiles', 'do': './script/up-dot.sh', 'on': ['NeverEverLoadMe'], 'for': 'RepoManager'}
    Plug 'huawenyu/zsh-local',          {'dir': '~/.oh-my-zsh/custom/plugins/zsh-local', 'do': './install --all', 'on': ['NeverEverLoadMe'], 'for': 'RepoManager'}  | " [oh-my-zsh plugin] my zsh env/alias/commands
    Plug 'zsh-users/zsh-completions',   {'dir': '~/.oh-my-zsh/custom/plugins/zsh-completions', 'do': './install --all', 'on': ['NeverEverLoadMe'], 'for': 'RepoManager'} | "[oh-my-zsh plugin]
    Plug 'dooblem/bsync',               {'dir': '~/bin/repo-bsync', 'do': 'chmod +x bsync && ln -s ${PWD}/bsync ../bsync \|\| true', 'on': ['NeverEverLoadMe'], 'for': 'RepoManager'} | " Tool: sync two dirs base-on rsync
"}}}

" Plug config: order-sensible {{{2
    "Plug 'echasnovski/mini.nvim',       Cond(has('nvim') && Mode(['editor']))	 | " Alternertive ~40 plugins

    Plug 'tpope/vim-sensible',          Cond(Mode(['basic', 'log', 'floatview', 'editor']))
    "Plug 'lambdalisue/vim-manpager',    Cond(Mode(['basic', 'log', 'floatview', 'editor']))

    Plug 'huawenyu/vim-basic',          Cond(Mode(['basic', 'log', 'conf-basic', 'floatview', 'editor']))
    Plug 'huawenyu/vimConfig',          Cond(has('nvim') && Mode(['basic', 'log', 'conf-plug', 'editor']))  | " config the plugs
"}}}

" ColorTheme {{{2
    "Plug 'tomasr/molokai',              Cond(Mode(['basic', 'log', 'conf-basic', 'floatview', 'editor']))
    "Plug 'vim-scripts/holokai',         Cond(Mode(['basic', 'log', 'conf-basic', 'floatview', 'editor']))
    "Plug 'pR0Ps/molokai-dark'
    "Plug 'shannonmoeller/vim-monokai256'

    Plug 'huawenyu/jellybeans.vim',      Cond(Mode(['log', 'conf-basic', 'floatview', 'editor']))
    "Plug 'loctvl842/monokai-pro.nvim'
    "Plug 'ayu-theme/ayu-vim'
    "Plug 'junegunn/seoul256.vim'
    "Plug 'NLKNguyen/papercolor-theme'
    "Plug 'marko-cerovac/material.nvim'
    "Plug 'cpea2506/one_monokai.nvim'
"}}}

" Writer {{{2
    Plug 'junegunn/goyo.vim',           Cond(has('nvim') && Mode(['writer',]), {'on': 'Goyo'})  | " :Goyo 80
    Plug 'junegunn/limelight.vim',      Cond(has('nvim') && Mode(['writer',]), {'on': 'Limelight'}) | ":Limelight
"}}}

" Coder {{{2
    " Try/test {{{3
        Plug 'andymass/vim-matchup',             Cond (has('nvim') && Mode(['editor',]))
        Plug 'huawenyu/vim.demo',                Cond (has('nvim') && Mode(['test',]))
    "}}}

    " Comment,Extra {{{3
        Plug 'tpope/vim-commentary',             Cond(has('nvim') && Mode(['coder'])) | " gcc comment-line, gc<motion>: gcap comment-paragraph)
        "Plug 'numToStr/Comment.nvim',           Cond(has('nvim') && Mode(['coder'])) | " gcc, gbc, gcw; not works good
        Plug 'huawenyu/nerdcommenter',           Cond(has('nvim') && Mode(['coder'])) | " remap to <C-/>

        Plug 'Chiel92/vim-autoformat',           Cond(has('nvim') && Mode(['coder']))
        Plug 'vim-scripts/iptables',             Cond(has('nvim') && Mode(['admin']) && Mode(['extra']))
        Plug 'tenfyzhong/CompleteParameter.vim', Cond(has('nvim') && Mode(['coder']) && Mode(['extra']))
        Plug 'FooSoft/vim-argwrap',              Cond(has('nvim') && Mode(['coder']) && Mode(['extra']))        | " an argument wrapping and unwrapping
        Plug 'ericcurtin/CurtineIncSw.vim',      Cond(has('nvim') && Mode(['coder']))          | " Toggle source/header
    "}}}

    " gdb front-end {{{3
        Plug 'huawenyu/neogdb2.vim',        Cond(has('nvim') && Mode(['coder']))      |  " Clone from fireflowerr/vwm.vim, vim windows management
        " Plug 'huawenyu/vwm.vim',            Cond(has('nvim') && Mode(['coder']))      |  " Clone from fireflowerr/vwm.vim, vim windows management
        " Plug 'huawenyu/termdebug.nvim',     Cond(has('nvim') && Mode(['coder']) && IfNoPlug('vimspector'))    | " Add config after copy /usr/share/nvim/runtime/pack/dist/opt/termdebug/plugin/termdebug.vim
    "}}}

    " Diff {{{3
        "Plug 'rickhowe/diffchar.vim',      Cond(has('nvim') && Mode(['editor']))
        Plug 'chrisbra/vim-diff-enhanced',  Cond(has('nvim') && Mode(['editor'])) | " vimdiff:  ]c - next;  [c - previous; do - diff obtain; dp - diff put; zo - unfold; zc - fold; :diffupdate - re-scan
        "Plug 'junkblocker/patchreview-vim', Cond(has('nvim') && Mode(['editor'])) | " :PatchReview some.patch,  :DiffReview git show <SHA1>  :DiffReview git staged --no-color -U5
    "}}}

    " Hex editor {{{3
        Plug 'fidian/hexmode',              Cond(has('nvim') && Mode(['editor',]), { 'on': 'Hexmode' }) | " Hex viewer, wrap of xxd, it's good.
    "}}}

    " plugin {{{3
        Plug 'huawenyu/vim-scriptease',     Cond(has('nvim') && Mode(['coder'])) | " A Vim plugin for Vim plugins
        "Plug 'junegunn/vader.vim',          Cond(has('nvim') && Mode(['coder']) && Mode(['plugin'])) | " A simple Vimscript test framework
        "Plug 'mhinz/vim-lookup',            Cond(has('nvim') && Mode(['coder']) && Mode(['plugin']))
    "}}}

    " C/Cplus {{{3
        Plug 'huawenyu/vim-linux-coding-style',  Cond(has('nvim') && Mode(['coder']) && Mode(['c']), {'for': ['c', 'cpp']})
        Plug 'octol/vim-cpp-enhanced-highlight', Cond(has('nvim') && Mode(['coder']) && Mode(['c', 'floatview']), {'for': ['c', 'cpp']})
        Plug 'bfrg/vim-cpp-modern',              Cond(has('nvim') && HasPlug('vim-cpp-enhanced-highlight'), {'for': ['c', 'cpp']})
    "}}}

    " Python {{{3
        Plug 'python-mode/python-mode',     Cond(has('nvim') && Mode(['coder']) && Mode(['python']), {'for': 'python', 'frozen': 1 })
        Plug 'davidhalter/jedi-vim',        Cond(has('nvim') && Mode(['coder']) && Mode(['python']), {'for': 'python', 'frozen': 1 }) | " K: doc-of-method; <leader>d: go-definition; n: usage-of-file; r: rename
    "}}}

    " LaTeX {{{3
    "Plug 'lervag/vimtex',                  Cond(has('nvim') && Mode(['editor',]) && Mode(['latex',]))  | " A modern vim plugin for editing LaTeX files
    "}}}

    " Perl {{{3
        Plug 'vim-perl/vim-perl',           Cond(has('nvim') && Mode(['coder']) && Mode(['perl']), { 'for': 'perl', 'do': 'make clean carp dancer highlight-all-pragmas moose test-more try-tiny' })
        Plug 'tpope/vim-cucumber',          Cond(has('nvim') && Mode(['coder']) && Mode(['perl']), { 'for': 'perl'}) | "      Auto    test  framework base on Behaviour Drive Development(BDD)
    "}}}

    " Javascript {{{3
        Plug 'pangloss/vim-javascript',     Cond(has('nvim') && Mode(['coder']) && Mode(['javascript']), {'for': ['javascript','typescript'] })
        Plug 'maksimr/vim-jsbeautify',      Cond(has('nvim') && Mode(['coder']) && Mode(['javascript']), {'for': ['javascript','typescript'] })
        Plug 'elzr/vim-json',               Cond(has('nvim') && Mode(['coder']) && Mode(['javascript']), {'for': ['javascript','typescript'] })
        Plug 'tpope/vim-jdaddy',            Cond(has('nvim') && Mode(['coder']) && Mode(['javascript']), {'for': ['javascript','typescript'] }) | " `:%!jq     .`         ;       `:%!jq --sort-keys .`
        Plug 'ternjs/tern_for_vim',         Cond(has('nvim') && Mode(['coder']) && Mode(['javascript']), {'for': ['javascript','typescript'] }) | " Tern-based JavaScript editing support.
        Plug 'carlitux/deoplete-ternjs',    Cond(has('nvim') && Mode(['coder']) && Mode(['javascript']), {'for': ['javascript','typescript'] })
    "}}}

    " TypeScript {{{3
        "Plug 'palantir/tslint',             Cond(has('nvim') && Mode(['coder']) && Mode(['typescript']), { 'for': 'typescript' })
    "}}}

    " Clojure {{{3
        "Plug 'tpope/vim-fireplace',         Cond(has('nvim') && Mode(['coder']) && Mode(['clojure']), { 'for': 'clojure' })
    "}}}

    " Database {{{3
        "Plug 'tpope/vim-dadbod',            Cond(has('nvim') && Mode(['coder']) && Mode(['database']))       | " :DB mongodb:///test < big_query.js
    "}}}

    " Golang {{{3
        Plug 'fatih/vim-go',                Cond(has('nvim') && Mode(['coder']) && Mode(['golang']), {'for': ['golang',] })
        "Plug 'nsf/gocode', { 'tag': 'v.20150303', 'rtp': 'vim' }
    "}}}

    " Tcl {{{3
        "Plug 'LStinson/TclShell-Vim',      Cond(has('nvim') && Mode(['coder',]) && Mode(['tcl',]), {'for': ['tcl', 'expect'] })
        "Plug 'vim-scripts/tcl.vim',        Cond(has('nvim') && Mode(['coder',]) && Mode(['tcl',]), {'for': ['tcl', 'expect'] })
    "}}}

    " Haskell {{{3
        Plug 'lukerandall/haskellmode-vim', Cond(has('nvim') && Mode(['coder']) && Mode(['haskell']), {'for': 'haskell'})
        Plug 'eagletmt/ghcmod-vim',         Cond(has('nvim') && Mode(['coder']) && Mode(['haskell']), {'for': 'haskell'})
        Plug 'ujihisa/neco-ghc',            Cond(has('nvim') && Mode(['coder']) && Mode(['haskell']), {'for': 'haskell'})
        Plug 'neovimhaskell/haskell-vim',   Cond(has('nvim') && Mode(['coder']) && Mode(['haskell']), {'for': 'haskell'})
    "}}}

    " Rust {{{3
        Plug 'racer-rust/vim-racer',        Cond(has('nvim') && Mode(['coder']) && Mode(['rust']), {'for': 'rust'})
        Plug 'rust-lang/rust.vim',          Cond(has('nvim') && Mode(['coder']) && Mode(['rust']), {'for': 'rust'})
        Plug 'timonv/vim-cargo',            Cond(has('nvim') && Mode(['coder']) && Mode(['rust']), {'for': 'rust'})
    "}}}

    " Meson build system: meson.build {{{3
        "Plug 'igankevich/mesonic',         Cond(has('nvim') && Mode(['coder']))
    "}}}

    " Markdown/Writing/Wiki {{{3
        " tool-render?
        "Plug 'vimwiki/vimwiki',            Cond(has('nvim') && Mode(['editor']) && Mode(['markdown']), {'for': 'markdown'})  | " Another choice is  [Gollum](https://github.com/gollum/gollum)
        "Plug 'lervag/wiki.vim',             Cond(has('nvim') && IfNoPlug('vimwiki') && Mode(['editor']) && Mode(['markdown']), {'for': 'markdown'})  | " Better vimwiki the philosophy of 'do one thing and do it well'
        "Plug 'godlygeek/tabular',           Cond(has('nvim') && Mode(['editor']) && Mode(['markdown']), {'on': 'Tabularize', 'for': 'markdown'}) | " EasyAlign is better.

        " ge: open link
        " ]], ]c, ]u, ][: next-header/cur-header/parent/sibling/
        " [[, []: previous header/sibling
        Plug 'preservim/vim-markdown',      Cond(has('nvim') && Mode(['editor']) && Mode(['markdown']), {'for': 'markdown'})
        Plug 'ellisonleao/glow.nvim',       Cond(has('nvim') && Mode(['editor']) && Mode(['markdown']), {'on':  'Glow', 'for': 'markdown', 'setup': ':LoadGlow', })

        "Plug 'SidOfc/mkdx',                Cond(has('nvim') && Mode(['editor']) && Mode(['markdown']), {'for': 'markdown'})
        "Plug 'tpope/vim-markdown',         Cond(has('nvim') && Mode(['editor']) && Mode(['markdown']), {'as':  'tpope_vim-markdown', 'for': 'markdown'} )     |        "       Light  but good enough
    "}}}

"}}}

" Facade {{{2
    " Statusline
    "Plug 'millermedeiros/vim-statline',    Cond(has('nvim') && Mode(['coder',]))	 | " Show current-function-name, simple, not annoy to distract our focus
    "Plug 'itchyny/lightline.vim',          Cond(has('nvim') && Mode(['coder',]))	 | "
    Plug 'nvim-lualine/lualine.nvim',       Cond(has('nvim') && Mode(['coder',]))
    Plug 'vimpostor/vim-tpipeline',         Cond(has('nvim') && Mode(['coder',]) && !empty($TMUX_PANE)) | " Show vim.statusline to the tmux.statusbar

    "Plug 'rcarriga/nvim-notify',           Cond(has('nvim') && Mode(['coder',]))  | " Substitute the vim's original print-type message
    Plug 'j-hui/fidget.nvim',               Cond(has('nvim') && Mode(['coder',]), {'tag': 'legacy'})	 | " Standalone UI for nvim-lsp progress
    Plug 'huawenyu/vim-mark',               Cond(has('nvim') && Mode(['editor'])) | " mm  colorize current word
    Plug 'huawenyu/vim-signature',          Cond(has('nvim') && Mode(['editor'])) | " place, toggle and display marks

    "Plug 'itchyny/vim-cursorword',          Cond(has('nvim') && Mode(['editor'])) | " Underlines the word under the cursor
    Plug 'lukas-reineke/indent-blankline.nvim', Cond(has('nvim') && Mode(['editor']) && g:vim_confi_option.indentline)
    "Plug 'nvimdev/indentmini.nvim',         Cond(has('nvim') && Mode(['editor'])) | " Not pretty/correct
    "Plug 'junegunn/rainbow_parentheses.vim',   Cond(has('nvim') && Mode(['editor']))

    " Copy directly into vim.config/plugin/misc.vim
    "Plug 'teto/vim-listchars',             Cond(has('nvim') && IfNoPlug('cyclist.vim') && Mode(['coder']))	 | " cycle listchars
    " prettier/vim-prettier

    " Windows related
    "Plug 'stevearc/stickybuf.nvim',        Cond(has('nvim') && Mode(['coder']))      |  " Can't make it works; bind buffer with the window
    Plug 'folke/which-key.nvim',        Cond(has('nvim') && Mode(['editor']) && g:vim_confi_option.help_keys, { 'setup': ':let g:which_key_preferred_mappings = 1' }) |  " Show/remember vim keymaps

    Plug 'chrisbra/NrrwRgn',            Cond(has('nvim') && Mode(['editor',]), {'on': ['NR', 'NRV'], })   | " focus on a selected region. :NR - Open selected into new window; :w - (in the new window) write the changes back
    "Plug 'jamessan/vim-gnupg',         Cond(has('nvim') && Mode(['extra']) && Mode(['admin']))         | " implements transparent editing of gpg encrypted files.
    Plug 'huawenyu/vim-tabber',         Cond(has('nvim') && Mode(['editor',]))        | " Tab management for Vim: the orig-version have no commands
    "Plug 'akinsho/bufferline.nvim',         Cond(has('nvim') && Mode(['editor',]))        | "
"}}}

" Syntax/Language {{{2
    "Plug 'norcalli/nvim-colorizer.lua'

    " Speedup vim by disable syntastic checker when write event
    "Plug 'vim-syntastic/syntastic',        Cond(has('nvim') && Mode(['editor', 'floatview']))
    ""Plug 'Chiel92/vim-autoformat',        Cond(has('nvim') && Mode(['coder',]))

    Plug 'justinmk/vim-syntax-extra',       Cond(has('nvim') && Mode(['coder',]), {'for': 'vim'})
    Plug 'vim-scripts/awk.vim',             Cond(has('nvim') && Mode(['admin',]) && Mode(['script']), {'for': 'awk'})
    Plug 'huawenyu/vim-log-syntax',         Cond(has('nvim') && Mode(['editor', 'log', ]), {'for': 'log'})
    Plug 'huawenyu/vim-autotest-syntax',    Cond(has('nvim') && Mode(['editor', 'log', ]), {'for': 'log'})
    Plug 'tmux-plugins/vim-tmux',           Cond(has('nvim') && Mode(['editor',]), {'for': 'tmux'})  | " The syntax of .tmux.conf
    Plug 'nickhutchinson/vim-cmake-syntax', Cond(has('nvim') && has('nvim') && Mode(['coder',]), {'for': 'cmake'})
    Plug 'xuhdev/syntax-dosini.vim',        Cond(has('nvim') && has('nvim') && Mode(['coder',]), {'for': 'dosini'})
    Plug 'eiginn/iptables-vim',             Cond(has('nvim') && has('nvim') && Mode(['coder',]))
"}}}

" Improve {{{2
    " Basic {{{3
        Plug 'junegunn/fzf',                Cond(has('nvim') && Mode(['editor',]), { 'dir': '~/.fzf', 'do': './install --all' })    | "Update-to-latest ($ fzf --version), FromVim :PlugUpdate fzf
        Plug 'junegunn/fzf.vim',            Cond(has('nvim') && HasPlug('fzf') && Mode(['editor',]))
        Plug 'junegunn/heytmux',            Cond(has('nvim') && Mode(['editor',]), { 'do': 'gem install heytmux' })     | " Shell: $ heytmux workspace.yml

        Plug 'kopischke/vim-fetch',         Cond(has('nvim') && Mode(['editor',]))      | " Support vim fname:line
        Plug 'nhooyr/neoman.vim',           Cond(has('nvim') && Mode(['coder',]), {'on': ['Nman', 'Snman']} )       | " Seems default :Man can't support view a file directly

        "Plug 'sudormrfbin/cheatsheet.nvim'
        "Plug 'nvim-lua/popup.nvim'
        "Plug 'nvim-lua/plenary.nvim'

        " Cody AI-code
        "Plug 'sourcegraph/sg.nvim', { 'do': 'nvim -l build/init.lua' }
        " Required for various utilities
        Plug 'nvim-lua/plenary.nvim',                       Cond(has('nvim') && Mode(['editor', 'floatview']))
        " Required if you want to use some of the search functionality
        Plug 'nvim-telescope/telescope.nvim',               Cond(has('nvim') && Mode(['coder',]))        | "
        Plug 'nvim-telescope/telescope-fzf-native.nvim',    Cond(has('nvim') && Mode(['coder',]), { 'do': 'make' })        | "
        Plug 'nvim-telescope/telescope-hop.nvim',           Cond(has('nvim') && Mode(['coder',]))    | "

    " Copy {{{3
        Plug 'ojroques/vim-oscyank',        Cond(has('nvim') && Mode(['editor']))       | " Tmux-user following [doc](https://github.com/tmux/tmux/wiki/Clipboard#quick-summary)
        Plug 'AckslD/nvim-neoclip.lua',     Cond(has('nvim') && Mode(['editor']))       | "
        "Plug 'gbprod/yanky.nvim',          Cond(has('nvim') && Mode(['editor']))       | " rm for anoy error: clipboard: error: Error: Can't open display: localhost:10.0; Feature: vim history of select, alternative 'AckslD/nvim-neoclip.lua'

    " Search/Jump {{{3
        Plug 'mhinz/vim-grepper',           Cond(has('nvim') && Mode(['editor',]), {'on': ['Grepper', 'GrepperAg', 'GrepperGit','GrepperGrep', 'GrepperRg']})  | " :Grepper text
            Plug 'huawenyu/c-utils.vim',    Cond(has('nvim') && Mode(['coder']) && HasPlug('vim-grepper') )
        "Plug 'pechorin/any-jump.vim',      Cond(has('nvim') && Mode(['coder',]))  | " Regex-fail when search-by 'rg',   ;jj  ;jb  ;jl
        "Plug 'tweekmonster/fzf-filemru',    Cond(has('nvim') && Mode(['editor',]) && HasPlug('fzf.vim'), {'on': 'FilesMru'})   | " : FilesMru
        Plug 'chengzeyi/fzf-preview.vim',   Cond(has('nvim') && Mode(['editor',]) && HasPlug('fzf.vim'))   | " Wrap with enable preview of fzf.vim
            Plug 'huawenyu/fzf-cscope.vim', Cond(has('nvim') && Mode(['editor',]) && HasPlug('fzf-preview.vim') && HasPlug('vim-basic'))

        Plug 'romainl/vim-cool',                Cond(has('nvim') && Mode(['editor',]))  | " No config, just disables search highlighting when you are done searching and re-enables it when you search again.
        Plug 'PeterRincker/vim-searchlight',    Cond(has('nvim') && Mode(['editor',]))  | " No config
        Plug 'kwkarlwang/bufjump.nvim',         Cond(has('nvim') && Mode(['editor',]))  | "
        Plug 'huawenyu/vim-windowswap',         Cond(has('nvim') && Mode(['coder']))      |  " Swap window buffers

        " Tags/cscope/indexer? {{{4
            Plug 'preservim/tagbar',                Cond(has('nvim') && IfNoPlug('vista.vim') && Mode(['coder',]), {'on': ['TagbarToggle', 'Tagbar', 'TagbarOpen'], 'config': 'LoadTagbar'})
            "Plug 'simrat39/symbols-outline.nvim',  Cond(has('nvim') && Mode(['coder',]), {'on': 'SymbolsOutline', 'setup': 'LoadSymbolsOutline'})
            "Plug 'liuchengxu/vista.vim',   Cond(has('nvim') && IfNoPlug('tagbar')    && Mode(['coder',]))
            "Plug 'vim-scripts/taglist.vim',Cond(has('nvim') && HasPlug('tagbar')     && Mode(['coder',]) && LINUX())
        "}}}

        " Quickfix/Todo list {{{4
            Plug 'huawenyu/quickfix-reflector.vim', Cond(has('nvim') && Mode(['editor',]))    | " Directly edit the quickfix, Refactor code from a quickfix list and makes it editable
            "Plug 'kevinhwang91/nvim-bqf',          Cond(has('nvim') && Mode(['editor',]))    | " Seems telescope.quickfix cover the feature, Better quickfix: zf   fzf-mode
            "Plug 'romainl/vim-qf',                 Cond(has('nvim') && Mode(['editor',]))    | " Tame the quickfix window

            Plug 'folke/todo-comments.nvim',        Cond(has('nvim') && Mode(['editor',]), { 'on': ['TodoLocList', 'TodoQuickFix'], 'setup': ':LoadTodo', } )       | " :TodoLocList, :TodoQuickFix
            "Plug 'freitass/todo.txt-vim',          Cond(has('nvim') && Mode(['editor',]) && Mode(['extra']))       | " codeblock with 'todo', http://todotxt.org/
            "Plug 'bfrg/vim-qf-preview',            Cond(has('nvim') && Mode(['editor',]) && Mode(['extra']))

        "}}}

        " history {{{4
            "Plug 'liuchengxu/vim-clap',            Cond(has('nvim') && Mode(['editor',]))    | "
        "}}}
    "}}}

    " Suggar {{{3
        "Plug 'Raimondi/delimitMate',       Cond(has('nvim') && Mode(['editor']) && IfNoPlug('auto-pairs'))
        "Plug 'jiangmiao/auto-pairs',       Cond(has('nvim') && Mode(['editor']) && IfNoPlug('delimitMate')) |  " Not work if  :set paste
        "Plug 'tpope/vim-endwise',          Cond(has('nvim') && Mode(['editor']))     | " smart insert certain end structures automatically.
        Plug 'windwp/nvim-autopairs',       Cond(has('nvim') && Mode(['editor']))

        Plug 'huawenyu/vim-unimpaired',     Cond(has('nvim') && Mode(['editor']))     | "Clone from @tpope
        Plug 'tpope/vim-surround',          Cond(has('nvim') && Mode(['editor']))     | " Help add/remove surround
        Plug 'tpope/vim-rsi',               Cond(has('nvim') && Mode(['editor']))     | " Readline shortcut for vim

        " Auto indent
        Plug 'ciaranm/securemodelines',     Cond(has('nvim') && Mode(['editor'])) | " Limit the vim magic mode line feature
        "Plug 'tpope/vim-sleuth',           Cond(has('nvim') && Mode(['editor',]))| " vimscript base
        "Plug 'NMAC427/guess-indent.nvim',  Cond(has('nvim') && Mode(['editor',]))| " Lua base
    "}}}

    " Motion {{{3
        Plug 'christoomey/vim-tmux-navigator',  Cond(has('nvim') && Mode(['basic', 'editor', 'log', 'floatview']) && !empty($TMUX_PANE))

        Plug 'mg979/vim-visual-multi',          Cond(has('nvim') && Mode(['editor',]))      | " `\\` Active:   Mult-select Change/replace/align, https://github.com/mg979/vim-visual-multi/blob/master/doc/vm-mappings.txt
        "Plug 'anuvyklack/hydra.nvim',          Cond(has('nvim') && Mode(['editor',]))      | " Create custom submodes and menus
        "Plug 'smoka7/multicursors.nvim',       Cond(has('nvim') && Mode(['editor',]))      | " Mult-select Change/replace/align,

        "Plug 'easymotion/vim-easymotion',      Cond(has('nvim') && Mode(['editor',]))
        Plug 'phaazon/hop.nvim',                Cond(has('nvim') && Mode(['editor',]), {'on': ['HopChar1CurrentLine', 'HopChar1', 'HopChar2', 'HopPattern', 'HopLineStart', 'HopLine'], 'setup': 'LoadHop'})

        Plug 'tpope/vim-abolish',               Cond(has('nvim') && Mode(['editor',]))      | " :Subvert/child{,ren}/adult{,s}/g
        "Plug 'karb94/neoscroll.nvim',          Cond(has('nvim') && Mode(['editor',]))  | " Make eye dizzy

        " 1. Rename a var:  search the var -> cgn -> change-it -> .(repeat-it-whole)
        Plug 'tpope/vim-repeat',            Cond(has('nvim') && Mode(['editor',]))
            " gA                   shows the four representations of the number under the cursor.
            " crd, crx, cro, crb   convert the number under the cursor to decimal, hex, octal, binary, respectively.
            " Plug  'glts/vim-radical',       Cond(has('nvim') && HasPlug('vim-repeat') && Mode(['editor',]))
            " Plug  'glts/vim-magnum',        Cond(has('nvim') && HasPlug('vim-repeat') && Mode(['editor',]))
            " Plug  'triglav/vim-visual-increment', Cond(has('nvim') && HasPlug('vim-repeat') && Mode(['editor',]))    | " Select by C-v, then increase by C-a, <OR-step-#>  #C-a

        Plug 'rhysd/clever-f.vim',          Cond(has('nvim') && Mode(['editor',]))   | " Using 'f' to repeat, and also we can release ';' as our new map leader
        Plug 'huawenyu/vim-motion',         Cond(has('nvim') && Mode(['editor',]))  | " Jump according indent
        Plug 'junegunn/vim-easy-align',     Cond(has('nvim') && Mode(['editor',]), {'on': 'EasyAlign'})   | " tablize selected and ga=
        "Plug 'dhruvasagar/vim-table-mode',  Cond(has('nvim') && Mode(['editor',]))| " <leader>tm :TableModeToggle; <leader>tr: Align; <leader>tt: Format existed
    "}}}

    " Auto completion {{{2
        " The autocomp fzf seems not works
        "Plug 'ms-jpq/coq_nvim',            Cond(has('nvim') && Mode(['coder',]) && LINUX(), {'branch': 'coq'})
        "Plug 'ms-jpq/coq.artifacts',       Cond(has('nvim') && Mode(['coder',]) && LINUX(), {'branch': 'artifacts'})
        "Plug 'ms-jpq/coq.thirdparty',      Cond(has('nvim') && Mode(['coder',]) && LINUX(), {'branch': '3p'})

        Plug 'Shougo/deoplete.nvim',        Cond(has('nvim') && Mode(['editor',]) && LINUX(), )         | "{ 'do': ':UpdateRemotePlugins' }
            Plug 'Shougo/neosnippet.vim',       Cond(has('nvim') && HasPlug('deoplete.nvim') && Mode(['editor',]))        | " <Tab> apply code, c-n next, c-p previous, :NeoSnippetEdit
            Plug 'Shougo/neosnippet-snippets',  Cond(has('nvim') && HasPlug('deoplete.nvim') && Mode(['editor',]))
            Plug 'huawenyu/vim-snippets.local', Cond(has('nvim') && HasPlug('deoplete.nvim') && Mode(['editor',])  && Mode(['snippet',]))
            Plug 'huawenyu/vim-template',       Cond(has('nvim') && Mode(['editor',]))                     | " :TemplateHere .md

        "Plug 'SirVer/ultisnips',           Cond(has('nvim') && HasPlug('deoplete.nvim') && Mode(['editor',]))        | " c-k apply code, c-n next, c-p previous, :NeoSnippetEdit
        "Plug 'honza/vim-snippets',         Cond(has('nvim') && HasPlug('deoplete.nvim') && Mode(['editor',]) && Mode(['snippet',]))

        Plug 'reedes/vim-wordy',            Cond(has('nvim') && Mode(['writer',]) && Mode(['snippet',]))
        Plug 'gelguy/wilder.nvim',          Cond(has('nvim') && Mode(['editor',]), { 'do': ':UpdateRemotePlugins' })  | " command line autocomplete
            Plug 'roxma/nvim-yarp',        Cond(has('nvim') && Mode(['editor',]) && HasPlug('wilder.nvim'), { 'do': 'pip install -r requirements.txt' })  | " command line autocomplete

        " LSP - Autocomplete/AutoIndexer
            " Plug 'neovim/nvim-lspconfig'
            " " setting with vim-lsp
            " if executable('ccls')
            "    au User lsp_setup call lsp#register_server({
            "       \ 'name': 'ccls',
            "       \ 'cmd': {server_info->['ccls']},
            "       \ 'root_uri': {server_info->lsp#utils#path_to_uri(
            "       \   lsp#utils#find_nearest_parent_file_directory(
            "       \     lsp#utils#get_buffer_path(), ['.ccls', 'compile_commands.json', '.git/']))},
            "       \ 'initialization_options': {
            "       \   'highlight': { 'lsRanges' : v:true },
            "       \   'cache': {'directory': stdpath('cache') . '/ccls' },
            "       \ },
            "       \ 'whitelist': ['c', 'cpp', 'objc', 'objcpp', 'cc'],
            "       \ })
            " endif

            "Plug 'nvim-treesitter/nvim-treesitter',             Cond (has('nvim') && Mode(['admin']), { 'do': ':TSUpdate', 'for': ['c', 'cpp', 'rust', 'java', 'awk', 'bash', 'meson', 'python', 'tcl', 'expect'] })
            " Plug 'nvim-treesitter/nvim-treesitter-refactor',  Cond (has('nvim') && HasPlug('nvim-treesitter') && Mode(['editor',]))
            " Plug 'nvim-treesitter/playground',                Cond (has('nvim') && HasPlug('nvim-treesitter') && Mode(['editor',]))
            " Plug 'romgrk/nvim-treesitter-context',            Cond (has('nvim') && HasPlug('nvim-treesitter') && Mode(['editor',]))
            " Plug 'nelstrom/vimprint',                         Cond (has('nvim') && HasPlug('nvim-treesitter') && Mode(['editor',]))

            " :LspInfo
            Plug 'neovim/nvim-lspconfig',           Cond(has('nvim') && Mode(['coder',]))
            Plug 'williamboman/nvim-lsp-installer', Cond(has('nvim') && Mode(['coder',]))

            "Plug 'glepnir/lspsaga.nvim',       Cond(has('nvim') && Mode(['coder',]) && LINUX(), {'branch': 'main'})
            Plug 'ojroques/nvim-lspfuzzy',      Cond(has('nvim') && Mode(['editor',]))  | " Sink lsp-result to fzf-float-windows, Select-All<c-aa> sink again to quickfix(<enter>)
            "Plug 'gfanto/fzf-lsp.nvim',        Cond(has('nvim') && Mode(['editor',]))
            "Plug 'VonHeikemen/lsp-zero.nvim',  Cond(has('nvim') && Mode(['editor',]))

        " Backend using node.js and eat too much memory/CPU
        "Plug 'neoclide/coc.nvim',          Cond(has('nvim') && Mode(['coder',]) && LINUX(), {'branch': 'release'})
            "Plug 'neoclide/coc.nvim',      Cond(has('nvim') && Mode(['coder',]) && LINUX(), {'do': 'yarn install --frozen-lockfile'})  | " sometimes find references fail
            "Plug 'neoclide/coc.nvim',      Cond(has('nvim') && Mode(['coder',]) && LINUX(), {'on': ['<Plug>(coc-definition)', '<Plug>(coc-references)'], 'do': 'yarn install --frozen-lockfile'})  | " Increase stable by only load the plugin after the 1st command call.
            "Plug 'neoclide/coc-rls',       Cond(has('nvim') && Mode(['coder',]) && LINUX())

        " Seem it's take too much CPU/memory, just comment out.
        "Plug 'hrsh7th/nvim-cmp',           Cond(has('nvim') && Mode(['editor',]))
        "Plug 'hrsh7th/cmp-nvim-lsp',       Cond(has('nvim') && Mode(['editor',]))
        "" Plug 'hrsh7th/cmp-buffer',       Cond(has('nvim') && Mode(['editor',]))
        "" Plug 'hrsh7th/cmp-path',         Cond(has('nvim') && Mode(['editor',]))
        "" Plug 'hrsh7th/cmp-cmdline',      Cond(has('nvim') && Mode(['editor',]))
        "Plug 'hrsh7th/cmp-vsnip',          Cond(has('nvim') && Mode(['editor',]))
        "Plug 'hrsh7th/vim-vsnip',          Cond(has('nvim') && Mode(['editor',]))
        "Plug 'lukas-reineke/cmp-rg',       Cond(has('nvim') && Mode(['editor',]))
    "}}}

    " Text objects? {{{2
    " https://blog.carbonfive.com/vim-text-objects-the-definitive-guide/
        Plug 'wellle/targets.vim',              Cond(has('nvim') && Mode(['editor']))      | " number-repeat/`n`ext/`l`ast: quota `,`, comma `,`, `(` as n
        Plug 'terryma/vim-expand-region',       Cond(has('nvim') && Mode(['editor']))     | " W/B - wider/narrow select-region
        Plug 'kana/vim-textobj-user',           Cond(has('nvim') && Mode(['editor']))      | " v-Select, d/x-Delete, c-Change, y-Yank, g-Goto; i-inside a-around
            Plug 'michaeljsmith/vim-indent-object', Cond(has('nvim') && Mode(['editor',])) | " <count>iI
            Plug 'glts/vim-textobj-indblock',       Cond(has('nvim') && Mode(['editor',])) | " o, Indentation block
            "Plug 'kana/vim-textobj-indent',        Cond(has('nvim') && Mode(['editor',])) | " iI
            Plug 'kana/vim-textobj-entire',         Cond(has('nvim') && Mode(['coder',]))  | " e, Whole buffer
            Plug 'mattn/vim-textobj-url',           Cond(has('nvim') && Mode(['editor',])) | " u, URL
            Plug 'kana/vim-textobj-diff',           Cond(has('nvim') && Mode(['coder',]))  | " dh-hunk  vdH-file  vdf-file
            Plug 'Julian/vim-textobj-brace',        Cond(has('nvim') && Mode(['editor',])) | " j
            Plug 'whatyouhide/vim-textobj-xmlattr', Cond(has('nvim') && Mode(['coder',]))  | " x
            Plug 'pocke/vim-textobj-markdown',      Cond(has('nvim') && Mode(['editor',])) | " c
            Plug 'glts/vim-textobj-comment',        Cond(has('nvim') && Mode(['coder',]))  | " c
            Plug 'preservim/vim-textobj-sentence',  Cond(has('nvim') && Mode(['editor',])) | " s; motion-(); jump-g()
            Plug 'kana/vim-textobj-function',       Cond(has('nvim') && Mode(['coder',]))  | " f, Function, support: c, java, vimscript
            "Plug 'thinca/vim-textobj-between',     Cond(has('nvim') && Mode(['editor',])) | " f,
            "Plug 'machakann/vim-textobj-functioncall', Cond(has('nvim') && Mode(['coder',]))

    "}}}

"}}}

" Tools {{{2
    " Terminal/shell  {{{3
        Plug 'tpope/vim-eunuch',            Cond(has('nvim') && Mode(['admin',]))  | " Support unix shell cmd: Delete,Unlink,Move,Rename,Chmod,Mkdir,Cfind,Clocate,Lfind,Wall,SudoWrite,SudoEdit
        "Plug 'tpope/vim-dotenv',            Cond(has('nvim') && Mode(['admin',]))  | " Basic support for .env and Procfile

        Plug 'voldikss/vim-floaterm',      Cond(has('nvim') && Mode(['editor',]), {'on': ['FloatermKill', 'FloatermNew', 'FloatermShow', 'FloatermUpdate']}) | "
        Plug 'huawenyu/vim-floaterm-repl', Cond(has('nvim') && HasPlug('vim-floaterm') && HasPlug('vim-basic') && Mode(['editor',]), {'on': 'FloatermRepl'})  | "
        Plug 'wsdjeg/notifications.vim',   Cond(has('nvim') && Mode(['editor',]), {'on': ['Echo', 'Echoerr']})	| " :Echoerr xxxxx

        Plug 'huawenyu/vimux',             Cond(has('nvim') && Mode(['admin']) && !empty($TMUX_PANE))   | " Send command to tmux's marked pane

        Plug 'akinsho/toggleterm.nvim',     Cond(has('nvim') && Mode(['admin',]), {'tag' : '*'})  | " Used by AsyncTask, :TermExec cmd='ls -l'  <OR> Toogle-terminal by <C-\>;     BUT 1.start-shell-slow 2.Can't re-use-same-window exe next command
        "Plug 'nikvdp/neomux',               Cond(has('nvim') && Mode(['editor',])) | " :Neomux,    BUT 2.Can't re-use-same-window exe next command
        "Plug 'wincent/terminus',            Cond(has('nvim') && Mode(['admin',]))  | " Enhanced terminal integration for Vim

        "Plug 'thinca/vim-quickrun',            Cond(has('nvim') && Mode(['editor',]))   | " :QuickRun
        "Plug 'jpalardy/vim-slime',             Cond(has('nvim') && Mode(['editor',]))   | " :
        "Plug 'jalvesaq/vimcmdline',            Cond(has('nvim') && Mode(['editor',]))   | " :
    "}}}

    " Async {{{3
        "Plug 'tpope/vim-dispatch',         Cond(has('nvim') && Mode(['admin',]))
        "Plug 'Shougo/vimproc.vim',         Cond(has('nvim') && Mode(['admin',]), {'do' : 'make'})
        "Plug 'neomake/neomake',            Cond(has('nvim') && Mode(['admin',]))

        Plug 'huawenyu/asyncrun.vim',    Cond(has('nvim') && Mode(['admin',]))
        Plug 'skywind3000/asynctasks.vim',     Cond(has('nvim') && HasPlug('asyncrun.vim') && Mode(['admin',]))   | " ~/.vim/tasks.ini
        "Plug 'skywind3000/vim-terminal-help',   Cond(has('nvim') && Mode(['editor',]))   | " :H ls -l  <OR> Toogle-terminal by <C-\>;
    "}}}

    " Repl {{{3
        "Plug 'jdhao/better-escape.vim',    Cond(has('nvim') && Mode(['editor',]))	| " :let g:better_escape_shortcut = 'jj'

        "Plug 'michaelb/sniprun',           Cond(has('nvim') && Mode(['admin']), {'do': 'bash install.sh'})   | " REPL/interpreters:  :SnipRun, :'<,'>SnipRun, :SnipReset, :SnipClose
        "Plug 'arjunmahishi/flow.nvim',     Cond(has('nvim') && Mode(['coder',]))   | " runcode.nvim
        "Plug 'xolox/vim-misc',             Cond(has('nvim') && Mode(['coder',]))	| " :
        Plug 'skywind3000/vim-preview',     Cond(has('nvim') && Mode(['coder'])) |  " Improve preview

    "}}}

    " Windows/Preview  {{{3
        Plug 'folke/edgy.nvim',             Cond(has('nvim') && Mode(['coder'])) |  " Windows layout management
    "}}}

    " Presentation? draw? pencil  {{{3
        Plug 'sk1418/blockit',              Cond(has('nvim') && Mode(['editor',]), { 'on': 'Block' })       | " :Block -- Draw a Box around text region
        Plug 'sk1418/HowMuch',              Cond(has('nvim') && Mode(['editor',]), { 'on': 'HowMuch' })       | " V-Select, then get summary by: <Leader><Leader>?s

        " Terminal Powerpoint: Suggestion use `presenterm` (https://mfontanini.github.io/presenterm/guides/basics.html)
        "Plug 'sotte/presenting.vim',        Cond(has('nvim') && Mode(['editor',]), {'for': 'markdown'})    | "PPT: n-next, p-prev, q-quit

        "Plug 'jbyuki/venn.nvim',            Cond(has('nvim') && Mode(['editor',]), { 'on': ['ToggleVennDraw', ], })       | " Draw pencil
    "}}}

    " Project/Session/Workspace {{{3
        "Plug 'tpope/vim-projectionist',         Cond(has('nvim') && Mode(['editor']) && Mode(['extra']))  | " MVC like project, used when our project have some fixed struct map rule
        "Plug 'c-brenn/fuzzy-projectionist.vim', Cond(has('nvim') && Mode(['coder'])  && Mode(['extra']))  | " Change the prefixChar from E to F, we can get fuzzy feature
        Plug 'rmagatti/auto-session',            Cond(has('nvim') && Mode(['editor']))  | " neovim > 0.7
    "}}}

    " File/Explore {{{3
        " Dependencies by neo-tree.nvim:
            Plug 'nvim-lua/plenary.nvim',        Cond(has('nvim') && Mode(['editor',]))   | " :Neotree
            Plug 'nvim-tree/nvim-web-devicons',  Cond(has('nvim') && Mode(['editor',]))   | " :Neotree
            Plug 'MunifTanjim/nui.nvim',         Cond(has('nvim') && Mode(['editor',]))   | " :Neotree
            "Plug '3rd/image.nvim',              Cond(has('nvim') && Mode(['editor',]))   | " :Neotree
        Plug 'nvim-neo-tree/neo-tree.nvim', Cond(has('nvim') && Mode(['editor',]), { 'on': 'Neotree', 'setup': ':LoadNeotree'})

        Plug 'preservim/nerdtree',          Cond(has('nvim') && Mode(['editor',]), { 'on':  ['NERDTreeToggle', 'NERDTreeTabsToggle', 'NERDTreeFocus'], 'config': 'LoadNerdtree' })   | " :NERDTreeToggle; <Enter> open-file; '?' Help, and remap 'M' as menu
        "Plug 'jistr/vim-nerdtree-tabs',    Cond(has('nvim') && Mode(['editor',]) && IfNoPlug('neo-tree.nvim'), { 'on':  'NERDTreeTabsToggle' })   | " :NERDTreeTabsToggle, Just one NERDTree, always and ever. It will always look the same in all tabs, including expanded/collapsed nodes, scroll position etc.
        "Plug 'lambdalisue/fern.vim',            Cond(has('nvim') && Mode(['editor',]), { 'on':  ['Fern',] })   | " :Fern . -draw -width=30
            Plug 'LumaKernel/fern-mapping-fzf.vim', Cond(has('nvim') && HasPlug('fern.vim') && Mode(['editor',]), { 'on':  ['Fern',] })   | " maps-for-fern-windows: ff, fd, fa, frf, frd, fra
            "Plug 'yuki-yano/fern-preview.vim',      Cond(has('nvim') && HasPlug('fern.vim') && Mode(['editor',]), { 'on':  ['Fern',] })   | " :

        Plug 'Shougo/defx.nvim',            Cond(has('nvim') && Mode(['editor']) && Mode(['extra']), { 'do': ':UpdateRemotePlugins' })
        Plug 'kristijanhusak/defx-git',     Cond(has('nvim') && Mode(['editor',]) && Mode(['extra']))
        Plug 'kristijanhusak/defx-icons',   Cond(has('nvim') && Mode(['editor',]) && Mode(['extra']))

    "}}}
    "

    " Outline/Context {{{3
        Plug 'huawenyu/VOoM',               Cond(has('nvim') && Mode(['editor', 'log', ]), { 'on': ['VoomToggle', 'Voom'] })
        "Plug 'vim-voom/VOoM_extras',       Cond(has('nvim') && Mode(['editor']))  | " Seems no use at all, but slow/frozen when read large file (>100M)
        Plug 'wellle/context.vim',          Cond(has('nvim') && Mode(['coder',]), {'on': 'ContextToggle', 'config': 'LoadContextVim'})    | " Show context every where
        "Plug 'nvim-treesitter/nvim-treesitter-context', Cond(has('nvim') && Mode(['coder',]))
        "Plug "SmiteshP/nvim-navic",         Cond(has('nvim') && Mode(['editor']) && HasPlug('nvim-lspconfig'))
    "}}}

"}}}

" Integration {{{2
    " git {{{3
        Plug 'tpope/vim-fugitive',          Cond(has('nvim') && Mode(['editor']) && Mode(['git']))   | " git blame:  :Gblame, help-g?  close-gq  key: -,~,P
        "Plug 'tpope/vim-rhubarb',          Cond(has('nvim') && Mode(['editor']) && Mode(['git']))   | " git blame:  :Gblame, help-g?  close-gq  key: -,~,P
        Plug 'mattn/gist-vim',              Cond(has('nvim') && Mode(['editor']) && Mode(['extra']), {'on': 'Gist'})              | " :'<,'>Gist -e 'list-sample'
        Plug 'airblade/vim-gitgutter',      Cond(has('nvim') && Mode(['editor']) && HasPlug('vim-fugitive'), { 'on':  ['GitGutterToggle'] })  | " Heavy Shows a git diff
        Plug 'junegunn/gv.vim',             Cond(has('nvim') && Mode(['editor']) && HasPlug('vim-fugitive'), { 'on': ['GV'] })  | " Awesome git wrapper
        "Plug 'AckslD/nvim-FeMaco.lua',      Cond(has('nvim') && Mode(['coder']), { 'on': 'FeMaco', 'setup': ':LoadFeMaco' }) | " Dependencies: tree-sitter

        " Troubleshooting :SignifyDebug
        " Diff by commit: export GitSHA=76748de92fa
        Plug 'mhinz/vim-signify',           Cond(has('nvim') && Mode(['editor',]))   | " Light/Quicker then vim-gitgutter to show git diff

        "Plug 'rbgrouleff/bclose.vim',       Cond(has('nvim') && Mode(['editor']) && Mode(['extra']) && executable('tig'))
        "Plug 'iberianpig/tig-explorer.vim', Cond(has('nvim') && Mode(['editor']) && Mode(['extra']) && HasPlug('bclose.vim') && executable('tig'))         | " tig for vim (https://github.com/jonas/tig): should install tig first.

    "}}}

    Plug 'huawenyu/tldr.nvim',              Cond(has('nvim') && executable('tldr') && Mode(['editor',]))    | " :Tldr <list>
    Plug 'yuratomo/w3m.vim',                Cond(has('nvim') && executable('w3m') && Mode(['admin',]) && Mode(['tool',]), {'on':['W3m', 'W3mTab'], 'config': 'LoadW3m'} ) | " :W3m
    Plug 's1n7ax/nvim-window-picker',       Cond(has('nvim') && Mode(['editor',]) && Mode(['tool',]))
"}}}

" Thirdpart Library {{{2
    Plug 'vim-jp/vital.vim',                Cond(has('nvim') && Mode(['coder']) && Mode(['library']))  | " promise?
    Plug 'google/vim-maktaba',              Cond(has('nvim') && Mode(['coder']) && Mode(['library']))
    Plug 'tomtom/tlib_vim',                 Cond(has('nvim') && Mode(['coder']) && Mode(['library']))
    "Plug 'echasnovski/mini.icons',          Cond(has('nvim') && Mode(['editor']))	 | "
"}}}

" Debug {{{2
    "Plug 'gu-fan/doctest.vim',              Cond(has('nvim') && Mode(['admin', 'coder']))     | " doctest for language vimscript, :DocTest
    Plug 'huawenyu/vimlogger',              Cond(has('nvim') && Mode(['admin', 'coder']))
"}}}

call plug#end()

" Keymap fzf {{{2

" nvim/vim shared: vim-basic
if has('nvim') && Mode(['coder',])
    if HasPlug('vim-basic')
        " Load my lua utils functions
        lua require 'nvim_utils'
    endif
endif


if g:vim_confi_option.debug && HasPlug('vimlogger')
    echomsg "Enable debug mode, please try 'tail -f /tmp/vim.log'."
    " troubleshooting?
    "silent! call logger#init('ALL', ['/dev/stdout', '/tmp/vim.log'])
    silent! call logger#init('ALL', ['/tmp/vim.log'])
endif


" END-setting {{{1
    " Only here works {{{2
    if has('nvim') && Mode(['coder',])
        augroup ugly_set
            autocmd!
            if has('cscope')
                autocmd BufEnter * call cscope#LoadCscope()
            endif
            autocmd BufEnter * set nolazyredraw lazyredraw
            autocmd BufEnter * redraw!

            autocmd BufRead,BufNewFile * setlocal signcolumn=yes
            autocmd FileType tagbar,nerdtree,voomtree,qf setlocal signcolumn=no
        augroup end
    endif
    "}}}

"}}}


if g:vim_confi_option.auto_install_plugs
    autocmd VimEnter *
        \   if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
        \ |     PlugInstall --sync | q
        \ | endif
endif


if filereadable(expand("~/.vimrc.after"))
    source ~/.vimrc.after
endif

