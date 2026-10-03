#!/usr/bin/env bash
# GPU load in percent for the Waybar GPU module (Intel iGPU via nvtop's snapshot mode).
nvtop -s 2>/dev/null | jq -r '.[0].gpu_util // "0"' | tr -d '%'
