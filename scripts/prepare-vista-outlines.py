#!/usr/bin/env python3
"""Build locally cached outline-distance PNGs for Veranda of Vistas.

Only works on masks already supplied by the user in
assets/wallpapers/.subjects/<artwork-id>.png (transparent subject on background).
Masks can be drawn by hand or produced offline by optional segmentation tools.
No wallpaper or map is sent to a server. No ML model is downloaded by this script.

Uses Pillow, NumPy and SciPy; this is an optional offline preparation command.
The resulting PNG is decoded by VistaTransition.qml as a texture:
  R = 0.5 on boundary, <0.5 inside and >0.5 outside (signed distance)
  G = angle around the subject's centroid (0..1), tracing order
  B = binary subject occupancy (0 or 1)
  A = opaque
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path


def build(mask_path: Path, output_path: Path, *, width: int = 640) -> None:
    try:
        import numpy as np
        from PIL import Image
        from scipy.ndimage import distance_transform_edt
    except ImportError as exc:
        raise SystemExit(
            "Requires Python Pillow, NumPy and SciPy (Fedora packages: "
            "python3-pillow python3-numpy python3-scipy)."
        ) from exc

    with Image.open(mask_path) as raw:
        rgba = raw.convert("RGBA")
        height = max(8, round(width * rgba.height / rgba.width))
        rgba = rgba.resize((width, height), Image.Resampling.LANCZOS)
        arr = np.asarray(rgba, dtype=np.uint8)

    alpha = arr[:, :, 3]
    if alpha.min() != alpha.max():
        inside = alpha > 128
    else:
        # A black-and-white mask works too; white denotes foreground.
        luminance = np.dot(arr[:, :, :3], [0.2126, 0.7152, 0.0722])
        inside = luminance > 128
    if not inside.any() or inside.all():
        raise ValueError(f"Mask is entirely empty or full: {mask_path}")

    # R: gentle distance gradient from silhouette, clipped so large vistas
    # do not run beyond the shader's transition duration.
    d_in = distance_transform_edt(inside)
    d_out = distance_transform_edt(~inside)
    signed = (d_out / max(width * 0.38, 1)) - (d_in / max(width * 0.1, 1))
    red = np.clip(0.5 + 0.45 * signed, 0.02, 0.98)

    # G: sweep from the uppermost radial direction, clockwise. This gives
    # readable outline-first motion without storing geometry or path data.
    yy, xx = np.indices(inside.shape)
    y_center = float(yy[inside].mean())
    x_center = float(xx[inside].mean())
    angle = (np.arctan2(xx-x_center, -(yy-y_center)) + np.pi) / (2*np.pi)

    out = np.empty((height, width, 4), dtype=np.uint8)
    out[:, :, 0] = np.rint(red * 255).astype(np.uint8)
    out[:, :, 1] = np.rint(angle * 255).astype(np.uint8)
    out[:, :, 2] = np.where(inside, 255, 0).astype(np.uint8)
    out[:, :, 3] = 255
    output_path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(out, mode="RGBA").save(output_path, optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--id", help="Single artwork ID; all available masks if omitted")
    parser.add_argument("--width", type=int, default=640)
    args = parser.parse_args()
    if args.width < 64 or args.width > 2048:
        parser.error("--width must be 64..2048")
    root = args.root.resolve()
    data = json.loads((root / "quickshell/data/veranda-wallpapers.json").read_text())
    ids = {row["id"] for row in data.get("wallpapers", [])}
    if args.id:
        if args.id not in ids:
            parser.error("Unknown artwork ID")
        ids = {args.id}
    mask_dir = root / "assets/wallpapers/.subjects"
    output_dir = root / "assets/wallpapers/.wallfx"
    count = 0
    for artwork_id in sorted(ids):
        mask = mask_dir / (artwork_id + ".png")
        if not mask.is_file():
            if args.id:
                parser.error(f"Mask not found: {mask}")
            continue
        out = output_dir / (artwork_id + ".png")
        build(mask, out, width=args.width)
        count += 1
        print(f"{artwork_id}: {out}")
    print(f"Prepared {count} outline map(s). Other artworks use pixel-colony transitions.")


if __name__ == "__main__":
    main()
