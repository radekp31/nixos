## TODO List

### Priority 1: Core Fixes & Structure
- [x] Rename `git.nix` → `default.nix` (and similar files in modules)
- [x] Rename `radekp.nix` → `default.nix` in user modules
- [x] Rename `home.nix` → `default.nix` in wsl
- [x] Update all imports to use directory paths instead of file paths
- [x] Set up flake checks/formatting with `treefmt` (via nixpush(), local only)
- [x] Add proper .gitignore
- [x] Fix nixpkgs.config warning with home-manager
- [x] Fix disko module import in deployment configuration

### Priority 2: Base Configuration
- [ ] Create `hosts/common/default.nix` with minimal sane secure defaults
  - Boot configuration
  - Networking basics
  - Security settings (firewall, sudo, SSH)
  - Nix settings (flakes, gc, auto-optimise)
  - Basic system packages
- [ ] Import common base in all host configurations
- [ ] Document override patterns with `lib.mkForce` for host-specific changes

### Priority 3: DRY & Package Management
- [ ] Move GUI applications to home-manager
  - discord, vlc, spotify, vscode, etc.
- [ ] Keep only system-critical packages in `environment.systemPackages`
  - Kernel modules, drivers, system services
- [ ] Create shared package lists
  - `modules/home/packages/common.nix` - CLI tools
  - `modules/home/packages/desktop.nix` - GUI apps
  - `modules/home/packages/development.nix` - Dev tools
- [ ] Extract common settings into reusable modules

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

### Priority 5: Module Consistency (Optional)
- [ ] Standardize module structure across all modules
  - Consistent file naming
  - Similar configuration patterns
  - Predictable import paths
- [ ] Add module options with `mkEnableOption` (only if needed for flexibility)
- [ ] Use `lib.mkDefault` for overrideable defaults
- [ ] Use `lib.mkIf` for conditional features

### Priority 6: Advanced Features (Future)
- [ ] Decide on `hosts/server/generic/` vs `deployments/server/generic/` strategy
  - Keep separate if they serve different purposes
  - Extract common config into shared modules
- [ ] Create host profiles if patterns emerge
  - `modules/system/profiles/desktop.nix`
  - `modules/system/profiles/server.nix`
  - `modules/system/profiles/wsl.nix`
- [ ] Setup CI/CD with GitHub Actions
  - Run `nix flake check` on push
  - Validate all configurations build
  - Check formatting with treefmt
- [ ] Create `default.nix` at repo root for `nix-build` compatibility
- [ ] Add pre-commit hooks for automatic formatting
- [ ] Test module isolation and independence

### Priority 7: Optimization (Low Priority)
- [ ] Profile build times and optimize slow modules
- [ ] Review and minimize closure sizes
- [ ] Audit security settings across all configurations
- [ ] Set up automatic security updates strategy
- [ ] Consider binary cache setup for faster rebuilds

---
