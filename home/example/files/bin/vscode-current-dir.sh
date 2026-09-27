#!/usr/bin/env bash
# Get the active window
active_window=$(hyprctl activewindow -j 2>/dev/null)

# Extract class and title
window_class=$(echo "$active_window" | grep -o '"class":"[^"]*"' | cut -d'"' -f4)
window_title=$(echo "$active_window" | grep -o '"title":"[^"]*"' | cut -d'"' -f4)

# For terminals, parse the path from the title
if [[ "$window_class" =~ (kitty|Alacritty|foot|WezTerm|Terminal) ]]; then
    # Find a path in the title (~ or /home/user/...)
    if [[ "$window_title" =~ (~|/home/[a-zA-Z0-9_-]+/.+) ]]; then
        dir="${BASH_REMATCH[1]}"
        # Convert ~ to $HOME
        dir="${dir/\~/$HOME}"
    else
        dir="$HOME"
    fi
else
    dir="$HOME"
fi

# Launch VS Code
exec code "$dir"
