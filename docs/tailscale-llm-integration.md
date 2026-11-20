---
name: tailscale-llm-integration
description: "Tailscale instalat pe Kali pt a ajunge la LLM-ul Ollama (Mac Mini) peste tailnet, pt integrare in evil-twin"
metadata:
  node_type: memory
  type: project
  originSessionId: dd5ff6c8-68fd-4c36-9c07-41610a0f19a8
  modified: 2026-10-01T10:24:35.311Z
---

Tailscale **1.102.4** instalat pe Kali (2026-10-01; acum **1.104.1**, upgrade 2026-10-16) ca sa ajunga la **LLM-ul Ollama de pe Mac Mini** (rolul „brain/analyst" din sistemul 3-masini — vezi [[evil-twin-hackathon-project]]). Scop: integrare in platforma — panou care trimite evenimentele BLUE (evil twin + reasons) la Ollama si afiseaza verdictul in consola.

**Instalare:** repo Debian **bookworm** (Kali e rolling, dar binarele-s statice), cheie in `/usr/share/keyrings/tailscale-archive-keyring.gpg`, lista `/etc/apt/sources.list.d/tailscale.list`. Instalat prin **pkexec** (sudo n-are tty aici — vezi [[root-via-pkexec-not-sudo]]). Trucul pt gotcha-ul „apt update = exit 100": `apt-get update -o Dir::Etc::sourcelist="sources.list.d/tailscale.list" -o Dir::Etc::sourceparts="-"` actualizeaza DOAR repo-ul tailscale, ocolind repo-urile sparte (din 2026-10-18 nu mai e nevoie — repo-urile sunt reparate, `apt-get update` iese cu 0) (vezi [[broken-third-party-apt-repos]], [[no-chaining-off-apt-update]]). `tailscaled` enabled+active.

**De facut de user:** `pkexec tailscale up --operator=$USER` → login browser cu contul care are Mac Mini-ul in tailnet. Dupa: `tailscale status` arata peer-ul, Ollama pe `http://<mac-mini-tailnet-ip>:11434`.

**Ramas:** userul da IP-ul din tailnet + modelul Ollama (llama3.1/qwen2.5/etc) → cablez panoul de analist in console.py (POST /api/generate sau /api/chat la Ollama cu evenimentele detectorului).
