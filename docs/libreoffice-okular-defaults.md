---
name: libreoffice-okular-defaults
description: "14 nov 2026: LibreOffice (suita completa + gtk3) instalat; .docx -> Writer (inainte se deschidea cu Xarchiver); PDF -> Okular (inainte Brave)"
metadata:
  type: project
---

14 nov: `.docx` se deschidea cu Xarchiver (nu era nicio suita Office). Instalat `libreoffice libreoffice-gtk3` (4:26.8.1, 147 pachete,
fara stergeri; primul install a dat 404 pe libmimalloc3 -> `pkexec apt update` separat, apoi ok). Implicit: .docx = libreoffice-writer.desktop.
PDF implicit = `org.kde.okular.desktop` (xdg-mime, verificat si cu gio). Tema RC (Retele, Univ. Oradea, prof. Vancea): userul face VM-ul in
VMware pe Windows (Kali); txt retea in `~/Documents/HododiValentin_L1_retea-locala.txt` (router ZTE DIGI, fibra, 192.168.1.0/24,
Wi-Fi DIGI-<ssid> 2.4 GHz); captura o face userul in Windows (HododiValentin_L1_C1.png, semnat HV rosu).
