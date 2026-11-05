#!/usr/bin/env python3
"""Build a Telegram Desktop theme accented by the current pywal palette.

Writes ~/.config/current/telegram/wal-<mode>.tdesktop-theme, where the mode
(dark or light) comes from theme-mode.sh. Telegram watches the theme file it
has applied and reloads it when the file changes, so once each file is applied
in the matching night-mode state the app follows wallpaper and mode changes on
its own. Keys left out keep Telegram's defaults, most of which point at the
base keys set here (windowBg, windowFg, windowBgActive, ...).
"""
import io
import json
import os
import struct
import sys
import zipfile
import zlib

PALETTE = os.path.expanduser("~/.cache/wal/colors.json")
MODE_FILE = os.path.expanduser("~/.config/current/theme-mode")
OUT_DIR = os.path.expanduser("~/.config/current/telegram")

# Telegram keeps neutral Day/Night surfaces; only small accent elements
# (badges, folder icons, checkmarks, links, send button, selection) take the
# wallpaper accent. ACCENT_STRENGTH: 0 is a grey accent, 1 the raw pywal one.
ACCENT_STRENGTH = {"dark": 0.85, "light": 0.85}
# Neutral surfaces, close to Telegram's own Night and Day themes.
NEUTRAL = {
    "dark": {"base": "#1e1e20", "side": "#18181a", "chat": "#121214", "in": "#2a2a2d", "fg": "#e8e8ea"},
    "light": {"base": "#ffffff", "side": "#f1f1f3", "chat": "#e7e8ea", "in": "#ffffff", "fg": "#1c1c1e"},
}


def rgb(h):
    h = h.lstrip("#")
    return [int(h[i:i + 2], 16) for i in (0, 2, 4)]


def mix(a, b, t):
    """Blend color a toward b by t (0..1)."""
    return "#" + "".join(f"{round(x + (y - x) * t):02x}" for x, y in zip(rgb(a), rgb(b)))


def alpha(c, a):
    return f"{c}{a:02x}"


def luminance(c):
    def channel(v):
        v /= 255
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = (channel(v) for v in rgb(c))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b):
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def legible(c, against, ratio, toward):
    """Move c toward `toward` until it reaches the contrast ratio against `against`."""
    for step in range(21):
        out = mix(c, toward, step / 20)
        if contrast(out, against) >= ratio:
            return out
    return toward


def on(c):
    """Black or white text, whichever reads better on c."""
    return "#ffffff" if contrast("#ffffff", c) >= contrast("#000000", c) else "#000000"


def png(color):
    """A 1x1 opaque PNG, used as the tiled chat background."""
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))
    raw = b"\x00" + bytes(rgb(color))
    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw))
            + chunk(b"IEND", b""))


def palette(pal, dark):
    c = pal["colors"]
    n = NEUTRAL["dark" if dark else "light"]
    strength = ACCENT_STRENGTH["dark" if dark else "light"]
    base, side, chat, fg = n["base"], n["side"], n["chat"], n["fg"]
    far = "#ffffff" if dark else "#000000"  # away from the background
    near = "#000000" if dark else "#ffffff"
    # Pull the (often neon) wallpaper accent toward grey by the knob.
    accent = mix(c["color4"], mix(base, fg, 0.5), 1 - strength)

    over = mix(base, fg, 0.06)
    ripple = mix(base, fg, 0.12)
    sub = mix(fg, base, 0.42)
    sub_over = mix(fg, base, 0.34)
    bold = mix(fg, far, 0.15)

    # Fills with white text on them: badges, send button, toggles.
    button = legible(accent, base, 2.5, far)
    if not dark:
        # Light accents are pale; darken buttons until white text reads on them.
        button = legible(button, "#ffffff", 4.0, "#000000")
    # Telegram's own themes put white text on buttons; keep it when it reads.
    button_fg = "#ffffff" if contrast("#ffffff", button) >= 4.0 else on(button)
    ink = accent
    text = legible(ink, base, 4.5, far)  # links, folder names, "Sticker" previews
    line = legible(accent, base, 3.0, far)
    icon = legible(mix(accent, sub, 0.35), side, 3.0, far)  # sidebar folder icons
    # Selected chat row: a light accent tint with normal text.
    selected = mix(base, accent, 0.22)
    selected_fg = legible(fg, selected, 7.0, far)
    selected_sub = legible(mix(fg, selected, 0.3), selected, 4.0, far)

    msg_in = n["in"]
    msg_out = mix(msg_in, accent, 0.10 if dark else 0.08)
    msg_in_sel = mix(msg_in, accent, 0.18)
    msg_out_sel = mix(msg_out, accent, 0.18)
    out_text = legible(ink, msg_out, 4.5, far)
    out_soft = legible(mix(fg, msg_out, 0.45), msg_out, 3.0, far)
    in_soft = legible(mix(fg, msg_in, 0.45), msg_in, 3.0, far)
    in_text = legible(ink, msg_in, 4.5, far)
    service = alpha(mix(chat, fg, 0.18), 0xc0)
    service_fg = on(service[:7])
    mono_in = legible(c["color2"], msg_in, 4.5, far)
    mono_out = legible(c["color2"], msg_out, 4.5, far)
    red = legible("#e05356", base, 3.5, far)
    green = legible("#4ab44a", base, 3.0, far)

    peers = ["#c03d33", "#4fad2d", "#d09306", None, "#8544d6", "#cd4073", "#2996ad", "#ce671b"]
    keys = {
        "windowBg": base,
        "windowFg": fg,
        "windowBgOver": over,
        "windowBgRipple": ripple,
        "windowSubTextFg": sub,
        "windowSubTextFgOver": sub_over,
        "windowBoldFg": bold,
        "windowBoldFgOver": bold,
        "windowBgActive": button,
        "windowFgActive": button_fg,
        "windowActiveTextFg": text,
        "windowShadowFg": "#000000",
        "windowShadowFgFallback": over,
        "shadowFg": alpha("#000000", 0x30 if dark else 0x18),
        "imageBgTransparent": "#ffffff",
        "activeButtonBgOver": mix(button, far, 0.10),
        "activeButtonBgRipple": mix(button, far, 0.20),
        "activeButtonSecondaryFg": mix(button_fg, button, 0.25),
        "activeLineFg": line,
        "activeLineFgError": red,
        "lightButtonBgOver": mix(base, accent, 0.12),
        "lightButtonBgRipple": mix(base, accent, 0.22),
        "attentionButtonFg": red,
        "attentionButtonFgOver": red,
        "attentionButtonBgOver": mix(base, red, 0.12),
        "attentionButtonBgRipple": mix(base, red, 0.22),
        "menuIconFg": sub,
        "menuIconFgOver": sub_over,
        "menuSubmenuArrowFg": sub,
        "menuFgDisabled": mix(fg, base, 0.6),
        "menuSeparatorFg": mix(base, fg, 0.10),
        "scrollBarBg": alpha(fg, 0x53),
        "scrollBarBgOver": alpha(fg, 0x7a),
        "scrollBg": alpha(fg, 0x1a),
        "scrollBgOver": alpha(fg, 0x2c),
        "smallCloseIconFg": mix(fg, base, 0.6),
        "smallCloseIconFgOver": sub,
        "placeholderFgActive": mix(fg, base, 0.55),
        "inputBorderFg": mix(base, fg, 0.20),
        "filterInputBorderFg": line,
        "filterInputInactiveBg": over,
        "checkboxFg": mix(fg, base, 0.5),
        "sliderBgInactive": mix(base, fg, 0.18),
        "tooltipBg": mix(base, fg, 0.10),
        "tooltipFg": fg,
        "tooltipBorderFg": mix(base, fg, 0.22),
        "titleShadow": alpha("#000000", 0x03),
        "titleBg": side,
        "titleFg": sub,
        "titleFgActive": fg,
        "titleButtonFg": sub,
        "titleButtonBgOver": mix(side, fg, 0.10),
        "titleButtonFgOver": fg,
        "boxTitleFg": bold,
        "boxTitleAdditionalFg": sub,
        "boxTextFgGood": green,
        "boxTextFgError": red,
        "boxDividerBg": mix(base, near, 0.25) if dark else side,
        "membersAboutLimitFg": sub_over,

        "dialogsBg": base,
        "dialogsBgOver": over,
        "dialogsBgActive": selected,
        "dialogsNameFgActive": selected_fg,
        "dialogsDateFgActive": selected_sub,
        "dialogsTextFgActive": selected_sub,
        "dialogsTextFgServiceActive": selected_fg,
        "dialogsSentIconFgActive": selected_fg,
        "dialogsUnreadBgActive": button,
        "dialogsUnreadFgActive": button_fg,
        "dialogsUnreadBgMutedActive": mix(selected_fg, selected, 0.45),
        "dialogsVerifiedIconBgActive": selected_fg,
        "dialogsVerifiedIconFgActive": selected,
        "dialogsNameFg": bold,
        "dialogsDraftFg": red,
        "dialogsSendingIconFg": sub,
        "dialogsSentIconFg": text,
        "dialogsSentIconFgOver": text,
        "dialogsUnreadBgMuted": mix(fg, base, 0.55),
        "dialogsArchiveFg": sub,
        "dialogsArchiveFgOver": sub_over,
        "dialogsOnlineBadgeFg": green,
        "dialogsDraftFgActive": legible(red, selected, 3.5, far),
        "dialogsSendingIconFgActive": selected_sub,
        "dialogsOnlineBadgeFgActive": selected_fg,
        "dialogsRippleBgActive": mix(selected, fg, 0.10),
        "dialogsMentionIconFg": button,
        "searchedBarBg": over,
        "searchedTextMatchBg": mix(base, c["color3"], 0.55),
        "searchedTextMatchFg": on(mix(base, c["color3"], 0.55)),
        "searchedTextCurrentMatchBg": mix(base, c["color1"], 0.75),
        "searchedTextCurrentMatchFg": on(mix(base, c["color1"], 0.75)),

        "sideBarBg": side,
        "sideBarBgActive": base,
        "sideBarBgRipple": mix(side, fg, 0.10),
        "sideBarTextFg": sub,
        "sideBarTextFgActive": text,
        "sideBarIconFg": icon,
        "sideBarIconFgActive": text,
        "sideBarBadgeBg": button,
        "sideBarBadgeBgMuted": mix(fg, side, 0.5),
        "sideBarBadgeFg": button_fg,

        "emojiPanBg": base,
        "emojiPanCategories": over,
        "emojiPanHeaderBg": alpha(base, 0xf2),
        "emojiIconFg": sub,
        "emojiSubIconFgActive": fg,
        "historyComposeIconFg": icon,
        "historyComposeIconFgOver": text,
        "historySendIconFg": text,
        "historySendIconFgOver": text,
        "stickerPreviewBg": alpha(base, 0xb0),

        "historyComposeAreaBg": base,
        "historyComposeAreaFg": fg,
        "historyComposeAreaFgService": sub,
        "historyComposeButtonBgOver": over,
        "historyComposeButtonBgRipple": ripple,
        "historyPinnedBg": base,
        "historyReplyBg": base,
        "historyToDownBg": base,
        "historyUnreadBarBg": over,
        "historyUnreadBarFg": text,
        "historyUnreadBarBorder": alpha("#000000", 0x20),
        "historyScrollBarBg": alpha(fg, 0x5a),
        "historyScrollBarBgOver": alpha(fg, 0x8a),
        "historyScrollBg": alpha(fg, 0x22),
        "historyScrollBgOver": alpha(fg, 0x34),
        "historyTextInFg": fg,
        "historyTextOutFg": fg,
        "historyLinkInFg": in_text,
        "historyLinkOutFg": out_text,
        "historyOutIconFg": out_text,
        "historyOutIconFgSelected": out_text,
        "historySendingOutIconFg": out_soft,
        "historySendingInIconFg": in_soft,
        "historyForwardChooseBg": alpha("#000000", 0x4c),
        "historyToDownShadow": alpha("#000000", 0x40),

        "msgInBg": msg_in,
        "msgInBgSelected": msg_in_sel,
        "msgOutBg": msg_out,
        "msgOutBgSelected": msg_out_sel,
        "msgSelectOverlay": alpha(accent, 0x4c),
        "msgStickerOverlay": alpha(accent, 0x7f),
        "msgInServiceFg": in_text,
        "msgInServiceFgSelected": in_text,
        "msgOutServiceFg": out_text,
        "msgOutServiceFgSelected": out_text,
        "msgInShadow": alpha("#000000", 0x40 if dark else 0x18),
        "msgInShadowSelected": alpha("#000000", 0x40 if dark else 0x18),
        "msgOutShadow": alpha("#000000", 0x40 if dark else 0x18),
        "msgOutShadowSelected": alpha("#000000", 0x40 if dark else 0x18),
        "msgInDateFg": in_soft,
        "msgInDateFgSelected": in_soft,
        "msgOutDateFg": out_soft,
        "msgOutDateFgSelected": out_soft,
        "msgServiceBg": service,
        "msgServiceBgSelected": alpha(mix(service[:7], accent, 0.3), 0xd0),
        "msgServiceFg": service_fg,
        "msgInReplyBarColor": in_text,
        "msgInReplyBarSelColor": in_text,
        "msgOutReplyBarColor": out_text,
        "msgOutReplyBarSelColor": out_text,
        "msgInMonoFg": mono_in,
        "msgOutMonoFg": mono_out,
        "msgFileInBg": button,
        "msgFileInBgOver": mix(button, far, 0.10),
        "msgFileInBgSelected": mix(button, accent, 0.3),
        "msgFileOutBg": out_text,
        "msgFileOutBgSelected": out_text,
        "historyFileOutIconFg": msg_out,
        "historyFileOutIconFgSelected": msg_out_sel,
        "msgFileThumbLinkInFg": in_text,
        "msgFileThumbLinkInFgSelected": in_text,
        "msgFileThumbLinkOutFg": out_text,
        "msgFileThumbLinkOutFgSelected": out_text,
        "msgWaveformInActive": in_text,
        "msgWaveformInActiveSelected": in_text,
        "msgWaveformInInactive": mix(msg_in, fg, 0.22),
        "msgWaveformInInactiveSelected": mix(msg_in_sel, fg, 0.22),
        "msgWaveformOutActive": out_text,
        "msgWaveformOutActiveSelected": out_text,
        "msgWaveformOutInactive": mix(msg_out, fg, 0.22),
        "msgWaveformOutInactiveSelected": mix(msg_out_sel, fg, 0.22),
        "msgBotKbOverBgAdd": alpha("#ffffff", 0x20),

        "overviewCheckBg": alpha("#000000", 0x40),
        "overviewPhotoSelectOverlay": alpha(accent, 0x33),
        "profileStatusFgOver": sub_over,
        "notificationSampleTextFg": mix(base, fg, 0.25),
        "notificationSampleNameFg": mix(base, fg, 0.45),
        "notificationSampleCloseFg": mix(base, fg, 0.25),
        "mainMenuCoverBg": side,
        "mainMenuCloudBg": button,
        "mediaPlayerDisabledFg": mix(button, base, 0.5),
        "mediaviewFileBg": base,
        "callBarBg": button,
        "callBarBgMuted": mix(fg, base, 0.5),
        "callBarFg": button_fg,
        "settingsIconFg": "#ffffff",
        "rankUserFg": sub,
        "currencyFg": text,
    }
    for i, hue in enumerate(peers, 1):
        if hue:
            keys[f"historyPeer{i}NameFg"] = legible(hue, msg_in, 4.0, far)
    return keys, chat


def main():
    if not os.path.isfile(PALETTE):
        return 0
    pal = json.load(open(PALETTE))
    try:
        mode = open(MODE_FILE).read().strip()
    except OSError:
        mode = "dark"
    mode = "light" if mode == "light" else "dark"
    # The mode names the file (Telegram's day or night slot); the colors
    # follow the palette itself, in case the two briefly disagree.
    keys, chat = palette(pal, dark=luminance(pal["special"]["background"]) < 0.4)

    colors = "// Generated by telegram-wal-theme.py from the pywal palette.\n"
    colors += "".join(f"{k}: {v};\n" for k, v in keys.items())
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as z:
        # Fixed timestamps: unchanged colors give identical bytes, and the
        # file is then left alone so Telegram does not reload for nothing.
        z.writestr(zipfile.ZipInfo("colors.tdesktop-theme", (2020, 1, 1, 0, 0, 0)), colors)
        z.writestr(zipfile.ZipInfo("tiled.png", (2020, 1, 1, 0, 0, 0)), png(chat))
    data = buf.getvalue()

    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, f"wal-{mode}.tdesktop-theme")
    try:
        if open(path, "rb").read() == data:
            return 0
    except OSError:
        pass
    # Atomic replace: Telegram's file watcher never sees a half-written zip.
    tmp = path + ".tmp"
    with open(tmp, "wb") as f:
        f.write(data)
    os.replace(tmp, path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
