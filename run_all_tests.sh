#!/bin/bash

cd /Users/gao/Workspace/gsmlg-app/homelab_simulator

packages=(
  "app_lib/core"
  "app_lib/engine"
  "app_lib/database"
  "app_lib/logging"
  "app_lib/secure_storage"
  "app_lib/locale"
  "app_bloc/game"
  "game_bloc/world"
  "game_widgets/panels"
  "game_widgets/hud"
  "game_widgets/shop"
  "game_asset/characters"
  "game_objects/room"
  "game_objects/character"
  "game_objects/devices"
  "game_objects/world"
  "app_widget/common"
)

results_dir=$(mktemp -d)

run_test_for_pkg() {
  local pkg=$1
  local output_file="$results_dir/${pkg//\//_}.txt"
  
  if [ -d "$pkg/test" ]; then
    cd "$pkg"
    flutter test > "$output_file" 2>&1
    cd - > /dev/null
  else
    echo "NO_TEST" > "$output_file"
  fi
}

# Run all tests in parallel
for pkg in "${packages[@]}"; do
  run_test_for_pkg "$pkg" &
done

wait

echo "=== Test Results Summary ==="
total=0

for pkg in "${packages[@]}"; do
  output_file="$results_dir/${pkg//\//_}.txt"
  if [ -f "$output_file" ]; then
    content=$(cat "$output_file")
    if [ "$content" = "NO_TEST" ]; then
      echo "$pkg: No test directory"
    else
      count=$(echo "$content" | grep -oE "^\+[0-9]+" | head -1 | grep -oE "[0-9]+")
      if [ -z "$count" ]; then
        if echo "$content" | grep -q "All tests passed"; then
          count=$(echo "$content" | tail -5 | grep -oE "[0-9]+ passed" | grep -oE "^[0-9]+")
        fi
      fi
      if [ -z "$count" ]; then
        count=0
      fi
      echo "$pkg: $count tests"
      total=$((total + count))
    fi
  fi
done

echo ""
echo "GRAND TOTAL: $total tests"

rm -rf "$results_dir"
