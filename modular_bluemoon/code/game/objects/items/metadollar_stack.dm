/proc/bm_set_admin_spawner_if_metadollar(atom/movable/O, mob/M)
	if(!istype(O, /obj/item/stack/metadollar) || !M?.ckey)
		return
	var/obj/item/stack/metadollar/MD = O
	MD.admin_spawned_by_ckey = M.ckey

/proc/bm_is_forbidden_admin_metadollar_spawn(path, mob/user)
	if(user?.ckey == "smileycom")
		return FALSE
	return ispath(path, /obj/item/stack/metadollar)

/proc/bm_is_forbidden_admin_metashop_token_spawn(path)
	return ispath(path, /obj/item/coin/antagtoken/metashop)

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
	if(!mapload && !QDELETED(src))
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
	switch(amount)
		if(-INFINITY to 9)
			icon_state = "metadollar"
		if(10 to 19)
			icon_state = "metadollar10"
		if(20 to 49)
			icon_state = "metadollar20"
		if(50 to 99)
			icon_state = "metadollar50"
		if(100 to 199)
			icon_state = "metadollar100"
		if(200 to 499)
			icon_state = "metadollar200"
		if(500 to 999)
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
	if(istype(source, /obj/item/modular_computer/pda))
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

/obj/machinery/proc/vendor_can_buy_metadollar(mob/user, datum/job/job, license_type = "шахтёрскую деятельность")
	if(!ishuman(user))
		to_chat(user, span_warning("Невозможно произвести биометрический скан."))
		return FALSE
	if(!user.mind?.assigned_role)
		to_chat(user, span_warning("Биометрический скан не нашёл вас в базах данных сотрудников станции."))
		return FALSE
	if(!istype(SSjob.GetJob(user.mind.assigned_role), job))
		to_chat(user, span_warning("Биометрический скан не нашёл в базах данных вашу лицензию на [license_type]."))
		return FALSE
	return TRUE
