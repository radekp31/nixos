# NixOS Configuration Roadmap

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
