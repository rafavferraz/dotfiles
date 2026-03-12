#!/bin/bash

folders=(
  "$HOME/Videos"
  "$HOME/Templates"
  "$HOME/Public"
  "$HOME/Pictures"
  "$HOME/Music"
  "$HOME/Documents"
  "$HOME/Desktop"
)

for folder in "${folders[@]}"; do
  if [ -d "$folder" ]; then
    rm -rf "$folder"
    echo "Deleted: $folder"
  else
    echo "Not found: $folder"
  fi
done
