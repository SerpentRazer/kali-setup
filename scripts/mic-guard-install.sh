#!/bin/bash
# Instaleaza mic-guard (serviciu systemd --user): daca o aplicatie (AGC din Steam/Discord) urca microfonul intern peste 40%,
# il readuce la 20% si noteaza in jurnal cine inregistra (journalctl --user -t mic-guard). Intre 20-40% nu se atinge.
# Instalare: bash ~/src/legion/mic-guard-install.sh      Dezinstalare: bash ~/src/legion/mic-guard-install.sh scoate
set -u
if [ "${1:-}" = scoate ]; then
    systemctl --user disable --now mic-guard.service 2>/dev/null
    rm -f ~/.local/bin/mic-guard ~/.config/systemd/user/mic-guard.service; systemctl --user daemon-reload; echo "mic-guard scos"; exit 0
fi
mkdir -p ~/.local/bin ~/.config/systemd/user
cat > ~/.local/bin/mic-guard <<'EOF'
#!/bin/bash
# mic-guard (1 nov 2026): DMIC-ul laptopului suna bine la 20%; peste ~40% intra boost-ul analogic (100% = +60 dB = sasait).
SRC=alsa_input.pci-0000_00_1f.3.analog-stereo; WANT=20; MAX=40
fix() {
    local v; v=$(pactl get-source-volume "$SRC" 2>/dev/null | grep -o '[0-9]*%' | head -1 | tr -d %)
    [ -n "$v" ] && [ "$v" -gt "$MAX" ] || return 0
    pactl set-source-volume "$SRC" "${WANT}%"
    logger -t mic-guard "microfon $v% -> $WANT% (inregistrau: $(pactl list source-outputs 2>/dev/null | grep -oP 'application.name = "\K[^"]+' | sort -u | paste -sd,))"
}
fix
pactl subscribe | while read -r line; do case "$line" in *"on source #"*) fix;; esac; done
EOF
chmod +x ~/.local/bin/mic-guard
cat > ~/.config/systemd/user/mic-guard.service <<'EOF'
[Unit]
Description=Tine microfonul intern sub 40% (AGC-ul din Steam/Discord il urca la 100%)
After=pipewire-pulse.service wireplumber.service

[Service]
ExecStart=%h/.local/bin/mic-guard
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOF
systemctl --user daemon-reload && systemctl --user enable --now mic-guard.service
sleep 1; echo "mic-guard: $(systemctl --user is-active mic-guard)"
SRC=alsa_input.pci-0000_00_1f.3.analog-stereo
pactl set-source-volume $SRC 100%; sleep 1
echo "test: urcat la 100% -> dupa 1 s: $(pactl get-source-volume $SRC | grep -o '[0-9]*%' | head -1) (trebuie 20%)"
