#!/bin/bash
#set -o nounset     # Treat unset variables as an error

declare -r DIR=$(cd "$(dirname "$0")" && pwd)
source $DIR/conf/lib_common.sh
source $DIR/conf/lib_bsfl.sh
source $DIR/conf/lib_log4sh.sh

# default message level: ERROR, INFO
#logger_setLevel INFO
logger_info "Starting ..."

# header {{{1
NOTE="update dotfile config"
_DEBUG="off"
verbose=0
dryrun="off"

action="none"
commitmsg="auto update"

ignore_files=( "$(basename $0)" '.' '..' \
    '.git' 'README.md' \
    'plugin' \
    '.zsh_history' \
    '.gvimrc' \
)

# functions {{{1
# help {{{2
Help ()
{
cat << EOF
Usage: ${0##*/} [-hvdn] [-a <action>] [-m <message>]

Options:
  -h  help
  -v  verbose
  -d  debug
  -n  dry-run
  -*a [push|pull]
  -*m "commit message"

Samples:
  ${0##*/} -na pull
  ${0##*/} -na push -m "auto update"

EOF
exit ${1:-0}
}

# basic function {{{2
GetOpts ()
{
    if [ $# -eq 0 ]; then
        Help >&2
    fi

    # Reset is necessary if getopts was used previously in the script.
    OPTIND=1
    local opt
    while getopts "hvdna:m:" opt; do
    case "$opt" in
    h)
        Help
        ;;
    v)  verbose=$OPTARG
        ;;
    d)  _DEBUG="on"
        ;;
    n)  dryrun="on"
        ;;
    a)  action=$OPTARG
        ;;
    m)  commitmsg=$OPTARG
        ;;
    \?)
        Help >&2
        ;;
    *)
        Help >&2
        ;;
    esac
    done
    # Shift off the options and optional
    shift "$((OPTIND-1))"

    # Check options
    if [ -z "${commitmsg}" ] || [ -z "${action}" ] \
        || [ "${action}" != "push" -a  "${action}" != "pull" ] ; then
        Help
    fi
}

DEBUG() { [ "$_DEBUG" == "on" ] && $@; }
Echo () { echo "# $(basename $0): $*"; }
Die()   { echo $1; exit 1; }

Run ()
{
    if [ "$dryrun" == "off" ]; then
        eval "$@"
    else
        echo "Will $*"
        return 0
    fi
}

# user function {{{2

# acording action to change copy direction
copy_file()
{
	local flag=$1
	local filename=$2

	if [ $action == 'pull' ]; then
		execute "cp $flag $filename ~/."
	elif [ $action == 'push' ]; then
		execute "cp $flag ~/$filename ."
	else
		echo "Action [$action] is not valid"
		exit 1
	fi
}

# Main: user script {{{1
Main ()
{
    DEBUG printf "###$(basename $0):${BASH_LINENO[0]}: ${FUNCNAME[0]} {{{${#FUNCNAME[@]}\n"
    printf "$NOTE: dry=$dryrun v=$verbose action=$action dir=$DIR\n\n"

    cd -P $DIR && cd .. && phy_dotfiles_dir=$(pwd)
    echo "Current dir: $old_dir"
    echo "Change to $(pwd)"

    if [ $action == 'pull' ]; then
        Run "git pull --all" || Die "Git pull failed!"
        home_bak=$HOME/dotfiles_bak
        Run "mkdir -p $home_bak" || Die "Make $home_bak failed!"

        for file in .* *
        do
            array_contains ignore_files "$file"  && echo "Skipping $file" && continue

            home_f=$HOME/$file
            # the softlink existed, but real file not exist, rm the softlink
            if [[ -L "$home_f" ]]; then
                if [[ -f "$home_f" || -d "$home_f" ]]; then
                    true
                else
                    Run "rm -fr $home_f 2> /dev/null"
                fi
            else
                true
            fi

            if [[ -f "$home_f" || -d "$home_f" ]]; then
                if [[ -L "$home_f" ]]; then
                    true
                else
                    Run "mv $home_f $home_bak/$file"
                fi

                Run "rm -fr $home_f 2> /dev/null"
            fi

            Run "ln -sfn $phy_dotfiles_dir/$file $home_f" || Die "Create softlink $home_f failed!"

        done

        # test file exists cannot use '~' to replace $HOME, and should have double-quote
        #Run "awk -f $phy_dotfiles_dir/script/awk/zsh_hist.awk $HOME/.zsh_history $phy_dotfiles_dir/.zsh_history > $HOME/.zsh_history"

        gvimrc="$HOME/.gvimrc"
        Run "rm -f $gvimrc"

        if [ ! -f "$gvimrc" ] && [ ! -L "$gvimrc" ]; then
            Run "ln -sfn ~/.vimrc $gvimrc"
        fi

        if [ ! -f "~/.vim/coc-settings.json" ]; then
            Run "mkdir -p ~/.vim/"
            Run "ln -sfn $phy_dotfiles_dir/coc-settings.json ~/.vim/coc-settings.json"
        fi

        if [ ! -f "~/.w3m/config" ]; then
            Run "mv -fr ~/.w3m ~/w3m.old"
            Run "ln -sfn $phy_dotfiles_dir/w3m ~/.w3m"
        fi

        # The terminal emulor kitty's config
        if [ ! -d "~/.config/kitty" ]; then
            Run "ln -sfn $phy_dotfiles_dir/kitty ~/.config/kitty"
        fi

        # The terminal emulor kitty's config, but looks the kitty is not clearly when rendering the font
        if [ ! -d "~/.config/gitconf" ]; then
            Run "ln -sfn $phy_dotfiles_dir/gitconf ~/.config/gitconf"
        fi

        if [ ! -d "~/.grc" ]; then
            Run "ln -sfn $phy_dotfiles_dir/grc ~/.grc"
        fi

        ## neovim
        ##Run "ln -sfn ~/.vim ~/.config/nvim"
        ##Run "ln -sfn ~/.vimrc ~/.config/nvim/init.vim"
    elif [ $action == 'push' ]; then
        diff_num=$(git diff | wc -l)
        file_num=$(git status --short | grep -v '^?' | wc -l)
        if [ $diff_num -gt 0 ] || [ $file_num -gt 0 ]; then
            Run "git commit -am \"$commitmsg\" &> /dev/null" \
                && Run "git push origin master &> /dev/null" \
                && msg_success "$phy_dotfiles_dir push $diff_num lines patch." \
                || Die "Git commit or push failed: $phy_dotfiles_dir"
        else
            msg_passed "$phy_dotfiles_dir no changed!"
        fi
    fi

    echo "Backto current dir: $old_dir"
    DEBUG printf "###$(basename $0):${BASH_LINENO[0]}: ${FUNCNAME[0]} {{{${#FUNCNAME[@]}\n"
}

# footer {{{1
old_dir=$(pwd)
DEBUG printf "###$(basename $0):${BASH_LINENO[0]}: ${FUNCNAME[0]} {{{${#FUNCNAME[@]}\n"
GetOpts "$@"
DEBUG set -vx
Main "$@"
DEBUG set +vx
DEBUG printf "###$(basename $0):${BASH_LINENO[0]}: ${FUNCNAME[0]}{{{${#FUNCNAME[@]}\n"
cd $old_dir
# End of file
