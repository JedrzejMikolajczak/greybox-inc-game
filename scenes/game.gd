extends Node2D


var score: int = 0
var click_power: int = 1

var upgrade_count: int = 0
var upgrade_cost: int = 15

@onready var upgrades_panel = $UpgradesWindow/CanvasLayer
@onready var upgrade_button = $UpgradesWindow/CanvasLayer/UpgradesPanel/MainVBox/ScrollContainer/UpgradesList/UpgradeButton


func _ready() -> void:
	_update_upgrade_button()


func _on_button_button_down() -> void:
	score += click_power
	_update_score_label()


func _on_upgrades_button_pressed() -> void:
	upgrades_panel.visible = true


func _on_close_button_pressed() -> void:
	upgrades_panel.visible = false


func _on_upgrade_button_pressed() -> void:
	if score < upgrade_cost:
		return

	score -= upgrade_cost
	click_power += 1
	upgrade_count += 1
	upgrade_cost = int(upgrade_cost * 1.5)

	_update_score_label()


func _update_score_label() -> void:
	$Label.set_text(str(score))
	$Label/ProgressBar.value = score
	_update_upgrade_button()


func _update_upgrade_button() -> void:
	upgrade_button.text = "Mocniejszy klik (x%d) — Koszt: %d" % [upgrade_count, upgrade_cost]
	upgrade_button.disabled = score < upgrade_cost
