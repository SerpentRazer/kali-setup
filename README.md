# kali-setup

Setup-ul meu de Kali Linux pe Lenovo Legion 5 17ITH6H (i7-11800H, RTX 3060 Laptop, NVIDIA 610), cu Samsung LC27RG50 240 Hz pe HDMI si dual boot Windows.
Repo PRIVAT, backup + documentatie. Fara secrete (verificat la urcare: chei, tokenuri, parole, email).

## Ce e aici

| Dosar | Continut |
|---|---|
| `config/` | `~/.config`: Hyprland 0.57 (config Lua), bara quickshell 43PR + patch-urile Kali (card vreme, tray, ws per monitor, Task Manager = btop...), kitty, btop, tema 43PR, rofi, Kvantum, wlogout, GTK, Spicetify |
| `home/` | `~/.zshrc` + scripturi din `~/.local/bin` (cs2-perf, game-perf) |
| `scripts/` | `~/src/legion`: scripturi de update sigur, merge-uri tema 43PR (port_bar*.py, migrari, teste izolate), build Hyprland 0.57 + patch aquamarine mgpuwait, audit de securitate, fix-uri CS2/GPU/GPT |
| `system/` | copii de referinta din `/etc` si `/usr/local/sbin`: fstab, GRUB, nftables (firewall), sysctl, zram, udev, modprobe NVIDIA, servicii systemd proprii, tema SDDM cyberglass |
| `docs/` | notitele detaliate pe subiecte (ce s-a facut, de ce, capcane, cum se revine) — incepe cu `MEMORY.md` |

## Restaurare (pe scurt)
1. `config/*` -> `~/.config/`, `home/.zshrc` -> `~/`, `home/bin/*` -> `~/.local/bin/` (pastreaza bitii +x: `cp -a`).
2. `system/` se aplica manual, fisier cu fisier (pkexec), dupa ce citesti nota din `docs/` despre el — unele depind de UUID-urile partitiilor (fstab) sau de hardware.
3. Hyprland 0.57 + aquamarine cu patch: `scripts/hypr-057/` (f2 dependinte -> f3 compilare -> f4 instalare).

Nu sunt incluse: wallpapere video (mari), istoricul shell, profilele de browser, cheile (ssh, KDE Connect), `~/.claude`.
