#!/bin/bash
# Install script for ATP environment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install_godot() {
	echo "Installing Godot Engine..."
	mkdir -p ${SCRIPT_DIR}/binaries/godot
	ARCH=$(uname -m)
	OS=$(uname)
	if [ "$OS" = "Darwin" ]; then
		GODOT_URL="https://github.com/godotengine/godot/releases/download/4.4-stable/Godot_v4.4-stable_macos.universal.zip"
		wget -O /tmp/godot.zip "${GODOT_URL}" && \
		unzip /tmp/godot.zip -d ${SCRIPT_DIR}/binaries/godot && \
		chmod +x ${SCRIPT_DIR}/binaries/godot/Godot.app/Contents/MacOS/Godot && \
		rm -f /tmp/godot.zip && \
		echo "Godot Engine installed successfully to ${SCRIPT_DIR}/binaries/godot/Godot.app"
	else
		if [ "$ARCH" = "x86_64" ]; then
			GODOT_URL="https://github.com/godotengine/godot/releases/download/4.4-stable/Godot_v4.4-stable_linux.x86_64.zip"
		elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
			GODOT_URL="https://github.com/godotengine/godot/releases/download/4.4-stable/Godot_v4.4-stable_linux.arm64.zip"
		else
			echo "Unsupported architecture: $ARCH"; exit 1
		fi
		wget -O /tmp/godot.zip "${GODOT_URL}" && \
		unzip /tmp/godot.zip -d ${SCRIPT_DIR}/binaries/godot && \
		mv ${SCRIPT_DIR}/binaries/godot/Godot_v4.4-stable_linux.* ${SCRIPT_DIR}/binaries/godot/godot && \
		chmod +x ${SCRIPT_DIR}/binaries/godot/godot && \
		rm -f /tmp/godot.zip && \
		echo "Godot Engine installed successfully to ${SCRIPT_DIR}/binaries/godot/godot"
	fi
}

uninstall() {
	rm -rf ${SCRIPT_DIR}/binaries/
	echo "ATP environment uninstalled. Please give us a good grade :)"
}

install_backend() {
	rm -rf $SCRIPT_DIR/binaries/backend/
	wget -O /tmp/celte_project.zip "https://github.com/celte-team/celte-team.github.io/releases/download/ATP-Release/celte_project.zip" && \
	unzip /tmp/celte_project.zip -d $SCRIPT_DIR/binaries/backend/ && \
	rm -f /tmp/celte_project.zip
}

configure_celte_yaml() {
	local config_file="$HOME/.celte.yaml"
	if [ -f "$config_file" ]; then
		echo -e "\033[1;33mConfig file $config_file already exists. Skipping generation.\033[0m"
		return
	fi

	# Example usage
	local ip_addr
	ip_addr=$(ipconfig getifaddr en0 2>/dev/null)
	if [ -z "$ip_addr" ]; then
		ip_addr=$(ifconfig | awk '/inet / && $2 != "127.0.0.1" {print $2; exit}')
	fi
	if [ -z "$ip_addr" ]; then
		echo "Could not detect local IP address. Please edit $config_file manually."
		return 1
	fi

	cat > "$config_file" <<EOF
celte:
  - CELTE_MASTER_HOST: $ip_addr
  - CELTE_MASTER_PORT: 1908
  - CELTE_REDIS_PORT: 6379
  - CELTE_REDIS_KEY: logs
  - CELTE_REDIS_HOST: $ip_addr
  - CELTE_GODOT_PATH: ${SCRIPT_DIR}/binaries/godot/godot
  - CELTE_GODOT_PROJECT_PATH: $SCRIPT_DIR/binaries/backend/demo-tek
  - CELTE_PULSAR_HOST: $ip_addr
  - CELTE_PULSAR_PORT: 6650
  - CELTE_PULSAR_ADMIN_PORT: 8080
  - PUSHGATEWAY_HOST: $ip_addr
  - PUSHGATEWAY_PORT: 9091
  - METRICS_UPLOAD_INTERVAL: 5
  - REPLICATION_INTERVAL: 1000
  - CELTE_SERVER_GRAPHICAL_MODE: "false"
  - CELTE_LOBBY_HOST: $ip_addr
  - CELTE_YGG_HOST: $ip_addr
  - CELTE_YGG_PORT: 4564
EOF
	echo "Generated $config_file with detected IP: $ip_addr"
}

install_deps() {
	# Installing dotnet toolchain
	echo "Installing .NET SDK..."
	if ! command -v dotnet &> /dev/null; then
		wget https://dot.net/v1/dotnet-install.sh -O /tmp/dotnet-install.sh
		bash /tmp/dotnet-install.sh --channel 8.0 --install-dir $HOME/.dotnet
		rm -f /tmp/dotnet-install.sh
		export PATH="$HOME/.dotnet:$PATH"
	else
		echo ".NET SDK is already installed."
	fi

	echo "Installing golang..."
	if ! command -v go &> /dev/null; then
		wget https://go.dev/dl/go1.21.3.linux-amd64.tar.gz -O /tmp/go.tar.gz
		sudo tar -C /usr/local -xzf /tmp/go.tar.gz
		rm -f /tmp/go.tar.gz
		export PATH="/usr/local/go/bin:$PATH"
	else
		echo "Golang is already installed."
	fi
}

compile_master() {
	echo "Compiling master server..."
	local master_dir="${SCRIPT_DIR}/binaries/backend/"
	wget  https://github.com/celte-team/celte-team.github.io/releases/download/ATP-Release/master.zip	-O /tmp/master.zip && \
	unzip /tmp/master.zip -d "$master_dir" && \
	rm -f /tmp/master.zip
}

if [[ "$1" == "--rm" ]]; then
	uninstall
	exit 0
fi

compile_lobby() {
	echo "Compiling lobby server..."
	local lobby_dir="${SCRIPT_DIR}/binaries/lobby/"
	wget  https://github.com/celte-team/celte-team.github.io/releases/download/ATP-Release/lobby.zip	-O /tmp/lobby.zip && \
	unzip /tmp/lobby.zip -d "$lobby_dir" && \
	rm -f /tmp/lobby.zip
	# build release for go
	pushd "${lobby_dir}/lobby-server/" || { echo "Failed to change directory to $lobby_dir"; exit 1; }
	go mod tidy	&& \
	go build -o .
	popd	|| { echo "Failed to return to previous directory"; exit 1; }
	echo "Lobby server compiled."
}

echo "Starting ATP installation..."
install_godot && \
 install_backend && \
 configure_celte_yaml && \
 install_deps && \
 compile_master && \
	compile_lobby

