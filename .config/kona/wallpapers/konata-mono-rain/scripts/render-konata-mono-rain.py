#!/usr/bin/env python3
"""Render the deterministic Kona Mono Rain loop with the system FFmpeg/WebP tools."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "source/KONATA_MONO_RAIN_REFERENCE.png"
DEFINITION = ROOT / "layers/rain-definition.json"
RENDER = ROOT / "render"
EXPECTED_SOURCE = "aab2a5e05dfb89163beed608b46052b219dfe14a638a94edf89d77d1dd4fa73c"
ASCII_FONT = Path("/usr/share/fonts/noto/NotoSansMono-Regular.ttf")
CJK_FONT = Path.home() / ".local/share/fonts/kona-music/NotoSansCJKsc-Regular.otf"


def run(command: list[str], *, capture: bool = False) -> str:
    completed = subprocess.run(command, check=True, text=True,
                               stdout=subprocess.PIPE if capture else None,
                               stderr=subprocess.STDOUT if capture else None)
    return completed.stdout if capture else ""


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def ffmpeg_escape(path: Path) -> str:
    return str(path).replace("\\", "\\\\").replace(":", "\\:").replace("'", "\\'")


def filter_graph(spec: dict, columns_dir: Path, frame_offset: int = 0) -> str:
    width, height = spec["width"], spec["height"]
    filters = [
        f"[0:v]scale={width}:{height}:flags=lanczos,format=rgba,"
        f"drawbox=x=0:y=0:w={spec['rain_width']}:h={height}:"
        f"color=black@{spec['left_dimming']}:t=fill[v0]"
    ]
    previous = "v0"
    period = spec["duration_seconds"] * spec["fps"]
    for index, column in enumerate(spec["columns"]):
        font = CJK_FONT if any(ord(char) > 127 for line in column["text"] for char in line) else ASCII_FONT
        text_path = columns_dir / f"column-{index:02d}.txt"
        text_path.write_text("\n".join(column["text"]) + "\n")
        loop = column["loop_height"]
        step = loop * column["cycles"] / period
        wrapped_frame = f"mod(n+{frame_offset}\\,{period})"
        position = f"mod({column['phase']}+{step:.12f}*{wrapped_frame}\\,{loop})-{loop}"
        pulse = (f"{column['opacity']}*(0.94+0.06*sin(2*PI*{wrapped_frame}/{period}"
                 f"+{index * 0.47:.2f}))")
        base = (f"fontfile='{ffmpeg_escape(font)}':textfile='{ffmpeg_escape(text_path)}':"
                f"reload=0:fontsize={column['font_size']}:line_spacing={column['line_spacing']}:"
                f"fontcolor=0x{column['color']}:x={column['x']}:alpha='{pulse}'")
        for copy_index, y in enumerate((position, f"({position})+{loop}")):
            current = f"v{index}-text-{copy_index}"
            filters.append(f"[{previous}]drawtext={base}:y='{y}'[{current}]")
            previous = current
        head_y = (len(column["text"]) * (column["font_size"] + column["line_spacing"]))
        head_alpha = min(0.72, column["opacity"] + 0.22)
        escaped_head = column["head"].replace("'", "\\'").replace(":", "\\:")
        head_base = (f"fontfile='{ffmpeg_escape(font)}':text='{escaped_head}':"
                     f"fontsize={column['font_size'] + 1}:fontcolor=0xc4cfda:"
                     f"x={column['x']}:alpha={head_alpha}")
        for copy_index, y in enumerate((f"({position})+{head_y}", f"({position})+{head_y + loop}")):
            current = f"v{index}-head-{copy_index}"
            filters.append(f"[{previous}]drawtext={head_base}:y='{y}'[{current}]")
            previous = current
    filters.append(f"[{previous}]format=yuv420p[out]")
    return ";\n".join(filters)


def render_frame(spec: dict, columns_dir: Path, output: Path, frame_offset: int) -> None:
    graph = columns_dir / f"frame-{frame_offset}.ffscript"
    graph.write_text(filter_graph(spec, columns_dir, frame_offset) + "\n")
    run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-loop", "1",
         "-framerate", str(spec["fps"]), "-i", str(SOURCE), "-filter_complex", graph.read_text(),
         "-map", "[out]", "-frames:v", "1", str(output)])


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="validate checked-in render outputs")
    args = parser.parse_args()
    spec = json.loads(DEFINITION.read_text())
    required = ("ffprobe", "webpmux") if args.check else ("ffmpeg",)
    missing = [name for name in required if shutil.which(name) is None]
    if missing:
        raise SystemExit("missing renderer tools: " + ", ".join(missing))
    if digest(SOURCE) != EXPECTED_SOURCE:
        raise SystemExit("approved reference checksum mismatch")
    if spec["duration_seconds"] != 10 or spec["fps"] < 10 or len(spec["columns"]) < 12:
        raise SystemExit("rain definition does not meet the loop contract")
    if any(c["x"] >= spec["rain_width"] or c["cycles"] < 1 for c in spec["columns"]):
        raise SystemExit("rain column escapes the left field or moves upward")
    webp = RENDER / "konata-mono-rain.webp"
    video = RENDER / "konata-mono-rain.mp4"
    gif = RENDER / "konata-mono-rain.gif"
    static = RENDER / "konata-mono-rain-static.png"
    outputs = [webp, video, gif, static]
    if args.check:
        if any(not path.is_file() or path.stat().st_size == 0 for path in outputs):
            raise SystemExit("render output is missing")
        info = run(["webpmux", "-info", str(webp)], capture=True)
        expected_frames = spec["duration_seconds"] * spec["fps"]
        if f"Number of frames: {expected_frames}" not in info or "Loop Count : 0" not in info:
            raise SystemExit("animated WebP frame/loop contract mismatch")
        gif_info = json.loads(run(["ffprobe", "-v", "error", "-show_entries",
                                   "stream=nb_frames,avg_frame_rate", "-show_entries",
                                   "format=duration", "-of", "json", str(gif)], capture=True))
        gif_stream = gif_info["streams"][0]
        if (int(gif_stream["nb_frames"]) != expected_frames or
                gif_stream["avg_frame_rate"] != f"{spec['fps']}/1" or
                float(gif_info["format"]["duration"]) != spec["duration_seconds"]):
            raise SystemExit("animated GIF frame/rate/duration contract mismatch")
        print("render outputs and animation loop contracts: PASS")
        return

    RENDER.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="kona-mono-rain-") as temporary:
        work = Path(temporary)
        graph = work / "rain.ffscript"
        graph.write_text(filter_graph(spec, work) + "\n")
        frame_count = spec["duration_seconds"] * spec["fps"]
        common = ["ffmpeg", "-hide_banner", "-loglevel", "warning", "-y", "-loop", "1",
                  "-framerate", str(spec["fps"]), "-i", str(SOURCE),
                  "-filter_complex", graph.read_text(), "-map", "[out]", "-frames:v", str(frame_count)]
        run(common + ["-c:v", "libwebp_anim", "-lossless", "0", "-q:v", "76",
                      "-compression_level", "3", "-loop", "0", "-an", str(webp)])
        run(common + ["-c:v", "libx264", "-preset", "slow", "-crf", "18", "-pix_fmt", "yuv420p",
                      "-g", str(frame_count), "-keyint_min", str(frame_count), "-sc_threshold", "0",
                      "-movflags", "+faststart", "-an", str(video)])
        lossless = work / "rain-lossless.mkv"
        run(common + ["-c:v", "ffv1", "-level", "3", "-an", str(lossless)])
        gif_filter = ("[0:v]split[a][b];[a]palettegen=max_colors=256:stats_mode=diff[p];"
                      "[b][p]paletteuse=dither=sierra2_4a:diff_mode=rectangle")
        run(["ffmpeg", "-hide_banner", "-loglevel", "warning", "-y", "-i", str(lossless),
             "-filter_complex", gif_filter, "-loop", "0", str(gif)])
        first, middle, seam = work / "first.png", work / "middle.png", work / "seam.png"
        render_frame(spec, work, first, 0)
        render_frame(spec, work, middle, frame_count // 2)
        render_frame(spec, work, seam, frame_count)
        if first.read_bytes() != seam.read_bytes():
            raise SystemExit("procedural cycle endpoint does not match its first state")
        shutil.copy2(first, static)
        stable_hashes = []
        for name, frame in (("first", first), ("middle", middle), ("seam", seam)):
            crop = work / f"{name}-stable.png"
            run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(frame),
                 "-vf", f"crop={spec['width'] - spec['stable_from_x']}:{spec['height']}:{spec['stable_from_x']}:0",
                 "-frames:v", "1", str(crop)])
            stable_hashes.append(digest(crop))
        if len(set(stable_hashes)) != 1:
            raise SystemExit("character/flower stability invariant failed")
        runtime_hashes = []
        for name, frame_number in (("first", 0), ("middle", frame_count // 2),
                                   ("last", frame_count - 1)):
            crop = work / f"gif-{name}-stable.rgb"
            run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(gif),
                 "-vf", (f"select='eq(n,{frame_number})',"
                         f"crop={spec['width'] - spec['stable_from_x']}:{spec['height']}:"
                         f"{spec['stable_from_x']}:0,format=rgb24"),
                 "-frames:v", "1", "-f", "rawvideo", str(crop)])
            runtime_hashes.append(digest(crop))
        if len(set(runtime_hashes)) != 1:
            raise SystemExit("encoded GIF character/flower stability invariant failed")
        validation = {
            "schema": 1,
            "source_sha256": digest(SOURCE),
            "duration_seconds": spec["duration_seconds"],
            "fps": spec["fps"],
            "frame_count": frame_count,
            "seam_endpoint_exact": True,
            "stable_region": {"x": spec["stable_from_x"], "width": spec["width"] - spec["stable_from_x"],
                              "sha256": stable_hashes[0]},
            "runtime_stable_region": {"format": "gif-rgb24", "sha256": runtime_hashes[0]},
            "outputs": {path.name: {"sha256": digest(path), "bytes": path.stat().st_size} for path in outputs},
        }
        (RENDER / "validation.json").write_text(json.dumps(validation, indent=2, sort_keys=True) + "\n")
    print(json.dumps(validation, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
