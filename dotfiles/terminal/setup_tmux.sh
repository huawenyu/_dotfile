#!/usr/bin/env bash

set -e

ROOT_DIR=${HOME}/tmp2
mkdir -p ${ROOT_DIR}

# Clean up
Thetmux="tmux-3.3a.tar.gz"
rm -rf libevent-2.1.12-stable.tar.gz
rm -rf ncurses-6.2.tar.gz
rm -rf ${Thetmux}


wget "https://github.com/tmux/tmux/releases/download/3.3a/${Thetmux}"
wget "https://invisible-mirror.net/archives/ncurses/ncurses-6.2.tar.gz"
wget "https://github.com/libevent/libevent/releases/download/release-2.1.12-stable/libevent-2.1.12-stable.tar.gz"
cp -r "./libevent-2.1.12-stable.tar.gz" "./ncurses-6.2.tar.gz" "./${Thetmux}" ${ROOT_DIR}

cd ${ROOT_DIR}

tar xvf "libevent-2.1.12-stable.tar.gz"
tar xvf "ncurses-6.2.tar.gz"
tar xvf "${Thetmux}"

# Install libevent
cd libevent-2.1.12-stable
./autogen.sh
./configure --prefix=${ROOT_DIR}/.local
make
make install
cd ..

# Install ncurses
cd ncurses-6.2
./configure --prefix=${ROOT_DIR}/.local
make
make install
cd ..

# Install tmux
cd /tmux-3.3a
./configure --prefix=${ROOT_DIR}/.local \
    CFLAGS="-I${ROOT_DIR}/.local/include -I${ROOT_DIR}/.local/include/ncurses" \
    LDFLAGS="-L${ROOT_DIR}/.local/include -L${ROOT_DIR}/.local/include/ncurses -L${ROOT_DIR}/.local/lib"
make
make install
cd ..

# Clean up
rm -rf libevent-2.1.12-stable*
rm -rf ncurses-6.2*
rm -rf tmux-*

echo "[SUCCESS] ${ROOT_DIR}/.local/bin/tmux is now available"
