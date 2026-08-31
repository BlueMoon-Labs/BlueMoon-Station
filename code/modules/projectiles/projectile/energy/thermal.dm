// Термальные пистолеты: снаряды инферно и крио, а также их "взломанные" эмагом версии.
/obj/item/projectile/energy/inferno
	name = "inferno nanites"
	icon_state = "infernoshot"
	damage = 20
	damage_type = BURN
	flag = ENERGY
	armour_penetration = 10
	is_reflectable = FALSE
	wound_bonus = 0
	bare_wound_bonus = 10
	impact_effect_type = /obj/effect/temp_visual/impact_effect/red_laser

/obj/item/projectile/energy/inferno/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	if(!ishuman(target))
		return

	if(HAS_TRAIT(target, TRAIT_RESISTCOLD))
		return

	var/mob/living/carbon/human/cold_target = target
	var/how_cold_is_target = cold_target.bodytemperature
	var/danger_zone = BODYTEMP_COLD_DAMAGE_LIMIT - 150
	if(how_cold_is_target < danger_zone)
		explosion(cold_target, devastation_range = -1, heavy_impact_range = -1, light_impact_range = 2, flame_range = 3) //лучше отойти подальше
		cold_target.bodytemperature = BODYTEMP_NORMAL //избегаем повторных взрывов, можно заодно и согреться
		playsound(cold_target, 'sound/items/weapons/sear.ogg', 30, TRUE, -1)

/obj/item/projectile/energy/inferno/emagged/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()

	if(isliving(target))
		var/mob/living/living_target = target
		living_target.adjust_wet_stacks(-20)

/obj/item/projectile/energy/cryo
	name = "cryo nanites"
	icon_state = "cryoshot"
	damage = 20
	damage_type = BRUTE
	armour_penetration = 10
	flag = ENERGY
	sharpness = SHARP_POINTY //большущий осколок льда
	is_reflectable = FALSE
	wound_bonus = 0
	bare_wound_bonus = 10

/obj/item/projectile/energy/cryo/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	if(!ishuman(target))
		return

	if(HAS_TRAIT(target, TRAIT_RESISTHEAT))
		return

	var/mob/living/carbon/human/hot_target = target
	var/how_hot_is_target = hot_target.bodytemperature
	var/danger_zone = BODYTEMP_HEAT_DAMAGE_LIMIT + 300
	if(how_hot_is_target > danger_zone)
		hot_target.Knockdown(100)
		hot_target.apply_damage(20, BURN)
		hot_target.bodytemperature = BODYTEMP_NORMAL //избегаем повторных сбиваний с ног, можно заодно и остудиться
		playsound(hot_target, 'sound/items/weapons/sonic_jackhammer.ogg', 30, TRUE, -1)

/obj/item/projectile/energy/cryo/emagged
	var/temperature = -100

/obj/item/projectile/energy/cryo/emagged/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()

	if(iscarbon(target))
		var/mob/living/carbon/hit_mob = target
		var/thermal_protection = 1 - hit_mob.get_insulation_protection(hit_mob.bodytemperature + temperature)

		// Новая температура тела подстраивается под эффект снаряда
		// Снижаем эффект изменения температуры исходя из изоляции, которую носит моб
		hit_mob.adjust_bodytemperature((thermal_protection * temperature) + temperature)

	else if(isliving(target))
		var/mob/living/L = target
		// новая температура тела подстраивается под эффект снаряда
		L.adjust_bodytemperature((1 - blocked) * temperature)

	if(isobj(target))
		var/obj/objectification = target

		if(objectification.reagents)
			var/datum/reagents/reagents = objectification.reagents
			reagents?.expose_temperature(temperature)

// Мокрота: простой счётчик влажности, используемый "взломанным" инферно, чтобы подсушивать цель.
/mob/living
	/// Текущая влажность моба (0 = сухой). Используется "взломанным" инферно-пистолетом.
	var/wet_stacks = 0

/// Подсушивает или намачивает цель.
/mob/living/proc/adjust_wet_stacks(amount)
	wet_stacks = clamp(wet_stacks + amount, 0, 100)

/// Насколько сильно моб защищён от перепада температуры (значение от 0 до 1)
/mob/living/carbon/proc/get_insulation_protection(temperature)
	return 0

/mob/living/carbon/human/get_insulation_protection(temperature)
	var/protection_flags = (temperature > bodytemperature) ? get_heat_protection_flags(temperature) : get_cold_protection_flags(temperature)
	if(!protection_flags)
		return 0
	// считаем защищённые части тела: голова, грудь, пах, ноги, ступни, руки, кисти
	var/protected_parts = 0
	for(var/part in list(HEAD, CHEST, GROIN, LEGS, FEET, ARMS, HANDS))
		if(protection_flags & part)
			protected_parts++
	return protected_parts / 7
