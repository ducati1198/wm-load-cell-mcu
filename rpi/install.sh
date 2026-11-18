#!/bin/bash
# The folder "rpi" was renamed to "zr-ultra" and install.sh moved to the main folder (version 1.0.6).
# This small file only forwards an old update to the new place.
exec bash "$(cd "$(dirname "$0")/.." && pwd)/install.sh" "$@"
