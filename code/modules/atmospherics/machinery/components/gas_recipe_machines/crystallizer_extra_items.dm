/// Crystallizer recipes: fuel pellets, stacks, shards (from WhiteMoon)

// === Gas crystal grenades ===
/obj/item/grenade/gas_crystal
	desc = "A crystal from the crystallizer."
	name = "Gas Crystal"
	icon = 'icons/obj/crystallizer_crystals.dmi'
	icon_state = "healium_crystal"
	item_state = "flashbang"
	resistance_flags = FIRE_PROOF

/obj/item/grenade/gas_crystal/microwave_act(obj/machinery/microwave/microwave_source, mob/microwaver, randomize_pixel_offset)
	. = ..()
	return . | crystallizer_microwave_detonate(microwave_source, microwaver)

/obj/item/grenade/gas_crystal/preprime(mob/user, delayoverride, msg = TRUE, volume = 60)
	var/armed_icon = icon_state
	..()
	icon_state = armed_icon

/obj/item/grenade/gas_crystal/prime(mob/living/lanced_by)
	..()
	update_mob()

/obj/item/grenade/gas_crystal/healium_crystal
	name = "Healium crystal"
	desc = "A crystal made from Healium gas, cold to the touch."
	icon_state = "healium_crystal"
	var/fix_range = 7
	/// Healium moles released per turf (scaled by distance)
	var/healium_per_turf = 50

/obj/item/grenade/gas_crystal/healium_crystal/prime(mob/living/lanced_by)
	..()
	playsound(src, 'sound/effects/spray2.ogg', 100, TRUE)
	for(var/turf/open/T in range(fix_range, src))
		var/dist = max(get_dist(T, src), 1)
		T.air.adjust_moles(GAS_HEALIUM, healium_per_turf / dist)
		T.air.adjust_moles(GAS_O2, MOLES_O2STANDARD * 0.5 / dist)
		T.air.adjust_moles(GAS_N2, MOLES_N2STANDARD * 0.5 / dist)
		T.air.set_temperature(T20C)
	qdel(src)

/obj/item/grenade/gas_crystal/healium_crystal/crystallizer_microwave_special(turf/center)
	for(var/turf/open/T in range(fix_range, center))
		T.air?.set_temperature(T20C)

/obj/item/grenade/gas_crystal/proto_nitrate_crystal
	name = "Proto Nitrate crystal"
	desc = "A crystal made from Proto Nitrate gas."
	icon_state = "proto_nitrate_crystal"
	var/refill_range = 5
	var/n2_gas_amount = 80
	var/o2_gas_amount = 30
	/// Proto nitrate moles released per turf (scaled by distance)
	var/proto_nitrate_amount = 40

/obj/item/grenade/gas_crystal/proto_nitrate_crystal/prime(mob/living/lanced_by)
	..()
	playsound(src, 'sound/effects/spray2.ogg', 100, TRUE)
	for(var/turf/open/T in view(refill_range, src))
		var/dist = max(get_dist(T, src), 1)
		T.air.adjust_moles(GAS_PROTO_NITRATE, proto_nitrate_amount / dist)
		T.air.adjust_moles(GAS_N2, n2_gas_amount / dist)
		T.air.adjust_moles(GAS_O2, o2_gas_amount / dist)
	qdel(src)

/obj/item/grenade/gas_crystal/nitrous_oxide_crystal
	name = "N2O crystal"
	desc = "A crystal made from N2O gas."
	icon_state = "n2o_crystal"
	var/fill_range = 3
	var/n2o_gas_amount = 50

/obj/item/grenade/gas_crystal/nitrous_oxide_crystal/prime(mob/living/lanced_by)
	..()
	playsound(src, 'sound/effects/spray2.ogg', 100, TRUE)
	for(var/turf/open/T in range(fill_range, src))
		var/dist = max(get_dist(T, src), 1)
		T.air.adjust_moles(GAS_NITROUS, n2o_gas_amount / dist)
	qdel(src)

/obj/item/grenade/gas_crystal/crystal_foam
	name = "crystal foam"
	desc = "A crystal with a foggy inside."
	icon = 'icons/obj/crystallizer_grenades.dmi'
	icon_state = "crystal_foam"
	var/breach_range = 7

/obj/item/grenade/gas_crystal/crystal_foam/prime(mob/living/lanced_by)
	..()
	crystallizer_foam_splash(get_turf(src))
	playsound(src, 'sound/effects/spray2.ogg', 100, TRUE)
	update_mob()
	qdel(src)

/obj/item/grenade/gas_crystal/crystal_foam/crystallizer_microwave_special(turf/center)
	crystallizer_foam_splash(center)

// === Fuel pellets ===
/obj/item/fuel_pellet
	name = "standard fuel pellet"
	desc = "A compressed fuel pellet."
	icon = 'icons/obj/crystallizer_exploration.dmi' 
	icon_state = "fuel_basic"
	w_class = WEIGHT_CLASS_SMALL
	var/uses = 5

/obj/item/fuel_pellet/advanced
	name = "advanced fuel pellet"
	icon_state = "fuel_advanced"

/obj/item/fuel_pellet/exotic
	name = "exotic fuel pellet"
	icon_state = "fuel_exotic"

// === Stacks (crystallizer products) ===
/obj/item/stack/ammonia_crystals
	name = "ammonia crystals"
	singular_name = "ammonia crystal"
	icon = 'icons/obj/crystallizer_crystals.dmi'
	icon_state = "ammonia_crystal"
	w_class = WEIGHT_CLASS_TINY
	resistance_flags = FLAMMABLE
	max_amount = 50
	grind_results = list(/datum/reagent/ammonia = 10)
	merge_type = /obj/item/stack/ammonia_crystals

/obj/item/stack/ammonia_crystals/microwave_act(obj/machinery/microwave/microwave_source, mob/microwaver, randomize_pixel_offset)
	. = ..()
	return . | crystallizer_microwave_detonate(microwave_source, microwaver)

/obj/item/stack/sheet/mineral/metal_hydrogen
	name = "metallic hydrogen"
	singular_name = "metallic hydrogen sheet"
	icon = 'icons/obj/crystallizer_sheets.dmi' 
	icon_state = "sheet-metalhydrogen"
	merge_type = /obj/item/stack/sheet/mineral/metal_hydrogen

/obj/item/stack/sheet/mineral/metal_hydrogen/microwave_act(obj/machinery/microwave/microwave_source, mob/microwaver, randomize_pixel_offset)
	. = ..()
	return . | crystallizer_microwave_detonate(microwave_source, microwaver)

/obj/item/stack/sheet/mineral/zaukerite
	name = "zaukerite"
	singular_name = "zaukerite crystal"
	icon = 'icons/obj/crystallizer_crystals.dmi'
	icon_state = "zaukerite"
	merge_type = /obj/item/stack/sheet/mineral/zaukerite

/obj/item/stack/sheet/mineral/zaukerite/microwave_act(obj/machinery/microwave/microwave_source, mob/microwaver, randomize_pixel_offset)
	. = ..()
	return . | crystallizer_microwave_detonate(microwave_source, microwaver)

// === Metallic hydrogen crafts ===
/obj/item/metallic_hydrogen_rod
	name = "metallic hydrogen rod"
	desc = "A rod reinforced with metallic hydrogen. Extremely dense; useful as a tool or improvised weapon."
	icon = 'icons/obj/crystallizer_sheets.dmi'
	icon_state = "sheet-metalhydrogen"
	item_state = "rods"
	force = 10
	throwforce = 12
	w_class = WEIGHT_CLASS_NORMAL
	attack_verb = list("bludgeoned", "hit", "struck")

/obj/item/metallic_hydrogen_cooling_pack
	name = "metallic hydrogen cooling pack"
	desc = "Stabilized metallic hydrogen wrapped in cloth. Stays very cold; use to cool down."
	icon = 'icons/obj/crystallizer_sheets.dmi'
	icon_state = "sheet-metalhydrogen"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/metallic_hydrogen_cooling_pack/attack_self(mob/user)
	. = ..()
	if(.)
		return
	to_chat(user, "<span class='notice'>You press the pack to your skin; it feels intensely cold.</span>")
	if(isliving(user))
		var/mob/living/L = user
		L.adjust_bodytemperature(-80)

/obj/item/stack/sheet/hot_ice
	name = "hot ice"
	singular_name = "hot ice sheet"
	icon = 'icons/obj/hot_ice.dmi'
	icon_state = "hot-ice"
	merge_type = /obj/item/stack/sheet/hot_ice
	grind_results = list(/datum/reagent/hot_ice_slush = 25)

/obj/item/stack/sheet/hot_ice/microwave_act(obj/machinery/microwave/microwave_source, mob/microwaver, randomize_pixel_offset)
	. = ..()
	return . | crystallizer_microwave_detonate(microwave_source, microwaver)

/obj/item/stack/sheet/hot_ice/proc/melt_release()
	var/turf/open/T = get_turf(src)
	if(!istype(T) || !T.air)
		return
	var/plasma_moles = amount * 150
	var/release_temp = 20 * amount + 300
	T.atmos_spawn_air("plasma=[plasma_moles];TEMP=[release_temp]")
	qdel(src)

/obj/item/stack/sheet/hot_ice/fire_act(exposed_temperature, exposed_volume)
	melt_release()

/obj/item/stack/sheet/hot_ice/welder_act(mob/living/user, obj/item/I)
	if(I.use_tool(src, user, 0, volume = 50))
		melt_release()
		return TRUE
	return FALSE

// === Hot ice cooling pack (craftable from crystallizer hot ice) ===
/obj/item/hot_ice_pack
	name = "hot ice cooling pack"
	desc = "A pack of stabilized hot ice wrapped in cloth. Stays cold for a long time; use to cool down."
	icon = 'icons/obj/hot_ice.dmi'
	icon_state = "hot-ice"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/hot_ice_pack/attack_self(mob/user)
	. = ..()
	if(.)
		return
	to_chat(user, "<span class='notice'>You press the pack to your skin; it feels pleasantly cool.</span>")
	if(isliving(user))
		var/mob/living/L = user
		L.adjust_bodytemperature(-50)

// === Ammonia pack (craftable from ammonia crystals) ===
/obj/item/ammonia_pack
	name = "ammonia pack"
	desc = "Crystals of ammonia wrapped in cloth. Can be broken to release a small cloud of ammonia."
	icon = 'icons/obj/crystallizer_crystals.dmi'
	icon_state = "ammonia_crystal"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/ammonia_pack/attack_self(mob/user)
	. = ..()
	if(.)
		return
	var/turf/T = get_turf(src)
	if(T)
		var/datum/reagents/R = new(10)
		R.add_reagent(/datum/reagent/ammonia, 10)
		var/datum/effect_system/smoke_spread/chem/smoke = new
		smoke.set_up(R, 1, T, TRUE)
		smoke.start()
	to_chat(user, "<span class='notice'>You crush the pack; a sharp smell of ammonia fills the air.</span>")
	qdel(src)

// === Crystal shard reagent injection (all living organisms) ===
/// Carbons without DNA/liver (xenos, etc.) never run handle_liver metabolism — apply effects immediately instead.
/proc/crystal_shard_can_metabolize_reagents(mob/living/target)
	if(!iscarbon(target) || !target.reagents)
		return FALSE
	var/mob/living/carbon/C = target
	if(!C.dna && !C.getorganslot(ORGAN_SLOT_LIVER))
		return FALSE
	if(C.dna && (NOLIVER in C.dna.species.species_traits))
		return FALSE
	return TRUE

/proc/crystal_shard_apply_instant(mob/living/target, reagent_type, amount)
	var/ticks = clamp(round(amount / 2.5), 2, 8)
	switch(reagent_type)
		if(/datum/reagent/zauker)
			for(var/i in 1 to ticks)
				target.adjustBruteLoss(15 * REM * 0.5)
				target.adjustOxyLoss(4.5 * REM * 0.5)
				target.adjustFireLoss(6 * REM * 0.5)
				target.adjustToxLoss(7.5 * REM * 0.5)
		if(/datum/reagent/nitrous_oxide)
			if(iscarbon(target))
				var/mob/living/carbon/C = target
				C.drowsyness += amount * 5
				C.Unconscious(45)
				C.AdjustSleeping(max(60, amount * 8))
				if(prob(70))
					C.losebreath += 3 * ticks
			else
				target.Stun(ticks * 2 SECONDS)
				target.Unconscious(45)
				target.AdjustSleeping(60)
			target.confused = min(target.confused + ticks * 2, 12)
		if(/datum/reagent/healium)
			var/heal_amount = clamp(round(3 + amount * 1.2), 3, 18) * ticks
			target.adjustBruteLoss(-heal_amount)
			target.adjustFireLoss(-heal_amount)
			target.adjustOxyLoss(-max(round(heal_amount * 0.5), 1))
			target.adjustToxLoss(-max(round(heal_amount * 0.3), 1))
		if(/datum/reagent/hypernoblium)
			if(iscarbon(target))
				var/mob/living/carbon/C = target
				if(isplasmaman(C))
					C.apply_status_effect(/datum/status_effect/hypernob_protection)
			target.adjustStaminaLoss(-2 * ticks)
		if(/datum/reagent/nitrium_low_metabolization)
			target.add_movespeed_modifier(/datum/movespeed_modifier/reagent/nitrium, update = FALSE)
			if(iscarbon(target))
				var/mob/living/carbon/C = target
				C.adjustStaminaLoss(-4 * REM * 0.5 * ticks, 0)
		if(/datum/reagent/proto_nitrate)
			target.radiation += amount * 100

/proc/crystal_shard_inject(mob/living/target, reagent_type, amount)
	if(!isliving(target) || HAS_TRAIT(target, TRAIT_ROBOTIC_ORGANISM))
		return
	if(crystal_shard_can_metabolize_reagents(target))
		target.reagents.add_reagent(reagent_type, amount)
	else
		crystal_shard_apply_instant(target, reagent_type, amount)

#define CRYSTAL_SHARD_THROW_PROC_CHANCE 2

/// Melee armor rating of the striking weapon — thicker gear muffles shard gas release.
/proc/crystal_shard_get_melee_armor(obj/item/weapon)
	if(!isobj(weapon) || !weapon.armor)
		return 0
	return weapon.armor.get_rating(MELEE)

/// Chance (0–100) for a shard to release gas on melee hit. Matches rebar bolt pen vs weapon melee armor.
/proc/crystal_shard_get_melee_proc_chance(armour_penetration, obj/item/weapon)
	var/melee_armor = crystal_shard_get_melee_armor(weapon)
	var/chance = 100 - melee_armor + armour_penetration
	if(armour_penetration < melee_armor)
		chance /= 3
	return clamp(round(chance), 0, 100)

/proc/crystal_shard_roll_strike_proc(obj/item/weapon, thrown, armour_penetration, mob/living/victim, mob/living/attacker)
	if(isliving(victim) && victim == attacker)
		return TRUE
	if(thrown)
		return prob(CRYSTAL_SHARD_THROW_PROC_CHANCE)
	return prob(crystal_shard_get_melee_proc_chance(armour_penetration, weapon))

// === Zaukerite shard (raw + cloth-wrapped weapon) ===
#define ZAUKERITE_SHARD_ZAUKER_AMOUNT 10

/obj/item/shard/zaukerite
	name = "zaukerite shard"
	desc = "A jagged shard of crystallized zaukerite. Extremely sharp and unstable."
	icon = 'icons/obj/crystallizer_exploration.dmi'
	icon_state = "zaukerite_sharp"
	item_state = "shard-glass"
	force = 7
	throwforce = 12
	armour_penetration = 20
	sharpness = SHARP_EDGED
	attack_verb = list("stabbed", "slashed", "sliced", "cut")
	embedding = null
	craft_time = 14 SECONDS
	custom_materials = null

/obj/item/shard/zaukerite/Initialize(mapload)
	. = ..()
	icon_state = "zaukerite_sharp"
	pixel_x = 0
	pixel_y = 0
	RegisterSignal(src, COMSIG_ITEM_ATTACK_ZONE, PROC_REF(on_zaukerite_melee_strike))

/obj/item/shard/zaukerite/attack(mob/living/M, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	..()
	if(!isliving(M) || iscarbon(M))
		return
	zaukerite_shard_consume_strike(src, M, user)

/obj/item/shard/zaukerite/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	var/mob/living/target = isliving(hit_atom) ? hit_atom : null
	var/mob/living/thrower = throwingdatum?.thrower
	var/result = ..()
	if(QDELETED(src) || !target || result == BLOCK_SUCCESS)
		return result
	zaukerite_shard_consume_strike(src, target, thrower, thrown = TRUE)
	return result

/obj/item/shard/zaukerite/attackby(obj/item/item, mob/user, params)
	if(istype(item, /obj/item/stack/sheet/cloth))
		var/obj/item/stack/sheet/cloth/cloth = item
		to_chat(user, span_notice("You begin to wrap the [cloth] around the [src]..."))
		if(do_after(user, craft_time, target = src))
			var/obj/item/zaukerite_shard/wrapped = new
			cloth.use(1)
			to_chat(user, span_notice("You wrap the [cloth] around the [src], forming a makeshift weapon."))
			remove_item_from_storage(src, user)
			qdel(src)
			user.put_in_hands(wrapped)
		return
	return ..()

/obj/item/zaukerite_shard
	name = "zaukerite shard"
	desc = "A zaukerite crystal shard wrapped in cloth. One strike leaks toxic zauker into the victim before the shard crumbles."
	icon = 'icons/obj/crystallizer_exploration.dmi'
	icon_state = "zaukerite_shard"
	item_state = "shard-glass"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	force = 7
	throwforce = 12
	armour_penetration = 20
	w_class = WEIGHT_CLASS_TINY
	sharpness = SHARP_EDGED
	attack_verb = list("stabbed", "slashed", "sliced", "cut")
	hitsound = 'sound/weapons/bladeslice.ogg'
	embedding = null

/obj/item/zaukerite_shard/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_ITEM_ATTACK_ZONE, PROC_REF(on_zaukerite_melee_strike))

/obj/item/zaukerite_shard/attack(mob/living/M, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	..()
	if(!isliving(M) || iscarbon(M))
		return
	zaukerite_shard_consume_strike(src, M, user)

/obj/item/zaukerite_shard/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	var/mob/living/target = isliving(hit_atom) ? hit_atom : null
	var/mob/living/thrower = throwingdatum?.thrower
	var/result = ..()
	if(QDELETED(src) || !target || result == BLOCK_SUCCESS)
		return result
	zaukerite_shard_consume_strike(src, target, thrower, thrown = TRUE)
	return result

/obj/item/proc/on_zaukerite_melee_strike(datum/source, mob/living/victim, mob/user, obj/item/bodypart/affecting)
	SIGNAL_HANDLER
	zaukerite_shard_consume_strike(src, victim, user)

/proc/zaukerite_shard_consume_strike(obj/item/weapon, mob/living/victim, mob/living/attacker, thrown = FALSE)
	if(QDELETED(weapon) || !isliving(victim))
		return
	if(!crystal_shard_roll_strike_proc(weapon, thrown, weapon.armour_penetration, victim, attacker))
		return
	var/amount = ZAUKERITE_SHARD_ZAUKER_AMOUNT
	var/wrapped = istype(weapon, /obj/item/zaukerite_shard)
	if(isliving(victim))
		zaukerite_shard_inject(victim, amount)
	if(!thrown && !wrapped && isliving(attacker) && victim != attacker && prob(25))
		zaukerite_shard_inject(attacker, amount)
		attacker.visible_message(
			span_warning("The [weapon] splinters apart, releasing toxic zauker dust onto [attacker]!"),
			span_userdanger("The [weapon] splinters apart, and you breathe in toxic zauker dust!"),
		)
	qdel(weapon)

/proc/zaukerite_shard_inject(mob/living/target, amount)
	crystal_shard_inject(target, /datum/reagent/zauker, amount)

// === N2O shard (raw + cloth-wrapped weapon) ===
#define N2O_SHARD_N2O_AMOUNT 10

/obj/item/shard/n2o
	name = "N2O shard"
	desc = "A jagged shard of crystallized nitrous oxide. Extremely sharp and unstable."
	icon = 'icons/obj/crystallizer_exploration.dmi'
	icon_state = "N2O_sharp"
	item_state = "shard-glass"
	force = 7
	throwforce = 12
	armour_penetration = 15
	sharpness = SHARP_EDGED
	attack_verb = list("stabbed", "slashed", "sliced", "cut")
	embedding = null
	craft_time = 14 SECONDS
	custom_materials = null

/obj/item/shard/n2o/Initialize(mapload)
	. = ..()
	icon_state = "N2O_sharp"
	pixel_x = 0
	pixel_y = 0
	RegisterSignal(src, COMSIG_ITEM_ATTACK_ZONE, PROC_REF(on_n2o_melee_strike))

/obj/item/shard/n2o/attack(mob/living/M, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	..()
	if(!isliving(M) || iscarbon(M))
		return
	n2o_shard_consume_strike(src, M, user)

/obj/item/shard/n2o/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	var/mob/living/target = isliving(hit_atom) ? hit_atom : null
	var/mob/living/thrower = throwingdatum?.thrower
	var/result = ..()
	if(QDELETED(src) || !target || result == BLOCK_SUCCESS)
		return result
	n2o_shard_consume_strike(src, target, thrower, thrown = TRUE)
	return result

/obj/item/shard/n2o/attackby(obj/item/item, mob/user, params)
	if(istype(item, /obj/item/stack/sheet/cloth))
		var/obj/item/stack/sheet/cloth/cloth = item
		to_chat(user, span_notice("You begin to wrap the [cloth] around the [src]..."))
		if(do_after(user, craft_time, target = src))
			var/obj/item/n2o_shard/wrapped = new
			cloth.use(1)
			to_chat(user, span_notice("You wrap the [cloth] around the [src], forming a makeshift weapon."))
			remove_item_from_storage(src, user)
			qdel(src)
			user.put_in_hands(wrapped)
		return
	return ..()

/obj/item/n2o_shard
	name = "N2O shard"
	desc = "A nitrous oxide crystal shard wrapped in cloth. One strike floods the victim with N2O before the shard crumbles."
	icon = 'icons/obj/crystallizer_exploration.dmi'
	icon_state = "N2O_shard"
	item_state = "shard-glass"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	force = 7
	throwforce = 12
	armour_penetration = 15
	w_class = WEIGHT_CLASS_TINY
	sharpness = SHARP_EDGED
	attack_verb = list("stabbed", "slashed", "sliced", "cut")
	hitsound = 'sound/weapons/bladeslice.ogg'
	embedding = null

/obj/item/n2o_shard/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_ITEM_ATTACK_ZONE, PROC_REF(on_n2o_melee_strike))

/obj/item/n2o_shard/attack(mob/living/M, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	..()
	if(!isliving(M) || iscarbon(M))
		return
	n2o_shard_consume_strike(src, M, user)

/obj/item/n2o_shard/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	var/mob/living/target = isliving(hit_atom) ? hit_atom : null
	var/mob/living/thrower = throwingdatum?.thrower
	var/result = ..()
	if(QDELETED(src) || !target || result == BLOCK_SUCCESS)
		return result
	n2o_shard_consume_strike(src, target, thrower, thrown = TRUE)
	return result

/obj/item/proc/on_n2o_melee_strike(datum/source, mob/living/victim, mob/user, obj/item/bodypart/affecting)
	SIGNAL_HANDLER
	n2o_shard_consume_strike(src, victim, user)

/proc/n2o_shard_consume_strike(obj/item/weapon, mob/living/victim, mob/living/attacker, thrown = FALSE)
	if(QDELETED(weapon) || !isliving(victim))
		return
	if(!crystal_shard_roll_strike_proc(weapon, thrown, weapon.armour_penetration, victim, attacker))
		return
	var/amount = N2O_SHARD_N2O_AMOUNT
	var/wrapped = istype(weapon, /obj/item/n2o_shard)
	if(isliving(victim))
		n2o_shard_inject(victim, amount)
	if(!thrown && !wrapped && isliving(attacker) && victim != attacker && prob(25))
		n2o_shard_inject(attacker, amount)
		attacker.visible_message(
			span_warning("The [weapon] splinters apart, releasing a puff of nitrous oxide onto [attacker]!"),
			span_userdanger("The [weapon] splinters apart, and you breathe in nitrous oxide!"),
		)
	qdel(weapon)

/proc/n2o_shard_inject(mob/living/target, amount)
	crystal_shard_inject(target, /datum/reagent/nitrous_oxide, amount)

// === Healium shard (raw + cloth-wrapped weapon) ===
#define HEALIUM_SHARD_HEALIUM_AMOUNT 10

/obj/item/shard/healium
	name = "Healium shard"
	desc = "A jagged shard of crystallized healium. Extremely sharp and unstable."
	icon = 'icons/obj/crystallizer_exploration.dmi'
	icon_state = "Healium_sharp"
	item_state = "shard-glass"
	force = 7
	throwforce = 12
	armour_penetration = 100
	sharpness = SHARP_EDGED
	attack_verb = list("stabbed", "slashed", "sliced", "cut")
	embedding = null
	craft_time = 14 SECONDS
	custom_materials = null

/obj/item/shard/healium/Initialize(mapload)
	. = ..()
	icon_state = "Healium_sharp"
	pixel_x = 0
	pixel_y = 0
	RegisterSignal(src, COMSIG_ITEM_ATTACK_ZONE, PROC_REF(on_healium_melee_strike))

/obj/item/shard/healium/attack(mob/living/M, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	..()
	if(!isliving(M) || iscarbon(M))
		return
	healium_shard_consume_strike(src, M, user)

/obj/item/shard/healium/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	var/mob/living/target = isliving(hit_atom) ? hit_atom : null
	var/mob/living/thrower = throwingdatum?.thrower
	var/result = ..()
	if(QDELETED(src) || !target || result == BLOCK_SUCCESS)
		return result
	healium_shard_consume_strike(src, target, thrower, thrown = TRUE)
	return result

/obj/item/shard/healium/attackby(obj/item/item, mob/user, params)
	if(istype(item, /obj/item/stack/sheet/cloth))
		var/obj/item/stack/sheet/cloth/cloth = item
		to_chat(user, span_notice("You begin to wrap the [cloth] around the [src]..."))
		if(do_after(user, craft_time, target = src))
			var/obj/item/healium_shard/wrapped = new
			cloth.use(1)
			to_chat(user, span_notice("You wrap the [cloth] around the [src], forming a makeshift weapon."))
			remove_item_from_storage(src, user)
			qdel(src)
			user.put_in_hands(wrapped)
		return
	return ..()

/obj/item/healium_shard
	name = "Healium shard"
	desc = "A healium crystal shard wrapped in cloth. One strike floods the victim with healium before the shard crumbles."
	icon = 'icons/obj/crystallizer_exploration.dmi'
	icon_state = "Healium_shard"
	item_state = "shard-glass"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	force = 7
	throwforce = 12
	armour_penetration = 100
	w_class = WEIGHT_CLASS_TINY
	sharpness = SHARP_EDGED
	attack_verb = list("stabbed", "slashed", "sliced", "cut")
	hitsound = 'sound/weapons/bladeslice.ogg'
	embedding = null

/obj/item/healium_shard/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_ITEM_ATTACK_ZONE, PROC_REF(on_healium_melee_strike))

/obj/item/healium_shard/attack(mob/living/M, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	..()
	if(!isliving(M) || iscarbon(M))
		return
	healium_shard_consume_strike(src, M, user)

/obj/item/healium_shard/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	var/mob/living/target = isliving(hit_atom) ? hit_atom : null
	var/mob/living/thrower = throwingdatum?.thrower
	var/result = ..()
	if(QDELETED(src) || !target || result == BLOCK_SUCCESS)
		return result
	healium_shard_consume_strike(src, target, thrower, thrown = TRUE)
	return result

/obj/item/proc/on_healium_melee_strike(datum/source, mob/living/victim, mob/user, obj/item/bodypart/affecting)
	SIGNAL_HANDLER
	healium_shard_consume_strike(src, victim, user)

/proc/healium_shard_consume_strike(obj/item/weapon, mob/living/victim, mob/living/attacker, thrown = FALSE)
	if(QDELETED(weapon) || !isliving(victim))
		return
	if(!crystal_shard_roll_strike_proc(weapon, thrown, weapon.armour_penetration, victim, attacker))
		return
	var/amount = HEALIUM_SHARD_HEALIUM_AMOUNT
	var/wrapped = istype(weapon, /obj/item/healium_shard)
	if(isliving(victim))
		healium_shard_inject(victim, amount)
	if(!thrown && !wrapped && isliving(attacker) && victim != attacker && prob(25))
		healium_shard_inject(attacker, amount)
		attacker.visible_message(
			span_warning("The [weapon] splinters apart, releasing a puff of healium onto [attacker]!"),
			span_userdanger("The [weapon] splinters apart, and you breathe in healium!"),
		)
	qdel(weapon)

/proc/healium_shard_inject(mob/living/target, amount)
	crystal_shard_inject(target, /datum/reagent/healium, amount)

// === Hypernoblium shard (raw + cloth-wrapped weapon) ===
#define HYPERNOBLIUM_SHARD_AMOUNT 10

/obj/item/shard/hypernoblium
	name = "hypernoblium shard"
	desc = "A jagged shard of crystallized hypernoblium. Extremely sharp and unstable."
	icon = 'icons/obj/crystallizer_crystal_shards.dmi'
	icon_state = "hypernoblium_sharp"
	item_state = "shard-glass"
	force = 7
	throwforce = 12
	armour_penetration = 100
	sharpness = SHARP_EDGED
	attack_verb = list("stabbed", "slashed", "sliced", "cut")
	embedding = null
	craft_time = 14 SECONDS
	custom_materials = null

/obj/item/shard/hypernoblium/Initialize(mapload)
	. = ..()
	icon_state = "hypernoblium_sharp"
	pixel_x = 0
	pixel_y = 0
	RegisterSignal(src, COMSIG_ITEM_ATTACK_ZONE, PROC_REF(on_hypernoblium_melee_strike))

/obj/item/shard/hypernoblium/attack(mob/living/M, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	..()
	if(!isliving(M) || iscarbon(M))
		return
	hypernoblium_shard_consume_strike(src, M, user)

/obj/item/shard/hypernoblium/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	var/mob/living/target = isliving(hit_atom) ? hit_atom : null
	var/mob/living/thrower = throwingdatum?.thrower
	var/result = ..()
	if(QDELETED(src) || !target || result == BLOCK_SUCCESS)
		return result
	hypernoblium_shard_consume_strike(src, target, thrower, thrown = TRUE)
	return result

/obj/item/shard/hypernoblium/attackby(obj/item/item, mob/user, params)
	if(istype(item, /obj/item/stack/sheet/cloth))
		var/obj/item/stack/sheet/cloth/cloth = item
		to_chat(user, span_notice("You begin to wrap the [cloth] around the [src]..."))
		if(do_after(user, craft_time, target = src))
			var/obj/item/hypernoblium_shard/wrapped = new
			cloth.use(1)
			to_chat(user, span_notice("You wrap the [cloth] around the [src], forming a makeshift weapon."))
			remove_item_from_storage(src, user)
			qdel(src)
			user.put_in_hands(wrapped)
		return
	return ..()

/obj/item/hypernoblium_shard
	name = "hypernoblium shard"
	desc = "A hypernoblium crystal shard wrapped in cloth. One strike floods the victim with hypernoblium before the shard crumbles."
	icon = 'icons/obj/crystallizer_crystal_shards.dmi'
	icon_state = "hypernoblium_shard"
	item_state = "shard-glass"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	force = 7
	throwforce = 12
	armour_penetration = 100
	w_class = WEIGHT_CLASS_TINY
	sharpness = SHARP_EDGED
	attack_verb = list("stabbed", "slashed", "sliced", "cut")
	hitsound = 'sound/weapons/bladeslice.ogg'
	embedding = null

/obj/item/hypernoblium_shard/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_ITEM_ATTACK_ZONE, PROC_REF(on_hypernoblium_melee_strike))

/obj/item/hypernoblium_shard/attack(mob/living/M, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	..()
	if(!isliving(M) || iscarbon(M))
		return
	hypernoblium_shard_consume_strike(src, M, user)

/obj/item/hypernoblium_shard/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	var/mob/living/target = isliving(hit_atom) ? hit_atom : null
	var/mob/living/thrower = throwingdatum?.thrower
	var/result = ..()
	if(QDELETED(src) || !target || result == BLOCK_SUCCESS)
		return result
	hypernoblium_shard_consume_strike(src, target, thrower, thrown = TRUE)
	return result

/obj/item/proc/on_hypernoblium_melee_strike(datum/source, mob/living/victim, mob/user, obj/item/bodypart/affecting)
	SIGNAL_HANDLER
	hypernoblium_shard_consume_strike(src, victim, user)

/proc/hypernoblium_shard_consume_strike(obj/item/weapon, mob/living/victim, mob/living/attacker, thrown = FALSE)
	if(QDELETED(weapon) || !isliving(victim))
		return
	if(!crystal_shard_roll_strike_proc(weapon, thrown, weapon.armour_penetration, victim, attacker))
		return
	var/amount = HYPERNOBLIUM_SHARD_AMOUNT
	var/wrapped = istype(weapon, /obj/item/hypernoblium_shard)
	if(isliving(victim))
		hypernoblium_shard_inject(victim, amount)
	if(!thrown && !wrapped && isliving(attacker) && victim != attacker && prob(25))
		hypernoblium_shard_inject(attacker, amount)
		attacker.visible_message(
			span_warning("The [weapon] splinters apart, releasing a puff of hypernoblium onto [attacker]!"),
			span_userdanger("The [weapon] splinters apart, and you breathe in hypernoblium!"),
		)
	qdel(weapon)

/proc/hypernoblium_shard_inject(mob/living/target, amount)
	crystal_shard_inject(target, /datum/reagent/hypernoblium, amount)

// === Nitrium shard (raw + cloth-wrapped weapon) ===
#define NITRIUM_SHARD_AMOUNT 10

/obj/item/shard/nitrium
	name = "nitrium shard"
	desc = "A jagged shard of crystallized nitrium. Extremely sharp and unstable."
	icon = 'icons/obj/crystallizer_crystal_shards.dmi'
	icon_state = "nitrium_sharp"
	item_state = "shard-glass"
	force = 7
	throwforce = 12
	armour_penetration = 15
	sharpness = SHARP_EDGED
	attack_verb = list("stabbed", "slashed", "sliced", "cut")
	embedding = null
	craft_time = 14 SECONDS
	custom_materials = null

/obj/item/shard/nitrium/Initialize(mapload)
	. = ..()
	icon_state = "nitrium_sharp"
	pixel_x = 0
	pixel_y = 0
	RegisterSignal(src, COMSIG_ITEM_ATTACK_ZONE, PROC_REF(on_nitrium_melee_strike))

/obj/item/shard/nitrium/attack(mob/living/M, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	..()
	if(!isliving(M) || iscarbon(M))
		return
	nitrium_shard_consume_strike(src, M, user)

/obj/item/shard/nitrium/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	var/mob/living/target = isliving(hit_atom) ? hit_atom : null
	var/mob/living/thrower = throwingdatum?.thrower
	var/result = ..()
	if(QDELETED(src) || !target || result == BLOCK_SUCCESS)
		return result
	nitrium_shard_consume_strike(src, target, thrower, thrown = TRUE)
	return result

/obj/item/shard/nitrium/attackby(obj/item/item, mob/user, params)
	if(istype(item, /obj/item/stack/sheet/cloth))
		var/obj/item/stack/sheet/cloth/cloth = item
		to_chat(user, span_notice("You begin to wrap the [cloth] around the [src]..."))
		if(do_after(user, craft_time, target = src))
			var/obj/item/nitrium_shard/wrapped = new
			cloth.use(1)
			to_chat(user, span_notice("You wrap the [cloth] around the [src], forming a makeshift weapon."))
			remove_item_from_storage(src, user)
			qdel(src)
			user.put_in_hands(wrapped)
		return
	return ..()

/obj/item/nitrium_shard
	name = "nitrium shard"
	desc = "A nitrium crystal shard wrapped in cloth. One strike floods the victim with nitrium before the shard crumbles."
	icon = 'icons/obj/crystallizer_crystal_shards.dmi'
	icon_state = "nitrium_shard"
	item_state = "shard-glass"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	force = 7
	throwforce = 12
	armour_penetration = 15
	w_class = WEIGHT_CLASS_TINY
	sharpness = SHARP_EDGED
	attack_verb = list("stabbed", "slashed", "sliced", "cut")
	hitsound = 'sound/weapons/bladeslice.ogg'
	embedding = null

/obj/item/nitrium_shard/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_ITEM_ATTACK_ZONE, PROC_REF(on_nitrium_melee_strike))

/obj/item/nitrium_shard/attack(mob/living/M, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	..()
	if(!isliving(M) || iscarbon(M))
		return
	nitrium_shard_consume_strike(src, M, user)

/obj/item/nitrium_shard/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	var/mob/living/target = isliving(hit_atom) ? hit_atom : null
	var/mob/living/thrower = throwingdatum?.thrower
	var/result = ..()
	if(QDELETED(src) || !target || result == BLOCK_SUCCESS)
		return result
	nitrium_shard_consume_strike(src, target, thrower, thrown = TRUE)
	return result

/obj/item/proc/on_nitrium_melee_strike(datum/source, mob/living/victim, mob/user, obj/item/bodypart/affecting)
	SIGNAL_HANDLER
	nitrium_shard_consume_strike(src, victim, user)

/proc/nitrium_shard_consume_strike(obj/item/weapon, mob/living/victim, mob/living/attacker, thrown = FALSE)
	if(QDELETED(weapon) || !isliving(victim))
		return
	if(!crystal_shard_roll_strike_proc(weapon, thrown, weapon.armour_penetration, victim, attacker))
		return
	var/amount = NITRIUM_SHARD_AMOUNT
	var/wrapped = istype(weapon, /obj/item/nitrium_shard)
	if(isliving(victim))
		nitrium_shard_inject(victim, amount)
	if(!thrown && !wrapped && isliving(attacker) && victim != attacker && prob(25))
		nitrium_shard_inject(attacker, amount)
		attacker.visible_message(
			span_warning("The [weapon] splinters apart, releasing a puff of nitrium onto [attacker]!"),
			span_userdanger("The [weapon] splinters apart, and you breathe in nitrium!"),
		)
	qdel(weapon)

/proc/nitrium_shard_inject(mob/living/target, amount)
	crystal_shard_inject(target, /datum/reagent/nitrium_low_metabolization, amount)

// === Proto nitrate shard (raw + cloth-wrapped weapon) ===
#define PROTO_NITRATE_SHARD_AMOUNT 10

/obj/item/shard/proto_nitrate
	name = "proto nitrate shard"
	desc = "A jagged shard of crystallized proto nitrate. Extremely sharp and unstable."
	icon = 'icons/obj/crystallizer_crystal_shards.dmi'
	icon_state = "proto_nitrate_sharp"
	item_state = "shard-glass"
	force = 7
	throwforce = 12
	armour_penetration = 20
	sharpness = SHARP_EDGED
	attack_verb = list("stabbed", "slashed", "sliced", "cut")
	embedding = null
	craft_time = 14 SECONDS
	custom_materials = null

/obj/item/shard/proto_nitrate/Initialize(mapload)
	. = ..()
	icon_state = "proto_nitrate_sharp"
	pixel_x = 0
	pixel_y = 0
	RegisterSignal(src, COMSIG_ITEM_ATTACK_ZONE, PROC_REF(on_proto_nitrate_melee_strike))

/obj/item/shard/proto_nitrate/attack(mob/living/M, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	..()
	if(!isliving(M) || iscarbon(M))
		return
	proto_nitrate_shard_consume_strike(src, M, user)

/obj/item/shard/proto_nitrate/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	var/mob/living/target = isliving(hit_atom) ? hit_atom : null
	var/mob/living/thrower = throwingdatum?.thrower
	var/result = ..()
	if(QDELETED(src) || !target || result == BLOCK_SUCCESS)
		return result
	proto_nitrate_shard_consume_strike(src, target, thrower, thrown = TRUE)
	return result

/obj/item/shard/proto_nitrate/attackby(obj/item/item, mob/user, params)
	if(istype(item, /obj/item/stack/sheet/cloth))
		var/obj/item/stack/sheet/cloth/cloth = item
		to_chat(user, span_notice("You begin to wrap the [cloth] around the [src]..."))
		if(do_after(user, craft_time, target = src))
			var/obj/item/proto_nitrate_shard/wrapped = new
			cloth.use(1)
			to_chat(user, span_notice("You wrap the [cloth] around the [src], forming a makeshift weapon."))
			remove_item_from_storage(src, user)
			qdel(src)
			user.put_in_hands(wrapped)
		return
	return ..()

/obj/item/proto_nitrate_shard
	name = "proto nitrate shard"
	desc = "A proto nitrate crystal shard wrapped in cloth. One strike floods the victim with radioactive proto nitrate before the shard crumbles."
	icon = 'icons/obj/crystallizer_crystal_shards.dmi'
	icon_state = "proto_nitrate_shard"
	item_state = "shard-glass"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	force = 7
	throwforce = 12
	armour_penetration = 20
	w_class = WEIGHT_CLASS_TINY
	sharpness = SHARP_EDGED
	attack_verb = list("stabbed", "slashed", "sliced", "cut")
	hitsound = 'sound/weapons/bladeslice.ogg'
	embedding = null

/obj/item/proto_nitrate_shard/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_ITEM_ATTACK_ZONE, PROC_REF(on_proto_nitrate_melee_strike))

/obj/item/proto_nitrate_shard/attack(mob/living/M, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	..()
	if(!isliving(M) || iscarbon(M))
		return
	proto_nitrate_shard_consume_strike(src, M, user)

/obj/item/proto_nitrate_shard/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	var/mob/living/target = isliving(hit_atom) ? hit_atom : null
	var/mob/living/thrower = throwingdatum?.thrower
	var/result = ..()
	if(QDELETED(src) || !target || result == BLOCK_SUCCESS)
		return result
	proto_nitrate_shard_consume_strike(src, target, thrower, thrown = TRUE)
	return result

/obj/item/proc/on_proto_nitrate_melee_strike(datum/source, mob/living/victim, mob/user, obj/item/bodypart/affecting)
	SIGNAL_HANDLER
	proto_nitrate_shard_consume_strike(src, victim, user)

/proc/proto_nitrate_shard_consume_strike(obj/item/weapon, mob/living/victim, mob/living/attacker, thrown = FALSE)
	if(QDELETED(weapon) || !isliving(victim))
		return
	if(!crystal_shard_roll_strike_proc(weapon, thrown, weapon.armour_penetration, victim, attacker))
		return
	var/amount = PROTO_NITRATE_SHARD_AMOUNT
	var/wrapped = istype(weapon, /obj/item/proto_nitrate_shard)
	if(isliving(victim))
		proto_nitrate_shard_inject(victim, amount)
	if(!thrown && !wrapped && isliving(attacker) && victim != attacker && prob(25))
		proto_nitrate_shard_inject(attacker, amount)
		attacker.visible_message(
			span_warning("The [weapon] splinters apart, releasing radioactive proto nitrate onto [attacker]!"),
			span_userdanger("The [weapon] splinters apart, and you are irradiated by proto nitrate!"),
		)
	qdel(weapon)

/proc/proto_nitrate_shard_inject(mob/living/target, amount)
	crystal_shard_inject(target, /datum/reagent/proto_nitrate, amount)

// === Crystallizer crystal microwave reactions ===
#define CRYSTALLIZER_MICROWAVE_HEAVY 2
#define CRYSTALLIZER_MICROWAVE_LIGHT 5
#define CRYSTALLIZER_MICROWAVE_FLAME 4
#define CRYSTALLIZER_MICROWAVE_GAS_RANGE 5

/proc/find_crystallizer_recipe_for_item(obj/item/item)
	for(var/recipe_id in GLOB.gas_recipe_meta)
		var/datum/gas_recipe/recipe = GLOB.gas_recipe_meta[recipe_id]
		if(recipe.machine_type != "Crystallizer" || !recipe.products)
			continue
		for(var/product_path in recipe.products)
			if(istype(item, product_path))
				return list(recipe = recipe, product_count = recipe.products[product_path])
	return null

/proc/crystallizer_crystal_microwave_release(turf/center, list/gas_amounts, release_range = CRYSTALLIZER_MICROWAVE_GAS_RANGE)
	if(!center || !length(gas_amounts))
		return
	playsound(center, 'sound/effects/spray2.ogg', 100, TRUE)
	for(var/turf/open/T in range(release_range, center))
		if(!T.air)
			continue
		var/dist = max(get_dist(T, center), 1)
		for(var/gas_id in gas_amounts)
			T.air.adjust_moles(gas_id, gas_amounts[gas_id] / dist)

/proc/crystallizer_foam_splash(turf/center)
	if(!center)
		return
	var/datum/reagents/first_batch = new(75)
	var/datum/reagents/second_batch = new(50)
	first_batch.add_reagent(/datum/reagent/aluminium, 75)
	second_batch.add_reagent(/datum/reagent/smart_foaming_agent, 25)
	second_batch.add_reagent(/datum/reagent/toxin/acid/fluacid, 25)
	chem_splash(center, 7, list(first_batch, second_batch))

/obj/item/proc/get_crystallizer_microwave_gases()
	var/list/recipe_data = find_crystallizer_recipe_for_item(src)
	if(!recipe_data)
		return list()
	var/datum/gas_recipe/recipe = recipe_data["recipe"]
	var/product_count = recipe_data["product_count"]
	var/mult = 1
	if(isstack(src))
		var/obj/item/stack/stack_item = src
		mult = stack_item.amount / product_count
	var/list/result = list()
	for(var/gas_id in recipe.requirements)
		result[gas_id] = recipe.requirements[gas_id] * mult
	return result

/obj/item/proc/crystallizer_microwave_special(turf/center)
	return

/obj/item/proc/crystallizer_microwave_detonate(obj/machinery/microwave/microwave_source, mob/microwaver)
	var/turf/T = get_turf(microwave_source || src)
	if(!T)
		return NONE
	if(microwave_source)
		microwave_source.visible_message(
			span_danger("[microwave_source] violently explodes as [src] destabilizes!"),
			span_danger("You hear a loud boom!"),
			span_danger("You hear a loud boom!"))
		microwave_source.ingredients -= src
		microwave_source.broken = 2 // REALLY_BROKEN
	else
		visible_message(span_danger("[src] violently explodes!"))
	var/list/gases = get_crystallizer_microwave_gases()
	explosion(T, devastation_range = 0, heavy_impact_range = CRYSTALLIZER_MICROWAVE_HEAVY, light_impact_range = CRYSTALLIZER_MICROWAVE_LIGHT, flame_range = CRYSTALLIZER_MICROWAVE_FLAME, adminlog = TRUE)
	crystallizer_crystal_microwave_release(T, gases)
	crystallizer_microwave_special(T)
	qdel(src)
	return COMPONENT_MICROWAVE_SUCCESS
