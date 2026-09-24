extends Node2D

# Scena-szablon pojedynczego przycisku ulepszenia — instancjonujemy ją
# wielokrotnie w kodzie zamiast ręcznie klikać przyciski w edytorze.
const UpgradeButtonScene = preload("res://scenes/upgrade_button.tscn")

# Cały stan gry (zł, USD, click_power, poziomy ulepszeń...) jest w GameState
# (scripts/game_state.gd, autoload). Ten skrypt zajmuje się tylko UI.

# @onready = "poczekaj aż scena się załaduje, dopiero wtedy pobierz ten node".
# $Sciezka/Do/Node to skrót na get_node("Sciezka/Do/Node").
@onready var upgrades_panel = $UpgradesWindow/CanvasLayer
@onready var zl_upgrades_list = $UpgradesWindow/CanvasLayer/UpgradesPanel/MainVBox/ScrollContainer/UpgradesList
@onready var usd_upgrades_list = $QuickUpgradesUSD/UsdButtonsList
@onready var usd_label = $QuickUpgradesUSD/UsdLabel
@onready var settingsWindow = $Settings/SettingsUiWindow
@onready var progressBar = $Label/ProgressBar
@onready var minigameWindow = $Minigra/CanvasLayer/PanelContainer

var bar_tween: Tween

# _ready() odpala się raz, gdy ta scena (Game) wchodzi do drzewa gry.
func _ready() -> void:
	# Ukryty node dalej działa (skrypty, fizyka, timery) — visible = false tylko go
	# nie rysuje. Dlatego minigierkę dodatkowo "zamrażamy", dopóki nie zostanie odblokowana.
	minigameWindow.process_mode = Node.PROCESS_MODE_DISABLED
	_spawn_upgrades()
	# Cokolwiek zmieni GameState (klik, zakup, minigierka) — odśwież UI.
	GameState.changed.connect(_update_labels)
	_update_labels()


# Tworzy jeden przycisk na każdy wpis w GameState.UPGRADES i wrzuca go
# do panelu właściwego dla jego waluty.
func _spawn_upgrades() -> void:
	for upgrade in GameState.UPGRADES:
		var container = zl_upgrades_list if upgrade.currency == "zl" else usd_upgrades_list
		# instantiate() = zrób nową "kopię" sceny upgrade_button.tscn
		var button = UpgradeButtonScene.instantiate()
		container.add_child(button)
		button.setup(upgrade)


# Odświeża liczniki. Przyciski ulepszeń odświeżają się same.
func _update_labels() -> void:
	$Label.set_text(str(GameState.zl))
	usd_label.text = "USD: %d" % GameState.usd
	
	if bar_tween:
		bar_tween.kill()
	bar_tween = create_tween()
	bar_tween.tween_property(progressBar, "value", GameState.zl, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Minigierka (shooter) odblokowuje się raz, gdy pasek postępu (zł) się napełni
	# — i zostaje otwarta, bez automatycznego zamykania czy resetowania.
	# Sprawdzamy GameState.zl, a nie progressBar.value — pasek dojeżdża z opóźnieniem (tween).
	if not GameState.minigame_unlocked and GameState.zl >= progressBar.max_value:
		GameState.minigame_unlocked = true
		minigameWindow.visible = true
		minigameWindow.process_mode = Node.PROCESS_MODE_INHERIT  # "odmroź" minigierkę
		minigameWindow.pivot_offset = minigameWindow.size / 2  # animacja skaluje od środka okna
		$AnimationPlayer.play("minigame_unlock")


func _on_button_button_down() -> void:
	GameState.zl += GameState.click_power

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
