#!/usr/bin/env bash
# Publishes every <project>/<version>/ to _site with an index.json of the translations it has.
# Names and Minecraft codes come from the folder's languages.json; without one, a file is named by
# its Minecraft code (LiquidBounce).
set -euo pipefail
shopt -s nullglob
cd "$(dirname "$0")/.."
rm -rf _site
mkdir _site

for project in $(jq -r 'keys[]' projects.json); do
    english=$(jq -r --arg project "$project" '.[$project].english' projects.json)
    for folder in "$project"/*/; do
        out="_site/$project/$(basename "$folder")"
        mkdir -p "$out"
        if [ -f "$folder/languages.json" ]; then
            languages=$(jq --arg english "${english%.json}" 'del(.[$english]) | with_entries(.value.file = (.value.catalog // .key) + ".json" | .value |= del(.catalog))' "$folder/languages.json")
        else
            languages=$(cd "$folder" && ls *.json | jq -R --arg english "$english" 'select(. != $english) | rtrimstr(".json") | {key: ., value: {minecraft: ., file: (. + ".json")}}' | jq -s from_entries)
        fi
        for code in $(jq -r 'keys_unsorted[]' <<< "$languages"); do
            file=$(jq -r --arg code "$code" '.[$code].file' <<< "$languages")
            [ -f "$folder$file" ] || continue
            jq empty "$folder$file"
            cp "$folder$file" "$out/$file"
            jq --arg code "$code" --arg sha256 "$(sha256sum "$folder$file" | cut -d' ' -f1)" \
                '{code: $code} + .[$code] + {sha256: $sha256}' <<< "$languages"
        done | jq -s '{languages: .}' > "$out/index.json"
    done
done
