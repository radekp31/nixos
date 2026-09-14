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
| Total `/run/current-system` (at review start) | 36.5 GiB |
| Total after groups A–F (2026-09-15) | **26.25 GiB** (−10.25, or 28%) |
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

- **[x] 3. [DONE 2026-09-14] Kernel settings contradicted each other.**
  `hosts/nixos-desktop/configuration.nix:97` blacklisted `kvm_intel`.
  Line 149 loaded `kvm-intel`. Same module, both directions.
  Line 133 set `usbcore.debug=1`, which floods the kernel log.
  - *Correction 1:* The root cause sat in the module, not in the host.
    `modules/system/apps/qemu/default.nix:8` set
    `boot.kernelModules = ["kvm-amd" "kvm-intel"]`. The host imports that module
    at line 23. The host lines 148-149 only repeated it. A host-only edit leaves
    the module still asking for `kvm-intel`. `nixos-desktop` is the only
    importer of the qemu module.
  - *Correction 2:* The CPU is AMD (`AuthenticAMD`), and `kvm_amd` is the loaded
    module. `kvm_intel` cannot load on this machine. The contradiction was dead
    noise, not active breakage. The true severity is P2, not P0.
  - *Correction 3:* The earlier claim "every filesystem is btrfs" is FALSE.
    `hosts/nixos-desktop/hardware-configuration.nix:56` declares `/media/A400`
    with `fsType = "xfs"`. The user confirmed on 2026-09-14 that the disk is a
    live scratch disk. **Keep `xfs` in `boot.kernelModules`. Do not remove the
    `/media/A400` block.**
  - *[DONE 2026-09-14]* `modules/system/apps/qemu/default.nix:8` now sets
    `["kvm-amd"]`. Removed `"kvm_intel"` from the blacklist on line 97. Deleted
    `"usbcore.debug=1"` from the kernel parameters. Deleted the duplicate
    `"kvm-amd"` and `"kvm-intel"` from the host `boot.kernelModules`.
  - *Verified:* `nixos-rebuild build` succeeded. In the built system,
    `etc/modules-load.d/nixos.conf` lists `kvm-amd`, `xfs`, and `nct6775`, and
    no `kvm-intel`. `etc/modprobe.d/nixos.conf` no longer blacklists
    `kvm_intel`. The only kernel-parameter change is the loss of
    `usbcore.debug=1`. The closure moved by 35 KiB, so the size is unchanged.
  - *Open (needs the disk attached):* `/media/A400` is NOT mounted, and the UUID
    `2b232c2c-3198-432d-bcbe-9d6056700d12` does not resolve. `nofail` hides the
    failure. Attach the disk and check the UUID. Also note that
    `boot.supportedFilesystems` on line 106 omits `xfs`, so the xfs user-space
    tools (`xfsprogs`) are absent. The mount still works, because the kernel
    loads the module on demand. Add `"xfs"` to that list only if you want
    `xfs_repair` and `mkfs.xfs`.

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

- **[x] 8. [CLOSED 2026-09-15] The running system does not come from this branch.**
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
  - *[DONE 2026-09-14]* `nixos-rebuild build --flake /etc/nixos#nixos-desktop`
    succeeded with Groups A, B, and C on the branch. The build used `build`,
    never `switch`. A `switch` on this branch takes dwl off the running system.
    The rule stands for every later group.
  - *[FACT 2026-09-15]* The switch already happened. Generation 372
    (2026-09-14 18:56) is the first system without dwl. Generation 374
    (2026-09-15 00:46) carries groups A-F at 26.3 GiB. The risk above is
    now history, not a warning.

    | Generation | Date | dwl | Closure |
    |---|---|---|---|
    | 371 | 2026-09-14 00:43 | yes | 36.5 GiB |
    | 372 | 2026-09-14 18:56 | no | 36.5 GiB |
    | 374 (current) | 2026-09-15 00:46 | no | 26.3 GiB |

  - *[DECIDED 2026-09-15]* **No merge. dwl stays on the `dwl` branch.**
    The user chose this. `config_maintenance` never carries the compositor.
    A `switch` from `config_maintenance` is therefore safe and expected.
    Build and run dwl from the `dwl` branch when you want it.
  - *Measured, for the record:* a merge would have been small. `git merge-tree`
    of `config_maintenance` and `dwl` auto-merges
    `hosts/nixos-desktop/configuration.nix` and conflicts only in
    `modules/system/apps/steam/default.nix`. The dwl branch commented out
    `gamemode` and `gamescopeSession`; finding 4 already did the same thing
    properly. Keep the `config_maintenance` side if a merge ever happens.
  - *[DONE 2026-09-15]* **Waydroid is disabled.** The `dwl` branch had commented
    out the import; `config_maintenance` still had it live at
    `hosts/nixos-desktop/configuration.nix:18`, so the running system carried
    the `waydroid` binary and an enabled `waydroid-container.service`. The user
    confirmed the decision on 2026-09-15. The import is now commented with the
    date and the reason.
    *Measured:* 28.1 MiB exclusive, not the 686 MiB its closure reports.
    `waydroid`, `lxc`, `android-tools`, `libgbinder` and `gbinder-python` all
    left, but python3, dbus and glib stay for the rest of the system. This is
    the same exclusive-versus-closure trap finding 7 documents.
    *Verified:* the built system has no `waydroid` binary and no
    `waydroid-container.service`. The closure fell from 26.256 to 26.229 GiB.
  - *Open, and it belongs to the `dwl` branch:* The `dwl` module is not
    treefmt-formatted. `treefmt.nix` enables
    `deadnix`, which strips the unused `config` and `lib` arguments. The next
    repo-wide `nix fmt` changes 56 lines in that file. Format it in its own
    commit, so the change never hides inside a feature diff.

### P1 — Duplication and dead code

- **[x] 5. [DONE 2026-09-14] Definitions repeated across files.**
  Each setting now has one owner. The rule: a dedicated module owns a subsystem,
  and the host and the profile do not repeat it.
  - *Why the build never failed:* NixOS merges a repeated option with
    `mergeEqualOption`. That function throws only when the values DIFFER. Every
    duplicate here held the same value, so evaluation stayed silent. These were
    maintenance faults, not build faults.
  - *[DONE]* **PipeWire.** `modules/system/hardware/sound/pipewire/default.nix`
    duplicated `hosts/common/profiles/desktop.nix:15-22` byte for byte, and held
    nothing unique. Deleted the module and its import. The profile keeps the
    block, so `hosts/hyperv` keeps sound too.
  - *[DONE]* **Bluetooth (three places).** The module is now the single owner,
    because it alone carried the `settings` block and the `btusb`/`uhid` modules.
    Deleted `hardware.bluetooth` from the desktop profile. Deleted
    `hardware.bluetooth.enable` from the host. Moved `services.blueman.enable`
    into the module, so the module is self-contained.
  - *[DONE]* `usbcore.autosuspend=-1` was set in the bluetooth module and in the
    host. Deleted the host copy. The built `kernel-params` now holds it once.
  - *[DONE]* `dejavu_fonts` was listed twice in one list. Deleted one.
  - *[DONE]* `spice-vdagent` was listed twice in the qemu module. Deleted one.
  - *[DONE]* **Nerd Fonts.** `nerd-fonts.fira-code` and `nerd-fonts.meslo-lg`
    installed system wide AND through home-manager. Deleted the home-manager
    copies. The system keeps them, because `fonts.fontconfig.defaultFonts`
    names "FiraCode Nerd Font". The other nine home fonts have no system copy
    and stay.
  - *[DONE]* **Repeated packages.** Deleted `git`, `ntfs3g`, `qemu`, and
    `mangohud` from the home package list. The system supplies each one:
    `git` from `hosts/common/default.nix:81` and from `programs.git`, `ntfs3g`
    from the host, `qemu_kvm` from the qemu module, and `mangohud` from the
    steam module.
  - *Verified:* `nixos-rebuild build` succeeded. In the built system,
    `pipewire.service`, `rtkit-daemon.service`, `bluetooth.service`, and
    `blueman-mechanism.service` all exist. `etc/bluetooth/main.conf` keeps
    `Experimental=false`, `MultiProfile=multiple`, and `AutoEnable=true`.
    `usbcore.autosuspend=-1` appears exactly once. All 12 Nerd Font store paths
    are present. `git`, `ntfs-3g`, `mangohud`, `qemu-kvm`, `virt-manager`, and
    `blueman-manager` all resolve under `sw/bin`.
  - *Measured:* the closure is 36.501 GiB before and after. A dedup changes no
    size, because the packages were always in the closure once.
  - *Trade-off (suboptimal):* `hosts/hyperv` imports the desktop profile but not
    the bluetooth module, so it loses bluetooth. `hosts/hyperv` is an orphan that
    the flake never builds (finding 6), and a Hyper-V guest has no bluetooth
    adapter. Import the module there if that host ever returns.

- **[x] 6. [DONE 2026-09-15] 2739 lines never evaluated. The user decided.**
  The repository held 75 `.nix` files and 6486 lines. A reachability walk from
  the real flake roots reached 44 files. **31 files, 2739 lines, stayed
  unreached.** The earlier estimate of "roughly 1700 lines" was low.

  **The user marked the Keep column on 2026-09-15. The result:**

  *Deleted — 6 files, 534 lines, and 2 flake inputs:*
  `modules/home/apps/desktop/noctalia` (424), `modules/home/apps/zen_browser`
  (20), `modules/devShells/devops` (28), `modules/devShells/tools/hooks.nix`
  (23), `modules/devShells/tools/shell.nix` (22), and
  `modules/system/apps/desktop/gnome` (17). The inputs `nixos-facter-modules`
  and `pre-commit-hooks` left `flake.nix`.

  *Kept — 2205 lines.* Every orphan host, every parked module except `gnome`,
  the `sops` module, the `disko` input, and both nested flakes. This code is
  parked work, not waste. **Do not propose it for deletion again.** Read the
  Keep column below before any later cleanup.

  *Verified 2026-09-15:* `nix flake check` passed both hosts and the treefmt
  gate. `nixos-rebuild build` produced store path
  `ynis4z46vjm2vd4nd83xd6f9sg2b06q4`, which is IDENTICAL to the path before the
  deletions. Dead code produces no output, so an identical path proves the cut
  removed nothing live. The WSL host also built. Both devShells still evaluate.
  `flake.lock` fell from 22 nodes to 18, because `pre-commit-hooks` also carried
  `flake-compat` and its own `nixpkgs`.

  *Note:* `modules/devShells/tools/devops.nix` is LIVE and stays. Do not confuse
  it with the deleted `modules/devShells/devops/default.nix`. The names differ by
  one directory level.

  *Method:* follow every relative path token from `flake.nix`,
  `hosts/nixos-desktop/configuration.nix`, `hosts/nixos-wsl/configuration.nix`,
  both home entry points, `patches/opencode-stub.nix`, and `treefmt.nix`. The
  walk counts a path in a comment as NO reference. It counts a path in any other
  position as a reference, so the result never calls a live file dead.

  *The user owns this decision (2026-09-14).* Some of this code is parked work,
  not waste. Fill the Keep column before anybody deletes a line.

  **Group 6a — Broken. Cannot evaluate today (444 lines).**
  Each one imports a flake input that `flake.nix` does not declare. An import
  fails with `attribute '<name>' missing`. Revival needs the input, not a rewrite.

  | Path | Lines | Missing input | Last touched | Keep? |
  |---|---|---|---|---|
  | `modules/home/apps/desktop/noctalia` | 424 | `inputs.noctalia` | 2026-08-04 | N |
  | `modules/home/apps/zen_browser` | 20 | `inputs.zen-browser` | 2026-01-14 | N |

  **Group 6b — Dead flake inputs.**
  Each input costs lock churn and evaluation time. None reaches a built host.

  | Input | Referenced by | Keep? |
  |---|---|---|
  | `nixos-facter-modules` | nothing at all, zero references | N |
  | `disko` | only `hosts/deployments/.../disk-config.nix` (unreached) and a comment | Yes, I want to create dynamic disko setup later, add that to README.md |
  | `pre-commit-hooks` | only `modules/devShells/devops/default.nix` (unreached) | No |

  *Note:* `flake-parts` and `systems` ARE live. `flake.nix:46-51` uses both.

  **Group 6c — Superseded. A working replacement already exists (124 lines).**

  | Path | Lines | Superseded by | Keep? |
  |---|---|---|---|
  | `modules/devShells/devops/default.nix` | 28 | the inline `devops` shell in `modules/devShells/default.nix:28` | No |
  | `modules/devShells/tools/hooks.nix` | 23 | data for the old devops shell above | No |
  | `modules/devShells/tools/shell.nix` | 22 | `flakes/compat` does the same FHS job. This file also reads `<nixpkgs>`, so it bypasses the flake lock. | No |
  | `modules/system/secrets/sops` | 51 | nothing. It is ALSO broken: line 3 comments out the only `sops-nix` import, so the `sops.*` options never exist. | Yes, I want to fix t his later |

  **Group 6d — Orphan hosts. The 2025-11 era (935 lines).**
  `parts/hosts.nix` builds exactly two hosts. None of these appears there. KEEP!

  | Path | Lines | Last touched | Keep? |
  |---|---|---|---|
  | `hosts/desktop-minimal` | 497 | 2026-04-21 | Yes for later revision |
  | `hosts/deployments/server/generic` | 171 | 2025-11-17 | yes for later revision |
  | `hosts/hyperv` | 86 | 2026-03-28 | yes |
  | `hosts/server/generic` | 86 | 2025-11-19 | yes |
  | `hosts/common/profiles/hyperv.nix` | 50 | 2025-11-19 | yes |
  | `hosts/common/profiles/server.nix` | 45 | 2025-11-19 | yes |

  `parts/hosts.nix:47-77` holds the commented host blocks that would import them. - KEEP!

  **Group 6e — Parked modules. Each one evaluates. Only the importer is missing
  (996 lines).**
  I checked every file in this group: none references an undeclared input. Add
  one import line and the module works. The recent dates mark active intent.

  | Path | Lines | Last touched | Note | Keep? |
  |---|---|---|---|---|
  | `modules/system/hardware/printers/brother/DCPL2622DW` | 239 | 2026-03-20 | import is commented at `hosts/nixos-desktop/configuration.nix:24` | Yes |
  | `modules/system/server/k8s` (master + node) | 192 | 2025-11-17 | | Yes I want to make this work later |
  | `modules/home/shells/bash` | 158 | 2026-03-20 | | yes |
  | `modules/home/shells/powershell` | 102 | **2026-08-13** | newest unreached file in the repository | yes |
  | `modules/home/apps/foot` | 79 | **2026-08-06** | `catppuccin/default.nix:15` says foot theming is broken upstream. A `foot-fix` branch exists. | Yes |
  | `modules/home/apps/alacritty` | 76 | **2026-07-25** | commit says "setting up alacritty with tmux" | yes |
  | `modules/system/server/webserver` | 75 | 2026-01-15 | commented at `parts/hosts.nix:63` | yes |
  | `modules/system/apps/cockpit` | 23 | 2025-11-16 | commented at `hosts/nixos-desktop/configuration.nix:193` | Yes I want to make this work later |
  | `modules/system/apps/openrgb` | 20 | 2025-11-17 | carries an mbedtls overlay | Yes, it supposedly works in newer kernerls, want to fix later |
  | `modules/system/apps/desktop/gnome` | 17 | 2026-05-03 | | No |
  | `modules/system/apps/desktop/xfce` | 15 | 2025-11-19 | | Yes |

  **Group 6f — NOT dead. Do not touch (240 lines).**
  The reachability walk misses these, because a nested flake is its own entry
  point. Both are live.

  | Path | Lines | Status | |
  |---|---|---|---|
  | `flakes/compat` | 185 | **Actively used.** Group C moved the `nix-ld` library set here. | Keep |
  | `flakes/rust` | 55 | Standalone shell. Review 2026-08-03 already tracks its lock drift. | Keep |

  - *[DONE 2026-09-15]* The user marked the column. The deletions above are the
    only ones authorised. Every other row stays.

- **[x] 9. [DONE 2026-09-14] A placeholder string reached the repository.**
  `modules/system/apps/qemu/default.nix:4` set
  `users.groups.libvirtd.members = ["your_username"];`. The value was upstream
  example text, not a real user. Line 12 already adds `radekp` to `libvirtd`
  through `users.users.radekp.extraGroups`, so the line was wrong and redundant.
  - *[DONE]* Deleted the line. Folded into the Group D commit, because both
    changes touch the qemu module.

- **[x] 7. [DONE 2026-09-15] Heavy packages sat in the always-on closure.**
  **The closure fell from 36.50 GiB to 26.25 GiB. That is 10.25 GiB, or 28%.**

  *Method:* measure EXCLUSIVE closure size per package — bytes reachable
  through that package alone. A plain closure size double-counts shared
  dependencies and overstates every candidate. The script `extra/dead-code-scan.py`
  does the reachability walk; the size walk used `nix path-info -r --json`.

  **Three corrections to the earlier estimate in this finding:**
  - `arduino-ide` does NOT cost 2.6 GiB. It costs **527 MiB**.
    `gcc-arm-embedded` (1.07 GiB) and `avr-gcc` (0.51 GiB) belong to the
    **`qmk`** system module. The exclusive walk proves it: both toolchains were
    reachable only through `qmk`.
  - `freecad` does NOT cost 0.8 GiB. It costs **3.13 GiB** — the largest single
    item on the machine (vtk 473 MiB, gfortran 315 MiB, ifcopenshell 266 MiB).
  - `speech-dispatcher` is NOT declared anywhere in this repository. Plasma 6
    enables it through Orca. See below.

  **Part 1 — packages in the wrong place. 5.47 GiB. These were defects.**
  - *[DONE]* `modules/system/hardware/gpu/nvidia/default.nix:29` put
    `cudatoolkit` in `hardware.graphics.extraPackages`. That option becomes
    `/run/opengl-driver`, which takes driver libraries only. Measured: the
    64-bit `graphics-drivers` closure was 6.59 GiB and `cuda-merged-12.9` was
    **3.94 GiB** of it. Worse, every FHS environment mounts the driver path, so
    `steam` and `steam-run` each carried it. **Group C removed this same CUDA
    from `nix-ld`. This was the second door.**
  - *[DONE]* The same list held `stdenv.cc`, `binutils`, `ncurses5` and `zlib`
    (~540 MiB). A compiler is not a driver.
  - *[DONE]* The same list held `intel-media-driver` and `intel-vaapi-driver`
    (~160 MiB). The CPU is AMD and the GPU is NVIDIA. No Intel graphics exists.
  - *[DONE]* `hosts/nixos-desktop/configuration.nix:67` held
    `user ALL=(ALL) NOPASSWD: ${pkgs.linuxPackages.nvidia_x11.settings}`.
    Two faults in one line. The user was literally `user`, and `getent passwd
    user` returns nothing — only `radekp` and `root` exist. And
    `pkgs.linuxPackages.nvidia_x11` is the DEFAULT driver, 595.71.05, while the
    pinned driver is 610.57.04. The rule held **782 MiB** of the wrong driver.
    **This is the same 595-against-610 mismatch finding 1 was meant to end.**
  - *[DONE]* Disabled Orca and speech-dispatcher in the plasma6 module.
    The chain was `plasma6.nix` → `services.orca.enable` → `orca.nix` →
    `services.speechd.enable` → `mbrola` → `mbrola-voices` at **644 MiB**.
    Orca is the screen reader. The user confirmed on 2026-09-15 that nobody
    here needs one. **Re-enable both if that changes.** A 56 MiB
    `speech-dispatcher` library remains, because Firefox and qtspeech link it.
  - *[DONE]* Replaced `bibata-cursors` (322 MiB) with `breeze_cursors` from
    `kdePackages.breeze`, which Plasma 6 already installs, so it is free.
    `home.pointerCursor` now declares the choice.
    *Open:* `~/.config/qt6ct/qt6ct.conf`, `qt5ct.conf`,
    `niri/dms/cursor.kdl`, `DankMaterialShell/settings.json` and
    `cosmic/.../icon_theme` still name Bibata. Those files are mutable user
    state, not nix-managed. Clear them or set Breeze in System Settings.

  **Part 2 — heavy tooling moved to `flakes/tools`. 3.58 GiB.**
  The user chose what to keep on 2026-09-15. See `flakes/tools/flake.nix`.
  - *[DONE]* `qmk`, `qmk_hid`, `via`, `nrfutil` → `#qmk`. A keyboard gets
    reflashed a few times a year; the toolchain was resident always.
  - *[DONE]* `arduino-ide` → `#arduino`.
  - *[DONE]* `quickemu` (with its own 963 MiB qemu) and the standalone
    virtualization tools → `#vm`.
  - *Two constraints decided the split, and both are real:*
    1. **A devShell cannot install udev rules.** So
       `hardware.keyboard.qmk.enable`, the udev rule block, and
       `services.udev.packages` stay in the qmk module. Verified: the built
       system keeps `50-qmk.rules` and `92-viia.rules`, and the `via` package
       itself left the closure. `services.udev.packages` copies the rules
       files without keeping the package.
    2. **A devShell cannot run a daemon.** `virtualisation.libvirtd` stays a
       system service, and `unit-libvirtd.service` references the 963 MiB qemu
       store path directly. **That closure does NOT leave while libvirtd stays
       enabled.** Disabling libvirtd would reclaim it and would end
       virt-manager VMs. That decision is open.

  **Kept by user decision (2026-09-15):** freecad, lmstudio, qmk, libreoffice,
  nixvim, quickemu, lutris, arduino-ide, firefox, bitwarden-cli, ripgrep-all,
  via, plasma-workspace-wallpapers, claude-code. The move to `flakes/tools`
  keeps every one of them available on demand. Nothing was lost.

  - *[DONE 2026-09-15]* **libvirtd is disabled.** The user chose quickemu.
    `qemu`, `libvirt` and `virt-manager` now have ZERO paths in the closure,
    and the 11 libvirtd systemd units are gone. That is a further 1.20 GiB.
    virt-manager, the dconf connection profile, and the `libvirtd` and
    `qemu-libvirtd` group memberships went with the daemon, because each one
    existed only to serve it. **Restore all five together if you want
    virt-manager back. A partial restore gives a GUI that cannot connect.**
    `virt-manager` also left `flakes/tools#vm`, for the same reason.
  - *Kept, and it cannot move to a devShell:* `boot.kernelModules = ["kvm-amd"]`
    and `virtualisation.spiceUSBRedirection.enable`. quickemu needs KVM from
    the kernel and needs the setuid `spice-client-glib-usb-acl-helper` for USB
    passthrough. `/dev/kvm` is mode 0666 on this host, so no group membership
    is required to reach it.
  - *[DONE 2026-09-15]* **The cursor theme moved to the plasma6 module.**
    `environment.sessionVariables` now sets `XCURSOR_THEME = "breeze_cursors"`
    and `XCURSOR_SIZE = "24"`. Verified in `etc/set-environment`, and
    `XCURSOR_PATH` already covers `/run/current-system/sw/share/icons`, where
    Plasma installs the theme. `home.pointerCursor` is removed.
    *Still open:* Plasma keeps its own copy in `~/.config/kcminputrc`, which
    nix does not manage. Change the theme once in System Settings, or delete
    the `[Mouse] cursorTheme` line, if a KDE application shows the old cursor.
    The same applies to `qt5ct.conf`, `qt6ct.conf`, `niri/dms/cursor.kdl`,
    `DankMaterialShell/settings.json` and `cosmic/.../icon_theme`.

### Plan

Commit each group alone. Rebuild and test after each commit. One commit per
group keeps a regression traceable.

| Group | Scope | Finding | Size change | Status |
|---|---|---|---|---|
| A | Environment variables | 2, 4 | none (36.5 GiB both) | **done 2026-09-14** (on `config_maintenance`) |
| B | Kernel settings | 3 | none (35 KiB) | **done 2026-09-14** (on `config_maintenance`) |
| C | `nix-ld` libraries → `flakes/compat` | 1 | **−5.8 GiB** | **done 2026-09-14** |
| D | Duplicate definitions | 5, 9 | none (36.501 GiB both) | **done 2026-09-14** (on `config_maintenance`) |
| E | Dead code | 6 | 534 lines, 4 lock nodes | **done 2026-09-15** (on `config_maintenance`) |
| F | Heavy packages → `flakes/tools` | 7 | **−10.25 GiB** (36.50 → 26.25) | **done 2026-09-15** (on `config_maintenance`) |

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
  - The user confirmed on 2026-09-15: keep `modules/system/secrets/sops` and fix
    it later. Review 2026-09-14, finding 6, group 6c holds the diagnosis.
  - *The blocker:* `modules/system/secrets/sops/default.nix:3` comments out the
    only `sops-nix` import. The module then sets `sops.defaultSopsFile` and
    `sops.secrets` at lines 14-49, but no module defines the `sops.*` options.
    Importing this file fails with "The option `sops' does not exist".
  - *The first step:* Add `sops-nix` to `flake.nix` inputs with
    `inputs.nixpkgs.follows = "nixpkgs"`. The flake does NOT declare it today.
    Then uncomment line 3. Only then does the rest of the file evaluate.
  - Review the sops-nix configuration. Confirm that secrets decrypt on deploy.
  - Move sensitive environment variables and udev rules into secrets.
- [ ] Audit the security settings across all host configurations.
  - `hosts/nixos-desktop/configuration.nix:53` sets
    `openssh.settings.PasswordAuthentication = true`. The common default is
    `false`. Confirm that the host needs the weaker setting.
  - Line 209 opens TCP ports 22, 5432, and 5050 on a desktop. Confirm the need.

## 🏗 Architecture & Core Refactoring

- [ ] **Dynamic disko setup** (user request, 2026-09-15)
  - The `disko` flake input stays declared, but nothing imports it today. The
    only consumer is `hosts/deployments/server/generic/disk-config.nix`, and
    `parts/hosts.nix:68-77` keeps that host commented out.
  - *Goal:* Build the disk layout from options instead of one hardcoded file.
    Take the device, the partition sizes, and the filesystem as arguments.
  - *Design it together with `mkHost`.* A host should declare its disk layout in
    the same place it declares everything else.
  - *Note:* Keep the input in `flake.nix` until this work starts. A later
    dead-input scan will flag `disko` again. This entry is the reason to keep it.
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
