extends Button

# Sygnał, który ten przycisk wysyła "na zewnątrz", gdy ktoś go kliknie.
# Przekazujemy w nim "button" (czyli self), żeby Game wiedział, KTÓRY
# konkretnie przycisk został kupiony.
signal purchase_requested(button)

# Dane wypełniane przez setup() poniżej — każda instancja tego przycisku
# ma własne wartości (bo każdy przycisk to osobna kopia tej sceny).
var upgrade_id = ""
var upgrade_name = ""
var cost = 0
var multiplier = 1.5
var level = 0
var currency = "zl"


# Wywoływane raz, zaraz po stworzeniu przycisku w game.gd (_spawn_upgrades).
# "upgrade" to jeden wpis z tablicy zl_upgrades/usd_upgrades (Dictionary).
func setup(upgrade, upgrade_currency) -> void:
	upgrade_id = upgrade.id
	upgrade_name = upgrade.name
	cost = upgrade.cost
	multiplier = upgrade.multiplier
	currency = upgrade_currency
	# Podłączamy wbudowany sygnał Buttona "pressed" (kliknięto) do naszej
	# własnej funkcji niżej
	pressed.connect(_on_pressed)
	_refresh_text()


func _on_pressed() -> void:
	# self = ten konkretny przycisk. Dzięki temu Game w game.gd wie,
	# który przycisk kupiono i może odczytać jego cost/currency/upgrade_id.
	purchase_requested.emit(self)


# Wywoływane z game.gd za każdym razem, gdy zmienia się stan konta —
# blokuje przycisk, jeśli gracza nie stać na kolejny zakup.
func update_statePLN(balance) -> void:
	disabled = balance < cost
func update_stateUSD(balance) -> void:
	disabled = balance < cost

# Wywoływane z game.gd PO tym, jak koszt już został odjęty z konta gracza.
# Przycisk sam podbija swój poziom i przelicza nową (droższą) cenę.
func level_up() -> void:
	level += 1
	cost = int(cost * multiplier)
	_refresh_text()


func _refresh_text() -> void:
	text = "%s (x%d) — Koszt: %d" % [upgrade_name, level, cost]
