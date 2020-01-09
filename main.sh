#!/usr/bin/env bash

# Print the commands being run so that we can see the command that triggers
# an error.  It is also useful for following along as the install occurs.
set -o xtrace

# Make sure custom grep options don't get in the way
unset GREP_OPTIONS
# Previously we used the C locale for this, every system has it, and
# it gives us a stable sort order. It does however mean that we
# effectively drop unicode support.... boo!  :(
#
# With python3 being more unicode aware by default, that's not the
# right option. While there is a C.utf8 locale, some distros are
# shipping it as C.UTF8 for extra confusingness. And it's support
# isn't super clear across distros. This is made more challenging when
# trying to support both out of the box distros, and the gate which
# uses diskimage builder to build disk images in a different way than
# the distros do.
#
# So... en_US.utf8 it is. That's existed for a very long time. It is a
# compromise position, but it is the least worse idea at the time of
# this comment.
#
# We also have to unset other variables that might impact LC_ALL
# taking effect.
unset LANG
unset LANGUAGE
LC_ALL=en_US.utf8
export LC_ALL

# Clear all OpenStack related envvars
unset `env | grep -E '^OS_' | cut -d = -f 1`

# Make sure umask is sane
umask 022

# Not all distros have sbin in PATH for regular users.
PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin

# Keep track of the DevStack directory
TOP_DIR=$(cd $(dirname "$0") && pwd)
source $TOP_DIR/functions-common

function install_homebrew() {
  url = "https://raw.githubusercontent.com/Homebrew/install/master/install"
  /usr/bin/ruby -e "$(curl -fsSL $url)"
}

function install_brew_softwares() {
  set_http_https_proxy

  if is_brew_installed
    then
      blue 'homebrew is already installed'
    else
      green "start install homebrew"
      install_homebrew
  fi

  local installed=1
  is_brew_software_installed monitorcontrol
  installed=$?
  if [ $installed == 0 ]
    then
      brew cask install monitorcontrol
    else
      software_is_installed monitorcontrol
  fi

  is_brew_software_installed zsh
  installed=$?
  if [ $installed == 0 ]
    then
      brew install zsh
    else
      software_is_installed zsh
  fi

  is_brew_software_installed tree
  installed=$?
  if [ $installed == 0 ]
    then
      brew install tree
    else
      software_is_installed tree
  fi

  is_brew_software_installed powerlevel9k
  installed=$?
  if [ $installed == 0 ]
    then
      brew tap sambadevi/powerlevel9k
      brew install powerlevel9k
    else
      software_is_installed powerlevel9k
  fi

  is_brew_software_installed git
  installed=$?
  if [ $installed == 0 ]
    then
      brew 
    else
      software_is_installed git
  fi

  is_brew_software_installed python
  installed=$?
  if [ $installed == 0 ]
    then
      brew install python3
    else
      software_is_installed python3
  fi

  is_brew_software_installed python@2
  installed=$?
  if [ $installed == 0 ]
    then
      brew install python2
    else
      software_is_installed python2
  fi

  is_brew_software_installed font-hack-nerd-font
  installed=$?
  if [ $installed == 0 ]; then
    brew tap homebrew/cask-fonts
    brew cask install font-hack-nerd-font
  else
    software_is_installed font-hack-nerd-font
  fi

  is_brew_software_installed telnet
  installed=$?
  if [ $installed == 0 ]; then
    brew install telnet
  else
    software_is_installed telnet
  fi

  is_brew_software_installed pkg-config
  installed=$?
  if [ $installed == 0 ]; then
    brew install pkg-config
  else
    software_is_installed pkg-config
  fi

  is_brew_software_installed libvirt
  install=$?
  if [ $installed == 0 ]; then
    brew install libvirt
  else
    software_is_installed libvirt
  fi

  unset_http_https_proxy
}

function setup_code_directory() {
  dir_or_file_exists ~/code
  folder_exists=$?
  if [ $folder_exists == 1 ]
    then
      file_or_dir_already_exists ~/code
    else
      mkdir ~/code
  fi

  if [ $folder_exists == 1 ]
    then
      file_or_dir_already_exists ~/code/Work
    else
      mkdir ~/code/Work
  fi

  if [ $folder_exists == 1 ]
    then
      file_or_dir_already_exists ~/code/OpenStack
    else
      mkdir ~/code/OpenStack
  fi

  if [ $folder_exists == 1 ]
    then
      file_or_dir_already_exists ~/code/Interest
    else
      mkdir ~/code/Interest
  fi
}

function git_clone_company_repo_to_work() {
  git clone git@gitlab.sh.99cloud.net:openstack/horizon.git ~/code/Work/horizon
  git clone git@gitlab.sh.99cloud.net:openstack/cloudkitty.git ~/code/Work/cloudkitty
  git clone git@gitlab.sh.99cloud.net:openstack/ceilometer.git ~/code/Work/ceilometer
  git clone git@gitlab.sh.99cloud.net:openstack/nova.git ~/code/Work/nova
  git clone git@gitlab.sh.99cloud.net:openstack/neutron.git ~/code/Work/neutron
  git clone git@gitlab.sh.99cloud.net:openstack/kolla-ansible.git ~/code/Work/kolla-ansible

}

function git_clone_my_repos_to_interets() {
  # TODO(xiaojueguan) add a python script to here.
  setup_virtualenv

}

function config_git() {

cat << EOF > ~/.gitignore_global
.vscode/
EOF

  cat << EOF > ~/.gitconfig
; core variables
[core]
        ; Proxy setting
        filemode = false
        excludesfile = ~/.gitignore_global
[http]
      sslVerify
[http "https://weak.example.com"]
      sslVerify
      cookieFile = /tmp/cookie.txt
; It seems includeIf only works in the rep which under the directory
[includeIf "gitdir/i:~/code/Work/"]
        path = ~/.gitconfig-work.inc
[includeIf "gitdir/i:~/code/OpenStack/"]
        path = ~/.gitconfig-openstack.inc
[includeIf "gitdir/i:~/code/Interest/"]
       path = ~/.gitconfig-interest.inc
EOF

cat << EOF > ~/.gitconfig-work.inc
[user]
    name = guanxiaojue
    email = guan.xiaojue@99cloud.net
[gitreview]
    username = guanxiaojue
EOF

cat << EOF > ~/.gitconfig-openstack.inc
[user]
    name = xiaojueguan
    email = xiaojueguan@gmail.com
EOF

cat << EOF > ~/.gitconfig-interest.inc
[user]
    name = xiaojueguan
    email = xiaojueguan@gmail.com
EOF

}

function main() {
  # install_brew_softwares
  # setup_zshrc
  setup_pip_rep
  # setup_code_directory
  # git_clone_company_repo_to_work
  # git_clone_my_repos_to_interets
  # setup_virtualenvwrappers
  # create_virtualenvwrappers
  # config_git
  # setup_config_for_vscode
}

main
