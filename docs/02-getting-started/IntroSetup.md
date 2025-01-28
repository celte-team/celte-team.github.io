---
sidebar_position: 1
---

# Overview

This document provides a step-by-step guide to setting up the development environment for the project. The project is developed in four main parts:

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

Go to the `celte-system` folder and run the following command:

```bash
dotnet run --config configFile.yml
```

The `configFile.yml` is a file that contains the configuration of the different grapes
```
grapes:
    - LeChateauDuMechant
    - LeChateauDuGentil
```

## Godot

The godot project contain the client and the server node.

### godot installation:

    - install godot version``4.2.2``
    - import godot project from the `godot` folder

![import godot project](./images/import_godot_project.png)

- Run the project:

---

### Link celte-godot to the celte-system:

The godot implementation of the SDK in base on a addon.
We will first compile de SDK and import it inside the godot addon Then we will use symbolic link to link the addon to your godot project !

1. Open at least one the project in godot.

2. Go to the `celte-godot` folder and run the following command:

```bash
cd extension-standalone ; scons
```

3. Go to the `celte-system` folder and run the following command:

```bash
./automations/setup_repository.sh PATH-TO.. /celte/celte-godot/addons/celte/deps/ ..
```
If needed you can create the `deps` folder in the `celte-godot/addons/celte` folder.


4. Rm godot-cpp then git clone the cpp module then git switch to 4.2

   ```bash
   rm -rf godot-cpp ; git clone git@github.com:godotengine/godot-cpp.git ; cd godot-cpp ; git checkout 4.2
   ```

5. Go to `celte-system/system/build` and run the following command:

```bash
    cmake install .
```

5. Then compile the project in godot.
```
cd YOUR_PATH/celte/celte-godot/projects/demo1
```

To use the server mode you have to set the following environment variable:
```bash
export CELTE_MODE=server
```

```bash
/Applications/Godot.app/Contents/MacOS/Godot .
```

ln -s YOUR_PATH/celte/celte-godot/addons addons

Then you have to go to system and run the following command:

```bash
cd system/build ; cmake --preset default -DCMAKE_INSTALL_PREFIX=YOUR_PATH/celte/celte-godot/addons/celte/deps/ .. ;
 ninja install
```

⚠️ You must have installed on your machine the following tools:

- `scons`
- `boost`

MAC OS users must install the following packages:

- `boost-python3` : `brew install boost-python3`

# Run the project:

To easily run the project, you can use the `run` script in the `celte-system` folder.

```bash
./automations/run (--pulsar, --master)
```

# Docker:

There is a docker image containing the celte-system folder and already compiled.
`clmt/celte_server:latest`
This will be use to run the project with the `--cpp` option.
