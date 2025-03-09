---
sidebar_position: 1
---
# Overview

This document provides a step-by-step guide to setting up the development environment for the project. The project is developed in four main parts:

## Setup export in bashrc

The project need some environment variable, here is what you need to add at the end of your bashrc (~/.bashrc) :
Path to your vcpkg:

```Bash
export VCPKG_ROOT= ~/vcpkg
```

Your type of OS (the exmple is for linux):
arm64-osx : macos
aarch64-linux : linux arm
x64-linux : linux

```
export VCPKG_TARGET_TRIPLET=x64-linux

export VCPKG_TARGET_TRIPLET=aarch64-linux

export VCPKG_TARGET_TRIPLET=arm64-osx
```

Add vcpkg_root to your path:

```
export PATH=$VCPKG_ROOT:$PATH
```

Add the config path:

```
export PKG_CONFIG_PATH=/usr/lib64/pkgconfig/:$PKG_CONFIG_PATH

```

Add the type of host (local by default):

```
export CELTE_CLUSTER_HOST=localhost
```

## Install Perl

Vcpkg don't install it by default at the compilation, you may need ton install it manually if not already installed

```
sudo dnf install perl-IPC-Cmd
```

## Redis

Redis is used for the error managment and report, it's a dynamic database using RAM instead of hard drive for better performance

To use it launch it using the run command

```
./automations/run --redis

```

## Pulsar

[Pulsar](https://pulsar.apache.org/) is a distributed messaging and event-streaming platform designed to provide high performance, scalability, and flexibility. It enables real-time data processing and is widely used for use cases like message queuing, pub-sub systems, and streaming data pipelines.

To use it you just have to go to the `celte-system` folder and run the following command:

```bash
./automations/run --pulsar
```

## Master

Master is the conductor of the orchestra. He is responsible :

* Of the assignation of the different client to the different server nodes.
* He is also responsible for the creation of the different server nodes.

go to the `celte-system` folder and run the following command:

```bash
./automations/run --master
```

## Godot

The godot project contain the client and the server node.

### godot installation:

    - install godot[version 4.2.2](https://godotengine.org/download/archive/4.2.2-stable/)
    - import godot project from the `godot` folder

![import godot project](./images/import_godot_project.png)

- Run the project:

---

### Link celte-godot to the celte-system:

1. open at least one the project in godot.
2. Go to the `celte-system` folder and run the following command:

```bash
./automations/setup_repository.sh PATH-TO..  /celte-godot
```

3. rm godot-cpp then git clone the cpp module then git switch to 4.2

   ```bash
   rm -rf godot-cpp ; git clone git@github.com:godotengine/godot-cpp.git ; cd godot-cpp ; git checkout 4.2
   ```
4. go to `celte-system/system/build` and run the following command:

```bash
    cmake install .
```

5. Then link the addons to your project:

```bash
ln -s /YOUR_PATH/celte/celte-godot/addons/celte/ addons/celte
```

⚠️ You must have installed on your machine the following tools:

- `scons`
- `boost`

MAC OS users must install the following packages:

- `boost-python3` : `brew install boost-python3`

# Run the project:

To easily run the project, you can use the `run` script in the `celte-system` folder.

launch them in this order : redis -> pulsar -> master

```bash
./automations/run (--redis, --pulsar, --master)
```

Now that all the dockers are launched go to the godot.project (by default in celte-godot/projects/demo1)

To launch a server:

```
export CELTE_MODE=server
godot . --headless
```

To launch a client (need at least one server launched)

```
godot .
```

# Docker:

There is a docker image containing the celte-system folder and already compiled.
`clmt/celte_server:latest`
This will be use to run the project with the `--cpp` option.
