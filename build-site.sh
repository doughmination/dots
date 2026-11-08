#!/usr/bin/env bash
# build-site.sh: build dots.doughmination.gay into public/. Cloudflare Pages runs
# this on every push (build command: bash build-site.sh, output: public).
#
# public/ gets the web page, the installer, and the whole repo as a tarball for
# the installer to download. Pages refuses files over 25 MiB, so the tarball is
# split into 20 MB pieces, listed in dots.parts, with its checksum next to it.

set -euo pipefail

cd "$(dirname "$0")"
OUT=public
PIECE=20m

rm -rf "$OUT"
mkdir -p "$OUT"

cp \
  index.html \
  site.css \
  screenshot.png \
  install \
  "$OUT/"

# Kept at the same path so the page works from the repo root too
cp --parents gtklock/avatar.png "$OUT/"

git archive --format=tar.gz HEAD >"$OUT/dots.tar.gz"
(cd "$OUT" && sha256sum dots.tar.gz >dots.tar.gz.sha256)

split -b "$PIECE" "$OUT/dots.tar.gz" "$OUT/dots.tar.gz.part-"
rm "$OUT/dots.tar.gz"
(cd "$OUT" && ls dots.tar.gz.part-* >dots.parts)

echo "Built $OUT/:"
ls -l "$OUT"
