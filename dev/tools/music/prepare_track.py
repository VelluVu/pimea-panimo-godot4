"""Turns a tracker export into a playlist track: intro + the looping body N times + a short
faded ending, levelled to the other music, written as OGG Vorbis.

The game's playlist plays each track once and moves on, so a short song loop is repeated
here instead of looped in the engine. Export the song from Furnace once through (no extra
loops); the body must be exactly the looping part, so give its length from the rows:
seconds = rows * speed / tick_rate.

    python dev/tools/music/prepare_track.py dev/music/dark_reggae_pub.wav \
        assets/audio/music/dark_reggae_pub.ogg --intro 7.4667 --repeats 3
"""

import argparse

import numpy as np
import soundfile as sf

# The playlist's tracks sit around -16 to -19 dB RMS.
DEFAULT_TARGET_RMS_DB = -17.5
CEILING_DB = -1.0
LOOKAHEAD_SECONDS = 0.005
RELEASE_SECONDS = 0.08
WRITE_BLOCK_FRAMES = 16384


def rms_db(x):
    return 20.0 * np.log10(np.sqrt(np.mean(x ** 2)) + 1e-12)


def _running_min(values, window):
    """Minimum over the next `window` samples, so the limiter starts ducking before a peak."""
    padded = np.concatenate([values, np.ones(window)])
    out = values.copy()
    for shift in range(1, window):
        np.minimum(out, padded[shift:shift + len(values)], out=out)
    return out


def limit(x, sr, ceiling):
    """Look-ahead peak limiter: transients are turned down instead of clipped."""
    peak = np.abs(x).max(axis=1)
    wanted = np.minimum(1.0, ceiling / np.maximum(peak, 1e-12))
    wanted = _running_min(wanted, max(1, int(LOOKAHEAD_SECONDS * sr)))
    release = np.exp(-1.0 / (RELEASE_SECONDS * sr))
    gain = np.empty_like(wanted)
    g = 1.0
    for i, w in enumerate(wanted):
        g = w if w < g else w + (g - w) * release
        gain[i] = g
    return x * gain[:, None]


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("source")
    parser.add_argument("target")
    parser.add_argument("--intro", type=float, default=0.0, help="intro length in seconds (played once)")
    parser.add_argument("--repeats", type=int, default=3, help="how many times the body plays")
    parser.add_argument("--ending", type=float, default=2.5, help="seconds of the body's start used as the faded ending")
    parser.add_argument("--target-rms", type=float, default=DEFAULT_TARGET_RMS_DB)
    args = parser.parse_args()

    x, sr = sf.read(args.source, always_2d=True)
    split = int(round(args.intro * sr))
    intro, body = x[:split], x[split:]

    ending = body[:int(args.ending * sr)].copy()
    ending *= np.linspace(1.0, 0.0, len(ending))[:, None] ** 2
    track = np.concatenate([intro] + [body] * args.repeats + [ending])

    gain_db = args.target_rms - rms_db(body.mean(axis=1))
    track = limit(track * 10 ** (gain_db / 20.0), sr, 10 ** (CEILING_DB / 20.0))

    # In blocks: libsndfile's Vorbis encoder overflows the stack on one long write (Windows).
    with sf.SoundFile(args.target, "w", sr, track.shape[1], format="OGG", subtype="VORBIS") as out:
        for start in range(0, len(track), WRITE_BLOCK_FRAMES):
            out.write(track[start:start + WRITE_BLOCK_FRAMES])
    mono = track.mean(axis=1)
    print(f"{args.target}: {len(track) / sr:.1f} s, gain {gain_db:+.1f} dB, "
          f"rms {rms_db(mono):.1f} dB, peak {20 * np.log10(np.abs(track).max()):.1f} dB")


if __name__ == "__main__":
    main()
