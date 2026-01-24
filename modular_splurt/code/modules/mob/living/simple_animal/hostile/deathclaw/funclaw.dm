/mob/living/simple_animal/hostile/deathclaw/funclaw
	name = "Funclaw"
	desc = "A massive, reptilian creature with powerful muscles, razor-sharp claws, and aggression to match. This one seems to have a strange look in its eyes.."
	var/change_target_hole_cooldown = 0
	var/chosen_hole
	var/voremode = FALSE // Fixes runtime when grabbing victim
	stat_attack = UNCONSCIOUS
	robust_searching = TRUE
	gold_core_spawnable = NO_SPAWN // Admin only
	deathclaw_mode = "rape"

/mob/living/simple_animal/hostile/deathclaw/funclaw/Initialize(mapload)
	. = ..()
	if(aggro_vision_range) // Если это не мирный моб, то его нельзя таскать, прятать в ящики и т.д.
		mob_weight = MOB_WEIGHT_HEAVY_SUPER

/mob/living/simple_animal/hostile/deathclaw/funclaw/gentle
	desc = "A massive, reptilian creature with powerful muscles, razor-sharp claws, and aggression to match. This one has the bedroom eyes.."
	deathclaw_mode = "gentle"

/mob/living/simple_animal/hostile/deathclaw/funclaw/abomination
	name = "Exiled Deathclaw"
	desc = "A massive, reptilian creature with powerful muscles, razor-sharp claws, and aggression to match. This one has a strange smell for some reason.."
	deathclaw_mode = "abomination"

//BLUEMOON ADD START || The sex mob will no longer even try to attack targets that are not suitable for prefs.
/mob/living/simple_animal/hostile/deathclaw/funclaw/ListTargets()
	. = ..()
	for(var/E in enemies) // Ебашим врагов до смерти
		if(!(E in .) && can_see(src, E, vision_range))
			. += E

/mob/living/simple_animal/hostile/deathclaw/funclaw/CanAttack(atom/the_target)
	. = ..()
	if(!.)
		return .

	if(!isliving(the_target))
		return .

	var/mob/living/M = the_target

	if(CanRape(M) || (M in enemies))
		return TRUE

	return FALSE

/mob/living/simple_animal/hostile/deathclaw/funclaw/proc/CanRape(mob/living/M)
	. = FALSE

	if(!M.client)
		return FALSE

	//So the new pref mobsexpref checks - Gardelin0
	if(M.client?.prefs.mobsexpref == "No" \
		|| M.client?.prefs.erppref != "Yes" \
		|| M.client?.prefs.nonconpref == "No")
		return FALSE

	if(CHECK_BITFIELD(M.client?.prefs.toggles, VERB_CONSENT))
		return TRUE

	return .

// Если фанклава обидели, он будет защищаться
// Удары
/mob/living/simple_animal/hostile/deathclaw/funclaw/attack_hand(mob/living/user)
	var/prev = health
	. = ..()
	mark_enemy_if_hurt(user, prev)

/mob/living/simple_animal/hostile/deathclaw/funclaw/attackby(obj/item/I, mob/living/user, params, attackchain_flags, damage_multiplier)
	var/prev = health
	. = ..()
	mark_enemy_if_hurt(user, prev)

/mob/living/simple_animal/hostile/deathclaw/funclaw/attack_animal(mob/living/simple_animal/M)
	var/prev = health
	. = ..()
	mark_enemy_if_hurt(M, prev)

/mob/living/simple_animal/hostile/deathclaw/funclaw/attack_alien(mob/living/carbon/alien/humanoid/M)
	var/prev = health
	. = ..()
	mark_enemy_if_hurt(M, prev)

/mob/living/simple_animal/hostile/deathclaw/funclaw/attack_larva(mob/living/carbon/alien/larva/L)
	var/prev = health
	. = ..()
	mark_enemy_if_hurt(L, prev)

/mob/living/simple_animal/hostile/deathclaw/funclaw/attack_slime(mob/living/simple_animal/slime/M)
	var/prev = health
	. = ..()
	mark_enemy_if_hurt(M, prev)

/mob/living/simple_animal/hostile/deathclaw/funclaw/attack_drone(mob/living/simple_animal/drone/M)
	var/prev = health
	. = ..()
	mark_enemy_if_hurt(M, prev)

/mob/living/simple_animal/hostile/deathclaw/funclaw/attack_paw(mob/living/carbon/monkey/M)
	var/prev = health
	. = ..()
	mark_enemy_if_hurt(M, prev)

/mob/living/simple_animal/hostile/deathclaw/funclaw/attack_hulk(mob/living/carbon/human/user, does_attack_animation)
	var/prev = health
	. = ..()
	mark_enemy_if_hurt(user, prev)

/mob/living/simple_animal/hostile/deathclaw/funclaw/attack_robot(mob/living/user)
	var/prev = health
	. = ..()
	mark_enemy_if_hurt(user, prev)

/mob/living/simple_animal/hostile/deathclaw/funclaw/mech_melee_attack(obj/vehicle/sealed/mecha/mecha_attacker, mob/user)
	var/prev = health
	. = ..()
	mark_enemy_if_hurt(user, prev)

// Дальнее оружие
/mob/living/simple_animal/hostile/deathclaw/funclaw/bullet_act(obj/item/projectile/Proj)
	var/prev = health
	. = ..()
	var/mob/living/A = isliving(Proj.firer) ? Proj.firer : null
	mark_enemy_if_hurt(A, prev)

// Броски
/mob/living/simple_animal/hostile/deathclaw/funclaw/hitby(atom/movable/AM, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	var/prev = health
	. = ..()
	var/mob/living/A = isliving(throwingdatum?.thrower) ? throwingdatum.thrower : null
	mark_enemy_if_hurt(A, prev)

/mob/living/simple_animal/hostile/deathclaw/funclaw/proc/mark_enemy_if_hurt(mob/living/A, prev_hp)
	if(!A)
		return
	if(prev_hp <= health)
		return
	if(A in range(vision_range, src))
		if(A in enemies)
			enemies -= A
		enemies.Insert(1, A) // Условно первый в агролисте личных врагов

/mob/living/simple_animal/hostile/deathclaw/funclaw/moan()
	var/message_to_display = pick("рычит%S%", "рычит%S% от удовольствия")
	visible_message(span_lewd("<b>\The [src]</b> [replacetext(message_to_display, "%S%", "")]."),
		span_lewd("Вы [replacetext(message_to_display, "%S%", "е")]."),
		span_lewd("Вы слышите наполненный удовольствием рык."),
		ignored_mobs = get_unconsenting(), omni = TRUE)

	var/static/list/moans = list('modular_splurt/sound/lewd/deathclaw_grunt1.ogg',
					'modular_splurt/sound/lewd/deathclaw_grunt2.ogg',
					'modular_splurt/sound/lewd/deathclaw_grunt3.ogg',
					'modular_splurt/sound/lewd/deathclaw_grunt4.ogg',
					'modular_splurt/sound/lewd/deathclaw_grunt5.ogg'
					)

	// Pick a sound from the list.
	var/sound = pick(moans)

	// If the sound is repeated, get a new from a list without it.
	if (lastmoan == sound)
		sound = pick(LAZYCOPY(moans) - lastmoan)

	playlewdinteractionsound(loc, sound, 80, 1, -1)
	lastmoan = sound

/mob/living/simple_animal/hostile/deathclaw/funclaw/PickTarget(list/Targets)
	//. = ..() Не требуется

	// targets_from — точка, от которой считаем дистанцию
	// Targets — список возможных целей
	// enemies — список личных врагов

	var/list/cands = list()
	var/min_d = vision_range * 5 // Большая мин дист, что бы перебить при проверке

	// 1) последний ЛИЧНЫЙ враг, что нанес урон
	for(var/atom/A in enemies)
		if(A in Targets)
			return A
	/*
	// 1) ближайший ЛИЧНЫЙ враг
	for(var/atom/A in Targets)
		if(!(A in enemies))
			continue
		var/d = get_dist(targets_from, A)
		if(d < min_d)
			min_d = d
			cands = list(A)
		else if(d == min_d)
			cands += A
	*/

	if(cands.len)
		return pick(cands)

	// 2) ближайшая ОБЫЧНАЯ цель
	cands.Cut()
	min_d = vision_range * 5 // Большая мин дист, что бы перебить при проверке

	for(var/atom/B in Targets)
		var/d2 = get_dist(targets_from, B)
		if(d2 < min_d)
			min_d = d2
			cands = list(B)
		else if(d2 == min_d)
			cands += B

	return cands.len ? pick(cands) : null
//BLUEMOON ADD END

/mob/living/simple_animal/hostile/deathclaw/funclaw/AttackingTarget()

	if(!CanRape(target))
		..() // Attack target to death
		return

	var/mob/living/M = target

	var/onLewdCooldown = FALSE

	if(get_refraction_dif() > 0)
		onLewdCooldown = TRUE

	switch(deathclaw_mode)
		if("gentle")
			if(onLewdCooldown)
				return // Do nothing
		if("abomination")
			if(onLewdCooldown)
				return // Do nothing
		if("rape")
			if(onLewdCooldown || M.health > M.maxHealth * 0.4)
				..() // Attack target
				return

	if((target in enemies) && M.health > M.maxHealth * 0.4)
		..() // Attack target
		return

	if(!M.pulledby)
		if(!M.buckled && !M.density)
			M.forceMove(src.loc)

		start_pulling(M, supress_message = TRUE)
		log_combat(src, M, "grabbed")
		M.visible_message("<span class='warning'>[src] violently grabs [M]!</span>", \
			"<span class='userdanger'>[src] violently grabs you!</span>")
		setGrabState(GRAB_NECK) //Instant neck grab

		return

	if(get_refraction_dif() > 0)
		..()
		return

	if(change_target_hole_cooldown < world.time)
		chosen_hole = null
		while (chosen_hole == null)
			pickNewHole(M)
		change_target_hole_cooldown = world.time + 100


	do_lewd_action(M)
	addtimer(CALLBACK(src, PROC_REF(do_lewd_action), M), rand(8, 12))

	// Regular sex has an extra action per tick to seem less slow and robotic
	if(deathclaw_mode != "abomination" || M.client?.prefs.unholypref != "Yes")
		addtimer(CALLBACK(src, PROC_REF(do_lewd_action), M), rand(12, 16))

/mob/living/simple_animal/hostile/deathclaw/LoseTarget()
	. = ..()
	stop_pulling()

/mob/living/simple_animal/hostile/deathclaw/funclaw/proc/pickNewHole(mob/living/M)
	switch(rand(2))
		if(0)
			chosen_hole = CUM_TARGET_ANUS
		if(1)
			if(M.has_vagina())
				chosen_hole = CUM_TARGET_VAGINA
			else
				chosen_hole = CUM_TARGET_ANUS
		if(2)
			chosen_hole = CUM_TARGET_THROAT

/mob/living/simple_animal/hostile/deathclaw/funclaw/proc/do_lewd_action(mob/living/M)
	if(get_refraction_dif() > 0)
		return

	var/datum/interaction/I
	switch(chosen_hole)
		if(CUM_TARGET_ANUS)
			if(tearSlot(M, ITEM_SLOT_OCLOTHING))
				return
			if(tearSlot(M, ITEM_SLOT_ICLOTHING))
				return

			// Abomination deathclaws do other stuff instead
			if(deathclaw_mode == "abomination" && M.client?.prefs.unholypref == "Yes")
				if(prob(1))
					I = SSinteractions.interactions["/datum/interaction/lewd/grindmouth"]
				else
					I = SSinteractions.interactions["/datum/interaction/lewd/grindface"]
				handle_post_sex(25, null, M)
			else
				I = SSinteractions.interactions["/datum/interaction/lewd/fuck/anal"]
			I.display_interaction(src, M)

		if(CUM_TARGET_VAGINA)
			if(tearSlot(M, ITEM_SLOT_OCLOTHING))
				return
			if(tearSlot(M, ITEM_SLOT_ICLOTHING))
				return

			// Abomination deathclaws do other stuff instead
			if(deathclaw_mode == "abomination" && M.client?.prefs.unholypref == "Yes")
				I = SSinteractions.interactions["/datum/interaction/lewd/footjob/vagina"]
				handle_post_sex(10, null, M)
			else
				I = SSinteractions.interactions["/datum/interaction/lewd/fuck"]
			I.display_interaction(src, M)

		if(CUM_TARGET_THROAT)
			if(tearSlot(M, ITEM_SLOT_HEAD))
				return
			if(tearSlot(M, ITEM_SLOT_MASK))
				return

			// Abomination deathclaws do other stuff instead
			if(deathclaw_mode == "abomination" && M.client?.prefs.unholypref == "Yes")
				if(prob(1))
					do_faceshit(M)
				else
					do_facefart(M)
				handle_post_sex(25, null, M)
				shake_camera(M, 6, 1)
			else
				I = SSinteractions.interactions["/datum/interaction/lewd/facefuck"] //Changed so they don't crit you anymore - Gardelin0
				I.display_interaction(src, M)

/mob/living/simple_animal/hostile/deathclaw/funclaw/cum(mob/living/M, target_orifice, cum_inside = FALSE, anonymous = FALSE)

	if(get_refraction_dif() > 0)
		return

	var/message
	var/obj/item/organ/genital/target_gen = null

	if(!istype(M))
		chosen_hole = null

	switch(chosen_hole)
		if(CUM_TARGET_THROAT)
			if(M.has_mouth() && M.mouth_is_free())
	// BLUEMOON EDIT START
				message = "засовывает свой толстый ящерский член глубоко в глотку \the [M] и кончает!"
				target_gen = M.getorganslot(ORGAN_SLOT_STOMACH)
				target_gen.reagents.add_reagent(/datum/reagent/consumable/semen, 30)
			else
				message = "кончает на лицо \the [M]!"
		if(CUM_TARGET_VAGINA)
			if(M.is_bottomless() && M.has_vagina())
				message = "засовывает свой мясистый член в киску \the [M] и наполняет ее спермой!"
				target_gen = M.getorganslot(ORGAN_SLOT_WOMB)
				target_gen.reagents.add_reagent(/datum/reagent/consumable/semen, 30)
				M.impregnate(src, M.getorganslot(ORGAN_SLOT_WOMB), src.type)
			else
				message = "кончает на живот \the [M]!"
		if(CUM_TARGET_ANUS)
			if(M.is_bottomless() && M.has_anus())
				message = "[pick("вгоняет","вонзает")] свой узловатый член в задницу \the [M] и наполняет ее своей спермой!"
				target_gen = M.getorganslot(ORGAN_SLOT_ANUS)
				target_gen.reagents.add_reagent(/datum/reagent/consumable/semen, 30)
			else
				message = "кончает на спину \the [M]!"
		else
			message = "кончает, заливая пространство под собой!"

	if(deathclaw_mode == "abomination" && M.client?.prefs.unholypref == "Yes")
		message = "покрывает все тело \the [M] спермой!"
	// BLUEMOON EDIT END

	new /obj/effect/decal/cleanable/semen(loc)

	playlewdinteractionsound(loc, "modular_splurt/sound/lewd/deathclaw[rand(1, 2)].ogg", 80, 1, -1) // BLUEMOON EDIT
	visible_message(span_userlove("<b>\The [src]</b> [message]")) // BLUEMOON EDIT
	shake_camera(M, 6, 1)
	set_is_fucking(null ,null)

	refractory_period = world.time + rand(100, 150) // Sex cooldown
	set_lust(0) // Nuts at 400

	addtimer(CALLBACK(src, PROC_REF(slap), M), 15)


/mob/living/simple_animal/hostile/deathclaw/funclaw/proc/slap(mob/living/M)
	playlewdinteractionsound(loc, "modular_sand/sound/interactions/slap.ogg", 30, 1, -1)
	visible_message(span_danger("\The [src]</b> шлёпает [M] по заднице!"), \
			span_userdanger("\The [src]</b> шлёпает [M] по заднице!"), null, COMBAT_MESSAGE_RANGE)

/mob/living/simple_animal/hostile/deathclaw/funclaw/proc/tearSlot(mob/living/M, slot)
	var/obj/item/W = M.get_item_by_slot(slot)
	if(W)
		M.dropItemToGround(W)
		playlewdinteractionsound(loc, "sound/items/poster_ripped.ogg", 30, 1, -1)
		visible_message(span_danger("\The [src]</b> разрывает одежду [M]!"), \
				span_userdanger("\The [src]</b> разрывает одежду [M]!"), null, COMBAT_MESSAGE_RANGE)
		return TRUE
	return FALSE
