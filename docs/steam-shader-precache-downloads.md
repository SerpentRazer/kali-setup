---
name: steam-shader-precache-downloads
description: "De ce Steam „valideaza si descarca shadere” mereu la CS2/Enshrouded — Shader Pre-Caching (fossilize swarm), ~6 GB CS2 / ~20 GB Enshrouded la fiecare versiune, aproape fara refolosire; analiza 8 nov"
metadata:
  node_type: memory
  type: project
  originSessionId: 58a3d256-89f2-401b-9c3a-8a4d27379603
  modified: 2026-11-08T07:59:31.365Z
---

**Analiza 8 nov 2026 (din `~/.steam/debian-installation/logs/content_log.txt` + `shader_log.txt`):**
- Ce descarca = **Shader Pre-Caching**, bucket `SteamSwarm / G7:VulkanPipelinesV6` (un singur `fozpipelinesv6/steam_pipeline_cache.foz`
  per joc in `/mnt/games/SteamLibrary/steamapps/shadercache/<appid>`). Depotul shader are ID = appid (730, 1203620); jocul Enshrouded e depot 1203621.
- Valve regenereaza cache-ul dupa update-urile jocului; delta aproape nula => descarcare aproape completa de fiecare data:
  CS2 ~6 GB (9 descarcari 28 oct–8 nov, ~36 GB; 7 nov s-a resetat la 2.3 GB dupa update CS2, 8 nov 6.6 GB „from 0”),
  Enshrouded ~20 GB (1 nov, 2 nov intrerupt, 7 nov, 8 nov: 19.3 GB din 20 GB, refolosit 390 MB).
- „Verifying Installed” real = doar odata cu update-urile jocului (normal). „Processing Vulkan shaders” la lansare = fiindca
  `EnableShaderBackgroundProcessing "0"` in `config/config.vdf` (coada `ProcessingQueue "1203620;730;"`).
- NU tine de setup-ul nostru: bucket-ul G7 nu depinde de GPU (comutarea Intel/NVIDIA nu conteaza), ID-urile bucket constante
  (730 = 1718468, 1203620 = 2770596); biblioteca ext4 ok.
- Optiuni oferite userului: (B, recomandat pt CS2 fluid) bifeaza „Allow background processing of Vulkan shaders”;
  (A) debifeaza „Enable Shader Pre-Caching” (opreste tot; risc sacadari la prima intalnire, mai ales Enshrouded/Proton DX12).
  CS2 are si cache NVIDIA local (nvidiav1, ~78k shadere; launch options cu `__GL_SHADER_DISK_CACHE_SIZE=12000000000` + SKIP_CLEANUP).
  **8 nov 10:21 userul a ales A (Pre-Caching OPRIT).** Steam a sters singur cache-urile descarcate (CS2 foz 6.6 GB,
  Enshrouded 20 GB; a omorat si un fossilize_replay Enshrouded) si a PASTRAT cache-urile NVIDIA locale
  (`shadercache/730/nvidiav1` 2.2 GB din 7 nov, Enshrouded 136 MB). /mnt/games 167 GB liberi.
  **8 nov 10:24 FIXAT in `~/.local/bin/cs2-perf` (pas 5):** export `__GL_SHADER_DISK_CACHE=1`, `_PATH=/mnt/games/SteamLibrary/steamapps/shadercache/730/nvidiav1`,
  `_APP_NAME=steamapp_shader_cache`, `_READ_ONLY_APP_NAME='steam_shader_cache;steamapp_merged_shader_cache'` (fara el merged-ul de 2.2 GB
  e ignorat), `_SKIP_CLEANUP=1` — valori luate din `strings steamclient.so` + layout-ul nvidiav1/GLCache; driver 610 le cunoaste.
  Testat: `cs2-perf sh -c env` le primeste, LD_PRELOAD intact, profilul revine. Backup/revino: `~/.config-backups/pre-cs2-shadercache-2026-11-08_10-23-31`.
  **VERIFICAT 8 nov 10:5x pe CS2 pornit:** environ-ul cs2 are toate variabilele, procesul tine deschis
  `steamapp_merged_shader_cache.bin` (2.2 GB) si a scris doar 5.8 MB noi in `steamapp_shader_cache1` dupa ~15 min => cache-ul cald e folosit.

Legat: [[gaming-optimization-plan-2026-11-01]], [[games-ext4-migration-plan]].
