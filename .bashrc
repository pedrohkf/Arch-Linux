#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# Ativa a proteção de olhos de forma independente do terminal
alias gs-on='nohup hyprsunset -t 4000 > /dev/null 2>&1 &'

# Desativa
alias gs-off='killall hyprsunset'
eval "$(starship init bash)"

