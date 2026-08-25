# NixOS Configuration Roadmap

## 🔎 Review 2026-08-03 — Reproducibility and Maintainability

This section lists verified findings from a full read of the flake. Each item
gives a file reference, an action, and a severity. Fix P0 items first. They
protect reproducibility and prevent broken auto-deploys.

### P0 — Reliability and reproducibility risks

- **[DONE 2026-08-03] Auto-merge now has a build gate.**
  `.github/workflows/flake-daily-update.yaml` runs a gate after
  `nix flake update` and before the PR steps. The gate runs `nix flake check`
  and builds every `nixosConfigurations.*.config.system.build.toplevel`. A
  failed gate aborts the job, so no PR is created and no broken lock reaches
  `main`. The failed workflow run is the notification.
  - *Trade-off (risky):* Full host builds can exceed free GitHub-runner disk or
    time, because the desktop closure pulls NVIDIA, CUDA, KDE, and Steam. Watch
    the first runs. If they fail on runner limits, move to a self-hosted runner
    or reduce the gate to `nix flake check` only.

- **[DONE 2026-08-25] Auto-upgrade pulls from a remote branch, not the local tree.**
  `hosts/common/default.nix:50` set `system.autoUpgrade.flake` to track GitHub
  `main`, confirmed intentional now that the P0 build gate protects `main`
  from broken locks. The contradictory `# too unstable` comment is resolved:
  `system.autoUpgrade.enable` is now `false`. Background builds no longer run
  unattended, since a stale scheduled window (`04:40`, missed whenever the
  host is off) combined with `persistent = true` meant the build actually
  fired on every power-on, competing with active use for CPU.
  - *Replacement:* `modules/home/shells/zsh/default.nix` prints a banner on
    every interactive shell when `/nix/var/nix/profiles/system` (the local
    generation, updated by both `switch` and `boot`, surviving reboots) is
    14+ days old. Upgrades stay manual, triggered when convenient.

- **[DONE 2026-08-25] Impure fetches no longer bypass the flake lock.**
  The two `builtins.fetchurl` Librewolf extension entries in
  `modules/home/users/radekp/desktop/default.nix` were dead code (marked
  `# OLD?`, `programs.librewolf.enable = false`, Firefox-ESR is the active
  browser) and are removed. `modules/home/users/radekp/wsl/packages.nix` now
  imports the Azure CLI nixpkgs pin from the new `nixpkgs_azcli_pin` flake
  input (`flake.nix`) instead of a hardcoded `builtins.fetchTarball`, so the
  pin is tracked in `flake.lock` and refreshed by `nix flake update`. The pin
  itself is unchanged (same revision) — it exists because azure-cli is broken
  on the main `nixpkgs` input, not because of neglect. Verified with
  `nix flake check` and a full build of both
  `nixosConfigurations.*.config.system.build.toplevel`.

### P1 — Input hygiene and evaluation cost

- **[DONE 2026-08-25] `nixvim` now follows the main `nixpkgs`.**
  `flake.nix` sets `inputs.nixpkgs.follows = "nixpkgs";` on the `nixvim`
  input. The prior comment-out (commit `b8f37f5`, "fixing nixvim warning")
  worked around a real warning, but the true cause was a second, separate
  nixvim module: `modules/system/apps/wsl-nixvim/default.nix` (used by the
  WSL host) never got the `programs.nixvim.nixpkgs.source = inputs.nixpkgs;`
  fix that `modules/system/apps/nixvim/default.nix` (desktop host) already
  had. Adding the same line to the WSL module fixed the warning at its
  source, so the flake input can safely follow the main `nixpkgs` on both
  hosts. The lock now holds four `nixpkgs` nodes instead of five. Verified
  with `nix flake check` (no nixvim warning on either host) and a full build
  of both `nixosConfigurations.*.config.system.build.toplevel`.

- **[DONE, predates this review] Release channels already align.**
  `flake.nix` pins `nixpkgs`, `home-manager`, `nixos-wsl`, `nixvim`, and
  `catppuccin` all to `26.05` (commit `5752578`, "WSL update to 26.05"). This
  review's original claim that `nixos-wsl` tracked `release-25.11` was
  already stale when written. `nixpkgs_deprecated` stays on `nixos-25.11` on
  purpose: `parts/shells.nix` exposes it as `pkgs25_11` in a devShell, for
  cherry-picking a package version off the main release train (see
  "Pending Discussion" below). No action needed.

- **The nested Rust flake drifts.** `flakes/rust/flake.nix` declares its own
  `nixos-unstable`, `rust-overlay`, and `flake-utils`. The main flake does not
  reference it. The daily update workflow does not update its lock. It ages
  independently.
  - *Action:* Wire it in as an input with `follows`, or document it as a
    standalone shell and add it to the update job.

### P2 — Maintainability

- **Host wiring repeats.** `parts/hosts.nix` copies the full home-manager block
  for each host. Add a `mkHost` helper to remove the boilerplate. (Also tracked
  below.)
- **Hardcoded values repeat across the repo.** The string `radekp` appears in
  17 `.nix` files. The git email `polasek.31@seznam.cz` repeats in 3 files.
  `time.timeZone` and `system.stateVersion` repeat per host with no shared
  source. The GitHub repo string `radekp31` repeats in `hosts/common/default.nix`
  and the daily-update workflow. Treat identity as one instance of a general
  pattern, not the only one.
  - *Action:* Add a `my.user` option set (name, email) and a small set of
    global constants (repo owner/URL). Reference them everywhere instead of
    the literal. Leave `time.timeZone` and `system.stateVersion` as per-host
    values (they are correct to differ) but note the rule once, centrally,
    instead of repeating the reasoning in each host file. (Also tracked
    below.)
- **Dead code remains.** [DONE 2026-08-04] The niri module and its `.bak`, plus
  all niri references in `noctalia`, `nvidia`, and `zsh`, are removed. Still
  open: large commented blocks in `parts/hosts.nix`, `modules/system/secrets/sops`,
  and `hosts/common/profiles/desktop.nix`. Remove or restore them.
- **devShell pin name misleads.** `parts/shells.nix:13` binds
  `pkgs25_11` to an argument named `pkgs25_05`. Rename for one term, one
  meaning.
- **stateVersion varies by host** (`24.05`, `24.11`, `25.05`). This is correct
  and you must not change existing values. Add a short note in each host to
  state the rule for new readers.
- **Secret scanning is off.** `.pre-commit-config.yaml` comments out
  `detect-secrets` and `trufflehog`, though `.secrets.baseline` exists. Re-enable
  one scanner.

---

## 🔐 Security & Secrets
- [ ] **SOPS-nix Integration** (High Priority)
  - Review sops-nix configuration and ensure secrets are decrypted in deployments.
  - Move sensitive environment variables and udev rules into secrets.
- [ ] Audit security settings across all host configurations.

## 🏗 Architecture & Core Refactoring
- [ ] **Refactor Host Definitions (mkHost)**
  - Implement a helper in `parts/hosts.nix` to reduce boilerplate for new hosts.
- [ ] **Transition to "Smart" Modules**
  - Convert static imports (like KDE/Plasma) to use `options` and `mkEnableOption`.
- [ ] **Centralize Global Constants**
  - Define `my.user.name`, `email`, etc., in a global module instead of hardcoding.
  - Scope is not limited to identity. Audit for any value repeated across
    files with one true source: the GitHub repo owner/URL (`radekp31`),
    the git email, and similar literals.
  - Do not centralize `time.timeZone` or `system.stateVersion`. These vary by
    host on purpose. Document the rule once instead.
- [ ] **Host-Wide Version Selector**
  - Add one option to set the major nixpkgs release per host.
  - Keep an escape hatch to override specific packages from another release.
  - Design together with `mkHost` and the `my.*` option set.
- [ ] **Clean up Path References**
  - Replace deep relative imports (`../../../../`) with `inputs.self` references.
- [ ] **Update Auto-Upgrade Logic**
  - Remove hardcoded GitHub URLs from `system.autoUpgrade.flake`.

## 💻 Hardware & Desktop Applications
- [ ] **Hardware Abstraction**
  - Extract kernel parameters and blacklisted modules from `nixos-desktop` into dedicated hardware files or use `nixos-hardware` profiles.
- [ ] **Host Configuration Cleanup**
  - Strip `nixos-desktop/configuration.nix` of settings already covered by `common` or `desktop` profiles.
  - Review and potentially remove `modules/home/users/radekp/wsl/packages.nix`.
  - Standardize `deployments/server/generic/configuration.nix`.
- [x] **Browser Extension Management** — [DONE 2026-08-25] The dead
  `builtins.fetchurl` Librewolf extension entries are removed (see P0
  reproducibility review above). No declarative addon module is in place;
  revisit with `nix-firefox-addons` if Librewolf extensions are needed again.

## 🛠 Developer Experience & Documentation
- [ ] **Comprehensive Documentation**
  - Document the directory structure and module hierarchy.
  - Explain the strategic difference between `hosts/` and `deployments/`.
  - Add usage comments/READMEs to major modules.
- [ ] **CI/CD & Automation**
  - Implement GitHub Actions to run `nix flake check` and build validations.
  - Add pre-commit hooks for automatic treefmt application.

## ⏳ Pending Discussion
- [ ] **FIX: flake inputs bloat**
  - *Strategy:* Having multiple `nixpkgs` (unstable/stable/deprecated) is valid for cherry-picking broken packages, but needs careful management.
  - *Evaluation Cost:* Bloat is primarily in evaluation time, not final system size. Keep it "lazy" where possible.
  - *Standardization:* Use `flake-parts` (`_module.args`) to expose `pkgs-unstable` or `pkgs-old` globally to all modules.
  - *Overlays:* Use overlays for "seamless" cherry-picking when a package is a shared dependency.
  - *Input Following:* Ensure all flake inputs (home-manager, catppuccin, etc.) use `follows` to point to the primary `nixpkgs` to prevent unnecessary version multiplication.

---

## ✅ Completed Tasks (Archive)

### Core Structure & Base Config
- [x] Standardized file naming (use `default.nix`) across modules and users.
- [x] Updated all imports to use directory paths.
- [x] Created `hosts/common/default.nix` with secure defaults.
- [x] Implemented host profiles (Desktop, Server, WSL, Hyper-V).
- [x] Setup `treefmt` for repository-wide formatting.
- [x] Added proper `.gitignore`.
- [x] Fixed nixpkgs.config warnings and disko module imports.

### Package & Module Management
- [x] Moved GUI applications to Home Manager.
- [x] Categorized apps in `modules/home/users/radekp/desktop/default.nix`.
- [x] Cleaned up duplicate packages across hosts.
- [x] Standardized module structure and usage of `lib.mkDefault`.
- [x] Added `flake.lock` update GitHub Action.
