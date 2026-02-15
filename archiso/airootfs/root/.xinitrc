#!/bin/sh

# Load X resources
[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources

# Start Window Manager
openbox-session &

# Launch Terminal with Claude Wrapper
# -fa 'DejaVu Sans Mono' sets the font
# -fs 12 sets font size
# -bg black -fg white sets colors
# -geometry sets size
exec xterm -fa 'DejaVu Sans Mono' -fs 12 -bg black -fg white -geometry 130x40 -e /root/run-claude.sh
