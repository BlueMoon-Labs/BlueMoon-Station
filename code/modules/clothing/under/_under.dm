/obj/item/clothing/under
	icon = 'icons/obj/clothing/uniforms.dmi'
	name = "under"
	body_parts_covered = CHEST|GROIN|LEGS|ARMS
	permeability_coefficient = 0.9
	block_priority = BLOCK_PRIORITY_UNIFORM
	slot_flags = ITEM_SLOT_ICLOTHING
	armor = list(MELEE = 0, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0, WOUND = 5)
	equip_sound = 'sound/items/equip/jumpsuit_equip.ogg'
	drop_sound = 'sound/items/handling/cloth_drop.ogg'
	pickup_sound = 'sound/items/handling/cloth_pickup.ogg'
	mutantrace_variation = STYLE_DIGITIGRADE|USE_TAUR_CLIP_MASK
	limb_integrity = 120
	var/fitted = FEMALE_UNIFORM_FULL // For use in alternate clothing styles for women
	var/has_sensor = HAS_SENSORS // For the crew computer
	var/sensor_flags = SENSOR_RANDOM
	var/sensor_mode = NO_SENSORS
	var/sensor_mode_intended = NO_SENSORS //if sensors become damaged and are repaired later, it will revert to the user's intended preferences
	var/sensormaxintegrity = 200 //if this is zero, then our sensors can only be destroyed by shredded clothing
	var/sensordamage = 0 //how much damage did our sensors take?
	var/can_adjust = TRUE
	var/adjusted = NORMAL_STYLE
	var/alt_covers_chest = FALSE // for adjusted/rolled-down jumpsuits, FALSE = exposes chest and arms, TRUE = exposes arms only
	var/dummy_thick = FALSE // is able to hold accessories on its item
	//SANDSTORM EDIT - Removed the old attached accessory system. We use a list of accessories instead.
	var/max_accessories = 7 // BLUEMOON EDIT - расширено возможное количество аксессуаров с 3 до 7
	var/max_restricted_accessories = 3 // BLUEMOON ADD - максимальное количество особых (боевых) аксессуаров
	var/list/obj/item/clothing/accessory/attached_accessories = list()
	var/list/mutable_appearance/accessory_overlays = list()
	//SANDSTORM EDIT END

/obj/item/clothing/under/worn_overlays(isinhands = FALSE, icon_file, used_state, style_flags = NONE)
	. = ..()
	if(isinhands)
		return
	if(damaged_clothes)
		. += mutable_appearance('icons/effects/item_damage.dmi', "damageduniform")
	if(blood_DNA)
		. += mutable_appearance('icons/effects/blood.dmi', "uniformblood", color = blood_DNA_to_color(), blend_mode = blood_DNA_to_blend())
	if(length(accessory_overlays))
		. += accessory_overlays

/obj/item/clothing/under/attackby(obj/item/I, mob/user, params)
	if((sensordamage || (has_sensor < HAS_SENSORS && has_sensor != NO_SENSORS)) && istype(I, /obj/item/stack/cable_coil))
		if(current_equipped_slot && (current_equipped_slot in user.check_obscured_slots()))
			to_chat(user, "<span class='warning'>You are unable to repair [src] sensors while wearing other garments over it!</span>")
			return
		if(damaged_clothes == CLOTHING_SHREDDED)
			to_chat(user,"<span class='warning'>[src] is too damaged to have its suit sensors repaired! Repair it first.</span>")
			return FALSE
		var/obj/item/stack/cable_coil/C = I
		I.use_tool(src, user, 0, 1)
		has_sensor = HAS_SENSORS
		sensordamage = 0
		sensor_mode = sensor_mode_intended
		to_chat(user,"<span class='notice'>You repair the suit sensors on [src] with [C].</span>")
		return TRUE

	if(!attach_accessory(I, user))
		return ..()

/obj/item/clothing/under/take_damage_zone(def_zone, damage_amount, damage_type, armour_penetration)
	..()
	if(sensormaxintegrity == 0 || has_sensor == NO_SENSORS || sensordamage >= sensormaxintegrity) return //sensors are invincible if max integrity is 0
	var/mob/living/carbon/human/H = src.loc
	if(istype(H) && clothing_protected(H, def_zone, damage_type))
		return
	var/damage_dealt = take_damage(damage_amount * 0.1, damage_type, armour_penetration, FALSE) * 10 // only deal 10% of the damage to the general integrity damage, then multiply it by 10 so we know how much to deal to limb
	sensordamage += damage_dealt
	var/integ = has_sensor
	var/newinteg = sensorintegrity()
	if(newinteg != integ)
		if(newinteg < integ && iscarbon(src.loc)) //the first check is to see if for some inexplicable reason the attack healed our suit sensors
			var/mob/living/carbon/C = src.loc
			switch(newinteg)
				if(DAMAGED_SENSORS_VITALS)
					to_chat(C,"<span class='warning'>Your tracking beacon on your suit sensors have shorted out!</span>")
				if(DAMAGED_SENSORS_LIVING)
					to_chat(C,"<span class='warning'>Your vital tracker on your suit sensors have shorted out!</span>")
				if(BROKEN_SENSORS)
					to_chat(C,"<span class='userdanger'>Your suit sensors have shorted out completely!</span>")
		updatesensorintegrity(newinteg)


/obj/item/clothing/under/proc/sensorintegrity()
	var/percentage = sensordamage/sensormaxintegrity //calculate the percentage of how much damage taken
	if(percentage < SENSOR_INTEGRITY_COORDS) return HAS_SENSORS
	else if(percentage < SENSOR_INTEGRITY_VITALS) return DAMAGED_SENSORS_VITALS
	else if(percentage < SENSOR_INTEGRITY_BINARY) return DAMAGED_SENSORS_LIVING
	else return BROKEN_SENSORS

/obj/item/clothing/under/proc/updatesensorintegrity(integ = HAS_SENSORS)
	if(sensormaxintegrity == 0 || has_sensor == NO_SENSORS) return //sanity check
	has_sensor = integ
	switch(has_sensor)
		if(HAS_SENSORS)
			sensor_mode = sensor_mode_intended
		if(DAMAGED_SENSORS_VITALS)
			if(sensor_mode > SENSOR_VITALS) sensor_mode = SENSOR_VITALS
		if(DAMAGED_SENSORS_LIVING)
			if(sensor_mode > SENSOR_LIVING) sensor_mode = SENSOR_LIVING
		if(BROKEN_SENSORS)
			sensor_mode = NO_SENSORS

/// Прок проверяет закрытую часть тела на предмет одежды (Включая слои, униформа + костюм; шлем + противогаз)
/// После этого производится проверка на броню. Если найденный armor лазера у носимой одежды больше 25, то униформа не повредится
/obj/item/clothing/under/proc/clothing_protected(mob/living/carbon/human/H, def_zone, damage_type)
	var/list/clothing_armor = list(H.w_uniform, H.wear_suit, H.gloves, H.shoes)
	for(var/obj/item/clothing/clothing_piece in clothing_armor)
		if(!clothing_piece || !((clothing_piece.body_parts_covered & zone2body_parts_covered_complicated(def_zone)))) // Нет одежды? Не проверяем. Одежда не покрывает часть тела? Не проверяем.
			continue
		var/protection = clothing_piece.get_armor_rating(LASER)
		if(protection >= 25)
			return TRUE

	return FALSE


/obj/item/clothing/under/update_clothes_damaged_state()
	..()
	if(ismob(loc))
		var/mob/M = loc
		M.update_inv_w_uniform()
	if(has_sensor > NO_SENSORS && damaged_clothes == CLOTHING_SHREDDED)
		has_sensor = BROKEN_SENSORS
		sensordamage = sensormaxintegrity

/obj/item/clothing/under/New()
	if(sensor_flags & SENSOR_RANDOM)
		//make the sensor mode favor higher levels, except coords.
		sensor_mode = pick(SENSOR_OFF, SENSOR_LIVING, SENSOR_LIVING, SENSOR_VITALS, SENSOR_VITALS, SENSOR_VITALS, SENSOR_COORDS, SENSOR_COORDS)
	sensor_mode_intended = sensor_mode
	..()

/obj/item/clothing/under/Initialize(mapload)
	. = ..()
	register_context()

/obj/item/clothing/under/equipped(mob/user, slot)
	..()
	if(adjusted)
		adjusted = NORMAL_STYLE
		fitted = initial(fitted)
		if(!alt_covers_chest)
			body_parts_covered |= CHEST

	// Sandstorm edit
	for(var/obj/item/clothing/accessory/attached_accessory in attached_accessories)
		if(attached_accessory && slot != ITEM_SLOT_HANDS && ishuman(user))
			var/mob/living/carbon/human/H = user
			attached_accessory.on_uniform_equip(src, user)
			if(attached_accessory.above_suit)
				H.update_inv_wear_suit()
	//

/obj/item/clothing/under/dropped(mob/user)
	// Sandstorm edit
	for(var/obj/item/clothing/accessory/attached_accessory in attached_accessories)
		attached_accessory.on_uniform_dropped(src, user)
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			if(attached_accessory.above_suit)
				H.update_inv_wear_suit()
	//
	..()


/obj/item/clothing/under/attach_accessory(obj/item/I, mob/user, notifyAttach = TRUE)
	. = FALSE
	if(istype(I, /obj/item/clothing/accessory) && !istype(I, /obj/item/clothing/accessory/ring))
		var/obj/item/clothing/accessory/A = I
		// BLUEMOON EDIT START - изменение аксессуаров
		// Проверка на общее количество
		if(length(attached_accessories) >= max_accessories)
			if(user)
				to_chat(user, "<span class='warning'>[src] уже имеет [length(attached_accessories)] аксессуаров.</span>")
			return
		// Проверка на количество особых / боевых
		if(A.restricted_accessory && length(attached_accessories))
			var/restricted_accesories_count = 0
			for(var/obj/item/clothing/accessory/already_attached in attached_accessories)
				if(already_attached.restricted_accessory)
					restricted_accesories_count++
			if(restricted_accesories_count >= max_restricted_accessories)
				if(user)
					to_chat(user, "<span class='warning'> К [src] некуда прикреплять очередной боевой аксессуар, на ней их уже [restricted_accesories_count]</span>")
				return
		// Проверка на максимальное количество аксессуаров одного вида
		if(A.max_stack != -1 && length(attached_accessories))
			var/similar_accessory_count = 0
			for(var/obj/item/clothing/accessory/already_attached in attached_accessories)
				if(already_attached.max_stack == -1)
					continue
				// У обоих аксессуаров может быть указан родительский класс, все дочерние классы которого не могут стакаться
				// друг с другом без ограничений
				if(already_attached.max_stack_path && A.max_stack_path)
					if(already_attached.max_stack_path == A.max_stack_path)
						similar_accessory_count++
				// Если не указан, проверяем, чтобы оба предмета не были дочерними классами друг друга
				else if(istype(A, already_attached.type) || istype(already_attached.type, A))
					similar_accessory_count++
			if(similar_accessory_count >= A.max_stack)
				if(user)
					to_chat(user, "<span class='warning'> На [src] уже слишком много похожих на [A] аксессуаров!</span>")
				return
		// BLUEMOON EDIT END

		if(dummy_thick)
			if(user)
				to_chat(user, "<span class='warning'>[src] слишком громоздкое, к нему нельзя крепить аксессуары!</span>")
			return
		else
			if(user && !user.temporarilyRemoveItemFromInventory(I))
				return
			if(!A.attach(src, user))
				return

			if(user && notifyAttach)
				to_chat(user, "<span class='notice'>Вы прикрепили [I] к [src].</span>")

			if((flags_inv & HIDEACCESSORY) || (A.flags_inv & HIDEACCESSORY))
				return TRUE

			//SANDSTORM EDIT
			accessory_overlays = list(mutable_appearance('icons/mob/clothing/accessories.dmi', "blank"))
			for(var/obj/item/clothing/accessory/attached_accessory in attached_accessories)
				var/datum/element/polychromic/polychromic = LAZYACCESS(attached_accessory.comp_lookup, "item_worn_overlays")
				if(!polychromic)
					var/mutable_appearance/accessory_overlay = mutable_appearance(attached_accessory.mob_overlay_icon, attached_accessory.item_state || attached_accessory.icon_state, -UNIFORM_LAYER)
					accessory_overlay.alpha = attached_accessory.alpha
					accessory_overlay.color = attached_accessory.color
					accessory_overlays += accessory_overlay
				else
					polychromic.apply_worn_overlays(attached_accessory, FALSE, attached_accessory.mob_overlay_icon, attached_accessory.item_state || attached_accessory.icon_state, NONE, accessory_overlays)
			//SANDSTORM EDIT END

			if(ishuman(loc))
				var/mob/living/carbon/human/H = loc
				H.update_inv_w_uniform()
				H.update_inv_wear_suit()

			return TRUE

/obj/item/clothing/under/proc/remove_accessory(mob/user)
	if(!isliving(user))
		return
	if(!can_use(user))
		return

	//SKYRAT EDIT
	if(length(attached_accessories))
		var/obj/item/clothing/accessory/A = attached_accessories[length(attached_accessories)]
	//SKYRAT EDIT END
		A.detach(src, user)
		if(user.put_in_hands(A))
			to_chat(user, "<span class='notice'>Вы открепили [A] от [src].</span>")
		else
			to_chat(user, "<span class='notice'>Вы открепили [A] от [src] с падением предмета на пол.</span>")

		if(ishuman(loc))
			var/mob/living/carbon/human/H = loc
			H.update_inv_w_uniform()
			H.update_inv_wear_suit()


/obj/item/clothing/under/examine(mob/user)
	. = ..()
	if(can_adjust)
		if(adjusted == ALT_STYLE)
			. += "Alt-click для нормального стиля ношения."
		else
			. += "Alt-click для повседневного стиля ношения."
	switch(has_sensor)
		if(BROKEN_SENSORS)
			. += "<span class='warning'>Сенсоры полностью вышли из строя. Их можно починить кабелем.</span>"
		if(DAMAGED_SENSORS_LIVING)
			. += "<span class='warning'>Сенсоры и маячок слежения повреждены, и не передают информацию. Это можно исправить кабелем.</span>"
		if(DAMAGED_SENSORS_VITALS)
			. += "<span class='warning'>Маячок слежения повреждён, невозможно отслеживать локацию владельца. Это можно исправить кабелем</span>"
	if(has_sensor > NO_SENSORS)
		switch(sensor_mode)
			if(SENSOR_OFF)
				. += "Сенсоры одежды выключены."
			if(SENSOR_LIVING)
				. += "Бинарные сенсоры статуса смерти включены."
			if(SENSOR_VITALS)
				. += "Сенсоры жизненных показателей выключены."
			if(SENSOR_COORDS)
				. += "Сенсоры жизненных показателей и маячок местонахождения включены."
	if(length(attached_accessories))
		for(var/obj/item/clothing/accessory/attached_accessory in attached_accessories)
			. += "\A [attached_accessory] находится на униформе."
	//SKYRAT EDIT END

/obj/item/clothing/under/verb/toggle()
	set name = "Adjust Suit Sensors"
	set category = "Object"
	set src in usr
	var/mob/M = usr
	if (istype(M, /mob/dead/))
		return
	if (!can_use(M))
		return
	if(src.has_sensor == BROKEN_SENSORS)
		to_chat(usr, "Сенсоры вышли из строя!")
		return FALSE
	if(src.sensor_flags & SENSOR_LOCKED)
		to_chat(usr, "Настройки заблокированы.")
		return FALSE
	if(src.has_sensor <= NO_SENSORS)
		to_chat(usr, "На униформе нет сенсоров.")
		return FALSE

	var/list/modes = list("Off", "Binary vitals", "Exact vitals", "Tracking beacon")
	var/switchMode = input("Выберите режим сенсоров:", "Режим сенсоров униформы", modes[sensor_mode + 1]) in modes
	if(get_dist(usr, src) > 1)
		to_chat(usr, "<span class='warning'>Вы отошли слишком далеко!</span>")
		return
	sensor_mode_intended = modes.Find(switchMode) - 1

	if (src.loc == usr)
		switch(sensor_mode_intended)
			if(0)
				to_chat(usr, "<span class='notice'>Вы отключили сенсорное оборудование вашей униформы.</span>")
				sensor_mode = sensor_mode_intended
			if(1)
				to_chat(usr, "<span class='notice'>Ваша униформа будет сообщать только смерть своего владельца.</span>")
				sensor_mode = sensor_mode_intended
			if(2)
				if(src.has_sensor == DAMAGED_SENSORS_LIVING)
					to_chat(usr, "<span class='warning'>Сенсоры вашей униформы сломались. Сообщается только смерть владельца.</span>")
					sensor_mode = SENSOR_LIVING
				else
					to_chat(usr, "<span class='notice'>Ваша униформа будет отслеживать точное состояние жизненных показателей.</span>")
					sensor_mode = sensor_mode_intended
			if(3)
				switch(src.has_sensor)
					if(DAMAGED_SENSORS_LIVING)
						to_chat(usr, "<span class='warning'>Сенсоры и маячок слежения вашей униформы сломались. Сообщается только смерть владельца.</span>")
						sensor_mode = SENSOR_LIVING
					if(DAMAGED_SENSORS_VITALS)
						to_chat(usr, "<span class='warning'>Маячок слежения вашей униформы сломался. Сообщается только состояние жизненных показателей.</span>")
						sensor_mode = SENSOR_VITALS
					if(HAS_SENSORS)
						to_chat(usr, "<span class='notice'>Ваша униформа теперь сообщает точное состояние жизненных показателей и координатную позицию.</span>")
						sensor_mode = sensor_mode_intended

	if(ishuman(loc))
		var/mob/living/carbon/human/H = loc
		if(H.w_uniform == src)
			H.update_suit_sensors()


/obj/item/clothing/under/CtrlClick(mob/user)
	. = ..()

	if (!(item_flags & IN_INVENTORY))
		return

	if(!isliving(user) || !user.canUseTopic(src, BE_CLOSE, ismonkey(user)))
		return

	if(src.has_sensor == BROKEN_SENSORS)
		to_chat(usr, "Сенсоры вышли из строя!")
		return FALSE
	if(src.sensor_flags & SENSOR_LOCKED)
		to_chat(usr, "Настройки заблокированы.")
		return FALSE
	if(has_sensor <= NO_SENSORS)
		to_chat(usr, "На униформе нет сенсоров.")
		return

	sensor_mode_intended = SENSOR_COORDS

	switch(src.has_sensor)
		if(DAMAGED_SENSORS_LIVING)
			to_chat(usr, "<span class='warning'>Сенсоры и маячок слежения вашей униформы сломались. Сообщается только смерть владельца.</span>")
			sensor_mode = SENSOR_LIVING
		if(DAMAGED_SENSORS_VITALS)
			to_chat(usr, "<span class='warning'>Маячок слежения вашей униформы сломался. Сообщается только состояние жизненных показателей.</span>")
			sensor_mode = SENSOR_VITALS
		if(HAS_SENSORS)
			to_chat(usr, "<span class='notice'>Ваша униформа теперь сообщает точное состояние жизненных показателей и координатную позицию.</span>")
			sensor_mode = sensor_mode_intended

	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(H.w_uniform == src)
			H.update_suit_sensors()

/obj/item/clothing/under/AltClick(mob/user)
	. = ..()
	if(!istype(user) || !user.canUseTopic(src, BE_CLOSE, ismonkey(user), TRUE, FALSE))
		return
	if(length(attached_accessories)) //SKYRAT EDIT
		remove_accessory(user)
	else
		rolldown()

/obj/item/clothing/under/verb/jumpsuit_adjust()
	set name = "Adjust Jumpsuit Style"
	set category = null
	set src in usr
	rolldown()

/obj/item/clothing/under/proc/rolldown()
	if(!can_use(usr))
		return
	if(toggle_jumpsuit_adjust() && ishuman(usr))
		var/mob/living/carbon/human/H = usr
		H.update_inv_w_uniform()
		H.update_body(TRUE)

/obj/item/clothing/under/proc/toggle_jumpsuit_adjust()
	if(!can_adjust)
		to_chat(usr, "<span class='warning'>Вы не можете как-либо особенно сложить эту одежду!</span>")
		return FALSE
	adjusted = !adjusted

	if(adjusted)
		to_chat(usr, "<span class='notice'>Вы сложили складки одежды для повседневного стиля ношения.</span>")
		if(fitted != FEMALE_UNIFORM_TOP)
			fitted = NO_FEMALE_UNIFORM
		if(!alt_covers_chest) // for the special snowflake suits that expose the chest when adjusted
			body_parts_covered &= ~CHEST
			mutantrace_variation &= ~USE_TAUR_CLIP_MASK //How are we supposed to see the uniform otherwise?
	else
		to_chat(usr, "<span class='notice'>Вы поправили одежду в её привычный вид.</span>")
		fitted = initial(fitted)
		if(!alt_covers_chest)
			body_parts_covered |= CHEST
			if(initial(mutantrace_variation) & USE_TAUR_CLIP_MASK)
				mutantrace_variation |= USE_TAUR_CLIP_MASK

	return TRUE

/obj/item/clothing/under/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()
	if (!(item_flags & IN_INVENTORY))
		return

	if(!isliving(user) || !user.canUseTopic(src, BE_CLOSE, ismonkey(user), TRUE, FALSE))
		return

	LAZYSET(context[SCREENTIP_CONTEXT_CTRL_LMB], INTENT_ANY, "Set to highest sensor")
	if(length(attached_accessories))
		LAZYSET(context[SCREENTIP_CONTEXT_ALT_LMB], INTENT_ANY, "Remove [attached_accessories[length(attached_accessories)]]")
	else
		LAZYSET(context[SCREENTIP_CONTEXT_ALT_LMB], INTENT_ANY, "Adjust [src]")
	return CONTEXTUAL_SCREENTIP_SET

/obj/item/clothing/under/rank
	dying_key = DYE_REGISTRY_UNDER
