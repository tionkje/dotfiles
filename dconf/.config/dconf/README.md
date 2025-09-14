
TODO: install manually
- media controls https://extensions.gnome.org/extension/4928/mpris-label/
- system monitor https://extensions.gnome.org/extension/3010/system-monitor-next/

Backup:
```sh
dconf dump / > dconf-$(date -I).conf
```

Dump:
```sh
dconf dump /org/gnome/ > gnome-dconf.conf
```

Load:
```sh
dconf load /org/gnome/ < gnome-dconf.conf
```

Source:
https://askubuntu.com/questions/26056/where-are-gnome-keyboard-shortcuts-stored/217310#217310

Watch changes:
```sh
dconf watch /
```

Load and dump window management keybindingd
```sh
dconf dump /org/gnome/desktop/wm/keybindings/ > gnome-wm-keybindings.conf
dconf load /org/gnome/desktop/wm/keybindings/ < gnome-wm-keybindings.conf
```
