/obj/item/reactive_armour_shell
	name = "reactive armour shell"
	desc = "Экспериментальный комплект брони, ожидающий установки аномального ядра."
	icon_state = "reactiveoff"
	icon = 'icons/obj/clothing/suits.dmi'
	w_class = WEIGHT_CLASS_BULKY

/obj/item/reactive_armour_shell/attackby(obj/item/I, mob/user, params)
	..()
	var/static/list/anomaly_armour_types = list(
		/obj/effect/anomaly/grav	                = /obj/item/clothing/suit/armor/reactive/repulse,
		/obj/effect/anomaly/flux 	           		= /obj/item/clothing/suit/armor/reactive/tesla,
		/obj/effect/anomaly/bluespace 	            = /obj/item/clothing/suit/armor/reactive/teleport,
		/obj/effect/anomaly/dimensional 			= /obj/item/clothing/suit/armor/reactive/barricade,
		/obj/effect/anomaly/ectoplasm 				= /obj/item/clothing/suit/armor/reactive/ectoplasm,
		/obj/effect/anomaly/fog						= /obj/item/clothing/suit/armor/reactive/smoke,
		/obj/effect/anomaly/pyro					= /obj/item/clothing/suit/armor/reactive/fire,
		/obj/effect/anomaly/bhole					= /obj/item/clothing/suit/armor/reactive/stealth,
		)

	if(istype(I, /obj/item/assembly/signaler/anomaly))
		var/obj/item/assembly/signaler/anomaly/A = I
		var/armour_path = anomaly_armour_types[A.anomaly_type]
		if(!armour_path)
			armour_path = /obj/item/clothing/suit/armor/reactive/stealth //Lets not cheat the player if an anomaly type doesnt have its own armour coded
		to_chat(user, "Вы вставляете [A] в нагрудную пластину. Броня тихо гудит, оживая.")
		new armour_path(get_turf(src))
		qdel(src)
		qdel(A)

//Reactive armor
/obj/item/clothing/suit/armor/reactive
	name = "reactive armor"
	desc = "Не похоже, что оно хоть что-то делает."
	var/active = 0
	var/reactivearmor_cooldown_duration = 0 //cooldown specific to reactive armor
	var/reactivearmor_cooldown = 0
	icon_state = "reactiveoff"
	item_state = "reactiveoff"
	blood_overlay_type = "armor"
	armor_type = /datum/armor/fireproof_and_acidproof_misc
	actions_types = list(/datum/action/item_action/toggle)
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE
	var/hit_reaction_chance = 50
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/armor/reactive/attack_self(mob/user)
	active = !(active)
	if(active)
		to_chat(user, span_notice("[src] переходит в активный режим."))
		icon_state = "reactive"
		item_state = "reactive"
	else
		to_chat(user, span_notice("[src] переходит в пассивный режим."))
		icon_state = "reactiveoff"
		item_state = "reactiveoff"
	add_fingerprint(user)
	if(user.get_item_by_slot(ITEM_SLOT_OCLOTHING) == src)
		user.update_inv_wear_suit()

/obj/item/clothing/suit/armor/reactive/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	active = 0
	icon_state = "reactiveoff"
	item_state = "reactiveoff"
	reactivearmor_cooldown = world.time + 200

/obj/item/clothing/suit/armor/reactive/run_block(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	if(!active)
		return BLOCK_NONE
	return block_action(owner, object, damage, attack_text, attack_type, armour_penetration, attacker, def_zone, final_block_chance, block_return)

/obj/item/clothing/suit/armor/reactive/proc/block_action(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	return BLOCK_NONE

//When the wearer gets hit, this armor will teleport the user a short distance away (to safety or to more danger, no one knows. That's the fun of it!)
/obj/item/clothing/suit/armor/reactive/teleport
	name = "reactive teleport armor"
	desc = "Кто-то разлучил нашего Директора Исследований с его головой!"
	var/tele_range = 8
	var/rad_amount = 60
	var/rad_amount_before = 120
	reactivearmor_cooldown_duration = 100

/obj/item/clothing/suit/armor/reactive/teleport/block_action(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	if(prob(hit_reaction_chance))
		var/mob/living/carbon/human/H = owner
		if(world.time < reactivearmor_cooldown)
			owner.visible_message(span_danger("Система реактивной телепортации ещё перезаряжается! Она не может телепортировать [H]!"))
			return
		owner.visible_message(span_danger("Система реактивной телепортации уводит [H] от [attack_text], отключаясь в процессе!"))
		playsound(get_turf(owner), 'sound/magic/blink.ogg', 100, 1)
		var/list/turfs = new
		var/turf/old = get_turf(src)
		for(var/turf/T in orange(tele_range, H))
			if(T.density)
				continue
			if(T.x>world.maxx-tele_range || T.x<tele_range)
				continue
			if(T.y>world.maxy-tele_range || T.y<tele_range)
				continue
			turfs += T
		if(!turfs.len)
			turfs += pick(/turf in orange(tele_range, H))
		var/turf/picked = pick(turfs)
		if(!isturf(picked))
			return
		do_teleport(H, picked, no_effects = TRUE, channel = TELEPORT_CHANNEL_WORMHOLE)
		radiation_pulse(old, rad_amount_before)
		radiation_pulse(src, rad_amount)
		reactivearmor_cooldown = world.time + reactivearmor_cooldown_duration
		block_return[BLOCK_RETURN_REDIRECT_METHOD] = REDIRECT_METHOD_PASSTHROUGH
		return BLOCK_SUCCESS | BLOCK_REDIRECTED | BLOCK_SHOULD_REDIRECT | BLOCK_TARGET_DODGED
	return BLOCK_NONE

//Fire

/obj/item/clothing/suit/armor/reactive/fire
	name = "reactive incendiary armor"
	desc = "Экспериментальный комплект брони с реактивной сенсорной матрицей, подключённой к эмиттеру пламени. Для пироманьяков со стилем."
	reactivearmor_cooldown_duration = 15

/obj/item/clothing/suit/armor/reactive/fire/block_action(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	if(prob(hit_reaction_chance))
		if(world.time < reactivearmor_cooldown)
			owner.visible_message(span_danger("Зажигательная броня на [owner] срабатывает, но не может выпустить пламя – её огненные сопла ещё перезаряжаются!"))
			return
		owner.visible_message(span_danger("[src] блокирует [attack_text], выпуская струи пламени!"))
		playsound(get_turf(owner),'sound/magic/fireball.ogg', 100, 1)
		for(var/mob/living/carbon/C in range(6, owner))
			if(C != owner)
				C.fire_stacks += 8
				C.IgniteMob()
		owner.fire_stacks = -20
		reactivearmor_cooldown = world.time + reactivearmor_cooldown_duration
		return BLOCK_SUCCESS | BLOCK_PHYSICAL_INTERNAL
	return BLOCK_NONE

//Stealth

/obj/item/clothing/suit/armor/reactive/stealth
	name = "reactive stealth armor"
	reactivearmor_cooldown_duration = 65
	desc = "Экспериментальный комплект брони, делающий владельца невидимым при обнаружении угрозы и создающий иллюзию, которая убегает от владельца. Нельзя биться с тем, кого не видишь, верно?"

/obj/item/clothing/suit/armor/reactive/stealth/block_action(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	if(prob(hit_reaction_chance))
		if(world.time < reactivearmor_cooldown)
			owner.visible_message(span_danger("Система невидимости на [owner] срабатывает, но её голографические излучатели ещё перезаряжаются!"))
			return
		var/mob/living/simple_animal/hostile/illusion/escape/E = new(owner.loc)
		E.Copy_Parent(owner, 50)
		E.GiveTarget(owner) //so it starts running right away: контроллер бежит сам
		owner.alpha = 30
		owner.visible_message(span_danger("[attack_text] попадает [owner] в грудь!")) //We pretend to be hit, since blocking it would stop the message otherwise
		spawn(40)
			owner.alpha = initial(owner.alpha)
		reactivearmor_cooldown = world.time + reactivearmor_cooldown_duration
		return BLOCK_SUCCESS | BLOCK_PHYSICAL_INTERNAL
	return BLOCK_NONE

//Tesla

/obj/item/clothing/suit/armor/reactive/tesla
	name = "reactive tesla armor"
	desc = "Экспериментальный комплект брони с чувствительными детекторами, подключёнными к огромной конденсаторной сетке, из которой торчат эмиттеры. Бзз!"
	siemens_coefficient = -1
	reactivearmor_cooldown_duration = 20
	var/zap_power = 25000
	var/zap_range = 20
	var/zap_flags = ZAP_MOB_DAMAGE | ZAP_OBJ_DAMAGE
	var/legacy = FALSE
	var/legacy_dmg = 30

/obj/item/clothing/suit/armor/reactive/tesla/dropped(mob/user)
	..()
	if(istype(user))
		REMOVE_TRAIT(user, TRAIT_TESLA_SHOCKIMMUNE, "reactive_tesla_armor")

/obj/item/clothing/suit/armor/reactive/tesla/equipped(mob/user, slot)
	..()
	if(slot_flags & slot) //Was equipped to a valid slot for this item?
		ADD_TRAIT(user, TRAIT_TESLA_SHOCKIMMUNE, "reactive_tesla_armor")

/obj/item/clothing/suit/armor/reactive/tesla/block_action(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	if(prob(hit_reaction_chance))
		if(world.time < reactivearmor_cooldown)
			var/datum/effect_system/spark_spread/sparks = new /datum/effect_system/spark_spread
			sparks.set_up(1, 1, src)
			sparks.start()
			owner.visible_message(span_danger("Тесла-конденсаторы брони [owner] ещё перезаряжаются!"))
			return
		owner.visible_message(span_danger("[src] блокирует [attack_text], выпуская дуги молний!"))
		if(!legacy)
			tesla_zap(owner, zap_range, zap_power, zap_flags)
		else
			for(var/mob/living/M in view(7, owner))
				if(M == owner)
					continue
				owner.Beam(M,icon_state="purple_lightning",icon='icons/effects/effects.dmi',time=5)
				M.adjustFireLoss(legacy_dmg)
				playsound(M, 'sound/machines/defib_zap.ogg', 50, 1, -1)
		reactivearmor_cooldown = world.time + reactivearmor_cooldown_duration
		return BLOCK_SUCCESS | BLOCK_PHYSICAL_INTERNAL
	return NONE

//Repulse

/obj/item/clothing/suit/armor/reactive/repulse
	name = "reactive repulse armor"
	reactivearmor_cooldown_duration = 20
	desc = "Экспериментальный комплект брони, разбрасывающий нападающих по сторонам."

/obj/item/clothing/suit/armor/reactive/repulse/block_action(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	if(prob(hit_reaction_chance))
		if(world.time < reactivearmor_cooldown)
			owner.visible_message(span_danger("Репульсионный генератор ещё перезаряжается!"))
			return FALSE
		playsound(get_turf(owner),'sound/magic/repulse.ogg', 100, 1)
		owner.visible_message(span_danger("[src] блокирует [attack_text], преобразуя атаку в волну силы!"))
		var/turf/T = get_turf(owner)
		var/list/cachedrange = range(T, 7) - owner
		var/safety = 50
		var/list/to_throw = list()
		for(var/mob/living/L in cachedrange)
			if(L.move_resist > MOVE_FORCE_EXTREMELY_STRONG)
				continue
			to_throw += L
		for(var/obj/O in cachedrange)
			if(O.anchored)
				continue
			to_throw += O
		for(var/i in to_throw)
			if(!safety)
				break
			var/atom/movable/AM = i
			var/throwtarget = get_edge_target_turf(T, get_dir(T, get_step_away(AM, T)))
			AM.throw_at(throwtarget,10,1)
			safety--
		reactivearmor_cooldown = world.time + reactivearmor_cooldown_duration
		return BLOCK_SUCCESS | BLOCK_PHYSICAL_INTERNAL
	return BLOCK_NONE

/obj/item/clothing/suit/armor/reactive/table
	name = "reactive table armor"
	reactivearmor_cooldown_duration = 0
	desc = "Если не можешь победить мемы – возглавь их."
	var/tele_range = 10

/obj/item/clothing/suit/armor/reactive/table/block_action(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	if(prob(hit_reaction_chance))
		var/mob/living/carbon/human/H = owner
		if(world.time < reactivearmor_cooldown)
			owner.visible_message(span_danger("Фабрикаторы реактивной стол-брони ещё перезаряжаются!"))
			return
		owner.visible_message(span_danger("Система реактивной телепортации уводит [H] от [attack_text] и впечатывает в созданный стол!"))
		owner.visible_message("<font color='red' size='3'>[H] ОКАЗЫВАЕТСЯ НА СТОЛЕ!!!</font>")
		owner.DefaultCombatKnockdown(40)
		var/list/turfs = new/list()
		for(var/turf/T in orange(tele_range, H))
			if(T.density)
				continue
			if(T.x>world.maxx-tele_range || T.x<tele_range)
				continue
			if(T.y>world.maxy-tele_range || T.y<tele_range)
				continue
			turfs += T
		if(!turfs.len)
			turfs += pick(/turf in orange(tele_range, H))
		var/turf/picked = pick(turfs)
		if(!isturf(picked))
			return
		H.forceMove(picked)
		new /obj/structure/table(get_turf(owner))
		reactivearmor_cooldown = world.time + reactivearmor_cooldown_duration
		return BLOCK_SUCCESS | BLOCK_PHYSICAL_INTERNAL
	return BLOCK_NONE

/obj/item/clothing/suit/armor/reactive/table/emp_act()
	return

// When the wearer gets hit, this armor will push people nearby and spawn some blocking objects.
/obj/item/clothing/suit/armor/reactive/barricade
	name = "reactive barricade armor"
	desc = "Экспериментальный комплект брони, создающий аномальные барьеры, когда обнаруживает опасность для своего владельца."
	reactivearmor_cooldown_duration = 10 SECONDS

/obj/item/clothing/suit/armor/reactive/barricade/block_action(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	if(world.time < reactivearmor_cooldown)
		return BLOCK_NONE
	playsound(get_turf(owner),'sound/magic/repulse.ogg', 100, TRUE)
	owner.visible_message(span_danger("Реактивная броня помещает аномальную материю между [src] и [attack_text]!"))
	for (var/atom/movable/target in repulse_targets(owner))
		repulse(target, owner)

	var/datum/armour_dimensional_theme/theme = new()
	theme.apply_random(get_turf(owner), dangerous = FALSE)
	qdel(theme)

	reactivearmor_cooldown = world.time + reactivearmor_cooldown_duration
	return BLOCK_SUCCESS | BLOCK_PHYSICAL_INTERNAL

/**
 * Returns a list of all atoms around the source which can be moved away from it.
 *
 * Arguments
 * * source - Thing to try to move things away from.
 */
/obj/item/clothing/suit/armor/reactive/barricade/proc/repulse_targets(atom/source)
	var/list/push_targets = list()
	for (var/atom/movable/nearby_movable in view(1, source))
		if(nearby_movable == source)
			continue
		if(nearby_movable.anchored)
			continue
		push_targets += nearby_movable
	return push_targets

/**
 * Pushes something one tile away from the source.
 *
 * Arguments
 * * victim - Thing being moved.
 * * source - Thing to move it away from.
 */
/obj/item/clothing/suit/armor/reactive/barricade/proc/repulse(atom/movable/victim, atom/source)
	var/dist_from_caster = get_dist(victim, source)

	if(dist_from_caster == 0)
		return

	if (isliving(victim))
		to_chat(victim, span_userdanger("Вас отбрасывает волной давления!"))
	var/turf/throwtarget = get_edge_target_turf(source, get_dir(source, get_step_away(victim, source, 1)))
	victim.safe_throw_at(throwtarget, 1, 1, source)

/obj/item/clothing/suit/armor/reactive/barricade/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	visible_message(span_danger("Реактивная броня выталкивает материю из нестабильного измерения!"))
	var/datum/armour_dimensional_theme/theme = new()
	theme.apply_random(get_turf(src), dangerous = TRUE)
	qdel(theme)

/obj/item/clothing/suit/armor/reactive/ectoplasm
	name = "reactive possession armor"
	desc = "Экспериментальный комплект брони, делающий одержимыми находящиеся рядом предметы."
	reactivearmor_cooldown_duration = 40 SECONDS

/obj/item/clothing/suit/armor/reactive/ectoplasm/block_action(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	if(world.time < reactivearmor_cooldown)
		return BLOCK_NONE
	playsound(get_turf(owner),'sound/hallucinations/veryfar_noise.ogg', 100, TRUE)
	owner.visible_message(span_danger("[src] высвобождает всплеск потусторонней энергии!"))

	haunt_outburst(epicenter = get_turf(owner), range = 5, haunt_chance = 85, duration = 30 SECONDS)

	reactivearmor_cooldown = world.time + reactivearmor_cooldown_duration
	return BLOCK_SUCCESS | BLOCK_PHYSICAL_INTERNAL

/obj/item/clothing/suit/armor/reactive/ectoplasm/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	var/mob/living/carbon/human/owner = loc
	if(!istype(owner) || owner.get_item_by_slot(ITEM_SLOT_OCLOTHING) != src)
		return
	owner.reagents?.add_reagent(/datum/reagent/impure/helgrasp, 20)

/obj/item/clothing/suit/armor/reactive/smoke
	name = "reactive smoke armor"
	desc = "Экспериментальный комплект брони, выпускающий облака густого дыма."
	reactivearmor_cooldown_duration = 15 SECONDS

/obj/item/clothing/suit/armor/reactive/smoke/block_action(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	if(world.time < reactivearmor_cooldown)
		return BLOCK_NONE
	var/datum/effect_system/smoke_spread/smoke = new
	smoke.set_up(5, src)
	smoke.start()
	reactivearmor_cooldown = world.time + reactivearmor_cooldown_duration
	return BLOCK_SUCCESS | BLOCK_PHYSICAL_INTERNAL
