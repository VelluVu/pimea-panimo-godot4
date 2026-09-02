class_name SpecialEventData
extends Resource


@export var event_caller_name: String = "Kaljabisnesmies"
@export var intro_dialogue: String = "Nyt pitäs saada reippaasti kaljaa kaikille, eli bulkkia vähintään 20 pulloa!"
@export var success_dialogue: String = "Nyt bileet pystyyn!"
@export var fail_dialogue: String = "Eikö täältä räkälästä saa ees bulkkii kaikille?"
@export var reject_dialogue : String = "Päätit olla tarttumatta tarjoukseen. Jatketaan pimeää bisnestä."
@export var required_style: BeerStyle.Style = BeerStyle.Style.BULKKILAGER
@export var required_bottles: int = 20
@export var reward_money: int = 70
@export var reward_reputation: int = 10
@export var reward_risk: int = 5
@export var clears_risk: bool = false