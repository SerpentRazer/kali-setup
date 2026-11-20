---
name: poe2-steamdeck-detection
description: "POE2 sub Proton se crede MEREU Steam Deck (regula hardcodata: ntdll are wine_get_version) — fix sigur = user_input_mode=KeyboardMouse in config (VERIFICAT 8 nov, HUD de PC); NU ascunde Wine (HideWineExports) — porneste verificarea Authenticode a DLL-urilor = „tampered”"
metadata:
  node_type: memory
  type: project
  originSessionId: 58a3d256-89f2-401b-9c3a-8a4d27379603
  modified: 2026-11-08T11:12:19.158Z
---

**8 nov 2026:** POE2 (2694490) reinstalat pe `/mnt/games/SteamLibrary` (~154 GB), Proton - Experimental. Prima pornire a scris
setarile de Deck: `user_input_mode=gamepad` (UI de controller/„consola”), shadow Low, texture Medium, FSR Balanced, light/GI 0.

**Cauza (dovedita din exe, objdump):** functia detector (0x14102ec20 in build 0.5.5f) = `GetProcAddress(GetModuleHandle("ntdll.dll"),
"wine_get_version") != NULL` => orice Wine/Proton = Steam Deck. Log la FIECARE pornire: `[SteamdeckSettingsInit] Set is running on steamdeck: 1`
+ „Default settings initialization”, dar valorile din config le suprascriu pe cele implicite. steam_api64.dll al jocului e SDK vechi
(SteamUtils_v009, fara IsSteamRunningOnSteamDeck); Steam nativ raspunde False (testat cu libsteam_api.so din CS2 + ctypes).

**NU ascunde Wine:** acelasi exe sare peste verificarea semnaturii „Microsoft Windows” (Authenticode) a version/kernel32/user32/gdi32/
advapi32/ws2_32 DOAR cand vede Wine (fn 0x140f03100) -> cu HideWineExports ar verifica DLL-urile Wine nesemnate -> „System or game DLLs
are tampered!” (risc anti-cheat). Testat doar pe prefix de test, NIMIC aplicat pe prefixul jocului. (Nota tehnica: in GE-Proton11-7
HideWineExports merge doar global `HKCU\Software\Wine`, AppDefaults\<exe> e ignorat — ntdll isi foloseste propriul nume.)

**Fix aplicat 12:49 (joc inchis):** in `compatdata/2694490/pfx/drive_c/users/steamuser/Documents/My Games/Path of Exile 2/poe2_production_Config.ini`
`user_input_mode=KeyboardMouse` + `auto_input_method_switching=false`. Backup + revino.sh: `~/.config-backups/pre-poe2-kbm-2026-11-08_12-49-20`.
**VERIFICAT 13:1x** (pornit de mine, captura pe ws 3): sfat de incarcare cu click, HUD de PC (flacoane 1/2, skill-uri Q/E/R/T/F), fara statistici.

**Statisticile din stanga = MangoHud** din LaunchOptions; userul l-a scos din Steam UI (acum
`__NV_PRIME_RENDER_OFFLOAD=1 __VK_LAYER_NV_optimus=NVIDIA_only gamemoderun %command%`). gamemoderun e inutil: `libgamemode.so` lipseste
in containerul SLR („dlopen failed” in console-linux.txt) — de scos. Grafica a ramas pe presetul Deck (FSR Balanced etc.) — oferit reglaj.

**Setari optime aplicate 8 nov 13:18-13:20 (joc inchis; backup+revino.sh `~/.config-backups/pre-poe2-grafica-2026-11-08_13-18-35`):**
upscale FSR->**DLSS** (Streamline DLSS merge sub Proton: „DLSS Enabled: true”, NGX 310.7), upscale_quality ->Quality (userul pusese
Performance), vsync_mode Locked->Off, framerate_limit 240 activ, background 30 activ. PASTRATE alegerile userului: user_input_mode=wasd,
rezolutie dinamica ON tinta 60, minimap alpha; Low/Medium/GI 0 raman (6 GB VRAM, „Insufficient VRAM” deja la Medium).
Valori enum verificate in exe: upscale Off/FSR/DLSS/XeSS/NIS; quality UltraQuality/Quality/Balanced/Performance/UltraPerformance;
vsync Off/Adaptive/Locked; reflex: valoarea exacta neconfirmata (exista „LowLatencyWithBoost”) -> userul o pune din meniu.
**`~/.local/bin/game-perf`** (nou) = cs2-perf generic (profil performance + LD_* restaurate, testat). Propus userului in LaunchOptions:
`__NV_PRIME_RENDER_OFFLOAD=1 __VK_LAYER_NV_optimus=NVIDIA_only __GL_SHADER_DISK_CACHE_SIZE=10000000000 __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1 PROTON_ENABLE_NVAPI=1 DXVK_NVAPI_VKREFLEX=1 /home/mastermind/.local/bin/game-perf %command%`
+ Compatibility -> GE-Proton11-7 (ntsync; NU 11-8/11-9). Cache NVIDIA al POE2 = ~/.cache/nvidia/GLCache (688 MB, implicit).
De verificat la urmatoarea pornire: DLSS/Reflex in Client.txt, „ntsync”, si `Failed to open LMDB environment ... Pipelines/Shaders:
Access denied` (apare la FIECARE pornire sub Experimental — cache LMDB al jocului nu se salveaza; ShaderCacheVulkan merge).

Capcane: un test Proton cu `SteamAppId=2694490` apare in Steam ca „joc pornit”; `grim -T` interzis pe ferestre NVIDIA -> captura =
`hl.dsp.focus({workspace=N})` + `grim -g` pe monitor + inapoi. Jocul se deschide pe ws 3.

Legat: [[games-ext4-migration-plan]], [[gaming-optimization-plan-2026-11-01]], [[grim-nvidia-window-crashes-hyprland]].
