---
name: verify-before-instructing
description: "This user wants commands verified against their actual machine before being handed over, not assumed from general knowledge"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 5dcfc3e1-24c2-49f7-8c0b-02b320274d17
  modified: 2026-08-09T12:30:17.721Z
---

The user brought a downloaded how-to guide and asked for a corrected version, saying "make sure everything works perfectly, I don't want excuses anymore, be professional." A prior attempt had evidently failed on untested instructions.

**Why:** The guide they had was written for a different OS version and failed silently in several places — a `wget` that saved an HTML page as `.tar.gz`, a theme name that never appears in any dropdown, menu paths removed two major versions ago, a package that doesn't exist. Each defect only surfaced mid-task. Being handed confident-sounding instructions that break partway through is the specific failure they are reacting to.

**How to apply:** Before handing over any command, run what can be run: check installed versions against the repos, simulate the install (`apt-get -s`), actually fetch the download and `file` it, read the archive's real folder name. State findings as measured facts with numbers, and mark clearly anything still unverified. When a prediction turns out wrong (e.g. a debconf dialog that never fired), say so plainly and move on — do not restate it as though it went to plan. See [[no-chaining-off-apt-update]] for one concrete instance.

2026-09-28, instalarea Hyprland: am raportat „78/78 checks” care verificau doar ca configurile SE INCARCA — utilizatorul a
dat apoi de popup-uri la hover, parola ceruta si Thunar netematizat. A spus: „nu ti-am zis eu sa verifici sa fie totul
functional?” si „nu mai presupune, testeaza”. Deci: „config ok” nu e verificare; testeaza comportamentul (click pe
butoane, captura de ecran, ce tema vede efectiv aplicatia) si verifica efectele secundare asupra celorlalte sesiuni.
