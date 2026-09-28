# NixOS Configuration Roadmap

## How to read this file

Reviews sit at the top. The newest review comes first. Each review holds
verified findings with a file reference, an action, and a severity.

The thematic backlog follows the reviews. It holds work with no deadline.

The archive sits at the bottom. Move an item there when the work is complete.
Keep the reason and the date. The archive explains why the repository looks as
it does today.

---

## 🔎 Review 2026-09-22 — The fans ramp at random

**Symptom.** The CPU fan and the case fans reach a high speed with no visible
cause. The user reported no pattern. The graphics card is not the source.

**Root cause, reproduced.** The Ryzen 5800X raises `Tctl` by about 40 °C in
under one second. The ASUS BIOS fan curve follows `Tctl` with almost no
smoothing. Any short background task therefore doubles the fan speed.

A 3 second all-core burst produced the table below. A logger sampled `Tctl`
five times per second, because a 2 second sample misses the spike.

| State | Tctl peak | CPU fan | Chassis fan |
|---|---|---|---|
| Idle | 42 °C | 965 RPM | 736 RPM |
| Burst, 2 s in | 74 °C | 1275 RPM | 885 RPM |
| 1 s after the burst ended | **81 °C** | **1979 RPM** | **1464 RPM** |
| 20 s later | 57 °C | 1293 RPM | 940 RPM |

Three seconds of work doubled both fans. Recovery took over 20 seconds. The
motherboard sensor stayed flat through the test. Only `Tctl` moved.

**Linux controls none of these fans.** `ls /sys/class/hwmon/hwmon*/pwm*`
returns no match. No pwm file exists on the host. `nct6775` loads
`nct6775_core` only; the platform driver does not bind, because this ASUS
board hides the Nuvoton chip behind the embedded controller. CoolerControl
logs `Uncontrollable RPM-only fan` for every motherboard fan and drives only
the two GPU fans. **The fix belongs in the UEFI, not in this repository.**

The old comment on `boot.extraModulePackages` read `# CPU fan goes full rpm
due to missing driver`. The driver is indeed missing. That is not the cause.
The BIOS curve works, and it reacts to a real 81 °C reading.

### Fixed — `hosts/nixos-desktop/configuration.nix`

| # | Change | Reason |
|---|---|---|
| 1 | Removed `boot.extraModulePackages = [it87]` | `it87` targets a different chip. This board uses a Nuvoton chip. The module never loaded. |
| 2 | Replaced `acpi_enforce_resources=lax` with `damon_stat.enabled=0` | The ACPI parameter came from the `it87` attempt, commit `53d035e`. It weakened ACPI resource arbitration and gained nothing. |
| 3 | Removed `powerManagement.cpuFreqGovernor = "performance"` | It never applied; the running governor was `powersave`. Under `amd-pstate-epp` a working `performance` setting raises boost aggression, which makes the `Tctl` spikes worse. |
| 4 | Documented why `nct6775` stays and does nothing | Prevents a fourth attempt at the same dead end. |

**Why DAMON.** `kdamond.0` used 521 s of CPU over 5185 s of uptime. That is
10 % of one core, held since boot, and the third largest consumer on the
machine, above Steam. This kernel enables it through
`CONFIG_DAMON_STAT_ENABLED_DEFAULT`. Nothing here reads the statistics.
Removing the load lowers the idle temperature, so each burst peaks lower.
This reduces the ramps. It does not remove them; only the UEFI curve does.

### Verification performed (2026-09-22)

```sh
nix build .#nixosConfigurations.nixos-desktop.config.system.build.toplevel
```

The build succeeds. The built `kernel-params` holds `damon_stat.enabled=0`
and no `acpi_enforce_resources`. No `cpufreq.service` exists in the closure.
`alejandra --check` passes on the changed file.

### ☑ OPEN TODO — fans

| # | Item | Action | Blocked on |
|---|---|---|---|
| 1 | ~~**Apply the change**~~ | ✅ **Done, verified 2026-09-28.** `/proc/cmdline` holds `damon_stat.enabled=0` and no `acpi_enforce_resources`. No `kdamond` thread runs. `it87` is not loaded. | — |
| 2 | **Tune Q-Fan in the UEFI** | Set the CPU fan profile to Manual. Raise the lower temperature point to about 60 °C. Increase the step up time and the step down time. Set the chassis fan source to **Motherboard**, not CPU; that sensor moves slowly and stops the case fan ramps. | The user |

---

## 🔎 Review 2026-09-20 — Lynis 3.1.6 Security Audit

Source: `~/lynis-audit.log`, run on `nixos-desktop`, kernel 7.2.2.
Result at the time of the scan: **hardening index 62**, 1 warning, 30
suggestions, 253 tests.

**The finding in one sentence:** the kernel ran with distribution defaults on
every hardening sysctl, and about a third of the audit output is a Linux
distribution assumption that NixOS does not meet.

Each item below carries a verdict. **FIXED** means the change is in the
repository and the closure builds. **REJECTED** means the change breaks this
system and must never be applied. **FALSE POSITIVE** means the test is wrong
about NixOS. **DEFERRED** means the work is real and waits for a decision.

### ✅ P0 — FIXED 2026-09-28. BusyBox put about 180 applets in the root PATH

**Fix:** `hosts/common/default.nix` replaces `busybox` with `lsof`, `psmisc`
(killall, pstree, fuser) and `bc`. Use `ip` and `ss` from iproute2 in place of
`ifconfig` and `netstat`. *Trade-off (suboptimal):* `strings`, `whois`,
`traceroute`, `powertop` and the other stubs leave the PATH with no
replacement. Use `nix shell nixpkgs#<pkg>` when one of them is needed.

**The audit did not report this. Chasing the audit's unnamed port 80 listener
found it on 2026-09-20.**

#### What BusyBox is for in this repository: nothing specific

`git log -S busybox` gives one commit. `46223cd`, 2026-03-06, titled
*"QOL packages + wsl nvidia drivers"*. The line went in with no comment, no
reason, and bundled with unrelated NVIDIA work. Nothing in this repository
references BusyBox, and no module depends on it.

The intent reads as convenience: one package instead of naming `lsof`,
`psmisc`, `nettools` and the rest. **The user's own later commits contradict
it.** When a tool was really needed, the real package went in:

| Tool | What wins the PATH today |
|---|---|
| `unzip` | **real** `unzip-6.0`, from the home profile |
| `nslookup` | **real** `bind-dnsutils`, from the home profile |
| `lsusb` | **real** `usbutils-019`, from the home profile |

#### What it actually delivers

BusyBox carries nixpkgs priority 15, so it loses every name collision with
coreutils. `ls`, `cp` and `grep` are safe. What survives are about **180
applet names that nothing else in the system profile provides**. Two groups
matter.

**Group 1 — degraded tools the user reaches by habit.** Each one below is a
BusyBox stub at the prompt right now, not the real program:

```
lsof  netstat  ifconfig  route  arp  killall  pstree  strings
bc  dc  ed  whois  traceroute  powertop  hdparm  crontab  telnet
```

*Measured:* `lsof` with no arguments prints a bare `pid / path / fd` table.
It accepts neither `-i` nor `-p`. That stub is why the port 80 hunt in this
review needed `/proc/net/tcp` and hand-matched socket inodes.

*Side effect:* `rpm` in that list is BusyBox too. It is the whole reason the
audit raised **PKGS-7308**. Remove BusyBox and that finding disappears.

**Group 2 — about 20 network daemons, in root's PATH:**

```
httpd  telnetd  ftpd  tftpd  inetd  dnsd  udhcpd  dhcprelay
sendmail  syslogd  crond  lpd  nbd-client  fakeidentd  tcpsvd  udpsvd  getty
```

#### How that fired

Lynis probed for Apache with `httpd -v`. Apache prints its version and exits.
**BusyBox reads `-v` as `verbose`, binds `*:80` and serves files.** The probe
started a root web server and walked away.

```
PID 63604  root  /run/current-system/sw/bin/httpd -v
           up 1h20m, parent = the user tmux session
           -> /nix/store/...-busybox-1.37.0/bin/httpd
           curl http://127.0.0.1:80/  ->  HTTP/1.1 404   (it answers)
```

*Measured exposure: low today.* The firewall allows TCP 22 only, so no LAN
host reaches port 80. A request for `/etc/passwd` returned 404, so the served
directory holds nothing useful. The defect is that a root server on every
interface starts from a version probe at all.

### Fixed — `hosts/common/default.nix` (every host)

| ID | Item | What changed |
|---|---|---|
| KRNL-6000 | 17 sysctl keys DIFFERENT from the profile | A hardening `boot.kernel.sysctl` block. See the table below. |
| NETW-3200 | dccp, sctp, rds, tipc load on demand | `boot.blacklistedKernelModules`. NixOS emits `blacklist <name>`, which blocks the module ALIAS. An unprivileged `socket()` call loads through that alias, so the path is closed. Root can still `modprobe` by name, which is not the threat. |
| BANN-7126 | `/etc/issue` WEAK, `/etc/issue.net` NOT FOUND | One `legalBanner` string feeds `services.getty.helpLine` and `environment.etc."issue.net"`. `services.openssh.settings.Banner` points sshd at the file. |
| — | Every sshd option reported NOT FOUND | The whole `services.openssh.settings` set is now explicit. See "SSH" below. |

**The sysctl keys, and the two the audit asked for that this repository refuses.**

| Key | Was | Now | Note |
|---|---|---|---|
| `dev.tty.ldisc_autoload` | 1 | 0 | Closes a known local privilege escalation path. |
| `fs.protected_fifos` | 1 | 2 | Stops the /tmp race attack. |
| `fs.protected_regular` | 1 | 2 | Same. |
| `fs.suid_dumpable` | 2 | 0 | No core dump from a setuid program. |
| `kernel.kptr_restrict` | 1 | 2 | **Trade-off, suboptimal for development.** `perf` loses kernel symbol names. Set the key to 1 to get them back. |
| `kernel.unprivileged_bpf_disabled` | 2 | 1 | 2 blocks unprivileged BPF but a privileged process reverses it. 1 is permanent for the boot. |
| `net.core.bpf_jit_harden` | unset | 2 | **Trade-off:** costs a little BPF throughput. |
| `net.ipv4.conf.{all,default}.accept_redirects` | 1 | 0 | No host here is a router. |
| `net.ipv4.conf.{all,default}.send_redirects` | 1 | 0 | Same. |
| `net.ipv6.conf.{all,default}.accept_redirects` | 1 | 0 | Same. |
| `net.ipv4.conf.{all,default}.log_martians` | 0 | 1 | Logs an impossible source address. |
| `net.ipv4.conf.{all,default}.rp_filter` | 0 | 1 (`mkDefault`) | **Risky, so it is overridable.** The NixOS firewall runs a LOOSE check with the rpfilter match and never touches this sysctl. `hosts/common/profiles/wsl.nix` sets 2, because WSL sits behind a Windows NAT and runs podman with a bridge. |
| `kernel.modules_disabled` | 0 | **0, REJECTED** | The audit asks for 1. It breaks NixOS. No module loads after boot, so `nixos-rebuild switch`, the NVIDIA driver, KVM and USB hotplug all fail. |
| `kernel.sysrq` | 1 | **1, REJECTED** | The audit asks for 0. `hosts/nixos-desktop/configuration.nix:171` sets 1 on purpose, with `boot.shell_on_fail`. The base layer must not fight a host decision. |

### Fixed — SSH, `hosts/common/default.nix`

The audit reported 22 sshd options as NOT FOUND, because sshd applies a
compiled-in default and writes nothing to the file. Every option is now
explicit, so the intent is recorded and an upstream default change cannot
move it silently.

`MaxAuthTries 3`, `MaxSessions 4`, `LoginGraceTime 30`,
`ClientAliveInterval 300`, `ClientAliveCountMax 2`, `AllowGroups wheel`,
`X11Forwarding no`, `AllowAgentForwarding no`, `PermitTunnel no`,
`GatewayPorts no`, `PermitUserEnvironment no`, `LogLevel VERBOSE`,
`KbdInteractiveAuthentication no`.

`AllowTcpForwarding` stays at the default `yes`. `ssh -L` and VS Code Remote
SSH both need it.

`AllowGroups wheel` is safe today: `radekp` holds `wheel` on `nixos-desktop`
and on `dt-wsl-nix`. Add a group to that list before you add a service account.

**Open risk, accepted by the user on 2026-09-20.**
`hosts/nixos-desktop/configuration.nix:80` keeps
`services.openssh.settings.PasswordAuthentication = true`, and port 22 is open
to the LAN. This is the largest real weakness in the audit. Key-only
authentication was rejected for now, because no `authorized_keys` entry exists
for `radekp` on this host, so the switch would lock SSH out.

*To close it later:* generate a key on the client, put the public half in
`hosts/nixos-desktop/users.nix` as
`users.users.radekp.openssh.authorizedKeys.keys`, and delete the
`PasswordAuthentication = true` line in the same commit. OpenSSH 10.5 already
applies `PerSourcePenalties` by default, so a repeated failure from one address
earns a growing block. That reduces the risk, it does not remove it.

### Rejected — this repository will not do these

**Group 1: the change breaks a desktop.**

| ID | Item | Why this repository refuses it |
|---|---|---|
| USB-1000 | Disable the `usb-storage` driver | USB sticks, card readers and phone storage stop working. This host runs QMK, Rockchip and Arduino workflows. |
| — | `hidepid` on `/proc` | Breaks the KDE system monitor, polkit and parts of the systemd user session unless `gid=proc` is wired correctly. Near-zero value on a single-user machine. |
| AUTH-9286 | Minimum and maximum password age | NIST SP 800-63B advises against forced rotation. Forced rotation produces weaker passwords. |

**Group 2: the user declined it on 2026-09-20.**

| ID | Item | Reason given |
|---|---|---|
| ACCT-9628 | Enable auditd | Real forensic value, but it needs a rule set and it writes to `/var/log/audit` continuously. |
| ACCT-9622 / ACCT-9626 | Process accounting, sysstat | `services.sysstat.enable` is one line. No NixOS module exists for `acct`. Neither earns its noise here. |
| PKGS-7398 | Package audit tool | **No low-noise tool exists on NixOS.** `vulnix` matches store name plus version against NVD and cannot see a nixpkgs backport patch, so most hits are false. The user measured the noise. The working control is already in place: a weekly flake update plus the shell staleness check. Nixpkgs ships security fixes as version bumps, so staying current IS the patch process. |
| HRDN-7230 | Install a malware scanner | ClamAV costs about 1 GB of signatures and a daily `freshclam` download, and finds close to nothing on a single-user Linux desktop. It raises the Lynis index and nothing else. |

**Group 3: the fix is impossible, or the value is zero.**

| ID | Item | Why |
|---|---|---|
| PRNT-2307 | CUPS config is world readable | `/etc/cups/cupsd.conf` is a symlink into `/nix/store`. `chmod` on a store path is impossible by design. *Measured mitigation, already in place:* cupsd listens on `localhost:631` only, `browsing = false`, `defaultShared = false`, `allowFrom = localhost`. What remains needs local access. |
| FINT-4350 | File integrity tool | AIDE has no NixOS service module. The Nix model already covers most of the goal: `/nix/store` is read-only and content addressed, and `/etc` is regenerated from the closure. Only `/home` and mutable state under `/var` stay uncovered. |
| LOGG-2154 | Remote log host | No log server exists on this LAN. |
| FILE-7524 | `/boot/grub/grub.cfg` is 0755 | GRUB reads the file through the firmware, not through Unix permissions, so 0600 is safe to set. The file holds no secret, so the value is near zero. |
| BOOT-5122 | GRUB boot password | Needs a PBKDF2 hash in the repository or a working sops module, and `modules/system/secrets/sops` is deferred. **Revisit when sops lands, not before.** |

### False positives — the test is wrong about NixOS

| ID | Claim | Reality |
|---|---|---|
| FIRE-4590 | No firewall | `networking.firewall.enable = true`, `firewall.service` is **active**, and `nft_compat` plus `x_tables` are loaded. Lynis looks for the legacy `ip_tables` module, which the nftables backend never loads. |
| LOGG-2146 | Log files are not rotated | NixOS keeps the logrotate config in `/nix/store` and passes it with `--config`. There is no `/etc/logrotate.conf`. `logrotate.timer` is **enabled**. |
| AUTH-9230 | Configure password hashing rounds | `/etc/login.defs` sets `ENCRYPT_METHOD YESCRYPT`. `SHA_CRYPT_MIN_ROUNDS` applies only to SHA-crypt. Lynis itself reports the test as DISABLED. yescrypt is the stronger algorithm. |
| AUTH-9284 | Look at the locked accounts | They are NixOS system daemon users with `!` in the shadow field. That is correct and required. |
| PKGS-7308 | Check the RPM database | The `rpm` on `PATH` is a **BusyBox applet**, not a package manager. There is no RPM system. Removing BusyBox removes this finding at the source. |
| PKGS-7370 | Install `debsums` | A Debian tool. The Nix equivalent is `nix store verify`, and every store path is already content addressed. |
| PKGS-7410 | Could not find any kernel packages | Lynis raised an exception. Nix has no such query. |
| FILE-6310 | Put `/var` on a separate partition | `/var/log` is the btrfs subvolume `@log`. It shares the pool, so it has no separate size limit, but it is not the root subvolume either. A btrfs quota group would close the gap; the complexity is not worth it here. |
| NAME-4028 | Check the DNS domain name | The LAN uses `search local` and no FQDN. Cosmetic. |

### ☑ TODO — one item left

Everything else in this review carries a closed verdict. Items 4 to 9 are
BOOT-5264 split one unit per item, because each unit needs its own
`serviceConfig` and its own test.

**Blockers and cleanup**

| # | Item | Action | Blocked on |
|---|---|---|---|
| 1 | ~~**Kill the stray root web server**~~ | ✅ **Done.** The reboot on 2026-09-28 ended it. `ss -tln 'sport = :80'` shows no listener. | — |
| 2 | **Remove `busybox` from `environment.systemPackages`** | ✅ **Done in the repository, 2026-09-28.** Replaced with `lsof`, `psmisc` and `bc`. Both closures build. **Not live yet:** run `sudo nixos-rebuild switch --flake .#nixos-desktop`. No reboot needed. | The user |
| 3 | ~~**Apply this review to the running system**~~ | ✅ **Done, verified 2026-09-28.** `/run/current-system` matched the repository build. The new sysctl values are live. | — |

**BOOT-5264 — one item per unit**

#### The method: measure the change before you apply it

`systemd-analyze security` reads a unit FILE, not a running service. So the
score of a change is readable from a built closure that never touched the
system. This removes the gamble from the whole group:

```sh
nix build .#nixosConfigurations.nixos-desktop.config.system.build.toplevel
systemd-analyze security --offline=true ./result/etc/systemd/system/<unit>.service
systemd-analyze verify              ./result/etc/systemd/system/<unit>.service
```

Read the number, then `nixos-rebuild switch`, then test the actual function.
**Never touch** `nix-daemon`, `display-manager`, `getty@` or `emergency`.

*One caution.* The score is a heuristic, not a standard. A unit that needs
`CAP_SYS_ADMIN` cannot score low and should not. Chase the knobs the unit does
not need, not the number.

#### Measured 2026-09-20

| # | Unit | Before | After | State |
|---|---|---|---|---|
| 4 | `acpid.service` | 9.4 UNSAFE | **removed** | ✅ disabled 2026-09-28, `hosts/common/profiles/desktop.nix` |
| 9 | `btrfs-scrub--`, `btrfs-scrub-nix` | 9.4 UNSAFE | **6.0 MEDIUM** | ✅ done, `modules/system/apps/btrfs/default.nix` |
| 5 | `coolercontrold.service` | 9.4 UNSAFE | — | ⛔ refused by the user, 2026-09-20 |
| 6 | `cups.service` | 9.2 UNSAFE | — | ⛔ refused by the user, 2026-09-20 |
| 7 | `udisks2.service` | 9.4 UNSAFE | — | ✅ closed 2026-09-28, working as intended |
| 8 | `nvidia-persistenced.service` | 9.4 UNSAFE | — | ✅ closed 2026-09-28, working as intended |

**Item 4, acpid — removed on 2026-09-28.** The upstream NixOS NVIDIA module
turns acpid on, not this repository. Measured 2026-09-20: all three event
handlers on this host (`acEvent.sh`, `lidEvent.sh`, `powerEvent.sh`) are
**empty files**, a shebang and nothing else. On 2026-09-28 no process
connected to `/run/acpid.socket`. acpid answered no event, so
`services.acpid.enable = lib.mkForce false` replaces the 1.6 OK hardening.
`hosts/nixos-desktop` already tells logind to ignore the power, suspend and
hibernate keys. *If a laptop host ever needs ACPI events,* remove the
`mkForce` line on that host only.

**Item 9, btrfs-scrub — done, and 6.0 is the honest floor.** A scrub needs
`CAP_SYS_ADMIN` and raw block device access, so the capability set and the
device nodes stay. What it does not need is a network, and `PrivateNetwork` was
the largest single win.

**Items 5 and 6 — refused by the user on 2026-09-20. Do not reopen.**

| # | Unit | Why the user refused it |
|---|---|---|
| 5 | `coolercontrold` | Fan control. A broken fan curve is a thermal problem, not a security one. *Correction 2026-09-22:* `it87` is gone and the fan cause was the BIOS curve; see the fan review. The refusal stands. |
| 6 | `cups` | A working Brother DCPL2622DW. NixOS already sets `PrivateTmp`. cupsd writes `/etc/cups/printers.conf` and reaches the printer over the network, so `ProtectSystem=strict` and `PrivateNetwork` were out anyway. `NoNewPrivileges` is the knob to distrust, because cupsd spawns filters and backends. |

**Items 7 and 8 — closed by user decision, 2026-09-28. Working as intended.**

| # | Unit | Why the score stays high, correctly |
|---|---|---|
| 7 | `udisks2` | It exists to mount arbitrary block devices. Broad device and mount privilege is its job. Hardening it to a good score means breaking it. |
| 8 | `nvidia-persistenced` | It holds the driver resident and needs the GPU device nodes. |

The remaining `systemd-analyze` exposure on these two is a description of
what the service does, not a defect to repair. Do not reopen.

**Skipped by user decision, 2026-09-20.** AUTH-9262, the PAM password strength
module. Note the coupling: this was the one control that argued for staying
with `PasswordAuthentication = true`. With PAM skipped, an SSH key is the only
remaining way to close that risk.

**Closed by user decision, recorded so nobody reopens it.** NETW-2705, the
single nameserver. The only resolver is the router at `10.0.50.1`. A second
entry means a public resolver, which leaks DNS off the LAN whenever the router
fails. That is a privacy trade, not a technical gap. Leave one nameserver.

**The standing risk, accepted 2026-09-20.** `PasswordAuthentication = true`
with port 22 open. See the SSH section above for the exact steps to close it.

### Verification performed (2026-09-20)

- `nix build .#nixosConfigurations.nixos-desktop.config.system.build.toplevel`
  and the same for `dt-wsl-nix`. Both succeed. `check-sshd-config` runs
  `sshd -t` inside the build and passes.
- `etc/sysctl.d/60-nixos.conf` in the built closure carries every new key, and
  still carries `kernel.sysrq=1` and `kernel.unprivileged_userns_clone=1` from
  the host.
- `etc/modprobe.d/nixos.conf` carries the four protocol blacklist lines next to
  the existing `nouveau` and `fjes` entries.
- `etc/issue`, `etc/issue.net` and `etc/ssh/sshd_config` all carry the expected
  text. The `nixos-help` line appears once, not twice.
- **Applied, verified 2026-09-28.** `/run/current-system` matched the build.
  `sysctl` reports the new values.

### Verification performed (2026-09-28)

- Both closures build: `nixos-desktop` and `dt-wsl-nix`. The first WSL
  attempt failed with a Go compiler SIGSEGV in `vault`, an unrelated package.
  The retry passed.
- `nvd diff /run/current-system result` on the desktop: `bc`, `lsof` and
  `psmisc` added; `acpid` and its three handler scripts removed; nothing else.
- The built `sw/bin` holds no `busybox`, `httpd`, `telnetd`, `ftpd` or `rpm`.
  `lsof`, `killall`, `pstree` and `bc` resolve to the real packages.
- `alejandra --check` passes on both changed Nix files.
- **Not live yet.** Run `sudo nixos-rebuild switch --flake .#nixos-desktop`.

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
| `/nix/store` on disk (2026-09-14) | 75 GiB across 18 generations |
| `/nix/store` on disk (2026-09-15) | **86 GiB across 21 generations** |

### Disk reclaim — measured 2026-09-15. No manual action needed.

**Conclusion first: run no garbage collection. The system already does it.**

`hosts/common/default.nix:60` sets `nix.gc.automatic = true`.
`hosts/nixos-desktop/configuration.nix:56-59` overrides the schedule to
`weekly` and the options to `--delete-older-than 14d`. The timer is enabled
and active.

*Proof that it works:* `nix-gc.service` ran on 2026-09-14 at 00:02. It
deleted 23200 store paths and freed **28.9 GiB** in 2.5 minutes. The journal
holds the full log.

So why did the store grow from 75 GiB to 86 GiB? Groups A-F ran on 2026-09-14
and 2026-09-15, AFTER that collection. Each group built a system closure. The
growth is normal build garbage between two scheduled runs, and it corrects
itself.

| Path set | narSize | Fate |
|---|---|---|
| Unreachable garbage today | **13.3 GiB** | the 2026-09-21 run deletes it |
| Held by generations 354-367 | part of 43.5 GiB | the 2026-09-21 run deletes it |
| Booted (373) + current (374) + `result` | 36.8 GiB | kept |

*Method:* sum `narSize` per path set. `du` under-reports, because
`auto-optimise-store = true` hardlinks identical files. The 2026-09-14 run
reported 8.2 GiB saved by hard linking.

**Two facts to act on, both time-bounded:**

1. **The booted system is generation 373, not 374.** The switch to 374 ran on
   2026-09-15 at 00:46 and no reboot followed. Generation 373 holds the running
   kernel and its modules. Reboot to make 374 the booted system.
2. **The 2026-09-21 run deletes every generation older than 2026-09-07.** That
   is generations 354 to 367. Generation 367 (2026-09-04 21:30) is the oldest
   BUILT system that carries dwl. Generations 368 to 371 carry dwl too, and
   later runs take them in turn.
   - *This costs nothing if you accept a rebuild.* The dwl source is safe on
     `origin/dwl`. Only the instant rollback disappears.
   - *Act only if you want a permanent dwl fallback.* Pin one generation with
     a GC root, or raise `--delete-older-than`.

*Not a constraint:* the root filesystem is 1.9 TiB with 1.2 TiB free, at 39%
use. `/boot` is 5.0 GiB at 12% use with 5 loader entries. No disk pressure
exists anywhere.

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
  | `modules/system/secrets/sops` | 51 | **FIXED 2026-09-15, then deferred.** The `sops-nix` import is live and the file is now 13 lines. The host import is commented out. See the Security & Secrets section. | Yes, I want to fix t his later |

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
  | `flakes/compat` | 185 | **Actively used.** Group C moved the `nix-ld` library set here. Its lock joined the daily update job on 2026-09-16. | Keep |
  | `flakes/rust` | 55 | **Moved 2026-09-16.** It is the `rust` devShell in the main flake now, and the directory is deleted. | Gone |

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

- **[x] [DONE 2026-09-16] The nested Rust flake drifted.** The shell is a
  normal devShell in the main flake now. The compat lock joined the daily
  update job.

  *Measured before the fix:* `flakes/rust/flake.lock` held `nixpkgs` at
  2026-07-26, `rust-overlay` at 2026-07-28, `flake-utils` at 2024-11-13, and a
  SECOND `nixpkgs` at **2025-04-13** that `rust-overlay` carried unfollowed.
  The root `nix flake update` reached none of them.

  *Done:* `flake.nix` declares `rust-overlay` with
  `inputs.nixpkgs.follows = "nixpkgs_unstable"`. `parts/shells.nix` applies the
  overlay to the existing `pkgs_unstable` instance, so nothing instantiates a
  second nixpkgs. `modules/devShells/tools/rust.nix` holds the toolchain and
  the package list. `modules/devShells/default.nix` exposes the `rust` shell
  beside `default` and `devops`. `flakes/rust` is deleted.

  **The command changed. Learn the new one.**

  | Before | After |
  |---|---|
  | `nix develop /etc/nixos/flakes/rust` | `nix develop /etc/nixos#rust` |

  *Verified 2026-09-16, and the overlay is provably inert:* the `default` and
  `devops` derivations are IDENTICAL before and after, at
  `c5lk5b2jbckihjh72a3412xy4qxiz111` and
  `ipkc896jk77amixwr36qilhi0n12nbv2`. An identical hash proves the overlay only
  ADDS `rust-bin` and replaces nothing the other two shells read. Both host
  store paths are unchanged too.

  *Verified by a real build, not only by evaluation:*
  `nix develop .#rust --command rustc --version` built the shell and printed
  `rustc 1.98.1 (48a229cea 2026-09-01)`. `nix flake check` passed.

  *Measured:* the root lock gained exactly ONE node, `rust-overlay`, because
  its nixpkgs follows. The repository lost a 5-node nested lock, including the
  2025-04-13 nixpkgs.

  **A second instance of the same defect, found on the way.**
  `flakes/compat` is also standalone, is also absent from the main flake, and
  was also absent from the update job. It matters MORE than `flakes/rust`,
  because Group C made it the live `nix-ld` replacement.
  - *Done:* `.github/workflows/flake-daily-update.yaml` runs
    `nix flake update --flake ./flakes/compat`.
  - *Why compat did NOT move into the main flake:* this README documents
    `nix run /etc/nixos/flakes/compat` in finding 1, in the Plan section, and
    in the flake header comment. A move makes every one of those lines wrong.
    The path IS the interface.
  - **A workflow bug, found and fixed.** The change gate ran
    `git diff --quiet flake.lock`, which names the root lock ONLY. On a day
    when only the nested lock moved, the gate reported `changed=false` and the
    job discarded the update. The gate names both locks now.
  - *Open, and it costs 2 lines:* no gate validates compat after its lock
    moves. The build gate builds host closures, and no host imports compat. Add
    `nix develop ./flakes/compat#light --command true` to close it.

### P2 — Maintainability

- **[x] [DONE 2026-09-16] Host wiring repeats.** `parts/hosts.nix` calls one
  `mkHost` helper now. The Architecture section records the interface and the
  proof. See "Refactor Host Definitions (mkHost)".
- **[x] [DONE 2026-09-15] Hardcoded values repeat across the repository.**
  `hosts/common/options.nix` declares every constant under `my.*` now. The
  Architecture section records the five commits and what stays hardcoded.
  See "Centralize every hardcoded value".
- **[ ] Commented blocks remain.** Large commented blocks sit in
  `parts/hosts.nix`, `modules/system/secrets/sops`, and
  `hosts/common/profiles/desktop.nix`. Remove them or restore them.
  (Review 2026-09-14, finding 6 extends this item.)
- **[x] [DONE 2026-09-15] devShell pin name misleads.** `parts/shells.nix`
  bound `pkgs25_11` to an argument named `pkgs25_05`.
  - *The root cause was the naming scheme, not the number.* A name that holds a
    release number goes stale the moment the input moves. A rename to
    `pkgs25_11` repeats the same defect at the next bump.
  - *Done:* the pin is now `pkgs_deprecated`, after the input
    `nixpkgs_deprecated` that supplies it. It matches the `pkgs_unstable` name
    beside it. The alias line is deleted, so the defect has no home left.
    The rename covers `parts/shells.nix`, `modules/devShells/default.nix` and
    `modules/devShells/tools/azure.nix`, 15 occurrences.
  - *Verified:* both devShells evaluate. The `devops` shell derivation is
    `8g573dr305yl5iyp5ijlfzbm1005cwpf-nix-shell.drv` before AND after the
    rename. An identical derivation proves the change is cosmetic.
- **[ ] stateVersion varies by host** (`24.05`, `24.11`, `25.05`). This is
  correct. Do not change existing values. Add a short note in each host to state
  the rule for new readers.
- **[x] [DONE 2026-09-15] Secret scanning is off.** It now runs in CI.
  - *The premise of this item was wrong, and that matters.* "Re-enable one
    scanner" assumes the pre-commit framework works. It does not.
    `pre-commit` is not on `PATH`, and `.git/hooks` holds **no hook at all**.
    So the `nix-fmt` hook never ran either. Uncommenting a block would have
    changed nothing.
  - *A second gap, found on the way:* `.github/workflows/flake-daily-update.yaml`
    was the ONLY workflow, and it triggers on `schedule` and
    `workflow_dispatch`. **No check of any kind ran on your own commits.**
  - *Done:* `.github/workflows/secret-scan.yaml` runs `gitleaks` on every
    `push` and every `pull_request`. CI cannot be skipped with `--no-verify`
    and needs no per-clone install.
  - *Done:* `.gitleaks.toml` extends the default rule set and allows one path.
  - **Measured, and it is good news: 621 commits hold no real secret.**
    The first run reported 11 leaks. All 11 were the `hashed_secret` SHA-1
    fields inside `.secrets.baseline`, which are hashes, not secrets. The
    encrypted `secrets.yaml` triggers nothing. With the allowlist the scan
    reports `no leaks found`.
  - *Why gitleaks and not detect-secrets:* `detect-secrets` needs a baseline
    that ages. `.secrets.baseline` dates from 2026-01-22 and is already stale,
    because `secrets.yaml` was recreated today. gitleaks needs no baseline.
  - *Trade-off (suboptimal):* CI catches a secret AFTER the push reaches
    GitHub. A local hook catches it before. A local hook is untracked,
    bypassable, and needs a manual install per clone, so it buys less than it
    appears to. Add one only if a real leak happens.
  - *[DONE 2026-09-15] Both dead files are deleted.* The user approved.
    `.secrets.baseline` and `.pre-commit-config.yaml` are gone. The
    `.gitleaks.toml` allowlist stays, because git history keeps the baseline
    after the delete. The scan still reports `no leaks found`.
  - **Correction to the note above.** "pre-commit is not installed" was true of
    `PATH` and of `.git/hooks`, but it was not the whole mechanism.
    `modules/devShells/default.nix` put `pkgs.pre-commit` in both shells, and
    the `devops` shellHook ran `pre-commit install --install-hooks` whenever
    `.pre-commit-config.yaml` existed. The hooks were devShell-gated. This
    clone never entered that shell, so `.git/hooks` stayed empty.
  - **[FIXED 2026-09-15] `nixpush` pushed unformatted code.** This is the real
    damage the dead hooks caused. `modules/home/shells/zsh/default.nix` held a
    "simplified nixpush(), because of pre-commit" whose comment said
    "pre-commit will run treefmt automatically". No hook existed, so nothing
    formatted anything. An older version of the same function, still commented
    out in the generated `.zshrc`, ran `nix fmt` itself.
    - *Done:* `nixpush` runs `nix fmt` again, guarded by `[ -f flake.nix ]` so
      it stays usable in a repository with no flake. The format runs BEFORE
      `git add -A`, which the old commented version got wrong.
    - *Verified:* the new function is in the built
      `home-manager-files/.zshrc`.
  - *[DONE 2026-09-15] Removed `pkgs.pre-commit` from both devShells and the
    install shellHook.* Nothing calls them now.
  - *[DONE 2026-09-15] Fixed a copy-paste defect found on the way.* The
    `default` devShell exported `DEVSHELL_NAME="devops"`, so its zsh prompt
    claimed to be the devops shell. It now exports `default`.

---

## 🔐 Security & Secrets

- [ ] **[DEFERRED 2026-09-15] SOPS-nix Integration.** The module is finished
  and verified. The host does NOT import it.
  - **>>> The user deferred this on 2026-09-15. The code is complete and the
    build is proven. Only the import at
    `hosts/nixos-desktop/configuration.nix` is commented out. Uncomment that
    one line to turn secrets on. Do NOT rebuild this work from scratch. <<<**
  - *Why the `sops-nix` input stays in `flake.nix`:* the module imports it, and
    the module stays. A later dead-input scan flags it, exactly as it flags
    `disko`. This entry is the reason to keep it.
  - *The old blocker, now closed:* `modules/system/secrets/sops/default.nix:3`
    commented out the only `sops-nix` import, and `flake.nix` never declared the
    input. Both are fixed. The input follows the main `nixpkgs` and adds one
    lock node.
  - *The module shrank from 51 lines to 13.* Every deleted line repeated an
    upstream default:
    - `services.openssh.enable` — the host owns the ssh daemon. A secrets
      module must not enable a network daemon.
    - `age.sshKeyPaths` — `sops-nix` defaults this to the ed25519 keys in
      `config.services.openssh.hostKeys`. *Verified* in the built manifest:
      `ageSshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"]` with no explicit
      value in this repository.
    - `age.keyFile` and `generateKey` — a generated key is in no recipient
      list, so it decrypts nothing. The ssh host key already works.
    - `sopsFile`, `format`, `mode` per secret — each one repeated the default.
    - The `owner` conditional on `config.users.users.radekp.enable`. The option
      is real and defaults to `true`, so the test was always true here.
    - `SOPS_AGE_KEY_FILE` in `environment.sessionVariables` — it pointed every
      session at a root-only path that does not exist. Review 2026-09-14,
      finding 2 removed global variables for the same reason.
  - **[FACT 2026-09-15] The old admin key was lost, and the secrets died with
    it.** `.sops.yaml` named one recipient, `age1at2agfd…`. The private half
    existed in none of four places: `~/.config/sops/age/keys.txt` (absent),
    `/var/lib/sops-nix/keys.txt` (absent), `~/.ssh/id_ed25519` → `age1zs6a38…`
    (no match), `/etc/ssh/ssh_host_ed25519_key` → `age1cq7ryk…` (no match).
    The user confirmed the loss. `secrets.yaml` was recreated from scratch.
    The lost content was `test_secret` and `IPs/pinas`, one IP address. That IP
    appears in no `~/.ssh/config` entry, so it is not recoverable here.
  - **[DECIDED 2026-09-15] The admin recipient is now the user ssh key.**
    `age1zs6a38rkxkrp3ala2vc7en46xhctn2v58v2zgt3pfyn4t0wnegysqcurer`, derived
    from `~/.ssh/id_ed25519`. No separate age key file exists to lose. The
    second recipient is the `nixos-desktop` host key, `age1cq7ryk…`.
  - *Documentation:* `modules/system/secrets/sops/README.md` explains the key
    chain, daily use, how to add a host, how to remove a host, and the rules
    that stop a brick. The user asked for this on 2026-09-15.
  - *Verified:* `nix flake check` passed both hosts and the treefmt gate.
    `nixos-rebuild build` succeeded, and the manifest declares
    `test_secret` at `/run/secrets/test_secret`, owner `radekp`, mode `0400`.
  - *Measured:* `nvd diff` reports **+48.6 MiB**, 3 added paths:
    `sops-install-secrets`, `manifest.json`, and `secrets.yaml`. The binary is
    the whole cost. This is the price of secret management on this host.
  - *[DONE 2026-09-15] `treefmt` no longer formats an encrypted file.*
    `prettier` reindented `secrets.yaml` from 4 spaces to 2 on the first run.
    The change was harmless, because YAML indentation carries no data and the
    MAC covers the values. It is still churn on every commit.
    `treefmt.nix` now sets `settings.global.excludes = ["**/secrets/*.yaml"]`.
  - **[PROVEN 2026-09-15] The decryption works at activation.** The user
    switched to generation 376 (`5yh30pwy…`, 17:11). The switch completed, and
    `/run/secrets/test_secret` exists and is readable by `radekp`. A failed
    decrypt aborts the switch, so a completed switch is the proof. The ed25519
    host key alone did the work; no age key file exists on this machine.
  - *Generation 376 still carries sops.* The disconnect needs one more switch.
    Generation 377 removes `sops-install-secrets` again.
  - *Open:* Move sensitive environment variables and udev rules into secrets.
    Nothing on this host reads a secret today.
  - *Open:* restore `IPs/pinas` when you know the address again.
- [x] **[AUDITED 2026-09-15] Security settings on `nixos-desktop`.**
  The audit checked the live system, not only the source. `sshd` is active and
  listens on `0.0.0.0:22` and `[::]:22`.

  - **[DECIDED 2026-09-15] SSH password authentication stays ON.**
    `hosts/nixos-desktop/configuration.nix:53` sets
    `openssh.settings.PasswordAuthentication = true`. That overrides the
    `lib.mkDefault false` in `hosts/common/default.nix:105`.
    - *The reason the override exists:* no key is authorized for this host.
      `/home/radekp/.ssh/authorized_keys` does not exist, and no
      `users.users.radekp.openssh.authorizedKeys` appears for `nixos-desktop`.
      Only `hosts/server/generic` and `hosts/deployments/server/generic`
      declare keys, and neither host is built. A password is therefore the ONLY
      way in. Disabling it without a key removes SSH access entirely.
    - *The user decided on 2026-09-15 to keep the setting.*
      **Do not raise this again as a defect.** It is a recorded choice.
    - *The upgrade path, when you want it:* declare
      `users.users.radekp.openssh.authorizedKeys.keys` with the public half of
      `~/.ssh/id_ed25519`, confirm the key reaches the built system, then delete
      line 53 so the common default applies.
    - *Residual exposure, stated plainly:* port 22 accepts password logins from
      the local network. `PermitRootLogin = "no"` in the common file limits the
      damage to the `radekp` account.

  - **[DONE 2026-09-15] Closed every firewall port with no listener.**
    The block held `allowedTCPPorts = [22 5432 5050]` and
    `allowedUDPPorts = [53 123 5432 5050]`.
    - *Measured:* `ss -tulnp` showed a listener on port 22 only. Ports 5432
      (postgres) and 5050 (pgadmin) served nothing, and a repository-wide grep
      found no `postgresql` or `pgadmin` service anywhere. The two port numbers
      were the only occurrences in the whole repository.
    - *Why inbound UDP 53 and 123 were never needed:* this host is a DNS and
      NTP **client**. A reply to an outbound query returns through conntrack.
      An inbound port serves a **server** only.
    - *Done:* the block is now `allowedTCPPorts = [22];` with a dated comment.
      `allowedUDPPorts` is deleted.
    - *Verified:* in the built `firewall-start` script the rules for 53, 123,
      5432 and 5050 are gone and `dport 22` remains. Ports 1714, 10400-10401
      (KDE Connect) and 27015-27040 (Steam) also remain. Those come from
      `programs.kdeconnect` and the Steam `openFirewall` options, not from this
      list, and the audit did not touch them.

## 🏗 Architecture & Core Refactoring

- [x] **[DONE 2026-09-16] Dynamic disko setup.** The repository holds a disk
  layout library. `nixos-desktop` carries a layout that reproduces the real
  machine. A fresh install is one command.

  **The goal changed, because the original goal was wrong.** This entry used
  to ask for options that build a layout: a device, partition sizes, and a
  filesystem as arguments. The user rejected that on 2026-09-16, and the
  reason is the right one:

  > it turns into a custom made abstraction layer which I still need to
  > understand and look up underlying disko options and pair them with
  > abstractions. That adds work.

  An abstraction you must learn **in addition to** the thing it wraps removes
  no work. It adds a translation step, and it puts a second layer between you
  and a failure that happens on a machine with no operating system. `disko`
  already models LVM, LUKS, mdadm, ZFS and btrfs as options. A `my.disks.*`
  tree on top of that is a second option layer over an option layer, and it
  would lag upstream forever. **Every file this item produced is plain disko
  syntax.** The upstream reference describes your file directly.

  **disko does not scan. disko commands.** This was the open question when the
  work started. You declare the layout and disko destroys, partitions, formats
  and mounts to match. A scanner does the reverse. So no variables file holds
  the device path. `disko-install` takes it as an argument and overrides the
  value in the file, which is what upstream's own example marks with
  `# When using disko-install, we will overwrite this value from the commandline`.
  Each layout keeps `lib.mkDefault` on `device` so that override always wins.

  **What exists now.**

  | File | Layout | Boots |
  |---|---|---|
  | `modules/system/disks/single-disk-ext4.nix` | ext4 root | BIOS and UEFI |
  | `modules/system/disks/single-disk-btrfs.nix` | btrfs subvolumes | BIOS and UEFI |
  | `modules/system/disks/multi-disk-btrfs.nix` | btrfs, plus a data disk | BIOS and UEFI |
  | `modules/system/disks/encrypted-btrfs.nix` | LUKS, then btrfs | UEFI only |
  | `hosts/nixos-desktop/disk-config.nix` | the real desktop: 5G ESP, btrfs `@`, `@home`, `@nix`, `@log` | UEFI |

  `modules/system/disks/README.md` holds the table, the install steps and the
  data-disk warning. No host imports a library layout, because two layouts in
  one host collide. You copy the one you want.

  **The library is not a library of our own.** Upstream ships 39 layouts,
  including ZFS, mdadm, LVM, bcachefs and FIDO2 unlock. These four are the
  common cases, pinned and checked. Anything exotic gets copied from upstream.

  **The data-safety rule, stated once.** disko formats every disk it knows
  about. `hosts/nixos-desktop/disk-config.nix` therefore describes the NVMe and
  nothing else. `sda` and `sdb`, which hold 3.6T of data on `/media/WDRED`,
  never appear in `disko.devices`. They keep their `fileSystems` entries in
  `hardware-configuration.nix`. **A disk disko never sees is a disk disko can
  never erase.** `multi-disk-btrfs.nix` repeats this warning in its header,
  because that template is the one that invites the mistake.

  **Why the live desktop cannot switch on yet.** `configuration.nix` sets
  `disko.enableConfig = false`. Upstream `module.nix` gates exactly three
  attributes behind that flag:

  ```nix
  fileSystems  = lib.mkIf cfg.enableConfig cfg.devices._config.fileSystems  or { };
  boot         = lib.mkIf cfg.enableConfig cfg.devices._config.boot         or { };
  swapDevices  = lib.mkIf cfg.enableConfig cfg.devices._config.swapDevices  or [ ];
  ```

  `system.build` sits outside the guard, so the format script still builds
  while `hardware-configuration.nix` keeps owning every mount. **Do not flip
  this flag on the running machine.** The generated script mounts by partition
  label, `/dev/disk/by-partlabel/disk-main-root`, and the disk in this machine
  carries no disko labels. It mounts by UUID. Flipping the flag would build a
  system that looks for labels that do not exist, and the desktop would not
  boot. Flip it when you reinstall from the layout, not before.

  **Correction to the `mkHost` entry.** It predicted that this item "adds one
  argument to `mkHost`". It does not. `parts/hosts.nix` is unchanged. Host
  files already receive `inputs` through `specialArgs`, so a host imports
  `inputs.disko.nixosModules.disko` and its own layout directly. The prediction
  assumed the abstraction that the user rejected.

  **A defect found on the way.** `disko` was the only input in `flake.nix` with
  no `inputs.nixpkgs.follows`. It pulled a second nixpkgs into the lock
  (`8c3cede7`, 2026-06-08, beside the root `a3116115`). The `follows` is now
  set and the duplicate lock node is gone. The "Flake input bloat" entry asks
  to confirm exactly this on every input.

  **Verified 2026-09-16.**

  | Check | Result |
  |---|---|
  | `system.build.toplevel.outPath`, both hosts | **IDENTICAL** to the baseline. `nixos-desktop` stays `a79mdz7f1pp3wv12lsh0q7rbdnamby49`, `dt-wsl-nix` stays `c24ngj66yxbavd22n976wivx1wi3s62z`. This is the proof that `enableConfig = false` changed nothing. |
  | `nix flake check` | all checks passed, including the treefmt gate and both hosts |
  | all 5 `diskoScript` derivations | build |
  | the desktop script, read by hand | partition 1 is 5G `EF00` labelled `disk-main-ESP`; partition 2 takes the rest as `8300` labelled `disk-main-root`; `mkfs.vfat` and `mkfs.btrfs` run; subvolumes `@`, `@home`, `@nix`, `@log` are created and mounted at `/`, `/home`, `/nix`, `/var/log`, with the pool at `/mnt/btr_pool`. This matches `lsblk` on the live machine. |
  | the multi-disk script, read by hand | `sda` takes a 1M `EF02` slot, a 1G ESP and a btrfs root. `sdb` takes one full partition with `mkfs.xfs`. |
  | `nix build '.#disko-test-single-disk-btrfs'` | **PASSED.** The VM partitioned a blank disk, ran `mkfs.vfat` and `mkfs.btrfs`, created `@`, `@home`, `@log` and `@nix`, mounted each with its options, installed NixOS, powered off, and a second VM booted from the result. 45s. |
  | `nix build '.#disko-test-single-disk-ext4'` | **PASSED.** |

  **Two VM tests were never run.** The user stopped them on 2026-09-16,
  because the run was taking too long on this machine, and chose to try the
  layouts in a VM instead.

  | Not run | State |
  |---|---|
  | `disko-test-multi-disk-btrfs` | script verified by reading it, VM test unfinished |
  | `disko-test-encrypted-btrfs` | script builds, VM test never started |

  *Expect `disko-test-encrypted-btrfs` to need work before it passes.* The
  template sets no `keyFile` and no `passwordFile`, so upstream turns
  `askPassword` on and `disko-format` prompts for a passphrase. That is the
  correct behaviour for a real install and the reason no key material sits in
  this repository, but a VM test runs unattended. Upstream's own
  `example/luks-btrfs-subvolumes.nix` sets `settings.keyFile = "/tmp/secret.key"`
  for exactly this reason, and the harness writes that file. Making the test
  pass needs a test-only key, not a change to the template.

  **The checks are the point.** `parts/disks.nix` builds the partition script
  for every layout on every `nix flake check`. Without it these files would be
  never-evaluated code, which is the class this repository deleted 2739 lines
  of in the Dead code item. A layout must fail in CI, never on an installer
  prompt.

  **Reinstall this desktop.**

  ```console
  lsblk
  sudo nix run 'github:nix-community/disko/latest#disko-install' -- \
    --flake '/etc/nixos#nixos-desktop' --disk main /dev/nvme0n1
  ```

  Set `disko.enableConfig = true` in the same change, because after that
  install the disk does carry the labels. The hardware scan is still needed
  for drivers, and it must skip the disks:
  `nixos-generate-config --no-filesystems --root /mnt`.

  *Open:* `hosts/deployments/server/generic/disk-config.nix` still holds an
  unmodified upstream LVM and ext4 template, and `parts/hosts.nix:68-77` still
  comments that host out. It reproduces no machine. The "Commented blocks
  remain" item owns it.
- [x] **[DONE 2026-09-16] Refactor Host Definitions (mkHost).**
  `parts/hosts.nix` holds one `mkHost` helper. Each host declares only its
  three differences. The helper owns every setting the hosts share.

  **The interface.**

  | Argument | Required | Purpose |
  |---|---|---|
  | `configuration` | yes | the path to the host `configuration.nix` |
  | `homeProfile` | yes | the path to the Home Manager profile of that host |
  | `extraModules` | no, defaults to `[]` | modules that load before the host file |

  `mkHost` owns `system`, `specialArgs`, the `home-manager` NixOS module,
  `useGlobalPkgs`, `useUserPackages`, `backupFileExtension`,
  `extraSpecialArgs`, and the `opencode-stub` patch. Each one appeared twice
  before. Each one appears once now.

  **Why `configuration` takes a full file path and not a directory.** A
  directory argument needs `dir + /configuration.nix` inside the helper. The
  similar `"${dir}/configuration.nix"` copies the whole host directory into
  the nix store, because Nix stores a path when it interpolates one. A full
  path removes that trap and one concept.

  **Why `extraModules` comes first in the module list.** The WSL host loaded
  `inputs.nixos-wsl.nixosModules.wsl` before its own file. The helper keeps
  that order.

  *Verified 2026-09-16:* `system.build.toplevel.outPath` is IDENTICAL before
  and after on both hosts. `nixos-desktop` stays
  `a79mdz7f1pp3wv12lsh0q7rbdnamby49` and `dt-wsl-nix` stays
  `c24ngj66yxbavd22n976wivx1wi3s62z`. A refactor that changes a store path is
  not a refactor. `nix flake check` passed both hosts and the treefmt gate.

  *Note for a later reader:* the attribute name `dt-wsl-nix` and the directory
  `hosts/nixos-wsl` differ. So `mkHost` never derives a path from the attribute
  name. Pass every path explicitly.

  **Left hardcoded on purpose.**

  | What | Why |
  |---|---|
  | `home-manager.users.radekp` | one user, one value. The name appears once now, not twice. The recursion risk that the `my.*` entry records does not apply here, because a helper argument is not a `config` read. Add the parameter when a second user arrives. |
  | `system = "x86_64-linux"` | both hosts use it. A parameter with one value is speculation. |
  | the 3 commented server blocks | the P2 item "Commented blocks remain" owns them. |

  *Next:* the dynamic disko setup and the Host-Wide Version Selector both
  waited on this helper. Each one adds one argument to `mkHost`.

  *Correction, 2026-09-16:* the disko half of that prediction was wrong.
  That work added **no** argument, and `parts/hosts.nix` is unchanged. A host
  file already receives `inputs` through `specialArgs`, so it imports
  `inputs.disko.nixosModules.disko` and its own layout by itself. The
  prediction assumed an option abstraction that the user rejected. The
  Host-Wide Version Selector is still expected to need an argument, because it
  must choose an input before a host evaluates.
- [ ] **Transition to "Smart" Modules**
  - Convert static imports (such as KDE and Plasma) to use `options` and
    `mkEnableOption`. Review 2026-09-14, finding 7 depends on this work.
- [x] **[DONE 2026-09-15] Centralize every hardcoded value.**
  Every constant now lives in one shared option module. No consumer guards
  the read, because every host has every option.

  **The mechanism.** `hosts/common/options.nix` DECLARES `my.user.*`,
  `my.repo.*` and `my.theme.catppuccin`, each with its default. It sets no
  host value. `hosts/common/default.nix` imports it, and both live hosts
  import `hosts/common/default.nix`, so one import reaches both.
  `hosts/<host>/variables.nix` holds host overrides only. Both files are
  empty today, because neither host differs from a default.

  Derive, never store: `my.user.home` comes from `my.user.name`, and
  `my.repo.url` comes from `my.repo.owner` and `my.repo.name`.

  A system module reads `config.my.*`. A Home Manager module reads
  `osConfig.my.*`.

  **The five commits.** Each one was proved by evaluating
  `config.system.build.toplevel.outPath` on both hosts.

  | Step | Commit | Store path |
  |---|---|---|
  | 1 | Add the option module | identical |
  | 2 | Migrate `catppuccinTheme` to `my.theme.catppuccin` | identical |
  | 3 | User identity values | identical |
  | 4 | Repository URL | identical |
  | 5 | Work identity | **changed, as intended** |

  Step 5 changed the path on both hosts. That same check stayed identical
  through steps 1 to 4, which proves the check sees Home Manager edits and
  that the first four steps moved values without changing them.

  **What step 5 fixed.**
  - `dt-wsl-nix` now defaults to `radek.polasek@dynatrace.com`. It is the
    work machine and its default identity was the personal address.
  - The typo `radekp.polasek@dynatrace.com`, with an extra `p`, is gone.
  - `nixos-desktop` lost the `includeIf` for
    `gitdir:/mnt/c/workspaces/dt_workspaces` and the `dynatrace.gitconfig`
    it reached. That path is under `/mnt/c`, so it could never exist there.
  - `nixos-desktop` lost the `includeIf` for `gitdir:/etc/nixos` and
    `personal.gitconfig`. Both repeated the default identity exactly.
    *The user approved this delete on 2026-09-15.*
  - Every `Radek Polasek (Dynatrace)` string is now `my.user.fullName`.
  - Both WSL `includes` blocks and both WSL gitconfig files stay. The
    `insteadOf` URL rewrite in `user-dynatrace-github.gitconfig` survives.

  **Still hardcoded, on purpose.**

  | What | Why |
  |---|---|
  | `users.users.radekp`, `home-manager.users.radekp` | attribute names. A `config` read inside an attribute name risks evaluation recursion. |
  | `modules/home/users/radekp/` | a directory name. Renaming buys nothing while there is one user. |
  | ssh public key material in 2 host files | key material, not a name. Never edit. |
  | `radekp31-nixos` in the 2 workflows | YAML cannot read a Nix option. |
  | `system.stateVersion`, `time.timeZone`, `networking.hostName` | correct to differ per host. |

  *Correction to the old entry:* it claimed `radekp` appears in 26 lines
  across 14 `.nix` files. The measured count before this work was **24 lines
  in 14 files**.

  *Open, for a later pass:* four inactive hosts still write the user name
  out in full — `hosts/desktop-minimal/configuration.nix:183,246`,
  `hosts/hyperv/users.nix`, `hosts/server/generic/users.nix` and
  `modules/system/hardware/printers/brother/DCPL2622DW/default.nix:210`.
  `parts/hosts.nix` does not build any of them, and they do not all import
  `hosts/common/default.nix`, so `config.my.*` does not reach them yet.
  Convert them when `mkHost` gives every host the common import.

  *Next:* `mkHost` reads this same option set to build a host. The two items
  share one data model, and `my.*` came first because `mkHost` depends on it.
- [ ] **Host-Wide Version Selector**
  - Add one option to set the major nixpkgs release per host.
  - Keep an escape hatch to override specific packages from another release.
  - Design it together with `mkHost` and the `my.*` option set.
- [ ] **Clean up Path References**
  - Replace deep relative imports (`../../../../`) with `inputs.self`.
- [x] **[DONE 2026-09-15] Update Auto-Upgrade Logic**
  - `system.autoUpgrade.flake` reads `my.repo.url` now. The option module
    derives that URL from `my.repo.owner` and `my.repo.name`.

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
  - ~~Add pre-commit hooks that apply treefmt automatically.~~ *Reconsidered
    2026-09-15.* The treefmt gate inside `nix flake check` already covers
    formatting, and a local hook is untracked and bypassable. A push-triggered
    workflow is the reliable place. See the Secret scanning entry above.
  - *[DONE 2026-09-15]* `nix flake check` now runs on `push` and
    `pull_request`. Both jobs live in one file, `.github/workflows/ci.yaml`,
    as `gitleaks` and `flake-check`. The separate `secret-scan.yaml` is folded
    into it, so the repository keeps one CI file.
  - *Scope of the check:* it evaluates both hosts and runs the treefmt gate. It
    does NOT build a host closure. The nightly workflow owns that build,
    because a full desktop closure can exhaust a free runner.

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
    - *[DONE 2026-09-16] `disko` was the one input with no `follows`.* It
      pulled a second nixpkgs into the lock, `8c3cede7` from 2026-06-08,
      beside the root `a3116115`. The `follows` is set and the duplicate lock
      node is gone. The remaining extra nixpkgs nodes are deliberate pins:
      `nixpkgs_deprecated`, `nixpkgs_unstable` and `nixpkgs_azcli_pin`.

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
