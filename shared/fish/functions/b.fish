function b --description 'Go back N directories in history'
    set -l count 1
    if test (count $argv) -gt 0
        set count $argv[1]
    end
    for i in (seq $count)
        prevd > /dev/null
    end
end
