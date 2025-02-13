# Setup:
#
# $ sudo apt install -y zsh
# $ sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# $ git clone https://github.com/huawenyu/zsh-local.git     ~/.oh-my-zsh/custom/plugins/zsh-local
# $ git clone https://github.com/zsh-users/zsh-completions  ~/.oh-my-zsh/custom/plugins/zsh-completions
# $ git clone https://github.com/jeffreytse/zsh-vi-mode $ZSH_CUSTOM/plugins/zsh-vi-mode
#
######################################################################################################
# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="robbyrussell"
#ZSH_THEME="daveverwer"
#ZSH_THEME="candy-kingdom"
#
#ZSH_THEME="mrtazz"
#murilasso
#ZSH_THEME="mrtazz"
#steeef
#gnzh
#dst

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
DISABLE_AUTO_UPDATE="true"
DISABLE_UPDATE_PROMPT=true

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.

# Zsh: debug-trap
#   https://jichu4n.com/posts/debug-trap-and-prompt_command-in-bash/
# Enable plugin:
#   git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions
#   git clone https://github.com/huawenyu/zsh-local.git    ~/.oh-my-zsh/custom/plugins/zsh-local
#
# Disable plugin:
#   git clone https://github.com/zdharma/history-search-multi-word ~/.oh-my-zsh/custom/plugins/history-search-multi-word
#   git clone https://github.com/tymm/zsh-directory-history ~/.oh-my-zsh/custom/plugins/zsh-directory-history
#   git clone git://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
#   git clone https://github.com/urbainvaes/fzf-marks.git ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/fzf-marks
# Usage:
#    $ mark <mark>, to register a new mark to the current directory;
#    $ fzm [<optional-initial-query>], to jump to or delete a mark using fzf.
#      ctrl-g, to fzm.
#      ctrl-y, to jump to a match;
#      ctrl-t, to toggle a match for deletion;
#      ctrl-d, to delete selected matches.
#plugins=(lighthouse history-search-multi-word zsh-directory-history history-substring-search zsh-completions zsh-autosuggestions)
#plugins=(history-substring-search zsh-completions zsh-local fzf-marks)
plugins=(history-substring-search zsh-completions zsh-local)
autoload -U compinit && compinit

# Folder permission "Insecure completion-dependent directories detected" #6835
# https://github.com/ohmyzsh/ohmyzsh/issues/6835
ZSH_DISABLE_COMPFIX=true

source $ZSH/oh-my-zsh.sh

# Change prompt: 'user@hostname ~ '
#PROMPT="%F{yellow}%n%f"  # Magenta user name
#PROMPT+="@"
#PROMPT+="%F{green}${${(%):-%m}#zoltan-}%f" # Blue host name, minus zoltan
#PROMPT+=" "
#PROMPT+="%F{yellow}%1~ %f" # Yellow working directory
##PROMPT+=" %# "

# speed git dir prompt
function git_prompt_info() {
  ref=$(git symbolic-ref HEAD 2> /dev/null) || return
  echo "$ZSH_THEME_GIT_PROMPT_PREFIX${ref#refs/heads/}${ZSH_THEME_GIT_PROMPT_CLEAN}${ZSH_THEME_GIT_PROMPT_SUFFIX}"
}

# Customize to your needs...
#

# Our local dir: data, tools, home
#if [ ! -f "/tmp/zsh_init_flag" ]; then
#  # remap caps to ESC
#  xmodmap -e 'clear Lock' -e 'keycode 0x42 = Escape'
#  echo "have init" > "/tmp/zsh_init_flag"
#fi

#alias emacs='emacs -nw'

# Avoid mosh flash when <c-l> tmux-pane jump
# bindkey -r "^L"
# bindkey "^L" clear-screen


# Use these lines to enable search by globs, e.g. gcc*foo.c
#

#[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

if command -v atuin 2>&1 >/dev/null
then
    eval "$(atuin init zsh --disable-up-arrow)"
fi

if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then . "$HOME/.nix-profile/etc/profile.d/nix.sh"; fi # added by Nix installer
export LFTP_ATCMD="lftp --norc -c 'open -u ftpuser,ftpuser 172.16.80.139; set ftp:ssl-allow off; set xfer:clobber on; set ssl:verify-certificate no;'"


if [ -e "$HOME/.atuin/bin/env" ]; then . "$HOME/.atuin/bin/env"; fi # Add atuin addons for command-history autocomplete

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Don't do this, will make shell mess: Removes duplicate path
#export PATH=$(echo $PATH | tr ':' '\n' | sort -u | tr '\n' ':')

