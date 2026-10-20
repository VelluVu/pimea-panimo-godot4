class_name DayPace
extends RefCounted

## How long a day runs, as a share of the original five-minute day. Every timer that a day
## holds a set number of (walk-ins, groups, events, aging, fermentation) is scaled by it, so
## a shorter day keeps the same visits and sales with less waiting between them.

const SCALE : float = 0.6
const BASE_DAY_SECONDS : float = 300.0
const DAY_SECONDS : float = BASE_DAY_SECONDS * SCALE
