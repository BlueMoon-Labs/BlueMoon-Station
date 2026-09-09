/datum/quirk/smartlink_incompatible
	name = "Несовместимость со смартлинком"
	desc = "Ваш организм не способен поддерживать смартлинк — интерфейс, \
		транслирующий данные о заряде и патронах оружия прямо в сетчатку. \
		Он просто не работает: вы не видите боевой HUD даже когда держите оружие в руках."
	value = 0
	flavor_quirk = TRUE
	medical_record_text = "Пациент несовместим со смартлинком, боевой HUD недоступен."

/datum/quirk/smartlink_incompatible/add()
	. = ..()
	quirk_holder?.refresh_ammo_hud()

/datum/quirk/smartlink_incompatible/remove()
	. = ..()
	quirk_holder?.refresh_ammo_hud()