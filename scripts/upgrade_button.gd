extends Button

# Przycisk nie trzyma już własnego stanu (poziomu, ceny) — wszystko jest
# w GameState. Przycisk tylko pamięta, KTÓRE ulepszenie reprezentuje,
# i pyta GameState o resztę.
var upgrade: Dictionary


# Wywoływane raz, zaraz po stworzeniu przycisku w game.gd (_spawn_upgrades).
# "upgrade_data" to jeden wpis z GameState.UPGRADES.
func setup(upgrade_data: Dictionary) -> void:
	upgrade = upgrade_data
	pressed.connect(func(): GameState.try_buy(upgrade))
	# Przy każdej zmianie stanu gry przycisk sam się odświeża
	# (tekst + czy nas na niego stać).
	GameState.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var cost = GameState.get_cost(upgrade)
	text = "%s (x%d) — Koszt: %d" % [upgrade.name, GameState.get_level(upgrade.id), cost]
	disabled = not GameState.can_afford(upgrade)
