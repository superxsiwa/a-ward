#!/usr/bin/env python3
"""Renders the game's sound effects into assets/sounds/*.wav from superxsiwa's SFXEngine.ts:
the same notes (frequency, duration, start), oscillator types and volume, with his gain envelope
(exponential ramp from 0.0001 to the volume in 12 ms, then down to 0.0001 at the note's end).

    python3 tool/make_sounds.py

Run from mobile/. Standard library only.
"""
import math
import struct
import wave
from pathlib import Path

OUT = Path("assets/sounds")
RATE = 22050

# name: (notes [(Hz, seconds, start)], oscillator, volume), as in SFXEngine.ts.
SOUNDS = {
    "pick": ([(680, 0.07, 0)], "sine", 0.2),
    "drop": ([(430, 0.06, 0), (760, 0.09, 0.05)], "sine", 0.2),
    "ok": ([(523, 0.12, 0), (659, 0.12, 0.09), (784, 0.12, 0.18), (1046, 0.28, 0.27)], "triangle", 0.24),
    "bad": ([(210, 0.18, 0), (150, 0.24, 0.13)], "sawtooth", 0.13),
    "win": ([(523, 0.14, 0), (659, 0.14, 0.12), (784, 0.14, 0.24), (1046, 0.14, 0.36), (1318, 0.4, 0.48)],
            "triangle", 0.24),
}
for i in range(3):
    SOUNDS[f"star{i}"] = ([(784 + i * 220, 0.3, 0), (1175 + i * 220, 0.25, 0.08)], "triangle", 0.22)


def wave_at(kind, phase):
    p = phase % 1.0
    if kind == "sine":
        return math.sin(2 * math.pi * p)
    if kind == "triangle":
        return 4 * abs(p - 0.5) - 1
    return 2 * p - 1  # sawtooth


def envelope(t, d, vol):
    lo = 0.0001
    attack = 0.012
    if t < 0 or t > d:
        return 0.0
    if t < attack:
        return lo * (vol / lo) ** (t / attack)
    return vol * (lo / vol) ** ((t - attack) / (d - attack))


def render(notes, kind, vol):
    length = max(at + d for _, d, at in notes) + 0.03
    samples = [0.0] * int(length * RATE)
    for f, d, at in notes:
        start = int(at * RATE)
        for i in range(int((d + 0.03) * RATE)):
            t = i / RATE
            if start + i < len(samples):
                samples[start + i] += wave_at(kind, f * t) * envelope(t, d, vol)
    return samples


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, (notes, kind, vol) in SOUNDS.items():
        data = render(notes, kind, vol)
        with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(RATE)
            w.writeframes(b"".join(struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in data))
    print("wrote", ", ".join(sorted(p.name for p in OUT.glob("*.wav"))))


if __name__ == "__main__":
    main()
