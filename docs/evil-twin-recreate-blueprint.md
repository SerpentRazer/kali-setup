---
name: evil-twin-recreate-blueprint
description: "Blueprint complet de RECREARE a WIDS-ului evil-twin (backend+scripturi, partea userului; frontend+LLM = Razvan). Arhitectura, logica de detectie, lantul de atac, apararea, dependinte, env, contracte API, gotchas"
metadata:
  node_type: memory
  type: project
  originSessionId: a0c338ac-edf4-4193-9f6c-659f180459ad
  modified: 2026-10-02T10:27:06.671Z
---

Blueprint ca sa reconstruiesc proiectul [[evil-twin-hackathon-project]] la cerere (user face BACKEND = logica+scripturi,
Razvan = FRONTEND + LLM). Deadline HackTech Lightning 2026-10-02. Totul ruleaza LIVE pe o singura cutie Kali, cu `sudo`
(monitor mode), prin `pkexec` in sesiunea asta ([[root-via-pkexec-not-sudo]]). NIMIC hardcodat (retele = baseline invatat live).

**ARHITECTURA (consolidata intr-o consola unica):** `console.py` (Flask :8080) = un proces, un dashboard, 3 panouri
RED/BLUE/CAPTURES + AI. Refoloseste prin import: `ops_server` (red), `guardian` (blue), `evil_twin_detect` (clasificator),
`ai_analyst` (LLM). Consolele vechi (ops_server :8080, guardian :8081, evil_portal :80) raman ca fallback standalone.
Vechea tinta „3 masini" (Kali sensor → Mac M4 dashboard → Mac Mini Ollama) e depasita: dashboard-ul e local; a ramas doar
Ollama pe Mac Mini prin Tailscale ([[tailscale-llm-integration]]).

**HARDWARE + ROLURI (politica pe driver, auto-assign in `assign_roles`):** AR9271 (`ath9k_htc`) = **DOAR ATTACK** (airbase-ng
bulletproof); Alfa AWUS036NHR 1W (`rtl8xxxu`/rtl8192cu) = **DEFENSE** (raza mare aude twin-ul + deauth tare). 2 adaptoare →
attack+defense SIMULTAN (momentul demo). 1 adaptor → one-job-at-a-time (AR9271 nu poate broadcast si sniff deodata). PCI intern
(iwlwifi) exclus din auto-assign (tine internetul). Override: `CON_ATTACK_IFACE`/`CON_DEFENSE_IFACE`, sau `CON_IFACE` single.
GOTCHA: AR9271 pica de pe USB passthrough (dmesg `USB disconnect`), re-enumera ca wlan0 managed → omoara monitor/airbase;
watchdog-ul din console.py (`radio_watchdog`, la 3s) auto-heal reda monitor mode. Nume interfete NU presupuse: enumerare din
`/sys/class/net/wl*` + `iw phy ... info` pt „* monitor".

**DEPENDINTE:** sistem Kali — aircrack-ng suite (`airbase-ng`, `airodump-ng`, `airmon-ng`), `dnsmasq`, `iw`, `iptables`,
`nmcli`, `iwconfig`, `lsusb`, `notify-send`. Python — `scapy` (2.7.x), `flask`. LLM — Ollama pe Mac Mini (Tailscale),
modele `qwen2.5:7b-instruct` + `huihui_ai/qwen3.5-abliterated:9b-q4_K`. `tailscale` CLI pt `_tailnet_ip()`.

**LOGICA DE DETECTIE (inima backend-ului, `evil_twin_detect.py` — vezi EVIL-TWIN-CONCEPTS.md):**
Definitia care conduce tot: *acelasi NUME (SSID) difuzat brusc de un DISPOZITIV NOU (BSSID) care nu e in hardware-ul stiut al
retelei reale.* NU „acelasi SSID pe 2+ BSSID = evil" (fals pozitiv pe ESS multi-AP legitim). Doua faze:
- LEARN (`run_learn`, `--learn N`): sniff beacons N s, inregistreaza `SSID→{BSSID→fingerprint}` in `baseline.json`. Fingerprint
  = channel, crypto, rates, HT-bit (IE 45), coridor RSSI (rssi_min/max). **MERGE, nu overwrite.** TREBUIE invatat cu atacatorul
  OPRIT, altfel twin-ul e salvat ca legit.
- WATCH (`run_watch`): per beacon, daca `ssid in baseline` si `bssid` nou → candidat; dupa `MIN_BEACONS_NEW`(3) sightings →
  `classify_new_bssid`. Profil din baseline: set OUI-uri (first-3), set base-MAC (first-5), secured-peste-tot?, peak RSSI.
  - `downgrade` = secured peste tot DAR twin OPEN (cel mai tare; bate chiar si OUI spoofuit). `same_radio` = first-5 match.
    `same_oui` = first-3 match. `louder` = rssi > peak + `RSSI_TWIN_LOUDER_MARGIN`(12dB).
  - Verdict: **benign** (same_radio, sau same_oui fara downgrade/louder → pliat in baseline, fara alerta) / **evil/rosu** HIGH
    (downgrade, SAU foreign-OUI+louder) / **review/galben** MEDIUM (foreign-OUI fara coroborare, sau same-OUI dar louder).
  - NU sunt probe (scot fals pozitivele): diferenta de canal, rates/HT, bitul LAA singur. Coridor RSSI pe BSSID cunoscut =
    DOAR louder (weaker = distanta). Clock-skew/TSF SCOS (fals pozitive uriase pe VM+USB, nevalid fara radiotap TSFT).
  5 straturi alerta: new-BSSID (`alert_new_bssid`), RSSI-anomaly, deauth-flood (`DEAUTH_THRESHOLD`10/`DEAUTH_WINDOW`5s),
  karma/probe-promiscuity (`PROBE_SSID_THRESHOLD`4/`PROBE_WINDOW`30s). Hop pe TOT 2.4GHz (`CHANNELS`=`range(1,14)`, env
  `ET_CHANNELS`, sursa unica in evil_twin_detect, refolosita de console+guardian) la 0.8s — NU doar 1/6/11 (un twin pe ch3/9
  era ratat). Praguri = constante sus in fisier (butoane de reglaj, NU hardcodare de retea). Scop onest: 2.4GHz, 1 adaptor pasiv;
  AMBELE radiouri (AR9271 atac / AWUS036NHR defense) sunt 2.4GHz-only, deci 5GHz = out of scope fara alt adaptor; un twin care spoofeaza OUI
  real + crypto + nu e louder = indistinct pasiv (ar trebui 802.1X/RADIUS cert sau TSF/seq — out of scope).

**LANT ATAC (`start-evil-twin.sh`, 7 pasi; `ops_server.py` il lanseaza cu `ET_SSID`/`ET_CHANNEL`/`ET_IFACE`):**
(1) lsusb check → (2) `nmcli device set IFACE managed no` (DOAR acest adaptor, wlan0 ramane online — fara `airmon-ng check kill`)
→ (3) monitor + `iw set channel` → (4) `airbase-ng -e SSID -c CH` creeaza `at0` → (5) `at0` ia `10.0.0.1/24` → (6) `dnsmasq -C
/etc/dnsmasq-portal.conf` (DHCP 10.0.0.10-100, DNS wildcard `address=/#/10.0.0.1`) → (7) `evil_portal.py` Flask pe :80 +
`iptables` DNAT 80/443→10.0.0.1:80. Portalul (`portal/evil_portal.py`) serveste „free wifi sign-in" + raspunde la probe-urile
captive-portal iOS/Android/Windows (pop automat), logheaza submit in `portal/captures.jsonl` (ip/mac/hostname din leasuri
dnsmasq + ARP). `stop-evil-twin.sh` reda managed la IFACE. Subreteaua 10.0.0.1 = normala pt AP fals; uplink real descoperit
dinamic (KIP). `ADMIN_TOKEN` (env) protejeaza /admin.

**APARARE (`defense/guardian.py`, engine blue):** refoloseste `classify_new_bssid` → `on_evil_twin` adauga BSSID-ul la
BLOCKLIST + **channel-lock** pe canalul rogue-ului (`pinned_channel`). Vede ATENTATE: frame-uri Auth/AssoReq/ReassoReq cu
addr1=rogue → `on_connect_attempt(sta)` (fara agent pe victima). `fingerprint_device`: known_devices.json (MAC→name/ntfy/contain,
castiga peste euristica) > bit LAA (0x02) = „randomized MAC (privacy) — vendor ascuns" > OUI vendor via scapy manufdb.
Fan-out `raise_alert`: dashboard + desktop `notify-send` + telefon `ntfy` (`DEF_NTFY_TOPIC`, `DEF_NTFY_URL` default ntfy.sh;
per-device topic ruteaza la owner). Containment opt-in (`DEF_CONTAIN=1` sau toggle): deauth tintit (reason 7, ×16) — necunoscut
= deauth automat; cunoscut = doar daca policy `contain:true` (nu-ti deauth propriul gear). `guardian_client.py` ruleaza pe
device-ul protejat: pull `/api/blocklist`, scan local (Linux nmcli/Win netsh/mac airport), popup nativ DO-NOT-CONNECT.

**CONSOLA UNIFICATA (`console.py`):** multi-radio role manager + `radio_watchdog`; `_blue` state machine cu **LEARN→GUARD +
warmup LLM** (adaugat de mine 2026-10-02, vezi detalii in [[evil-twin-hackathon-project]]); AI incident attach (`_ai_attach`
submit o data per BSSID → verdict in `/api/status` `blue.evil[].ai`); event log durabil `events.jsonl` (`_event_sink`);
report determinist (`_render_facts` = codul calculeaza faptele, LLM scrie doar proza). Env: `CON_PORT`(8080),
`CON_LEARN_SECONDS`(45), `CON_ATTACK_IFACE`/`CON_DEFENSE_IFACE`/`CON_IFACE`, `DEF_AI`(1).

**AI ANALYST (`defense/ai_analyst.py`, advisory-only — NU controleaza detectie/blocklist/deauth):** Ollama `/api/chat`,
verdict schema-locked (verdict∈{benign/evil/uncertain}, severity 1-5, recommended_action ENUM) ca un model abliterat sa nu
emita instructiuni libere; primary→fallback, circuit breaker, coada marginita + worker, toate string-urile observate = date
neincrezute. Env `DEF_AI_URL` default `http://100.70.174.44:11434` (IP Tailscale Mac Mini — stabil cu reteaua; numele da 403
pe Host-header Ollama, deci IP e corect), `DEF_AI_PRIMARY`/`DEF_AI_FALLBACK`/`DEF_AI_TIMEOUT`. Verdictul se degradeaza la
„unavailable" daca Ollama/Tailscale pica → verdictul detectorului determinist ramane. Teste `defense/test_ai_analyst.py`.

**CONTRACTE SPRE FRONTEND/LLM (partea Razvan, dar backend-ul le serveste):** `/api/status` → {red, blue{running,phase,
learn_remaining,evil[],blocklist,attempts,contain}, captures, roles, dual_radio, radios[], ai}. `/api/action` POST {action:
red_scan|red_select|red_launch|red_stop|blue_start(+learn_seconds)|blue_stop|blue_toggle}. `/api/ai/health|chat|report|config`.
`/api/captures`, `/api/captures/wipe`, `/api/logs`, `/api/known` (hot-reload known_devices). `/portal/<file>` preview + editor.

**GOTCHAS de recreare:** (1) baseline invatat cu atacatorul OPRIT. (2) detectia prinde twin DOAR al unui SSID aflat in baseline
(SSID nou-nou = vecin, nu clona — intentionat). (3) AR9271 one-job + USB dropoff. (4) scripturi NM-safe (elibereaza DOAR
adaptorul de atac, internetul supravietuieste). (5) SSID sanitizat + pasat prin env/argv (NICIODATA shell string), channel int
1-14, actiuni allow-list. (6) gitignore: `baseline.json`, `portal/captures.jsonl`, `defense/known_devices.json`, `memory/`,
`.claude/`. baseline.json GOLIT la `{}` 2026-10-02 (backup `~/.config-backups/baseline.json.venue-*`). Repo privat
`SerpentRazer/evil-twin-project`, push pe main merge (`gh` in ~/.local/bin). Vezi [[evil-twin-hackathon-project]],
[[kitty-smooth-wheel-patch]] nu-i legat, [[verify-before-instructing]].
