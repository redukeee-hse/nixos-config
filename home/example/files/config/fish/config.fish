# Interactive shell in kitty. Autosuggestions, syntax highlighting and
# completions come with fish itself; the login shell and all scripts stay bash.
status is-interactive; or exit

set -g fish_greeting

# Same guards as .bashrc: rm asks once before removing more than three files
# or recursing; cp and mv ask before overwriting; `del` moves to the trash.
alias rm 'rm -I --preserve-root=all'
alias cp 'cp -i'
alias mv 'mv -i'
alias del 'trash-put'

# Modern replacements, same habits.
alias ls 'eza --icons=auto --group-directories-first'
alias ll 'eza -l --icons=auto --git --group-directories-first'
alias la 'eza -la --icons=auto --git --group-directories-first'
alias tree 'eza --tree --icons=auto'
alias cat 'bat --paging=never --style=plain'
alias lg 'lazygit'

# VS Code terminals follow the editor theme; others get the pywal palette.
if test "$TERM_PROGRAM" = vscode
    printf '\e]104\a\e]110\a\e]111\a\e]112\a'
else if test -r ~/.cache/wal/sequences; and set -q WAYLAND_DISPLAY
    command cat ~/.cache/wal/sequences
end

# Autosuggestions, comments and completion descriptions default to brblack,
# which pywal often makes a loud colour (blue on a pink palette). Use the
# foreground tinted with the accent and dimmed toward the background instead.
if test "$TERM_PROGRAM" != vscode; and test -r ~/.cache/wal/colors
    set -l pal (string replace '#' '' < ~/.cache/wal/colors)
    set -l muted
    for i in 1 3 5
        set -l bg (math 0x(string sub -s $i -l 2 $pal[1]))
        set -l fg (math 0x(string sub -s $i -l 2 $pal[8]))
        set -l ac (math 0x(string sub -s $i -l 2 $pal[6]))
        set -a muted (printf '%02x' (math -s0 "(0.7 * $fg + 0.3 * $ac) * 0.5 + $bg * 0.5"))
    end
    set muted (string join '' $muted)
    set -g fish_color_autosuggestion $muted
    set -g fish_color_comment $muted
    set -g fish_pager_color_description $muted
end

# `y` opens yazi and cds into the folder it was left in.
function y
    set tmp (mktemp -t yazi-cwd.XXXXXX)
    yazi $argv --cwd-file="$tmp"
    if read -z cwd < "$tmp"; and test -n "$cwd"; and test "$cwd" != "$PWD"
        builtin cd -- "$cwd"
    end
    command rm -f -- "$tmp"
end

zoxide init fish --cmd cd | source
fzf --fish | source
starship init fish | source
