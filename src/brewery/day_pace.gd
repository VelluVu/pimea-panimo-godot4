class_name DayPace
extends RefCounted

## The day's length as a share of the old five-minute day. Timers a day holds a set number
## of (visits, events, aging, fermentation) scale with it, so only the waiting shrinks.

const SCALE : float = 0.6
const BASE_DAY_SECONDS : float = 300.0
const DAY_SECONDS : float = BASE_DAY_SECONDS * SCALE
