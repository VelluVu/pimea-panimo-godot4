"""Synthesizes the game's own 16-bit style sound effects into assets/audio/sfx/synth/.

Everything is generated from code (square, triangle, saw and noise voices with simple
envelopes), so the sounds are ours: no licence to track. Seeded, so a rerun writes the
same files. Edit a recipe below and rerun to change a sound:

    python dev/tools/sfx/make_sfx.py            # all sounds
    python dev/tools/sfx/make_sfx.py cat_meow   # only the named ones
"""

import sys
import wave
from pathlib import Path

import numpy as np

RATE = 22050
OUT_DIR = Path(__file__).resolve().parents[3] / "assets" / "audio" / "sfx" / "synth"
rng = np.random.default_rng(1234)


# --- voices -------------------------------------------------------------------------

def _t(seconds):
    return np.arange(int(seconds * RATE)) / RATE


def _phase(freq, seconds):
    """Phase in cycles for a constant or per-sample frequency (sweeps stay click-free)."""
    n = int(seconds * RATE)
    f = np.broadcast_to(np.asarray(freq, dtype=float), (n,)) if np.ndim(freq) == 0 else np.asarray(freq, dtype=float)[:n]
    return np.cumsum(f) / RATE


def square(freq, seconds, duty=0.5):
    return np.where((_phase(freq, seconds) % 1.0) < duty, 1.0, -1.0)


def triangle(freq, seconds):
    p = _phase(freq, seconds) % 1.0
    return 4.0 * np.abs(p - 0.5) - 1.0


def saw(freq, seconds):
    return 2.0 * (_phase(freq, seconds) % 1.0) - 1.0


def noise(seconds, hold=1):
    """White noise; hold > 1 repeats each value to get the grainy low 'NES noise' colour."""
    n = int(seconds * RATE)
    values = rng.uniform(-1.0, 1.0, n // hold + 1)
    return np.repeat(values, hold)[:n]


def sweep(start, end, seconds, curve=1.0):
    x = np.linspace(0.0, 1.0, int(seconds * RATE)) ** curve
    return start + (end - start) * x


def env(seconds, attack=0.005, release=0.05, sustain_level=1.0, decay=0.0):
    """Attack, optional decay to sustain_level, hold, then release, in seconds."""
    n = int(seconds * RATE)
    e = np.full(n, sustain_level)
    a = min(int(attack * RATE), n)
    d = min(int(decay * RATE), n - a)
    r = min(int(release * RATE), n)
    if a:
        e[:a] = np.linspace(0.0, 1.0, a)
    if d:
        e[a:a + d] = np.linspace(1.0, sustain_level, d)
    elif a < n:
        e[a:] = np.maximum(e[a:], 0)
    if r:
        e[n - r:] *= np.linspace(1.0, 0.0, r)
    return e


def perc(seconds, decay_rate=30.0):
    return np.exp(-decay_rate * _t(seconds))


def lowpass(x, cutoff):
    """One-pole lowpass: softens the square edges toward a SNES-like tone."""
    a = np.exp(-2.0 * np.pi * cutoff / RATE)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1.0 - a) * v + a * acc
        y[i] = acc
    return y


def highpass(x, cutoff):
    return x - lowpass(x, cutoff)


def crush(x, levels=64):
    return np.round(x * levels) / levels


def note(name):
    names = {"C": -9, "C#": -8, "D": -7, "D#": -6, "E": -5, "F": -4, "F#": -3, "G": -2, "G#": -1, "A": 0, "A#": 1, "B": 2}
    pitch, octave = name[:-1], int(name[-1])
    return 440.0 * 2.0 ** ((names[pitch] + 12 * (octave - 4)) / 12.0)


def seq(parts):
    return np.concatenate(parts)


def silence(seconds):
    return np.zeros(int(seconds * RATE))


def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = np.zeros(n)
    for t in tracks:
        out[:len(t)] += t
    return out


def at(seconds, x):
    """x delayed by `seconds`, for laying parts over each other with mix()."""
    return np.concatenate([silence(seconds), x])


def tone(freq, seconds, voice="square", duty=0.5, attack=0.005, release=0.04, cutoff=5000.0):
    if voice == "square":
        x = square(freq, seconds, duty)
    elif voice == "triangle":
        x = triangle(freq, seconds)
    else:
        x = saw(freq, seconds)
    return lowpass(x * env(seconds, attack, release), cutoff)


def melody(notes, step, voice="square", duty=0.5, gap=0.01, cutoff=5000.0):
    parts = []
    for n in notes:
        if n is None:
            parts.append(silence(step))
        else:
            parts.append(tone(note(n), step - gap, voice, duty, cutoff=cutoff))
            parts.append(silence(gap))
    return seq(parts)


# --- recipes --------------------------------------------------------------------------
# Each returns (samples, peak). Peak sets how loud the file is relative to the others:
# small world sounds quiet, announcements louder.

def footstep():
    s = 0.09
    thump = lowpass(noise(s, hold=6), 900) * perc(s, 45)
    knock = triangle(sweep(140, 70, s), s) * perc(s, 60) * 0.6
    return mix(thump, knock), 0.5


def babble(seed):
    local = np.random.default_rng(seed)
    parts = []
    for _ in range(local.integers(5, 8)):
        length = local.uniform(0.05, 0.09)
        base = local.uniform(330, 520)
        f = sweep(base, base * local.uniform(0.85, 1.2), length)
        syllable = square(f, length, duty=local.choice([0.25, 0.5])) * env(length, 0.004, 0.025)
        parts.append(lowpass(syllable, 2600))
        parts.append(silence(local.uniform(0.02, 0.05)))
    return seq(parts), 0.4


def pour():
    s = 1.8
    stream = lowpass(noise(s), 1800) * env(s, 0.08, 0.3) * 0.5
    # Glugs climb in pitch as the glass fills.
    glugs = []
    t = 0.12
    while t < s - 0.25:
        length = 0.07
        f0 = 180 + 260 * (t / s)
        glug = triangle(sweep(f0, f0 * 1.5, length), length) * perc(length, 25) * 0.7
        glugs.append(at(t, glug))
        t += rng.uniform(0.09, 0.16)
    fizz = highpass(noise(s), 4000) * env(s, 1.2, 0.3) * 0.12
    return mix(stream, fizz, *glugs), 0.45


def _seamless_loop(x, fade=0.05):
    """Crossfades the tail into the head so the loop has no seam."""
    n = int(fade * RATE)
    head, tail = x[:n], x[-n:]
    ramp = np.linspace(0.0, 1.0, n)
    out = x[:-n].copy()
    out[:n] = tail * (1.0 - ramp) + head * ramp
    return out


def drone_hover():
    s = 2.0 + 0.05
    t = _t(s)
    wobble = 1.0 + 0.03 * np.sin(2 * np.pi * 7.0 * t)
    rotor = square(118.0 * wobble, s, duty=0.3) * 0.5 + square(236.5 * wobble, s, duty=0.2) * 0.2
    air = lowpass(noise(s), 1200) * (0.6 + 0.4 * np.sin(2 * np.pi * 14.0 * t)) * 0.4
    return _seamless_loop(lowpass(rotor, 1400) + air), 0.3


def robot_whir():
    s = 2.0 + 0.05
    t = _t(s)
    motor = saw(70.0 * (1.0 + 0.02 * np.sin(2 * np.pi * 3.0 * t)), s) * 0.5
    servo = square(210.0 + 30.0 * np.sin(2 * np.pi * 0.5 * t), s, 0.25) * 0.12
    return _seamless_loop(lowpass(motor + servo, 900)), 0.3


def cat_meow(variant):
    s = 0.55 if variant == 1 else 0.7
    up, top, down = (520, 820, 430) if variant == 1 else (480, 760, 380)
    t = _t(s) / s
    f = np.interp(t, [0.0, 0.35, 1.0], [up, top, down])
    # The duty cycle moves like an opening and closing mouth: "mi-a-ow".
    duty_curve = np.interp(t, [0.0, 0.5, 1.0], [0.12, 0.5, 0.2])
    p = _phase(f, s) % 1.0
    voice = np.where(p < duty_curve, 1.0, -1.0)
    vibrato_env = env(s, 0.04, 0.18)
    return lowpass(voice * vibrato_env, 2400), 0.55


def mouse_squeak():
    parts = []
    for f in (2600, 3000, 2800):
        length = 0.05
        parts.append(square(sweep(f, f * 1.15, length), length, 0.5) * env(length, 0.003, 0.02))
        parts.append(silence(0.035))
    return lowpass(seq(parts), 6000), 0.3


def bat_squeak():
    parts = []
    for f in (4200, 4600):
        length = 0.03
        parts.append(triangle(sweep(f, f * 0.8, length), length) * env(length, 0.002, 0.015))
        parts.append(silence(0.05))
    return seq(parts), 0.25


def toast():
    return melody(["E6", "A6"], 0.07, "square", duty=0.25, cutoff=3500) * 0.8, 0.35


def crit_gain():
    """A critical tip or quality gain: a fast rising coin arpeggio and a sparkling top."""
    run = melody(["E5", "G#5", "B5", "E6", "G#6"], 0.045, "square", duty=0.25, gap=0.005, cutoff=4500)
    ring = tone(note("B6"), 0.35, "square", 0.125, release=0.3, cutoff=5000)
    sparkle = highpass(noise(0.3, hold=1), 6000) * env(0.3, 0.005, 0.25) * 0.25
    bass = seq([tone(note("E3"), 0.12, "triangle"), tone(note("B3"), 0.2, "triangle", release=0.15)])
    return mix(seq([run, ring]), at(0.22, sparkle), bass * 0.6), 0.5


def group_banner():
    fanfare = melody(["C5", "E5", "G5", "C6"], 0.09, "square", duty=0.5, cutoff=3500)
    hold = tone(note("C6"), 0.35, "square", 0.25, release=0.25, cutoff=3500)
    cheer = lowpass(noise(0.7, hold=2), 2500) * env(0.7, 0.15, 0.4) * 0.35
    bass = melody(["C3", "G3", "C3", "G3"], 0.09, "triangle")
    return mix(seq([fanfare, hold]), at(0.2, cheer), bass), 0.6


def day_event_generic():
    chime = melody(["G5", "C6", "E6"], 0.12, "triangle")
    tail = tone(note("E6"), 0.4, "triangle", release=0.35)
    return seq([chime, tail]), 0.5


def ship_horn():
    s = 1.1
    horn = (saw(note("A2"), s) + saw(note("A2") * 1.005, s) + saw(note("E3"), s) * 0.5)
    horn = lowpass(horn * env(s, 0.12, 0.35), 700)
    second = lowpass((saw(note("F2"), 0.7) + saw(note("C3"), 0.7) * 0.5) * env(0.7, 0.1, 0.3), 700)
    gulls = melody(["E6", "B5", None, "E6", "B5"], 0.07, "square", duty=0.25, cutoff=4000) * 0.25
    return mix(horn, at(1.2, second), at(0.4, gulls)), 0.65


def stadium_horn():
    drum = []
    for i, t in enumerate([0.0, 0.25, 0.5, 0.62, 0.75]):
        hit = lowpass(noise(0.12, hold=8), 500) * perc(0.12, 30) + triangle(sweep(110, 50, 0.12), 0.12) * perc(0.12, 25)
        drum.append(at(t, hit))
    s = 1.0
    vuvuzela = lowpass(square(note("A#3") * (1.0 + 0.008 * np.sin(2 * np.pi * 5 * _t(s))), s, 0.4) * env(s, 0.05, 0.2), 1500) * 0.6
    return mix(*drum, at(0.9, vuvuzela)), 0.65


def heatwave():
    s = 1.2
    shimmer = triangle(sweep(1400, 700, s) * (1.0 + 0.04 * np.sin(2 * np.pi * 9 * _t(s))), s) * env(s, 0.05, 0.5) * 0.5
    sizzle = highpass(noise(s), 3000) * env(s, 0.3, 0.6) * 0.3
    return mix(shimmer, sizzle), 0.5


def sauna():
    splash = lowpass(noise(0.15, hold=3), 3000) * perc(0.15, 20)
    s = 1.3
    steam = highpass(lowpass(noise(s), 6000), 1500) * env(s, 0.15, 0.9, sustain_level=0.7, decay=0.2) * 0.8
    sigh = triangle(sweep(note("E4"), note("C4"), 0.6), 0.6) * env(0.6, 0.1, 0.3) * 0.4
    return mix(splash, at(0.12, steam), at(0.5, sigh)), 0.55


def pests():
    parts = []
    t = 0.0
    while t < 0.9:
        length = 0.025
        parts.append(at(t, highpass(noise(length, hold=2), 2000) * perc(length, 80)))
        t += rng.uniform(0.03, 0.07)
    squeak = mouse_squeak()[0]
    return mix(*parts, at(0.55, squeak)), 0.45


def inspection():
    s = 0.35
    parts = []
    for _ in range(3):
        parts.append(square(sweep(note("A5"), note("D5"), s), s, 0.5) * env(s, 0.01, 0.05))
    return lowpass(seq(parts), 3500), 0.5


def protection_money():
    return mix(
        melody(["E3", "F3", "E3", None, "E3", "F3", "A#3"], 0.16, "saw", cutoff=900),
        melody(["E2", None, "E2", None, "E2", None, "A#2"], 0.16, "triangle"),
    ), 0.6


def fridge_breaks():
    s = 0.9
    hum = square(sweep(120, 40, s, 2.0), s, 0.4) * env(s, 0.01, 0.2) * 0.5
    clunk = lowpass(noise(0.15, hold=10), 400) * perc(0.15, 18)
    spark = highpass(noise(0.08), 3500) * perc(0.08, 40) * 0.5
    return mix(lowpass(hum, 1200), at(0.7, clunk), at(0.3, spark), at(0.45, spark)), 0.55


def festival():
    lead = melody(["C5", "E5", "G5", "E5", "A5", "G5", "C6"], 0.09, "square", duty=0.25, cutoff=4000)
    bass = melody(["C3", "C3", "G2", "G2", "A2", "A2", "C3"], 0.09, "triangle")
    return mix(lead, bass), 0.55


def bass_drop():
    s = 0.9
    t = _t(s)
    wub = 0.5 + 0.5 * np.sin(2 * np.pi * sweep(2, 8, s) * t)
    bass = lowpass(saw(sweep(note("F2"), note("F1"), s, 0.5), s) * wub * env(s, 0.01, 0.15), 600)
    riser = triangle(sweep(300, 1600, 0.4), 0.4) * env(0.4, 0.3, 0.02) * 0.3
    return mix(riser, at(0.4, bass)), 0.65


def coins():
    parts = []
    for t in (0.0, 0.1, 0.2):
        ding = seq([tone(note("B5"), 0.05, "square", 0.25), tone(note("E6"), 0.15, "square", 0.25, release=0.12)])
        parts.append(at(t, ding * 0.7))
    return mix(*parts), 0.5


def coffee():
    s = 1.0
    parts = []
    t = 0.0
    while t < s:
        length = 0.06
        f = rng.uniform(300, 600)
        parts.append(at(t, triangle(sweep(f, f * 1.8, length), length) * perc(length, 30)))
        t += rng.uniform(0.05, 0.11)
    ding = tone(note("A5"), 0.3, "triangle", release=0.25)
    return mix(*parts, at(s, ding)), 0.5


def wife_carrying():
    boings = []
    for i, t in enumerate((0.0, 0.25, 0.5)):
        boings.append(at(t, square(sweep(200 + 60 * i, 500 + 80 * i, 0.15, 0.5), 0.15, 0.5) * env(0.15, 0.005, 0.06)))
    splash = lowpass(noise(0.4, hold=2), 2500) * env(0.4, 0.01, 0.3) * 0.6
    return lowpass(mix(*boings, at(0.8, splash)), 3500), 0.55


def topping_out():
    knocks = []
    for t in (0.0, 0.18, 0.36):
        thud = lowpass(noise(0.07, hold=4), 1500) * perc(0.07, 50)
        ring = square(note("D5"), 0.05, 0.5) * perc(0.05, 60) * 0.4
        knocks.append(at(t, mix(thud, ring)))
    cheer = melody(["G4", "C5", "E5", "G5"], 0.08, "square", duty=0.5, cutoff=3500) * 0.7
    return mix(*knocks, at(0.55, cheer)), 0.55


# --- brew day ---------------------------------------------------------------------

def brew_burner():
    """The gas burner under the kettle: a fluttering low roar with a thin hiss on top."""
    s = 2.0 + 0.05
    t = _t(s)
    roar = lowpass(noise(s, hold=2), 700) * (0.85 + 0.15 * np.sin(2 * np.pi * 11.0 * t))
    hiss = highpass(noise(s), 3000) * 0.12
    return _seamless_loop(roar + hiss), 0.35


def brew_boil():
    """A rolling boil: a low churn and a steady run of popping bubbles."""
    s = 2.0 + 0.05
    churn = lowpass(noise(s, hold=3), 500) * 0.35
    bubbles = []
    t = 0.0
    while t < s - 0.1:
        length = rng.uniform(0.03, 0.06)
        f0 = rng.uniform(180, 520)
        bubble = triangle(sweep(f0, f0 * 1.8, length), length) * perc(length, 40) * rng.uniform(0.3, 0.7)
        bubbles.append(at(t, bubble))
        t += rng.uniform(0.03, 0.09)
    return _seamless_loop(mix(churn, *bubbles)[:int(s * RATE)]), 0.35


def _grain_ticks(seconds, count):
    return [at(rng.uniform(0.0, seconds - 0.01), noise(0.004) * rng.uniform(0.4, 0.9)) for _ in range(count)]


def brew_malt_pour():
    """Crushed malt sliding out of the sack into the water."""
    s = 1.0
    grain = highpass(noise(s, hold=2), 1500) * env(s, 0.05, 0.3) * 0.6
    rustle = lowpass(noise(s, hold=4), 1200) * env(s, 0.1, 0.4) * 0.4
    return mix(grain, rustle, *_grain_ticks(s, 40))[:int(s * RATE)], 0.45


def brew_hop_pour():
    """Hop pellets trickling from the sack, looped while the sack is held."""
    s = 1.0 + 0.05
    rustle = highpass(noise(s, hold=3), 1200) * 0.4
    return _seamless_loop(mix(rustle, *_grain_ticks(s, 30))[:int(s * RATE)]), 0.3


def brew_plop():
    s = 0.18
    drop = triangle(sweep(900, 250, s, 0.6), s) * perc(s, 22) * 0.8
    splash = highpass(noise(s), 2500) * perc(s, 35) * 0.3
    return mix(drop, splash), 0.45


def brew_clump_hit():
    """The paddle smacking a dough ball."""
    s = 0.14
    thud = lowpass(noise(s, hold=5), 600) * perc(s, 30)
    squelch = lowpass(square(sweep(220, 110, s), s, 0.3), 1500) * perc(s, 40) * 0.3
    return mix(thud, squelch), 0.5


def brew_clump_break():
    s = 0.35
    squish = lowpass(noise(s, hold=3), 1400) * perc(s, 14) * 0.7
    sparkle = melody(["E6", "G#6", "B6"], 0.06, "square", 0.25) * 0.35
    return mix(squish, at(0.05, sparkle)), 0.5


def brew_paddle_knock():
    """Wood on the steel kettle wall: a knock and a short metallic ring."""
    s = 0.25
    knock = triangle(sweep(700, 500, s), s) * perc(s, 35)
    ring = lowpass(square(1480, s, 0.5), 3000) * perc(s, 18) * 0.15
    return mix(knock, ring), 0.45


def brew_boil_over():
    s = 1.1
    hiss = highpass(noise(s), 2000) * env(s, 0.02, 0.6) * 0.6
    crackle = noise(s) * (rng.uniform(0.0, 1.0, int(s * RATE)) > 0.97) * env(s, 0.01, 0.5) * 0.8
    return mix(hiss, crackle), 0.5


def brew_step_done():
    return melody(["E5", "B5"], 0.09, "triangle"), 0.45


def brew_result_good():
    return melody(["C5", "E5", "G5", "C6"], 0.08, "square", 0.25, cutoff=4000.0), 0.5


def brew_result_low():
    return melody(["E4", "C4"], 0.16, "triangle"), 0.45


def keg_scrub():
    """The spring brush loosening grime: a short bristly scratch."""
    s = 0.22
    scratch = highpass(noise(s, hold=2), 1800) * env(s, 0.01, 0.08) * 0.7
    rasp = lowpass(square(sweep(140, 110, s), s, 0.2), 900) * perc(s, 14) * 0.25
    return mix(scratch, rasp), 0.45


def keg_splash():
    """Rinsed grime washing off the keg wall."""
    s = 0.35
    wash = lowpass(noise(s), 2600) * env(s, 0.005, 0.25) * 0.7
    drops = mix(*[at(rng.uniform(0.05, 0.25), triangle(sweep(f, f * 1.6, 0.04), 0.04) * perc(0.04, 50) * 0.4)
                  for f in rng.uniform(600, 1400, 4)])
    return mix(wash, drops)[:int(s * RATE)], 0.4


def keg_skitter():
    """A critter fleeing out of the keg: quick tiny footsteps and a squeak."""
    steps = mix(*[at(i * 0.035, highpass(noise(0.015), 3000) * perc(0.015, 120) * 0.6) for i in range(6)])
    squeak = triangle(sweep(1800, 2600, 0.08), 0.08) * env(0.08, 0.005, 0.04) * 0.4
    return mix(steps, at(0.2, squeak)), 0.35


def keg_clank():
    """A tool knocking the hollow steel keg."""
    s = 0.5
    ring = mix(triangle(310, s) * 0.5, triangle(527, s) * 0.3, triangle(911, s) * 0.15) * perc(s, 9)
    hit = noise(0.01) * 0.5
    return mix(ring, hit), 0.4


def keg_shine():
    """A keg washed spotless: a bright glint and sparkle."""
    glint = melody(["E6", "B6", "E7"], 0.06, "triangle")
    sparkle = mix(*[at(0.12 + i * 0.05, square(note(n), 0.05, 0.25) * perc(0.05, 40) * 0.25)
                    for i, n in enumerate(["B6", "G#6", "E7", "B6"])])
    return mix(glint, sparkle), 0.45


def ferment_bubble():
    """An airlock: two lazy blubs as a brew starts fermenting."""
    def blub(f0):
        return triangle(sweep(f0, f0 * 2.2, 0.09), 0.09) * env(0.09, 0.005, 0.05)
    return mix(blub(170), at(0.22, blub(210) * 0.8)), 0.45


def soured():
    """A batch gone sour: a sagging, slightly wobbly 'wah-wah'."""
    wobble = 1.0 + 0.02 * np.sin(2 * np.pi * 7 * _t(0.7))
    wah = lowpass(square(sweep(330, 200, 0.7) * wobble, 0.7, 0.3), 1400) * env(0.7, 0.02, 0.2)
    return wah, 0.4


RECIPES = {
    "keg_scrub": keg_scrub,
    "keg_splash": keg_splash,
    "keg_skitter": keg_skitter,
    "keg_clank": keg_clank,
    "keg_shine": keg_shine,
    "ferment_bubble": ferment_bubble,
    "soured": soured,
    "footstep": footstep,
    "babble_1": lambda: babble(1),
    "babble_2": lambda: babble(2),
    "babble_3": lambda: babble(3),
    "babble_4": lambda: babble(4),
    "pour": pour,
    "drone_hover_loop": drone_hover,
    "robot_whir_loop": robot_whir,
    "cat_meow_1": lambda: cat_meow(1),
    "cat_meow_2": lambda: cat_meow(2),
    "mouse_squeak": mouse_squeak,
    "bat_squeak": bat_squeak,
    "toast": toast,
    "crit_gain": crit_gain,
    "group_banner": group_banner,
    "day_event": day_event_generic,
    "day_ship_horn": ship_horn,
    "day_stadium": stadium_horn,
    "day_heatwave": heatwave,
    "day_sauna": sauna,
    "day_pests": pests,
    "day_inspection": inspection,
    "day_protection_money": protection_money,
    "day_fridge_breaks": fridge_breaks,
    "day_festival": festival,
    "day_bass_drop": bass_drop,
    "day_coins": coins,
    "day_coffee": coffee,
    "day_wife_carrying": wife_carrying,
    "day_topping_out": topping_out,
    "brew_burner_loop": brew_burner,
    "brew_boil_loop": brew_boil,
    "brew_malt_pour": brew_malt_pour,
    "brew_hop_pour_loop": brew_hop_pour,
    "brew_plop": brew_plop,
    "brew_clump_hit": brew_clump_hit,
    "brew_clump_break": brew_clump_break,
    "brew_paddle_knock": brew_paddle_knock,
    "brew_boil_over": brew_boil_over,
    "brew_step_done": brew_step_done,
    "brew_result_good": brew_result_good,
    "brew_result_low": brew_result_low,
}


def write_wav(path, samples, peak):
    samples = samples - np.mean(samples)
    top = np.max(np.abs(samples))
    if top > 0:
        samples = samples / top * peak
    data = (np.clip(samples, -1.0, 1.0) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())


def main(names):
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name in names or RECIPES:
        samples, peak = RECIPES[name]()
        write_wav(OUT_DIR / f"{name}.wav", samples, peak)
        print(f"{name}.wav  {len(samples) / RATE:.2f} s")


if __name__ == "__main__":
    main(sys.argv[1:])
