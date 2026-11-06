#!/bin/sh
# Vezuve OS - reglages appliques une seule fois a la premiere connexion de chaque compte
MARK="$HOME/.config/vezuve-firstlogin-v1"
[ -f "$MARK" ] && exit 0
sleep 8
# Fond d'ecran Vezuve
plasma-apply-wallpaperimage /usr/share/vezuve/wallpapers/lofi.png
# Ne plus lancer le portail et les annonces Bazzite au demarrage
mkdir -p "$HOME/.config/autostart"
for f in io.github.ublue_os.yafti_gtk.desktop bazzite-announcement.desktop; do
  printf '[Desktop Entry]\nHidden=true\n' > "$HOME/.config/autostart/$f"
done
touch "$MARK"
