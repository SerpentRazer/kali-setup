---
name: ideapad-bluetooth-rfkill
description: "Pe laptop (Legion 5 17ITH6H, driver ideapad_laptop), BT pornea soft-blocked de rfkill; fix = unblock in autostart Hyprland"
metadata:
  node_type: memory
  type: project
  originSessionId: dd5ff6c8-68fd-4c36-9c07-41610a0f19a8
  modified: 2026-10-01T09:38:26.962Z
---

Laptop **Lenovo Legion 5 17ITH6H** (model 82JM; i7-11800H, RTX 3060 Mobile 6 GB, merge pe driverul `ideapad_laptop`,
de aici confuzia cu IdeaPad; Intel AX201 BT, controller A0:E7:0B:B1:31:53). La boot, switch-ul rfkill `ideapad_bluetooth` pornește Bluetooth-ul **soft-blocked** → `hci0` DOWN.

**Simptom:** butonul BT din quickshell (`~/.config/quickshell/SettingsPages/BluetoothPage.qml`, `togglePower()`) pare mort. De ce: API-ul `Quickshell.Bluetooth` comută doar `Powered` în BlueZ, iar BlueZ **nu poate porni un adaptor blocat de rfkill** — toggle-ul eșuează în tăcere. Nu butonul e stricat.

**Fix aplicat (2026-10-01):** `rfkill unblock bluetooth` (merge FĂRĂ root pe cutia asta) adăugat în autostart-ul Hyprland din `~/.config/hypr/hyprland.lua` (`hl.on("hyprland.start")`, lângă `nm-applet`) → se deblochează la fiecare login. `bluetoothd` era deja enabled+active; adaptorul e OK.

**Rămas opțional:** `AutoEnable=true` în `/etc/bluetooth/main.conf` (secțiunea `[Policy]`, acum comentat) ca adaptorul să se și powereze singur după unblock, fără să apeși butonul. Cere root (pkexec).

Vezi și [[hyprland-43pr-on-kali]], [[root-via-pkexec-not-sudo]], [[verify-before-instructing]].
