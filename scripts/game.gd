extends Node2D

# Scena-szablon pojedynczego przycisku ulepszenia — instancjonujemy ją
# wielokrotnie w kodzie zamiast ręcznie klikać przyciski w edytorze.
const UpgradeButtonScene = preload("res://scenes/upgrade_button.tscn")

# Cały stan gry (dopamina, goon pointy, click_power, poziomy ulepszeń...) jest w GameState
# (scripts/game_state.gd, autoload). Ten skrypt zajmuje się tylko UI.

# @onready = "poczekaj aż scena się załaduje, dopiero wtedy pobierz ten node".
# $Sciezka/Do/Node to skrót na get_node("Sciezka/Do/Node").
@onready var upgrades_panel = $UpgradesWindow/CanvasLayer
@onready var upgrades_list = $QuickUpgrades/UpgradesList
@onready var stats_label = $QuickUpgrades/StatsLabel
@onready var settingsWindow = $Settings/SettingsUiWindow
@onready var progressBar = $Label/ProgressBar
@onready var minigameWindow = $Minigra/CanvasLayer/PanelContainer

var bar_tween: Tween

# _ready() odpala się raz, gdy ta scena (Game) wchodzi do drzewa gry.
func _ready() -> void:
	# Ukryty node dalej działa (skrypty, fizyka, timery) — visible = false tylko go
	# nie rysuje. Dlatego minigierkę dodatkowo "zamrażamy", dopóki nie zostanie odblokowana.
	minigameWindow.process_mode = Node.PROCESS_MODE_DISABLED
	# Pasek u góry = podniecenie; pełny pasek = orgazm (próg ustawiony w GameState).
	progressBar.max_value = GameState.ORGASM_THRESHOLD
	_spawn_upgrades()
	# Cokolwiek zmieni GameState (klik, zakup, minigierka) — odśwież UI.
	GameState.changed.connect(_update_labels)
	_update_labels()


# Tworzy przyciski zwykłych ulepszeń (tych bez "pos", czyli spoza drzewka)
# i wrzuca je do panelu obok gry. Drzewkiem zajmuje się upgrade_tree.gd.
func _spawn_upgrades() -> void:
	for upgrade in GameState.UPGRADES:
		if upgrade.has("pos"):
			continue
		# instantiate() = zrób nową "kopię" sceny upgrade_button.tscn
		var button = UpgradeButtonScene.instantiate()
		upgrades_list.add_child(button)
		button.setup(upgrade)


# Odświeża liczniki. Przyciski ulepszeń odświeżają się same.
func _update_labels() -> void:
	$Label.set_text(str(GameState.dopamine))
	stats_label.text = "Goon pointy: %d\nDopamina/klik: %d\nDopamina/s: %d" % [
		GameState.goon_points, GameState.click_power, GameState.dopamine_per_sec]

	# Pasek pokazuje podniecenie (GameState.arousal), a nie stan konta dopaminy.
	if bar_tween:
		bar_tween.kill()
	bar_tween = create_tween()
	bar_tween.tween_property(progressBar, "value", GameState.arousal, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# TYMCZASOWO WYŁĄCZONE — zamiast minigierki pełny pasek daje stałe goon pointy
	# (GameState.earn_dopamine). Stary kod zostaje do przywrócenia:
	# Minigierka (shooter) odblokowuje się raz, gdy pasek postępu się napełni
	# — i zostaje otwarta, bez automatycznego zamykania czy resetowania.
	# Sprawdzamy GameState.dopamine, a nie progressBar.value — pasek dojeżdża z opóźnieniem (tween).
	#if not GameState.minigame_unlocked and GameState.dopamine >= progressBar.max_value:
		#GameState.minigame_unlocked = true
		#minigameWindow.visible = true
		#minigameWindow.process_mode = Node.PROCESS_MODE_INHERIT  # "odmroź" minigierkę
		#minigameWindow.pivot_offset = minigameWindow.size / 2  # animacja skaluje od środka okna
		#$AnimationPlayer.play("minigame_unlock")


func _on_button_button_down() -> void:
	GameState.earn_dopamine(GameState.click_power)

func _on_upgrades_button_pressed() -> void:
	upgrades_panel.visible = true

func _on_close_button_pressed() -> void:
	upgrades_panel.visible = false

func _on_button_pressed() -> void:
	settingsWindow.visible = true


func _on_timer_timeout() -> void:
	progressBar.value = 0
	minigameWindow.visible = false
	minigameWindow.process_mode = Node.PROCESS_MODE_DISABLED
