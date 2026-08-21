/turf/open/pool
	icon = 'icons/turf/pool.dmi'
	name = "poolwater"
	desc = "You're safer here than in the deep."
	icon_state = "pool_tile"
	// BLUEMOON: pools are sunken basins. This blocks walking out (see
	// /turf/open/CanPass in the liquids module) and makes falling in a real drop,
	// so the only way out is climbing/dragging yourself up.
	turf_height = -30
	heat_capacity = INFINITY
	footstep = FOOTSTEP_WATER
	barefootstep = FOOTSTEP_WATER
	clawfootstep = FOOTSTEP_WATER
	heavyfootstep = FOOTSTEP_WATER
	/// How much water each pool tile starts with. Pools are dry at round start
	/// and get filled by whatever pours water into them.
	var/start_liquid = 0
	var/next_splash = 0
	// BLUEMOON: what tile item this pool returns when dismantled with a crowbar
	var/floor_tile = /obj/item/stack/tile/plasteel/pool

/turf/open/pool/Initialize(mapload)
	. = ..()
	if(!liquids && start_liquid > 0)
		add_liquid(/datum/reagent/water, start_liquid)

// BLUEMOON EDIT: shared drag-out check so the liquids module override of /turf/open/MouseDrop_T
// doesn't eat the pool climb-out. The user must be able to use their hands to pull themselves out.
/turf/open/proc/check_pool_drag_out(atom/from, mob/living/user)
	if(!istype(user))
		return FALSE
	// I could make this /open/floor and not have the !istype but ehh - kev
	if(HAS_TRAIT(from, TRAIT_SWIMMING) && ((user == from) || (isliving(user) && user.CanReach(from))) && CHECK_MOBILITY(user, MOBILITY_USE) && !istype(src, /turf/open/pool))
		var/mob/living/L = from
		//The element only exists if you're on water and a living mob, so let's skip those checks.
		var/pre_msg
		var/post_msg
		if(user == from)
			pre_msg = "<span class='notice'>[L] is getting out of the pool.</span>"
			post_msg = "<span class='notice'>[L] gets out of the pool.</span>"
		else
			pre_msg = "<span class='notice'>[L] is being pulled out of the pool by [user].</span>"
			post_msg = "<span class='notice'>[user] pulls [L] out of the pool.</span>"
		L.visible_message(pre_msg)
		if(do_mob(user, L, 20))
			L.visible_message(post_msg)
			L.forceMove(src)
		return TRUE
	return FALSE

// Mousedrop hook to normal turfs to get out of pools.
// (Consolidated into the base /turf/open/MouseDrop_T in code/game/turfs/open.dm)

// Entered logic
/turf/open/pool/Entered(atom/movable/AM, atom/oldloc)
	if(istype(AM, /obj/effect/decal/cleanable))
		var/obj/effect/decal/cleanable/C = AM
		if(prob(C.bloodiness))
			visible_message("<span class='warning'>[C] washes away in the pool water.</span>")
		QDEL_IN(AM, 25)
		animate(AM, alpha = 10, time = 20)
		return ..()
	if(!AM.has_gravity(src))
		return ..()
	if(isliving(AM))
		var/mob/living/victim = AM
		// Synthetics with the water-vulnerability quirk short out in water (below),
		// but the fall damage itself is identical for everyone.
		var/vulnerable_robo = isrobotic(victim) && HAS_TRAIT(victim, TRAIT_BLUEMOON_WATER_VULNERABILITY)
		// A pool is "empty" when there's no meaningful water - a dry basin you fall into
		// and hit the bottom. Detect by liquid state so a lingering empty liquid turf
		// (drained but not yet destroyed) still counts as empty.
		var/water_level = liquids ? liquids.liquid_state : LIQUID_STATE_PUDDLE
		if(water_level <= LIQUID_STATE_PUDDLE)
			// BLUEMOON: drained/empty pool - falling in hits the hard bottom. The same for everyone.
			if(iscarbon(victim) && !HAS_TRAIT(victim, TRAIT_SWIMMING) && !istype(oldloc, /turf/open/pool))
				var/mob/living/carbon/H = victim
				if(!H.head || !(H.head.armor.getRating(MELEE) > 20))
					if(prob(75))
						H.visible_message("<span class='danger'>[H] falls in the drained pool!</span>",
											"<span class='userdanger'>You fall in the drained pool!</span>")
						H.adjustBruteLoss(7)
						H.DefaultCombatKnockdown(80)
						playsound(src, 'sound/effects/woodhit.ogg', 60, TRUE, 1)
					else
						H.visible_message("<span class='danger'>[H] falls in the drained pool, and cracks [H.ru_ego()] skull!</span>",
											"<span class='userdanger'>You fall in the drained pool, and crack your skull!</span>")
						H.apply_damage(15, BRUTE, "head")
						H.DefaultCombatKnockdown(200) // This should hurt. And it does.
						playsound(src, 'sound/effects/woodhit.ogg', 60, TRUE, 1)
						playsound(src, 'sound/misc/crack.ogg', 100, TRUE)
				else
					H.visible_message("<span class='danger'>[H] falls in the drained pool, but had an helmet!</span>",
										"<span class='userdanger'>You fall in the drained pool, but you had an helmet!</span>")
					H.DefaultCombatKnockdown(40)
					playsound(src, 'sound/effects/woodhit.ogg', 60, TRUE, 1)
		else if(water_level >= LIQUID_STATE_ANKLES && !HAS_TRAIT(victim, TRAIT_SWIMMING))		//poor guy not swimming time to dunk them!
			victim.AddElement(/datum/element/swimming)
			if(locate(/obj/structure/pool/ladder) in src)		//safe climbing
				return
			if(iscarbon(AM))		//FUN TIME!
				var/mob/living/carbon/H = victim
				if(vulnerable_robo)
					H.visible_message("<span class='danger'>[H] sparks and shorts out as the water hits [H.ru_ego()] circuits!</span>",
										"<span class='userdanger'>The water shorts out your circuits!</span>")
					do_sparks(4, TRUE, H)
					playsound(src, 'sound/effects/splash.ogg', 60, TRUE, 1)
					playsound(src, 'sound/machines/hiss.ogg', 40, FALSE)
					if(H.stat == CONSCIOUS)
						H.apply_damage(25, BURN)
						H.AdjustConfused(30 SECONDS)
						H.Jitter(15)
						H.DefaultCombatKnockdown(40)
				else if(isrobotic(H))
					H.visible_message("<span class='danger'>[H] falls in the water!</span>",
										"<span class='userdanger'>You fall in the water!</span>")
					playsound(src, 'sound/effects/splash.ogg', 60, TRUE, 1)
					H.adjustBruteLoss(5)
					H.DefaultCombatKnockdown(60)
				else if (H.wear_mask && H.wear_mask.flags_cover & MASKCOVERSMOUTH)
					H.visible_message("<span class='danger'>[H] falls in the water!</span>",
										"<span class='userdanger'>You fall in the water!</span>")
					playsound(src, 'sound/effects/splash.ogg', 60, TRUE, 1)
					H.adjustBruteLoss(3)
					H.DefaultCombatKnockdown(20)
					return
				else
					H.visible_message("<span class='danger'>[H] falls in and takes a drink!</span>",
										"<span class='userdanger'>You fall in and swallow some water!</span>")
					playsound(src, 'sound/effects/splash.ogg', 60, TRUE, 1)
					H.adjustBruteLoss(5)
					H.DefaultCombatKnockdown(60)
					H.adjustOxyLoss(5)
					H.emote("cough")
		else if(liquids)
			if(iscarbon(victim))
				victim.adjustStaminaLoss(1)
			playsound(src, "water_wade", 20, TRUE)
	return ..()

/turf/open/pool/MouseDrop_T(atom/from, mob/user)
	// Handle the drag-in BEFORE the base /turf/open/MouseDrop_T generic height
	// climbing, so the victim has TRAIT_SWIMMING before being moved into the pool
	// and Entered's fall damage doesn't trigger on a deliberate lowering.
	if(!isliving(from))
		return ..()
	var/mob/living/victim = from
	if(user.stat || user.lying || !Adjacent(user) || !from.Adjacent(user) || !iscarbon(user) || !victim.has_gravity(src) || HAS_TRAIT(victim, TRAIT_SWIMMING))
		return ..()
	var/victimname = victim == user? "себя" : "[victim]"
	var/starttext = victim == user? "[user] спускается в [src]." : "[user] опускает [victim] в [src]."
	user.visible_message("<span class='notice'>[starttext]</span>")
	if(do_mob(user, victim, 20))
		user.visible_message("<span class='notice'>[user] опускает [victimname] в [src].</span>")
		victim.AddElement(/datum/element/swimming)		//make sure they have it so they don't fall/whatever
		victim.forceMove(src)
	return TRUE

/turf/open/pool/attackby(obj/item/W, mob/living/user)
	if(istype(W, /obj/item/mop) && liquids)
		W.reagents.add_reagent(/datum/reagent/water, 5)
		to_chat(user, "<span class='notice'>Вы намочили [W] в [src].</span>")
		playsound(src, 'sound/effects/slosh.ogg', 25, TRUE)
	else
		return ..()

// BLUEMOON: pool disassembly with a crowbar. Pools are built by placing pool
// floor tiles, so a crowbar in HELP intent pries them back up into a tile item.
/turf/open/pool/crowbar_act(mob/living/user, obj/item/I)
	if(user.a_intent != INTENT_HELP)
		return FALSE
	to_chat(user, "<span class='notice'>Вы начинаете выламывать [src]...</span>")
	if(!I.use_tool(src, user, 3 SECONDS, volume = 80))
		return FALSE
	// BLUEMOON: the pool might have been replaced while we were working
	if(!istype(src, /turf/open/pool))
		return TRUE
	if(floor_tile)
		new floor_tile(src)
	if(liquids)
		// drain the water when the basin is removed
		qdel(liquids, TRUE)
	for(var/obj/effect/decal/cleanable/C in src)
		if(C.wiped_by_floor_change)
			qdel(C)
	// BLUEMOON: prying up a player-built pool returns to whatever floor was
	// underneath (matching floor tile prying). Map pools sit on the bare
	// /turf/baseturf_bottom, so if scraping doesn't leave a normal floor,
	// fall back to plain plating instead.
	var/turf/new_turf = ScrapeAway(flags = CHANGETURF_INHERIT_AIR)
	if(!isfloorturf(new_turf))
		new_turf.ChangeTurf(/turf/open/floor/plating, flags = CHANGETURF_INHERIT_AIR)
	to_chat(user, "<span class='notice'>Вы разобрали [src] и получили тайл пола.</span>")
	return TRUE

/turf/open/pool/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	. = ..()
	if(.)
		return
	if((user.loc != src) && !user.IsStun() && !user.IsKnockdown() && !user.incapacitated() && Adjacent(user) && HAS_TRAIT(user, TRAIT_SWIMMING) && liquids && (next_splash < world.time))
		playsound(src, 'sound/effects/watersplash.ogg', 8, TRUE, 1)
		next_splash = world.time + 25
		var/obj/effect/splash/S = new(src)
		animate(S, alpha = 0, time = 8)
		QDEL_IN(S, 10)
		for(var/mob/living/carbon/human/H in src)
			if(!H.wear_mask && (H.stat == CONSCIOUS))
				H.emote("cough")
			H.adjustStaminaLoss(4)
