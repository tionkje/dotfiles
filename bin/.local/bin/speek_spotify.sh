
#!/bin/bash

prev=""
playerctl -p spotify --follow metadata --format '"{{title}}" van "{{artist}}"' | while read -r line; do
  text=""

  if [[ -n "$prev" ]]; then
    text="We luisterden net naar $prev. - En het volgende liedje wordt $line.";
  else
    text="We luisteren nu naar $line.";
  fi
  prev="$line"

  volume=$(echo  "scale=0; (50 * $(playerctl -p spotify metadata --format '{{volume}}'))/1" | bc)

  echo "$volume $text"

  curl -s -X POST \
    "https://api.elevenlabs.io/v1/text-to-speech/pNInz6obpgDQGcFmaJgB/stream" \
    -H "Accept: audio/mpeg" \
    -H "Content-Type: application/json" \
    -H "xi-api-key: $(cat ~/.ssh/elevenlabs_spotify_apikey.txt)" \
    -d '{
      "text": "'"${text//\"/\\\"}"'",
      "model_id": "eleven_turbo_v2_5",
      "voice_settings": {
        "stability": 0.5,
        "similarity_boost": 1.0,
        "style": 0.0,
        "use_speaker_boost": true
      }
    }' | ffplay -loglevel fatal - -autoexit -nodisp -volume $volume ; done
done
