# NixOS Configuration Roadmap

## How to read this file

Reviews sit at the top. The newest review comes first. Each review holds
verified findings with a file reference, an action, and a severity.

The thematic backlog follows the reviews. It holds work with no deadline.

The archive sits at the bottom. Move an item there when the work is complete.
Keep the reason and the date. The archive explains why the repository looks as
it does today.

---

## 🔎 Review 2026-09-14 — Desktop Runtime Hygiene

This review examines `nixos-desktop` at runtime, not on paper. The audit used
the live system closure, not only the source files.

**The finding in one sentence:** the desktop host sets global overrides that
fight the desktop stack, and those overrides cause random application failures.

Disk size is a symptom. Interference is the disease. Fix the interference first.

### Measured evidence (2026-09-14)

| Item | Size in the system closure |
|---|---|
| Total `/run/current-system` | 36.5 GiB |
| `ld-library-path` (from `nix-ld`) | **6.0 GiB** → 200.9 MiB (fixed 2026-09-14) |
| ├ `cuda-merged-12.9` | 3.9 GiB (removed) |
| └ `nvidia-x11-595.71.05` (wrong version) | 782 MiB (removed) |
| `mbrola-voices` (through `speech-dispatcher`) | 644 MiB |
| `/nix/store` on disk | 75 GiB across 18 generations |

### P0 — Active interference

- **[x] 1. [DONE 2026-09-14] `nix-ld` supplied a wrong NVIDIA driver.**
  `modules/system/apps/nix-ld/default.nix` added `linuxPackages.nvidia_x11`.
  That resolved to **595.71.05**. The kernel module runs **610.57.04**.
  Every FHS binary that started through `nix-ld` received the 595 user space
  against the 610 kernel module. This broke graphics at random.
  The list also held `cudaPackages.cudatoolkit` at 3.9 GiB. Nothing on this
  machine used it.
  - *[DONE 2026-09-14]* The whole library set moved to `flakes/compat`. The
    system module now sets `programs.nix-ld.enable` and nothing else. The shim
    costs 67.8 KiB and stays, because it owns `/lib64/ld-linux-x86-64.so.2`.
    That path sits outside the store, so only the system can create it.
  - *Measured:* the `ld-library-path` closure fell from **6.0 GiB** to
    **200.9 MiB**. The remainder is the upstream default list in
    `nixos/modules/programs/nix-ld.nix`. `programs.nix-ld.libraries` is a list
    option, so any value in this repository MERGES with that default instead of
    replacing it. Use `lib.mkForce []` to go lower. The lost base is not worth
    it, because the default already covers zlib, curl, openssl, and systemd.
  - *Verified:* inside `nix run /etc/nixos/flakes/compat#fhs` the driver reads
    `libnvidia-glcore.so.610.57.04`. Both compat paths take the driver from the
    host at `/run/opengl-driver`, so the user space always matches the kernel
    module. The 595-against-610 mismatch cannot return.

- **[x] 2. [DONE 2026-09-14] Global variables overrode each application.**
  All references point to `hosts/nixos-desktop/configuration.nix`.
  - `:169` `TERM = "xterm-256color"` forces one terminfo on every session,
    local and remote. It breaks key handling and colour in WezTerm and foot.
  - `:174` `WLR_NO_HARDWARE_CURSORS` is a wlroots variable. The host runs KDE
    and KWin. The variable is dead.
  - `:178` `QT_QPA_PLATFORMTHEME = "qt6ct"` conflicts with Plasma 6. Plasma
    supplies its own platform theme.
  - `:175-177` `GDK_SCALE` and `GDK_DPI_SCALE` repeat the default value.
    `XCURSOR_SCALE` is not a valid Xcursor variable. Use `XCURSOR_SIZE`.
  - `:184-187` `__GL_GSYNC_ALLOWED`, `__GL_VRR_ALLOWED`,
    `__GL_THREADED_OPTIMIZATIONS`, and `DXVK_ASYNC` apply to every process.
    They belong to games only.
  - *Done:* Deleted `TERM`, `WLR_NO_HARDWARE_CURSORS`, `QT_QPA_PLATFORMTHEME`,
    `GDK_SCALE`, `GDK_DPI_SCALE`, and `XCURSOR_SCALE`. Deleted `DXVK_ASYNC`,
    which only ever worked with the third-party dxvk-async patch and is a
    no-op on mainline DXVK 2.x. Moved `__GL_GSYNC_ALLOWED`, `__GL_VRR_ALLOWED`,
    and `__GL_THREADED_OPTIMIZATIONS` into
    `programs.steam.package = pkgs.steam.override { extraEnv = { ... }; }`.
    They now live in the Steam FHS profile and reach games only.
  - *Kept:* `LIBVA_DRIVER_NAME`, `GBM_BACKEND`, and `__GLX_VENDOR_LIBRARY_NAME`
    stay global. `nvidia_drv_video.so` exists in `/run/opengl-driver`, so the
    VA-API setting resolves to a real driver. Remove them one at a time later
    and test.

- **[ ] 3. Kernel settings contradict each other.**
  `hosts/nixos-desktop/configuration.nix:97` blacklists `kvm_intel`.
  Line 149 loads `kvm-intel`. Same module, both directions.
  Line 133 sets `usbcore.debug=1`, which floods the kernel log.
  Line 150 loads `xfs`, but every filesystem is btrfs.
  - *Action:* Keep one direction for `kvm_intel`. Delete `usbcore.debug=1`.
    Delete the `xfs` module.

- **[x] 4. [DONE 2026-09-14] The Steam module contradicted a recorded decision.**
  `modules/system/apps/steam/default.nix:19,26` enable `gamemode` and
  `gamescopeSession`. A note from 2026-09-08 says keep both off, because a
  Steam launch option called the removed binaries and Dota 2 failed to start.
  The live closure holds `gamescope-3.16.23`. The fix never reached git.
  Line 16 also sets `STEAM_EXTRA_COMPAT_TOOLS_PATH`. Steam reads
  `STEAM_EXTRA_COMPAT_TOOLS_PATHS`, with a final "S". The name is wrong, and
  the value hardcodes `/home/radekp`.
  Line 35 starts Steam at every graphical login.
  - *[DONE 2026-09-14]* Deleted `STEAM_EXTRA_COMPAT_TOOLS_PATH`. The name was
    wrong, and Steam already reads `~/.steam/root/compatibilitytools.d` by
    default, so the variable was also redundant.
  - *[DONE 2026-09-14]* The background service ran `${pkgs.steam}/bin/steam`.
    The plain package ignores every `programs.steam` setting, including
    `extraEnv`. The service now runs `${config.programs.steam.package}`.
  - *[DONE 2026-09-14]* The user confirmed: **no gamescope**.
    `gamescopeSession.enable` is now `false` with a comment that states the
    decision and the date. Verified: the new closure carries no gamescope
    session file, and `gamescope` is not on `PATH`.
    The `gamescope-3.16.23` store path still appears in the closure, because
    `bottles` depends on it. A store path is not an active session. Remove
    `bottles` from `modules/system/apps/steam/default.nix` if you want the
    path gone too.
    Checked `localconfig.vdf` first: no launch option calls `gamescope` now,
    so this removal cannot repeat the 2026-09-08 failure.
  - *[DONE 2026-09-14]* `programs.gamemode.enable` stays commented out.
    The user confirmed the decision on 2026-09-14: keep gamemode off.
    An earlier note in this file said gamemode stays `true`. That note is
    superseded. The code and this file now agree.
  - *Action (open):* Decide whether the Steam background service should exist.

- **[ ] 8. The running system does not come from this branch.**
  `/run/current-system` carries a `dwl.desktop` session and a `dwl` binary.
  This branch carries neither. `git rev-list` reports `config_maintenance`
  0 ahead and `dwl` 6 ahead. `config_maintenance` and `main` both point at
  `0e38ef1`, so this branch holds no unique commit.
  - *Risk (high):* `nixos-rebuild switch` on `config_maintenance` removes the
    dwl compositor, its session entry, and the hot-reload, bar, and
    seat-keyboard-restore patches from the running system.
  - *[DONE 2026-09-14]* Group A lives on `config_maintenance`. The user chose
    this branch for the maintenance work. The dwl work stays on `dwl`.
  - *[DONE 2026-09-14]* The `dwl` branch is pushed. `origin/dwl` and `dwl`
    both point at `0d0a1e2`.
  - *Action (open):* Test Group A with `nixos-rebuild build`, not `switch`.
    A `switch` on this branch takes dwl off the running system.
  - *Action (open):* Merge `dwl` first, then rebase `config_maintenance` on
    top. Only then is a `switch` from this branch safe.
  - *Note:* The `dwl` module is not treefmt-formatted. `treefmt.nix` enables
    `deadnix`, which strips the unused `config` and `lib` arguments. The next
    repo-wide `nix fmt` changes 56 lines in that file. Format it in its own
    commit, so the change never hides inside a feature diff.

### P1 — Duplication and dead code

- **[ ] 5. Definitions repeat across files.**
  The PipeWire block exists in `hosts/common/profiles/desktop.nix:17` and again
  in the imported `modules/system/hardware/sound/pipewire`.
  Bluetooth is set three times: the desktop profile, the host, and the module.
  Three Nerd Fonts install system wide and again through home-manager.
  `mangohud`, `ntfs3g`, `git`, and `qemu` repeat.
  `dejavu_fonts` appears twice in one list.

- **[ ] 6. Roughly 1700 lines never evaluate.**
  `parts/hosts.nix` builds two hosts. `nix flake check` validates two hosts.
  - `hosts/desktop-minimal` (497 lines) and `hosts/hyperv` are orphans.
  - `modules/home/apps/desktop/noctalia` (424 lines) calls `inputs.noctalia`.
    `flake.nix` does not declare that input. The module cannot evaluate.
  - The `foot`, `alacritty`, `zen_browser`, `bash`, and `powershell` home
    modules have no importer.
  - `modules/system/hardware/printers/brother/DCPL2622DW` (239 lines) is
    commented out at the import.
  - `cockpit`, `openrgb`, `gnome`, `k8s`, and `webserver` have no importer.
  - The `nixos-facter-modules` flake input has zero uses.

- **[ ] 7. Home packages carry heavy applications.**
  `lmstudio` costs 2.2 GiB. `libreoffice` costs 1.5 GiB. `arduino-ide` with
  `gcc-arm-embedded` and `avr-gcc` costs about 2.6 GiB. `freecad` with `vtk`
  costs about 0.8 GiB. `speech-dispatcher` pulls `mbrola-voices` at 644 MiB.
  - *Action:* Convert each one into an opt-in module with `mkEnableOption`.

### Plan

Commit each group alone. Rebuild and test after each commit. One commit per
group keeps a regression traceable.

| Group | Scope | Finding | Size change | Status |
|---|---|---|---|---|
| A | Environment variables | 2, 4 | none (36.5 GiB both) | **done 2026-09-14** (on `config_maintenance`) |
| B | Kernel settings | 3 | none | open |
| C | `nix-ld` libraries → `flakes/compat` | 1 | **−5.8 GiB** | **done 2026-09-14** |
| D | Duplicate definitions | 5 | small | open |
| E | Dead code | 6 | none | open |
| F | Opt-in heavy packages | 7 | large | open |

Measure each step with `nvd diff /run/current-system result`.

*Trade-off (risky):* Group A removes NVIDIA variables that possibly still fix a
real bug. Test Steam, Firefox, and video playback after the rebuild. Revert one
variable at a time if a problem appears.

*Trade-off (complex):* Group C moved the `nix-ld` library set into
`flakes/compat`. That flake holds two mechanisms. The FHS sandbox is the
default, because it is a superset of the nix-ld path and removes the need to
choose:

- `nix develop /etc/nixos/flakes/compat` gives an interactive sandbox.
- `nix run /etc/nixos/flakes/compat -- ./installer.run` runs one command.
- `nix develop /etc/nixos/flakes/compat#light` gives the nix-ld path. It starts
  no sandbox, so it is faster, and it leaves `/etc` alone. The sandbox replaces
  `/etc` with a tmpfs, which a binary that reads an unusual `/etc` file can
  notice.

*Note:* The two mechanisms never run together. nix-ld works by being the ELF
interpreter at `/lib64/ld-linux-x86-64.so.2`. Inside the sandbox that path is
the real glibc loader, so nix-ld is bypassed. `NIX_LD` and
`NIX_LD_LIBRARY_PATH` leak into the sandbox, but nothing reads them there.

*Note:* `nix develop -c CMD` does not work on the default shell. Its shellHook
execs the sandbox, so `CMD` never runs. Use `nix run` for one command.

*Trade-off (workaround):* a binary launched outside both compat paths now fails
with a missing `.so`. That is the price of an on-demand environment. A binary
that needs CUDA also fails; add `cudaPackages.cudatoolkit` to the list in
`flakes/compat/flake.nix` if that day comes. Do not add it to the system.

*Trade-off (suboptimal):* Group E deletes work you possibly want later. The git
history keeps it. The branches `noctalia`, `dwl`, and `foot-fix` also keep it.

---

## 🔎 Review 2026-08-03 — Reproducibility and Maintainability

The completed items from this review sit in the archive. The open items follow.

### P1 — Input hygiene and evaluation cost

- **[ ] The nested Rust flake drifts.** `flakes/rust/flake.nix` declares its own
  `nixos-unstable`, `rust-overlay`, and `flake-utils`. The main flake does not
  reference it. The daily update workflow does not update its lock. It ages
  independently.
  - *Action:* Wire it in as an input with `follows`, or document it as a
    standalone shell and add it to the update job.

### P2 — Maintainability

- **[ ] Host wiring repeats.** `parts/hosts.nix` copies the full home-manager
  block for each host. Add a `mkHost` helper to remove the boilerplate.
- **[ ] Hardcoded values repeat across the repository.** The string `radekp`
  appears in 17 `.nix` files. The git email `polasek.31@seznam.cz` repeats in
  3 files. The GitHub repo string `radekp31` repeats in
  `hosts/common/default.nix` and the daily-update workflow. Treat identity as
  one instance of a general pattern, not the only one.
  - *Action:* Add a `my.user` option set (name, email) and a small set of global
    constants (repo owner and URL). Reference them everywhere.
    Leave `time.timeZone` and `system.stateVersion` as per-host values. They are
    correct to differ. State the rule once, centrally.
- **[ ] Commented blocks remain.** Large commented blocks sit in
  `parts/hosts.nix`, `modules/system/secrets/sops`, and
  `hosts/common/profiles/desktop.nix`. Remove them or restore them.
  (Review 2026-09-14, finding 6 extends this item.)
- **[ ] devShell pin name misleads.** `parts/shells.nix:13` binds `pkgs25_11` to
  an argument named `pkgs25_05`. Rename for one term, one meaning.
- **[ ] stateVersion varies by host** (`24.05`, `24.11`, `25.05`). This is
  correct. Do not change existing values. Add a short note in each host to state
  the rule for new readers.
- **[ ] Secret scanning is off.** `.pre-commit-config.yaml` comments out
  `detect-secrets` and `trufflehog`, though `.secrets.baseline` exists.
  Re-enable one scanner.

---

## 🔐 Security & Secrets

- [ ] **SOPS-nix Integration** (High Priority)
  - Review the sops-nix configuration. Confirm that secrets decrypt on deploy.
  - Move sensitive environment variables and udev rules into secrets.
- [ ] Audit the security settings across all host configurations.
  - `hosts/nixos-desktop/configuration.nix:53` sets
    `openssh.settings.PasswordAuthentication = true`. The common default is
    `false`. Confirm that the host needs the weaker setting.
  - Line 209 opens TCP ports 22, 5432, and 5050 on a desktop. Confirm the need.

## 🏗 Architecture & Core Refactoring

- [ ] **Refactor Host Definitions (mkHost)**
  - Implement a helper in `parts/hosts.nix` to reduce boilerplate for new hosts.
- [ ] **Transition to "Smart" Modules**
  - Convert static imports (such as KDE and Plasma) to use `options` and
    `mkEnableOption`. Review 2026-09-14, finding 7 depends on this work.
- [ ] **Centralize Global Constants**
  - Define `my.user.name`, `my.user.email`, and similar in a global module.
  - Do not centralize `time.timeZone` or `system.stateVersion`.
- [ ] **Host-Wide Version Selector**
  - Add one option to set the major nixpkgs release per host.
  - Keep an escape hatch to override specific packages from another release.
  - Design it together with `mkHost` and the `my.*` option set.
- [ ] **Clean up Path References**
  - Replace deep relative imports (`../../../../`) with `inputs.self`.
- [ ] **Update Auto-Upgrade Logic**
  - Remove the hardcoded GitHub URL from `system.autoUpgrade.flake`.

## 💻 Hardware & Desktop Applications

- [ ] **Hardware Abstraction**
  - Extract the kernel parameters and the blacklisted modules from
    `nixos-desktop` into dedicated hardware files. Consider `nixos-hardware`.
- [ ] **Host Configuration Cleanup**
  - Strip `nixos-desktop/configuration.nix` of settings that `common` or the
    `desktop` profile already covers. Review 2026-09-14, finding 5 lists them.
  - Review `modules/home/users/radekp/wsl/packages.nix`.
  - Standardize `deployments/server/generic/configuration.nix`.

## 🛠 Developer Experience & Documentation

- [ ] **Comprehensive Documentation**
  - Document the directory structure and the module hierarchy.
  - Explain the difference between `hosts/` and `deployments/`.
  - Add a README to each major module.
- [ ] **CI/CD & Automation**
  - Add pre-commit hooks that apply treefmt automatically.

## ⏳ Pending Discussion

- [ ] **Flake input bloat**
  - *Strategy:* Multiple `nixpkgs` inputs (unstable, stable, deprecated) help
    when you cherry-pick a broken package. They need careful management.
  - *Evaluation cost:* The cost sits in evaluation time, not in system size.
    Keep the inputs lazy where you can.
  - *Standardization:* Use `flake-parts` `_module.args` to expose
    `pkgs-unstable` or `pkgs-old` to all modules.
  - *Overlays:* Use an overlay when a cherry-picked package is a shared
    dependency.
  - *Input following:* Confirm that every input uses `follows` on the primary
    `nixpkgs`.

---

## ✅ Completed Tasks (Archive)

### Review 2026-08-03 completions

- **[DONE 2026-08-03] Auto-merge has a build gate.**
  `.github/workflows/flake-daily-update.yaml` runs a gate after
  `nix flake update` and before the PR steps. The gate runs `nix flake check`
  and builds every `nixosConfigurations.*.config.system.build.toplevel`. A
  failed gate aborts the job, so no PR appears and no broken lock reaches
  `main`. The failed workflow run is the notification.
  - *Trade-off (risky):* Full host builds can exceed free GitHub-runner disk or
    time, because the desktop closure pulls NVIDIA, CUDA, KDE, and Steam. Move
    to a self-hosted runner if the runner limits fail the job.

- **[DONE 2026-08-25] Auto-upgrade no longer runs unattended.**
  `hosts/common/default.nix:50` sets `system.autoUpgrade.flake` to track GitHub
  `main`. `system.autoUpgrade.enable` is now `false`. A stale scheduled window
  (`04:40`, missed whenever the host is off) plus `persistent = true` fired the
  build on every power-on and competed with active use for CPU.
  - *Replacement:* `modules/home/shells/zsh/default.nix` prints a banner on every
    interactive shell when `/nix/var/nix/profiles/system` is 14+ days old.
    Upgrades stay manual.

- **[DONE 2026-08-25] Impure fetches no longer bypass the flake lock.**
  The two `builtins.fetchurl` Librewolf extension entries in
  `modules/home/users/radekp/desktop/default.nix` were dead code and are
  removed. `modules/home/users/radekp/wsl/packages.nix` imports the Azure CLI
  pin from the `nixpkgs_azcli_pin` flake input instead of a hardcoded
  `builtins.fetchTarball`. The lock now tracks the pin. The pin exists because
  azure-cli is broken on the main `nixpkgs` input.

- **[DONE 2026-08-25] `nixvim` follows the main `nixpkgs`.**
  `flake.nix` sets `inputs.nixpkgs.follows = "nixpkgs"` on the `nixvim` input.
  The true cause of the earlier warning was
  `modules/system/apps/wsl-nixvim/default.nix`. It never received the
  `programs.nixvim.nixpkgs.source = inputs.nixpkgs;` line that the desktop
  module already had. The lock now holds four `nixpkgs` nodes instead of five.

- **[DONE, predates the review] Release channels align.**
  `flake.nix` pins `nixpkgs`, `home-manager`, `nixos-wsl`, `nixvim`, and
  `catppuccin` to `26.05`. `nixpkgs_deprecated` stays on `nixos-25.11` on
  purpose. `parts/shells.nix` exposes it as `pkgs25_11` in a devShell.

- **[DONE 2026-08-04] The niri module is removed.**
  The module, its `.bak` file, and all niri references in `noctalia`, `nvidia`,
  and `zsh` are gone.

- **[DONE 2026-08-25] Browser extension management.**
  The dead `builtins.fetchurl` Librewolf extension entries are removed. No
  declarative addon module is in place. Revisit with `nix-firefox-addons` if
  Librewolf extensions are needed again.

### Core Structure & Base Config

- [x] Standardized file naming (use `default.nix`) across modules and users.
- [x] Updated all imports to use directory paths.
- [x] Created `hosts/common/default.nix` with secure defaults.
- [x] Implemented host profiles (Desktop, Server, WSL, Hyper-V).
- [x] Setup `treefmt` for repository-wide formatting.
- [x] Added a proper `.gitignore`.
- [x] Fixed the nixpkgs.config warnings and the disko module imports.

### Package & Module Management

- [x] Moved GUI applications to Home Manager.
- [x] Categorized apps in `modules/home/users/radekp/desktop/default.nix`.
- [x] Cleaned up duplicate packages across hosts.
- [x] Standardized the module structure and the use of `lib.mkDefault`.
- [x] Added the `flake.lock` update GitHub Action.
- [x] Added GitHub Actions that run `nix flake check` and build validations.
