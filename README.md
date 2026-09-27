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

Конфиг рассчитан на NixOS 25.11 и `x86_64-linux`. Он включает Hyprland, Home Manager, SDDM, оформление рабочего стола и локальные пакеты. Flake-выход называется `nixosConfigurations.example`.

Публичная версия обезличена: в ней используются шаблонные `configuser` и `confighost`, UTC и аппаратный файл с недействительными UUID. Личные настройки подставляются только в локальном клоне.

### Установка

Нужны Git, установленная NixOS и права `sudo`. Замените `OWNER/REPO` на адрес репозитория:

```bash
git clone https://github.com/OWNER/REPO.git nixos-config
cd nixos-config
./scripts/configure-local.sh
sudo env NIX_CONFIG='experimental-features = nix-command flakes' nixos-rebuild build --flake .#example
sudo env NIX_CONFIG='experimental-features = nix-command flakes' nixos-rebuild switch --flake .#example
```

Скрипт подставляет текущие имя пользователя и хоста и копирует `/etc/nixos/hardware-configuration.nix` в локальный клон. Чтобы задать другие значения, используйте `./scripts/configure-local.sh USERNAME HOSTNAME`.

Перед `switch` проверьте `git diff`, особенно `hosts/example/hardware-configuration.nix`, настройки загрузчика, `/boot`, службы и `system.stateVersion`. Значение `system.stateVersion` должно соответствовать первоначальному выпуску **вашей** установленной системы. `build` только собирает систему; `switch` применяет её. Вернуться к предыдущему поколению можно через меню загрузчика или `sudo nixos-rebuild switch --rollback`.

После запуска скрипта в рабочем каталоге появятся ваше имя пользователя, имя хоста и UUID дисков. **Не коммитьте и не отправляйте эти локальные изменения в публичный репозиторий.** Держите персонализированный клон локально или в отдельном приватном репозитории.

### Структура

- `flake.nix`, `flake.lock` — зависимости и конфигурация NixOS.
- `hosts/example/` — системные настройки и аппаратный шаблон.
- `home/example/` — Home Manager и настройки рабочего стола.
- `modules/` — общие модули NixOS.
- `packages/` — локальные пакеты.

Свои язык, сеть, оборудование и часовой пояс настройте в локальном клоне. При первой сборке некоторые пакеты скачивают внешние исходники; версии Nix-зависимостей закреплены в `flake.lock`.

## English

### What's included

This configuration targets NixOS 25.11 on `x86_64-linux`. It includes Hyprland, Home Manager, SDDM, desktop styling, and local packages. The flake output is `nixosConfigurations.example`.

The public version uses neutral `configuser`, `confighost`, UTC, and a hardware template with invalid UUIDs. Machine-specific settings are inserted only into your local clone.

### Installation

You need Git, an installed NixOS system, and `sudo` access. Replace `OWNER/REPO` with the repository address:

```bash
git clone https://github.com/OWNER/REPO.git nixos-config
cd nixos-config
./scripts/configure-local.sh
sudo env NIX_CONFIG='experimental-features = nix-command flakes' nixos-rebuild build --flake .#example
sudo env NIX_CONFIG='experimental-features = nix-command flakes' nixos-rebuild switch --flake .#example
```

The script inserts your current username and hostname and copies `/etc/nixos/hardware-configuration.nix` into the local clone. To choose different values, run `./scripts/configure-local.sh USERNAME HOSTNAME`.

Before `switch`, review `git diff`, especially `hosts/example/hardware-configuration.nix`, the bootloader, `/boot`, enabled services, and `system.stateVersion`. Keep `system.stateVersion` at the value matching **your** system's initial installation release. `build` only builds the system; `switch` applies it. To return to an earlier generation, use the boot menu or `sudo nixos-rebuild switch --rollback`.

After setup, your working tree contains your username, hostname, and disk UUIDs. **Do not commit or push these local changes to the public repository.** Keep the personalized clone local or in a separate private repository.

### Layout

- `flake.nix`, `flake.lock`: dependencies and NixOS configuration.
- `hosts/example/`: system settings and hardware template.
- `home/example/`: Home Manager and desktop configuration.
- `modules/`: shared NixOS modules.
- `packages/`: local packages.

Set your language, network, hardware, and timezone in the local clone. Some packages download external sources on the first build; `flake.lock` pins the Nix dependencies.
