// Аванпост — департамент-спавн с двумя размерами: малый (1) и средний (2).
// Папка 1: _maps/RandomRuins/StationRuins/avpost/1/ — малые руины (3x3)
// Папка 2: _maps/RandomRuins/StationRuins/avpost/2/ — средние руины (5x4, 10x5)
// Добавь свои .dmm файлы в эти папки и создай датумы по аналогии.
// Ландмарки: /obj/effect/landmark/stationroom/bluemoon/avpost1 и avpost2

/datum/map_template/ruin/station/avpost/small
	prefix = "_maps/RandomRuins/StationRuins/avpost/1/"

/datum/map_template/ruin/station/avpost/small/avpost1
	id = "avpost1"
	suffix = "avpost1.dmm"
	name = "Аванпост 1"

/datum/map_template/ruin/station/avpost/medium
	prefix = "_maps/RandomRuins/StationRuins/avpost/2/"

/datum/map_template/ruin/station/avpost/medium/avpost2
	id = "avpost2"
	suffix = "avpost2.dmm"
	name = "Аванпост 2"
