#!/bin/bash

prev=""
playerctl -p spotify --follow metadata --format '"{{title}}" by "{{artist}}"' | while read -r line; do
  text=""

  if [[ -n "$prev" ]]; then
    text="We just listened to $prev. And next up is $line."
  else
    text="Now playing $line."
  fi
  prev="$line"

  volume=$(echo "scale=0; (100 * $(playerctl -p spotify metadata --format '{{volume}}'))/1" | bc)

  echo "$volume $text"

  # Generate TTS locally with supertonic
  supertonic tts "$text" -o /tmp/spotify_tts.wav
  ffplay -loglevel fatal /tmp/spotify_tts.wav -autoexit -nodisp -volume $volume
done
