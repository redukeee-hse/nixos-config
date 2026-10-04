[Русский](#русский) · [English](#english)

# NixOS + Hyprland

**RU:** Это мой конфиг NixOS. За основу я взял конфигурацию другого автора и переработал её под свои задачи. Я хотел сделать рабочий стол одновременно красивым и удобным.

**EN:** This is my NixOS configuration. I started with another person's setup and adapted it to my workflow. My goal was a desktop that looks good and is comfortable to use.

### Скриншоты / Screenshots

Нажмите на изображение, чтобы открыть его в полном размере. / Click an image to view it in full size.

| Гроза / Storm | Лес / Forest | Горы / Mountains |
| :---: | :---: | :---: |
| [![Dark desktop with a storm wallpaper](docs/screenshots/storm.png)](docs/screenshots/storm.png) | [![Green desktop with a forest wallpaper](docs/screenshots/forest.png)](docs/screenshots/forest.png) | [![Purple desktop with a mountain wallpaper](docs/screenshots/mountains.png)](docs/screenshots/mountains.png) |

## Русский

### Что внутри

Конфиг рассчитан на NixOS 26.05 и `x86_64-linux`. Он включает Hyprland, Home Manager, SDDM, оформление рабочего стола и локальные пакеты. Flake-выход называется `nixosConfigurations.example`.

Публичная версия обезличена: в ней используются шаблонные `configuser` и `confighost`, UTC и аппаратный файл с недействительными UUID. Личные настройки подставляются только в локальном клоне.

### Установка

Нужна уже установленная NixOS (x86_64) и пользователь с правами `sudo`. Все команды выполняются от имени этого пользователя, не от root.

**1. Скачайте конфиг.** Клонируйте именно в `~/nixos-config`: по этому пути панель настроек Quickshell открывает конфиги. Если Git ещё не установлен, `nix-shell` временно его даст.

```bash
nix-shell -p git --run 'git clone https://github.com/redukeee-hse/nixos-config.git ~/nixos-config'
cd ~/nixos-config
```

**2. Подставьте свои данные.** Скрипт заменит шаблонные `configuser` и `confighost` на ваши текущие имя пользователя и хоста и скопирует ваш `/etc/nixos/hardware-configuration.nix`.

```bash
./scripts/configure-local.sh
```

Нужны другие имя пользователя или хоста: `./scripts/configure-local.sh USERNAME HOSTNAME`. Скрипт работает только на чистом клоне, поэтому запускайте его сразу после `git clone`.

**3. Проверьте изменения.** Посмотрите `git diff` и откройте `hosts/example/default.nix`: значение `system.stateVersion` должно совпадать с версией NixOS, с которой **ваша** система была установлена изначально (его видно в `/etc/nixos/configuration.nix`). Конфиг использует GRUB в режиме UEFI (`modules/system/boot.nix`); если у вас systemd-boot или загрузка в режиме BIOS, поправьте этот файл.

```bash
git diff
```

**4. Соберите и примените.** `build` только собирает систему и ничего не меняет; если он прошёл без ошибок, `switch` применяет её.

```bash
sudo env NIX_CONFIG='experimental-features = nix-command flakes' nixos-rebuild build --flake .#example
sudo env NIX_CONFIG='experimental-features = nix-command flakes' nixos-rebuild switch --flake .#example
```

**5. Перезагрузитесь** и войдите в сессию Hyprland через SDDM.

Если что-то пошло не так, выберите предыдущее поколение в меню загрузчика или выполните `sudo nixos-rebuild switch --rollback`.

После шага 2 в клоне лежат ваши имя пользователя, имя хоста и UUID дисков. **Не коммитьте и не пушьте эти изменения в этот публичный репозиторий.** Держите личную копию локально или в своём приватном репозитории.

### Структура

- `flake.nix`, `flake.lock` — зависимости и конфигурация NixOS.
- `hosts/example/` — имя хоста, `system.stateVersion` и аппаратный шаблон.
- `modules/system/` — Nix, загрузчик, сеть, локаль и пользователь.
- `modules/hardware/` — звук (PipeWire), Bluetooth и питание.
- `modules/desktop/` — Hyprland, вход через SDDM с собственной темой и шрифты.
- `modules/services/` — Docker, nginx, PostgreSQL и Happ.
- `home/example/` — Home Manager и настройки рабочего стола.
- `packages/` — локальные пакеты.

Свои язык, сеть, оборудование и часовой пояс настройте в локальном клоне. При первой сборке некоторые пакеты скачивают внешние исходники; версии Nix-зависимостей закреплены в `flake.lock`.

## English

### What's included

This configuration targets NixOS 26.05 on `x86_64-linux`. It includes Hyprland, Home Manager, SDDM, desktop styling, and local packages. The flake output is `nixosConfigurations.example`.

The public version uses neutral `configuser`, `confighost`, UTC, and a hardware template with invalid UUIDs. Machine-specific settings are inserted only into your local clone.

### Installation

You need an installed NixOS system (x86_64) and a user with `sudo` access. Run every command as that user, not as root.

**1. Get the config.** Clone it into `~/nixos-config` exactly: the Quickshell settings panel opens config files from that path. If Git is not installed yet, `nix-shell` provides it temporarily.

```bash
nix-shell -p git --run 'git clone https://github.com/redukeee-hse/nixos-config.git ~/nixos-config'
cd ~/nixos-config
```

**2. Fill in your machine.** The script replaces the placeholder `configuser` and `confighost` with your current username and hostname and copies your `/etc/nixos/hardware-configuration.nix`.

```bash
./scripts/configure-local.sh
```

For a different username or hostname, run `./scripts/configure-local.sh USERNAME HOSTNAME`. The script only runs on a clean clone, so run it right after `git clone`.

**3. Review the changes.** Look through `git diff` and open `hosts/example/default.nix`: `system.stateVersion` must match the NixOS release **your** system was originally installed with (see `/etc/nixos/configuration.nix`). The config uses GRUB in UEFI mode (`modules/system/boot.nix`); if you use systemd-boot or BIOS boot, adjust that file.

```bash
git diff
```

**4. Build and apply.** `build` only builds the system and changes nothing; if it succeeds, `switch` applies it.

```bash
sudo env NIX_CONFIG='experimental-features = nix-command flakes' nixos-rebuild build --flake .#example
sudo env NIX_CONFIG='experimental-features = nix-command flakes' nixos-rebuild switch --flake .#example
```

**5. Reboot** and log in to the Hyprland session from SDDM.

If something breaks, pick the previous generation in the boot menu or run `sudo nixos-rebuild switch --rollback`.

After step 2, your clone contains your username, hostname, and disk UUIDs. **Do not commit or push these changes to this public repository.** Keep your personal copy local or in your own private repository.

### Layout

- `flake.nix`, `flake.lock`: dependencies and NixOS configuration.
- `hosts/example/`: hostname, `system.stateVersion`, and hardware template.
- `modules/system/`: Nix, bootloader, networking, locale, and the user account.
- `modules/hardware/`: sound (PipeWire), Bluetooth, and power management.
- `modules/desktop/`: Hyprland, SDDM login with a custom theme, and fonts.
- `modules/services/`: Docker, nginx, PostgreSQL, and Happ.
- `home/example/`: Home Manager and desktop configuration.
- `packages/`: local packages.

Set your language, network, hardware, and timezone in the local clone. Some packages download external sources on the first build; `flake.lock` pins the Nix dependencies.
