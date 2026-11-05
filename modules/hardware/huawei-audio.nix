# Huawei MateBook with the SN6140 codec: its speakers hang off the
# Headphone DAC. Off by default; turn on with huaweiAudio in local/settings.nix.
{ lib, pkgs, settings, ... }:
let
  # SN6140 on this MateBook feeds the speakers through the Headphone DAC.
  # Correct the UCM control mapping only for this codec/subsystem ID.
  ucm = pkgs.runCommand "alsa-ucm-huawei-sn6140" { nativeBuildInputs = [ pkgs.python3 ]; } ''
    cp -r ${pkgs.alsa-ucm-conf}/share/alsa/ucm2 "$out"
    chmod -R u+w "$out"
    python3 - "$out/HDA/HiFi-analog.conf" <<'PY'
import sys
from pathlib import Path
p = Path(sys.argv[1])
s = p.read_text()
# Upstream picks the speaker control through spkvol. Point it at the Headphone
# DAC right before the Speaker device is declared, so PipeWire's volume, mute
# and the enable sequence drive the DAC that is actually wired to the speakers.
# Fail the build if upstream moves this block, instead of silently not patching.
anchor = 'If.spk {\n\tCondition {\n\t\tType String\n\t\tEmpty "\u0024{var:spkvol}"'
if s.count(anchor) != 1:
    sys.exit("HDA/HiFi-analog.conf changed upstream; update huawei-audio.nix")
override = """If.huawei_sn6140 {
\tCondition {
\t\tType RegexMatch
\t\tRegex "HDA:14f11f87,19e53291,"
\t\tString "\u0024{CardComponents}"
\t}
\tTrue.Define.spkvol "Headphone"
}

"""
p.write_text(s.replace(anchor, override + anchor))
PY
  '';
in lib.mkIf settings.huaweiAudio {
  systemd.user.services.wireplumber.environment.ALSA_CONFIG_UCM2 = "${ucm}";
  systemd.user.services.pipewire.environment.ALSA_CONFIG_UCM2 = "${ucm}";
}
