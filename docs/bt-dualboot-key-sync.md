---
name: bt-dualboot-key-sync
description: "Buds FE nu se conectau in Kali = cheie Bluetooth suprascrisa de Windows (dual boot, acelasi adaptor); din 26 oct bt-winsync tine cheia la fel in ambele"
metadata:
  node_type: memory
  type: project
  originSessionId: 20246a59-18db-4d16-af67-4b661ea80390
  modified: 2026-10-26T17:05:09.407Z
---

2026-10-26: „nu se conecteaza la buds fe” — Galaxy Buds FE `D0:56:FB:DF:21:6F`, adaptor `A0:E7:0B:B1:31:53`.
Simptom: `bluetoothctl connect` -> „Connected: yes” apoi `br-connection-refused`; in jurnal bluetoothd
`Hands-Free Voice gateway failed connect ...: Permission denied (13)` = castile nu mai au cheia (mergeau 18 oct, pica din 25 oct).
Cauza: Windows (nvme0n1p4, montat rw la /mnt/windows) are propria cheie pt aceeasi adresa de adaptor
(`HKLM\SYSTEM\ControlSet001\Services\BTHPORT\Parameters\Keys\a0e70bb13153\d056fbdf216f`); castile tin doar cheia
ultimei imperecheri. Userul le-a re-imperecheat in Kali, apoi a ales sa copiez cheia Kali in registrul Windows.

**bt-winsync** (`/usr/local/sbin/bt-winsync`, Python + `reged` din chntpw; sursa in scratchpad-ul sesiunii):
- `boot` = serviciul `bt-winsync.service` (Before=bluetooth.service, After=mnt-windows.mount): daca cheia din Windows
  s-a schimbat fata de ultima rulare (re-imperecheat in Windows) o scrie in `/var/lib/bluetooth/<A>/<D>/info`
  (backup `info.bak-winsync`). Daca s-a schimbat cea din Kali, doar avertizeaza in jurnal.
- `pkexec bt-winsync push` = cheile BlueZ -> registrul Windows, doar pt dispozitive imperecheate in ambele; refuza
  daca hive-ul nu e curat (seq1 != seq2 = hibernare/Fast Startup); verifica dupa scriere, altfel pune backup-ul inapoi.
- Stare: `/var/lib/bt-winsync/` (ultima cheie vazuta in Windows) + `hive-backups/` (ultimele 3).
  Backup registru Windows inainte de prima scriere: `~/.config-backups/bt-winsync-2026-10-26/SYSTEM`.
- Cheile pt BR/EDR au aceeasi ordine de bytes in Windows (`hex:aa,bb,...`) si BlueZ (`Key=AABB...`).
- Testat pe copie: din 358321 valori s-a schimbat doar cea a castilor; marimea hive-ului si seq neschimbate.

Daca re-imperechezi in Kali: `pkexec bt-winsync push`. In Windows: nimic, Kali preia singur la boot.
Vezi [[root-via-pkexec-not-sudo]], [[ideapad-bluetooth-rfkill]], [[gaming-windows-steam-on-kali]].

**1 nov:** din 28 oct fiecare boot avertizeaza „cheia din Kali e mai noua” pt Buds -> registrul Windows are cheia veche;
`pkexec bt-winsync push` NU rulat inca (spus userului; conteaza doar inainte de Windows + Buds).
**1 nov 08:21: userul a rulat `pkexec bt-winsync push`** (iesirea n-am vazut-o; la urmatorul boot avertismentul ar trebui sa dispara).
