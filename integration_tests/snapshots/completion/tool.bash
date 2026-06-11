# tool bash completion (auto-generated)
# Source this file or place it in a directory loaded by bash-completion.

_tool() {
    local cur prev path cmds flags values i value_prefix
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    path=""
    for (( i=1; i<COMP_CWORD; i++ )); do
        case "${COMP_WORDS[i]}" in
            --color)
                (( i++ ))
                ;;

            --name|--target-name)
                (( i++ ))
                ;;

            --format|-f)
                (( i++ ))
                ;;

            --rate)
                (( i++ ))
                ;;

            --interval)
                (( i++ ))
                ;;

            --config)
                (( i++ ))
                ;;

            --tag)
                (( i++ ))
                ;;

            --host)
                (( i++ ))
                ;;

            -*) ;;
            *)
                if [[ -z "$path" ]]; then
                    path="${COMP_WORDS[i]}"
                else
                    path="$path ${COMP_WORDS[i]}"
                fi
                ;;
        esac
    done
    case "$path" in
        "")
            case "$cur" in
                --color=*)
                    value_prefix="${cur#*=}"
                    COMPREPLY=( $(compgen -W "auto always never" -- "$value_prefix") )
                    COMPREPLY=( "${COMPREPLY[@]/#/${cur%%=*}=}" )
                    return ;;
            esac
            case "$prev" in
                --color)
                    COMPREPLY=( $(compgen -W "auto always never" -- "$cur") ); return ;;
            esac
            ;;
        "run")
            case "$cur" in
                --color=*)
                    value_prefix="${cur#*=}"
                    COMPREPLY=( $(compgen -W "auto always never" -- "$value_prefix") )
                    COMPREPLY=( "${COMPREPLY[@]/#/${cur%%=*}=}" )
                    return ;;
                --format=*)
                    value_prefix="${cur#*=}"
                    COMPREPLY=( $(compgen -W "json text yaml" -- "$value_prefix") )
                    COMPREPLY=( "${COMPREPLY[@]/#/${cur%%=*}=}" )
                    return ;;
                -f*)
                    value_prefix="${cur:2}"
                    COMPREPLY=( $(compgen -W "json text yaml" -- "$value_prefix") )
                    COMPREPLY=( "${COMPREPLY[@]/#/${cur:0:2}}" )
                    return ;;
                --config=*)
                    value_prefix="${cur#*=}"
                    COMPREPLY=( $(compgen -f -- "$value_prefix") )
                    COMPREPLY=( "${COMPREPLY[@]/#/${cur%%=*}=}" )
                    return ;;
                --host=*)
                    value_prefix="${cur#*=}"
                    COMPREPLY=( $(compgen -W "$("${COMP_WORDS[0]}" __complete --host "$value_prefix")" -- "$value_prefix") )
                    COMPREPLY=( "${COMPREPLY[@]/#/${cur%%=*}=}" )
                    return ;;
            esac
            case "$prev" in
                --color)
                    COMPREPLY=( $(compgen -W "auto always never" -- "$cur") ); return ;;
                --format|-f)
                    COMPREPLY=( $(compgen -W "json text yaml" -- "$cur") ); return ;;
                --config)
                    COMPREPLY=( $(compgen -f -- "$cur") ); return ;;
                --host)
                    COMPREPLY=( $(compgen -W "$("${COMP_WORDS[0]}" __complete --host "$cur")" -- "$cur") ); return ;;
            esac
            ;;
    esac

    case "$path" in
        "")
            cmds="run"
            flags="--verbose -v --debug -d --color --help -h"
            values=""
            ;;
        "run")
            cmds=""
            flags="--verbose -v --debug -d --color --name --format -f --rate --interval --config --tag --host --help -h"
            values=""
            ;;
        *)
            cmds=""
            flags=""
            ;;
    esac

    if [[ "$cur" == -* ]]; then
        COMPREPLY=( $(compgen -W "$flags" -- "$cur") )
    else
        if [[ -n "$cmds" ]]; then
            COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
        else
            COMPREPLY=( $(compgen -W "$values" -- "$cur") )
        fi
    fi
}

complete -F _tool tool
