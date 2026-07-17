/// Mappers: place on the InteQ evac / bridge when the venue is ready. Code-only repo: type exists for mapping later.
/obj/machinery/inteq_bluespace_evac_activator
	name = "InteQ bluespace evac interlock"
	desc = "Поднимает сигнатуру запуска БС-двигателя и переводит станционные Врата ПАКТ в режим «красного канала» на ваш объект. Требуется личное присутствие оперативника InteQ."
	icon = 'icons/obj/device.dmi'
	icon_state = "syndbeacon"
	density = TRUE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF

/obj/machinery/inteq_bluespace_evac_activator/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(!isliving(user))
		return
	if(GLOB.inteq_pact_siege.active)
		to_chat(user, span_warning("Протокол осады уже активен."))
		return
	var/ask = tgui_alert(user, "Инициировать тревогу и открыть «красный канал» для ПАКТ? Станция получит объявление ЦК.", "БС-двигатель InteQ", list("Да", "Нет"), timeout = 30 SECONDS)
	if(ask != "Да")
		return
	if(!GLOB.inteq_pact_siege.role_check_inteq(user))
		to_chat(user, span_warning("Консоль не реагирует: нет авторизации InteQ."))
		return

	user.visible_message(span_notice("[user] начинает последовательность синхронизации emergency bluespace drive..."), span_notice("Вы начинаете последовательность синхронизации..."))
	if(!do_after(user, 12 SECONDS, target = src))
		return
	if(GLOB.inteq_pact_siege.activate(user))
		playsound(src, 'sound/machines/gateway/gateway_open.ogg', 65, TRUE)
