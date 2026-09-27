#!/usr/bin/env bash
cfg="$1"
limit=${CAVA_SILENCE_FRAMES:-100} # ~0.5s at 60 FPS
silence=0
last=""

cava -p "$cfg" | while read -r line; do
   clean="${line//;/}"
   if [[ "${clean//0/}" == "" ]]; then
      ((silence++))
      if ((silence >= limit)); then
         printf '{"text":"","class":"silent"}\n'
      else
         printf '{"text":"%s","class":"active idle"}\n' "$last"
      fi
   else
      silence=0
      # Map the configured 0..90 range to standard Unicode bars.
      last=""
      IFS=';' read -r -a values <<< "$line"
      glyphs=(' ' '▁' '▂' '▃' '▄' '▅' '▆' '▇' '█')
      for value in "${values[@]}"; do
         [[ "$value" =~ ^[0-9]+$ ]] || continue
         level=$(( (10#$value * 8 + 89) / 90 ))
         ((level > 8)) && level=8
         last+="${glyphs[level]}"
      done
      printf '{"text":"%s","class":"active"}\n' "$last"
   fi
done
