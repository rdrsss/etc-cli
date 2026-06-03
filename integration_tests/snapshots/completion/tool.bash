# tool bash completion (auto-generated)
# Source this file or place it in a directory loaded by bash-completion.

_tool() {
    local cur prev path cmds flags values i
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    case "$prev" in
    esac

    path=""
    for (( i=1; i<COMP_CWORD; i++ )); do
        case "${COMP_WORDS[i]}" in
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
            cmds="run"
            flags="--verbose -v --help -h"
            values=""
            ;;
        "run")
            cmds=""
            flags="--verbose -v --name --help -h"
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
