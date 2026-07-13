//The base for slab-bound/based ranged abilities
/obj/effect/proc_holder/slab
	var/obj/item/clockwork/slab/slab
	var/successful = FALSE
	var/finished = FALSE
	var/in_progress = FALSE

/obj/effect/proc_holder/slab/Destroy()
	if(!QDELETED(slab) && slab.slab_ability == src)
		slab.slab_ability = null
	slab = null
	return ..()

/obj/effect/proc_holder/slab/remove_ranged_ability(msg)
	..()
	finished = TRUE
	QDEL_IN(src, 6)

/obj/effect/proc_holder/slab/InterceptClickOn(mob/living/caller, params, atom/target)
	if(..() || in_progress)
		return TRUE
	if(ranged_ability_user.incapacitated() || !slab || !(slab in ranged_ability_user.held_items) || target == slab)
		remove_ranged_ability()
		return TRUE

//For the Hateful Manacles scripture; applies replicant handcuffs to the target.
/obj/effect/proc_holder/slab/hateful_manacles

/obj/effect/proc_holder/slab/hateful_manacles/InterceptClickOn(mob/living/caller, params, atom/target)
	if(..())
		return TRUE

	var/turf/T = ranged_ability_user.loc
	if(!isturf(T))
		return TRUE

	if(iscarbon(target) && target.Adjacent(ranged_ability_user))
		var/mob/living/carbon/L = target
		if(is_servant_of_ratvar(L))
			to_chat(ranged_ability_user, "<span class='neovgre'>\"[L.ru_who(TRUE)] Слуга.\"</span>")
			return TRUE
		else if(L.stat)
			to_chat(ranged_ability_user, "<span class='neovgre'>\"Смысл в том, чтобы сковывать мертвецов? Если только для примера.\"</span>")
			return TRUE
		else if (istype(L.handcuffed,/obj/item/restraints/handcuffs/clockwork))
			to_chat(ranged_ability_user, "<span class='neovgre'>\"[L.ru_who(TRUE)] уже беспомощен, нет?\"</span>")
			return TRUE

		playsound(loc, 'sound/weapons/handcuffs.ogg', 30, TRUE)
		ranged_ability_user.visible_message("<span class='danger'>[ranged_ability_user] начинает формировать оковы вокруг запястий [L]!</span>", \
		"<span class='neovgre_small'>Вы начинаете формировать оковы из сплава репликантов вокруг запястий [L]...</span>")
		to_chat(L, "<span class='userdanger'>[ranged_ability_user] начинает формировать оковы вокруг ваших запястий!</span>")
		if(do_mob(ranged_ability_user, L, 30))
			if(!(istype(L.handcuffed,/obj/item/restraints/handcuffs/clockwork)))
				L.handcuffed = new/obj/item/restraints/handcuffs/clockwork(L)
				L.update_handcuffed()
				to_chat(ranged_ability_user, "<span class='neovgre_small'>Вы сковываете [L].</span>")
				log_combat(ranged_ability_user, L, "handcuffed")
		else
			to_chat(ranged_ability_user, "<span class='warning'>Вам не удалось заковать [L].</span>")

		successful = TRUE

		remove_ranged_ability()

	return TRUE

/obj/item/restraints/handcuffs/clockwork
	name = "replicant manacles"
	desc = "Тяжёлые наручники из ледяного металла. На вид похожи на латунь, но на ощупь гораздо более прочные."
	icon_state = "brass_manacles"
	item_state = "brass_manacles"
	item_flags = DROPDEL

/obj/item/restraints/handcuffs/clockwork/dropped(mob/user)
	user.visible_message("<span class='danger'>[name] в руках [user] разваливается на части!</span>", \
	"<span class='userdanger'>Ваши [name] разваливается на части при снятии!</span>")
	. = ..()

//For the Sentinel's Compromise scripture; heals a target servant.
/obj/effect/proc_holder/slab/compromise
	ranged_mousepointer = 'icons/effects/compromise_target.dmi'

/obj/effect/proc_holder/slab/compromise/InterceptClickOn(mob/living/caller, params, atom/target)
	if(..())
		return TRUE

	var/turf/T = ranged_ability_user.loc
	if(!isturf(T))
		return TRUE

	if(isliving(target) && (target in view(7, get_turf(ranged_ability_user))))
		var/mob/living/L = target
		if(!is_servant_of_ratvar(L))
			to_chat(ranged_ability_user, "<span class='inathneq'>\"[L] пока не служит Ратвару.\"</span>")
			return TRUE
		if(L.stat == DEAD)
			to_chat(ranged_ability_user, "<span class='inathneq'>\"[L.ru_who(TRUE)] мёртв. [text2ratvar("Ох, дитя... Как жаль, что твоя жизнь оборвалась так рано...")]\"</span>")
			return TRUE

		var/brutedamage = L.getBruteLoss()
		var/burndamage = L.getFireLoss()
		var/oxydamage = L.getOxyLoss()
		var/totaldamage = brutedamage + burndamage + oxydamage
		if(!totaldamage && (!L.reagents || !L.reagents.has_reagent(/datum/reagent/water/holywater)))
			to_chat(ranged_ability_user, "<span class='inathneq'>\"[L] не пострадал и остался неосквернённым.\"</span>")
			return TRUE

		successful = TRUE

		to_chat(ranged_ability_user, "<span class='brass'>Вы окунаете [L == ranged_ability_user ? "себя":"[L]"] в силу Инат-Нек!</span>")
		var/targetturf = get_turf(L)
		var/has_holy_water = (L.reagents && L.reagents.has_reagent(/datum/reagent/water/holywater))
		var/healseverity = max(round(totaldamage*0.05, 1), 1) //shows the general severity of the damage you just healed, 1 glow per 20
		for(var/i in 1 to healseverity)
			new /obj/effect/temp_visual/heal(targetturf, "#1E8CE1")
		if(totaldamage)
			L.heal_overall_damage(brutedamage, burndamage, only_organic = FALSE) //Maybe a machine god shouldn't murder augmented followers instead of healing them
			L.adjustOxyLoss(-oxydamage)
			L.adjustToxLoss(totaldamage * 0.5, TRUE, TRUE, toxins_type = TOX_OMNI)
			clockwork_say(ranged_ability_user, text2ratvar("[has_holy_water ? "Исцели осквернённую" : "Почини раненную"] плоть!"))
			log_combat(ranged_ability_user, L, "исцелился с помощью Компромисса Стража")
			L.visible_message("<span class='warning'>Синий свет омывает [L], [has_holy_water ? "заставляя [L.ru_ego()] на мгновение засветиться, пока он исцеляется" : " исцеляя"] [L.ru_ego()] ушибы и ожоги!</span>", \
			"<span class='heavy_brass'>Вы чувствуете, как сила Инат-Нек лечит ваши раны[has_holy_water ? " и избавляет от тьмы внутри вас" : ""], но вас охватывает сильная тошнота!</span>")
		else
			clockwork_say(ranged_ability_user, text2ratvar("Прогони злую тьму!"))
			log_combat(ranged_ability_user, L, "очищен святой водой с помощью Компромисса Стража")
			L.visible_message("<span class='warning'>Синий свет омывает [L], заставляя [L.ru_ego()] на мгновение засиять!</span>", \
			"<span class='heavy_brass'>Вы чувствуете, как сила Инат-Нек изгоняет тьму из вас!</span>")
		playsound(targetturf, 'sound/magic/staff_healing.ogg', 50, 1)

		if(has_holy_water)
			L.reagents.del_reagent(/datum/reagent/water/holywater)

		remove_ranged_ability()

	return TRUE

//For the Volt Void scripture, fires a ray of energy at a target location
/obj/effect/proc_holder/slab/volt
	ranged_mousepointer = 'icons/effects/volt_target.dmi'

/obj/effect/proc_holder/slab/volt/InterceptClickOn(mob/living/caller, params, atom/target)
	if(target == slab || ..()) //we can't cancel
		return TRUE

	var/turf/T = ranged_ability_user.loc
	if(!isturf(T))
		return TRUE

	if(target in view(7, get_turf(ranged_ability_user)))
		successful = TRUE
		ranged_ability_user.visible_message("<span class='warning'>[ranged_ability_user] стреляет лучом энергии в [target]!</span>", "<span class='nzcrentr'>Вы стреляете лучем высокого напряжения в [target].</span>")
		playsound(ranged_ability_user, 'sound/effects/light_flicker.ogg', 50, 1)
		T = get_turf(target)
		new/obj/effect/temp_visual/ratvar/volt_hit(T, ranged_ability_user)
		log_combat(ranged_ability_user, T, "fired a volt ray")
		remove_ranged_ability()

	return TRUE

//For the Kindle scripture; stuns and mutes a target non-servant.
/obj/effect/proc_holder/slab/kindle
	ranged_mousepointer = 'icons/effects/volt_target.dmi'

/obj/effect/proc_holder/slab/kindle/InterceptClickOn(mob/living/caller, params, atom/target)
	if(..())
		return TRUE

	var/turf/T = ranged_ability_user.loc
	if(!isturf(T))
		return TRUE

	if(target in view(7, get_turf(ranged_ability_user)))

		successful = TRUE

		var/turf/U = get_turf(target)
		to_chat(ranged_ability_user, "<span class='brass'>Вы высвобождаете свет Ратвара!</span>")
		clockwork_say(ranged_ability_user, text2ratvar("Избавьтесь от всей лжи и чтите Двигатель"))
		log_combat(ranged_ability_user, U, "fired at with Kindle")
		playsound(ranged_ability_user, 'sound/magic/blink.ogg', 50, TRUE, frequency = 0.5)
		var/obj/item/projectile/kindle/A = new(T)
		A.preparePixelProjectile(target, caller, params)
		A.fire()

		remove_ranged_ability()

	return TRUE

/obj/item/projectile/kindle
	name = "kindled flame"
	icon_state = "pulse0"
	nodamage = TRUE
	damage = 0 //We're just here for the stunning!
	damage_type = BURN
	flag = "bomb"
	range = 3
	log_override = TRUE

/obj/item/projectile/kindle/Destroy()
	visible_message("<span class='warning'>[src] гаснет!</span>")
	. = ..()

/obj/item/projectile/kindle/on_hit(atom/target, blocked = FALSE)
	if(isliving(target))
		var/mob/living/L = target
		if(is_servant_of_ratvar(L) || L.stat || L.has_status_effect(STATUS_EFFECT_KINDLE))
			return BULLET_ACT_HIT
		var/atom/O = L.anti_magic_check()
		playsound(L, 'sound/magic/fireball.ogg', 50, TRUE, frequency = 1.25)
		if(O)
			if(isitem(O))
				L.visible_message("<span class='warning'>В глазах [L] вспыхнул тусклый свет!</span>", \
				"<span class='userdanger'>Ваш [O] раскалился добела, поглощая силу [src]!</span>")
			else if(ismob(O))
				L.visible_message("<span class='warning'>В глазах [L] вспыхнул тусклый свет!</span>")
			playsound(L, 'sound/weapons/sear.ogg', 50, TRUE)
		else
			if(!iscultist(L))
				L.visible_message("<span class='warning'>Глаза [L] сияют ярким светом!</span>", \
				"<span class='userdanger'>Твоё зрение внезапно ослепляет раскалённый белый свет!</span>")
				L.DefaultCombatKnockdown(15, TRUE, FALSE, 15)
				L.apply_status_effect(STATUS_EFFECT_KINDLE)
				L.flash_act(1, 1)
				if(issilicon(target))
					var/mob/living/silicon/S = L
					S.emp_act(80)
			else //for Nar'sian weaklings
				to_chat(L, "<span class='heavy_brass'>\"Каково это увидеть свет, псинка?\"</span>")
				L.visible_message("<span class='warning'>Глаза [L] вспыхнули ярким светом!</span>", \
				"<span class='userdanger'>Внезапно в ваших глазах вспыхивает ослепительный свет!</span>")  //Debuffs Narsian cultists hard + deals some burn instead of just hardstunning them; Only the confusion part can stack
				L.flash_act(1,1)
				if(iscarbon(target))
					var/mob/living/carbon/C = L
					C.stuttering = max(8, C.stuttering)
					C.drowsyness = max(8, C.drowsyness)
					C.confused += clamp(16 - C.confused, 0, 8)
					C.apply_status_effect(STATUS_EFFECT_BELLIGERENT)
				L.adjustFireLoss(15)
	..()


//For the cyborg Linked Vanguard scripture, grants you and a nearby ally Vanguard
/obj/effect/proc_holder/slab/vanguard
	ranged_mousepointer = 'icons/effects/vanguard_target.dmi'

/obj/effect/proc_holder/slab/vanguard/InterceptClickOn(mob/living/caller, params, atom/target)
	if(..())
		return TRUE

	var/turf/T = ranged_ability_user.loc
	if(!isturf(T))
		return TRUE

	if(isliving(target) && (target in view(7, get_turf(ranged_ability_user))))
		var/mob/living/L = target
		if(!is_servant_of_ratvar(L))
			to_chat(ranged_ability_user, "<span class='inathneq'>\"[L] пока не служит Ратвару.\"</span>")
			return TRUE
		if(L.stat == DEAD)
			to_chat(ranged_ability_user, "<span class='inathneq'>\"[L.ru_who(TRUE)] мёртв. [text2ratvar("Ох, дитя... Как жаль, что твоя жизнь оборвалась так рано...")]\"</span>")
			return TRUE
		if(islist(L.stun_absorption) && L.stun_absorption["vanguard"] && L.stun_absorption["vanguard"]["end_time"] > world.time)
			to_chat(ranged_ability_user, "<span class='inathneq'>\"[L.ru_who(TRUE)] уже находится под защитой Вангарда.\"</span>")
			return TRUE

		successful = TRUE

		if(L == ranged_ability_user)
			for(var/mob/living/LT in spiral_range(7, T))
				if(LT.stat == DEAD || !is_servant_of_ratvar(LT) || LT == ranged_ability_user || !(LT in view(7, get_turf(ranged_ability_user))) || \
				(islist(LT.stun_absorption) && LT.stun_absorption["vanguard"] && LT.stun_absorption["vanguard"]["end_time"] > world.time))
					continue
				L = LT
				break

		L.apply_status_effect(STATUS_EFFECT_VANGUARD)
		ranged_ability_user.apply_status_effect(STATUS_EFFECT_VANGUARD)

		clockwork_say(ranged_ability_user, text2ratvar("Shield us from darkness!"))

		remove_ranged_ability()

	return TRUE

//For the cyborg Judicial Marker scripture, places a judicial marker
/obj/effect/proc_holder/slab/judicial
	ranged_mousepointer = 'icons/effects/visor_reticule.dmi'

/obj/effect/proc_holder/slab/judicial/InterceptClickOn(mob/living/caller, params, atom/target)
	if(..())
		return TRUE

	var/turf/T = ranged_ability_user.loc
	if(!isturf(T))
		return TRUE

	if(target in view(7, get_turf(ranged_ability_user)))
		successful = TRUE

		clockwork_say(ranged_ability_user, text2ratvar("На колени, язычники!"))
		ranged_ability_user.visible_message("<span class='warning'>Из глаз [ranged_ability_user] вырывается поток энергии, который попадает в  [target] и оставляет на нем странный след!</span>", \
		"<span class='heavy_brass'>Вы направляете силу правосудия на [target].</span>")
		var/turf/targetturf = get_turf(target)
		new/obj/effect/clockwork/judicial_marker(targetturf, ranged_ability_user)
		log_combat(ranged_ability_user, targetturf, "created a judicial marker")
		remove_ranged_ability()

	return TRUE
