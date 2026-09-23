extends Node

signal usd_changed(new_amount: int)

var usd: int = 0:
	set(value):
		usd = value
		usd_changed.emit(usd)

var usd_per_kill: int = 10  # ile USD dostajesz za zabicie wroga w minigierce (shooter)
