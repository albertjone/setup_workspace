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

function setup_zshrc() {
  # bakup your zsh configuration
  if [ -f ~/.zshrc ]
    then
      mv ~/.zshrc ~/.zshrc.bak$(date "+%Y-%m-%d%H:%M:%S")
  fi

  cat << EOF > ~/.zshrc
source /usr/local/opt/powerlevel9k/powerlevel9k.zsh-theme

POWERLEVEL9K_CUSTOM_WIFI_SIGNAL="zsh_wifi_signal"
POWERLEVEL9K_CUSTOM_WIFI_SIGNAL_BACKGROUND="white"
POWERLEVEL9K_CUSTOM_WIFI_SIGNAL_FOREGROUND="black"

zsh_wifi_signal(){
        local output=\$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport -I)
        local airport=\$(echo \$output | grep 'AirPort' | awk -F': ' '{print \$2}')

        if [ "\$airport" = "Off" ]; then
                local color='%F{black}'
                echo -n "%{\$color%}Wifi Off"
        else
                local ssid=\$(echo \$output | grep ' SSID' | awk -F': ' '{print \$2}')
                local speed=\$(echo \$output | grep 'lastTxRate' | awk -F': ' '{print \$2}')
                local color='%F{black}'

                [[ \$speed -gt 100 ]] && color='%F{black}'
                [[ \$speed -lt 50 ]] && color='%F{red}'

                echo -n "%{\$color%}\$speed Mbps \uf1eb%{%f%}" # removed char not in my PowerLine font
        fi
}

POWERLEVEL9K_CONTEXT_TEMPLATE='%n'
POWERLEVEL9K_CONTEXT_DEFAULT_FOREGROUND='white'
POWERLEVEL9K_BATTERY_CHARGING='yellow'
POWERLEVEL9K_BATTERY_CHARGED='green'
POWERLEVEL9K_BATTERY_DISCONNECTED='$DEFAULT_COLOR'
POWERLEVEL9K_BATTERY_LOW_THRESHOLD='10'
POWERLEVEL9K_BATTERY_LOW_COLOR='red'
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=''
POWERLEVEL9K_BATTERY_ICON='\uf1e6 '
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%F{014}\u2570%F{cyan}\uF460%F{073}\uF460%F{109}\uF460%f "
POWERLEVEL9K_VCS_MODIFIED_BACKGROUND='yellow'
POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND='yellow'
POWERLEVEL9K_VCS_UNTRACKED_ICON='?'

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon context battery dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status time dir_writable ip custom_wifi_signal ram load background_jobs)

POWERLEVEL9K_SHORTEN_DIR_LENGTH=1

POWERLEVEL9K_TIME_FORMAT="%D{\uf017 %H:%M \uf073 %d/%m/%y}"
POWERLEVEL9K_TIME_BACKGROUND='white'
POWERLEVEL9K_RAM_BACKGROUND='yellow'
POWERLEVEL9K_LOAD_CRITICAL_BACKGROUND="white"
POWERLEVEL9K_LOAD_WARNING_BACKGROUND="white"
POWERLEVEL9K_LOAD_NORMAL_BACKGROUND="white"
POWERLEVEL9K_LOAD_CRITICAL_FOREGROUND="red"
POWERLEVEL9K_LOAD_WARNING_FOREGROUND="yellow"
POWERLEVEL9K_LOAD_NORMAL_FOREGROUND="black"
POWERLEVEL9K_LOAD_CRITICAL_VISUAL_IDENTIFIER_COLOR="red"
POWERLEVEL9K_LOAD_WARNING_VISUAL_IDENTIFIER_COLOR="yellow"
POWERLEVEL9K_LOAD_NORMAL_VISUAL_IDENTIFIER_COLOR="green"
POWERLEVEL9K_HOME_ICON=''
POWERLEVEL9K_HOME_SUB_ICON=''
POWERLEVEL9K_FOLDER_ICON=''
POWERLEVEL9K_STATUS_VERBOSE=true
POWERLEVEL9K_STATUS_CROSS=true

# cause the python installed by homebrew will be placed to /usr/local/bin
# Todo(xiaojueguan) this line will fail in deploy
export PATH="/usr/local/bin:/usr/local/sbin:${PATH}"

alias swork="cd ~/code/Work"
alias sint="cd ~/code/Interest"
alias srep="cd ~/code/Openstack"
alias sproxy="export http_proxy=http://127.0.0.1:1087;export https_proxy=http://127.0.0.1:1087;"
alias dproxy="unset http_proxy;unset https_proxy"
alias stack="ssh root@192.168.199.126"

EOF
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
  install_brew_softwares
  setup_zshrc
  setup_pip_rep
  setup_code_directory
  git_clone_company_repo_to_work
  git_clone_my_repos_to_interets
  setup_virtualenvwrappers
  create_virtualenvwrappers
  config_git
  setup_config_for_vscode
}

main


