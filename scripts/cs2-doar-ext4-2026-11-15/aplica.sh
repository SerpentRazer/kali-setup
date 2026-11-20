#!/bin/bash
# CS2 pe Kali DOAR de pe ext4 (/mnt/games), Windows ramane cu copia lui de pe C:. 15 nov 2026.
# Problema: Windows Steam a actualizat CS2 pe C:; Steam de pe Kali a vazut appmanifest_730.acf pe C: si a rulat jocul de pe
# NTFS (ntfs-3g) -> lag. Fix: pe Linux, peste manifestul de pe C: se monteaza (bind, read-only) un fisier GOL. Steam-ul de pe
# Kali nu mai vede CS2 pe C: si foloseste /mnt/games; Windows vede fisierul real (bind-ul exista doar in Linux, nimic scris pe C:).
# Rulare (cu Steam INCHIS): pkexec bash /home/mastermind/src/legion/cs2-doar-ext4-2026-11-15/aplica.sh
set -u
T='/mnt/windows/Program Files (x86)/Steam/steamapps/appmanifest_730.acf'
T_FSTAB='/mnt/windows/Program\040Files\040(x86)/Steam/steamapps/appmanifest_730.acf'
G=/etc/steam-ascuns/appmanifest-gol.acf
die(){ echo "STOP: $*"; exit 1; }
[ "$(id -u)" = 0 ] || die "ruleaza cu pkexec"
pgrep -x steam >/dev/null && die "inchide Steam intai (Steam -> Exit), apoi ruleaza din nou"
[ -f "$T" ] || die "nu gasesc manifestul CS2 de pe C:"
[ -f /mnt/games/SteamLibrary/steamapps/appmanifest_730.acf ] || die "nu gasesc CS2 pe /mnt/games"
B=/home/mastermind/.config-backups/pre-cs2-ext4-$(date +%F_%H-%M-%S); mkdir -p "$B"
cp -p /etc/fstab "$B/fstab"
install -d -m 755 /etc/steam-ascuns
: > "$G"; chmod 644 "$G"
if ! grep -qF "$G" /etc/fstab; then
    printf '%s\n' "# CS2-DOAR-EXT4 (15 nov 2026): Kali nu vede copia CS2 de pe C: (a Windows-ului) -> joaca de pe /mnt/games. ~/src/legion/cs2-doar-ext4-2026-11-15" \
        "$G  $T_FSTAB  none  bind,ro,nofail,x-systemd.requires=/mnt/windows  0  0" >> /etc/fstab
fi
systemctl daemon-reload
mountpoint -q "$T" || { mount --bind "$G" "$T" && mount -o remount,bind,ro "$T"; } || die "bind esuat"
[ "$(wc -c < "$T")" = 0 ] || die "manifestul inca se vede"
cat > "$B/revino.sh" <<R
#!/bin/sh
umount '$T' 2>/dev/null; cp -p '$B/fstab' /etc/fstab && systemctl daemon-reload && echo revenit
R
chown -R 1000:1000 "$B"; chmod 755 "$B/revino.sh"
echo "GATA. Pe Kali manifestul CS2 de pe C: e gol (Windows nu e afectat). Backup + revino.sh: $B"
echo "Porneste Steam: CS2 va fi pe biblioteca 'Kali games (ext4)' si isi descarca update-ul acolo."
