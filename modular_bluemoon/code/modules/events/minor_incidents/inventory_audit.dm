#define AUDIT_ITEM_COUNT 4
#define AUDIT_ITEM_REWARD 150
#define AUDIT_FULL_BONUS 200
#define AUDIT_DURATION (30 MINUTES)
/// Если всё сдано раньше срока, ящик забирают почти сразу.
#define AUDIT_EARLY_PICKUP (1 MINUTES)
/// Насколько вещь сдвинута внутри клетки тайника, в пикселях.
#define AUDIT_ITEM_SCATTER 6
#define AUDIT_ICON 'modular_bluemoon/icons/obj/minor_incidents/inventory_audit.dmi'

/datum/round_event_control/paperwork/inventory_audit
	name = "Inventory Audit"
	description = "Аудит ЦК находит недостачу: четыре обычные вещи с инвентарными бирками лежат в техтоннелях, в приёмную карго или главный коридор прибывает ящик возврата с описью мест. За каждую сданную вещь 150 кр получает тот, кто первым её поднял, за полный возврат бюджет снабжения получает ещё 200 кр. Через полчаса ящик забирают."
	typepath = /datum/round_event/paperwork/inventory_audit
	family = "inventory_audit"
	var/list/bin_areas = list(/area/cargo/lobby, /area/hallway/primary, /area/cargo/office, /area/cargo/sorting, /area/cargo/storage)

/datum/round_event_control/paperwork/inventory_audit/preflight_failure()
	if(!find_delivery_turf(bin_areas))
		return "Нет свободного пола ни в приёмной карго, ни в главных коридорах, ни в отсеках снабжения."
	if(!length(find_hideouts(1)))
		return "В техтоннелях нет укромных мест."
	return null

/datum/round_event/paperwork/inventory_audit
	var/list/audit_item_pool = list(
		/obj/item/analyzer,
		/obj/item/extinguisher,
		/obj/item/flashlight,
		/obj/item/hand_labeler,
		/obj/item/radio,
		/obj/item/stamp,
		/obj/item/stamp/denied,
		/obj/item/storage/toolbox/mechanical,
		/obj/item/t_scanner,
	)
	var/bin_area_name
	var/list/hideout_area_names = list()

/datum/round_event/paperwork/inventory_audit/start()
	var/datum/round_event_control/paperwork/inventory_audit/audit = control
	var/turf/drop_spot = audit.find_delivery_turf(audit.bin_areas)
	var/list/hideouts = audit.find_hideouts(AUDIT_ITEM_COUNT)
	if(!drop_spot || !length(hideouts))
		return
	var/obj/structure/lost_and_found_bin/bin = new()
	var/list/pool = audit_item_pool.Copy()
	var/list/inventory_lines = list()
	for(var/turf/spot as anything in hideouts)
		var/item_type = pick_n_take(pool)
		var/obj/item/lost = new item_type(spot)
		lost.pixel_x = rand(-AUDIT_ITEM_SCATTER, AUDIT_ITEM_SCATTER)
		lost.pixel_y = rand(-AUDIT_ITEM_SCATTER, AUDIT_ITEM_SCATTER)
		var/datum/component/audit_tag/tag = bin.register_item(lost)
		inventory_lines += "[length(inventory_lines) + 1]. [format_text(lost.name)], инв. № [tag.inventory_number]: [describe_hideout(spot)]."
		hideout_area_names |= get_area_name(spot)
	bin_area_name = get_area_name(drop_spot)
	var/obj/item/paper/listing = paperwork_print(null, "paper - 'Audit Inventory List'", "<center><b>ЦЕНТРАЛЬНОЕ КОМАНДОВАНИЕ NANOTRASEN</b><br>Отдел инвентаризации. Опись недостачи</center><br>[jointext(inventory_lines, "<br>")]<br><br>Места указаны по последней сверке. Вещь с биркой опустите в ящик возврата: [AUDIT_ITEM_REWARD] кр за неё получит тот, кто первым её поднял. За возврат всей описи бюджет снабжения получит [AUDIT_FULL_BONUS] кр.")
	bin.start_audit(AUDIT_DURATION)
	deliver(drop_spot, list(bin, listing))
	log_game("DIRECTOR: [control.name], ящик возврата в [bin_area_name], вещей спрятано: [length(hideouts)] ([english_list(hideout_area_names)]).")

/datum/round_event/paperwork/inventory_audit/announce(fake)
	if(!bin_area_name)
		return
	priority_announce("Аудит выявил недостачу: часть станционного имущества числится в описи, но на месте не найдена. По последней сверке вещи остались в техтоннелях ([english_list(hideout_area_names)]), на каждой инвентарная бирка. Ящик возврата и опись с приметами мест доставлены в отсек [bin_area_name]. За каждую сданную вещь [AUDIT_ITEM_REWARD] кр получит тот, кто первым её поднял, за возврат всей описи бюджет снабжения получит ещё [AUDIT_FULL_BONUS] кр. Ящик заберут через [DisplayTimeText(AUDIT_DURATION)].", "Отдел инвентаризации ЦК NanoTrasen")

/// Инвентарная бирка: наклейка на предмете и строка в описании. Помнит, кто первым поднял вещь. Снимается при сдаче или по итогам аудита.
/datum/component/audit_tag
	var/datum/weakref/bin_ref
	var/datum/weakref/finder_ref
	var/finder_name
	var/inventory_number

/datum/component/audit_tag/Initialize(obj/structure/lost_and_found_bin/bin)
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE
	bin_ref = WEAKREF(bin)
	inventory_number = "[rand(100, 999)]-[rand(1000, 9999)]"

/datum/component/audit_tag/RegisterWithParent()
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(parent, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(on_update_overlays))
	RegisterSignal(parent, COMSIG_ITEM_PICKUP, PROC_REF(on_pickup))
	var/obj/item/tagged = parent
	tagged.update_appearance()

/datum/component/audit_tag/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_PARENT_EXAMINE, COMSIG_ATOM_UPDATE_OVERLAYS, COMSIG_ITEM_PICKUP))
	var/obj/item/tagged = parent
	if(!QDELETED(tagged))
		tagged.update_appearance()

/datum/component/audit_tag/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	var/obj/structure/lost_and_found_bin/bin = bin_ref?.resolve()
	var/where = bin ? " ([get_area_name(bin)])" : ""
	var/payee = finder_name ? "При сдаче [AUDIT_ITEM_REWARD] кр уйдут на счёт нашедшего: [finder_name]." : "При сдаче [AUDIT_ITEM_REWARD] кр получит тот, кто первым поднимет вещь."
	examine_list += span_notice("К вещи привязана инвентарная бирка ЦК № [inventory_number]: «Числится за станцией. Вернуть в ящик возврата[where]». [payee]")

/datum/component/audit_tag/proc/on_update_overlays(atom/source, list/overlays)
	SIGNAL_HANDLER
	overlays += mutable_appearance(AUDIT_ICON, "audit_tag")

/datum/component/audit_tag/proc/on_pickup(datum/source, mob/taker)
	SIGNAL_HANDLER
	if(finder_ref || !isliving(taker))
		return
	finder_ref = WEAKREF(taker)
	finder_name = taker.real_name

/obj/structure/lost_and_found_bin
	name = "lost & found return bin"
	desc = "Синий приёмный ящик ЦК с прорезью в крышке и табличкой «Возврат имущества». Вещь с инвентарной биркой опускают в прорезь, а выплата приходит на счёт того, кто первым её поднял."
	icon = AUDIT_ICON
	icon_state = "bin"
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/list/datum/weakref/tagged_items = list()
	var/returned = 0
	var/paid = 0
	var/bonus_paid = FALSE
	var/pickup_timer
	var/collected = FALSE

/obj/structure/lost_and_found_bin/Destroy()
	if(pickup_timer)
		deltimer(pickup_timer)
		pickup_timer = null
	clear_tags()
	return ..()

/obj/structure/lost_and_found_bin/examine(mob/user)
	. = ..()
	. += span_notice("Чтобы сдать вещь с инвентарной биркой, приложите её к ящику. Вернули [returned] из [length(tagged_items)].")
	if(!bonus_paid && !collected)
		. += span_notice("За возврат всей описи бюджет снабжения получит [AUDIT_FULL_BONUS] кр.")
	if(pickup_timer)
		. += span_notice("До отправки ящика в ЦК осталось: [DisplayTimeText(timeleft(pickup_timer), 60)].")

/obj/structure/lost_and_found_bin/proc/register_item(obj/item/lost)
	tagged_items += WEAKREF(lost)
	return lost.AddComponent(/datum/component/audit_tag, src)

/obj/structure/lost_and_found_bin/proc/start_audit(duration)
	pickup_timer = addtimer(CALLBACK(src, PROC_REF(finish_audit)), duration, TIMER_STOPPABLE)

/obj/structure/lost_and_found_bin/attackby(obj/item/item, mob/living/user, params)
	if(user.a_intent == INTENT_HARM)
		return ..()
	if(!item.GetComponent(/datum/component/audit_tag))
		to_chat(user, span_warning("Прорезь не принимает [item]: этой вещи нет в описи аудита."))
		return TRUE
	accept_item(item, user)
	return TRUE

/obj/structure/lost_and_found_bin/proc/accept_item(obj/item/item, mob/living/user)
	var/datum/component/audit_tag/tag = item?.GetComponent(/datum/component/audit_tag)
	if(collected || QDELETED(item) || !tag)
		return FALSE
	if(tag.bin_ref?.resolve() != src)
		to_chat(user, span_warning("Номер на бирке не из этой описи."))
		return FALSE
	if(ismob(item.loc) && !user.temporarilyRemoveItemFromInventory(item))
		return FALSE
	var/mob/living/finder = tag.finder_ref?.resolve()
	qdel(tag)
	SEND_SIGNAL(item, COMSIG_TRY_STORAGE_QUICK_EMPTY, drop_location())
	new /obj/effect/temp_visual/paperwork_intake(get_turf(src), item)
	flick("bin_accept", src)
	playsound(src, 'sound/machines/chime.ogg', 30, FALSE)
	returned++
	paid += AUDIT_ITEM_REWARD
	var/mob/living/payee = pay_reward(item, user, finder)
	log_game("DIRECTOR: Inventory Audit, [key_name(user)] сдал [item] в [AREACOORD(src)], [AUDIT_ITEM_REWARD] кр получил [key_name(payee)].")
	qdel(item)
	var/expected = length(tagged_items)
	if(returned < expected)
		paperwork_radio("Ящик возврата ([get_area_name(src)]): сдано [returned] из [expected].", RADIO_CHANNEL_SUPPLY)
		return TRUE
	pay_full_bonus()
	paperwork_radio("Ящик возврата ([get_area_name(src)]): сданы все вещи описи, [expected] из [expected]. Бюджету снабжения начислено [AUDIT_FULL_BONUS] кр.", RADIO_CHANNEL_SUPPLY)
	if(pickup_timer)
		deltimer(pickup_timer)
		pickup_timer = addtimer(CALLBACK(src, PROC_REF(finish_audit)), AUDIT_EARLY_PICKUP, TIMER_STOPPABLE)
	return TRUE

/// Награда уходит тому, кто первым поднял вещь, а без его счёта - сдавшему. Возвращает получателя.
/obj/structure/lost_and_found_bin/proc/pay_reward(obj/item/item, mob/living/user, mob/living/finder)
	var/mob/living/payee = finder
	var/datum/bank_account/account = paperwork_account_of(finder)
	if(!account)
		payee = user
		account = paperwork_account_of(user)
	if(!account)
		new /obj/item/holochip(drop_location(), AUDIT_ITEM_REWARD)
		to_chat(user, span_notice("Ящик принимает [item] и выдаёт голочип на [AUDIT_ITEM_REWARD] кр: ID-карты со счётом при вас нет."))
		return user
	account.adjust_money(AUDIT_ITEM_REWARD, "ЦК: возврат имущества по аудиту")
	if(payee == user)
		to_chat(user, span_notice("Ящик принимает [item] и пищит: на ваш счёт зачислено [AUDIT_ITEM_REWARD] кр."))
	else
		to_chat(user, span_notice("Ящик принимает [item] и пищит: [AUDIT_ITEM_REWARD] кр ушли на счёт нашедшего, [payee.real_name]."))
		account.bank_card_talk("ЦК: найденная вами вещь ([item]) сдана в ящик возврата, начислено [AUDIT_ITEM_REWARD] кр.")
	return payee

/obj/structure/lost_and_found_bin/proc/pay_full_bonus()
	if(bonus_paid)
		return FALSE
	bonus_paid = TRUE
	var/datum/bank_account/budget = SSeconomy.get_dep_account(ACCOUNT_CAR)
	budget?.adjust_money(AUDIT_FULL_BONUS, "ЦК: полный возврат имущества по аудиту")
	visible_message(span_notice("[src] звенит дважды: опись закрыта полностью."))
	playsound(src, 'sound/machines/ding.ogg', 40, FALSE)
	log_game("DIRECTOR: Inventory Audit, опись закрыта полностью в [AREACOORD(src)], бюджету снабжения начислено [AUDIT_FULL_BONUS] кр.")
	return TRUE

/// Итог аудита на бумаге, бирки с несданных вещей снимаются, ящик забирает капсула.
/obj/structure/lost_and_found_bin/proc/finish_audit(launch_pod = TRUE)
	if(collected)
		return FALSE
	collected = TRUE
	if(pickup_timer)
		deltimer(pickup_timer)
		pickup_timer = null
	var/expected = length(tagged_items)
	clear_tags()
	var/missing = expected - returned
	var/verdict = missing ? "Не найдено: [missing]. Вещи списаны как износ, взысканий не будет." : "Недостача закрыта полностью. Бюджету снабжения начислена премия [AUDIT_FULL_BONUS] кр."
	paperwork_print(drop_location(), "paper - 'Audit Summary'", "ЦЕНТРАЛЬНОЕ КОМАНДОВАНИЕ NANOTRASEN<br>Отдел инвентаризации. Итог аудита станционного имущества.<br><br>Числилось к возврату: [expected].<br>Возвращено: [returned].<br>Выплачено нашедшим: [paid] кр.<br>[verdict]<br><br>Спасибо за содействие. Ящик возврата отозван.")
	visible_message(span_notice("[src] печатает итог аудита и мигает лампой: за ящиком летит капсула."))
	playsound(src, 'sound/machines/twobeep.ogg', 40, FALSE)
	log_game("DIRECTOR: Inventory Audit завершён в [AREACOORD(src)], возвращено [returned] из [expected], выплачено [paid] кр.")
	if(launch_pod)
		paperwork_pickup_pod(src)
	return TRUE

/obj/structure/lost_and_found_bin/proc/clear_tags()
	for(var/datum/weakref/item_ref as anything in tagged_items)
		var/obj/item/lost = item_ref.resolve()
		var/datum/component/audit_tag/tag = lost?.GetComponent(/datum/component/audit_tag)
		if(tag?.bin_ref?.resolve() == src)
			qdel(tag)

#undef AUDIT_ITEM_COUNT
#undef AUDIT_ITEM_REWARD
#undef AUDIT_FULL_BONUS
#undef AUDIT_DURATION
#undef AUDIT_EARLY_PICKUP
#undef AUDIT_ITEM_SCATTER
#undef AUDIT_ICON
