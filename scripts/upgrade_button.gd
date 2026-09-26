extends Button

# Przycisk nie trzyma już własnego stanu (poziomu, ceny) — wszystko jest
# w GameState. Przycisk tylko pamięta, KTÓRE ulepszenie reprezentuje,
# i pyta GameState o resztę.
var upgrade: Dictionary

# true = kwadratowy węzeł w drzewku (tekst w kilku liniach),
# false = szeroki przycisk w liście (tekst w jednej linii).
var compact := false


# Wywoływane raz, zaraz po stworzeniu przycisku (game.gd / upgrade_tree.gd).
# "upgrade_data" to jeden wpis z GameState.UPGRADES.
func setup(upgrade_data: Dictionary) -> void:
	upgrade = upgrade_data
	pressed.connect(func(): GameState.try_buy(upgrade))
	# Przy każdej zmianie stanu gry przycisk sam się odświeża
	# (tekst + czy nas na niego stać).
	GameState.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	disabled = not GameState.can_afford(upgrade)

	if not GameState.is_unlocked(upgrade):
		text = "???"
		return

	var level = GameState.get_level(upgrade.id)
	var level_text = "%d/%d" % [level, upgrade.max_level] if upgrade.has("max_level") else "x%d" % level
	var cost_text = "MAX" if GameState.is_maxed(upgrade) else "%d %s" % [GameState.get_cost(upgrade), GameState.CURRENCY_NAMES[upgrade.currency]]

	if compact:
		text = "%s\n%s\n%s" % [upgrade.name, level_text, cost_text]
	else:
		text = "%s (%s) — %s" % [upgrade.name, level_text, cost_text]
