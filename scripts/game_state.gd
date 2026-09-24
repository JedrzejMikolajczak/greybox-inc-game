extends Node

# GameState to AUTOLOAD (Project Settings -> Globals) — globalny obiekt,
# dostępny z KAŻDEGO skryptu po prostu jako "GameState", np.:
#   GameState.zl += 5
#   GameState.usd -= 10
#   print(GameState.click_power)
# Tu trzymamy CAŁY stan gry (waluty, statystyki, poziomy ulepszeń),
# żeby nie był rozrzucony po scenach.

# Emitowany przy każdej zmianie stanu. UI podpina się pod ten jeden sygnał
# i odświeża się samo — nie trzeba ręcznie wołać _update_labels() wszędzie.
signal changed


# --- Waluty ---
var zl: int = 0:
	set(value):
		zl = value
		changed.emit()

var usd: int = 0:
	set(value):
		usd = value
		changed.emit()


# --- Statystyki (to co podbijają ulepszenia) ---
var click_power: int = 20:  # ile zł dostajesz za jedno kliknięcie
	set(value):
		click_power = value
		changed.emit()

var usd_per_kill: int = 10:  # ile USD za zabicie wroga w minigierce (shooter)
	set(value):
		usd_per_kill = value
		changed.emit()


# --- Postęp ---
var minigame_unlocked: bool = false


# --- Ulepszenia ---
# Definicje (dane stałe). Żeby dodać nowe ulepszenie:
#   1. dopisz wpis tutaj
#   2. obsłuż jego "id" w _apply_upgrade() niżej
# Pola:
#   id         - unikalna nazwa
#   name       - tekst na przycisku
#   currency   - "zl" albo "usd" — czym się płaci (i w którym panelu się pokaże)
#   cost       - startowa cena
#   multiplier - o ile drożeje po każdym zakupie (1.5 = +50%)
const UPGRADES = [
	{"id": "click_power", "name": "Mocniejszy klik", "currency": "zl", "cost": 15, "multiplier": 1.5},
	{"id": "usd_click_power", "name": "Lepszy kurs wymiany", "currency": "usd", "cost": 10, "multiplier": 1.4},
]

# Aktualne poziomy ulepszeń: id -> poziom. Brak wpisu = poziom 0.
var upgrade_levels: Dictionary = {}


func get_level(upgrade_id: String) -> int:
	return upgrade_levels.get(upgrade_id, 0)


# Cena liczona z poziomu: cost * multiplier^poziom
func get_cost(upgrade: Dictionary) -> int:
	return int(upgrade.cost * pow(upgrade.multiplier, get_level(upgrade.id)))


func get_balance(currency: String) -> int:
	return zl if currency == "zl" else usd


func can_afford(upgrade: Dictionary) -> bool:
	return get_balance(upgrade.currency) >= get_cost(upgrade)


# Próbuje kupić ulepszenie. Zwraca true, jeśli się udało.
func try_buy(upgrade: Dictionary) -> bool:
	if not can_afford(upgrade):
		return false

	var cost = get_cost(upgrade)
	if upgrade.currency == "zl":
		zl -= cost
	else:
		usd -= cost

	upgrade_levels[upgrade.id] = get_level(upgrade.id) + 1
	_apply_upgrade(upgrade.id)
	changed.emit()
	return true


# Efekt każdego ulepszenia — match to jak "switch" w innych językach.
func _apply_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"click_power":
			click_power += 1
		"usd_click_power":
			usd_per_kill += 1
