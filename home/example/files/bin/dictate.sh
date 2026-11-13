#!/usr/bin/env bash
# Voice typing, after Ryoku's offline dictation (Super+Alt+D): press once to
# start recording, again to stop; whisper.cpp turns the speech into text on
# this machine (Russian or English, detected) and types it where the cursor is.
# The model (~150 MB, multilingual "base") downloads on first use.
set -uo pipefail

dir="${XDG_DATA_HOME:-$HOME/.local/share}/whisper"
model="$dir/ggml-base.bin"
url="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin"
run="$XDG_RUNTIME_DIR/dictate"
wav="$run.wav"
note() { notify-send -a Dictation -i audio-input-microphone -h string:x-canonical-private-synchronous:dictate "$@"; }

if [[ -e "$run.pid" ]]; then
   kill -INT "$(cat "$run.pid")" 2>/dev/null
   rm -f "$run.pid"
   sleep 0.3
   note "Transcribing…"
   text=$(whisper-cli -m "$model" -l auto -nt -np -f "$wav" 2>/dev/null | tr -s ' \n' ' ' | sed 's/^ *//; s/ *$//')
   rm -f "$wav"
   if [[ -z "$text" ]]; then
      note "Nothing heard"
      exit 0
   fi
   wtype -- "$text"
   note "Typed" "$text"
   exit 0
fi

if [[ ! -s "$model" ]]; then
   mkdir -p "$dir"
   note "Downloading the speech model" "About 150 MB, only once."
   curl -fL --retry 3 -o "$model.part" "$url" && mv "$model.part" "$model" || {
      note "Model download failed" "Check the network and try again."
      exit 1
   }
fi

pw-record --rate 16000 --channels 1 --format s16 "$wav" &
echo $! > "$run.pid"
note "Listening…" "Super+Alt+D again to stop."
