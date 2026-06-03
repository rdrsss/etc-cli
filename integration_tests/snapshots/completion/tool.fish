# tool fish completion (auto-generated)

function __fish_tool_path
    set -l cmd (commandline -opc)
    set -l path
    set -l first 1
    for word in $cmd[2..]
        if string match -q -- '-*' $word
            continue
        end
        if test $first -eq 1
            set path $word
            set first 0
        else
            set path "$path $word"
        end
    end
    test "$path" = "$argv[1]"
end

complete -c tool -n '__fish_tool_path ""' -f -a 'run' -d 'Run target'
complete -c tool -n '__fish_tool_path ""' -f -l 'verbose' -s v -d 'Verbose output'
complete -c tool -n '__fish_tool_path ""' -f -l 'color' -a 'auto always never' -d 'When to colorize output'
complete -c tool -n '__fish_tool_path "run"' -f -l 'name' -d 'Target name'
complete -c tool -n '__fish_tool_path "run"' -f -l 'format' -s f -a 'json text yaml' -d 'Output format'
complete -c tool -n '__fish_tool_path "run"' -f -l 'rate' -d 'Sampling rate'
complete -c tool -n '__fish_tool_path "run"' -f -l 'interval' -d 'Poll interval'
complete -c tool -n '__fish_tool_path "run"' -l 'config' -d 'Config file path'
complete -c tool -n '__fish_tool_path "run"' -f -l 'tag' -d 'Repeatable tag'
