class_name SpecialEventText
extends RefCounted

## Text for SpecialEventWindow: the time left on its bar, the delivery line of an
## accepted request and the reward popups that fly out once it is done.

const DELIVERY_FORMAT : String = "Toimita %d × %s.\nVarastossa: %d / %d"
const MONEY_FORMAT : String = "%+d €"
const MONEY_DECIMAL_FORMAT : String = "%+.1f €"
const REPUTATION_FORMAT : String = "%+d mainetta"
const RISK_FORMAT : String = "%+d LVV-riskiä"
const SECONDS_FORMAT : String = "%d s"


## Rounded up, so the bar reads "1 s" until the time is really out.
static func seconds(seconds_left : float) -> String:
	return UiText.of(SECONDS_FORMAT) % maxi(ceili(seconds_left), 0)


## `have` is capped at `need`, so a full cellar does not read as "40 / 15".
static func delivery(requirement : String, have : int, need : int) -> String:
	return UiText.of(DELIVERY_FORMAT) % [need, requirement, mini(have, need), need]


static func money(amount : float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return UiText.of(MONEY_FORMAT) % roundi(amount)
	return UiText.of(MONEY_DECIMAL_FORMAT) % amount


static func reputation(amount : int) -> String:
	return UiText.of(REPUTATION_FORMAT) % amount


static func risk(amount : int) -> String:
	return UiText.of(RISK_FORMAT) % amount
