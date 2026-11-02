#!/usr/bin/env python3
"""Create a reproducible inventory of the 0.16 web source before porting."""
from collections import Counter
from pathlib import Path
import sys

root = Path(sys.argv[1]).resolve()
out = Path(sys.argv[2]).resolve()
out.mkdir(parents=True, exist_ok=True)

files = sorted(p for p in root.rglob("*") if p.is_file())
counts = Counter(p.suffix.lower() or "[no extension]" for p in files)
total_bytes = sum(p.stat().st_size for p in files)

manifest = []
for p in files:
    rel = p.relative_to(root).as_posix()
    manifest.append(f"{p.stat().st_size:>10}  {rel}")
(out / "file-manifest.txt").write_text("\n".join(manifest) + "\n", encoding="utf-8")

key_names = {
    "package.json", "vite.config.js", "vite.config.ts", "index.html",
    "tsconfig.json", "README.md", "capacitor.config.ts",
    "src/main.jsx", "src/main.tsx", "src/App.jsx", "src/App.tsx",
}
key_files = []
for p in files:
    rel = p.relative_to(root).as_posix()
    if rel in key_names or p.name in {"package.json", "vite.config.js", "vite.config.ts", "capacitor.config.ts"}:
        key_files.append(rel)

asset_exts = {".glb", ".gltf", ".fbx", ".obj", ".png", ".jpg", ".jpeg", ".webp", ".ktx", ".basis", ".wav", ".mp3", ".ogg", ".ttf", ".otf"}
asset_files = [p for p in files if p.suffix.lower() in asset_exts]
model_files = [p for p in files if p.suffix.lower() in {".glb", ".gltf", ".fbx", ".obj"}]
image_files = [p for p in files if p.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp", ".ktx", ".basis"}]
audio_files = [p for p in files if p.suffix.lower() in {".wav", ".mp3", ".ogg"}]

report = [
    "# IRON-FRONT 0.16 — Source Audit",
    "",
    "This is an inventory only. It does not modify or convert the source project.",
    "",
    f"- Extracted root: {root}",
    f"- Total files: **{len(files)}**",
    f"- Total unpacked size: **{total_bytes:,} bytes**",
    f"- 3D model files: **{len(model_files)}**",
    f"- Image/texture files: **{len(image_files)}**",
    f"- Audio files: **{len(audio_files)}**",
    "",
    "## File types",
    "",
    "| Extension | Count |",
    "|---|---:|",
]
for ext, count in counts.most_common():
    report.append(f"| {ext} | {count} |")

report += ["", "## Important project files", ""]
report += [f"- {name}" for name in key_files] or ["- No common web entry files detected at expected paths."]
report += ["", "## 3D models", ""]
report += [f"- {p.relative_to(root).as_posix()} ({p.stat().st_size:,} bytes)" for p in model_files[:300]]
if len(model_files) > 300:
    report.append(f"- … and {len(model_files) - 300} more model files (see full manifest).")
report += ["", "## Asset candidates", ""]
report += [f"- {p.relative_to(root).as_posix()}" for p in asset_files[:300]]
if len(asset_files) > 300:
    report.append(f"- … and {len(asset_files) - 300} more asset files (see full manifest).")

(out / "REPORT.md").write_text("\n".join(report) + "\n", encoding="utf-8")
print("\n".join(report[:25]))
print(f"Full manifest written: {out / 'file-manifest.txt'}")
