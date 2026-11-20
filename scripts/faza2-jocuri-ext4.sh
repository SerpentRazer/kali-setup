#!/bin/bash
# FAZA 2 (dupa `chkdsk C: /f` + Shrink C: in Windows): jocurile pe o partitie ext4 nativa + C: inapoi pe ntfs-3g. 1 nov 2026
#   proba  (implicit, fara root): verifica tot si arata ce ar face, nu scrie nimic
#   aplica (root): pkexec /bin/bash /home/mastermind/src/legion/faza2-jocuri-ext4.sh aplica      (cu Steam inchis)
# Pasi (fiecare sare peste ce e deja facut si se opreste la prima problema):
#   A. partitie noua in spatiul nealocat de dupa C: (intre p4 si p5), ext4 cu eticheta "jocuri"
#   B. copiere /mnt/games (containerul de pe C:) -> partitia noua, verificare 1:1
#   C. /mnt/games montat de pe partitia noua (aceeasi cale => Steam nu observa); containerul ramane pe C: ca backup
#   D. C: inapoi pe ntfs-3g (driverul kernel `ntfs` a pus C: read-only pe 1 nov si lasa MFT-uri agatate la stergeri)
set -u
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
MOD=${1:-proba}
DISK=/dev/nvme0n1; SYS=/sys/block/nvme0n1
CUUID=060A49400A492DCD          # C:
LABEL=jocuri; NEW=/mnt/games-new; MIN_GIB=150
OLDLOOP='/mnt/windows/LinuxGames/kali-games.ext4 /mnt/games '
CLINE="UUID=$CUUID  /mnt/windows  ntfs-3g  uid=1000,gid=1000,umask=022,windows_names,big_writes,exec,noatime,nofail,x-systemd.device-timeout=10  0  0"
case "$MOD" in aplica|proba) ;; *) echo "mod necunoscut: $MOD (proba|aplica)"; exit 1;; esac
if [ "$MOD" = aplica ]; then
    [ "$(id -u)" = 0 ] || { echo "aplica cere root: pkexec /bin/bash $0 aplica"; exit 1; }
    B=/home/mastermind/.config-backups/pre-faza2-jocuri-ext4-$(date +%Y-%m-%d_%H-%M-%S); mkdir -p $B
    exec > >(tee -a "$B/log.txt") 2>&1
    cp -p /etc/fstab $B/fstab
    cat > $B/revino.sh <<EOF
#!/bin/bash
# revine faza 2: /mnt/games pe containerul de pe C:, C: pe driverul kernel ntfs. Partitia "jocuri" ramane (stergere: sgdisk -d NR $DISK).
[ "\$(id -u)" = 0 ] || { echo "Ruleaza cu pkexec, cu Steam inchis."; exit 1; }
umount /mnt/games 2>/dev/null; umount -R /mnt/windows 2>/dev/null
cp -p $B/fstab /etc/fstab
dpkg-divert --list /usr/sbin/mount.ntfs | grep -q . || dpkg-divert --local --rename --divert /usr/sbin/mount.ntfs.ntfs-3g --add /usr/sbin/mount.ntfs
systemctl daemon-reload; mount -a; findmnt -R /mnt/windows -o TARGET,FSTYPE; findmnt /mnt/games
EOF
    trap 'chown -R mastermind:mastermind $B' EXIT
fi
die()  { echo "STOP: $*"; exit 1; }
need() { if [ "$MOD" = aplica ]; then die "$*"; else echo "  [proba] ar opri aici: $*"; fi; }   # conditie obligatorie
gol()  { blkid -p -D "$1" >/dev/null 2>&1; [ $? = 2 ] && [ -z "$(wipefs -n "$1" 2>/dev/null)" ]; }   # partitie fara nicio semnatura
run()  { if [ "$MOD" = aplica ]; then echo "+ $*"; "$@" || die "a esuat: $*"; else echo "  [proba] $*"; fi; }

echo "== conditii"
if pgrep -x steam >/dev/null || pgrep -x cs2 >/dev/null; then need "Steam/CS2 ruleaza (Steam > Exit)"; else echo "  Steam inchis: ok"; fi
case ",$(findmnt -no OPTIONS /mnt/windows)," in *,rw,*) echo "  C: montat rw: ok";; *) need "C: e tot read-only (a rulat chkdsk + Restart?)";; esac
ne=$(journalctl -k -b --no-pager -o cat | grep -cE 'ntfs: .*(Run chkdsk|set read-only|corrupt)')
[ "$ne" = 0 ] && echo "  fara erori ntfs de la boot: ok" || need "$ne erori ntfs in kernel de la boot (chkdsk n-a reparat?)"
[ "$(lsblk -no UUID ${DISK}p4)" = "$CUUID" ] || die "${DISK}p4 nu e C: (UUID diferit) - nu ating nimic"

# ---------- A. partitia noua
SRC=$(findmnt -no SOURCE /mnt/games)
p4s=$(cat $SYS/nvme0n1p4/start); p4n=$(cat $SYS/nvme0n1p4/size); p5s=$(cat $SYS/nvme0n1p5/start)
S=$(( (p4s+p4n+2047)/2048*2048 )); E=$(( p5s/2048*2048 - 1 ))
echo "== A. partitie: C: se termina la sectorul $((p4s+p4n-1)), recovery (p5) incepe la $p5s"
EXIST=""
for p in $SYS/nvme0n1p*; do [ "$(cat $p/start)" = $S ] && [ "$(cat $p/size)" = $((E-S+1)) ] && EXIST=/dev/${p##*/}; done
if [ -n "$EXIST" ]; then
    PART=$EXIST; echo "  partitia exista deja: $PART (rulare anterioara)"
    t=$(blkid -p -o value -s TYPE $PART 2>/dev/null); l=$(blkid -p -o value -s LABEL $PART 2>/dev/null)
    if [ "$t/$l" = "ext4/$LABEL" ]; then echo "  deja formatata ext4 \"$LABEL\": ok"
    elif [ -z "$t" ] && { [ "$MOD" = proba ] || gol $PART; }; then run mkfs.ext4 -q -L $LABEL -m 1 $PART
    else wipefs -n $PART; die "$PART contine ${t:-o semnatura (vezi wipefs)} - nu formatez"; fi
else
    for p in $SYS/nvme0n1p*; do ps=$(cat $p/start); pe=$((ps+$(cat $p/size)-1))
        [ $ps -le $E ] && [ $pe -ge $S ] && die "${p##*/} se suprapune cu zona $S-$E - nu ating nimic"; done
    GIB=$(( E>S ? (E-S+1)*512/1073741824 : 0 ))
    if [ $GIB -lt $MIN_GIB ]; then need "spatiu nealocat dupa C: = $GIB GiB (< $MIN_GIB). Ai facut Shrink pe C: in Windows?"
    else echo "  spatiu nealocat dupa C: $GIB GiB (sectoarele $S-$E): ok"; fi
    NR=1; while [ -e $SYS/nvme0n1p$NR ] || { [ "$MOD" = aplica ] && sgdisk -i $NR $DISK 2>/dev/null | grep -q '^Partition GUID'; }; do NR=$((NR+1)); done
    PART=${DISK}p$NR
    if [ "$MOD" = aplica ]; then
        sgdisk -v $DISK | grep -q 'No problems found' || die "sgdisk -v gaseste probleme in tabela GPT - nu scriu nimic"
        sgdisk -p $DISK | awk -v s=$S -v e=$E '$1~/^[0-9]+$/ && $2<=e && $3>=s {bad=1} END {exit bad}' || die "zona e ocupata in tabela GPT"
        run sgdisk --backup=$B/gpt-nvme0n1-inainte.bin $DISK
        echo "+ sgdisk -n $NR:$S:$E -t $NR:8300 -c $NR:$LABEL $DISK"
        sgdisk -n $NR:$S:$E -t $NR:8300 -c $NR:$LABEL $DISK      # avertismentul „kernel still uses old table” e normal aici
        sgdisk -i $NR $DISK | grep -q "^First sector: $S " || die "partitia $NR nu apare in GPT la sectorul $S"
        partx -a --nr $NR $DISK 2>/dev/null; udevadm settle
        [ -b $PART ] || die "$PART nu a aparut in kernel (partx)"
        [ "$(cat $SYS/${PART##*/}/start)" = $S ] && [ "$(cat $SYS/${PART##*/}/size)" = $((E-S+1)) ] || die "$PART nu are marimea asteptata"
        gol $PART || { wipefs -n $PART; die "$PART are deja o semnatura de sistem de fisiere - nu formatez"; }
    else
        echo "  [proba] backup GPT; sgdisk -n $NR:$S:$E -t $NR:8300 -c $NR:$LABEL $DISK; partx -a --nr $NR $DISK"
    fi
    run mkfs.ext4 -q -L $LABEL -m 1 $PART
fi

# ---------- B. copierea
echo "== B. copiere $SRC -> $PART"
if [ "$SRC" = "$PART" ]; then echo "  /mnt/games e deja pe $PART: sar peste B si C"
else
    case "$SRC" in /dev/loop*) echo "  sursa = containerul de pe C: ($SRC): ok";; *) die "/mnt/games vine din $SRC, nu din container - verifica manual";; esac
    run mkdir -p $NEW
    if [ "$MOD" = aplica ]; then
        findmnt -no SOURCE $NEW | grep -qx $PART || mount -o noatime $PART $NEW || die "nu pot monta $PART"
        chown mastermind:mastermind $NEW; chmod 755 $NEW
        need_b=$(du -sb --exclude=lost+found /mnt/games | cut -f1); free_b=$(( $(stat -f -c '%a*%S' $NEW) ))
        [ $free_b -gt $((need_b + 5*1073741824)) ] || die "loc insuficient pe $PART"
    fi
    run rsync -aHAXS --numeric-ids --info=progress2 --exclude=/lost+found /mnt/games/ $NEW/
    if [ "$MOD" = aplica ]; then
        d=$(rsync -aHAXSn --numeric-ids --delete --exclude=/lost+found -i /mnt/games/ $NEW/ | wc -l)
        a=$(du -sb --apparent-size --exclude=lost+found /mnt/games | cut -f1); b=$(du -sb --apparent-size --exclude=lost+found $NEW | cut -f1)
        na=$(find /mnt/games -xdev -not -path '/mnt/games/lost+found*' | wc -l); nb=$(find $NEW -xdev -not -path "$NEW/lost+found*" | wc -l)
        echo "  diferente rsync: $d | octeti $a vs $b | intrari $na vs $nb"
        [ "$d" = 0 ] && [ "$a" = "$b" ] && [ "$na" = "$nb" ] || die "copia nu e identica - /mnt/games ramane pe container"
        [ -f $NEW/SteamLibrary/steamapps/appmanifest_730.acf ] || die "lipseste appmanifest_730.acf in copie"
    fi

# ---------- C. comutarea /mnt/games
    echo "== C. /mnt/games de pe $PART"
    if [ "$MOD" = aplica ]; then
        U=$(blkid -s UUID -o value $PART); [ -n "$U" ] || die "fara UUID pe $PART"
        fuser -m /mnt/games >/dev/null 2>&1 && { fuser -vm /mnt/games; die "ceva inca foloseste /mnt/games (vezi lista)"; }
        sed -i "s|^$OLDLOOP|# KALI-JOCURI-VECHI (container pe C:, inlocuit 1 nov 2026): &|" /etc/fstab
        printf '# Jocuri pe partitie ext4 nativa (din 1 nov 2026, inainte: container pe C:). Faza 2, ~/src/legion/faza2-jocuri-ext4.sh\nUUID=%s  /mnt/games  ext4  defaults,noatime,nofail,x-systemd.device-timeout=10  0  2\n' "$U" >> /etc/fstab
        systemctl daemon-reload
        umount $NEW && umount /mnt/games || { cp -p $B/fstab /etc/fstab; systemctl daemon-reload; die "nu pot demonta - fstab revenit"; }
        if ! mount /mnt/games || [ "$(findmnt -no SOURCE /mnt/games)" != "$PART" ]; then
            umount /mnt/games 2>/dev/null; cp -p $B/fstab /etc/fstab; systemctl daemon-reload; mount /mnt/games; die "montare esuata - revenit pe container"
        fi
        rmdir $NEW 2>/dev/null; echo "  /mnt/games = $(findmnt -no SOURCE,FSTYPE /mnt/games): ok"
    else echo "  [proba] fstab: comentez linia containerului, adaug UUID=<nou> /mnt/games ext4; demontez container, montez $PART"; fi
fi

# ---------- D. C: pe ntfs-3g
echo "== D. C: pe ntfs-3g"
if [ "$(findmnt -no FSTYPE /mnt/windows)" = fuseblk ]; then echo "  C: e deja pe ntfs-3g: ok"
elif [ "$MOD" = aplica ]; then
    case "$(findmnt -no SOURCE /mnt/games)" in /dev/loop*) die "jocurile sunt inca pe C: - nu schimb driverul";; esac
    fuser -m /mnt/windows >/dev/null 2>&1 && { fuser -vm /mnt/windows; die "ceva foloseste C: (vezi lista)"; }
    cp -p /etc/fstab $B/fstab.inainteD
    sed -i "s|^UUID=$CUUID[[:space:]]\+/mnt/windows[[:space:]]\+ntfs[[:space:]].*|# KALI-C-KERNEL-NTFS (pana la 1 nov 2026): &\n$CLINE|" /etc/fstab
    grep -q "^UUID=$CUUID  /mnt/windows  ntfs-3g" /etc/fstab || die "n-am putut schimba linia C: in fstab"
    dpkg-divert --list /usr/sbin/mount.ntfs | grep -q . && dpkg-divert --local --rename --remove /usr/sbin/mount.ntfs
    systemctl daemon-reload
    umount -R /mnt/windows || die "nu pot demonta C:"
    if ! mount /mnt/windows || [ "$(findmnt -no FSTYPE /mnt/windows)" != fuseblk ]; then   # revin DOAR pasul D
        umount -R /mnt/windows 2>/dev/null; cp -p $B/fstab.inainteD /etc/fstab
        dpkg-divert --list /usr/sbin/mount.ntfs | grep -q . || dpkg-divert --local --rename --divert /usr/sbin/mount.ntfs.ntfs-3g --add /usr/sbin/mount.ntfs
        systemctl daemon-reload; mount /mnt/windows; mount -a
        die "ntfs-3g n-a montat C: - C: revenit pe driverul kernel (jocurile raman pe partitia noua)"
    fi
    mount -a
    echo "  driver C: $(findmnt -no FSTYPE,OPTIONS /mnt/windows | cut -c1-60) | mount.ntfs -> $(readlink /usr/sbin/mount.ntfs)"
else echo "  [proba] fstab: C: ntfs -> ntfs-3g; scot dpkg-divert pe mount.ntfs; remontez C: + cele 4 bind-uri"; fi

echo "== stare finala"
findmnt -no TARGET,SOURCE,FSTYPE /mnt/games; findmnt -R /mnt/windows -o TARGET,FSTYPE | head -6
if [ "$MOD" = aplica ]; then echo "GATA. Revenire: pkexec /bin/bash $B/revino.sh   (containerul vechi e inca pe C:)"; fi; exit 0
