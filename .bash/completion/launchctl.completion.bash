# ex: filetype=sh et sw=4
#
# launchctl(1) completion
#

_launchctl()
{
    local cur oslevel

    oslevel=${OSTYPE//darwin/}
    oslevel=${oslevel%%.*}

    COMPREPLY=()
    cur=`_get_cword`

    if [[ $COMP_CWORD -eq 1 ]]; then
        local commands

        commands="load unload start stop list setenv unsetenv \
            getenv export limit shutdown getrusage log umask help"

        if [[ $oslevel -le 8 ]]; then
            commands+=" reloadttys stdout stderr"
        fi

        if [[ $oslevel -ge 9 ]]; then
            commands+=" submit remove bootstrap singleuser bsexec bslist"
            if [[ $oslevel -ge 10 ]]; then
                commands+=" bstree managerpid manageruid managername"
            fi
        fi
        COMPREPLY=( $( compgen -W "$commands" -- $cur ) )
    else
        local command
        command=${COMP_WORDS[1]}
        prev=${COMP_WORDS[COMP_CWORD-1]}

        case "$command" in
            load|unload)
                case $prev in
                    -S)
                        COMPREPLY=( $( compgen -W "Aqua LoginWindow Background StandardIO System" -- $cur ) )
                    ;;
                    -D)
                        COMPREPLY=( $( compgen -W "system local network all user" -- $cur ) )
                    ;;
                    *)
                        opts="-w"
                        if [[ $oslevel -ge 0 ]]; then
                            opts+=" -S -D"
                            if [[ $command = load ]]; then
                                opts+=" -F"
                            fi
                        fi
                        COMPREPLY=( $( compgen -f -W "$opts" -- $cur ) )
                    ;;
                esac
            ;;
            start|stop|remove|list)
                local jobs opts

                if [[ $command != list || $oslevel -ge 9 ]]; then
                    if [[ $oslevel -le 8 ]]; then
                        jobs="$( launchctl list )"
                    else
                        jobs="$( launchctl list | awk 'NR>1 { print $3 }')"
                        if [[ $oslevel -ge 10 && $command = list ]]; then
                            opts="-x"
                        fi
                    fi
                fi
                COMPREPLY=( $( compgen -W "$jobs $opts" -- $cur ) )
            ;;
            getenv|setenv|unsetenv)
                if [[ $COMP_CWORD -eq 2 ]]; then
                    envvars="$( launchctl export | cut -f1 -d= )"
                    COMPREPLY=( $( compgen -W "$envvars" -- $cur ) )
                fi
            ;;
            getrusage)
                if [[ $COMP_CWORD -eq 2 ]]; then
                    COMPREPLY=( $( compgen -W "self children" -- $cur ) )
                fi
            ;;
            limit)
                if [[ $COMP_CWORD -eq 2 ]]; then
                    local limits
                    limits="$( launchctl limit | awk '{print $1}' )"
                    COMPREPLY=( $( compgen -W "$limits" -- $cur ) )
                fi
            ;;
            log)
                if [[ $COMP_CWORD -eq 2 ]]; then
                    COMPREPLY=( $( compgen -W "level only mask" -- $cur ) )
                else
                    local level
                    levels="debug info notice warning error critical alert emergency"
                    case ${COMP_WORDS[2]} in
                        level)
                            if [[ $COMP_CWORD -eq 3 ]]; then
                                COMPREPLY=( $( compgen -W "$levels" -- $cur ) )
                            fi
                        ;;
                        mask|only)
                            COMPREPLY=( $( compgen -W "$levels" -- $cur ) )
                        ;;
                    esac
                fi
            ;;
            stdout|stderr)
                # Darwin 8 only
                if [[ $oslevel -le 8 ]]; then
                    _filedir
                fi
            ;;
            submit)
                local i
                i=1
                while [[ $i -lt ${#COMP_WORDS[@]} ]]; do
                    if [[ "${COMP_WORDS[i-1]}" = "--" ]]; then
                        _command_offset $i
                        return 0
                    fi
                    i=$((i+1))
                done

                local submit_opts
                submit_opts="-l -p -o -e --"
                case $prev in
                    -l)
                    ;;
                    -p)
                        _command_offset $COMP_CWORD
                    ;;
                    -o|-e)
                        _filedir
                    ;;
                    *)
                        COMPREPLY=( $( compgen -W "$submit_opts" -- $cur ) )
                    ;;
                esac

            ;;
            bslist)
                local pids opts
                pids=$( ps axo pid= )
                [[ $oslevel -ge 10 ]] && opts="-j"
                COMPREPLY=( $( compgen -W "$pids $opts" -- $cur ) )
            ;;
            bsexec)
                if [[ $COMP_CWORD -eq 2 ]]; then
                    local pids
                    pids=$( ps axo pid= )
                    COMPREPLY=( $( compgen -W "$pids" -- $cur ) )
                else
                    _command_offset 3
                fi
            ;;
            bstree)
                if [[ $oslevel -ge 10 ]]; then
                    COMPREPLY=( $( compgen -W "-j" -- $cur ) )
                fi
                ;;
        esac
    fi

    return 0
}
complete -F _launchctl $filenames launchctl
