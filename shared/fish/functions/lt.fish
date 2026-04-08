function lt --description 'List directory tree using eza'
    if test (count $argv) -gt 1
        eza --icons --header -long -A -T --level=$argv[2] $argv[1]
    else
        eza --icons --header -long -A -T --level=2 $argv[1]
    end
end
