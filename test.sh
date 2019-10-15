#!/bin/bash
source functions-common
# if is_brew_software_installed zsh; then
#     software_is_installed zsh
#   else
#     echo 'zsh is not installed'
# fi


# is_brew_software_installed "zsh"
# installed=$?
# green "software is installed with name zsh"
# echo $installed

# is_brew_software_installed "monitorcontrol"
# installed=$?
# green "software is installed with name monitorcontrol"
# echo $installed

# is_brew_software_installed "tree"
# installed=$?
# green "software is installed with name tree"
# echo $installed

# is_brew_software_installed powerlevel9k
# installed=$?
# green "software is installed with name powerlevel9k"
# echo $installed

# if is_brew_software_installed zsh
#   then
#     echo 'zsh installed'
# fi
# if is_brew_software_installed hihi
#   then
#     echo 'hihi'
# fi

# if is_brew_software_installed 'op' -eq 1
#   then
#     green 'zsh'
#   else
#     red 'zsh'
# fi

dir_or_file_exists ~/code
file_exits=$?
echo $file_exits
if [ $file_exits == 1 ]
  then
    green '~/code'
  else
    red '~/code'
fi

dir_or_file_exists ~/hih
file_exits=$?
echo $file_exits
if [ $file_exits == 1 ]
  then
    green '~/hih'
  else
    red '~/hih'
fi

# if is_brew_installed
#   then
#     green 'brew'

# fi

