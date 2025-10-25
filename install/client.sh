#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -d "$SCRIPT_DIR/binaries/backend/demo-tek" ]; then
				echo "Demo Tek project not found. Please install the ATP environment using the install command first."
				exit 1
fi

if [[ "$(uname)" == "Darwin" ]]; then
    GODOT_BIN="$SCRIPT_DIR/binaries/godot/Godot.app/Contents/MacOS/Godot"
else
    GODOT_BIN="$SCRIPT_DIR/binaries/godot/godot"
fi

echo "Opening project in path: $SCRIPT_DIR/binaries/backend/demo-tek/"
cd "$SCRIPT_DIR/binaries/backend/demo-tek/" || { echo "Failed to change directory to $SCRIPT_DIR/binaries/backend/demo-tek/"; exit 1; }
$GODOT_BIN .
