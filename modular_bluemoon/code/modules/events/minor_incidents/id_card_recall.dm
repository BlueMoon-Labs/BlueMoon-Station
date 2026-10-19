#define CARD_RECALL_MIN_CARDS 2
#define CARD_RECALL_MAX_CARDS 4
#define CARD_RECALL_REWARD 150
/// Плата главе персонала за замену чужой карты.
#define CARD_RECALL_HOP_FEE 50
#define CARD_RECALL_DURATION (40 MINUTES)
#define CARD_RECALL_SWAP_TIME (5 SECONDS)
/// Когда все карты партии заменены, терминал забирают почти сразу.
#define CARD_RECALL_EARLY_PICKUP (2 MINUTES)
#define CARD_RECALL_HOP_JOB "Head of Personnel"
#define CARD_RECALL_ICON 'modular_bluemoon/icons/obj/minor_incidents/id_card_recall.dmi'

/datum/round_event_control/paperwork/id_card_recall
	name = "ID Card Recall"
	description = "ЦК отзывает партию ID-карт с дефектным чипом: у 2-4 членов экипажа на карте мигает жёлтая метка, доступ сохраняется. В офис HoP или в общий коридор прибывает терминал отзыва со списком карт; замена чипа занимает секунды, владельцу приходит 150 кр компенсации, HoP получает 50 кр за каждую чужую карту. В конце терминал печатает итог со списком незаменённых карт."
	typepath = /datum/round_event/paperwork/id_card_recall
	family = "id_card_recall"
	min_players = 8

/datum/round_event_control/paperwork/id_card_recall/preflight_failure()
	if(length(get_recall_candidates()) < CARD_RECALL_MIN_CARDS)
		return "Меньше [CARD_RECALL_MIN_CARDS] сотрудников со своей ID-картой на теле."
	if(!find_terminal_turf())
		return "Некуда поставить терминал отзыва."
	return null

/datum/round_event_control/paperwork/id_card_recall/proc/get_recall_candidates()
	. = list()
	for(var/mob/living/carbon/human/crew as anything in GLOB.human_list)
		if(crew.client && is_recall_eligible(crew))
			. += crew

/// Без HoP на смене его кабинет заперт, поэтому терминал ставят в общедоступном месте.
/datum/round_event_control/paperwork/id_card_recall/proc/find_terminal_turf()
	var/list/area_types = list(/area/hallway/primary, /area/cargo/lobby, /area/cargo/office)
	if(is_hop_on_shift())
		area_types.Insert(1, /area/command/heads_quarters/hop)
	return find_delivery_turf(area_types)

/proc/is_hop_on_shift()
	for(var/mob/living/carbon/human/crew as anything in GLOB.human_list)
		if(crew.client && crew.mind?.assigned_role == CARD_RECALL_HOP_JOB && is_effective_crew_mob(crew))
			return TRUE
	return FALSE

/// Живой член экипажа, не синтетик, со своей ID-картой в слоте ID.
/proc/is_recall_eligible(mob/living/carbon/human/crew)
	if(QDELETED(crew) || !is_effective_crew_mob(crew) || isrobotic(crew))
		return FALSE
	var/obj/item/card/id/card = crew.wear_id?.GetID()
	return is_recallable_card(card, crew)

/proc/is_recallable_card(obj/item/card/id/card, mob/living/carbon/human/owner)
	var/static/list/excluded_cards = typecacheof(list(
		/obj/item/card/id/away,
		/obj/item/card/id/centcom,
		/obj/item/card/id/debug,
		/obj/item/card/id/departmental_budget,
		/obj/item/card/id/ert,
		/obj/item/card/id/prisoner,
		/obj/item/card/id/syndicate,
	))
	if(!istype(card) || is_type_in_typecache(card, excluded_cards) || !card.registered_account)
		return FALSE
	if(card.GetComponent(/datum/component/id_card_recall))
		return FALSE
	return card.registered_name == owner.real_name

/datum/round_event/paperwork/id_card_recall
	var/terminal_area_name
	var/recalled_count = 0

/datum/round_event/paperwork/id_card_recall/start()
	var/datum/round_event_control/paperwork/id_card_recall/recall = control
	var/list/candidates = shuffle(recall.get_recall_candidates())
	var/count = min(rand(CARD_RECALL_MIN_CARDS, CARD_RECALL_MAX_CARDS), length(candidates))
	var/turf/spot = recall.find_terminal_turf()
	if(count < CARD_RECALL_MIN_CARDS || !spot)
		return
	terminal_area_name = get_area_name(spot)
	var/obj/structure/card_recall_terminal/terminal = new()
	for(var/i in 1 to count)
		var/mob/living/carbon/human/owner = candidates[i]
		terminal.recall_card(owner.wear_id.GetID(), owner, terminal_area_name)
	recalled_count = count
	var/obj/item/paper/listing = terminal.print_recall_list(null)
	terminal.start_recall(CARD_RECALL_DURATION)
	deliver(spot, list(terminal, listing))
	log_game("DIRECTOR: [control.name], терминал в [terminal_area_name], отозвано карт: [count].")

/datum/round_event/paperwork/id_card_recall/announce(fake)
	if(!terminal_area_name)
		return
	priority_announce("Центральное командование отзывает партию ID-карт: в части чипов найден производственный дефект. Затронутые карты помечены мигающей жёлтой меткой, доступ у них сохраняется. Терминал замены доставлен в отсек [terminal_area_name] вместе со списком карт; замена занимает несколько секунд, за беспокойство владельцу положено [CARD_RECALL_REWARD] кр, а главе персонала - [CARD_RECALL_HOP_FEE] кр за каждую заменённую им чужую карту.", "Служба идентификации персонала ЦК")

/// Отметка об отзыве: мигающая метка на карте и строка в описании. Доступ и всё остальное не меняются.
/datum/component/id_card_recall
	var/datum/weakref/terminal_ref
	var/terminal_area_name

/datum/component/id_card_recall/Initialize(obj/structure/card_recall_terminal/terminal, area_name)
	if(!istype(parent, /obj/item/card/id))
		return COMPONENT_INCOMPATIBLE
	terminal_ref = WEAKREF(terminal)
	terminal_area_name = area_name

/datum/component/id_card_recall/RegisterWithParent()
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(parent, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(on_update_overlays))
	var/obj/item/card/id/card = parent
	card.update_appearance()

/datum/component/id_card_recall/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_PARENT_EXAMINE, COMSIG_ATOM_UPDATE_OVERLAYS))
	var/obj/item/card/id/card = parent
	if(!QDELETED(card))
		card.update_appearance()

/datum/component/id_card_recall/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	var/where = terminal_area_name ? ", отсек [terminal_area_name]" : ""
	examine_list += span_notice("В углу карты мигает жёлтая метка: чип из отозванной партии. Доступ работает как обычно. Замените чип в терминале отзыва ЦК[where], владельцу счёта положена компенсация [CARD_RECALL_REWARD] кр.")

/datum/component/id_card_recall/proc/on_update_overlays(atom/source, list/overlays)
	SIGNAL_HANDLER
	overlays += mutable_appearance(CARD_RECALL_ICON, "recall_mark")

/obj/structure/card_recall_terminal
	name = "card recall terminal"
	desc = "Настольный терминал ЦК для замены чипов ID-карт из отозванной партии. Помеченную карту вставляют в слот: через несколько секунд чип заменён, доступ сохранён, владельцу счёта приходит компенсация, а глава персонала получает плату за каждую замену чужой карты."
	icon = CARD_RECALL_ICON
	icon_state = "terminal"
	density = TRUE
	anchored = FALSE
	pass_flags = PASSTABLE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/list/datum/weakref/recalled_cards = list()
	var/list/recall_entries = list()
	var/list/datum/weakref/replaced_cards = list()
	var/compensation_paid = 0
	var/hop_fees_paid = 0
	var/busy = FALSE
	var/finished = FALSE
	var/pickup_timer

/obj/structure/card_recall_terminal/Destroy()
	if(pickup_timer)
		deltimer(pickup_timer)
		pickup_timer = null
	clear_notices()
	return ..()

/obj/structure/card_recall_terminal/examine(mob/user)
	. = ..()
	. += span_notice("Чтобы заменить чип, приложите к терминалу помеченную ID-карту. Заменено [length(replaced_cards)] из [length(recalled_cards)]. Глава персонала получает [CARD_RECALL_HOP_FEE] кр за каждую заменённую им чужую карту.")
	if(pickup_timer)
		. += span_notice("До отправки терминала в ЦК осталось: [DisplayTimeText(timeleft(pickup_timer), 60)].")

/obj/structure/card_recall_terminal/proc/recall_card(obj/item/card/id/card, mob/living/owner, area_name)
	card.AddComponent(/datum/component/id_card_recall, src, area_name)
	recalled_cards += WEAKREF(card)
	recall_entries += "[card.registered_name], [card.assignment || "без должности"]"
	if(owner)
		owner.playsound_local(get_turf(owner), 'sound/machines/twobeep_high.ogg', 30, FALSE)
		to_chat(owner, span_notice("Ваша ID-карта коротко пищит, в её углу замигала жёлтая метка. Центральное командование NanoTrasen приносит извинения: чип вашей карты входит в партию с производственным дефектом. Доступ сохраняется. Пожалуйста, замените чип в терминале отзыва (отсек [area_name]): это займёт несколько секунд, а за беспокойство на ваш счёт придёт [CARD_RECALL_REWARD] кр."))

/obj/structure/card_recall_terminal/proc/print_recall_list(atom/location)
	var/list/lines = list()
	for(var/i in 1 to length(recall_entries))
		lines += "[i]. [recall_entries[i]]"
	return paperwork_print(location, "paper - 'ID Card Recall List'", "<center><b>СЛУЖБА ИДЕНТИФИКАЦИИ ПЕРСОНАЛА ЦК</b><br>Список отзываемых ID-карт</center><br>[jointext(lines, "<br>")]<br><br>Доступ у карт сохраняется, на каждой мигает жёлтая метка. Владельцу нужно приложить карту к терминалу отзыва; замена чипа занимает несколько секунд, компенсация [CARD_RECALL_REWARD] кр приходит на счёт владельца автоматически. Терминал работает для любого сотрудника, а глава персонала получает [CARD_RECALL_HOP_FEE] кр за каждую заменённую им чужую карту.")

/obj/structure/card_recall_terminal/proc/start_recall(duration)
	pickup_timer = addtimer(CALLBACK(src, PROC_REF(finish_recall)), duration, TIMER_STOPPABLE)

/obj/structure/card_recall_terminal/attackby(obj/item/item, mob/living/user, params)
	var/obj/item/card/id/card = item.GetID()
	if(!card || user.a_intent == INTENT_HARM)
		return ..()
	if(finished)
		to_chat(user, span_warning("Кампания отзыва закрыта, терминал ждёт отправки в ЦК."))
		return TRUE
	if(busy)
		to_chat(user, span_warning("Терминал уже меняет чип."))
		return TRUE
	if(!card.GetComponent(/datum/component/id_card_recall))
		playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 30, FALSE)
		to_chat(user, span_notice("Терминал сверяет серийный номер: чип [card] исправен, замена не нужна."))
		return TRUE
	busy = TRUE
	icon_state = "terminal_working"
	playsound(src, 'sound/machines/card_slide.ogg', 40, FALSE)
	to_chat(user, span_notice("Вы вставляете [card] в слот. Терминал выпаивает старый чип..."))
	if(do_after(user, CARD_RECALL_SWAP_TIME, src))
		replace_chip(card, user)
	busy = FALSE
	icon_state = initial(icon_state)
	return TRUE

/obj/structure/card_recall_terminal/proc/replace_chip(obj/item/card/id/card, mob/living/user)
	var/datum/component/id_card_recall/notice = card?.GetComponent(/datum/component/id_card_recall)
	if(finished || !notice)
		return FALSE
	qdel(notice)
	replaced_cards += WEAKREF(card)
	flick("terminal_done", src)
	playsound(src, 'sound/machines/terminal_success.ogg', 40, FALSE)
	var/datum/bank_account/account = card.registered_account
	if(account)
		account.adjust_money(CARD_RECALL_REWARD, "ЦК: компенсация за отзыв ID-карты")
		account.bank_card_talk("Компенсация за замену чипа ID-карты: [CARD_RECALL_REWARD] кр.")
		compensation_paid += CARD_RECALL_REWARD
	var/hop_paid = pay_hop_fee(card, user)
	to_chat(user, span_notice("Чип [card] заменён, доступ сохранён.[account ? " Владельцу счёта начислено [CARD_RECALL_REWARD] кр." : ""][hop_paid ? " За обслуживание на ваш счёт начислено [CARD_RECALL_HOP_FEE] кр." : ""]"))
	log_game("DIRECTOR: ID Card Recall, [key_name(user)] заменил чип карты [card.registered_name], компенсация [account ? CARD_RECALL_REWARD : 0] кр, плата HoP [hop_paid ? CARD_RECALL_HOP_FEE : 0] кр.")
	if(length(replaced_cards) >= length(recalled_cards) && pickup_timer)
		deltimer(pickup_timer)
		pickup_timer = addtimer(CALLBACK(src, PROC_REF(finish_recall)), CARD_RECALL_EARLY_PICKUP, TIMER_STOPPABLE)
	return TRUE

/// Глава персонала, заменивший чужую карту, получает плату на счёт своей надетой карты.
/obj/structure/card_recall_terminal/proc/pay_hop_fee(obj/item/card/id/card, mob/living/user)
	if(user?.mind?.assigned_role != CARD_RECALL_HOP_JOB || card.registered_name == user.real_name)
		return FALSE
	var/obj/item/card/id/own_card = user.get_idcard(FALSE)
	if(!own_card || own_card == card || !own_card.registered_account)
		return FALSE
	own_card.registered_account.adjust_money(CARD_RECALL_HOP_FEE, "ЦК: обслуживание отзыва ID-карт")
	hop_fees_paid += CARD_RECALL_HOP_FEE
	return TRUE

/// Кампания закрыта: итог со списком незаменённых карт, отметки снимаются, терминал забирает капсула.
/obj/structure/card_recall_terminal/proc/finish_recall(launch_pod = TRUE)
	if(finished)
		return FALSE
	finished = TRUE
	anchored = TRUE
	if(pickup_timer)
		deltimer(pickup_timer)
		pickup_timer = null
	var/list/pending = list()
	for(var/i in 1 to length(recalled_cards))
		if(!(recalled_cards[i] in replaced_cards))
			pending += "[length(pending) + 1]. [recall_entries[i]]"
	clear_notices()
	var/verdict = length(pending) ? "Не заменены, признаны годными, метки сняты:<br>[jointext(pending, "<br>")]" : "Все карты партии заменены."
	paperwork_print(drop_location(), "paper - 'ID Card Recall Summary'", "<center><b>СЛУЖБА ИДЕНТИФИКАЦИИ ПЕРСОНАЛА ЦК</b><br>Итог отзыва ID-карт</center><br>Заменено чипов: [length(replaced_cards)] из [length(recalled_cards)].<br>Компенсаций владельцам: [compensation_paid] кр.<br>Плата главе персонала: [hop_fees_paid] кр.<br><br>[verdict]")
	visible_message(span_notice("[src] пищит и печатает итог: кампания отзыва закрыта.[length(pending) ? " Незаменённых карт: [length(pending)]." : ""] За терминалом летит капсула."))
	log_game("DIRECTOR: ID Card Recall завершён в [AREACOORD(src)], заменено [length(replaced_cards)] из [length(recalled_cards)].")
	if(launch_pod)
		paperwork_pickup_pod(src)
	return TRUE

/obj/structure/card_recall_terminal/proc/clear_notices()
	for(var/datum/weakref/card_ref as anything in recalled_cards)
		var/obj/item/card/id/card = card_ref.resolve()
		var/datum/component/id_card_recall/notice = card?.GetComponent(/datum/component/id_card_recall)
		if(notice?.terminal_ref?.resolve() == src)
			qdel(notice)

#undef CARD_RECALL_MIN_CARDS
#undef CARD_RECALL_MAX_CARDS
#undef CARD_RECALL_REWARD
#undef CARD_RECALL_HOP_FEE
#undef CARD_RECALL_DURATION
#undef CARD_RECALL_SWAP_TIME
#undef CARD_RECALL_EARLY_PICKUP
#undef CARD_RECALL_HOP_JOB
#undef CARD_RECALL_ICON
