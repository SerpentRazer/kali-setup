#!/bin/bash
# Audit de securitate 20 nov 2026 — reparatiile alese de user: firewall, xrdp oprit, kernel hardening, docker oprit la boot.
# Backup + revino.sh. Firewall-ul se testeaza imediat (DNS + HTTPS); daca netul nu merge, se scoate singur.
# Rulare:  pkexec bash /home/mastermind/src/legion/audit-securitate-2026-11-20/repara.sh
set -u
[ "$(id -u)" = 0 ] || { echo "ruleaza cu pkexec"; exit 1; }
U=mastermind
B=/home/$U/.config-backups/pre-securitate-$(date +%F_%H-%M-%S); mkdir -p "$B"
exec > >(tee -a "$B/log.txt") 2>&1
KEYS="kernel.kptr_restrict kernel.dmesg_restrict kernel.yama.ptrace_scope kernel.sysrq fs.suid_dumpable net.ipv4.ip_forward
 net.ipv4.conf.all.send_redirects net.ipv4.conf.default.send_redirects net.ipv4.conf.all.accept_redirects
 net.ipv4.conf.default.accept_redirects net.ipv6.conf.all.accept_redirects net.ipv6.conf.default.accept_redirects
 net.ipv4.conf.all.accept_source_route net.ipv4.conf.default.accept_source_route net.ipv4.conf.all.rp_filter net.ipv4.conf.default.rp_filter"

echo "== 0. backup in $B"
cp -a /etc/nftables.conf "$B/" 2>/dev/null
cp -a /etc/xrdp/sesman.ini "$B/" 2>/dev/null
for k in $KEYS; do echo "$k = $(sysctl -n $k)"; done > "$B/sysctl-inainte.conf"
for s in nftables xrdp xrdp-sesman docker.service docker.socket containerd; do
    echo "$s $(systemctl is-enabled $s 2>/dev/null) $(systemctl is-active $s 2>/dev/null)"; done > "$B/servicii-inainte.txt"
cat > "$B/revino.sh" <<EOF
#!/bin/bash
# Revine la starea de dinainte de reparatiile de securitate din $(date '+%d %b %H:%M'). Rulare: pkexec bash $B/revino.sh
[ "\$(id -u)" = 0 ] || { echo "ruleaza cu pkexec"; exit 1; }
nft delete table inet kali_fw 2>/dev/null
cp -a "$B/nftables.conf" /etc/nftables.conf
cp -a "$B/sesman.ini" /etc/xrdp/sesman.ini
rm -f /etc/sysctl.d/99-securitate.conf; sysctl -q -p "$B/sysctl-inainte.conf"
while read -r s en ac; do
    [ "\$en" = enabled ] && systemctl enable "\$s" 2>/dev/null; [ "\$en" = disabled ] && systemctl disable "\$s" 2>/dev/null
    [ "\$ac" = active ] && systemctl start "\$s" 2>/dev/null; [ "\$ac" = inactive ] && systemctl stop "\$s" 2>/dev/null
done < "$B/servicii-inainte.txt"
echo "revenit (firewall scos, xrdp/docker si sysctl ca inainte)"
EOF
chmod +x "$B/revino.sh"

echo "== 1. firewall nftables (tabel propriu inet kali_fw; NU atinge regulile Docker, deci fara 'flush ruleset')"
cat > /etc/nftables.conf <<'EOF'
#!/usr/sbin/nft -f
# Kali (20 nov 2026, audit de securitate): blocheaza tot ce INTRA nesolicitat, permite tot ce IESE.
# Tabel propriu, fara "flush ruleset" -> regulile Docker / Tailscale raman neatinse.
# Revenire: pkexec bash ~/.config-backups/pre-securitate-*/revino.sh
# De deschis la nevoie: Tailscale -> iifname "tailscale0" accept + udp dport 41641 accept;
#   Steam Remote Play -> udp dport 27031-27036 + tcp dport 27036-27037; KDE Connect -> tcp/udp dport 1714-1764.
table inet kali_fw
delete table inet kali_fw
table inet kali_fw {
    chain input {
        type filter hook input priority filter; policy drop;
        ct state invalid drop
        ct state established,related accept
        iif "lo" accept
        iifname "docker0" accept                                   # containere / VM-uri locale catre host
        iifname "br-*" accept
        iifname "vboxnet*" accept
        meta l4proto ipv6-icmp accept                              # IPv6 (neighbor discovery, RA) nu merge fara
        icmp type { destination-unreachable, time-exceeded, parameter-problem } accept
        udp sport 67 udp dport 68 accept                           # raspunsuri DHCP (IP de la router)
        udp sport 547 udp dport 546 accept                         # DHCPv6
        counter comment "aruncate"
    }
}
EOF
nft -c -f /etc/nftables.conf || { echo "STOP: regulile nu trec verificarea"; cp -a "$B/nftables.conf" /etc/nftables.conf; exit 1; }
nft -f /etc/nftables.conf
systemctl enable nftables >/dev/null 2>&1
sleep 1
if getent hosts deb.debian.org >/dev/null && timeout 10 bash -c 'exec 3<>/dev/tcp/deb.debian.org/443' 2>/dev/null; then
    echo "   firewall activ, internetul merge (DNS + HTTPS ok)"
else
    echo "   ATENTIE: internetul nu raspunde cu firewall-ul -> il scot"; nft delete table inet kali_fw
    cp -a "$B/nftables.conf" /etc/nftables.conf; systemctl disable nftables >/dev/null 2>&1
fi

echo "== 2. xrdp (Remote Desktop) oprit + fara logare root"
systemctl disable --now xrdp xrdp-sesman 2>&1 | grep -v '^Synchronizing\|^Executing' | tail -2
sed -i 's/^AllowRootLogin=true/AllowRootLogin=false/' /etc/xrdp/sesman.ini

echo "== 3. kernel hardening (sysctl)"
cat > /etc/sysctl.d/99-securitate.conf <<'EOF'
# Kali (20 nov 2026, audit de securitate). Revenire: revino.sh din ~/.config-backups/pre-securitate-*
kernel.kptr_restrict = 1                 # adresele kernelului ascunse userilor (ajuta exploit-urile)
kernel.dmesg_restrict = 1                # dmesg doar root (journalctl -k merge in continuare, esti in grupul adm)
kernel.yama.ptrace_scope = 1             # un program poate citi memoria doar a copiilor lui (ca Ubuntu)
kernel.sysrq = 176                       # SysRq doar sync + remount-ro + reboot (inainte: toate, 1 din 70-cachy-bazzite)
fs.suid_dumpable = 0                     # fara core dump-uri din programe SUID
net.ipv4.ip_forward = 0                  # laptopul nu ruteaza (Docker il porneste singur cand il pornesti)
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.rp_filter = 2          # anti-spoofing, modul "loose" (merge cu VPN / Tailscale / Docker)
net.ipv4.conf.default.rp_filter = 2
EOF
sysctl -q -p /etc/sysctl.d/99-securitate.conf && echo "   aplicat"

echo "== 4. Docker oprit la boot (pornire manuala: pkexec systemctl start docker)"
systemctl disable --now docker.service docker.socket containerd.service 2>&1 | grep -v '^Synchronizing\|^Executing' | tail -3

echo "== 5. verificare"
for s in nftables xrdp xrdp-sesman docker.service docker.socket containerd; do
    printf '   %-15s %-9s %s\n' "$s" "$(systemctl is-enabled $s 2>/dev/null)" "$(systemctl is-active $s 2>/dev/null)"; done
echo "   porturi deschise catre exterior:"; ss -tulnH | awk '$5 !~ /^(127\.|\[::1\]|::1)/ {print "     " $1, $5}' | sort -u
nft list table inet kali_fw >/dev/null 2>&1 && echo "   firewall: ACTIV (policy drop pe input)"
for k in kernel.kptr_restrict kernel.dmesg_restrict kernel.yama.ptrace_scope kernel.sysrq fs.suid_dumpable net.ipv4.ip_forward; do
    echo "   $k = $(sysctl -n $k)"; done
chown -R $U:$U "$B"
echo
echo "GATA. Revenire: pkexec bash $B/revino.sh"
