#CustomerRegistry (Autoload)
extends Node


const WARNING_FOLDER_OPEN_FAILED = "CustomerRegistry: Failed to open path: "
const WARNING_POOL_EMPTY = "CustomerRegistry: Customer pool is empty!"
const WARNING_EVENTS_EMPTY = "CustomerRegistry: Special events pool is empty!"

const NAMES_OPISKELIJA = ["Otto", "Onni", "Olli", "Eetu", "Juho", "Kalle"]
const NAMES_OPISKELIJA_NAARAS = ["Oona", "Anni", "Emma", "Iida", "Aino", "Sanni"]
const NAMES_RAKSAMIES = ["Rane", "Reijo", "Arto", "Make", "Jorma", "Seppo", "Pentti", "Tane", "Jari", "Kake"]
const NAMES_HIPSTERI = ["Hilkka", "Heka", "Hugo", "Saga", "Milo", "Luna", "Felix", "Alva", "Eno", "Noa"]
const NAMES_AGENTTI = ["Asko", "Aaro", "Ilona", "Kari", "Risto", "Sami", "Veera", "Tapio", "Tuula", "Oskari"]
const NAMES_BARBAARI = ["Urho", "Rolf", "Kustaa", "Turkka", "Valto", "Thor", "Birger"]
const NAMES_BARBAARI_NAARAS = ["Helga", "Aila", "Inkeri", "Brynhild", "Sigrid"]
const NAMES_MAFIOSO = ["Don", "Vito", "Carlo", "Rane", "Toni", "Sulo", "Gunnar", "Pepe", "Vesa", "Arska"]

const TITLES = {
	"opiskelija_naaras": {"title": "Opiskelija", "names": NAMES_OPISKELIJA_NAARAS},
	"opiskelija": {"title": "Opiskelija", "names": NAMES_OPISKELIJA},
	"raksamies": {"title": "Raksamies", "names": NAMES_RAKSAMIES},
	"hipsteri": {"title": "Hipsteri", "names": NAMES_HIPSTERI},
	"agentti": {"title": "Agentti", "names": NAMES_AGENTTI},
	"barbaari_naaras": {"title": "Barbaari", "names": NAMES_BARBAARI_NAARAS},
	"barbaari": {"title": "Barbaari", "names": NAMES_BARBAARI},
	"mafioso": {"title": "Mafioso", "names": NAMES_MAFIOSO}
}

const DEFAULT_TITLE = "Asiakas"
const DEFAULT_NAMES = ["Matti", "Maija", "Pekka", "Liisa", "Antti"]

@export var customer_folder_path: String = "res://src/resources/customers/"
@export var special_event_folder_path: String = "res://src/resources/special_events/"

var customer_pool: Array[CustomerData] = []
var special_events_pool: Array[SpecialEventData] = []


func _ready() -> void:
	_load_resources()


func get_random_customer_data() -> CustomerData:
	if customer_pool.is_empty():
		return null

	var current_reputation : int = 0
	if BrewEngine.current_brewery != null:
		current_reputation = BrewEngine.current_brewery.reputation

	var eligible_customers : Array[CustomerData] = []
	for customer in customer_pool:
		if current_reputation >= customer.min_reputation_to_appear:
			eligible_customers.append(customer)

	if eligible_customers.is_empty():
		eligible_customers = customer_pool

	return eligible_customers.pick_random()


func get_random_special_event() -> SpecialEventData:
	if special_events_pool.is_empty(): 
		return null
	return special_events_pool.pick_random()


func generate_random_name(resource_filename: String) -> String:
	var lower_filename = resource_filename.to_lower()
	var matched_key = ""
	
	for key in TITLES.keys():
		if lower_filename.begins_with(key):
			matched_key = key
			break
			
	if matched_key != "":
		var data = TITLES[matched_key]
		var random_first_name = data["names"].pick_random()
		return data["title"] + " " + random_first_name
		
	var backup_name = DEFAULT_NAMES.pick_random()
	return DEFAULT_TITLE + " " + backup_name


func _load_resources() -> void:
	var dir_cust = DirAccess.open(customer_folder_path)
	if dir_cust:
		dir_cust.list_dir_begin()
		var file_name = dir_cust.get_next()
		while file_name != "":
			if not dir_cust.current_is_dir() and file_name.ends_with(".tres"):
				var res = load(customer_folder_path + file_name)
				if res is CustomerData:
					customer_pool.append(res)
			file_name = dir_cust.get_next()
		dir_cust.list_dir_end()
	else:
		push_warning(WARNING_FOLDER_OPEN_FAILED + customer_folder_path)
		
	var dir_ev = DirAccess.open(special_event_folder_path)
	if dir_ev:
		dir_ev.list_dir_begin()
		var file_name = dir_ev.get_next()
		while file_name != "":
			if not dir_ev.current_is_dir() and file_name.ends_with(".tres"):
				var res = load(special_event_folder_path + file_name)
				if res is SpecialEventData:
					special_events_pool.append(res)
			file_name = dir_ev.get_next()
		dir_ev.list_dir_end()
	else:
		push_warning(WARNING_FOLDER_OPEN_FAILED + special_event_folder_path)
		
	if customer_pool.is_empty():
		push_warning(WARNING_POOL_EMPTY)
	if special_events_pool.is_empty():
		push_warning(WARNING_EVENTS_EMPTY)
