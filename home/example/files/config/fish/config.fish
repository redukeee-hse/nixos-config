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
