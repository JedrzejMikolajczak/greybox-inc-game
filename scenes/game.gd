extends Node2D

# Scena-szablon pojedynczego przycisku ulepszenia — instancjonujemy ją
# wielokrotnie w kodzie zamiast ręcznie klikać przyciski w edytorze.
const UpgradeButtonScene = preload("res://scenes/upgrade_button.tscn")

# --- Waluty gracza ---
var zl = 0
var click_power = 20  # ile zł dostajesz za jedno kliknięcie

var usd = 0
var usd_click_power = 1  # ile USD dostajesz za jedno kliknięcie przycisku USD

# --- Dane ulepszeń ---
# To jest ta "tablica", z której dynamicznie tworzymy przyciski.
# Każdy wpis to Dictionary (słownik) z 4 polami:
#   id         - unikalna nazwa używana w match() niżej, żeby wiedzieć co kupiono
#   name       - tekst wyświetlany na przycisku
#   cost       - startowa cena
#   multiplier - o ile drożeje po każdym zakupie (1.5 = +50%)
# Żeby dodać nowe ulepszenie: dopisz kolejny wpis tutaj i obsłuż jego "id"
# w match() w funkcji _on_upgrade_purchased().
var zl_upgrades = [
	{"id": "click_power", "name": "Mocniejszy klik", "cost": 15, "multiplier": 1.5},
]

var usd_upgrades = [
	{"id": "usd_click_power", "name": "Lepszy kurs wymiany", "cost": 10, "multiplier": 1.4},
]

# @onready = "poczekaj aż scena się załaduje, dopiero wtedy pobierz ten node".
# $Sciezka/Do/Node to skrót na get_node("Sciezka/Do/Node").
@onready var upgrades_panel = $UpgradesWindow/CanvasLayer
@onready var zl_upgrades_list = $UpgradesWindow/CanvasLayer/UpgradesPanel/MainVBox/ScrollContainer/UpgradesList
@onready var usd_upgrades_list = $QuickUpgradesUSD/UsdButtonsList
@onready var usd_label = $QuickUpgradesUSD/UsdLabel
@onready var settingsWindow = $Settings/SettingsUiWindow
@onready var progressBar = $Label/ProgressBar
@onready var usd_button = $UsdButton


# _ready() odpala się raz, gdy ta scena (Game) wchodzi do drzewa gry.
func _ready() -> void:
	# Tu dzieje się to "dynamiczne wczytywanie" — zamiast mieć przyciski
	# ręcznie poukładane w scenie, tworzymy je z tablic zl_upgrades/usd_upgrades.
	_spawn_upgrades(zl_upgrades, zl_upgrades_list, "zl")
	_spawn_upgrades(usd_upgrades, usd_upgrades_list, "usd")
	_update_labels()


# Tworzy jeden przycisk na każdy wpis w tablicy "upgrades" i wrzuca go
# do kontenera "container" (VBoxContainer, więc same się ułożą w kolumnę).
func _spawn_upgrades(upgrades, container, currency) -> void:
	for upgrade in upgrades:
		# instantiate() = zrób nową "kopię" sceny upgrade_button.tscn
		var button = UpgradeButtonScene.instantiate()
		# add_child() = wstaw tę kopię do drzewa sceny, żeby się pokazała
		container.add_child(button)
		# setup() to nasza własna funkcja w upgrade_button.gd — wypełnia
		# przycisk danymi (nazwa, cena, waluta) i ustawia mu tekst
		button.setup(upgrade, currency)
		# Kiedy przycisk zostanie kupiony, sam wyśle sygnał purchase_requested
		# i przekaże siebie (self) jako argument "button" niżej
		button.purchase_requested.connect(_on_upgrade_purchased)


# Wywoływane za każdym razem, gdy KTÓRYKOLWIEK przycisk ulepszenia zostanie
# kliknięty (i tak, i dla zł, i dla USD — bo oba typy łączymy z tą samą funkcją).
func _on_upgrade_purchased(button) -> void:
	# Sprawdzamy, jaką walutą płaci ten konkretny przycisk, i ile jej mamy
	var balance = zl if button.currency == "zl" else usd

	# Nie stać nas — nic nie rób
	if balance < button.cost:
		return

	# Stać nas — odejmij koszt z właściwej waluty
	if button.currency == "zl":
		zl -= button.cost
	else:
		usd -= button.cost

	# match to jak "switch" w innych językach — sprawdza upgrade_id
	# i wykonuje efekt właściwy dla danego ulepszenia.
	# Żeby dodać nowe ulepszenie, dopisujesz tu kolejną linijkę "id": efekt.
	match button.upgrade_id:
		"click_power":
			click_power += 1
		"usd_click_power":
			usd_click_power += 1

	# Powiedz przyciskowi, żeby podniósł swój poziom i podbił sobie cenę
	button.level_up()
	_update_labels()


# Odświeża wszystko, co pokazuje aktualny stan gry: liczniki i to,
# czy poszczególne przyciski są klikalne (czy nas na nie stać).
func _update_labels() -> void:
	$Label.set_text(str(zl))
	$Label/ProgressBar.value = zl
	usd_label.text = "USD: %d" % usd
	# Przycisk "zarabiaj USD" odblokowuje się dopiero, gdy pasek postępu (zł) się napełni.
	usd_button.disabled = progressBar.value < progressBar.max_value

	# get_children() zwraca wszystkie dzieci kontenera — czyli wszystkie
	# przyciski, które wcześniej stworzyliśmy w _spawn_upgrades()
	for button in zl_upgrades_list.get_children():
		button.update_statePLN(zl)
	for button in usd_upgrades_list.get_children():
		button.update_stateUSD(usd)


func _on_button_button_down() -> void:
	zl += click_power
	_update_labels()

func _on_usd_button_down() -> void:
	usd += usd_click_power
	_update_labels()

func _on_upgrades_button_pressed() -> void:
	upgrades_panel.visible = true

func _on_close_button_pressed() -> void:
	upgrades_panel.visible = false

func _on_button_pressed() -> void:
	settingsWindow.visible = true
