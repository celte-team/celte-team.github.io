# Integrating Celte into Godot

## Building the system's binaries

Start by building Celte's dynamic libraries following [this](how-to-build-**systems**.md) tutorial.

### Coming soon: how to setup the extension

Check out [this documentation](./CompilingGodot.md) to learn how to build your godot project using the celte extension.

### Customizing your netcode with CelteHooks

Celte will take care of managing all the major aspects of networking to bring server meshing to your game. However, you might want to customize the behaviors of a number of events. You may use celte's [hooks](./Hooks.md) for this purpose.