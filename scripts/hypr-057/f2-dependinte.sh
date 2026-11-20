#!/bin/bash
# F2 (15 nov 2026): dependinte de compilare pt Hyprland 0.57 / gpu-screen-recorder / mpvpaper + copii .deb ale stack-ului
# Hyprland ACTUAL (pt revenire). NU instaleaza si NU schimba Hyprland-ul care ruleaza.
# Rulare: pkexec bash /home/mastermind/src/legion/hypr-057/f2-dependinte.sh
set -u
W=/home/mastermind/src/legion/hypr-057
S=$W/src
R=$W/rollback
die(){ echo "STOP: $*"; exit 1; }
[ "$(id -u)" = 0 ] || die "ruleaza cu pkexec"
export DEBIAN_FRONTEND=noninteractive
PKGS="hyprland-protocols hyprwire-scanner libcanberra-dev libeis-dev libhyprcursor-dev libhyprgraphics-dev libhyprlang-dev
      libhyprutils-dev libhyprwire-dev libpulse-dev libavfilter-dev libva-dev libmpv-dev libegl-dev dpkg-repack libjack-jackd2-dev"
LOCAL="$S/libaquamarine15_0.16.0-1+mgpuwait1_amd64.deb $S/libaquamarine-dev_0.16.0-1+mgpuwait1_amd64.deb"

# 1. garda: simularea ca root trebuie sa NU stearga nimic si sa NU atinga hyprland / libaquamarine13
apt-get -s install $PKGS $LOCAL > /tmp/f2-sim.txt 2>&1 || { cat /tmp/f2-sim.txt | tail -5; die "simularea a esuat"; }
grep -q '^Remv' /tmp/f2-sim.txt && { grep '^Remv' /tmp/f2-sim.txt; die "ar sterge pachete"; }
grep -E '^Inst (hyprland|hyprland-guiutils|libaquamarine13) ' /tmp/f2-sim.txt && die "ar atinge Hyprland-ul actual"
echo "== 1. simulare ok: $(grep -E '^[0-9]+ upgraded' /tmp/f2-sim.txt)"

# 2. copii .deb ale pachetelor actuale (revenire), cu dpkg-repack (instalat intai, singur)
mkdir -p "$R"; cd "$R"
dpkg -s dpkg-repack >/dev/null 2>&1 || apt-get install -y dpkg-repack >/dev/null || die "dpkg-repack"
for p in hyprland hyprland-guiutils libaquamarine13 libhyprutils13 libhyprutils-dev; do
    ls "$R"/${p}_*.deb >/dev/null 2>&1 || dpkg-repack "$p" >/dev/null 2>&1 && echo "   copie: $(ls "$R"/${p}_*.deb 2>/dev/null | xargs -n1 basename)"
done
dpkg-query -W -f='${Package}=${Version}\n' > "$R/pachete-inainte-f2.txt"
echo "== 2. copii in $R"

# 3. instalarea
apt-get install -y $PKGS $LOCAL 2>&1 | tail -4
dpkg -s libaquamarine15 libmpv-dev libhyprwire-dev >/dev/null 2>&1 || die "instalarea nu e completa"
chown -R 1000:1000 "$R"
echo "== 3. GATA. Hyprland ramane $(dpkg-query -W -f='${Version}' hyprland) (neschimbat). Spune-i lui Claude."
