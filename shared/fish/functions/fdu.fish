function fdu
    if test (count $argv) -lt 1
		fd . -H -t d -d 1 -0 | xargs -0 du -shc | sort -h
	else
		set dir $argv[1]
		if path filter -d $dir
			fd . $dir -H -t d -d 1 -0 | xargs -0 du -shc | sort -h
		else
			echo "'$dir' is not a directory"
		end
	end

end
