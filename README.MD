## TODO List

### Priority 1: Code Quality & Structure
- [ ] Rename `git.nix` → `default.nix` (and similar files in modules)
- [ ] Rename `radekp.nix` → `default.nix` in user modules
- [ ] Rename `home.nix` → `default.nix` in wsl
- [ ] Update all imports to use directory paths instead of file paths
  - Benefits: cleaner imports like `../../modules/system/apps/git` instead of `../../modules/system/apps/git/git.nix`
- [ ] Set up flake checks/formatting with `treefmt`
- [ ] Add proper .gitignore

### Priority 2: DRY (Don't Repeat Yourself)
- [ ] Extract common packages/settings into shared lists
- [ ] Move GUI applications (discord, vlc, etc.) to home-manager
- [ ] Keep only system-critical packages in `environment.systemPackages`
- [ ] Create `modules/system/packages/common.nix` for shared package lists

### Priority 3: Module System Improvements
- [ ] Add `options` and `mkEnableOption` to modules
- [ ] Create base modules with sane defaults using `lib.mkDefault`
- [ ] Standardize module structure (all should have similar patterns)
- [ ] Consider using `lib.mkIf` for conditional module loading
- [ ] Create `modules/system/default.nix` and `modules/home/default.nix` to aggregate imports

### Priority 4: Documentation
- [ ] Add module documentation (comments explaining what each module does)
- [ ] Add README files in key directories explaining their purpose
- [ ] Document the difference between `hosts/` and `deployments/`
  - `hosts/` = Local machine configurations
  - `deployments/` = Remote server configurations

### Priority 5: Advanced Features
- [ ] Decide if `hosts/server/generic/` and `deployments/server/generic/` should stay separate
  - If they're similar, extract common config into modules
- [ ] Create host profiles (desktop, server, wsl) if patterns emerge
- [ ] Consider creating `modules/system/profiles/` and `modules/home/profiles/`
- [ ] Create a `default.nix` at repo root for `nix-build` compatibility
- [ ] Setup CI/CD with GitHub Actions
  - Flake checks
  - Build validation
  - Format checking
- [ ] Test each module independently for errors
