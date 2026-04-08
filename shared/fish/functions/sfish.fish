function sfish --description 'Reload fish configuration and functions'
    set -l fish_dir "$HOME/dotfiles/shared/fish"
    set -l config_path "$fish_dir/config.fish"

    if test -f "$config_path"
        source "$config_path"
        # Reload all functions in the functions directory
        for f in "$fish_dir/functions/"*.fish
            source "$f"
        end
        echo "Fish configuration and functions reloaded from $fish_dir"
    else
        # Fallback to standard location
        source "$HOME/.config/fish/config.fish"
        echo "Fish configuration reloaded from $HOME/.config/fish/config.fish"
    end
end
