# tool fish completion (auto-generated)

function __fish_tool_path
    set -l cmd (commandline -opc)
    set -l path
    set -l first 1
    set -l skip_next 0
    for word in $cmd[2..]
        if test $skip_next -eq 1
            set skip_next 0
            continue
        end
        switch $word
            case '--color'
                set skip_next 1
                continue

            case '--name'
                set skip_next 1
                continue

            case '--format' '-f'
                set skip_next 1
                continue

            case '--rate'
                set skip_next 1
                continue

            case '--interval'
                set skip_next 1
                continue

            case '--config'
                set skip_next 1
                continue

            case '--tag'
                set skip_next 1
                continue

            case '--host'
                set skip_next 1
                continue

            case '-*'
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
complete -c tool -n '__fish_tool_path "run"' -f -l 'host' -a '(tool __complete --host (commandline -ct))' -d 'Target host (dynamic)'
