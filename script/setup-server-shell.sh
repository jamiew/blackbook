#!/bin/bash
#
# Push jamie's shell config to a server, tinted so you can tell at a glance that
# you are not on the laptop. Run this from the laptop, not the server.
#
#   ./script/setup-server-shell.sh rails@beta.000000book.com
#   ./script/setup-server-shell.sh rails@beta.000000book.com blackbook-beta red
#
# Copies only the portable files. Skips .projects (laptop paths), .bash_profile
# and .zshrc (homebrew, nodenv, mac completions). The few brew lines inside
# .profile and .bash_aliases no-op on Linux.
#
set -euo pipefail

TARGET="${1:?usage: setup-server-shell.sh user@host [label] [color]}"
HOST_LABEL="${2:-${TARGET#*@}}"
PROMPT_COLOR="${3:-red}"

case "$PROMPT_COLOR" in
  red)     TMUX_ACCENT=160 ;;
  yellow)  TMUX_ACCENT=178 ;;
  green)   TMUX_ACCENT=64  ;;
  blue)    TMUX_ACCENT=32  ;;
  magenta) TMUX_ACCENT=127 ;;
  *) echo "color must be red/yellow/green/blue/magenta" >&2; exit 1 ;;
esac

echo "Pushing shell config to $TARGET"
echo "  label: $HOST_LABEL"
echo "  color: $PROMPT_COLOR (tmux accent $TMUX_ACCENT)"

for f in .tmux.conf .profile .bash_aliases .bash_ps1 .inputrc; do
  [ -f "$HOME/$f" ] || { echo "  skip $f (not on this machine)"; continue; }
  scp -q "$HOME/$f" "$TARGET:$f"
  echo "  sent $f"
done

ssh "$TARGET" "HOST_LABEL='$HOST_LABEL' PROMPT_COLOR='$PROMPT_COLOR' TMUX_ACCENT='$TMUX_ACCENT' bash -s" <<'REMOTE'
set -euo pipefail

# .tmux.conf already ends with:
#   if-shell "[ -f ~/.tmux.conf.local ]" 'source ~/.tmux.conf.local'
# so this overrides the laptop's coral accent without editing the shared file.
cat > ~/.tmux.conf.local <<TMUX
# Server overrides. Sourced from the end of .tmux.conf.
# Accent is $PROMPT_COLOR here so a server pane never looks like a laptop pane.
set -g status-left-length 40
set -g status-left '#[fg=colour233,bg=colour$TMUX_ACCENT,bold] $HOST_LABEL #[fg=colour$TMUX_ACCENT,bg=colour234,nobold] '
set -g window-status-current-format "#[bg=colour$TMUX_ACCENT,fg=colour233,noreverse,bold] #I #W #[fg=colour$TMUX_ACCENT,bg=colour234,nobold]"
set -g pane-active-border-style fg=colour$TMUX_ACCENT,bold
set -g status-right '#[fg=colour244] #H '

# The laptop config pipes copies to pbcopy, which does not exist here. Copying
# within tmux still works; it just does not reach a system clipboard.
TMUX

# Host-local shell overrides, sourced last so it wins over .bash_ps1
cat > ~/.bash_host.local <<'BASH_HOST'
# Set by script/setup-server-shell.sh from the blackbook repo.
export HOST_LABEL="__LABEL__"
export PROMPT_COLOR="__COLOR__"

case "$PROMPT_COLOR" in
  red)     _c=$(tput setaf 1) ;;
  green)   _c=$(tput setaf 2) ;;
  yellow)  _c=$(tput setaf 3) ;;
  blue)    _c=$(tput setaf 4) ;;
  magenta) _c=$(tput setaf 5) ;;
  *)       _c="" ;;
esac
_r=$(tput sgr0)

# \[ \] around the escapes so long lines and history recall do not wrap wrong,
# which is what made colour prompts unusable last time.
if declare -F __git_ps1 >/dev/null 2>&1; then
  PS1='\[${_c}\]['"$HOST_LABEL"']\[${_r}\] \w$(__git_ps1 " (%s)")\$ '
else
  PS1='\[${_c}\]['"$HOST_LABEL"']\[${_r}\] \w\$ '
fi
BASH_HOST
sed -i "s/__LABEL__/$HOST_LABEL/; s/__COLOR__/$PROMPT_COLOR/" ~/.bash_host.local

# Loader mirroring the documented order from the laptop's .bashrc header,
# minus the mac-only pieces. ssh gives a login shell, so .bash_profile runs.
cat > ~/.bash_profile <<'PROFILE'
# Server loader. See ~/.bashrc on the laptop for the full map.
#   .profile       shared env + PATH
#   .bash_aliases  shared aliases + functions
#   .bash_ps1      prompt
#   .bash_host.local  per-host label and colour, overrides the prompt above
for f in ~/.profile ~/.bash_aliases ~/.bash_ps1 ~/.bash_host.local; do
  [ -r "$f" ] && . "$f"
done
unset f

export RBENV_ROOT="$HOME/.rbenv"
[ -d "$RBENV_ROOT/bin" ] && export PATH="$RBENV_ROOT/bin:$PATH"
command -v rbenv >/dev/null && eval "$(rbenv init - bash)"
PROFILE

# A bare non-login bash should get the same thing
cat > ~/.bashrc <<'RC'
[ -r ~/.bash_profile ] && . ~/.bash_profile
RC

echo "installed: .tmux.conf.local .bash_host.local .bash_profile .bashrc"
REMOTE

echo
echo "Done. Open a new session to see it:"
echo "  ssh $TARGET"
echo "  tmux new -s blackbook"
