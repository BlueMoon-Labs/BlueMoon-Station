#define MANUSCRIPT_STAGES 3
#define MANUSCRIPT_STAGE_TIME (20 SECONDS)
#define MANUSCRIPT_PRICE 500
#define MANUSCRIPT_TRANSLATOR_FEE 150

/datum/round_event_control/station_incident/service/rare_manuscript
	name = "Rare Manuscript"
	typepath = /datum/round_event/station_incident/service/rare_manuscript
	family = "rare_manuscript"
	min_players = 4
	area_groups = list(list(/area/service/library))
	announcement_title = "Архивная служба NanoTrasen"

/datum/round_event_control/station_incident/service/rare_manuscript/New()
	. = ..()
	incident_message = "При разборе архива списанной станции нашлась опечатанная рукопись без описи, её отправили в библиотеку. Библиотекарю поручено расшифровать текст, Архивная служба заплатит переводчику [MANUSCRIPT_TRANSLATOR_FEE] кредитов. Готовый перевод можно поставить на полку библиотеки, где его прочтут, или продать коллекционерам через карго. Просим не ставить на рукопись кружки: она старше большинства экипажа."
	description = "В библиотеку капсулой прибывает опечатанная старинная рукопись. Расшифровка идёт в [MANUSCRIPT_STAGES] этапа по [DisplayTimeText(MANUSCRIPT_STAGE_TIME)] (библиотекарю вдвое быстрее), каждый открывает фрагмент истории; к последнему приложена опись тайника смотрителя в техтоннелях (консервы, игрушка, немного наличных). Переводчик получает [MANUSCRIPT_TRANSLATOR_FEE] кредитов, перевод можно поставить на полку библиотеки (прочитавшие получают хорошее настроение) или продать через карго за [MANUSCRIPT_PRICE] кредитов."

/datum/round_event/station_incident/service/rare_manuscript

/datum/round_event/station_incident/service/rare_manuscript/pack_shipment(obj/structure/closet/supplypod/pod)
	new /obj/item/book/minor_manuscript(pod)

/datum/mood_event/minor_manuscript_read
	description = "<span class='nicegreen'>Журнал смотрителя «Кедр-4» - хорошая история, особенно про кота.</span>\n"
	mood_change = 2
	timeout = 10 MINUTES

/obj/item/book/minor_manuscript
	name = "sealed manuscript"
	desc = "Стопка ломких листов в кожаной обложке, перевязанная шнуром и запечатанная сургучом. Почерк мелкий, чернила выцвели."
	icon = 'modular_bluemoon/icons/obj/minor_incidents/rare_manuscript.dmi'
	icon_state = "manuscript_sealed"
	unique = TRUE
	has_drm = TRUE
	title = "Журнал смотрителя ретранслятора «Кедр-4»"
	author = "Ирма Вальц"
	var/stage = 0
	var/deciphering = FALSE
	/// Расшифрованная рукопись побывала на полке библиотеки и радует читателей.
	var/shelved = FALSE
	var/cache_note
	var/static/list/fragments = list(
		"Запись смотрителя ретранслятора «Кедр-4» Ирмы Вальц, сделанная задолго до того, как в секторе появились станции NanoTrasen. Буксир снабжения опаздывает на девятый день. Кофе кончился на третий, на четвёртый она начала разговаривать с антенной. Антенна отвечает только помехами, зато строго по расписанию.",
		"На двенадцатый день в помехах появляется ритм: короткий, длинный, короткий, и так каждые сорок минут. Ирма сверяет пеленг с картой и находит источник - дрейфующий грузовой контейнер в двух часах лёта. Буксира всё нет, поэтому она берёт ремонтную капсулу и летит сама, «потому что кто-то же должен».",
		"В контейнере нет ни сокровищ, ни чудовищ. Обогреватель исправен, ящик консервированной рыбы вскрыт, а на тёплой кнопке аварийного маяка спит рыжий кот, сбежавший с какого-то судна: это он отбивал сигнал, ворочаясь во сне. Буксир приходит на следующий день, кота зачисляют в штат ретранслятора с окладом в одну банку рыбы в неделю. Смотритель пишет, что лучшего сотрудника у неё не было.",
	)

/obj/item/book/minor_manuscript/examine(mob/user)
	. = ..()
	if(stage >= MANUSCRIPT_STAGES)
		. += span_notice("Перевод готов: рукопись можно читать, поставить на полку библиотеки или продать через карго.")
		. += span_notice((shelved ? "Рукопись числится в фонде библиотеки: прочитавшие её получают хорошее настроение." : "Поставьте её на книжную полку в библиотеке, и каждый прочитавший получит хорошее настроение."))
		if(cache_note)
			. += span_notice("Под обложкой вложена опись тайника смотрителя: [cache_note].")
		return
	. += span_notice("Расшифровано этапов: [stage] из [MANUSCRIPT_STAGES]. Используйте рукопись в руке, чтобы продолжить: этап занимает [DisplayTimeText(MANUSCRIPT_STAGE_TIME)], у библиотекаря вдвое быстрее. За полный перевод Архивная служба платит [MANUSCRIPT_TRANSLATOR_FEE] кредитов.")

/obj/item/book/minor_manuscript/update_icon_state()
	icon_state = stage ? "manuscript_open" : "manuscript_sealed"
	return ..()

/obj/item/book/minor_manuscript/Moved(atom/OldLoc, Dir, Forced = FALSE)
	. = ..()
	if(!shelved && stage >= MANUSCRIPT_STAGES && is_library_shelf(loc))
		shelved = TRUE
		log_game("DIRECTOR: Rare Manuscript, перевод поставлен на полку в [get_area_name(loc, TRUE)].")

/obj/item/book/minor_manuscript/proc/is_library_shelf(atom/place)
	return istype(place, /obj/structure/bookcase) && istype(get_area(place), /area/service/library)

/obj/item/book/minor_manuscript/attack_self(mob/user)
	if(stage >= MANUSCRIPT_STAGES)
		if(!user.can_read(src))
			return
		..()
		reward_reader(user)
		return
	if(deciphering || !user.can_read(src))
		return
	deciphering = TRUE
	if(!stage)
		to_chat(user, span_notice("Вы осторожно ломаете сургучную печать и разбираете первые строки..."))
	else
		to_chat(user, span_notice("Вы возвращаетесь к выцветшим строкам..."))
	var/finished = do_after(user, decipher_time(user), target = src)
	deciphering = FALSE
	if(finished)
		advance_stage(user)

/obj/item/book/minor_manuscript/proc/reward_reader(mob/living/reader)
	if(!shelved || !isliving(reader))
		return FALSE
	SEND_SIGNAL(reader, COMSIG_ADD_MOOD_EVENT, "minor_manuscript_read", /datum/mood_event/minor_manuscript_read)
	return TRUE

/obj/item/book/minor_manuscript/proc/decipher_time(mob/user)
	return user?.mind?.assigned_role == "Curator" ? MANUSCRIPT_STAGE_TIME / 2 : MANUSCRIPT_STAGE_TIME

/// Один этап расшифровки: открывает следующий фрагмент, на последнем выдаёт перевод.
/obj/item/book/minor_manuscript/proc/advance_stage(mob/user)
	if(stage >= MANUSCRIPT_STAGES)
		return FALSE
	stage++
	if(stage == 1)
		name = "unsealed manuscript"
		desc = "Стопка ломких листов в кожаной обложке. Сургучная печать сломана, шнур развязан; почерк мелкий, чернила выцвели."
	var/fragment = fragments[stage]
	dat += "<p>[fragment]</p>"
	to_chat(user, span_notice("<b>Фрагмент [stage] из [MANUSCRIPT_STAGES].</b> [fragment]"))
	playsound(src, pick('sound/effects/pageturn1.ogg', 'sound/effects/pageturn2.ogg', 'sound/effects/pageturn3.ogg'), 40, TRUE)
	update_appearance()
	if(stage >= MANUSCRIPT_STAGES)
		finish_transcription(user)
	return TRUE

/obj/item/book/minor_manuscript/proc/find_cache_spot()
	var/list/spots = find_maintenance_hideouts(1)
	return length(spots) ? spots[1] : null

/// Тайник смотрителя в техтоннелях появляется вместе с последним фрагментом.
/obj/item/book/minor_manuscript/proc/place_cache()
	var/turf/spot = find_cache_spot()
	if(!spot)
		return null
	new /obj/item/storage/toolbox/minor_keeper_stash(spot)
	cache_note = describe_hideout(spot)
	log_game("DIRECTOR: Rare Manuscript, тайник смотрителя в [AREACOORD(spot)].")
	return spot

/obj/item/book/minor_manuscript/proc/finish_transcription(mob/user)
	name = "transcribed manuscript"
	desc = "Старинная рукопись в кожаной обложке. Между страницами вложены закладки, текст расшифрован целиком."
	var/postscript = ""
	if(place_cache())
		postscript = "Под обложкой вложена опись архива: «Личный ящик смотрителя И. Вальц (консервы для кота, игрушка, жалованье за последний месяц) при переезде оставлен в технических тоннелях станции: [cache_note]»."
		dat += "<p><i>[postscript]</i></p>"
	var/obj/item/paper/translation = new(drop_location())
	translation.name = "paper - 'Manuscript translation'"
	translation.add_raw_text("<b>[title]</b><br>Перевод с полустёртого оригинала.<br><br>[jointext(fragments, "<br><br>")][postscript ? "<br><br><i>[postscript]</i>" : ""]")
	translation.update_appearance()
	var/datum/bank_account/account = minor_service_account_of(user)
	if(account)
		account.adjust_money(MANUSCRIPT_TRANSLATOR_FEE, "Архивная служба NanoTrasen: оплата перевода")
		account.bank_card_talk("Получено [MANUSCRIPT_TRANSLATOR_FEE] кр. за перевод рукописи.")
	if(user)
		user.put_in_hands(translation)
		to_chat(user, span_notice("Последняя страница поддаётся. Вы переписываете перевод на чистый лист.[postscript ? " [postscript]" : ""]"))
	log_game("DIRECTOR: Rare Manuscript, рукопись расшифровал [key_name(user)] в [get_area_name(src, TRUE)], [account ? "оплата [MANUSCRIPT_TRANSLATOR_FEE] кр." : "без счёта"].")

/obj/item/storage/toolbox/minor_keeper_stash
	name = "keeper's stash"
	desc = "Облезлый ящик для инструментов. На крышке выцарапано: «Рыжему. Не трогать»."
	icon_state = "toolbox_blue_old"
	item_state = "toolbox_blue"
	has_latches = FALSE
	can_rubberify = FALSE

/obj/item/storage/toolbox/minor_keeper_stash/PopulateContents()
	new /obj/item/reagent_containers/food/snacks/tuna(src)
	new /obj/item/toy/cattoy(src)
	new /obj/item/stack/spacecash/c100(src)

/datum/export/minor_manuscript
	cost = MANUSCRIPT_PRICE
	k_elasticity = 0
	unit_name = "transcribed manuscript"
	export_types = list(/obj/item/book/minor_manuscript)

/datum/export/minor_manuscript/get_cost(obj/item/book/minor_manuscript/manuscript, allowed_categories, apply_elastic)
	if(!istype(manuscript) || manuscript.stage < MANUSCRIPT_STAGES)
		return 0
	return ..()

#undef MANUSCRIPT_STAGES
#undef MANUSCRIPT_STAGE_TIME
#undef MANUSCRIPT_PRICE
#undef MANUSCRIPT_TRANSLATOR_FEE
