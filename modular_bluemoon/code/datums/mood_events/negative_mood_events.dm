/*
 * ИВЕНТЫ НАСТРОЕНИЯ, СВЯЗАННЫЕ С ВАМПИРАМИ-АНТАГОНИСТАМИ
 */

/datum/mood_event/drankkilled/lesser
	description = "<span class='warning'>Моя жертва умерла от потери крови. Это слишком жестоко...</span>\n"
	mood_change = -6
	timeout = 15 MINUTES

/datum/mood_event/drankkilled/minimal
	description = "<span class='danger'>Моя жертва умерла от потери крови... Неужели я действительно такое чудовище?</span>\n"
	mood_change = -3
	timeout = 5 MINUTES

/*
// (ADD) Pe4henika Bluemoon (14.03.2026)
 *MARK:  ИВЕНТЫ ВЗАИМОДЕЙСТВИЯ С ИИ ЧЕРЕЗ НЕЙРОИНТЕРФЕЙС
 */

/datum/mood_event/ai_scold
	description = span_danger("ИИ выразил крайнее недовольство моей эффективностью... Мне стоит работать лучше.\n")
	mood_change = -6
	timeout = 5 MINUTES
