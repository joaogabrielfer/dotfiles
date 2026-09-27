# function fish_prompt
#     set -l last_status $status
# 	set_color white
# 	printf "["
#     set_color yellow
# 	printf "%s " (whoami)
# 	set_color white
# 	printf "-> "
#     set_color red
#     printf "%s" (basename $(prompt_pwd))
#     set_color white
#     printf "]"
#
#     set -l git_info (fish_git_prompt)
#     if test -n "$git_info"
#         printf "%s" "$git_info"
# 	end
#
# 	if test $last_status -ne 0
# 		set_color red
# 	else
# 		set_color green
# 	end
#     printf " ❯ "
#     set_color normal
# end

set -g fish_transient_prompt 1

function __prompt_pwd_display
    set -l realpwd (pwd -P 2>/dev/null; or pwd)
    set -l home $HOME
    set -l projects "$home/personal/programming/projects"

    if string match -q "$projects/*" -- $realpwd
        or test $realpwd = $projects
        set -l rest (string replace -r "^$projects/?" "" -- $realpwd)
        if test -z "$rest"
            printf '%s\n%s\n' purple "~projects"
        else
            printf '%s\n%s\n' purple $rest
        end
        return
    end

    printf '%s\n%s\n' blue (string replace -r "^$home" "~" -- $realpwd)
end

function fish_prompt
    set -l last_status $status

    if contains -- --final-rendering $argv
        if test $last_status -ne 0
            set_color red
        else
            set_color green
        end
        printf '$ '
        set_color normal
        return
    end

    set -l sep_color brblack
    set -l first 1

    function __prompt_seg --no-scope-shadowing
        if test $first -eq 0
            set_color $sep_color
            printf ' | '
        end
        set first 0
    end

    # user@host
    __prompt_seg
    set_color yellow
    printf '\uf007 %s' $USER
    set_color $sep_color
    printf '@'
    set_color cyan
    printf '%s' (prompt_hostname)

    # pwd
    set -l pwd_info (__prompt_pwd_display)
    __prompt_seg
    set_color $pwd_info[1]
    printf '\uf07c %s' $pwd_info[2]

    # git
    set -l git_info (fish_git_prompt ' %s')
    if test -n "$git_info"
        __prompt_seg
        set_color magenta
        printf '\ue725 (%s)' (string trim -- $git_info)
    end

    # guix shell
    if set -q GUIX_ENVIRONMENT
        __prompt_seg
        set_color green
        printf '\uf1b2 guix'
    end

    # exit status
    if test $last_status -ne 0
        __prompt_seg
        set_color red
        printf '[%s]' $last_status
    end

    printf '\n'

    if test $last_status -ne 0
        set_color red
    else
        set_color green
    end
    printf '$ '
    set_color normal
end
