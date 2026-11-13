#!/usr/bin/env bash
# Capture tool (Super+Shift+S): screenshots, annotation, colour picker, OCR,
# QR codes and screen recording, after Ryoku's ryoshot.
#   capture.sh            menu
#   capture.sh <action>   run one action directly (see the list below)
set -uo pipefail

shots="$HOME/Pictures/Screenshots"
videos="$HOME/Videos/Recordings"
stamp() { date +%Y-%m-%d_%H-%M-%S; }
note() { notify-send -a Capture -i "${3:-camera-photo}" "$1" "${2:-}"; }
area() { slurp -d -b '#00000066' -c '#e2b26aff' -w 2; }

record_stop() {
   if pkill -INT -x wf-recorder; then
      note "Recording saved" "$(cat "$XDG_RUNTIME_DIR/capture-recording" 2>/dev/null)" media-record
      rm -f "$XDG_RUNTIME_DIR/capture-recording"
      pkill -RTMIN+9 waybar
      return 0
   fi
   return 1
}

record_start() {
   mkdir -p "$videos"
   local file="$videos/$(stamp).mp4" geometry=()
   if [[ "$1" == area ]]; then
      local g
      g=$(area) || exit 0
      geometry=(-g "$g")
   fi
   printf '%s\n' "$file" > "$XDG_RUNTIME_DIR/capture-recording"
   wf-recorder "${geometry[@]}" -f "$file" ${2:+--audio} >/dev/null 2>&1 &
   disown
   pkill -RTMIN+9 waybar
   note "Recording" "Super+Shift+S again (or Super+Alt+R) stops it" media-record
}

run() {
   case "$1" in
      area-copy)
         g=$(area) || exit 0
         grim -g "$g" - | wl-copy --type image/png && note "Area copied" ;;
      area-edit)
         g=$(area) || exit 0
         mkdir -p "$shots"
         grim -g "$g" - | satty --filename - --output-filename "$shots/$(stamp).png" \
            --copy-command wl-copy --early-exit --actions-on-enter save-to-clipboard ;;
      window)
         g=$(hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
         mkdir -p "$shots"
         f="$shots/$(stamp).png"
         grim -g "$g" "$f" && wl-copy --type image/png < "$f" && note "Window saved" "$f" ;;
      screen)
         mkdir -p "$shots"
         f="$shots/$(stamp).png"
         grim "$f" && wl-copy --type image/png < "$f" && note "Screen saved" "$f" ;;
      color)
         c=$(hyprpicker -a -f hex) && [[ -n "$c" ]] && note "Colour copied" "$c" color-select ;;
      ocr)
         g=$(area) || exit 0
         t=$(grim -g "$g" - | tesseract -l eng+rus - - 2>/dev/null)
         [[ -n "${t//[[:space:]]/}" ]] || { note "No text found"; exit 0; }
         printf '%s' "$t" | wl-copy && note "Text copied" "$(head -c 160 <<<"$t")" accessories-text-editor ;;
      qr)
         g=$(area) || exit 0
         q=$(grim -g "$g" - | zbarimg -q --raw - 2>/dev/null)
         [[ -n "$q" ]] || { note "No QR code found"; exit 0; }
         printf '%s' "$q" | wl-copy && note "QR copied" "$q" ;;
      record-area) record_stop || record_start area ;;
      record-screen) record_stop || record_start screen ;;
      record-screen-audio) record_stop || record_start screen audio ;;
      record-stop) record_stop || note "Nothing is recording" ;;
      *) echo "unknown action: $1" >&2; exit 2 ;;
   esac
}

if [[ -n "${1:-}" ]]; then
   run "$1"
   exit
fi

# A running recording turns the menu into a stop button.
record_stop && exit 0

pkill -x rofi && exit 0
choice=$(printf '%s\n' \
   "󰩬  Area → clipboard" \
   "󰏫  Area → edit and save" \
   "󰖯  Window → file" \
   "󰍹  Screen → file" \
   "󰈊  Pick a colour" \
   "󰊄  Text from area (OCR)" \
   "󰐲  QR code from area" \
   "󰑋  Record area" \
   "󰑊  Record screen" \
   "󰕾  Record screen with sound" |
   rofi -dmenu -i -p "" -mesg "Capture" -no-custom) || exit 0

case "$choice" in
   *"Area → clipboard"*) action=area-copy ;;
   *"Area → edit"*) action=area-edit ;;
   *Window*) action=window ;;
   *"Screen → file"*) action=screen ;;
   *colour*) action=color ;;
   *OCR*) action=ocr ;;
   *QR*) action=qr ;;
   *"Record area"*) action=record-area ;;
   *"with sound"*) action=record-screen-audio ;;
   *"Record screen"*) action=record-screen ;;
   *) exit 0 ;;
esac
# Let rofi close before grabbing the screen.
sleep 0.2
run "$action"
