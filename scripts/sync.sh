#!/usr/bin/env bash
# Run by a project's workflow after a push or a release, like the LiquidBounce-Theme sync:
#   sync.sh <project> <checkout with history and tags> <translation folder in it> <default branch ref>
# Copies the default branch's translations into <project>/next/ and refreshes the project's latest
# release in <project>/<version>/: that keeps its own wording but takes the default branch's
# translation of every string whose English is unchanged since, so fixes and new languages reach it
# without an update. Older releases stay as they were.
set -euo pipefail
project=$1
checkout=$(realpath "$2")
folder=$3
branch=$4
cd "$(dirname "$0")/.."
english=$(jq -r --arg project "$project" '.[$project].english' projects.json)

# The translation files at a ref, in a new temporary directory.
extract() {
    local dir file
    dir=$(mktemp -d)
    for file in $(git -C "$checkout" ls-tree --name-only "$1" "$folder/" | grep '\.json$'); do
        git -C "$checkout" show "$1:$file" > "$dir/$(basename "$file")"
    done
    echo "$dir"
}

main=$(extract "$branch")
rm -rf "$project/next"
mkdir -p "$project"
cp -r "$main" "$project/next"

tag=$(gh api "repos/$GITHUB_REPOSITORY/releases/latest" --jq .tag_name 2>/dev/null) || exit 0
released=$(extract "$tag")
# Releases from before the project had translations.
[ -f "$released/$english" ] || exit 0

out="$project/${tag#v}"
rm -rf "$out"
cp -r "$released" "$out"
for file in "$main"/*.json; do
    name=$(basename "$file")
    case "$name" in
        "$english") ;;
        languages.json) cp "$file" "$out/" ;;
        *)
            jq -n --slurpfile old <(cat "$released/$name" 2>/dev/null || echo '{}') --slurpfile new "$file" \
                --slurpfile old_en "$released/$english" --slurpfile new_en "$main/$english" '
                def at($p): try getpath($p) catch null;
                reduce ($new[0] | paths(scalars)) as $p ($old[0];
                    ($old_en[0] | at($p)) as $before
                    | if $before != null and $before == ($new_en[0] | at($p)) then setpath($p; $new[0] | getpath($p)) else . end)' \
                > "$out/$name"
            ;;
    esac
done
