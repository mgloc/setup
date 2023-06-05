# Arch Linux Bootstrap script
#
# Author: John Hammond
# Date:   October 1st, 2019
#
# This script is meant to help set up and install all the tools
# and configuration that I need to get Arch Linux up and running
# quickly and easily.

NEW_USER=$1

# Define some colors for quick use...
COLOR_RED=$(tput setaf 1)
COLOR_GREEN=$(tput setaf 2)
COLOR_YELLOW=$(tput setaf 3)
COLOR_BLUE=$(tput setaf 4)
COLOR_MAGENTA=$(tput setaf 5)
COLOR_CYAN=$(tput setaf 6)
COLOR_WHITE=$(tput setaf 7)
BOLD=$(tput bold)
COLOR_RESET=$(tput sgr0)

function echo_red(){
	echo "${COLOR_RED}${BOLD}$1${COLOR_RESET}"
}

function echo_green(){
	echo "${COLOR_GREEN}${BOLD}$1${COLOR_RESET}"
}

function echo_yellow(){
	echo "${COLOR_YELLOW}${BOLD}$1${COLOR_RESET}"
}

###############################################################


SUDO_DEPENDENCIES="sudo"
GIT_DEPENDENCIES="git"
TMUX_DEPENDENCIES="tmux"

DEPENDENCIES="\
 $SUDO_DEPENDENCIES \
 $GIT_DEPENDENCIES \
 $TMUX_DEPENDENCIES
"

##############################################################

function create_new_user(){
	sudo apt-get update && sudo apt-get install sudo -y
	id -u $NEW_USER > /dev/null

	if [ $? -eq 1 ]
	then
		echo_green "Creating new user $COLOR_BLUE$NEW_USER"

		mkdir /home/$NEW_USER
		useradd $NEW_USER
		echo_yellow "Please set the password for $COLOR_BLUE$NEW_USER:"
		passwd $NEW_USER
	else
		echo_green "New user already exists, using that account for everything"
	fi

	groupadd sudo
	usermod -aG sudo $NEW_USER
	sed -i 's/# %sudo/%sudo/g' /etc/sudoers
	echo "$NEW_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

	chown $NEW_USER:$NEW_USER /home/$NEW_USER
	chown -R $NEW_USER:$NEW_USER $(pwd)
	mv $(pwd) /home/$NEW_USER/archlinux
	cd /home/$NEW_USER/archlinux
}

function cleanup(){
	sed -i "s/$NEW_USER ALL=(ALL) NOPASSWD: ALL//g" /etc/sudoers
}

###############################################################


function configure_bashrc(){
	echo_green "Getting default .bashrc"

	sudo -u $NEW_USER bash -c 'cp bashrc ~/.bashrc'
	sudo -u $NEW_USER bash -c '. ~/.bashrc'
	cp bashrc /etc/bash.bashrc
}

function configure_tmux(){
	sudo -u $NEW_USER bash -c "echo 'source \"\$HOME/.bashrc\"' > ~/.bash_profile"
	sudo -u $NEW_USER bash -c 'cp tmux.conf ~/.tmux.conf'
}


function configure_git(){
	sudo -u $NEW_USER bash -c 'git config --global core.editor "vim"'
	sudo -u $NEW_USER bash -c 'git config --global user.email "johnhammond010@gmail.com"'
	sudo -u $NEW_USER bash -c 'git config --global user.name "John Hammond"'
}

##############################################################

function prepare_opt(){
	chown $NEW_USER:$NEW_USER /opt
}

###############################################################

function set_locale(){
	echo_green "Configuration de la langue"
	sed -i 's/#fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/g' /etc/locale.gen
	echo "LANG=fr_FR.UTF-8" > /etc/locale.conf
	locale-gen
}

function set_hostname(){
	echo_green "Setting hostname"

	echo glox > /etc/hostname
	cat <<EOF >/etc/hosts
127.0.0.1 localhost
::1	      localhost
127.0.1.1 glox.localdomain glox
EOF

}

function pre_install(){
	set_locale
	set_hostname
}


function install_niceties(){
	apt-get update
	apt-get install -y $DEPENDENCIES
}

if [ "$1" == "" ]
then
	echo_red "You must supply a username to use."
	echo "usage: $0 <new_username>"
	exit
fi

pre_install
create_new_user
install_niceties
configure_bashrc
configure_tmux
configure_git
prepare_opt

cleanup
