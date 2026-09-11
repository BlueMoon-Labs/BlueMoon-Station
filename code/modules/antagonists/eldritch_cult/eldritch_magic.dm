/obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift/ash
	name = "Пепельный переход"
	desc = "Ненадолго обратитесь в пепел, чтобы пройти сквозь стены."
	school = "transmutation"
	invocation = "DULK'ES PRE'ZIMAS"
	invocation_type = "whisper"
	charge_max = 150
	range = -1
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "ash_shift"
	action_background_icon_state = "bg_ecult"
	jaunt_in_time = 20
	jaunt_duration = 15
	jaunt_in_type = /obj/effect/temp_visual/dir_setting/ash_shift
	jaunt_out_type = /obj/effect/temp_visual/dir_setting/ash_shift/out

/obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift/ash/long
	jaunt_duration = 75

/obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift/ash/play_sound(type, mob/living/target)
	playsound(target, 'sound/effects/wounds/sizzle2.ogg', 55, TRUE)
	new /obj/effect/temp_visual/heretic_oldpath/ash/trail(get_turf(target))

/obj/effect/temp_visual/dir_setting/ash_shift
	name = "пепельный след"
	icon = 'icons/mob/mob.dmi'
	icon_state = "ash_shift2"
	duration = 13

/obj/effect/temp_visual/dir_setting/ash_shift/out
	icon_state = "ash_shift"

/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp
	name = "Хватка Мансуса"
	desc = "Хватка наносит 10 ушибов, 60 урона выносливости и ненадолго сбивает с ног. Знания пути добавляют эффекты и метку, которую активирует ваш клинок."
	hand_path = /obj/item/melee/touch_attack/mansus_fist
	school = "evocation"
	charge_max = 120
	clothes_req = FALSE
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "mansus_grasp"
	action_background_icon_state = "bg_ecult"

/obj/item/melee/touch_attack/mansus_fist
	name = "Хватка Мансуса"
	desc = "Искажает пространство вокруг ладони. Хватка наносит ушибы, истощает и сбивает с ног. Изученные знания добавляют эффекты вашего пути."
	icon = 'icons/obj/eldritch.dmi'
	icon_state = "mansus_grasp"
	item_state = "mansus"
	catchphrase = "T'IESA SIE'KTI VISATA"

/obj/item/melee/touch_attack/mansus_fist/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	if(!proximity_flag || target == user)
		return
	var/datum/antagonist/heretic/heretic = user.mind?.has_antag_datum(/datum/antagonist/heretic)
	if(!heretic)
		qdel(src)
		return
	if(isliving(target))
		var/mob/living/victim = target
		if(IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim))
			return
		if(victim.check_magic_resistance())
			to_chat(user, span_warning("Защита от магии отталкивает хватку."))
			return ..()
	var/use_charge = FALSE
	var/grasp_sound = 'sound/items/welder.ogg'
	var/grasp_visual
	if(isliving(target))
		var/mob/living/victim = target
		if(victim.stat != DEAD)
			use_charge = TRUE
			victim.adjustBruteLoss(10)
			if(iscarbon(victim))
				victim.DefaultCombatKnockdown(2 SECONDS, override_stamdmg = 0)
				victim.adjustStaminaLoss(60)
	var/list/knowledge = heretic.get_all_knowledge()
	for(var/knowledge_type in knowledge)
		if(QDELETED(target))
			break
		var/datum/eldritch_knowledge/entry = knowledge[knowledge_type]
		if(entry.grasp_visual)
			grasp_visual = entry.grasp_visual
			grasp_sound = entry.grasp_sound
		if(entry.on_mansus_grasp(target, user, proximity_flag, click_parameters))
			use_charge = TRUE
	if(use_charge)
		playsound(user, grasp_sound, 60, TRUE)
		if(grasp_visual && !QDELETED(target))
			new grasp_visual(get_turf(target))
		return ..()

/obj/effect/proc_holder/spell/self/heretic_summon
	action_icon = 'icons/obj/eldritch.dmi'
	action_background_icon_state = "bg_ecult"
	charge_max = 100
	clothes_req = FALSE
	var/obj/item/summon_type // istype
	var/summon_sound = 'modular_bluemoon/sound/heretic/book_summon.ogg'
	var/hide_sound = 'modular_bluemoon/sound/heretic/book_hide.ogg'

/obj/effect/proc_holder/spell/self/heretic_summon/heart
	name = "Призвать живое сердце"
	desc = "Позволяет призывать и прятать живое сердце в пучине безумия. Остальные услышат очень тихий звук призыва, только вплотную к вам."
	action_icon_state = "living_heart"
	summon_type = /obj/item/living_heart
	summon_sound = 'sound/magic/enter_blood.ogg'
	hide_sound = 'sound/magic/Demon_consume.ogg'

/obj/effect/proc_holder/spell/self/heretic_summon/book
	name = "Призвать кодекс"
	desc = "Позволяет призывать и прятать кодекс в тайных глубинах. Остальные услышат очень тихий звук призыва, только вплотную к вам."
	action_icon_state = "codex"
	summon_type = /obj/item/forbidden_book

/obj/effect/proc_holder/spell/self/heretic_summon/can_cast(mob/user, skipcharge, silent)
	. = ..()
	if(!.)
		return
	if(user.incapacitated())
		if(!silent)
			to_chat(user, span_warning("Вы не можете этого сделать в нынешнем состоянии!"))
		return FALSE

/obj/effect/proc_holder/spell/self/heretic_summon/cast(list/targets, mob/user)
	. = ..()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic) // Такого быть не должно, но вдруг
		revert_cast(user)
		return
	var/obj/item/I = locate(summon_type) in heretic.summon_items
	if(I)
		if(summon_item(I, user))
			heretic.summon_items -= I
		else
			to_chat(user, span_warning("Не удалось призвать предмет!"))
			revert_cast(user)
		return

	I = locate(summon_type) in user.loc
	if(I)
		hide_item(I, heretic)
		return
	else
		var/turf/turf = get_turf(user)
		if(turf != user.loc)
			I = locate(summon_type) in turf
			if(I)
				hide_item(I, heretic)
				return

	var/list/temp = user.GetAllContents(summon_type)
	if(LAZYLEN(temp))
		hide_item(temp[1], heretic)
		return

	to_chat(user, span_warning("Вы не ощущаете [initial(summon_type.name)] ни поблизости, ни за завесой."))
	revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_summon/proc/hide_item(obj/item/I, datum/antagonist/heretic/heretic)
	var/mob/living/M = heretic.owner.current
	if(hide_sound)
		playsound(M, hide_sound, 60, TRUE, -SOUND_RANGE+2, SOUND_FALLOFF_EXPONENT*4, falloff_distance = 0)
	var/obj/old_loc = I.loc
	// Да, это магия, клей тут не поможет
	if(ismob(I.loc))
		var/mob/living/Mob = I.loc
		Mob.transferItemToLoc(I, null, TRUE)
	else
		I.moveToNullspace()
	heretic.summon_items += I
	if(istype(old_loc) && old_loc.GetComponent(/datum/component/storage) && (!ismob(old_loc.loc) || (old_loc in M?.GetAllContents())))
		SEND_SIGNAL(old_loc, COMSIG_TRY_STORAGE_SHOW, M)

/obj/effect/proc_holder/spell/self/heretic_summon/proc/summon_item(obj/item/I, mob/living/carbon/human/user)
	if(!istype(user))
		return
	if(summon_sound)
		playsound(user, summon_sound, 60, TRUE, -SOUND_RANGE+2, SOUND_FALLOFF_EXPONENT*4, falloff_distance = 0)
	if(user.put_in_hands(I))
		return TRUE

	var/static/list/slots = list(
		"left pocket" = ITEM_SLOT_LPOCKET,
		"right pocket" = ITEM_SLOT_RPOCKET,
		"backpack" = ITEM_SLOT_BACKPACK
	)

	var/where = user.equip_in_one_of_slots(I, slots, qdel_on_fail = FALSE, critical = TRUE)
	if(where == "backpack")
		SEND_SIGNAL(user.back, COMSIG_TRY_STORAGE_SHOW, user)
	if(!where)
		I.moveToNullspace()
	return where

/obj/effect/proc_holder/spell/aoe_turf/rust_conversion
	name = "Буйное разрастание"
	desc = "Покройте ржавчиной поверхности вокруг себя."
	school = "transmutation"
	charge_max = 300 //twice as long as mansus grasp
	clothes_req = FALSE
	invocation = "PLI'STI MINO DOMI'KA"
	invocation_type = "whisper"
	range = 6
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "corrode"
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/aoe_turf/rust_conversion/cast(list/targets, mob/user = usr)
	playsound(user, 'sound/effects/clangsmall1.ogg', 75, TRUE)
	for(var/turf/T in targets)
		///What we want is the 3 tiles around the user and the tile under him to be rusted, so min(dist,1)-1 causes us to get 0 for these tiles, rest of the tiles are based on chance
		var/chance = 100 - (max(get_dist(T,user),1)-1)*100/(range+1)
		if(!prob(chance))
			continue
		T.rust_heretic_act()
		if(get_dist(T, user) <= 3)
			new /obj/effect/temp_visual/heretic_oldpath/rust(T)

/obj/effect/proc_holder/spell/aoe_turf/rust_conversion/small
	name = "Обращение ржавчины"
	desc = "Покройте ржавчиной поверхности вокруг себя."
	range = 4

/obj/effect/proc_holder/spell/pointed/blood_siphon
	name = "Кровавый сифон"
	desc = "Вытяните кровь из выбранного врага: нанесите 20 ушибов и вылечите столько же себе. Каждая ваша рана с вероятностью 50% перейдёт на соответствующую конечность цели."
	school = "evocation"
	charge_max = 150
	clothes_req = FALSE
	invocation = "FL'MS O'ET'RN'ITY"
	invocation_type = "whisper"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "blood_siphon"
	action_background_icon_state = "bg_ecult"
	range = 6

/obj/effect/proc_holder/spell/pointed/blood_siphon/cast(list/targets, mob/user)
	if(!length(targets) || !can_target(targets[1], user, TRUE))
		revert_cast(user)
		return
	if(!heretic_can_affect(user, targets[1]))
		return
	var/mob/living/victim = targets[1]
	playsound(user, 'sound/effects/wounds/blood3.ogg', 65, TRUE)
	victim.Beam(user, icon_state = "drainbeam", time = 10)
	new /obj/effect/temp_visual/heretic_oldpath/flesh(get_turf(victim))
	new /obj/effect/temp_visual/heretic_oldpath/flesh/mend(get_turf(user))
	victim.adjustBruteLoss(20)
	var/mob/living/living_user = user
	living_user.adjustBruteLoss(-20)
	if(!iscarbon(user) || !iscarbon(victim))
		return
	var/mob/living/carbon/carbon_user = user
	var/mob/living/carbon/carbon_victim = victim
	for(var/obj/item/bodypart/limb as anything in carbon_user.bodyparts)
		var/obj/item/bodypart/target_limb = locate(limb.type) in carbon_victim.bodyparts
		if(!target_limb)
			continue
		for(var/datum/wound/wound as anything in limb.wounds.Copy())
			if(prob(50))
				wound.remove_wound()
				wound.apply_wound(target_limb)
	carbon_victim.blood_volume = max(0, carbon_victim.blood_volume - 20)
	if(carbon_user.blood_volume < BLOOD_VOLUME_MAXIMUM)
		carbon_user.adjust_integration_blood(min(20, BLOOD_VOLUME_MAXIMUM - carbon_user.blood_volume))

/obj/effect/proc_holder/spell/pointed/blood_siphon/can_target(atom/target, mob/user, silent)
	return ..() && heretic_can_affect(user, target, chargecost = 0)

/obj/effect/proc_holder/spell/aimed/rust_wave
	name = "Длань покровителя"
	desc = "Выпустите волну, которая покрывает ржавчиной поверхности на своём пути."
	projectile_type = /obj/item/projectile/magic/spell/rust_wave
	charge_max = 350
	clothes_req = FALSE
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	base_icon_state = "rust_wave"
	action_icon_state = "rust_wave"
	action_background_icon_state = "bg_ecult"
	sound = 'sound/effects/curse5.ogg'
	active_msg = "Вы протягиваете руку, готовясь выпустить волну ржавчины."
	deactive_msg = "Вы позволяете собранной силе угаснуть."
	invocation = "RUD'ZI VAR'ZTAS"
	invocation_type = "whisper"

/obj/item/projectile/magic/spell/rust_wave
	name = "ржавый снаряд"
	icon_state = "eldritch_projectile"
	alpha = 180
	damage = 50
	damage_type = TOX
	nodamage = 0
	hitsound = 'sound/effects/curseattack.ogg'
	range = 15

/obj/item/projectile/magic/spell/rust_wave/Moved(atom/OldLoc, Dir)
	. = ..()
	playsound(src, 'sound/items/welder.ogg', 75, TRUE)
	var/list/turflist = list()
	var/turf/T1
	turflist += get_turf(src)
	T1 = get_step(src,turn(dir,90))
	turflist += T1
	turflist += get_step(T1,turn(dir,90))
	T1 = get_step(src,turn(dir,-90))
	turflist += T1
	turflist += get_step(T1,turn(dir,-90))
	for(var/X in turflist)
		if(!X || prob(25))
			continue
		var/turf/T = X
		T.rust_heretic_act()

/obj/effect/proc_holder/spell/aimed/rust_wave/short
	name = "Малая длань покровителя"
	projectile_type = /obj/item/projectile/magic/spell/rust_wave/short

/obj/item/projectile/magic/spell/rust_wave/short
	range = 7

/obj/effect/proc_holder/spell/pointed/cleave
	name = "Рассечение"
	desc = "Нанесите 20 ушибов, резаную рану и кровотечение выбранному человеку и врагам в одной клетке от него."
	school = "transmutation"
	charge_max = 350
	clothes_req = FALSE
	invocation = "PLES'TI VI'RIBUS"
	invocation_type = "whisper"
	range = 7
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "cleave"
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/pointed/cleave/cast(list/targets, mob/user)
	if(!length(targets) || !can_target(targets[1], user))
		revert_cast(user)
		return FALSE
	var/attempted_hit = FALSE
	for(var/mob/living/carbon/human/victim in view(1, targets[1]))
		if(!length(victim.bodyparts) || victim.stat == DEAD || victim == user || IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim))
			continue
		attempted_hit = TRUE
		if(!heretic_can_affect(user, victim))
			continue
		var/obj/item/bodypart/limb = pick(victim.bodyparts)
		var/datum/wound/slash/moderate/wound = new
		wound.apply_wound(limb)
		limb.generic_bleedstacks += 3
		victim.adjustBruteLoss(20)
		new /obj/effect/temp_visual/cleave(victim.drop_location())
	if(!attempted_hit)
		revert_cast(user)

/obj/effect/proc_holder/spell/pointed/cleave/can_target(atom/target, mob/user, silent)
	. = ..()
	if(!.)
		return FALSE
	if(!istype(target,/mob/living/carbon/human))
		if(!silent)
			to_chat(user, "<span class='warning'>Эту цель нельзя рассечь!</span>")
		return FALSE
	return TRUE

/obj/effect/proc_holder/spell/pointed/cleave/long
	charge_max = 650

/obj/effect/proc_holder/spell/targeted/touch/mad_touch
	name = "Касание безумия"
	desc = "Коснитесь врага, чтобы обрушить на его разум запретные знания Мансуса."
	hand_path = /obj/item/melee/touch_attack/mad_touch
	school = "evocation"
	charge_max = 1800
	clothes_req = FALSE
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "mad_touch"
	action_background_icon_state = "bg_ecult"

/obj/item/melee/touch_attack/mad_touch
	name = "Касание безумия"
	desc = "Зловещая аура, от которой трескается чужой рассудок."
	icon = 'icons/obj/eldritch.dmi'
	icon_state = "mad_touch"
	item_state = "madness"
	catchphrase = "SUNA'IKINTI PROTA"

/obj/item/melee/touch_attack/mad_touch/afterattack(atom/target, mob/user, proximity_flag, click_parameters)

	if(!proximity_flag || target == user)
		return
	if(ishuman(target))
		var/mob/living/carbon/human/tar = target
		if(tar.check_magic_resistance())
			tar.visible_message(span_danger("Заклинание отскакивает от [target]!"), span_danger("Заклинание отскакивает от вас!"))
			return ..()

	if(iscarbon(target))
		playsound(user, 'sound/effects/curseattack.ogg', 75, TRUE)
		var/mob/living/carbon/C = target
		C.adjustOrganLoss(ORGAN_SLOT_BRAIN,60)
		C.DefaultCombatKnockdown(60, override_stamdmg = 0)
		C.gain_trauma(/datum/brain_trauma/mild/phobia)
		to_chat(user, span_warning("На [target.name] наложено проклятие!"))
		SEND_SIGNAL(target, COMSIG_ADD_MOOD_EVENT, "gates_of_mansus", /datum/mood_event/gates_of_mansus)
		return ..()

/obj/effect/proc_holder/spell/targeted/touch/grasp_of_decay
	name = "Хватка распада"
	desc = "Коснитесь врага, чтобы его тело гнило изнутри в течение двадцати секунд."
	hand_path = /obj/item/melee/touch_attack/grasp_of_decay
	school = "evocation"
	charge_max = 1200
	clothes_req = FALSE
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "mansus_grasp"
	action_background_icon_state = "bg_ecult"

/obj/item/melee/touch_attack/grasp_of_decay
	name = "Хватка распада"
	desc = "Зловещая аура, разлагающая чужую плоть изнутри."
	icon = 'icons/obj/eldritch.dmi'
	icon_state = "mansus_grasp"
	item_state = "mansus"
	catchphrase = "SKILI'EDUONIS"

/obj/item/melee/touch_attack/grasp_of_decay/afterattack(atom/target, mob/user, proximity_flag, click_parameters)

	if(!proximity_flag || target == user)
		return
	if(ishuman(target))
		var/mob/living/carbon/human/tar = target
		if(tar.check_magic_resistance())
			tar.visible_message(span_danger("Заклинание отскакивает от [target]!"), span_danger("Заклинание отскакивает от вас!"))
			return ..()

	if(iscarbon(target))
		playsound(user, 'sound/effects/curseattack.ogg', 75, TRUE)
		var/mob/living/carbon/C = target
		C.DefaultCombatKnockdown(60, override_stamdmg = 0)
		C.apply_status_effect(/datum/status_effect/corrosion_curse/lesser)
		return ..()

/obj/effect/proc_holder/spell/pointed/nightwatchers_rite
	name = "Обряд ночного дозора"
	desc = "Выпустите пять расходящихся потоков огня в выбранном направлении."
	school = "transmutation"
	invocation = "IGNIS'INTI"
	invocation_type = "whisper"
	charge_max = 300
	range = 15
	clothes_req = FALSE
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "flames"
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/pointed/nightwatchers_rite/cast(list/targets, mob/user)
	playsound(user, 'modular_bluemoon/sound/heretic/ash_burst.ogg', 80, TRUE)
	var/list/magic_checks = list()
	for(var/X in targets)
		var/T
		T = line_target(-25, range, X, user)
		INVOKE_ASYNC(src, PROC_REF(fire_line), user, T, magic_checks)
		T = line_target(10, range, X, user)
		INVOKE_ASYNC(src, PROC_REF(fire_line), user, T, magic_checks)
		T = line_target(0, range, X, user)
		INVOKE_ASYNC(src, PROC_REF(fire_line), user, T, magic_checks)
		T = line_target(-10, range, X, user)
		INVOKE_ASYNC(src, PROC_REF(fire_line), user, T, magic_checks)
		T = line_target(25, range, X, user)
		INVOKE_ASYNC(src, PROC_REF(fire_line), user, T, magic_checks)
	return ..()

/obj/effect/proc_holder/spell/pointed/nightwatchers_rite/proc/line_target(offset, range, atom/at , atom/user)
	if(!at)
		return
	var/angle = ATAN2(at.x - user.x, at.y - user.y) + offset
	var/turf/T = get_turf(user)
	for(var/i in 1 to range)
		var/turf/check = locate(user.x + cos(angle) * i, user.y + sin(angle) * i, user.z)
		if(!check)
			break
		T = check
	return (getline(user, T) - get_turf(user))

/obj/effect/proc_holder/spell/pointed/nightwatchers_rite/proc/fire_line(atom/source, list/turfs, list/magic_checks = list())
	var/list/hit_list = list()
	for(var/turf/T in turfs)
		if(QDELETED(src) || QDELETED(source) || istype(T, /turf/closed))
			break

		for(var/mob/living/L in T.contents)
			if(L in hit_list)
				continue
			hit_list += L
			if(!(L in magic_checks))
				magic_checks[L] = heretic_can_affect(source, L)
			if(!magic_checks[L])
				continue
			L.adjustFireLoss(8)
			L.adjust_fire_stacks(1)
			L.IgniteMob()

		new /obj/effect/hotspot(T)
		T.hotspot_expose(700,50,1)
		// deals damage to mechs
		for(var/obj/vehicle/sealed/mecha/M in T.contents)
			if(M in hit_list)
				continue
			hit_list += M
			M.take_damage(45, BURN, MELEE, 1)
		sleep(1.5)

/obj/effect/proc_holder/spell/targeted/shapeshift/eldritch
	invocation_type = "none"
	clothes_req = FALSE
	action_background_icon_state = "bg_ecult"
	sound = 'sound/magic/enter_blood.ogg'
	possible_shapes = list(/mob/living/simple_animal/mouse,\
		/mob/living/simple_animal/pet/dog/corgi,\
		/mob/living/simple_animal/hostile/carp,\
		/mob/living/simple_animal/bot/secbot,\
		/mob/living/simple_animal/pet/fox,\
		/mob/living/simple_animal/pet/cat )

/obj/effect/proc_holder/spell/targeted/emplosion/eldritch
	name = "Энергетический импульс"
	invocation_type = "none"
	clothes_req = FALSE
	action_background_icon_state = "bg_ecult"
	range = -1
	include_user = TRUE
	charge_max = 300
	range = 14
	sound = 'modular_bluemoon/sound/heretic/flesh_screech.ogg'

/obj/effect/proc_holder/spell/aoe_turf/fire_cascade
	name = "Огненный каскад"
	desc = "Раскалите воздух вокруг себя."
	school = "transmutation"
	charge_max = 300 //twice as long as mansus grasp
	clothes_req = FALSE
	invocation = "IGNIS'SAVARIN"
	invocation_type = "whisper"
	range = 8
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "fire_ring"
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/aoe_turf/fire_cascade/cast(list/targets, mob/user = usr)
	INVOKE_ASYNC(src, PROC_REF(fire_cascade), user,range)

/obj/effect/proc_holder/spell/aoe_turf/fire_cascade/proc/fire_cascade(atom/centre,max_range)
	var/turf/origin = get_turf(centre)
	playsound(origin, 'sound/items/welder.ogg', 75, TRUE)
	for(var/radius in 1 to max_range)
		if(QDELETED(src) || QDELETED(centre))
			return
		for(var/turf/open/floor/floor in view(radius, origin))
			if(get_dist(origin, floor) != radius)
				continue
			floor.hotspot_expose(700, 50, TRUE)
			for(var/mob/living/victim in floor)
				if(!heretic_can_affect(centre, victim))
					continue
				victim.adjustFireLoss(15)
				victim.adjust_fire_stacks(1)
				victim.IgniteMob()
		sleep(0.3 SECONDS)

/obj/effect/proc_holder/spell/aoe_turf/fire_cascade/big
	range = 6

/obj/effect/proc_holder/spell/targeted/telepathy/eldritch
	invocation = ""
	invocation_type = "whisper"
	clothes_req = FALSE
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/targeted/fire_sworn
	name = "Клятва огня"
	desc = "В течение минуты поддерживайте вокруг себя кольцо огня."
	invocation = "IGNIS'AISTRA'LISTRE"
	invocation_type = "whisper"
	clothes_req = FALSE
	action_background_icon_state = "bg_ecult"
	range = -1
	include_user = TRUE
	charge_max = 1200
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "fire_ring"
	///how long it lasts
	var/duration = 1 MINUTES
	///who casted it right now
	var/mob/current_user
	///Determines if you get the fire ring effect
	var/has_fire_ring = FALSE

/obj/effect/proc_holder/spell/targeted/fire_sworn/cast(list/targets, mob/user)
	. = ..()
	current_user = user
	has_fire_ring = TRUE
	addtimer(CALLBACK(src, PROC_REF(remove), user), duration, TIMER_OVERRIDE|TIMER_UNIQUE)

/obj/effect/proc_holder/spell/targeted/fire_sworn/proc/remove()
	has_fire_ring = FALSE
	current_user = null

/obj/effect/proc_holder/spell/targeted/fire_sworn/process()
	. = ..()
	if(!has_fire_ring || QDELETED(current_user) || current_user.stat == DEAD || !IS_HERETIC(current_user))
		has_fire_ring = FALSE
		current_user = null
		return
	for(var/turf/open/floor/floor in range(1, current_user))
		floor.hotspot_expose(700, 50, TRUE)
		for(var/mob/living/victim in floor)
			if(!heretic_can_affect(current_user, victim, chargecost = 0))
				continue
			victim.adjust_fire_stacks(1)
			victim.IgniteMob()
			victim.adjustFireLoss(2)

/obj/effect/proc_holder/spell/targeted/worm_contract
	name = "Сжаться"
	desc = "Стяните сегменты своего тела на одну клетку."
	invocation_type = "none"
	clothes_req = FALSE
	action_background_icon_state = "bg_ecult"
	range = -1
	include_user = TRUE
	charge_max = 300
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "worm_contract"

/obj/effect/proc_holder/spell/targeted/worm_contract/cast(list/targets, mob/user)
	. = ..()
	if(!istype(user,/mob/living/simple_animal/hostile/eldritch/armsy))
		to_chat(user, span_userdanger("Вы напрягаете мышцы, но ничего не происходит..."))
		return
	var/mob/living/simple_animal/hostile/eldritch/armsy/armsy = user
	armsy.contract_next_chain_into_single_tile()

/obj/effect/temp_visual/cleave
	icon = 'icons/effects/eldritch.dmi'
	icon_state = "cleave"
	duration = 6

/obj/effect/temp_visual/eldritch_smoke
	icon = 'icons/effects/eldritch.dmi'
	icon_state = "smoke"
	duration = 10

/obj/effect/proc_holder/spell/targeted/fiery_rebirth
	name = "Возрождение ночного дозорного"
	desc = "Погасите огонь на себе и вытяните жар из четырёх горящих врагов в пределах 4 клеток. Каждый получает 15 ожогов и восстанавливает вам по 10 ушибов и ожогов."
	invocation = "PETHRO'MINO'IGNI"
	invocation_type = "whisper"
	clothes_req = FALSE
	action_background_icon_state = "bg_ecult"
	range = -1
	include_user = TRUE
	charge_max = 600
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "smoke"

/obj/effect/proc_holder/spell/targeted/fiery_rebirth/cast(list/targets, mob/user)
	var/mob/living/living_user = user
	var/was_on_fire = living_user.on_fire
	living_user.ExtinguishMob()
	var/victims_drained = 0
	for(var/mob/living/victim in view(4, user))
		if(!victim.on_fire || victim.stat == DEAD || victim == user || IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim))
			continue
		if(!heretic_can_affect(user, victim, chargecost = 0))
			continue
		victim.adjustFireLoss(15)
		victims_drained++
		if(victims_drained >= 4)
			break
	if(!was_on_fire && !victims_drained)
		to_chat(user, span_warning("Рядом нет доступного пламени, из которого можно вытянуть жар."))
		revert_cast(user)
		return
	living_user.adjustBruteLoss(-10 * victims_drained)
	living_user.adjustFireLoss(-10 * victims_drained)
	playsound(user, 'modular_bluemoon/sound/heretic/ash_burst.ogg', 60, TRUE)

/obj/effect/proc_holder/spell/pointed/manse_link
	name = "Связь Мансуса"
	desc = "Соедините разумы сквозь Мансус. Выбранные участники смогут обмениваться сообщениями на любом расстоянии."
	school = "transmutation"
	charge_max = 300
	clothes_req = FALSE
	invocation = "SUSEI' METO MIN'TIS"
	invocation_type = "whisper"
	range = 12
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "mansus_link"
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/pointed/manse_link/can_target(atom/target, mob/user, silent)
	if(!isliving(target))
		return FALSE
	return TRUE

/obj/effect/proc_holder/spell/pointed/manse_link/cast(list/targets, mob/user)
	var/mob/living/simple_animal/hostile/eldritch/raw_prophet/originator = user

	var/mob/living/target = targets[1]

	to_chat(originator, span_notice("Вы начинаете связывать разум [target] со своим..."))
	to_chat(target, span_warning("Что-то тянет ваш разум... соединяет его с чужим... вплетает в саму ткань реальности..."))
	if(!do_after(originator, 6 SECONDS, target))
		return
	if(!originator.link_mob(target))
		to_chat(originator, span_warning("Не удаётся связать разум [target] со своим..."))
		to_chat(target, span_warning("Чужое присутствие покидает ваш разум."))
		return
	to_chat(originator, span_notice("Разум [target] присоединился к вашей связи Мансуса!"))


/datum/action/innate/mansus_speech
	name = "Связь Мансуса"
	desc = "Отправьте мысленное сообщение всем участникам вашей связи Мансуса."
	button_icon_state = "link_speech"
	icon_icon = 'icons/mob/actions/actions_slime.dmi'
	background_icon_state = "bg_ecult"
	var/mob/living/simple_animal/hostile/eldritch/raw_prophet/originator

/datum/action/innate/mansus_speech/New(_originator)
	. = ..()
	originator = _originator

/datum/action/innate/mansus_speech/Activate()
	var/mob/living/living_owner = owner
	if(!originator?.linked_mobs[living_owner])
		CRASH("Uh oh the mansus link got somehow activated without it being linked to a raw prophet or the mob not being in a list of mobs that should be able to do it.")

	var/message = sanitize(input("Сообщение:", "Телепатия Мансуса") as text|null)

	if(QDELETED(living_owner))
		return

	if(!originator?.linked_mobs[living_owner])
		to_chat(living_owner, span_warning("Связь оборвалась..."))
		Remove(living_owner)
		return
	if(message)
		var/msg = "<i><font color=#568b00>\[Связь Мансуса\] <b>[living_owner]:</b> [message]</font></i>"
		log_directed_talk(living_owner, originator, msg, LOG_SAY, "Mansus Link")
		to_chat(originator.linked_mobs, msg)

		for(var/dead_mob in GLOB.dead_mob_list)
			var/link = FOLLOW_LINK(dead_mob, living_owner)
			to_chat(dead_mob, "[link] [msg]")

/obj/effect/proc_holder/spell/pointed/trigger/blind/eldritch
	range = 10
	invocation = "AK'LIS"
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/pointed/trigger/mute/eldritch
	name = "Безмолвие"
	desc = "Сила Мансуса лишает выбранную цель голоса на тридцать секунд."
	school = "transmutation"
	charge_max = 1800
	clothes_req = FALSE
	invocation = "VIS'TIEK TAVO'LIZUVIS"
	invocation_type = "whisper"
	message = "<span class='userdanger'>Невидимая сила словно удерживает ваш язык!</span>"
	starting_spells = list("/obj/effect/proc_holder/spell/targeted/genetic/mute")
	ranged_mousepointer = 'icons/effects/mouse_pointers/mute_target.dmi'
	action_background_icon_state = "bg_ecult"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "mute"
	active_msg = "Вы готовитесь лишить цель голоса..."

/obj/effect/proc_holder/spell/targeted/genetic/mute
	mutations = list(MUT_MUTE)
	duration = 30 SECONDS
	charge_max = 1200 // needs to be higher than the duration or it'll be permanent
	sound = 'sound/magic/blind.ogg'

/obj/effect/proc_holder/spell/pointed/trigger/mute/can_target(atom/target, mob/user, silent)
	. = ..()
	if(!.)
		return FALSE
	if(!isliving(target))
		if(!silent)
			to_chat(user, span_warning("Лишить голоса можно только живое существо!"))
		return FALSE
	return TRUE


/obj/effect/temp_visual/dir_setting/entropic
	icon = 'icons/effects/160x160.dmi'
	icon_state = "entropic_plume"
	duration = 3 SECONDS

/obj/effect/temp_visual/dir_setting/entropic/setDir(dir)
	. = ..()
	switch(dir)
		if(NORTH)
			pixel_x = -64
		if(SOUTH)
			pixel_x = -64
			pixel_y = -128
		if(EAST)
			pixel_y = -64
		if(WEST)
			pixel_y = -64
			pixel_x = -128

/obj/effect/temp_visual/glowing_rune
	icon = 'icons/effects/eldritch.dmi'
	icon_state = "small_rune_1"
	duration = 1 MINUTES
	layer = LOW_SIGIL_LAYER

/obj/effect/temp_visual/glowing_rune/Initialize(mapload)
	. = ..()
	pixel_y = rand(-6,6)
	pixel_x = rand(-6,6)
	icon_state = "small_rune_[rand(12)]"
	update_icon()

/obj/effect/proc_holder/spell/cone/staggered/entropic_plume
	name = "Энтропийное облако"
	desc = "Выпустите облако, которое дезориентирует врагов, ослепляет и отравляет их. Вдали ослепление сильнее, а отравление слабее. Поверхности на пути облака покрываются ржавчиной."
	school = "illusion"
	invocation = "RU'KAS NU'DYTI"
	invocation_type = "whisper"
	clothes_req = FALSE
	action_background_icon_state = "bg_ecult"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "entropic_plume"
	charge_max = 300
	cone_levels = 5
	respect_density = TRUE

/obj/effect/proc_holder/spell/cone/staggered/entropic_plume/cast(list/targets,mob/user = usr)
	. = ..()
	new /obj/effect/temp_visual/dir_setting/entropic(get_step(user,user.dir), user.dir)

/obj/effect/proc_holder/spell/cone/staggered/entropic_plume/do_turf_cone_effect(turf/target_turf, level)
	. = ..()
	target_turf.rust_heretic_act()

/obj/effect/proc_holder/spell/cone/staggered/entropic_plume/do_mob_cone_effect(mob/living/victim, level)
	. = ..()
	if(IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim) || victim.check_magic_resistance())
		return
	victim.apply_status_effect(STATUS_EFFECT_AMOK)
	victim.apply_status_effect(STATUS_EFFECT_CLOUDSTRUCK, (level*10))
	if(iscarbon(victim))
		var/mob/living/carbon/carbon_victim = victim
		carbon_victim.reagents.add_reagent(/datum/reagent/eldritch, max(1, cone_levels + 1 - level))

/obj/effect/proc_holder/spell/cone/staggered/entropic_plume/calculate_cone_shape(current_level)
	if(current_level == cone_levels)
		return 5
	else if(current_level == cone_levels-1)
		return 3
	else
		return 2

/obj/effect/proc_holder/spell/targeted/shed_human_form
	name = "Сбросить облик"
	desc = "Сбросьте человеческий облик и примите многорукую форму Повелителя Ночи."
	invocation_type = "shout"
	invocation = "РЕАЛЬНОСТЬ, РАЗВЕРНИСЬ!"
	clothes_req = FALSE
	action_background_icon_state = "bg_ecult"
	range = -1
	include_user = TRUE
	charge_max = 100
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "worm_ascend"
	var/segment_length = 10

/obj/effect/proc_holder/spell/targeted/shed_human_form/cast(list/targets, mob/user)
	. = ..()
	var/mob/living/target = user
	var/mob/living/mob_inside = locate() in target.contents - target

	if(!mob_inside)
		var/mob/living/simple_animal/hostile/eldritch/armsy/prime/outside = new(user.loc,TRUE,segment_length)
		target.mind.transfer_to(outside, TRUE)
		target.forceMove(outside)
		target.apply_status_effect(STATUS_EFFECT_STASIS,STASIS_ASCENSION_EFFECT)
		for(var/mob/living/carbon/human/humie in view(9,outside)-target)
			if(IS_HERETIC(humie) || IS_HERETIC_MONSTER(humie))
				continue
			SEND_SIGNAL(humie, COMSIG_ADD_MOOD_EVENT, "gates_of_mansus", /datum/mood_event/gates_of_mansus)
			///They see the very reality uncoil before their eyes.
			if(prob(25))
				var/trauma = pick(subtypesof(BRAIN_TRAUMA_MILD) + subtypesof(BRAIN_TRAUMA_SEVERE))
				humie.gain_trauma(new trauma(), TRAUMA_RESILIENCE_LOBOTOMY)
		return

	if(iscarbon(mob_inside))
		var/mob/living/simple_animal/hostile/eldritch/armsy/prime/armsy = target
		if(mob_inside.remove_status_effect(STATUS_EFFECT_STASIS,STASIS_ASCENSION_EFFECT))
			mob_inside.forceMove(armsy.loc)
		armsy.mind.transfer_to(mob_inside, TRUE)
		segment_length = armsy.get_length()
		qdel(armsy)
		return

/obj/effect/proc_holder/spell/pointed/void_blink
	name = "Пустотный сдвиг"
	desc = "Переместитесь на открытую клетку в поле зрения в 3–7 клетках от вас. Враги возле точек выхода и входа получают 20 ушибов."
	invocation_type = "whisper"
	invocation = "PAS'VEIK"
	clothes_req = FALSE
	range = 7
	action_background_icon_state = "bg_ecult"
	charge_max = 300
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "voidblink"
	selection_type = "range"

/obj/effect/proc_holder/spell/pointed/void_blink/can_target(atom/target, mob/user, silent)
	if(!..())
		return FALSE
	var/turf/destination = get_turf(target)
	return isopenturf(destination) && !is_blocked_turf(destination, TRUE) && user.z == destination.z && get_dist(user, destination) >= 3 && (destination in view(7, user))

/obj/effect/proc_holder/spell/pointed/void_blink/cast(list/targets, mob/user)
	if(!length(targets) || !can_target(targets[1], user))
		revert_cast(user)
		return
	var/turf/departure = get_turf(user)
	var/turf/destination = get_turf(targets[1])
	if(!do_teleport(user, destination, channel = TELEPORT_CHANNEL_MAGIC))
		revert_cast(user)
		return
	playsound(departure, 'sound/magic/voidblink.ogg', 80, TRUE)
	playsound(destination, 'sound/magic/voidblink.ogg', 80, TRUE)
	new /obj/effect/temp_visual/voidin(departure)
	new /obj/effect/temp_visual/voidout(destination)
	new /obj/effect/temp_visual/heretic_oldpath/void(departure)
	new /obj/effect/temp_visual/heretic_oldpath/void(destination)
	var/list/victims = list()
	for(var/mob/living/victim in view(1, departure))
		victims |= victim
	for(var/mob/living/victim in view(1, destination))
		victims |= victim
	for(var/mob/living/victim as anything in victims)
		if(heretic_can_affect(user, victim))
			victim.adjustBruteLoss(20)

/obj/effect/temp_visual/voidin
	icon = 'icons/effects/96x96.dmi'
	icon_state = "void_blink_in"
	alpha = 150
	duration = 6
	pixel_x = -32
	pixel_y = -32

/obj/effect/temp_visual/voidout
	icon = 'icons/effects/96x96.dmi'
	icon_state = "void_blink_out"
	alpha = 150
	duration = 6
	pixel_x = -32
	pixel_y = -32

/obj/effect/proc_holder/spell/targeted/void_pull
	name = "Притяжение пустоты"
	desc = "Притяните видимых врагов в пределах трёх клеток на два шага к себе. Те, кто уже стоит вплотную, получают 20 ушибов и падают на 2 секунды."
	invocation_type = "whisper"
	invocation = "VISA'GALIS TRAUK'IMAS"
	clothes_req = FALSE
	action_background_icon_state = "bg_ecult"
	range = -1
	include_user = TRUE
	charge_max = 400
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "voidpull"

/obj/effect/proc_holder/spell/targeted/void_pull/cast(list/targets, mob/user)
	playsound(user, 'sound/magic/voidpull.ogg', 75, TRUE)
	new /obj/effect/temp_visual/voidin(user.drop_location())
	for(var/mob/living/victim in view(3, user))
		if(!isturf(victim.loc) || victim.anchored || victim.buckled || !heretic_can_affect(user, victim))
			continue
		if(get_turf(victim) != get_turf(user))
			var/turf/departure = get_turf(victim)
			departure.Beam(get_turf(user), icon_state = "slingbeam", icon = 'modular_bluemoon/icons/obj/heretic_shadows.dmi', time = 0.8 SECONDS, maxdistance = 4, beam_type = /obj/effect/ebeam/heretic_void)
		if(get_dist(user, victim) <= 1)
			victim.adjustBruteLoss(20)
			victim.AdjustKnockdown(2 SECONDS)
			victim.AdjustParalyzed(0.5 SECONDS)
		for(var/i in 1 to 2)
			if(get_dist(user, victim) <= 1)
				break
			step_towards(victim, user)

/obj/effect/proc_holder/spell/pointed/boogie_woogie
	name = "Аплодисменты пустоты"
	desc = "Хлопните в ладоши и поменяйтесь местами с выбранной целью."
	school = "transmutation"
	charge_max = 100
	clothes_req = FALSE
	invocation = "BOOGIE WOOGIE"
	invocation_type = "none"
	range = 15
	message = "Мир вокруг вас внезапно меняется!"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "mansus_link"
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/pointed/boogie_woogie/cast(list/targets, mob/user)
	if(!length(targets) || !can_target(targets[1], user))
		revert_cast(user)
		return
	var/mob/living/victim = targets[1]
	var/turf/victim_turf = get_turf(victim)
	var/turf/user_turf = get_turf(user)
	if(!do_teleport(victim, user_turf, channel = TELEPORT_CHANNEL_MAGIC))
		revert_cast(user)
		return
	if(!do_teleport(user, victim_turf, channel = TELEPORT_CHANNEL_MAGIC))
		do_teleport(victim, victim_turf, channel = TELEPORT_CHANNEL_MAGIC)
		revert_cast(user)
		return
	user.emote("clap1")
	playsound(user, 'sound/magic/voidblink.ogg', 75, TRUE)
	new /obj/effect/temp_visual/voidswap(user_turf)
	new /obj/effect/temp_visual/voidswap(victim_turf)

/obj/effect/proc_holder/spell/pointed/boogie_woogie/can_target(atom/target, mob/user, silent)
	if(!..() || !isliving(target) || !isturf(target.loc) || !isturf(user.loc))
		return FALSE
	var/mob/living/victim = target
	return victim != user && victim.stat != DEAD && !victim.anchored && !victim.buckled && !victim.check_magic_resistance(chargecost = 0) && !is_blocked_turf(get_turf(victim), TRUE) && !is_blocked_turf(get_turf(user), TRUE)

/obj/effect/proc_holder/spell/aoe_turf/domain_expansion
	name = "Бесконечная пустота"
	desc = "После трёх секунд сосредоточения создайте домен 7×7 на 20 секунд. Он замедляет врагов и накладывает метки Пустоты; союзники свободно проходят через него."
	charge_max = 900
	clothes_req = FALSE
	invocation_type = "none"
	range = 0
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "voidpull"
	action_background_icon_state = "bg_ecult"
	var/obj/effect/domain_expansion/active_domain

/obj/effect/proc_holder/spell/aoe_turf/domain_expansion/cast(list/targets, mob/user = usr)
	var/mutable_appearance/halo = mutable_appearance('icons/effects/effects.dmi', "at_shield2", EFFECTS_LAYER)
	user.add_overlay(halo)
	var/completed = do_mob(user, user, 3 SECONDS)
	user.cut_overlay(halo)
	if(!completed || QDELETED(src) || !IS_HERETIC(user))
		if(!QDELETED(src))
			revert_cast(user)
		return
	QDEL_NULL(active_domain)
	user.emote("clap1")
	playsound(user, 'sound/magic/domain.ogg', 85, TRUE)
	active_domain = new(get_turf(user), 3, 20 SECONDS, list(user))
	RegisterSignal(active_domain, COMSIG_PARENT_QDELETING, PROC_REF(on_domain_deleted))

/obj/effect/proc_holder/spell/aoe_turf/domain_expansion/proc/on_domain_deleted(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_PARENT_QDELETING)
	if(active_domain == source)
		active_domain = null

/obj/effect/proc_holder/spell/aoe_turf/domain_expansion/Destroy()
	QDEL_NULL(active_domain)
	return ..()
