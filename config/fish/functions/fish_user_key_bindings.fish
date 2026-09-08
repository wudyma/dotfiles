function fish_user_key_bindings
    # fzf
    if type -q fzf; and type -q ghq
        bind \cf fzf_change_directory
    end

    # vim-like
    bind \cl forward-char

    # prevent iterm2 from closing when typing Ctrl-D (EOF)
    bind \cd delete-char
    if type -q fzf; and functions -q fzf_configure_bindings
        fzf_configure_bindings --directory=\co
    end
end
