class_name SpeechTiming
extends RefCounted

## How long a customer's speech bubble stays: longer lines longer, within limits.

const BASE_SECONDS : float = 3.0
## Shorter: the preview line only delays the sale.
const PREVIEW_BASE_SECONDS : float = 1.5
const PER_CHARACTER_SECONDS : float = 0.04
const MAX_SECONDS : float = 9.0
const FADE_SECONDS : float = 1.0


static func seconds_for(text : String, base_seconds : float = BASE_SECONDS) -> float:
	return clampf(base_seconds + text.length() * PER_CHARACTER_SECONDS, base_seconds, MAX_SECONDS)
