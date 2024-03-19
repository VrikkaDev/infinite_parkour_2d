#!/bin/sh
echo -ne '\033c\033]0;infinite_parkour\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/infinite_parkour_server.x86_64" "$@"
