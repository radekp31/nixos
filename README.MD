## TODO List

### Priority 1: Core Fixes & Structure ✅ COMPLETE
- [x] Rename `git.nix` → `default.nix` (and similar files in modules)
- [x] Rename `radekp.nix` → `default.nix` in user modules
- [x] Rename `home.nix` → `default.nix` in wsl
- [x] Update all imports to use directory paths instead of file paths
- [x] Set up flake checks/formatting with `treefmt` (via nixpush(), local only)
- [x] Add proper .gitignore
- [x] Fix nixpkgs.config warning with home-manager
- [x] Fix disko module import in deployment configuration

### Priority 2: Base Configuration ✅ COMPLETE
- [x] Create `hosts/common/default.nix` with minimal sane secure defaults
  - [x] Networking basics
  - [x] Security settings (firewall, sudo, SSH)
  - [x] Nix settings (flakes, gc, auto-optimise)
  - [x] Basic system packages
- [x] Import common base in all host configurations
- [x] Document override patterns with `lib.mkDefault` for host-specific changes
- [x] Create host profiles
  - [x] `hosts/common/profiles/desktop.nix`
  - [x] `hosts/common/profiles/server.nix`
  - [x] `hosts/common/profiles/wsl.nix`
  - [x] `hosts/common/profiles/hyperv.nix`

### Priority 3: DRY & Package Management ✅ MOSTLY COMPLETE
- [x] Move GUI applications to home-manager
  - [x] discord, vlc, spotify, vscode, etc.
  - [x] Categorized and organized in `modules/home/users/radekp/desktop/default.nix`
- [x] Keep only system-critical packages in `environment.systemPackages`
  - [x] Kernel modules, drivers, system services
- [x] Extract common settings into reusable modules
- [x] Clean up duplicate packages across all hosts
- [ ] ~~Create shared package lists~~ (Decided against - using home-manager directly)
  - ~~`modules/home/packages/common.nix` - CLI tools~~
  - ~~`modules/home/packages/desktop.nix` - GUI apps~~
  - ~~`modules/home/packages/development.nix` - Dev tools~~

### Priority 4: Documentation
- [ ] Document module structure in main README.md
  - What goes in `modules/system/` vs `modules/home/`
  - How to add new modules
  - How to enable/disable features
- [ ] Add comments to complex modules explaining their purpose
- [ ] Document the difference between `hosts/` and `deployments/`
  - `hosts/` = Configurations for existing machines
  - `deployments/` = Fresh installations with nixos-anywhere
- [ ] Create `hosts/common/README.md` explaining base configuration
- [ ] Add usage examples to each major module

### Priority 5: Module Consistency ✅ MOSTLY COMPLETE
- [x] Standardize module structure across all modules
  - [x] Consistent file naming (all `default.nix`)
  - [x] Similar configuration patterns
  - [x] Predictable import paths
- [x] Use `lib.mkDefault` for overrideable defaults
- [ ] Add module options with `mkEnableOption` (only if needed for flexibility)
- [ ] Use `lib.mkIf` for conditional features

### Priority 6: Advanced Features (Future)
- [x] ~~Decide on `hosts/server/generic/` vs `deployments/server/generic/` strategy~~
  - [x] Kept separate - they serve different purposes
  - [x] Extracted common config into `hosts/common/profiles/server.nix`
- [x] Create host profiles ✅ COMPLETE
  - [x] `hosts/common/profiles/desktop.nix`
  - [x] `hosts/common/profiles/server.nix`
  - [x] `hosts/common/profiles/wsl.nix`
  - [x] `hosts/common/profiles/hyperv.nix`
- [ ] Setup CI/CD with GitHub Actions
  - [ ] Run `nix flake check` on push
  - [ ] Validate all configurations build
  - [ ] Check formatting with treefmt
- [ ] Create `default.nix` at repo root for `nix-build` compatibility
- [ ] Add pre-commit hooks for automatic formatting
- [ ] Test module isolation and independence

### Priority 7: Optimization (Low Priority)
- [ ] Profile build times and optimize slow modules
- [ ] Review and minimize closure sizes
- [ ] Audit security settings across all configurations
- [ ] Set up automatic security updates strategy
- [ ] Consider binary cache setup for faster rebuilds

### NEW: Priority 8: Remaining Cleanup
- [ ] Clean up `nixos-desktop/configuration.nix` to match the new pattern
  - [ ] Remove duplicates from common/profiles
  - [ ] Keep only hardware-specific configuration
- [ ] Review and potentially remove `modules/home/users/radekp/wsl/packages.nix` if redundant
- [ ] Update `deployments/server/generic/configuration.nix` to use common base + server profile
- [ ] Add section comments to all configuration files for better readability

---

**Next session focus:** Documentation (Priority 4) and final cleanup of `nixos-desktop` 🚀

