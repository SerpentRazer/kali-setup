---
name: kali-github-backup-wish
description: User wants their whole Kali setup uploaded to a PRIVATE GitHub repo at the end (requested 20 nov 2026, not done yet)
metadata:
  type: project
---
20 nov 2026: userul vrea „la final sa uploadez tot kali-ul meu pe github, la privat”. Raspuns dat: repo PRIVAT cu setup-ul (dotfiles
~/.config: hypr, quickshell, kitty, btop, 43pr...; scripturile din ~/src/legion; fstab/GRUB/SDDM ca referinta), FARA secrete (parole,
chei SSH/GPG, tokenuri gh, cookies browser, .env), nu discul intreg. De facut dupa ce tema 43PR din 20 nov e confirmata.

**Why:** backup/reproductibilitate a tot ce am construit. **How to apply:** gh e in ~/.local/bin (cont SerpentRazer, vezi [[evil-twin-hackathon-project]]);
scaneaza de secrete inainte de push; repo privat obligatoriu; intreaba inainte de push (actiune externa).
