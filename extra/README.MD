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

- **Auto-upgrade pulls from a remote branch, not the local tree.**
  `hosts/common/default.nix:53` sets
  `system.autoUpgrade.flake = "git+https://github.com/radekp31/nixos.git#<host>"`.
  The running system tracks GitHub `main`, not `/etc/nixos`. The local tree and
  the deployed system can diverge silently.
  - *Action:* Confirm this is intentional. Pin a tag or a commit, or point to
    the local path. Combine with the P0 build gate above.
  - *Note:* `enable = true` carries the comment `# too unstable`. Resolve this
    contradiction.

- **Impure fetches bypass the flake lock.**
  `modules/home/users/radekp/desktop/default.nix:161,169` use
  `builtins.fetchurl` for Librewolf extensions.
  `modules/home/users/radekp/wsl/packages.nix:68` uses `builtins.fetchTarball`
  for an Azure CLI nixpkgs pin. The hashes are pinned, so builds are
  reproducible today. The `addons.mozilla.org` versioned URLs rotate and return
  404 over time. A future rebuild then fails. These pins do not update with
  `nix flake update`.
  - *Action:* Move the extension URLs to flake inputs, or use a declarative
    addon module. Move the Azure CLI pin to a dedicated flake input.

### P1 — Input hygiene and evaluation cost

- **`nixvim` does not follow the main `nixpkgs`.** `flake.nix:23` comments out
  `inputs.nixpkgs.follows`. The lock now holds five `nixpkgs` nodes
  (`nixpkgs_2`..`nixpkgs_5`). This increases evaluation time and mixes package
  sets.
  - *Action:* Add `inputs.nixpkgs.follows = "nixpkgs";` to `nixvim`, or state
    the reason to keep it separate.

- **Release channels do not align.** `flake.nix` pins `nixpkgs` to
  `nixos-26.05`, `home-manager`, `nixvim`, and `catppuccin` to `26.05`, but
  `nixos-wsl` to `release-25.11` and `nixpkgs_deprecated` to `nixos-25.11`.
  A WSL module built for 25.11 against a 26.05 `nixpkgs` can break.
  - *Action:* Track `nixos-wsl` on the matching release. Document why each
    off-channel input exists.

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
- **Identity is hardcoded.** The string `radekp` appears in 17 `.nix` files.
  Add a `my.user` option set and reference it. (Also tracked below.)
- **Dead code remains.** `modules/home/apps/desktop/niri/default.nix.bak`,
  large commented blocks in `parts/hosts.nix`, `modules/system/secrets/sops`,
  and `hosts/common/profiles/desktop.nix` add noise. Remove or restore them.
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
- [ ] **Browser Extension Management**
  - Replace `builtins.fetchurl` in Firefox/Librewolf with `nix-firefox-addons` or declarative policies.

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
