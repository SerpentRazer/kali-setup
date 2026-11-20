#!/bin/bash
# F3 (15 nov 2026): compileaza Hyprland 0.57 (.deb), gpu-screen-recorder 5.13.8 (.deb) si mpvpaper 1.9 (local, in build/).
# Ca user normal, FARA root; NU instaleaza nimic. Dureaza ~10-20 min (Hyprland e mare). Log-uri in src/build-*.log.
# Rulare: bash ~/src/legion/hypr-057/f3-compileaza.sh
set -u
S=/home/mastermind/src/legion/hypr-057/src
cd "$S" || exit 1
J=$(nproc)
ok(){ grep -q "^rc=0" "$1" && echo "  OK" || { echo "  ESUAT — ultimele linii:"; tail -n 15 "$1"; }; }

echo "== 1/3 Hyprland 0.57.0 (cel mai lung)"
(cd hyprland-0.57.0+ds && DEB_BUILD_OPTIONS="nocheck parallel=$J" nice dpkg-buildpackage -us -uc -b > ../build-hyprland.log 2>&1; echo "rc=$?" >> ../build-hyprland.log)
ok build-hyprland.log

echo "== 2/3 gpu-screen-recorder 5.13.8"
(cd gpu-screen-recorder-5.13.8 && DEB_BUILD_OPTIONS="nocheck parallel=$J" nice dpkg-buildpackage -us -uc -b > ../build-gsr.log 2>&1; echo "rc=$?" >> ../build-gsr.log)
ok build-gsr.log

echo "== 3/3 mpvpaper 1.9"
(cd mpvpaper-1.9 && rm -rf build && meson setup build --prefix=/home/mastermind/.local --buildtype=release > ../build-mpvpaper.log 2>&1 && nice ninja -C build >> ../build-mpvpaper.log 2>&1; echo "rc=$?" >> ../build-mpvpaper.log)
ok build-mpvpaper.log

echo; ls -1 "$S"/*.deb | grep -v dbgsym | xargs -n1 basename
echo "GATA. Spune-i lui Claude."
