# ~/.bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Auto-start recovery init script on first login
if [[ -z "$RECOVERY_INIT_RAN" ]]; then
    export RECOVERY_INIT_RAN=1
    exec ~/init-recovery.sh
fi

alias ls='ls --color=auto'
alias grep='grep --colour=auto'

PS1='[\u@\h \W]\$ '
