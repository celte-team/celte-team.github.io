RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BOLD='\033[1m'
RESET='\033[0m'

error_exit() {
				local lineno=$1
				local msg=$2
				echo "${RED}Error on or near line ${lineno}: ${msg}${RESET}"
				exit 1
}

info() {
				local msg=$1
				echo "${CYAN}[INFO] ${msg}${RESET}"
}

warn() {
				local msg=$1
				echo "${YELLOW}[WARNING] ${msg}${RESET}"
}

success() {
				local msg=$1
				echo "${GREEN}[SUCCESS] ${msg}${RESET}"
}

take_input() {
				local prompt=$1
				local default=$2
				local input

				if [ -n "$default" ]; then
								read -p "$(echo -e ${BLUE}${prompt} [${default}]: ${RESET})" input
								input=${input:-$default}
				else
								read -p "$(echo -e ${BLUE}${prompt}: ${RESET})" input
				fi

				echo "$input"
}

greet() {
    echo "${BOLD}Welcome to CELTE!${RESET}"
    echo "This script will guide you through the installation of the ATP environment."
    echo "You can then use this script to launch our development environment utilities easily."
    echo "Use ${BLUE}./atp.sh --help${RESET} to see available options."
    echo "Run ${BLUE}./atp.sh --install${RESET} to install ATP now."
	}

	if [ $# -eq 0 ]; then
		greet
		exit 0
	fi

	# script entry point
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	while [[ $# -gt 0 ]]; do
		key="$1"

		case $key in
			--install)
				bash "$SCRIPT_DIR/install.sh"
				success "ATP installation completed."
				shift
				;;
			--uninstall)
				bash "$SCRIPT_DIR/install.sh" --rm
				success "ATP uninstalled."
				shift
				;;
			--backend)
				bash "$SCRIPT_DIR/start_backend.sh"
				success "ATP backend started."
				shift
				;;
			--lobby)
				bash "$SCRIPT_DIR/start_lobby.sh"
				success "ATP lobby server started."
				shift
				;;
			--edit)
				bash "$SCRIPT_DIR/edit.sh"
				shift
				;;
			--client)
				bash "$SCRIPT_DIR/client.sh"
				shift
				;;
			--todo)
				cat "$SCRIPT_DIR/TODO.md"
				shift
				;;
			--help)
				greet
				echo ""
				echo "Available options:"
				echo "  --install    Install ATP environment"
				echo "  --uninstall  Uninstall ATP environment"
				echo "  --backend    Start ATP backend servers"
				echo "  --lobby      Start ATP lobby server"
				echo "  --edit       Open the Demo Tek project in Godot Editor"
				echo "  --client     Open the Demo Tek project in Godot (play mode). To use this you must first start the backend, then start the lobby. Run this command multiple times to connect multiple clients."
				echo "  --todo							Show the TODO list for ATP testing"
				echo "  --help       Show this help message"
				echo ""
				echo "${BOLD}Tutorial:${RESET} To run the project, run the following commands in order:"
				echo "  1. ${BLUE} ./atp.sh --install ${RESET} (only once to install the environment)"
				echo "  2. ${BLUE} ./atp.sh --backend ${RESET}"
				echo "  3. ${BLUE} ./atp.sh --lobby ${RESET} # in a new terminal"
				echo "  4. ${BLUE} ./atp.sh --client$ {RESET} # in a new terminal, run multiple times to connect multiple clients"
				echo ""
				echo "${BOLD}This project is a very technical EIP project meant to run in a production environment which can't be reproduced on a single machine.${RESET}"
				echo "${BOLD}If you have trouble using it, please don't give up and contact us at ${BLUE}celte.system@gmail.com${RESET}"
				shift
				;;
			*)
				warn "Unknown option: $key"
				greet
				exit 1
				;;
		esac
	done
