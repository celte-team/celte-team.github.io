# Setup the Project

This document explains how to set up a local development environment for Celte. It contains the required tools, repository cloning steps, build and run instructions, and development norms the team follows. This page is intended for developers working on the project and provides extra detail compared to the internal notes.

Note that the configuration for production is slightly different than the configuration for developping.

# Running in production and using the addon

If you wish to only use CELTE in your game and deploy it you will need our **Godot addon.**

Download it from the [latest release](https://github.com/celte-team/celte-godot/releases) and place it under the addons folder of your godot project.

The components you need to think about are the following:
- Your game
- Having a master server up and running
- Deploying Apache pulsar and Redis for the networking backend
- One or more lobbies to bridge the master server and your clients, and create game sessions

Each of these components has a section in this documentation. Please refer to it.

# Contributing

## Required tools

- Git
- Docker (and docker-compose if you use it locally)
- VCPKG
- Ninja (or another supported generator for CMake)
- Python (required by SCons)
- scons (build tool used by Godot native extensions)
- a language that supports HTTP requests for building the lobby server (we use Go)
- dotnet SDK (for running Master)

Install the platform-specific packages using your distribution package manager or Homebrew on macOS.

## Git clone

Clone the two repositories you'll work with:

```bash
git clone git@github.com:celte-team/celte-system.git && cd celte-system && git clone git@github.com:celte-team/celte-godot.git
```


## Setup Celte System (celte-system)

1. Create a deps folder inside the celte-godot addon (this is where the automation script will place dependencies):

```bash
cd celte-godot/addons/celte/
mkdir -p deps
cd -
```

2. Configure environment variables

Open your shell rc file to add environment variables (use `~/.bashrc`, `~/.zshrc`, or the file appropriate to your shell):

```bash
code ~/.bashrc   # or: nano ~/.bashrc, vim ~/.bashrc
```

Add (replace the paths and triplet with values for your machine):

```bash
export VCPKG_ROOT="$HOME/vcpkg"                # path to your vcpkg checkout
export VCPKG_TARGET_TRIPLET="x64-linux"        # or: aarch64-linux, arm64-osx
export PATH="$VCPKG_ROOT:$PATH"
export PKG_CONFIG_PATH="/usr/lib64/pkgconfig/:$PKG_CONFIG_PATH"
export CELTE_CLUSTER_HOST=localhost              # host used by some local tooling
```

Then reload your shell:

```bash
source ~/.bashrc   # or source ~/.zshrc
```

3. Run the repository setup for celte-system

The automation script prepares the celte-godot workspace and copies/builds required pieces. From the `celte-system` repo run:

```bash
cd celte-system/
./automations/setup_repository.sh ./celte-godot/
cd -
```

This script expects the path to the `celte-godot` repository and will configure the addon folders accordingly.

## Setup Celte-Godot (celte-godot)

1. Install Godot 4.4 (or the documented supported version)

Download the stable release archive for your OS from https://godotengine.org/download/archive/4.4-stable/ and unpack it to a known location.

2. Configure Godot environment variables

Add the path to your Godot executable to your shell rc (example for Linux/macOS):

```bash
export GODOT_PATH="$HOME/Downloads/Godot_v4.4-stable_linux.x86_64"
export CELTE_GODOT_PATH="$HOME/Downloads/Godot_v4.4-stable_linux.x86_64"
source ~/.bashrc
```

If you run into linker errors during SCons (example: cannot find -lstdc++), on some distros you will need to install libc++ packages and build with the static C++ option disabled:

```bash
sudo dnf install libcxx libcxx-devel          # Fedora/RHEL example
# In the SCons build add:
# env.Append(LIBS=["c++"])
# And run scons with:
scons use_static_cpp=no
```

3. Clone and build godot-cpp (GDNative bindings)

The project expects a compatible `godot-cpp` checkout inside the `extension-standalone` folder. From the root of `celte-godot` run:

```bash
cd extension-standalone/
git clone git@github.com:godotengine/godot-cpp.git
cd godot-cpp/
git switch 4.4
git checkout 6388e26dd8a42071f65f764a3ef3d9523dda3d6e  # pinned revision used by the project
cd ../
```

4. Build the Godot extension

From the `celte-godot/extension-standalone` directory run SCons to compile native extensions:

```bash
cd celte-godot/extension-standalone
scons
cd -
```

5. Link the addon into a project

Point a demo project to the shared addon with a symlink (example for `demo-tek`):

```bash
cd projects/demo-tek/
rm -rf addons/celte
ln -s ../../addons/celte/ addons/celte
```

6. Build the lobby server (Go)

From the lobby server directory:

```bash
cd projects/lobby-server/
go mod init lobby-server   # only if module not initialized yet
go mod tidy
go build -o lobby-server .
```

7. Create `~/.celte.yaml` developer config

Create a `~/.celte.yaml` file containing your local development configuration. Replace the example IP addresses with the values for your network. DO NOT commit credentials or real tokens.

Example `~/.celte.yaml` (edit the values):

```yaml
# Dev config
celte:
    - CELTE_MASTER_HOST: 192.168.1.41
    - CELTE_MASTER_PORT: 1908
    - CELTE_REDIS_PORT: 6379
    - CELTE_REDIS_KEY: logs
    - CELTE_REDIS_HOST: 192.168.1.41
    - CELTE_GODOT_PATH: /Applications/Godot.app/Contents/MacOS/Godot
    - CELTE_GODOT_PROJECT_PATH: /path/to/celte-godot/projects/demo-tek
    - CELTE_PULSAR_HOST: 192.168.1.41
    - CELTE_PULSAR_PORT: 6650
    - CELTE_PULSAR_ADMIN_PORT: 8080
    - PUSHGATEWAY_HOST: 192.168.1.41
    - PUSHGATEWAY_PORT: 9091
    - METRICS_UPLOAD_INTERVAL: 5
    - REPLICATION_INTERVAL: 1000
    - CELTE_SERVER_GRAPHICAL_MODE: 'false'
    - CELTE_LOBBY_HOST: 192.168.1.41
```

8. Final compile step for godot native extension

```bash
cd celte-godot/extension-standalone
scons
cd -
```

## Launching the project (local development)

1. Determine your host IP

Run the orchestration script which prints a suggested host address (or run `ifconfig`/`ip a` for your OS). Update your `~/.celte.yaml` values with the detected IP where required.

```bash
./automations/run   # prints info and can start specific services
```

2. Start Pulsar and other Docker services

Use the automation script to start the full stack (Pulsar, Zookeeper, Bookkeeper, Redis, etc):

```bash
./automations/run --all
```

If Pulsar or Bookkeeper report permission errors for data directories, run (from `celte-system`):

```bash
sudo mkdir -p pulsar/data/zookeeper pulsar/data/zookeeper/version-2 pulsar/data/bookkeeper
sudo chmod 777 pulsar/data/ -R
```

3. Start Master

From the `celte-system` repo:

```bash
cd master
dotnet run
```

4. Start the lobby server (from `celte-godot`)

```bash
cd projects/lobby-server/
./lobby-server
```

5. Launch the Godot client or server

To run a server instance (headless):

```bash
export CELTE_MODE=server
godot . --headless
```

Note that servers are normally started automatically by the master when the lobby connects to it.

To run a client (desktop):

```bash
godot .
```

If everything is configured correctly the client will connect to the local servers and you should see the demo scene.

## Docker image

We publish a prebuilt image containing `celte-system` and compiled artifacts as `clmt/celte_server:latest`. This image can be used to run the system in environments where building locally is inconvenient. Consult the automation scripts for `--cpp` or other flags that use the image.

## Push a release (notes)

1. Create a GitHub Personal Access Token with the correct scopes (do not paste tokens into git-tracked files).
2. Export it in your shell before running release scripts:

```bash
export GITHUB_TOKEN="<your_personal_access_token_here>"
```

3. Run the release script (example):

```bash
./send_release.sh
```

## Coding Style & Development Norms

This project follows language-specific styles and a lightweight review process. The goal is readable, documented, and reviewed code.

### TL;DR

- Implement a working feature with tests where applicable.
- Write clear commit messages and follow the commit prefix convention (fix:, add:, update:, etc.).
- Request reviews and don't merge without at least one approval.

### General rules

- Keep commits focused and small.
- Avoid header files where the project conventions forbid them.
- Remove irrelevant comments and unused code before pushing.
- Follow the language-specific style sections below.

### C++ (.cpp)

Follow the Google C++ Style Guide. Use CamelCase for classes and methods, prefix private members with an underscore, use Doxygen-style comments (///), and prefer unit tests (GoogleTest).

Examples and conventions:

```cpp
/// @brief my method does this
/// @param x an integer
void Method(int x);

int _member; ///< this member stores ...
```

### C# (.cs)

Follow Microsoft C# conventions: PascalCase for public members and types, XML documentation comments, and keep GUI code separated.

### GDScript (.gd)

Follow Godot style: snake_case for methods and variables and keep scenes and scripts well-documented.

## Branching and PR process

Follow the flow in the project's PR templates: create an issue, link to milestone/epic, create a branch, implement & test, update docs, then open a PR using the template. Ensure CI passes and at least one review is completed.
