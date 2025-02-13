if [[ -f "$HOME/.cargo/env" ]]; then
	. "$HOME/.cargo/env"
fi

if [[ -f "$HOME/sub-me/bin/me" ]]; then
	eval "$($HOME/sub-me/bin/me init -)"
fi

#eval "$(/home/hyu/sub-star/bin/star init -)"
#export SCRIPT_DIR="/home/hyu/sub-demo/bin"
#export _MC_ROOT="/home/hyu/sub-demo/bin"
#eval "$(/home/hyu/sub-demo/bin/demo init -)"

if [ -e /home/hyu/.nix-profile/etc/profile.d/nix.sh ]; then . /home/hyu/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
