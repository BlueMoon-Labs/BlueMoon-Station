/proc/bm_set_admin_spawner_if_metadollar(atom/movable/O, mob/M)
	if(!istype(O, /obj/item/stack/metadollar) || !M?.ckey)
		return
	var/obj/item/stack/metadollar/MD = O
	MD.admin_spawned_by_ckey = M.ckey

/obj/item/stack/metadollar
	name = "metadollar"
	singular_name = "metadollar"
	desc = "Межгалактические казначейские купюры. Зачисление на постоянный счёт: проведите стопкой по КПК или по ID-карте."
	icon = 'icons/obj/economy.dmi'
	icon_state = "metadollar"
	novariants = TRUE
	merge_type = /obj/item/stack/metadollar
	max_amount = INFINITY
	full_w_class = WEIGHT_CLASS_TINY
	amount = 1
	resistance_flags = FLAMMABLE
	var/admin_spawned_by_ckey

/obj/item/stack/metadollar/Initialize(mapload, new_amount, merge = TRUE)
	. = ..()
	update_metadollar_icon()
	if(!mapload)
		addtimer(CALLBACK(src, PROC_REF(bm_log_admin_spawn_if_needed)), 1)

/obj/item/stack/metadollar/proc/bm_log_admin_spawn_if_needed()
	if(QDELETED(src) || !(flags_1 & ADMIN_SPAWNED_1))
		return
	var/who = admin_spawned_by_ckey || "ckey неизвестен (не панель/верб Spawn?)"
	var/msg = "Метадоллары: [who] заспаунил [get_amount()] М$, тип [src.type]."
	send2adminchat("Metadollar", msg)
	log_admin("METADOLLAR ADMIN SPAWN: [msg]")

/obj/item/stack/metadollar/get_item_credit_value()
	return 0

/obj/item/stack/metadollar/update_icon_state()
	update_metadollar_icon()

/obj/item/stack/metadollar/proc/update_metadollar_icon()
	var/n = amount
	if(n <= 0)
		icon_state = "metadollar"
		return
	if(n < 10)
		icon_state = "metadollar"
	else if(n < 20)
		icon_state = "metadollar10"
	else if(n < 50)
		icon_state = "metadollar20"
	else if(n < 100)
		icon_state = "metadollar50"
	else if(n < 200)
		icon_state = "metadollar100"
	else if(n < 500)
		icon_state = "metadollar200"
	else if(n < 1000)
		icon_state = "metadollar500"
	else
		icon_state = "metadollar1000"

/obj/item/stack/metadollar/proc/deposit_to_lobby_prefs(mob/user, atom/source)
	var/client/C = user?.client
	if(!C?.prefs)
		to_chat(user, span_warning("Не удалось связаться с лобби-счётом."))
		return FALSE
	if(amount <= 0)
		return FALSE
	SSmetadollars.add_amount(C, amount, "voucher")
	if(istype(source, /obj/item/pda))
		to_chat(user, span_notice("Казначейский билет был погружён в КПК и растворился на мельчайшие атомы, успешно зачислив метадоллары на ваш счёт."))
	else if(istype(source, /obj/item/card/id))
		to_chat(user, span_notice("Казначейский билет был погружён в ID-карту и растворился на мельчайшие атомы, успешно зачислив метадоллары на ваш счёт."))
	else
		to_chat(user, span_notice("Метадоллары зачислены на ваш счёт."))
	qdel(src)
	return TRUE

/obj/item/stack/metadollar/examine(mob/user)
	. = ..()
	. += span_notice("В стопке <b>[get_amount()]</b> М$. Зачисление: проведите по КПК или по ID-карте.")

/obj/item/stack/metadollar/AltClick(mob/living/user)
	if(!user.canUseTopic(src, BE_CLOSE, TRUE, FALSE) || zero_amount())
		return
	var/max_amt = get_amount()
	var/split_amount = round(input(user, "Сколько метадолларов отделить? (макс.: [max_amt])", "Стопка метадолларов") as null|num)
	if(split_amount == null || split_amount <= 0 || !user.canUseTopic(src, BE_CLOSE, TRUE, FALSE))
		return
	split_amount = min(max_amt, split_amount)
	split_stack(user, split_amount)
	to_chat(user, span_notice("Вы отделяете [split_amount] М$."))

/obj/item/stack/metadollar/fifty
	amount = 50
