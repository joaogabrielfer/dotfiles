#!/usr/bin/env bash

check_if_present(){
	pacman -Qi $1 >/dev/null 2>&1
	return $?
}

check_if_updates(){
	if ! command -v checkupdates &> /dev/null; then
		print_error "Checkupdates command not present."
		return 1
	fi

	echo -e "\033[32mChecking for updates...\033[0m\n"

	checkupdates > /dev/null 2>&1
	local status=$?

	if [ $status -eq 0 ]; then
		sudo pacman -Syu
	elif [ $status -eq 1 ]; then
		print_error "Could not check if there were updates."
		return 0
	else
		return 1
	fi
}

update_pacman(){
	sudo pacman --noconfirm -Syu
}

install_paru(){
	sudo pacman -S --needed base-devel
	git clone https://aur.archlinux.org/paru.git
	pushd paru 1>/dev/null
	makepkg -si
	popd 
	rm -rf paru
}

install_package_pacman(){
	sudo pacman --noconfirm -S $1
}

install_package_paru(){
	paru -S --noconfirm $1
}

link_file(){
	printf "\n# file %s to link in %s" "$2" "$3" >> $DOT_DIR/bin/link-"$1".sh
	printf "\nln -vsf %s %s" "\$DOT_DIR/$1/$2" "$3" >> $DOT_DIR/bin/link-"$1".sh
}

link_dir(){
	printf "\n# dir %s to link in %s" "$2" "$3" >> $DOT_DIR/bin/link-"$1".sh
	printf "\nrm -rf %s" "$3" >> $DOT_DIR/bin/link-"$1".sh
	printf "\nln -vsf %s %s" "\$DOT_DIR/$1/$2" "$3" >> $DOT_DIR/bin/link-"$1".sh
}

print_usage_exit() {
	echo -e "\033[33mUSAGE: \033[0m"
	echo "    $0 <command>"
	echo ""
	echo "commands:"
	echo "    help                             -> outputs this message"
	echo "    install <target>                 -> install the desired configuration for the <target>"
	echo "    targets                          -> list all avaliable target configurations"
	echo "    update                           -> fetch the latest changes and updates the local environment"
	echo "    push                             -> push the current config into the remote repository"
	echo "    add-link <target> <name> <path?> -> add a link to the desired <target> in the config"
	echo "                                        <name> : root name of the dir or the file to link"
	echo "                                        <path> : full path of the target link. default: \"\$HOME/.config/\""
	echo "    add-pkg  <target> <name>         -> add a package to the <target> instalation script"
	echo "                                        <name> : name of the package"
	exit 0
}

print_error() {
	echo -e "\033[31mERROR:\033[0m $1"
}

install_target() {
	echo -e "\033[32mInstalling...\033[0m\n"

	case $1 in
		arch-desktop)
			$DOT_DIR/bin/install-arch-desktop.sh
			$DOT_DIR/bin/install-shared.sh
			;;
		arch-wsl)
			$DOT_DIR/bin/install-shared.sh
			;;
	esac
}

link_target() {
	echo -e "\033[32mCreating symlinks...\033[0m\n"

	case $1 in
		arch-desktop)
			$DOT_DIR/bin/link-arch-desktop.sh
			$DOT_DIR/bin/link-shared.sh
			;;
		arch-wsl)
			$DOT_DIR/bin/link-shared.sh
			;;
	esac
}

get_target() {
    if [[ -f "$STATE_FILE" ]]; then
        # Extrai o valor
        local found_path=$(grep "^installed_target=" "$STATE_FILE" | cut -d'=' -f2-)
        
        if [[ -n "$found_path" ]]; then
            echo "$found_path"
            return 0
        fi
    fi
    return 1 
}

contains() {
    local busca="$1"
    shift 
    
    for item in "$@"; do
        [[ "$item" == "$busca" ]] && return 0 
    done
    
    return 1 
}
