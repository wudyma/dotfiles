function fzf_change_directory --description 'Jump to a repository or nearby directory'
    type -q fzf; and type -q ghq; or return 1
    set -l dir (
        begin
            printf '%s\n' "$HOME/.config"
            ghq list -p
            for candidate in $PWD/*/ $HOME/Developments/*/*/
                test -d "$candidate"; and string trim --right --chars / -- "$candidate"
            end
        end | awk '!seen[$0]++' | fzf
    )
    if test -n "$dir"; and test -d "$dir"
        builtin cd -- "$dir"
        commandline -r ''
        commandline -f repaint
    end
end
