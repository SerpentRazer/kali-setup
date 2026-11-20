---
name: security-audit-2026-11-20
description: Security audit of the Kali laptop started 20 nov 2026 (skills mukul975/Anthropic-Cybersecurity-Skills); findings, runZero removed, phase 2 pending
metadata:
  type: project
---
Cerut de user 20 nov 2026 cu lista de skill-uri https://github.com/mukul975/Anthropic-Cybersecurity-Skills (817 skill-uri; folosite:
hardening-linux-endpoint-with-cis-benchmark, analyzing-persistence-mechanisms-in-linux, hunting-for-unusual-network-connections,
detecting-privilege-escalation-attempts, detecting-rootkit-activity, implementing-secret-scanning-with-gitleaks). Dosar: ~/src/legion/audit-securitate-2026-11-20.

Faza 1 (fara root) — gasit: xrdp pe *:3389 enabled + AllowRootLogin=true; NICIUN firewall (ufw/nft lipsa); parola contului
scrisa in chat + 1x in ~/.zsh_history (de schimbat cu passwd, de scos din istoric); disc Kali necriptat, Secure Boot oprit;
fara blocare la inactivitate (hypridle nu ruleaza); 343 update-uri (liste din 14 nov; kernel 7.2, xrdp); sysctl permisive Kali
(ptrace_scope 0, kptr/dmesg_restrict 0, sysrq 1, ip_forward 1 de la docker); docker+containerd mereu pornite; tailscaled
enabled dar delogat; Steam 27036 pe 0.0.0.0. OK: ssh oprit, fara authorized_keys, fara SUID straine, fara ld.so.preload.
Fals pozitiv: lock_password in 43pr/themes/*.toml = culoare. Secret real de exclus la GitHub: ~/.config/kdeconnect/privateKey.pem.
Capabilities de stiut: gsr-kms-server cap_sys_admin (pus de noi 15 nov), nmap/dumpcap cap_net_raw (Kali).

**runZero agent STERS 20 nov 20:07** (cerut: „runZero kill”; instalat 17 iul 2025, root, raporta la console.runzero.com org
0a29466a-...); dovezi in ~/.config-backups/runzero-sters-2026-11-20_20-07-40. Verificat: 0 procese, 0 unitati, /opt/runzero lipsa.

Faza 2 (root, 20:1x): lynis 66/100, 0 warnings, 46 sugestii; chkrootkit/rkhunter = doar fals pozitive (dotfiles din pachete,
/dev/shm Steam/Brave, NetworkManager „sniffer” = DHCP, „Xor.DDoS” = scripturi .sh din scratchpad /tmp); debsums = kitty (patch
scroll) + Spotify (Spicetify) + doc nvidia. xrdp: 0 conexiuni in 60 zile. root L, postgres L. NICIO urma de compromitere.
Scannere instalate (--no-install-recommends; altfel rkhunter aduce exim4).

**REPARATII APLICATE 20 nov 20:17** (alese de user; revino: pkexec bash ~/.config-backups/pre-securitate-2026-11-20_20-17-59/revino.sh):
- firewall nftables, tabel propriu `inet kali_fw` in /etc/nftables.conf (FARA flush ruleset -> Docker neatins), input policy drop,
  accept established/lo/docker0/br-*/vboxnet*/ICMPv6/DHCP; nftables enabled. Internet verificat (HTTP 200). User: exceptii = NICIUNA
  (Tailscale/Steam Remote Play/KDE Connect blocate la intrare; liniile de deschis comentate in fisier). Testat in `unshare -rn` inainte.
- xrdp + xrdp-sesman disabled/stopped, AllowRootLogin=false.
- /etc/sysctl.d/99-securitate.conf: kptr_restrict 1, dmesg_restrict 1, ptrace_scope 1, sysrq 176, suid_dumpable 0, ip_forward 0,
  redirects 0, source_route 0, rp_filter 2 (loose).
- docker.service/socket + containerd disabled (pornire: pkexec systemctl start docker).
- parola scoasa din ~/.zsh_history (python, 1 linie). User trebuie sa ruleze `passwd` in kitty (NECONFIRMAT).
- Blocare ecran automata: userul a zis NU.
Ramase/informativ: disc necriptat, Secure Boot oprit (NVIDIA DKMS => MOK), 343 update-uri (kernel 7.2 + NVIDIA 610 DKMS de verificat),
GRUB fara parola, atftpd instalat, ip_unprivileged_port_start=0 (Kali), gvfsd-wsdd asculta 3702 (retea Dolphin; blocat de firewall).
**Parola veche apare si in jurnalele Claude (~/.claude/projects/*.jsonl) -> ~/.claude EXCLUS la GitHub.**
**Why:** userul vrea sistemul curat inainte de [[kali-github-backup-wish]]. **How to apply:** reparatiile prin scripturi pkexec cu backup/revino;
NU inchide xrdp/docker fara sa intrebi daca le foloseste; capcana `pgrep -af` prinde propriul shell/script (foloseste ps -eo comm).
