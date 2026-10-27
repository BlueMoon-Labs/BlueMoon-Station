/*
 * Язык расы Shadekin — Marish.
 *
 * Портировано из S.P.L.U.R.T-tg и адаптировано под языковую систему
 * BlueMoon-Station: обычный произносимый язык расы.
 */

/datum/language/marish
	name = "Marish"
	desc = "Мягкий, мурлыкающий язык шейдкинов, полный тонких оттенков и протяжных слогов."
	key = "M" // BLUEMOON: "m" уже занят языком modular_sand, поэтому как в SPLURT — заглавная
	space_chance = 55
	icon = 'modular_splurt/icons/misc/language.dmi'
	icon_state = "marish"
	default_priority = 90
	restricted = FALSE // BLUEMOON: язык доступен для выбора в «Дополнительных языках»
	flags = LANGUAGE_HIDE_ICON_IF_NOT_UNDERSTOOD | NO_STUTTER
	syllables = list("mar", "mwrrr", "maaAr", "'aarrr", "wrurrl", "mmar")

/datum/language_holder/shadekin
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/marish = list(LANGUAGE_ATOM)
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/marish = list(LANGUAGE_ATOM)
	)
