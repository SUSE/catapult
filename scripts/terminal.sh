#!/bin/bash

. scripts/include/common.sh
. .envrc

set -euo pipefail

kubectl create namespace catapult || true
kubectl create -f ../kube/task.yaml || true

bash ../scripts/wait_ns.sh catapult

kubectl cp ../build$CLUSTER_NAME catapult/task:/catapult/
kubectl exec -ti -n catapult task -- /bin/bash -c "CLUSTER_NAME=$CLUSTER_NAME make buildir login" || true
kubectl exec -ti -n catapult task -- /bin/bash -c "chsh root -s /bin/zsh" || true

echo "source /catapult/build$CLUSTER_NAME/.envrc" > .zshrc
# Inject a sane zshrc!
cat <<'EOF' >> .zshrc
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export GOPATH=$HOME/go
export HISTFILE=$HOME/.zsh_history # Where it gets saved
setopt append_history # Don't overwrite, append!
export GIT_DUET_ROTATE_AUTHOR=1

if [[ ! -d ~/.zplug ]]; then
    git clone https://github.com/zplug/zplug ~/.zplug
    source ~/.zplug/init.zsh && zplug update
fi

source ~/.zplug/init.zsh

zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-autosuggestions"

zplug "djui/alias-tips"

# fuzzy filtering
zplug "junegunn/fzf", as:command, hook-build:"./install --bin", use:"bin/{fzf-tmux,fzf}"

export ZSH_TMUX_AUTOSTART=true
export ZSH_TMUX_AUTOSTART_ONCE=true
export ZSH_TMUX_AUTOCONNECT=true

export FZF_TMUX=1

zplug "plugins/git",   from:oh-my-zsh
zplug "plugins/tmux",   from:oh-my-zsh

zplug "mafredri/zsh-async", defer:0
zplug "sindresorhus/pure", use:pure.zsh, as:theme
zplug "zdharma/fast-syntax-highlighting", defer:2
zplug "zsh-users/zsh-history-substring-search", defer:3
zplug "zsh-users/zsh-syntax-highlighting"
zplug "junegunn/fzf", use:"shell/*.zsh"

if ! zplug check --verbose; then
	zplug install
fi

zplug load

export HISTSIZE=999999999
setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
setopt HIST_BEEP                 # Beep when accessing nonexistent history.
export SAVEHIST=$HISTSIZE

echo
echo "@@@@@@@@@@@@@@"
echo "You can already use 'cf' and 'kubectl'"
echo "Note: After you are done, you need to remove the terminal pod explictly with: kubectl delete pod -n catapult task"
echo "@@@@@@@@@@@@@@"
echo

EOF

kubectl cp .zshrc catapult/task:/root/
rm -rf .zshrc

echo
echo "@@@@@@@@@@@@@@"
echo "Executing into the persistent pod"
echo "@@@@@@@@@@@@@@"
echo

exec kubectl exec -ti task -n catapult -- /bin/zsh