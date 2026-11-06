#!/bin/sh
# Vezuve OS - changement de Mood : couleurs + fond d'ecran + ambiance musicale
# Usage : vezuve-mood.sh lofi|rain|ninja [--silence]   ou   vezuve-mood.sh stop
MOOD="${1:-lofi}"
case "$MOOD" in
  lofi)  SCHEME=VezuveLofi;  WP=lofi;  AMB=lofi ;;
  rain)  SCHEME=VezuveRain;  WP=rain;  AMB=lofi_rain ;;
  ninja) SCHEME=VezuveNinja; WP=ninja; AMB=anime_ninja ;;
  stop)
    pkill -f vezuve-ambiance-loop
    pkill -f /usr/share/vezuve/ambiances/
    exit 0 ;;
  *) echo "Mood inconnu : $MOOD (lofi, rain, ninja ou stop)"; exit 1 ;;
esac
plasma-apply-colorscheme "$SCHEME"
plasma-apply-wallpaperimage "/usr/share/vezuve/wallpapers/$WP.png"
mkdir -p "$HOME/.config"
echo "$MOOD" > "$HOME/.config/vezuve-mood"
# On coupe l'ambiance precedente
pkill -f vezuve-ambiance-loop
pkill -f /usr/share/vezuve/ambiances/
[ "$2" = "--silence" ] && exit 0
# Ambiance du Mood en boucle, en arriere-plan
nohup sh /usr/libexec/vezuve-ambiance-loop.sh "/usr/share/vezuve/ambiances/$AMB.ogg" >/dev/null 2>&1 &
exit 0
