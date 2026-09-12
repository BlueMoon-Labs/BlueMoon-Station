// Сумки хранения, БоХ/BoH и их инертные версии

/obj/item/storage/backpack/holding
	name = "bag of holding"
	desc = "Рюкзак с доступом в карманное блюспейс-пространство."
	icon_state = "holdingpack"
	item_state = "holdingpack"
	resistance_flags = FIRE_PROOF
	item_flags = NO_MAT_REDEMPTION
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 60, ACID = 50)
	component_type = /datum/component/storage/concrete/bluespace/bag_of_holding
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE
	verb_say = "states"
	var/depleted_core = FALSE
	var/second_chance = TRUE

/obj/item/storage/backpack/holding/satchel
	name = "satchel of holding"
	desc = "Поясной ранец с доступом в карманное блюспейс-пространство."
	icon_state = "holdingsat"
	item_state = "holdingsat"

/obj/item/storage/backpack/holding/duffel
	name = "duffel bag of holding"
	desc = "Сумка с доступом в карманное блюспейс-пространство."
	icon_state = "holdingduffel"
	item_state = "holdingduffel"

/obj/item/storage/backpack/holding/examine()
	. = ..()
	var/stability = round(obj_integrity/max_integrity, 0.01) * 100
	. += span_info("Стабильность ядра: [stability]%. [span_tooltip_fast("Можно рекалибровать на твёрдой поверхности нейтрализатором аномалий")]")

/obj/item/storage/backpack/holding/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = MAX_WEIGHT_CLASS_BAG_OF_HOLDING
	STR.storage_flags = STORAGE_FLAGS_VOLUME_DEFAULT
	STR.max_volume = STORAGE_VOLUME_BAG_OF_HOLDING

/obj/item/storage/backpack/holding/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] влезает внутрь [src]! Похоже, что [user.ru_who()] пытается исчезнуть навсегда!"))
	user.dropItemToGround(src, TRUE)
	user.Stun(100, ignore_canstun = TRUE)
	sleep(2 SECONDS)
	playsound(src, "rustle", 50, 1, -5)
	qdel(user)
	return

/obj/item/storage/backpack/holding/singularity_act(current_size)
	var/dist = max((current_size - 2),1)
	explosion(src.loc,(dist),(dist*2),(dist*4))
	return

/obj/item/storage/backpack/holding/proc/teleport_damage(tele_damage, force_destruction = FALSE)
	obj_integrity = max(0, obj_integrity - tele_damage)
	var/stability = round(obj_integrity/max_integrity, 0.01) * 100
	if(stability == 0 && second_chance && !force_destruction)
		second_chance = FALSE
		obj_integrity = max_integrity * 0.01
		stability = 1

	switch(stability)
		if(0)
			say("Внимание, стабильность конструкции изменена и составляет 0%. Разрушение оболочки неизбежно.")
			SEND_SIGNAL(src, COMSIG_TRY_STORAGE_QUICK_EMPTY)
			if(!depleted_core)
				new /obj/effect/anomaly/bluespace(get_turf(src))
			else
				for(var/mob/living/affected_mob in range(4, src))
					if(QDELETED(affected_mob))
						continue
					do_teleport(affected_mob, get_turf(affected_mob), 6, channel = TELEPORT_CHANNEL_BLUESPACE)
			qdel(src)
		if(1 to 25)
			say("Внимание, стабильность конструкции изменена и составляет [stability]%. Требуется срочная рекалибровка.")
		if(26 to 50)
			say("Cтабильность конструкции изменена и составляет [stability]%. Крайне рекомендуется рекалибровка.")
		if(51 to 75)
			say("Cтабильность конструкции изменена и составляет [stability]%. Рекомендуется рекалибровка.")
		if(76 to 100)
			say("Cтабильность конструкции изменена и составляет [stability]%.")

/obj/item/storage/backpack/holding/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/anomaly_neutralizer) && loc != user && !(user.a_intent == INTENT_HELP))
		if(INTERACTING_WITH(user, src))
			return
		to_chat(user, span_notice("Вы начинаете рекалибровку [src] при помощи [I]."))
		if(do_after(user, 20 SECONDS, src))
			to_chat(user, span_notice("Электроника [I] сгорает после процесса рекалибрации [src]!"))
			obj_integrity = max_integrity
			say("Рекалибровка конструкции завершена. Целостность составляет 100%.")
			qdel(I)
			return

	return ..()

////////////////////////////////////////////////////////////////

/obj/item/BoH_inert
	name = "inert bag of nothing"
	desc = "В нынешнем состоянии – габаритный кусок металла со слотом, готовым принять ядро блюспейс-аномалии."
	icon = 'modular_bluemoon/phenyamomota/code/modules/holdingfashion_port/icons/items.dmi'
	icon_state = "bag-inert"
	var/backpack_type = /obj/item/storage/backpack/holding

/obj/item/BoH_inert/attackby(obj/item/I, mob/living/user, params)
	. = ..()
	if(I.type == /obj/item/assembly/signaler/anomaly/bluespace && !(user.a_intent == INTENT_HARM))
		if(item_flags & IN_STORAGE)
			to_chat(user, span_danger("Я не смогу вставить ядро, пока [src.name] лежит внутри чего-то!"))
			return
		if(INTERACTING_WITH(user, src))
			return

		to_chat(user, span_notice("Вы начинаете вставлять [I] в [src]."))
		if(!do_after(user, 3 SECONDS, src))
			return
		if(!user.temporarilyRemoveItemFromInventory(src))
			to_chat(user, span_danger("Я не смогу вставить ядро, пока [src] прилипло к моей руке!"))
			return

		var/obj/item/storage/backpack/holding/created_boh = new backpack_type(get_turf(loc))
		// Рассчёт штрафа к ёмкости БоХа, если мы используем повреждённое ядро
		var/core_max_integrity = I.max_integrity
		var/core_integrity = I.obj_integrity
		if(core_max_integrity && core_integrity < core_max_integrity) // Первая проверка защита от 0/null, дельнейшее деление на ноль нам не нужно
			var/core_integrity_percentage = 100 * core_integrity / core_max_integrity
			if(core_integrity_percentage < 80)
				created_boh.depleted_core = TRUE

		qdel(I)
		qdel(src)
		user.put_in_hands(created_boh)

/obj/item/BoH_inert/bag
	name = "inert bag of holding"
	backpack_type = /obj/item/storage/backpack/holding

/obj/item/BoH_inert/satchel
	name = "inert satchel of holding"
	icon_state = "satchel-inert"
	backpack_type = /obj/item/storage/backpack/holding/satchel

/obj/item/BoH_inert/duffel
	name = "inert duffel bag of holding"
	icon_state = "duff-inert"
	backpack_type = /obj/item/storage/backpack/holding/duffel
