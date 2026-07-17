//Ocular warden: Low-damage, low-range turret. Deals constant damage to whoever it makes eye contact with.

/// How often (in game time) the ocular warden re-scans for nearby targets. Between scans it
/// keeps damaging its current target and reuses the cached target list. Lives in SSfastprocess
/// (0.2s ticks), so this is ~5 ticks between viewers() scans instead of one every tick.
#define OCULAR_WARDEN_SCAN_INTERVAL (1 SECONDS)

/obj/structure/destructible/clockwork/ocular_warden
	name = "ocular warden"
	desc = "Большой латунный глаз со свисающими под ним щупальцами и широкой красной радужкой."
	clockwork_desc = "Хрупкая турель, которая автоматически атакует находящихся поблизости нескованных не-Слуг, которых она может видеть."
	icon_state = "ocular_warden"
	unanchored_icon = "ocular_warden_unwrenched"
	max_integrity = 25
	construction_value = 15
	layer = WALL_OBJ_LAYER
	break_message = "<span class='warning'>Глаза надзирателя вспыхивают полной ненависти, прежде чем потемнеть!</span>"
	debris = list(/obj/item/clockwork/component/belligerent_eye/blind_eye = 1)
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	var/damage_per_tick = 3
	var/sight_range = 3
	var/atom/movable/target
	/// Cached result of the last acquire_nearby_targets() call, reused on non-scan ticks.
	var/list/cached_targets
	COOLDOWN_DECLARE(target_scan_cooldown)
	var/list/idle_messages = list(" угрюмо смотрит по сторонам.", " лениво переваливается с боку на бок.", " оглядывается в поисках чего-нибудь, что можно было бы сжечь.", " медленно вращается по кругу.")

/obj/structure/destructible/clockwork/ocular_warden/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSfastprocess, src)

/obj/structure/destructible/clockwork/ocular_warden/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	return ..()

/obj/structure/destructible/clockwork/ocular_warden/examine(mob/user)
	. = ..()
	. += "<span class='brass'>[target ? "<b>Он зафиксирован на [target]!</b>" : "Его взгляд бесцельно блуждает."]</span>"

/obj/structure/destructible/clockwork/ocular_warden/hulk_damage()
	return 25

/obj/structure/destructible/clockwork/ocular_warden/can_be_unfasten_wrench(mob/user, silent)
	if(!anchored)
		for(var/obj/structure/destructible/clockwork/ocular_warden/W in orange(OCULAR_WARDEN_EXCLUSION_RANGE, src))
			if(W.anchored)
				if(!silent)
					to_chat(user, "<span class='neovgre'>Вы чувствуете, что другой глазной страж находится слишком близко к этому месту. Активация этого стража так близко приведет к драке.</span>")
				return FAILED_UNFASTEN
	return SUCCESSFUL_UNFASTEN

/obj/structure/destructible/clockwork/ocular_warden/ratvar_act()
	..()
	if(GLOB.ratvar_awakens)
		damage_per_tick = 10
		sight_range = 6
	else
		damage_per_tick = initial(damage_per_tick)
		sight_range = initial(sight_range)

/obj/structure/destructible/clockwork/ocular_warden/process()
	if(!anchored)
		lose_target()
		return
	var/list/validtargets = cached_targets
	if(COOLDOWN_FINISHED(src, target_scan_cooldown))
		validtargets = acquire_nearby_targets()
		cached_targets = validtargets
		COOLDOWN_START(src, target_scan_cooldown, OCULAR_WARDEN_SCAN_INTERVAL)
	if(!islist(validtargets))
		validtargets = list()
	if(target)
		if(QDELETED(target) || !(target in validtargets))
			lose_target()
		else
			if(isliving(target))
				var/mob/living/L = target
				if(!L.anti_magic_check(chargecost = 0))
					if(isrevenant(L))
						var/mob/living/simple_animal/revenant/R = L
						if(R.revealed)
							R.unreveal_time += 2
						else
							R.reveal(10)
					if(prob(50))
						L.playsound_local(null,'sound/machines/clockcult/ocularwarden-dot1.ogg',75 * get_efficiency_mod(),1)
					else
						L.playsound_local(null,'sound/machines/clockcult/ocularwarden-dot2.ogg',75 * get_efficiency_mod(),1)
					L.adjustFireLoss((!iscultist(L) ? damage_per_tick : damage_per_tick * 2) * get_efficiency_mod()) //Nar'Sian cultists take additional damage
					if(GLOB.ratvar_awakens && L)
						L.adjust_fire_stacks(damage_per_tick)
						L.IgniteMob()
			else if(ismecha(target))
				var/obj/vehicle/sealed/mecha/M = target
				M.take_damage(damage_per_tick * get_efficiency_mod(), BURN, MELEE, 1, get_dir(src, M))

			new /obj/effect/temp_visual/ratvar/ocular_warden(get_turf(target))

			setDir(get_dir(get_turf(src), get_turf(target)))
	if(!target)
		if(validtargets.len)
			target = pick(validtargets)
			playsound(src,'sound/machines/clockcult/ocularwarden-target.ogg',50,1)
			visible_message("<span class='warning'>[src] поворачивается лицом к [target]!</span>")
			if(isliving(target))
				var/mob/living/L = target
				to_chat(L, "<span class='neovgre'>\"Я ВИЖУ ТЕБЯ!\"</span>\n<span class='userdanger'>Взгляд [src] [GLOB.ratvar_awakens ? "плавит вас заживо" : "обжигает вас"]!</span>")
			else if(ismecha(target))
				var/obj/vehicle/sealed/mecha/M = target
				to_chat(M.occupants, "<span class='neovgre'>\"Я ВИЖУ ТЕБЯ!\"</span>" )
		else if(prob(0.5)) //Extremely low chance because of how fast the subsystem it uses processes
			if(prob(50))
				visible_message("<span class='notice'>[src][pick(idle_messages)]</span>")
			else
				setDir(pick(GLOB.cardinals))//Random rotation

/obj/structure/destructible/clockwork/ocular_warden/proc/acquire_nearby_targets()
	. = list()
	for(var/mob/living/L in viewers(sight_range, src)) //Doesn't attack the blind
		var/obj/item/storage/book/bible/B = L.bible_check()
		if(B)
			if(!(B.resistance_flags & ON_FIRE))
				to_chat(L, "<span class='warning'>Ваш [B.name] вспыхивает пламенем!</span>")
			for(var/obj/item/storage/book/bible/BI in L.GetAllContents())
				if(!(BI.resistance_flags & ON_FIRE))
					BI.fire_act()
			continue
		if(is_servant_of_ratvar(L) || (HAS_TRAIT(L, TRAIT_BLIND)) || L.anti_magic_check(TRUE, TRUE) || L.incapacitated(TRUE))
			continue
		if (iscarbon(L))
			var/mob/living/carbon/c = L
			if (istype(c.handcuffed,/obj/item/restraints/handcuffs/clockwork))
				continue
		if(ishostile(L))
			var/mob/living/simple_animal/hostile/H = L
			if(("ratvar" in H.faction) || (!H.mind && ("neutral" in H.faction)) || (!H.mind && ("skeleton" in H.faction)))
				continue
			if(ismegafauna(H) || (!H.mind && H.AIStatus == AI_OFF))
				continue
		else if(isrevenant(L))
			var/mob/living/simple_animal/revenant/R = L
			if(R.stasis) //Don't target any revenants that are respawning
				continue
		else if(!L.mind)
			continue
		. += L
	var/list/viewcache = list()
	for(var/N in GLOB.mechas_list)
		var/obj/vehicle/sealed/mecha/M = N
		if(get_dist(M, src) <= sight_range && LAZYLEN(M.occupants))
			for(var/mob/living/MB in M.occupants)
				if(is_servant_of_ratvar(MB))
					return
			if(!length(viewcache))
				for (var/obj/Z in view(sight_range, src))
					viewcache += Z
			if (M in viewcache)
				. += M

/obj/structure/destructible/clockwork/ocular_warden/proc/lose_target()
	if(!target)
		return FALSE
	target = null
	visible_message("<span class='warning'>[src] успокаивается и кажется почти разочарованным.</span>")
	return TRUE

/obj/structure/destructible/clockwork/ocular_warden/get_efficiency_mod()
	if(GLOB.ratvar_awakens)
		return 2
	. = 1
	if(target)
		for(var/turf/T in getline(src, target))
			if(T.density)
				. -= 0.1
				continue
			for(var/obj/structure/O in T)
				if(O != src && O.density)
					. -= 0.1
					break
		. -= (get_dist(src, target) * 0.05)
		. = max(., 0.1) //The lowest damage a warden can do is 10% of its normal amount (0.25 by default)

#undef OCULAR_WARDEN_SCAN_INTERVAL
