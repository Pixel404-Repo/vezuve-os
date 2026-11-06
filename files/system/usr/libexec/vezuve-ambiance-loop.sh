#!/bin/sh
# Vezuve OS - joue une ambiance en boucle (lance par vezuve-mood.sh)
F="$1"
[ -f "$F" ] || exit 1
while true; do
  pw-play --volume=0.5 "$F" 2>/dev/null || paplay "$F" || exit 1
done
