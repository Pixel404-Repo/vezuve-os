#!/bin/sh
# Vezuve OS - joue une ambiance en boucle (lance par vezuve-mood.sh ou l'appli Vezuve Mood)
# Usage : vezuve-ambiance-loop.sh FICHIER [VOLUME 0.0-1.0]
F="$1"
V="${2:-0.5}"
[ -f "$F" ] || exit 1
while true; do
  pw-play --volume="$V" "$F" 2>/dev/null || paplay "$F" || exit 1
done
