#!/bin/bash
# Repara tabela GPT de pe /dev/nvme0n1 (3 nov 2026).
#
# Cauza: header-ul GPT spune ca tabela principala sta la sectorul 2016, dar Windows (Shrink pe 1 nov,
# update WinRE pe 2 nov 21:52) o scrie la sectorul 2. La 2016 ramane o tabela veche -> CRC gresit ->
# kernelul Linux respinge tot discul (fara parametrul `gpt` nu incearca backup-ul) -> nu gaseste root.
#
# Reparatia = `sgdisk -j 2`: header-ul arata spre sectorul 2, unde Windows scrie oricum. Testata pe o
# copie a discului: schimba DOAR sectorul 1 si ultimul sector (cele 2 header-e), tabelele raman identice.
#
# Plasa de siguranta: parametrul kernel `gpt` (daca tabela principala se strica iar din alt motiv,
# Linux foloseste backup-ul si porneste, in loc sa ramana in initramfs).
#
# Rulare: pkexec /bin/bash ~/src/legion/gpt-fix-2026-11-03/repara-gpt.sh
# Test pe copie (fara root, fara GRUB): TEST_IMG=/cale/disc.img bash repara-gpt.sh
set -u
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
REF=/mnt/stuff/gpt-2026-11-03                       # copia discului analizata (citita azi 21:39)
EXP=/home/mastermind/src/legion/gpt-fix-2026-11-03  # rezultatul asteptat (din simulare)
die(){ echo; echo "STOP: $*"; echo "Nu reporni. Spune-i lui Claude ce scrie mai sus."; exit 1; }

if [ -n "${TEST_IMG:-}" ]; then
    D=$TEST_IMG; N=$(( $(stat -c %s "$D") / 512 ))
    B=$(dirname "$D")/test-backup; mkdir -p "$B"
else
    [ "$(id -u)" = 0 ] || die "ruleaza cu: pkexec /bin/bash $0"
    D=/dev/nvme0n1; N=$(blockdev --getsz $D)
    B=/home/mastermind/.config-backups/pre-gpt-fix-$(date +%F_%H-%M-%S); mkdir -p "$B"
fi
exec > >(tee -a "$B/log.txt") 2>&1
echo "== disc $D, $N sectoare, backup in $B"

# 1. Discul trebuie sa fie exact cel analizat si testat
[ "$N" = "$(cat $REF/sectors.txt)" ] || die "alt numar de sectoare decat la analiza"
dd if="$D" bs=512 count=2048 status=none | cmp -s - $REF/nvme-head.img \
    || die "inceputul discului s-a schimbat de la analiza - nu scriu nimic"
dd if="$D" bs=512 skip=$((N-33)) count=33 status=none | cmp -s - $REF/nvme-tail.img \
    || die "finalul discului s-a schimbat de la analiza - nu scriu nimic"
cp -p $REF/nvme-head.img $REF/nvme-tail.img $REF/gpt.bin "$B/"
echo "== 1. disc identic cu copia testata, copia salvata si in $B: ok"

# 2. Reparatia
echo "== 2. sgdisk -j 2"
sgdisk -j 2 "$D"; rc=$?
[ $rc = 0 ] || die "sgdisk a iesit cu codul $rc"
sync

# 3. Verificare: discul trebuie sa fie byte cu byte rezultatul simularii
dd if="$D" bs=512 count=2048 status=none | cmp -s - $EXP/asteptat-head.img \
    || die "inceputul discului NU e cel asteptat (copia de dinainte e in $B)"
dd if="$D" bs=512 skip=$((N-33)) count=33 status=none | cmp -s - $EXP/asteptat-tail.img \
    || die "finalul discului NU e cel asteptat (copia de dinainte e in $B)"
sgdisk -v "$D" > "$B/sgdisk-v-dupa.txt" 2>&1
grep -q 'No problems found' "$B/sgdisk-v-dupa.txt" || { cat "$B/sgdisk-v-dupa.txt"; die "sgdisk -v inca vede probleme"; }
echo "== 3. disc = exact rezultatul testat; sgdisk -v: No problems found: ok"
sgdisk -p "$D" | tail -12

[ -n "${TEST_IMG:-}" ] && { echo "== TEST: sar peste GRUB. GATA"; exit 0; }

# 4. Plasa de siguranta: parametrul kernel gpt, pentru toate intrarile GRUB (inclusiv recovery)
cp -p /etc/default/grub "$B/grub.default"
cp -p /boot/grub/grub.cfg "$B/grub.cfg"
if grep -q '^GRUB_CMDLINE_LINUX=""' /etc/default/grub; then
    sed -i 's/^GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="gpt"/' /etc/default/grub
fi
grep '^GRUB_CMDLINE_LINUX=' /etc/default/grub
update-grub 2>&1 | tail -4
echo "== 4. intrari GRUB cu gpt: $(grep -c -E '^\s*linux\s.* gpt( |$)' /boot/grub/grub.cfg)"

cat > "$B/revino.sh" <<EOF
#!/bin/bash
# scoate doar plasa 'gpt' din GRUB. Tabela reparata ramane (vechile header-e stricate sunt in nvme-head.img / nvme-tail.img).
[ "\$(id -u)" = 0 ] || { echo "ruleaza cu pkexec"; exit 1; }
cp -p "$B/grub.default" /etc/default/grub && update-grub
EOF
echo "== GATA. Poti reporni normal (fara sa mai scrii gpt in GRUB)."
