#!/bin/bash
# Start lobby server for ATP
echo "Starting ATP lobby server..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
$SCRIPT_DIR/binaries/lobby/lobby-server/lobby-server
