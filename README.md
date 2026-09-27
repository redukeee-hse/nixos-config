# NixOS configuration template

A public NixOS 25.11 template for `x86_64-linux` with Hyprland, Home Manager, SDDM, and local packages. The public Git history contains no machine or account identifiers. The flake output is `nixosConfigurations.example`.

## Install on NixOS

You need Git, NixOS, and `sudo` access. Replace `OWNER/REPO` with the repository address. The setup script inserts your local username and hostname, then copies your machine's hardware configuration into **your local clone**.

```bash
git clone https://github.com/OWNER/REPO.git nixos-config
cd nixos-config
./scripts/configure-local.sh
sudo env NIX_CONFIG='experimental-features = nix-command flakes' nixos-rebuild build --flake .#example
sudo env NIX_CONFIG='experimental-features = nix-command flakes' nixos-rebuild switch --flake .#example
```

To choose a different username or hostname, run `./scripts/configure-local.sh USERNAME HOSTNAME`. Before `switch`, review `git diff`, especially `hosts/example/hardware-configuration.nix`, the bootloader, `/boot`, enabled services, and `system.stateVersion`. Keep `system.stateVersion` at the value matching **your** system's initial installation release. `build` only builds the system; `switch` applies it. To return to an earlier generation, use the boot menu or `sudo nixos-rebuild switch --rollback`.

After setup, your working tree contains your username, hostname, and disk UUIDs. **Do not commit or push these local changes to the public repository.** Keep the personalized clone local or in a separate private repository. Clone the public template again when you need a clean copy.

## Layout

- `flake.nix`, `flake.lock`: inputs and NixOS configuration.
- `hosts/example/`: system settings and hardware template with invalid UUIDs.
- `home/example/`: Home Manager and desktop configuration.
- `modules/`: shared NixOS modules.
- `packages/`: local packages.

The template uses neutral `configuser`, `confighost`, and UTC defaults. Set your own language, network, hardware, and timezone in the local clone. Some packages download external sources on the first build; `flake.lock` pins the Nix dependencies.
