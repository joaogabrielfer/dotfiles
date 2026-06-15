function run --description "Compile and run a single-file program (defaults: gcc, .c, builds/)"
    if test (count $argv) -lt 1
        echo "Error: Missing filename."
        echo "Usage: run <filename_without_extension> [program_arguments...]"
        return 1
    end

    # Set defaults if variables are not already set
    set -l compiler_cmd (set -q compiler; and echo $compiler; or echo gcc)
    set -l extension (set -q ext; and echo $ext; or echo c)
    set -l build_dir (set -q dir; and echo $dir; or echo builds)
    set -l build_flags (set -q flags; and echo $flags; or echo "")

    set -l name "$argv[1]"
    set -l source "$name.$extension"
    set -l output "$build_dir/$name"

    if not test -f "$source"
        echo "Error: Source file '$source' not found."
        return 1
    end

    if not command -q "$compiler_cmd"
        echo "Error: Compiler '$compiler_cmd' not found."
        return 1
    end

    if not mkdir -p "$build_dir"
        echo "Error: Could not create directory '$build_dir'."
        return 1
    end

    # Compile and run
	echo "RUNNING: $compiler_cmd $source $build_flags -o $output"
    if eval "$compiler_cmd" "$source" "$build_flags" -o "$output"
        "$output" $argv[2..-1]
    else
        echo "Error: Compilation failed."
        return 1
    end
end
