#!/usr/bin/env bash
# Copies a course module (a proyecto-*-template / proyecto-*-base checkout) into a student
# repository created from proyecto-base, and registers its npm scripts in the root package.json.
#
# Used by the setup-* composite actions of this repository and by the teaching team's local
# simulator, so both always install modules the same way.
#
# Usage: install-module.sh <group> <id> <source-dir> <target-repo-dir>
#   group            e2e | vrt | reconocimiento (npm workspace folder in proyecto-base)
#   id               module id, e.g. cypress, backstopjs, monkey
#   source-dir       checkout of the module repository
#   target-repo-dir  checkout of the student repository
set -euo pipefail

usage() {
  echo "Usage: $(basename "$0") <e2e|vrt|reconocimiento> <id> <source-dir> <target-repo-dir>" >&2
  exit 2
}

[[ $# -eq 4 ]] || usage
group=$1
id=$2
source_dir=$3
target_dir=$4

case "$group" in
  e2e | vrt | reconocimiento) ;;
  *) echo "Unknown group: '$group'" >&2; usage ;;
esac
if [[ ! "$id" =~ ^[a-z0-9-]+$ ]]; then
  echo "Invalid module id: '$id'" >&2
  exit 2
fi
if [[ ! -d "$source_dir" ]]; then
  echo "Source directory not found: $source_dir" >&2
  exit 1
fi
if [[ ! -f "$target_dir/package.json" ]]; then
  echo "Target repository has no package.json: $target_dir" >&2
  exit 1
fi

workspace="misw-4103-$id"

echo "Copying files from $source_dir to $target_dir/$group/$workspace"
# .github is excluded so a module's own CI workflows are not copied into the student repository.
rsync -a --exclude='.git' --exclude='.github' --exclude='package-lock.json' "$source_dir/" "$target_dir/$group/$workspace/"
echo "Files copied successfully"

echo "Setting up scripts for $id in the root package.json"
cd "$target_dir"

set_script() {
  npm pkg set "scripts.$id:$1=$2"
}

if [[ "$group:$id" == "e2e:kraken" ]]; then
  # kraken-node requires undeclared dependencies at runtime, so it needs the default (hoisted) layout.
  set_script install "npm install -w $workspace"
else
  set_script install "npm install --install-strategy=nested -w $workspace"
fi
set_script prepare "npm run prepare -w $workspace"
set_script test "npm run test -w $workspace"

case "$group:$id" in
  vrt:backstopjs)
    set_script reference "npm run reference -w $workspace"
    set_script approve "npm run approve -w $workspace"
    set_script ui "npm run test:ui -w $workspace"
    ;;
  vrt:pixelmatch | vrt:resemblejs)
    set_script report "npm run report -w $workspace"
    ;;
  vrt:*) ;;
  reconocimiento:ripper)
    set_script ui "npm run test:ui -w $workspace"
    set_script resume "npm run resume -w $workspace"
    ;;
  *)
    set_script ui "npm run test:ui -w $workspace"
    ;;
esac
