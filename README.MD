## TODO List

### 1. Deal with `hosts/` vs `deployments/` duplication
- [ ] Decide if `hosts/server/generic/` and `deployments/server/generic/` should stay separate
- [ ] If they're similar, extract common config into modules
- [ ] Document the difference between them (deployment targets vs local test?)

### 2. Implement DRY Principle
- [ ] Create base modules with sane defaults using `lib.mkDefault`
- [ ] Add `options` and `mkEnableOption` to modules
- [ ] Extract common packages/settings into shared lists
- [ ] Create host profiles (desktop, server, wsl) if patterns emerge
- [ ] Consider creating `modules/system/profiles/` and `modules/home/profiles/`

### 3. Fix `default.nix` naming convention
- [ ] Rename `git.nix` → `default.nix` (and similar files)
- [ ] Rename `radekp.nix` → `default.nix` in user modules
- [ ] Rename `home.nix` → `default.nix` in wsl
- [ ] Update all imports to use directory paths instead of file paths
- [ ] Benefits: cleaner imports like `../../modules/system/apps/git` instead of `../../modules/system/apps/git/git.nix`

### 4. Additional Improvements
- [ ] Create `modules/system/default.nix` and `modules/home/default.nix` to aggregate imports
- [ ] Add module documentation (comments explaining what each module does)
- [ ] Consider using `lib.mkIf` for conditional module loading
- [ ] Standardize module structure (all should have similar patterns)
- [ ] Add README files in key directories explaining their purpose

### 5. Optional but Recommended
- [ ] Set up flake checks/formatting with `treefmt`
- [ ] Test each module independently for errors
- [ ] Create a `default.nix` at repo root for `nix-build` compatibility
- [ ] Setup proper .gitignore

**Priority order:** 3 → 2 → 1 → 4 → 5

*Start with #3 (default.nix) as it makes #2 (DRY) much cleaner to implement!*
