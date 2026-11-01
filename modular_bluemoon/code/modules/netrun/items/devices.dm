// MARK: Кибердека

/// Переносной терминал нетраннера. Работает по NTnet или проводом, воткнутым в машину рядом.
/obj/item/netrun_deck
	name = "cyberdeck"
	desc = "Плоский переносной терминал с выдвижным кабелем. Воткните кабель в машину рядом, чтобы подключиться к её локальной сети напрямую."
	icon = 'icons/obj/device.dmi'
	icon_state = "hand_tele"
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_BELT
	var/datum/netrun_console/console
	var/buffer_bonus = 0
	var/storage_capacity = 8 * NETRUN_STORAGE_SCALE
	/// Дека перегорела от ответного удара и до этого времени не работает
	var/burnt_until = 0

/obj/item/netrun_deck/Initialize(mapload)
	. = ..()
	console = new(src, NETRUN_ORIGIN_DECK)
	console.connection.wireless = TRUE
	console.intrusion.buffer_bonus = buffer_bonus
	console.inventory.local_store.capacity = storage_capacity
	console.tgui_title = "Кибердека"
	AddComponent(/datum/component/netrun_access_device, console, NETRUN_NODE_DECK)

/obj/item/netrun_deck/Destroy()
	QDEL_NULL(console)
	return ..()

/obj/item/netrun_deck/examine(mob/user)
	. = ..()
	if(world.time < burnt_until)
		. += span_warning("Из корпуса тянет горелой изоляцией. Ещё [round((burnt_until - world.time) / (1 SECONDS))] сек.")
	if(console?.connection.jack)
		. += span_notice("Кабель подключён к [console.connection.jack.get_name()].")
	. += span_notice("Буфер взлома: +[buffer_bonus]. Память: [console ? netrun_storage_used(console.inventory.local_store.files) : 0]/[console ? console.inventory.local_store.capacity : storage_capacity].")

/obj/item/netrun_deck/attack_self(mob/user)
	if(world.time < burnt_until)
		to_chat(user, span_warning("[src] не включается."))
		return
	console.ui_interact(user)

/obj/item/netrun_deck/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/netrun_shard))
		console.insert_shard(I, user)
		return TRUE
	return ..()

/obj/item/netrun_deck/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!proximity_flag || world.time < burnt_until)
		return
	var/datum/component/netrun_node/node = netrun_find_node(target)
	if(!node)
		return
	if(console.connection.jack == node)
		console.set_jack(null)
		to_chat(user, span_notice("Вы выдёргиваете кабель из [target]."))
		return
	console.operator = user
	if(console.plug_into(node, user))
		console.ui_interact(user)

/obj/item/netrun_deck/netrun_traced(datum/netrun_console/traced)
	burnt_until = world.time + NETRUN_TRACE_LOCKOUT
	console.set_jack(null)
	do_sparks(3, TRUE, src)
	var/mob/living/holder = loc
	if(istype(holder))
		to_chat(holder, span_danger("[src] искрит и обжигает пальцы!"))
		holder.adjustFireLoss(5)
	SStgui.close_uis(console)

/obj/item/netrun_deck/advanced
	name = "military cyberdeck"
	desc = "Деку в армированном корпусе явно делали не для бухгалтерии. Больше памяти, шире буфер."
	icon_state = "hand_tele"
	color = "#7fbfff"
	buffer_bonus = 1
	storage_capacity = 16 * NETRUN_STORAGE_SCALE

// MARK: Нейролинк

/// Имплант подключения сознания к сети через близкий узел.
/obj/item/organ/cyberimp/brain/netlink
	name = "neural netlink implant"
	desc = "Нейроинтерфейс с коротким сервисным кабелем. Позволяет выбрать близкий узел и погрузить сознание в сеть; для работы в сети необходимо погрузиться."
	icon_state = "brain_implant"
	implant_color = "#4a9eff"
	slot = "brain_netlink"
	actions_types = list(/datum/action/item_action/organ_action/netrun_console, /datum/action/item_action/organ_action/netrun_dive)
	var/datum/netrun_console/implant/console

/obj/item/organ/cyberimp/brain/netlink/Initialize(mapload)
	. = ..()
	console = new(src, NETRUN_ORIGIN_IMPLANT)
	console.connection.wireless = TRUE
	console.inventory.local_store.capacity = 6 * NETRUN_STORAGE_SCALE
	console.state_override = GLOB.conscious_state
	console.tgui_title = "Нейролинк"
	AddComponent(/datum/component/netrun_access_device, console, NETRUN_NODE_IMPLANT)

/obj/item/organ/cyberimp/brain/netlink/Destroy()
	console?.disconnect_client(TRUE)
	QDEL_NULL(console)
	return ..()

/obj/item/organ/cyberimp/brain/netlink/Remove(special = FALSE)
	if(console)
		console.disconnect_client(TRUE)
		console.operator = null
	. = ..()
	var/datum/component/netrun_node/node = GetComponent(/datum/component/netrun_node)
	node?.refresh_physical_host()

/obj/item/organ/cyberimp/brain/netlink/ui_action_click(mob/user, actiontype)
	if(!owner || owner != user)
		return
	if(istype(actiontype, /datum/action/item_action/organ_action/netrun_dive) || ispath(actiontype, /datum/action/item_action/organ_action/netrun_dive))
		try_dive()
		return
	console.ui_interact(owner)

/obj/item/organ/cyberimp/brain/netlink/proc/try_dive(datum/component/netrun_node/node)
	var/mob/living/carbon/diver = owner
	if(!diver || !console)
		return FALSE
	console.operator = diver
	node = node || console.selected_node()
	var/reason = console.dive_denial(node, diver)
	if(reason)
		console.log_line(reason, "bad")
		to_chat(diver, span_warning(reason))
		return FALSE
	console.diving = TRUE
	to_chat(diver, span_notice("Вы закрываете глаза и проваливаетесь в сеть..."))
	var/ready = do_after(diver, 3 SECONDS, target = diver)
	if(QDELETED(src) || QDELETED(console))
		return FALSE
	console.diving = FALSE
	if(!ready || owner != diver || console.dive_denial(node, diver))
		return FALSE
	return complete_dive(node, diver)

/// Keep the final admission and mind transfer atomic after the interruptible preparation.
/obj/item/organ/cyberimp/brain/netlink/proc/complete_dive(datum/component/netrun_node/node, mob/living/carbon/diver)
	if(owner != diver || !console || console.dive_denial(node, diver))
		return FALSE
	var/mob/camera/netrun_entity/entity = netrun_start_dive(diver, node)
	if(entity)
		console.dive_ref = WEAKREF(entity)
		entity.dive_link.bind_client(console, console.connection.jack)
		if(QDELETED(entity))
			return FALSE
		console.stop_watch()
		for(var/datum/component/netrun_node/listened_node as anything in console.listening.Copy())
			listened_node.stop_listening(console)
		SStgui.close_uis(console)
		return TRUE
	return FALSE

/obj/item/organ/cyberimp/brain/netlink/netrun_traced(datum/netrun_console/traced)
	if(!owner)
		return
	to_chat(owner, span_userdanger("Ответный импульс системы защиты прошивает нейролинк!"))
	owner.adjustOrganLoss(ORGAN_SLOT_BRAIN, 15)
	owner.Paralyze(4 SECONDS)
	owner.emote("scream")
	SStgui.close_uis(console)

/datum/action/item_action/organ_action/netrun_console
	name = "Настроить нейролинк"
	desc = "Выбрать узел погружения и настроить подключение."

/datum/action/item_action/organ_action/netrun_dive
	name = "Погружение"
	desc = "Оставить тело и уйти в выбранный узел сети."
