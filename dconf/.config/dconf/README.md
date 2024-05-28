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


