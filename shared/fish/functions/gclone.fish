function gclone
	if test (count $argv) -lt 2
		git clone https://github.com/joaogabrielfer/$argv[1]
	else
		git clone https://github.com/$argv[1]/$argv[2]
	end
end
