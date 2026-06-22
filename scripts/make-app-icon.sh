#!/usr/bin/env bash
# Build AppIcon.icns — white ghost on black square.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SVG="${ROOT}/Resources/ghost-mirror-mark.svg"
ICON_GHOST="${ROOT}/Resources/ghost-mirror-icon-ghost.png"
WORK="${ROOT}/.build/icon-work"
ICONSET="${WORK}/AppIcon.iconset"
OUT="${ROOT}/Resources/AppIcon.icns"

mkdir -p "$WORK" "$ICONSET"
cp "${ROOT}/../ghostcloud-app/static/ghost-mirror-mark.svg" "$SVG" 2>/dev/null || true

if [[ ! -f "$SVG" ]]; then
  echo "Missing ghost mark SVG at $SVG" >&2
  exit 1
fi

qlmanage -t -s 1024 -o "$WORK" "$SVG" >/dev/null 2>&1
GHOST="${WORK}/ghost-mirror-mark.svg.png"
[[ -f "$GHOST" ]] || { echo "qlmanage failed to render ghost PNG" >&2; exit 1; }
if [[ -f "$ICON_GHOST" ]]; then
  GHOST="$ICON_GHOST"
fi

swift - <<'SWIFT' "$GHOST" "$WORK/base-1024.png"
import AppKit
import Foundation

let args = CommandLine.arguments
guard args.count >= 3,
      let ghost = NSImage(contentsOf: URL(fileURLWithPath: args[1])) else {
    fputs("icon compose failed\n", stderr)
    exit(1)
}
let canvas: CGFloat = 1024
let img = NSImage(size: NSSize(width: canvas, height: canvas))
img.lockFocus()
let rect = NSRect(x: 0, y: 0, width: canvas, height: canvas)
let background = NSGradient(colors: [
    NSColor(calibratedWhite: 0.15, alpha: 1),
    NSColor(calibratedWhite: 0.055, alpha: 1),
    NSColor(calibratedWhite: 0.015, alpha: 1)
])!
background.draw(in: rect, angle: -90)

let gloss = NSGradient(colors: [
    NSColor(calibratedWhite: 1, alpha: 0.10),
    NSColor(calibratedWhite: 1, alpha: 0.025),
    NSColor(calibratedWhite: 1, alpha: 0)
])!
gloss.draw(in: rect, angle: -90)

NSColor(calibratedWhite: 0, alpha: 0.98).setStroke()
let border = NSBezierPath(rect: rect.insetBy(dx: 3, dy: 3))
border.lineWidth = 6
border.stroke()

let pad: CGFloat = 96
let drawRect: NSRect
if abs(ghost.size.width - ghost.size.height) < 1 {
    drawRect = rect
} else {
    let drawW = canvas - pad * 2
    let aspect = ghost.size.height / max(ghost.size.width, 1)
    let drawH = min(canvas - pad * 2, drawW * aspect)
    drawRect = NSRect(x: (canvas - drawW) / 2, y: (canvas - drawH) / 2, width: drawW, height: drawH)
}
ghost.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1)
img.unlockFocus()
guard let tiff = img.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fputs("png export failed\n", stderr)
    exit(1)
}
try png.write(to: URL(fileURLWithPath: args[2]))
SWIFT

declare -a SIZES=(16 32 64 128 256 512 1024)
for size in "${SIZES[@]}"; do
  base="${WORK}/base-1024.png"
  out="${ICONSET}/icon_${size}x${size}.png"
  sips -z "$size" "$size" "$base" --out "$out" >/dev/null
  if [[ "$size" != "1024" ]]; then
    double=$((size * 2))
    sips -z "$double" "$double" "$base" --out "${ICONSET}/icon_${size}x${size}@2x.png" >/dev/null
  fi
done

iconutil -c icns "$ICONSET" -o "$OUT"
echo "Icon: $OUT"
