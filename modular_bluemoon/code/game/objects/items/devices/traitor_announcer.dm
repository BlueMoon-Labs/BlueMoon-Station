#define TRAITOR_ANNOUNCER_INFINITE_CHARGES -1

var/static/list/traitor_announcer_styles = list(
	"Центком",
	"Приоритетное",
	"Капитан / консоль связи",
	"Синдикат",
	"ИИ",
	"Ионный шторм",
	"Сбой ИИ",
	"Биоугроза (уровень 5)",
	"Биоугроза (уровень 7)",
)

/obj/item/device/traitor_announcer
	name = "odd device"
	desc = "Хм... а это для чего?"
	icon = 'icons/obj/device.dmi'
	icon_state = "shield0"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	item_state = "electronic"
	/// Сколько использований осталось; -1 — бесконечно.
	var/uses = 1

/obj/item/device/traitor_announcer/examine(mob/user)
	. = ..()
	. += span_notice("Пульт для передачи поддельного приоритетного объявления по вашему сценарию.")
	if(uses == TRAITOR_ANNOUNCER_INFINITE_CHARGES)
		. += span_notice("Зарядов: бесконечно.")
	else if(uses > 0)
		. += span_notice("Осталось использований: [uses].")
	else
		. += span_warning("Заряд исчерпан.")

/obj/item/device/traitor_announcer/attack_self(mob/user)
	. = ..()
	if(!isliving(user) || uses == 0)
		balloon_alert(user, "заряд исчерпан!")
		return
	var/mob/living/L = user
	if(L.incapacitated() || !L.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return
	var/origin = reject_bad_text(tgui_input_text(L, "Кто объявляет или откуда исходит сообщение?", "Источник объявления", get_area_name(L), max_length = 28), 28, FALSE)
	if(!origin)
		balloon_alert(L, "некорректный источник!")
		return
	var/audio_key = tgui_input_list(L, "Какой звук объявления проиграть? (по умолчанию — intercept)", "Звук объявления", GLOB.announcer_keys, ANNOUNCER_INTERCEPT)
	if(!audio_key)
		balloon_alert(L, "некорректный звук!")
		return
	var/style_name = tgui_input_list(L, "Какой стиль оформления использовать?", "Стиль объявления", traitor_announcer_styles)
	if(!style_name)
		balloon_alert(L, "некорректный стиль!")
		return
	var/announce_type = resolve_announcement_type(style_name)
	var/title = reject_bad_text(tgui_input_text(L, "Заголовок объявления.", "Заголовок", max_length = 42), 42, FALSE)
	if(!title)
		balloon_alert(L, "некорректный заголовок!")
		return
	var/input = reject_bad_text(tgui_input_text(L, "Текст объявления.", "Текст", max_length = 512, multiline = TRUE), 512, FALSE)
	if(!input)
		balloon_alert(L, "некорректный текст!")
		return
	var/list/message_data = L.treat_message(input)
	priority_announce(
		text = message_data["message"],
		title = title,
		sound = audio_key,
		type = announce_type,
		sender_override = origin,
		has_important_message = TRUE,
	)
	if(uses != TRAITOR_ANNOUNCER_INFINITE_CHARGES)
		uses--
	deadchat_broadcast(" сделал(а) поддельное приоритетное объявление из [span_name("[get_area_name(L, TRUE)]")].", span_name("[L.real_name]"), L, message_type = DEADCHAT_ANNOUNCEMENT)
	L.log_talk("\[Заголовок\]: [title], \[Текст\]: [input], \[Ключ звука\]: [audio_key]", LOG_TELECOMMS, tag = "priority announcement")
	message_admins("[ADMIN_LOOKUPFLW(L)] использовал(а) [src] для поддельного объявления: [input].")

/obj/item/device/traitor_announcer/proc/resolve_announcement_type(style_name)
	switch(style_name)
		if("Центком")
			return null
		if("Приоритетное")
			return "Priority"
		if("Капитан / консоль связи")
			return "CommunicationsConsole"
		if("Синдикат")
			return "Syndicate"
		if("ИИ")
			return "AI"
		if("Ионный шторм")
			return "ionstorm"
		if("Сбой ИИ")
			return "aimalf"
		if("Биоугроза (уровень 5)")
			return "outbreak5"
		if("Биоугроза (уровень 7)")
			return "outbreak7"
	return null

/obj/item/device/traitor_announcer/infinite
	uses = TRAITOR_ANNOUNCER_INFINITE_CHARGES

#undef TRAITOR_ANNOUNCER_INFINITE_CHARGES
