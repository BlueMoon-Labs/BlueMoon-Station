"""Синтез звуков путей Песка и Воска.

python build_sand_wax.py --preview-dir PATH
Нужны numpy и ffmpeg. WAV-промежуточные файлы и отчёт остаются в preview-dir, OGG пишутся в
modular_bluemoon/sound/heretic/. Спрайты путей (одежда, предметы, значки, сигилы, эффекты, книги)
этим скриптом не собираются.
"""

import argparse
import json
import math
import subprocess
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
SOUNDS = ROOT / "modular_bluemoon/sound/heretic"
TAU = math.tau
PATHS = ("sand", "wax")


def synthesize(args, path, kind):
    sample_rate = 44100
    durations = dict(grasp=.7, cast=1.2, impact=.9, ascend=3.2)
    length = durations[kind]
    t = np.arange(int(sample_rate * length)) / sample_rate
    rng = np.random.default_rng(710 + PATHS.index(path) * 13 + list(durations).index(kind))
    noise = rng.normal(0, 1, len(t))
    low = np.convolve(noise, np.ones(25) / 25, mode="same")
    mid = noise - np.convolve(noise, np.ones(5) / 5, mode="same")
    envelope = np.minimum(1, t / .012) * np.maximum(0, 1 - t / length) ** 1.6
    if path == "sand":
        rush = (low * .6 + mid * .09) * (.55 + .45 * np.sin(t * 27) ** 2)
        pitch = dict(grasp=510, cast=280, impact=190, ascend=160)[kind]
        metal = sum(np.sin(TAU * pitch * ratio * t) * np.exp(-t * decay) * gain for ratio, decay, gain in [(1, 5, .14), (2.756, 8, .06), (5.404, 12, .025)])
        signal = (rush + metal) * envelope
        for at in ([.035, .2, .43] if kind != "ascend" else [.03, .45, .92, 1.5, 2.1]):
            dt = np.maximum(0, t - at)
            signal += (t >= at) * np.sin(TAU * (1900 - dt * 1200) * dt) * np.exp(-dt * 85) * .06
        if kind == "ascend":
            signal += np.sin(TAU * (110 * t + 18 * t ** 2)) * np.sin(np.pi * t / length) ** 2 * .10
    else:
        pitch = dict(grasp=164, cast=123, impact=82, ascend=61.7)[kind]
        hum = sum(np.sin(TAU * pitch * ratio * t + .008 * np.sin(t * 9)) * gain for ratio, gain in [(1, .20), (1.498, .08), (2, .06), (3.02, .025)])
        signal = (hum * np.exp(-t * 1.5) + low * .23) * envelope
        for at in ([.025, .21, .47] if kind != "ascend" else [.1, .4, .85, 1.3, 1.8, 2.35]):
            dt = np.maximum(0, t - at)
            signal += (t >= at) * np.sin(TAU * (900 * dt - 1200 * dt ** 2)) * np.exp(-dt * 37) * .12
        if kind == "ascend":
            signal += sum(np.sin(TAU * frequency * t) for frequency in (246.9, 293.66, 369.99)) * .04 * np.sin(np.pi * t / length) ** 2
    dry = signal.copy()
    for delay, gain in [(.061, .19), (.113, .11), (.181, .055)]:
        offset = int(delay * sample_rate)
        signal[offset:] += dry[:-offset] * gain
    signal *= np.minimum(1, (length - t) / .04)
    signal *= .78 / max(.001, np.max(np.abs(signal)))
    wav_path = args.preview_dir / f"{path}_{kind}.wav"
    with wave.open(str(wav_path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(sample_rate)
        output.writeframes((signal * 32767).astype("<i2").tobytes())
    SOUNDS.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(wav_path), "-c:a", "libvorbis", "-q:a", "5", "-map_metadata", "-1", str(SOUNDS / f"{path}_{kind}.ogg")], check=True)
    return dict(path=f"{path}_{kind}.ogg", duration=length, peak=float(np.max(np.abs(signal))), rms=float(np.sqrt(np.mean(signal ** 2))))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview-dir", type=Path, required=True)
    args = parser.parse_args()
    args.preview_dir.mkdir(parents=True, exist_ok=True)
    report = []
    for path in PATHS:
        for kind in ("grasp", "cast", "impact", "ascend"):
            report.append(synthesize(args, path, kind))
    (args.preview_dir / "audio-report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
