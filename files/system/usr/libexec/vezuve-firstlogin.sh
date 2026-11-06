#!/bin/sh
# Vezuve OS - reglages appliques une seule fois a la premiere connexion de chaque compte
MARK="$HOME/.config/vezuve-firstlogin-v2"
[ -f "$MARK" ] && exit 0
sleep 8
# Police Vezuve (Plus Jakarta Sans)
F="Plus Jakarta Sans,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file kdeglobals --group General --key font "$F"
kwriteconfig6 --file kdeglobals --group General --key menuFont "$F"
kwriteconfig6 --file kdeglobals --group General --key toolBarFont "$F"
kwriteconfig6 --file kdeglobals --group General --key smallestReadableFont "Plus Jakarta Sans,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kwriteconfig6 --file kdeglobals --group WM --key activeFont "Plus Jakarta Sans,10,-1,5,600,0,0,0,0,0,0,0,0,0,0,1"
# Mood Lofi par defaut (couleurs + fond d'ecran, sans musique au demarrage)
sh /usr/libexec/vezuve-mood.sh lofi --silence
# Ne plus lancer le portail et les annonces Bazzite au demarrage
mkdir -p "$HOME/.config/autostart"
for f in io.github.ublue_os.yafti_gtk.desktop bazzite-announcement.desktop; do
  printf '[Desktop Entry]\nHidden=true\n' > "$HOME/.config/autostart/$f"
done
touch "$MARK"
