---
  Name: Dotfiles manager by yadm
  File: ~/README.md
  Topic:
    - yadm
    - myssh -t work "tmux new -As default"  ### autossh
---

# dotfiles

linux config files: zsh, ssh, tmux, vim, script, ...
- dotfile-manager: yadm
- editor: nvim
- tmux: multiple shell with share support
- [sub](https://github.com/qrush/sub): a delicious way to organize programs/scripts/tools
- vimplug: nvim/vim plugin manager, used to update this `dotfiles`
- xclip: clipboard tool
- terminal ppt: presenterm -x

# QuickStart

## Install

```bash
sudo apt install yadm

    <or> Download from script directly
    sudo curl -fLo /usr/local/bin/yadm https://github.com/TheLocehiliosan/yadm/raw/master/yadm
    sudo chmod a+x /usr/local/bin/yadm
```

## [New env deploy] Sync/pull

```bash
yadm clone https://github.com/huawenyu/_dotfile.git
yadm checkout --force
yadm decrypt  # Decrypted and apply the encrypted file
```

## ['main' env maitain] Update/push

### Status

```bash
yadm status # Check Status
yadm pull # Pull Changes
yadm ls-files --others --exclude-standard  # List Untracked Files
yadm diff # Diff Changes
yadm ls-tree -r master --name-only # List All Managed Files
```

### Add files

```bash
yadm add ~/.bashrc   ### git add
yadm add ~/.vimrc    ### git add

yadm commit -m "message"   ### git commit
```

### Push to Remote

```bash
### Push to github
yadm remote add origin https://github.com/huawenyu/_dotfile.git
yadm push -u origin main
yadm push --mirror origin
```

# Advance topic

## Create a new dotfile

1. Git `alias`

```bash
yadm init
```

```bash +exec
tree ~/.local/share/yadm
```

2. Reference to `Update/push dotfile`

## Special features

- [bootstrap](https://yadm.io/docs/bootstrap#)
- [alternates](https://yadm.io/docs/alternates#)
- [Encrypt sensitive info](https://yadm.io/docs/encryption#)
- Template support multiple OS/env


```bash
    ### [Require] chmod a+x ~/.config/yadm/bootstrap
    ### Run ~/.config/yadm/bootstrap
    yadm install
```

## Config sensitive file pattern**


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


## Support multiple OS

```bash
$ ls
    ~/.bashrc##my-laptop        ### endwith <hostname>, <os>
    ~/.bashrc##linux

$ yadm config local.class main
$ yadm alt ~/.bashrc --os Linux --class main

$ yadm alt      ### Auto link the appropriate file for the current env
```

