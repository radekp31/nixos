# Secrets with sops-nix

## How the chain works

A secret file is encrypted to a list of **recipients**. A recipient is an age
public key. Any private key in that list decrypts the file. There is no master
key and no password.

This repository uses two kinds of recipient:

| Recipient | Private half lives in           | Purpose                        |
| --------- | ------------------------------- | ------------------------------ |
| **admin** | `~/.ssh/id_ed25519`             | You read and edit the secrets. |
| **host**  | `/etc/ssh/ssh_host_ed25519_key` | The machine decrypts at boot.  |

Both are ssh ed25519 keys. `ssh-to-age` converts an ssh key to an age key.
The conversion is deterministic, so the same ssh key always gives the same age
key. No extra key file exists to lose.

`.sops.yaml` holds the recipient list. Each encrypted file also holds its own
copy of that list, written at the time of encryption.

**This is the fact that surprises people:** `.sops.yaml` is the rule for _new_
files only. An existing file keeps its own recipient list until you rewrite it.

## Files

| Path                                               | Role                                                  |
| -------------------------------------------------- | ----------------------------------------------------- |
| `.sops.yaml` (repository root)                     | The recipient list. Edit this to add or remove a key. |
| `modules/system/secrets/sops/secrets/secrets.yaml` | The encrypted secrets.                                |
| `modules/system/secrets/sops/default.nix`          | Declares which secrets the host installs.             |

## Daily use

### Edit a secret

```sh
sops modules/system/secrets/sops/secrets/secrets.yaml
```

Your editor opens the plaintext. sops re-encrypts on save. The plaintext never
touches the repository.

### Add a secret

1. Add the key and the value with `sops`, as above.
2. Declare it in `default.nix`:

   ```nix
   sops.secrets.my_secret.owner = "radekp";
   ```

3. Rebuild. The value appears at `/run/secrets/my_secret`, mode `0400`.

A nested YAML key uses a slash: `sops.secrets."IPs/pinas"` reads `IPs.pinas`.

### Read a secret in a NixOS option

Pass the **path**, never the value. A value in a Nix string lands in the world
readable nix store.

```nix
services.foo.passwordFile = config.sops.secrets.my_secret.path;
```

## Add a new host

A new machine has no ssh host key until it boots once. So the order matters.

1. Install the host **without** the sops module. Enable
   `services.openssh.enable = true`.
2. Boot it. NixOS generates `/etc/ssh/ssh_host_ed25519_key`.
3. Read the age key on that host:

   ```sh
   nix run nixpkgs#ssh-to-age -- -i /etc/ssh/ssh_host_ed25519_key.pub
   ```

4. Add the key to `.sops.yaml`, both under `keys` and under the
   `key_groups` of every rule the host must read.
5. Re-encrypt every existing file to the new list. **Step 4 alone does
   nothing.**

   ```sh
   sops updatekeys modules/system/secrets/sops/secrets/secrets.yaml
   ```

6. Import the sops module in that host and rebuild.

Run step 5 on a machine that already decrypts the file. `updatekeys` must read
the file before it can rewrite it.

## Remove a host

1. Remove the sops module from that host. Rebuild and switch it **first**.
2. Delete its key from `.sops.yaml`.
3. Run `sops updatekeys` on every secret file.

Keep this order. A host that still imports the module, but is no longer a
recipient, fails activation on its next switch.

Removal does not recall the old data. The host held the plaintext. Rotate any
secret that the removed host could read.

## Rules that stop a brick

- **Keep the admin key on every file.** If only host keys remain, no person
  can edit the file again.
- **Run `sops updatekeys` after every `.sops.yaml` change.** The file and the
  rule drift apart otherwise.
- **Back up `~/.ssh/id_ed25519`.** It is now the admin key. Lose it and every
  host key, and the data is gone for good.
- **A failed decrypt fails the switch, not the boot.** The running generation
  stays. Fix the recipients and switch again.
- **Never commit plaintext.** Use `sops` to edit. Do not decrypt to a file
  inside the repository.

## History

The previous admin key `age1at2agfd…` was lost. Its private half existed in no
backup, and neither ssh key derived it, so `secrets.yaml` became permanently
undecryptable. The file was recreated from scratch on 2026-09-15 with the two
recipients above. The lost content was `test_secret` and one IP address.
