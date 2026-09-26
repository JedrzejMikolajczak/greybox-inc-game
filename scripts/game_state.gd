extends Node

# GameState to AUTOLOAD (Project Settings -> Globals) — globalny obiekt,
# dostępny z KAŻDEGO skryptu po prostu jako "GameState", np.:
#   GameState.dopamine += 5
#   GameState.goon_points -= 10
#   print(GameState.click_power)
# Tu trzymamy CAŁY stan gry (waluty, statystyki, poziomy ulepszeń),
# żeby nie był rozrzucony po scenach.

# Emitowany przy każdej zmianie stanu. UI podpina się pod ten jeden sygnał
# i odświeża się samo — nie trzeba ręcznie wołać _update_labels() wszędzie.
signal changed


# --- Waluty ---
# dopamine    = dopamina (główna waluta, z klikania i co sekundę)
# goon_points = goon pointy (za orgazm, czyli zapełnienie paska u góry)
var dopamine: int = 0:
	set(value):
		dopamine = value
		changed.emit()

var goon_points: int = 0:
	set(value):
		goon_points = value
		changed.emit()

# Nazwy walut do wyświetlania w UI (np. na przyciskach ulepszeń).
const CURRENCY_NAMES = {"dopamine": "dopaminy", "goon_points": "GP"}


# --- Statystyki (to co podbijają ulepszenia) ---
var click_power: int = 20:  # dopamina za jedno kliknięcie
	set(value):
		click_power = value
		changed.emit()

var dopamine_per_sec: int = 0:  # dopamina dodawana automatycznie co sekundę
	set(value):
		dopamine_per_sec = value
		changed.emit()

var goon_points_per_kill: int = 10:  # ile goon pointów za zabicie wroga w minigierce (shooter)
	set(value):
		goon_points_per_kill = value
		changed.emit()


# --- Postęp ---
var minigame_unlocked: bool = false

# Orgazm: każda zdobyta dopamina napełnia pasek u góry (podniecenie).
# Gdy dobije do progu — dostajesz stałą liczbę goon pointów, a pasek się zeruje.
# Wydawanie dopaminy NIE cofa paska — liczy się tylko to, ile zdobyłeś.
const ORGASM_THRESHOLD = 500      # ile dopaminy trzeba zdobyć do orgazmu
const ORGASM_REWARD = 50          # ile goon pointów za orgazm

var arousal: int = 0:
	set(value):
		arousal = value
		changed.emit()


func _ready() -> void:
	# Dopamina/s — Timer co sekundę dodaje dopamine_per_sec.
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(func(): earn_dopamine(dopamine_per_sec))
	add_child(timer)
	timer.start()


# Jedyne miejsce, przez które dopamina WPADA do gry (klik, co sekundę) —
# dzięki temu każde źródło dopaminy napełnia też pasek orgazmu.
func earn_dopamine(amount: int) -> void:
	if amount <= 0:
		return
	dopamine += amount
	arousal += amount
	# while, a nie if — przy dużym /s jedna porcja może dobić kilka orgazmów naraz.
	while arousal >= ORGASM_THRESHOLD:
		arousal -= ORGASM_THRESHOLD
		goon_points += ORGASM_REWARD


# --- Ulepszenia ---
# Definicje (dane stałe). Żeby dodać nowe ulepszenie, wystarczy dopisać wpis tutaj.
# Pola:
#   id         - unikalna nazwa
#   name       - tekst na przycisku
#   currency   - "dopamine" albo "goon_points" — czym się płaci
#   cost       - startowa cena
#   multiplier - o ile drożeje po każdym zakupie (1.5 = +50%)
#   max_level  - (opcjonalne) ile razy max można kupić
#   requires   - (opcjonalne) id ulepszeń, które trzeba mieć kupione choć raz (WSZYSTKIE)
#   effects    - co daje jeden zakup: nazwa statystyki -> o ile ją podbić
#   pos        - (opcjonalne) miejsce w drzewku, w kratkach siatki; (0, 0) = środek.
#                Ulepszenie z "pos" trafia do drzewka, bez "pos" — do listy zwykłych ulepszeń obok gry.
const UPGRADES = [
	# Start — środek drzewka
	{"id": "click_power", "name": "Mocniejszy klik", "currency": "dopamine", "cost": 15, "multiplier": 1.5, "max_level": 10,
	 "requires": [], "effects": {"click_power": 1}, "pos": Vector2(0, 0)},

	# Góra-lewo
	{"id": "tl", "name": "Twardy palec", "currency": "dopamine", "cost": 60, "multiplier": 1.6, "max_level": 5,
	 "requires": ["click_power"], "effects": {"click_power": 2}, "pos": Vector2(-1, -1)},
	{"id": "tl_up", "name": "Kofeina", "currency": "dopamine", "cost": 250, "multiplier": 1.7, "max_level": 5,
	 "requires": ["tl"], "effects": {"click_power": 3}, "pos": Vector2(-1, -2)},
	{"id": "tl_left", "name": "Nadgodziny", "currency": "dopamine", "cost": 250, "multiplier": 1.7, "max_level": 5,
	 "requires": ["tl"], "effects": {"click_power": 3}, "pos": Vector2(-2, -1)},

	# Góra-prawo
	{"id": "tr", "name": "Szybkie ręce", "currency": "dopamine", "cost": 60, "multiplier": 1.6, "max_level": 5,
	 "requires": ["click_power"], "effects": {"click_power": 2}, "pos": Vector2(1, -1)},
	{"id": "tr_up", "name": "Ergonomiczna mysz", "currency": "dopamine", "cost": 250, "multiplier": 1.7, "max_level": 5,
	 "requires": ["tr"], "effects": {"click_power": 3}, "pos": Vector2(1, -2)},
	{"id": "tr_right", "name": "Automatyzacja", "currency": "dopamine", "cost": 250, "multiplier": 1.7, "max_level": 5,
	 "requires": ["tr"], "effects": {"click_power": 3}, "pos": Vector2(2, -1)},

	# Dół-lewo
	{"id": "bl", "name": "Celownik", "currency": "dopamine", "cost": 60, "multiplier": 1.6, "max_level": 5,
	 "requires": ["click_power"], "effects": {"goon_points_per_kill": 2}, "pos": Vector2(-1, 1)},
	{"id": "bl_down", "name": "Premia za trafienie", "currency": "dopamine", "cost": 250, "multiplier": 1.7, "max_level": 5,
	 "requires": ["bl"], "effects": {"goon_points_per_kill": 3}, "pos": Vector2(-1, 2)},
	{"id": "bl_left", "name": "Łowca nagród", "currency": "dopamine", "cost": 250, "multiplier": 1.7, "max_level": 5,
	 "requires": ["bl"], "effects": {"goon_points_per_kill": 3}, "pos": Vector2(-2, 1)},

	# Dół-prawo
	{"id": "br", "name": "Lepsza amunicja", "currency": "dopamine", "cost": 60, "multiplier": 1.6, "max_level": 5,
	 "requires": ["click_power"], "effects": {"goon_points_per_kill": 2}, "pos": Vector2(1, 1)},
	{"id": "br_down", "name": "Kontrakt z bankiem", "currency": "dopamine", "cost": 250, "multiplier": 1.7, "max_level": 5,
	 "requires": ["br"], "effects": {"goon_points_per_kill": 3}, "pos": Vector2(1, 2)},
	{"id": "br_right", "name": "Handel walutą", "currency": "dopamine", "cost": 250, "multiplier": 1.7, "max_level": 5,
	 "requires": ["br"], "effects": {"goon_points_per_kill": 3}, "pos": Vector2(2, 1)},

	# Czerwone węzły — wymagają OBU sąsiednich odnóg, płatne w goon pointach, jednorazowe
	{"id": "final_top", "name": "Klik mistrza", "currency": "goon_points", "cost": 150, "multiplier": 1.0, "max_level": 1,
	 "requires": ["tl_up", "tr_up"], "effects": {"click_power": 25}, "pos": Vector2(0, -3)},
	{"id": "final_bottom", "name": "Wojenny zysk", "currency": "goon_points", "cost": 150, "multiplier": 1.0, "max_level": 1,
	 "requires": ["bl_down", "br_down"], "effects": {"goon_points_per_kill": 25}, "pos": Vector2(0, 3)},
	{"id": "final_left", "name": "Równowaga", "currency": "goon_points", "cost": 150, "multiplier": 1.0, "max_level": 1,
	 "requires": ["tl_left", "bl_left"], "effects": {"click_power": 10, "goon_points_per_kill": 10}, "pos": Vector2(-3, 0)},
	{"id": "final_right", "name": "Imperium", "currency": "goon_points", "cost": 150, "multiplier": 1.0, "max_level": 1,
	 "requires": ["tr_right", "br_right"], "effects": {"click_power": 10, "goon_points_per_kill": 10}, "pos": Vector2(3, 0)},

	# Zwykłe ulepszenia (brak "pos" = poza drzewkiem, lista obok gry).
	# Każde podbija dopaminę/klik i dopaminę/s. Wartości tymczasowe — do strojenia.
	{"id": "basic_1", "name": "Scrollowanie", "currency": "dopamine", "cost": 15, "multiplier": 1.15,
	 "effects": {"click_power": 1, "dopamine_per_sec": 1}},
	{"id": "basic_2", "name": "Memy", "currency": "dopamine", "cost": 100, "multiplier": 1.15,
	 "effects": {"click_power": 2, "dopamine_per_sec": 5}},
	{"id": "basic_3", "name": "Kawa", "currency": "dopamine", "cost": 500, "multiplier": 1.15,
	 "effects": {"click_power": 5, "dopamine_per_sec": 20}},
	{"id": "basic_4", "name": "Energetyk", "currency": "dopamine", "cost": 2000, "multiplier": 1.15,
	 "effects": {"click_power": 10, "dopamine_per_sec": 60}},
	{"id": "basic_5", "name": "Gry", "currency": "dopamine", "cost": 8000, "multiplier": 1.15,
	 "effects": {"click_power": 25, "dopamine_per_sec": 150}},
	{"id": "basic_6", "name": "Zakupy online", "currency": "dopamine", "cost": 30000, "multiplier": 1.15,
	 "effects": {"click_power": 50, "dopamine_per_sec": 400}},
	{"id": "basic_7", "name": "Hazard", "currency": "dopamine", "cost": 100000, "multiplier": 1.15,
	 "effects": {"click_power": 100, "dopamine_per_sec": 1000}},
]

# Aktualne poziomy ulepszeń: id -> poziom. Brak wpisu = poziom 0.
var upgrade_levels: Dictionary = {}


func get_level(upgrade_id: String) -> int:
	return upgrade_levels.get(upgrade_id, 0)


# Cena liczona z poziomu: cost * multiplier^poziom
func get_cost(upgrade: Dictionary) -> int:
	return int(upgrade.cost * pow(upgrade.multiplier, get_level(upgrade.id)))


func get_balance(currency: String) -> int:
	return dopamine if currency == "dopamine" else goon_points


# Czy wszystkie wymagane ulepszenia są kupione choć raz.
func is_unlocked(upgrade: Dictionary) -> bool:
	for req in upgrade.get("requires", []):
		if get_level(req) == 0:
			return false
	return true


func is_maxed(upgrade: Dictionary) -> bool:
	return upgrade.has("max_level") and get_level(upgrade.id) >= upgrade.max_level


# Czy można TERAZ kupić: odblokowane, nie na maksie i stać nas.
func can_afford(upgrade: Dictionary) -> bool:
	return is_unlocked(upgrade) and not is_maxed(upgrade) \
		and get_balance(upgrade.currency) >= get_cost(upgrade)


# Próbuje kupić ulepszenie. Zwraca true, jeśli się udało.
func try_buy(upgrade: Dictionary) -> bool:
	if not can_afford(upgrade):
		return false

	var cost = get_cost(upgrade)
	if upgrade.currency == "dopamine":
		dopamine -= cost
	else:
		goon_points -= cost

	upgrade_levels[upgrade.id] = get_level(upgrade.id) + 1
	_apply_upgrade(upgrade)
	changed.emit()
	return true


# Efekt ulepszenia bierzemy z pola "effects", np. {"click_power": 2}.
# get()/set() to dostęp do zmiennej po nazwie w stringu — set() woła też
# setter, więc "changed" dalej się emituje.
func _apply_upgrade(upgrade: Dictionary) -> void:
	for stat in upgrade.effects:
		set(stat, get(stat) + upgrade.effects[stat])
