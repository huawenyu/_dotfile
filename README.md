---
  title: Dotfiles
  sub_title: _
  authors:
    - presenterm -x [^1]
---

# dotfiles

linux config files: zsh, tmux, vim, script, ...
- editor: nvim
- tmux: multiple shell with share support
- [sub](https://github.com/qrush/sub): a delicious way to organize programs/scripts/tools
- vimplug: nvim/vim plugin manager, used to update this `dotfiles`
- xclip: clipboard tool

## QuickStart

 <!-- cmd:pause -->
```bash +exec
ls -a ~/ | egrep '^\.'
```

 <!-- cmd:pause -->
 <!-- cmd:jump_to_middle -->
 **Stew**
 -
Stew is a tool for managing your dotfiles and configuration files using symlinks.
 <!-- cmd:end_slide -->

# Stew

 **1. Create dotfiles git-repo**
 -
```bash
mkdir ~/.dotfiles
cd ~/.dotfiles
git init
```

 <!-- cmd:pause -->
 **2. Move config files to the repo**
 -
```bash
mv ~/.bashrc ~/.dotfiles/bashrc
mv ~/.vimrc ~/.dotfiles/vimrc
```

 <!-- cmd:pause -->
 **3. Stew ...**
 -
```bash
stew link ~/.dotfiles
```

 <!-- cmd:pause -->
 **4. push**
 -
```bash
git remote add origin git@github.com:<user>/dotfiles.git
git push -u origin main
```

 <!-- cmd:end_slide -->
## Stew create symlinks

<!-- cmd:column_layout: [1, 1] -->
 <!-- cmd:column: 0 -->

```plaintext
~/.dotfiles
├── bashrc
├── vimrc
└── config
    └── nvim
        └── init.vim

```

 <!-- cmd:pause -->
 <!-- cmd:column: 1 -->
```plaintext
~/
├── .bashrc
├── .vimrc
└── .config
    └── nvim
        └── init.vim

```
 <!-- cmd:end_slide -->


 <!-- cmd:jump_to_middle -->
 **chezmoi**
 -
An efficient way to maintain consistency across multiple systems.
 <!-- cmd:end_slide -->

# chezmoi

 <!-- cmd:pause -->
 **1. Manage our dotfile **
 -
```bash
chezmoi init            ### Create dir ~/.local/share/chezmoi
chezmoi add ~/.bashrc   ### Copy the file to the dir
chezmoi edit ~/.bashrc  ### Edit the stored-dir version

chezmoi diff            ### Preview the changes
chezmoi apply           ### Auto deploy/merge back to our HOME
```

 <!-- cmd:pause -->
 **2. Push to github **
 -
```bash
cd ~/.local/share/chezmoi
git init
git remote add origin git@github.com:<user>/dotfiles.git
git add .
git commit -m "Initial commit"
git push -u origin main
```

 <!-- cmd:pause -->
 **3. Deploy to another env**
 -
```bash
chezmoi init git@github.com:<user>/dotfiles.git
chezmoi update
chezmoi apply
```

 <!-- cmd:end_slide -->
## Special features

 <!-- cmd:pause -->
- Encrypt sensitive info
- Template support multiple OS/env


 <!-- cmd:pause -->
 **Sensitive data**
 -
```bash
chezmoi add ~/.ssh/config
chezmoi encrypt ~/.ssh/config   ### The stored-dir file encrypted
chezmoi apply                   ### Auto-decrypt and apply to `HOME`
```


 <!-- cmd:pause -->
 **Multiple OS**
 -
```bash
# https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/#use-templates
$ cat ~/.local/share/chezmoi/dot_bashrc.tmpl

    {{ if eq .chezmoi.os "linux" }}
    export PATH="/usr/bin:$PATH"
    {{ else if eq .chezmoi.os "darwin" }}
    export PATH="/usr/local/bin:$PATH"
    {{ end }}

```

 <!-- cmd:end_slide -->
 <!-- cmd:jump_to_middle -->
 **git dotfiles**
 -
Using git manage our dotfiles directly.
 <!-- cmd:end_slide -->

# DIY by git

 <!-- cmd:pause -->
 **git dotfiles**
 -

 <!-- cmd:pause -->
 <!-- cmd:incremental_lists: true -->
- Q1. Don't want extra dir/file in our `$HOME`.
- Q2. Support manage our config from every where.
 <!-- cmd:incremental_lists: false -->

 <!-- cmd:end_slide -->
 <!-- cmd:jump_to_middle -->
 **Git**
 -
 <!-- cmd:end_slide -->
 <!-- cmd:incremental_lists: true -->
- What's inside a Git dir?
  + a repo: version/history/tags/branch/metadata
  + the working dir
- How to split repo from working-dir?
  + bare
  + worktree
  + Solve Q1: `Don't want extra dir/file in our $HOME`.
- ---
- How to execute a git command from `any where`?
  + The pre-requirement of a git command
    - path of the repo
    - path of the working dir
  + How we can offer them to `git`?
    1. From current dir, and search up the `.git`
      + what's `.git`? dir or file?
    2. From env variable
      + `$GIT_DIR` / `$GIT_WORK_TREE`
    3. From arguments
      + `--git-dir` / `--work-tree`
- Create a cmd for our dotfile
  + `config`, `conf`, `dot`
    - conf add a-file
    - conf commit -am "add a-file"
    - conf push --mirror origin
  + Solve Q2: `alias dot='/usr/bin/git --git-dir=$HOME/.dotfile/ --work-tree=$HOME'`

- Bug?
  + How to resolve untraced file?
    - `dot config --local status.showUntrackedFiles no`
  + How to encrypt sensitive info?
    - git-crypt
  + How to resolve multiple OS/env?
    - branch

 <!-- cmd:incremental_lists: false -->



 <!-- cmd:end_slide -->
 <!-- cmd:jump_to_middle -->
 **yadm**
 -
Using yadm (Yet Another Dotfiles Manager) is a simple and efficient way to manage your dotfiles.
 <!-- cmd:end_slide -->

# yadm

<!-- cmd:column_layout: [1, 1] -->
 <!-- cmd:column: 0 -->

 <!-- cmd:pause -->
 **1. Git `alias`**
 -
```bash
yadm init
```
 <!-- cmd:column: 1 -->

```bash +exec
tree ~/.local/share/yadm
```

 <!-- cmd:reset_layout -->

---

<!-- cmd:column_layout: [1, 1] -->
 <!-- cmd:column: 0 -->

 <!-- cmd:pause -->
 **Add files ...**
 -
```bash
yadm add ~/.bashrc   ### git add
yadm add ~/.vimrc    ### git add

yadm commit -m "message"   ### git commit
```

 <!-- cmd:column: 1 -->
 <!-- cmd:pause -->
 **Status**
 -
```bash
yadm status # Check Status
yadm pull # Pull Changes
yadm ls-files --others --exclude-standard  # List Untracked Files
yadm diff # Diff Changes
yadm ls-tree -r master --name-only # List All Managed Files
```

 <!-- cmd:reset_layout -->
---

<!-- cmd:column_layout: [1, 1] -->
 <!-- cmd:pause -->
 <!-- cmd:column: 0 -->
 **Push to Remote**
 -
```bash
### Push to github
yadm remote add origin https://github.com/huawenyu/_dotfile.git
yadm push -u origin main
yadm push --mirror origin
```

 <!-- cmd:pause -->
 <!-- cmd:column: 1 -->

 **Clone another env**
 -
```bash
### Clone from another env
yadm clone https://github.com/huawenyu/_dotfile.git
```


 <!-- cmd:end_slide -->
## Special features

 <!-- cmd:pause -->
- [bootstrap](https://yadm.io/docs/bootstrap#)
- [alternates](https://yadm.io/docs/alternates#)
- [Encrypt sensitive info](https://yadm.io/docs/encryption#)
- Template support multiple OS/env


```bash
    ### [Require] chmod a+x ~/.config/yadm/bootstrap
    ### Run ~/.config/yadm/bootstrap
    yadm install
```

<!-- cmd:column_layout: [1, 1] -->
 <!-- cmd:pause -->
 <!-- cmd:column: 0 -->
 **Config sensitive file pattern**
 -

 <!-- cmd:pause -->
```bash
# default: gpg: no valid OpenPGP data found.
yadm config yadm.cipher openssl
# alt use: only main may need install yadm and add files
yadm config local.class main

# Create pattern
$ cat ~/.config/yadm/encrypt
.ssh/*

# Added config/encoded-data
yadm add ~/.config/yadm/encrypt
yadm add ~/.local/share/yadm/archive
```

```bash
# Don't add the require encrypt-files, only need add the encrypted-archive, that's enough
# yadm add ~/.ssh/config

yadm encrypt  # Create an encrypted version file(~/.local/share/yadm/archive)
yadm decrypt  # Decrypted and apply the encrypted file
```


 <!-- cmd:pause -->
 **Multiple OS**
 -
```bash
$ ls
    ~/.bashrc##my-laptop        ### endwith <hostname>, <os>
    ~/.bashrc##linux

$ yadm alt      ### Auto link the appropriate file for the current env
```

 <!-- cmd:end_slide -->
 <!-- cmd:jump_to_middle -->
  **THANKS**
  -
---
 <!-- cmd:end_slide -->
<!-- vim: ft=markdown setlocal autoindent cindent et ts=4 sw=4 sts=4 -->


## Reference

[Best way to store in a bare git](https://www.atlassian.com/git/tutorials/dotfiles)  
[Git Bare Repository - A Better Way To Manage Dotfiles](https://www.youtube.com/watch?v=tBoLDpTWVOM)  
[Manage Your Secrets with git-crypt](https://dev.to/heroku/how-to-manage-your-secrets-with-git-crypt-56ih)  

