## Setup and configuration

- Add the `addons/celte` folder to your Godot project (or copy the compiled gdextension `celte-systems-api.gdextension` into `res://addons/celte/`).
- Ensure the extension is enabled in the project `Project Settings -> Plugins` (or use the `plugin.cfg` included in the addon).
- Provide a configuration file at `~/.celte.yaml` with keys used by the demo (see `02-YAML-config.md` for full keys). The demo reads `CELTE_LOBBY_HOST` from this YAML to contact the lobby.

When working with headless server nodes, you typically run Godot in headless mode and set environment variables such as `CELTE_MODE=server` and other connection parameters.
