"""Turns a tracker export into a playlist track: intro + the looping body N times + a short
faded ending, levelled to the other music, written as OGG Vorbis.

The game's playlist plays each track once and moves on, so a short song loop is repeated
here instead of looped in the engine. Export the song from Furnace once through (no extra
loops); the body must be exactly the looping part, so give its length from the rows:
seconds = rows * speed / tick_rate.

    python dev/tools/music/prepare_track.py dev/music/dark_reggae_pub.wav \
        assets/audio/music/custom/dark_reggae_pub.ogg --intro 7.4667 --repeats 3 \
        --low-shelf -3 --mid 2 --high-shelf -6 --compress 3

The tone options smooth a bright FM export towards the softer chiptunes in the playlist:
a low shelf below 150 Hz, a broad mid bump at 900 Hz, a high shelf from 2 kHz and a slow
compressor (ratio) that rounds off the sharpest hits. All are off by default.
"""

import argparse

import numpy as np
import soundfile as sf
from scipy.signal import lfilter

# The playlist's tracks sit around -16 to -19 dB RMS.
DEFAULT_TARGET_RMS_DB = -17.5
CEILING_DB = -1.0
LOOKAHEAD_SECONDS = 0.005
RELEASE_SECONDS = 0.08
WRITE_BLOCK_FRAMES = 16384
LOW_SHELF_HZ = 150.0
MID_HZ = 900.0
MID_Q = 0.7
HIGH_SHELF_HZ = 2000.0
COMPRESS_THRESHOLD_DB = -24.0
COMPRESS_ATTACK_SECONDS = 0.003
COMPRESS_RELEASE_SECONDS = 0.15


def rms_db(x):
    return 20.0 * np.log10(np.sqrt(np.mean(x ** 2)) + 1e-12)


def _biquad(kind, freq, gain_db, sr, q=0.707):
    """RBJ cookbook shelf and peaking filters, as (b, a)."""
    a_gain = 10 ** (gain_db / 40.0)
    w0 = 2.0 * np.pi * freq / sr
    cos_w0, alpha = np.cos(w0), np.sin(w0) / (2.0 * q)
    if kind == "peak":
        b = [1 + alpha * a_gain, -2 * cos_w0, 1 - alpha * a_gain]
        a = [1 + alpha / a_gain, -2 * cos_w0, 1 - alpha / a_gain]
    else:
        sq = 2.0 * np.sqrt(a_gain) * alpha
        sign = 1.0 if kind == "low" else -1.0
        b = [a_gain * ((a_gain + 1) - sign * (a_gain - 1) * cos_w0 + sq),
             sign * 2 * a_gain * ((a_gain - 1) - sign * (a_gain + 1) * cos_w0),
             a_gain * ((a_gain + 1) - sign * (a_gain - 1) * cos_w0 - sq)]
        a = [(a_gain + 1) + sign * (a_gain - 1) * cos_w0 + sq,
             -sign * 2 * ((a_gain - 1) + sign * (a_gain + 1) * cos_w0),
             (a_gain + 1) + sign * (a_gain - 1) * cos_w0 - sq]
    return np.array(b) / a[0], np.array(a) / a[0]


def shape_tone(x, sr, low_db, mid_db, high_db):
    filters = (("low", LOW_SHELF_HZ, low_db, 0.707), ("peak", MID_HZ, mid_db, MID_Q), ("high", HIGH_SHELF_HZ, high_db, 0.707))
    for kind, freq, gain_db, q in filters:
        if gain_db != 0.0:
            b, a = _biquad(kind, freq, gain_db, sr, q)
            x = lfilter(b, a, x, axis=0)
    return x


def compress(x, sr, ratio):
    """Downward compressor on a smoothed level: rounds off the hits that the limiter would
    only catch at the ceiling. The RMS levelling afterwards makes up the gain."""
    level = np.abs(x).max(axis=1)
    attack = np.exp(-1.0 / (COMPRESS_ATTACK_SECONDS * sr))
    release = np.exp(-1.0 / (COMPRESS_RELEASE_SECONDS * sr))
    env = np.empty_like(level)
    e = 0.0
    for i, v in enumerate(level):
        e = v + (e - v) * (attack if v > e else release)
        env[i] = e
    over_db = np.maximum(0.0, 20.0 * np.log10(np.maximum(env, 1e-12)) - COMPRESS_THRESHOLD_DB)
    return x * (10 ** (-over_db * (1.0 - 1.0 / ratio) / 20.0))[:, None]


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
    parser.add_argument("--low-shelf", type=float, default=0.0, help=f"dB below {LOW_SHELF_HZ:.0f} Hz")
    parser.add_argument("--mid", type=float, default=0.0, help=f"dB around {MID_HZ:.0f} Hz")
    parser.add_argument("--high-shelf", type=float, default=0.0, help=f"dB above {HIGH_SHELF_HZ:.0f} Hz")
    parser.add_argument("--compress", type=float, default=1.0, help="compressor ratio, 1 = off")
    args = parser.parse_args()

    x, sr = sf.read(args.source, always_2d=True)
    x = shape_tone(x, sr, args.low_shelf, args.mid, args.high_shelf)
    if args.compress > 1.0:
        # Levelled first, so the threshold means the same for any export volume.
        x *= 10 ** ((DEFAULT_TARGET_RMS_DB - rms_db(x.mean(axis=1))) / 20.0)
        x = compress(x, sr, args.compress)
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
