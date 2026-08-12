#define HEART_RESPAWN_THRESHHOLD 40
#define HEART_SPECIAL_SHADOWIFY 2

/datum/species/shadow
	// Humans cursed to stay in the darkness, lest their life forces drain. They regain health in shadow and die in light.
	name = "???"
	id = SPECIES_SHADOW
	sexes = 0
	blacklisted = 1
	ignored_by = list(/mob/living/simple_animal/hostile/faithless)
	meat = /obj/item/reagent_containers/food/snacks/meat/slab/human/mutant/shadow
	species_traits = list(NOBLOOD,NOEYES,HAS_FLESH,HAS_BONE,HAIR) // BLUEMOON CHANGE - species_traits = list(NOBLOOD,NOEYES,HAS_FLESH,HAS_BONE)
	inherent_traits = list(TRAIT_RADIMMUNE,TRAIT_VIRUSIMMUNE,TRAIT_NOBREATH)

	dangerous_existence = 1
	mutanteyes = /obj/item/organ/eyes/night_vision
	languagewhitelist = list("Shadowtongue") //Skyrat change - species language whitelist

	species_category = SPECIES_CATEGORY_SHADOW
	wings_icons = SPECIES_WINGS_SKELETAL //not sure what's more spooky for these guys - skeleton or dragon?

/datum/species/shadow/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	. = ..()
	C.AddElement(/datum/element/photosynthesis, 1, 1, 0, 0, 0, 0, SHADOW_SPECIES_LIGHT_THRESHOLD, SHADOW_SPECIES_LIGHT_THRESHOLD)

/datum/species/shadow/on_species_loss(mob/living/carbon/C)
	. = ..()
	C.RemoveElement(/datum/element/photosynthesis, 1, 1, 0, 0, 0, 0, SHADOW_SPECIES_LIGHT_THRESHOLD, SHADOW_SPECIES_LIGHT_THRESHOLD)

/datum/species/shadow/check_roundstart_eligible()
	if(SSholidays.holidays && SSholidays.holidays[HALLOWEEN])
		return TRUE
	return ..()

/datum/species/shadow/nightmare
	name = "Nightmare"
	id = SPECIES_NIGHTMARE
	limbs_id = SPECIES_SHADOW
	burnmod = 1.5
	brutemod = 0.5
	blacklisted = TRUE
	nojumpsuit = TRUE
	no_equip = list(ITEM_SLOT_MASK, ITEM_SLOT_OCLOTHING, ITEM_SLOT_GLOVES, ITEM_SLOT_FEET, ITEM_SLOT_ICLOTHING, ITEM_SLOT_SUITSTORE)
	species_traits = list(NOBLOOD,NO_UNDERWEAR,NO_DNA_COPY,NOTRANSSTING,NOEYES,HAIR)
	inherent_traits = list(TRAIT_RESISTCOLD,TRAIT_NOBREATH,TRAIT_RESISTHIGHPRESSURE,TRAIT_RESISTLOWPRESSURE,TRAIT_CHUNKYFINGERS,TRAIT_RADIMMUNE,TRAIT_VIRUSIMMUNE,TRAIT_PIERCEIMMUNE,TRAIT_NODISMEMBER,TRAIT_NOHUNGER,TRAIT_NOTHIRST,CAN_BE_OPERATED_WITHOUT_PAIN,TRAIT_NODISMEMBER)
	mutanteyes = /obj/item/organ/eyes/night_vision/nightmare
	mutant_organs = list(/obj/item/organ/heart/nightmare)
	mutant_brain = /obj/item/organ/brain/nightmare

	var/info_text = "You are a <span class='danger'><b>Nightmare</b></span>. The ability <span class='warning'>shadow walk</span> allows unlimited, unrestricted movement in the dark while activated. \
					Your <span class='warning'>light eater</span> will destroy any light producing objects you attack, as well as destroy any lights a living creature may be holding. You will automatically dodge gunfire and melee attacks when on a dark tile. If killed, you will eventually revive if left in darkness."

/datum/species/shadow/nightmare/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	. = ..()
	to_chat(C, examine_block(info_text))

	C.fully_replace_character_name("[pick(GLOB.nightmare_names)]")
// BLUEMOON ADD START - Задаем найтмеру темно-пепельные волосы
	var/mob/living/carbon/human/H = C
	H.hair_color = "333333"
	H.facial_hair_color = "333333"
	H.update_hair()
	H.grad_style = NONE
// BLUEMOON ADD END
	for(var/spell_type in subtypesof(/datum/action/cooldown/nightmare))
		var/datum/action/cooldown/spell = new spell_type(C)
		spell.Grant(C)

/datum/species/shadow/nightmare/on_species_loss(mob/living/carbon/C)
	. = ..()
	var/list/temp = LAZYCOPY(C.actions)
	for(var/datum/action/cooldown/nightmare/spell in temp)
		qdel(spell)

/datum/species/shadow/nightmare/bullet_act(obj/item/projectile/P, mob/living/carbon/human/H)
	var/turf/T = H.loc
	if(istype(T))
		var/light_amount = T.get_lumcount()
		if(light_amount < SHADOW_SPECIES_LIGHT_THRESHOLD)
			H.visible_message("<span class='danger'>[H] dances in the shadows, evading [P]!</span>")
			playsound(T, "bullet_miss", 75, 1)
			return BULLET_ACT_FORCE_PIERCE
	return ..()

/datum/species/shadow/nightmare/check_roundstart_eligible()
	return FALSE

//Organs

/obj/item/organ/brain/nightmare
	name = "tumorous mass"
	desc = "A fleshy growth that was dug out of the skull of a Nightmare."
	icon_state = "brain-x-d"
	var/obj/effect/proc_holder/spell/targeted/shadowwalk/shadowwalk

/obj/item/organ/brain/nightmare/Insert(mob/living/carbon/M, special = 0, drop_if_replaced = TRUE)
	..()
	if(M.dna.species.id != "nightmare")
		M.set_species(/datum/species/shadow/nightmare)
		visible_message("<span class='warning'>[M] thrashes as [src] takes root in [M.ru_ego()] body!</span>")
	var/obj/effect/proc_holder/spell/targeted/shadowwalk/SW = new
	M.AddSpell(SW)
	shadowwalk = SW

/obj/item/organ/brain/nightmare/Remove(special = FALSE)
	if(shadowwalk && owner)
		owner.RemoveSpell(shadowwalk)
	return ..()

/obj/item/organ/heart/nightmare
	name = "heart of darkness"
	desc = "An alien organ that twists and writhes when exposed to light."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "demon_heart-on"
	color = "#1C1C1C"
	var/respawn_progress = 0
	var/obj/item/light_eater/blade
	decay_factor = 0
	actions_types = list(/datum/action/item_action/organ_action/use) // BLUEMOON ADD - для работы /obj/item/organ/heart/nightmare/ui_action_click(mob/living/carbon/M, action)

/obj/item/organ/heart/nightmare/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/update_icon_blocker)

/obj/item/organ/heart/nightmare/attack(mob/M, mob/living/carbon/user, obj/target)
	if(M != user)
		return ..()
	user.visible_message("<span class='warning'>[user] raises [src] to [user.ru_ego()] mouth and tears into it with [user.ru_ego()] teeth!</span>", \
						 "<span class='danger'>[src] feels unnaturally cold in your hands. You raise [src] your mouth and devour it!</span>")
	playsound(user, 'sound/magic/demon_consume.ogg', 50, 1)


	user.visible_message("<span class='warning'>Blood erupts from [user]'s arm as it reforms into a weapon!</span>", \
						 "<span class='userdanger'>Icy blood pumps through your veins as your arm reforms itself!</span>")
	user.temporarilyRemoveItemFromInventory(src, TRUE)
	Insert(user)

/obj/item/organ/heart/nightmare/Remove(special = FALSE)
	respawn_progress = 0
	if(!QDELETED(owner) && blade && special != HEART_SPECIAL_SHADOWIFY)
		owner.visible_message("<span class='warning'>\The [blade] disintegrates!</span>")
		QDEL_NULL(blade)
	return ..()

/obj/item/organ/heart/nightmare/Stop()
	return FALSE

/obj/item/organ/heart/nightmare/on_death()
	if(!owner)
		return
	var/turf/T = get_turf(owner)
	if(istype(T))
		var/light_amount = T.get_lumcount()
		if(light_amount < SHADOW_SPECIES_LIGHT_THRESHOLD)
			respawn_progress++
			playsound(owner,'sound/effects/singlebeat.ogg',40,1)
	if(respawn_progress >= HEART_RESPAWN_THRESHHOLD)
		owner.revive(full_heal = TRUE)
		if(!(owner.dna.species.id == SPECIES_SHADOW || owner.dna.species.id == SPECIES_NIGHTMARE))
			var/mob/living/carbon/old_owner = owner
			Remove(HEART_SPECIAL_SHADOWIFY)
			old_owner.set_species(/datum/species/shadow)
			Insert(old_owner, HEART_SPECIAL_SHADOWIFY)
			to_chat(owner, "<span class='userdanger'>You feel the shadows invade your skin, leaping into the center of your chest! You're alive!</span>")
			SEND_SOUND(owner, sound('sound/effects/ghost.ogg'))
		owner.visible_message("<span class='warning'>[owner] staggers to [owner.ru_ego()] feet!</span>")
		playsound(owner, 'sound/hallucinations/far_noise.ogg', 50, 1)
		respawn_progress = 0

/obj/item/organ/heart/nightmare/ui_action_click(mob/living/carbon/M, action)
	if(QDELETED(blade))
		blade = new(src)
	if(blade.loc == src)
		M.put_in_hands(blade, forced = TRUE)
	else
		blade.forceMove(src)
	playsound(M, 'sound/effects/blobattack.ogg', 30, 1)

//Weapon

/obj/item/light_eater
	name = "light eater" //as opposed to heavy eater
	icon_state = "arm_blade"
	item_state = "arm_blade"
	force = 30
	armour_penetration = 25
	stuttering = 5
	lefthand_file = 'icons/mob/inhands/antag/changeling_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/antag/changeling_righthand.dmi'
	item_flags = ABSTRACT
	resistance_flags = FIRE_PROOF | ON_FIRE | UNACIDABLE | ACID_PROOF
	w_class = WEIGHT_CLASS_HUGE
	hitsound = 'sound/weapons/bladeslice.ogg'
	usesound = 'sound/items/crowbar.ogg'
	attack_verb = list("attacked", "slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	sharpness = SHARP_EDGED
	total_mass = TOTAL_MASS_HAND_REPLACEMENT
	tool_behaviour = TOOL_CROWBAR
	can_force_powered = TRUE

/obj/item/light_eater/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, HAND_REPLACEMENT_TRAIT)
	AddComponent(/datum/component/butchering, 80, 70)

/obj/item/light_eater/afterattack(atom/movable/AM, mob/user, proximity)
	. = ..()
	if(!proximity)
		return
	if(isopenturf(AM))
		var/turf/open/T = AM
		if(T.light_range && !isspaceturf(T)) //no fairy grass or light tile can escape the fury of the darkness.
			to_chat(user, "<span class='notice'>You scrape away [T] with your [name] and snuff out its lights.</span>")
			T.ScrapeAway(flags = CHANGETURF_INHERIT_AIR)
	else if(is_cleanable(AM))
		var/obj/effect/E = AM
		if(E.light_range && E.light_power)
			disintegrate(E)
	else if(isliving(AM))
		var/mob/living/L = AM
		if(isethereal(AM))
			AM.emp_act(50)
		if(iscyborg(AM))
			var/mob/living/silicon/robot/borg = AM
			if(borg.lamp_enabled)
				borg.smash_headlamp()
		else
			for(var/obj/item/O in AM)
				if(O.light_range && O.light_power)
					disintegrate(O)
		if(L.pulling && L.pulling.light_range && isitem(L.pulling))
			disintegrate(L.pulling)
	else if(istype(AM, /obj/structure/glowshroom) || istype(AM, /obj/structure/marker_beacon))
		qdel(AM)
		visible_message(span_danger("[AM] is disintegrated by [src]!</span>"))
	else if(isitem(AM) && AM.light_range && AM.light_power)
		disintegrate(AM)
		return

/obj/item/light_eater/get_damage_to_obj(obj/O, mob/living/user)
	. = ..()
	var/damage_multiplier = 3.5
	if(istype(O, /obj/machinery/power/apc) || istype(O, /obj/machinery/airalarm))
		damage_multiplier = 2.5
	else if(O.light_range && O.light_power)
		damage_multiplier = 5

	. *= damage_multiplier

#define NIGHTMARE_LIGHT_OFF_PROC(atom_to_off) \
	var/atom/movable/true_atom_to_off = astype(atom_to_off); \
	if(true_atom_to_off){ \
		if(istype(true_atom_to_off, /obj/machinery/light)) { \
			var/obj/machinery/light/light = true_atom_to_off; \
			. = light.break_light_tube(); \
		} \
		else if(istype(true_atom_to_off, /obj/item/modular_computer/pda)) { \
			var/obj/item/modular_computer/pda/PDA = true_atom_to_off; \
			PDA.set_light_on(FALSE); \
			PDA.fon = FALSE; \
			PDA.update_icon(); \
			. = TRUE; \
		} \
		else if(istype(true_atom_to_off, /obj/item/gun)) { \
			var/obj/item/gun/weapon = true_atom_to_off; \
			if(weapon.gun_light) { \
				var/obj/item/flashlight/seclite/light = weapon.gun_light; \
				light.forceMove(get_turf(weapon)); \
				light.burn(); \
				weapon.gun_light = null; \
				weapon.update_gunlight(); \
				QDEL_NULL(weapon.alight); \
				weapon.visible_message(span_danger("[light] on [true_atom_to_off] flickers out and disintegrates!")); \
				. = TRUE; \
			}; \
		} \
		else if(true_atom_to_off.light_range && true_atom_to_off.light_power) { \
			if(IS_OVERLAY_LIGHT_SYSTEM(true_atom_to_off.light_system)) \
				true_atom_to_off.set_light_on(FALSE); \
			else \
				true_atom_to_off.set_light(0); \
			. = TRUE; \
		}; \
	}; \

/obj/item/light_eater/proc/disintegrate(obj/item/O)
	NIGHTMARE_LIGHT_OFF_PROC(O)
	playsound(src, 'sound/items/welder.ogg', 50, 1)

/datum/action/cooldown/nightmare
	name = "Some nightmare action (You shouldn't see this)"
	icon_icon = 'icons/mob/actions/actions.dmi'

/datum/action/cooldown/nightmare/darkness
	name = "Great Darkness"
	desc = "Восславь Тьму и уничтожь извечного врага её."
	button_icon_state = "vampire_extinguish"
	cooldown_time = 60 SECONDS
	var/const/aoe_radius = 7

/datum/action/cooldown/nightmare/darkness/Activate(atom/target)
	var/list/pre_targets = range(aoe_radius, owner)
	var/list/targets = list()
	for(var/atom/movable/atom_target in pre_targets)
		CHECK_TICK
		for(var/atom/movable/AM as anything in atom_target.GetAllContents())
			if(!istype(AM, /obj/machinery/light) && !istype(AM, /obj/item/gun) && (!AM.light_range || !AM.light_power))
				continue
			targets += AM
	if(!targets.len)
		return
	var/success = FALSE
	for(var/atom/movable/AM as anything in targets)
		NIGHTMARE_LIGHT_OFF_PROC(AM)
		if(.)
			success++
	if(!success)
		return
	StartCooldown()
	if(prob(80))
		playsound(get_turf(owner), 'sound/effects/screech.ogg', 100, TRUE)
	else
		var/static/list/temp_sounds = list(
			'sound/hallucinations/im_here1.ogg',
			'sound/hallucinations/im_here2.ogg',
			'sound/hallucinations/behind_you1.ogg',
			'sound/hallucinations/behind_you2.ogg',
			'sound/hallucinations/i_see_you1.ogg',
			'sound/hallucinations/i_see_you2.ogg',
			'sound/hallucinations/look_up1.ogg',
			'sound/hallucinations/look_up2.ogg',
			'sound/hallucinations/over_here1.ogg',
			'sound/hallucinations/over_here2.ogg',
			'sound/hallucinations/over_here3.ogg',
			'sound/hallucinations/turn_around1.ogg',
			'sound/hallucinations/turn_around2.ogg',
		)
		playsound(get_turf(owner), pick(temp_sounds), 100, FALSE)

#undef HEART_SPECIAL_SHADOWIFY
#undef HEART_RESPAWN_THRESHHOLD
#undef NIGHTMARE_LIGHT_OFF_PROC
