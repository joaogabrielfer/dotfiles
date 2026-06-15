set CONFIG_PATH "$HOME/dotfiles/shared/"
function lfn
	for func in (functions)
		if type -p $func | grep -q ".*/fish/functions"
			echo $func
		end
	end
end
