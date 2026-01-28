/obj/item/clothing/under/syndicate/centcom
	name = "green turtleneck"
	icon_state = "centcom_t"
	item_state = "centcom_t"

/obj/item/clothing/under/syndicate/skirt/centcom
	name = "green skirtleneck"
	icon_state = "centcom_t_skirt"
	item_state = "centcom_t_skirt"

/obj/item/clothing/under/syndicate/brigdoc
	name = "red turtleneck"
	icon_state = "security_medic_turtleneck"
	item_state = "security_medic_turtleneck"
	has_sensor = 3

/obj/item/clothing/under/syndicate/skirt/brigdoc
	name = "red skirtleneck"
	icon_state = "security_medic_turtleneck_skirt"
	item_state = "security_medic_turtleneck_skirt"

/obj/item/clothing/under/rank/security/officer/tacticool
	name = "tacticool security jumpsuit"
	icon_state = "tacticool_sec"
	item_state = "tacticool_sec"
	unique_reskin = list(
		"Blue" = list("icon_state" = "tacticool_sec_blue", "item_state" = "tacticool_sec_blue"),
		"Black" = list("icon_state" = "tacticool_sec_black", "item_state" = "tacticool_sec_black"),
		"Pink" = list("icon_state" = "tacticool_sec_pink", "item_state" = "tacticool_sec_pink"),
	) ///bluemoon add

/obj/item/clothing/suit/armor/vest/agent
	name = "agent armored vest"
	desc = "A Type II armored vest that provides protection against most types of damage. This one is used by the Internal Affairs Agents."
	icon_state = "agent"
	item_state = "agent"
	dog_fashion = null
	armor = list("melee" = 50, "bullet" = 40, "laser" = 40, "energy" = 45, "bomb" = 25, "bio" = 0, "rad" = 0, "fire" = 70, "acid" = 90, "wound" = 40)

/obj/item/clothing/head/helmet/flakhelm	//Actually the M1 Helmet
	name = "flak helmet"
	icon_state = "m1helm"
	item_state = "m1helm"
	desc = "A dilapidated helmet used in ancient wars. This one is brittle and essentially useless. An ace of spades is tucked into the band around the outer shell."
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/tiny/spacenam	//So you can stuff other things in the elastic band instead of it simply being a fluff thing.

/obj/item/clothing/head/helmet/russian_green_helmet
	name = "6b79 helmet"
	icon_state = "russian_green_helmet"
	item_state = "russian_green_helmet"
	desc = "One of the newest NRI helmets, also widely spread asross space corporations security forces."
	icon = 'modular_bluemoon/kovac_shitcode/icons/rus/obj_rus.dmi'
	mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/rus/mob_rus.dmi'

/obj/item/clothing/head/helmet/aviator_helmet
	name = "aviator helmet"
	icon_state = "avipilotdown"
	item_state = "avipilotdown"
	desc = "Touch the skies and above!"

/obj/item/clothing/head/helmet/aviator_helmet/no_armor
	armor = list("melee" = 0, "bullet" = 0, "laser" = 0, "energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 0, "acid" = 0, "wound" = 0)

/obj/item/clothing/head/helmet/blast_helmet
	name = "blast helmet"
	icon_state = "blast_helmet"
	item_state = "blast_helmet"
	desc = "Generic heavy troopers helmet. Reinforced parts and plates were replaced with simpler parts."

/obj/item/clothing/suit/chaplain/clownpriest
	name = "honkmother garb"
	desc = "This outfit makes you proud of being clown mate."
	icon_state = "clownpriest"
	item_state = "clownpriest"
	body_parts_covered = CHEST|GROIN|LEGS|ARMS
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/chaplain/shrinehand
	name = "shrinehand garb"
	desc = "Siddhartha Gautama - Superstar."
	icon_state = "shrinehand"
	item_state = "shrinehand"
	body_parts_covered = CHEST|GROIN|LEGS|ARMS
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/head/clownmitre
	name = "clown mitre"
	desc = "A mitre, worn by Honkmother faith servants."
	icon_state = "clownmitre"
	item_state = "clownmitre"
	flags_inv = HIDEHAIR

/obj/item/clothing/mask/gas/nri
	name = "NRI Gas Mask"
	desc = "An additional part of 6b79 helmet, provided with wide clear visor and simple breathing systems."
	alternate_screams = RUSSIAN_SCREAMS
	icon_state = "nri_gas"
	item_state = "nri_gas"
	flags_inv = HIDEFACE|HIDEFACIALHAIR|HIDESNOUT
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	icon = 'modular_bluemoon/kovac_shitcode/icons/rus/obj_rus.dmi'
	mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/rus/mob_rus.dmi'

/obj/item/storage/backpack/rucksack
	name = "Rucksack"
	icon_state = "rucksack"
	item_state = "rucksack"

/obj/item/storage/backpack/rucksack/blue
	icon_state = "rucksack_blue"
	item_state = "rucksack_blue"

/obj/item/storage/backpack/rucksack/green
	icon_state = "rucksack_green"
	item_state = "rucksack_green"

/obj/item/storage/backpack/rucksack/navy
	icon_state = "rucksack_navy"
	item_state = "rucksack_navy"

/obj/item/storage/backpack/rucksack/tan
	icon_state = "rucksack_tan"
	item_state = "rucksack_tan"

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//// Vox suits and weapons (tau ceti). Sprites by deadmodo and coiscin /////////////////////

// Base
/obj/item/clothing/suit/space/vox
	w_class = WEIGHT_CLASS_TINY
	allowed = list(/obj/item/gun, /obj/item/melee, /obj/item/restraints, /obj/item/tank)
	slowdown = 0.7
	armor = list(MELEE = 60, BULLET = 50, LASER = 40, ENERGY = 15, BOMB = 30, BIO = 30, RAD = 30)
	heat_protection = CHEST|GROIN|LEGS|ARMS
	max_heat_protection_temperature = SPACE_SUIT_MAX_TEMP_PROTECT
	species_restricted = list("Vox")
	tail_state = ""

/obj/item/clothing/head/helmet/space/vox
	armor = list(MELEE = 60, BULLET = 50, LASER = 40, ENERGY = 15, BOMB = 30, BIO = 30, RAD = 30)
	flags_cover = NONE
	species_restricted = list("Vox")

/////////////////////////////////////////////////////////////////////////////////////////////// Stealth suit
#define MAX_STEALTH_SPACESUIT_CHARGE 300
#define IS_VOX_SUIT_STEALTH(action) (istype(action, /datum/action/item_action/vox_stealth))

/obj/item/clothing/head/helmet/space/vox/stealth
	name = "alien stealth helmet"
	icon_state = "vox-stealth"
	item_state = "vox-stealth"
	desc = "A smoothly contoured, matte-black alien helmet."

	armor = list(MELEE = 25, BULLET = 25, LASER = 20, ENERGY = 5, BOMB = 15, BIO = 30, RAD = 30)

/obj/item/clothing/suit/space/vox/stealth
	name = "alien stealth suit"
	icon_state = "vox-stealth"
	item_state = "vox-stealth"
	desc = "A sleek black suit. it seems to be rather heavy."

	armor = list(MELEE = 25, BULLET = 25, LASER = 20, ENERGY = 5, BOMB = 15, BIO = 30, RAD = 30)

	slowdown = 1.4
	actions_types = list(/datum/action/item_action/vox_stealth)
	var/on = FALSE
	var/mob/living/carbon/human/wearer
	var/current_charge = MAX_STEALTH_SPACESUIT_CHARGE
	var/last_try = 0

////
/datum/action/item_action/vox_stealth
	name = "Toggle Stealth"
	desc = "Toggles stealth mode on and off."
	button_icon_state = "ninja_cloak"
	icon_icon = 'icons/mob/actions/actions_minor_antag.dmi'
///

/obj/item/clothing/suit/space/vox/stealth/ui_action_click(mob/user, action)
	if(IS_VOX_SUIT_STEALTH(action))
		toggle_stealth()
		return TRUE
	return FALSE

/obj/item/clothing/suit/space/vox/stealth/Destroy()
	STOP_PROCESSING(SSobj, src)
	wearer = null
	return ..()

/obj/item/clothing/suit/space/vox/stealth/process(damage)
	if(on)
		var/power_decrease = 2 // 5 minutes to full discharge
		if(damage > 0)
			power_decrease = 5 // 2 minutes to full discharge
		if(damage > 3)
			power_decrease = 10 // 1 minute to full discharge
		if(damage > 6)
			power_decrease = 0
			current_charge = 0
			STOP_PROCESSING(SSobj, src)
		current_charge -= power_decrease
		if(is_damaged())
			toggle_stealth(TRUE)
			return
		if(current_charge <= 0)
			current_charge = 0
			toggle_stealth(TRUE)
			return
		if(wearer)
			wearer.alpha = 6
			wearer.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
			if(current_charge <= (power_decrease * 15)) // there are 30 seconds to full discharge
				playsound(get_turf(src), 'sound/rig/loudbeep.ogg', 100, 1, 1)
				to_chat(wearer, "<span class='danger'>Малый запас энергии:</span> <span class='electronicblue'>\[ [current_charge] \]</span>")
	else
		var/power_increase = 20 // 30 seconds to full charge
		if(damage > 0)
			power_increase = 10 // 1 minutes to full charge
		if(damage > 3)
			power_increase = 5 // 2 minutes to full charge
		if(damage > 6)
			power_increase = 0
			current_charge = 0
			STOP_PROCESSING(SSobj, src)
		current_charge += power_increase
		if(current_charge > MAX_STEALTH_SPACESUIT_CHARGE)
			current_charge = 300
			STOP_PROCESSING(SSobj, src)

/obj/item/clothing/suit/space/vox/stealth/equipped(mob/user, slot)
	..()
	if(slot == ITEM_SLOT_OCLOTHING)
		wearer = user

/obj/item/clothing/suit/space/vox/stealth/dropped(mob/user)
	toggle_stealth(TRUE)
	wearer = null
	..()

/obj/item/clothing/suit/space/vox/stealth/proc/toggle_stealth(deactive = FALSE, damage)
	if(on)
		playsound(get_turf(src), 'sound/rig/stealthrig_turn_off.ogg', 100, 1, 1)
		on = FALSE
		slowdown = 0.2
		wearer.alpha = 255
		wearer.mouse_opacity = MOUSE_OPACITY_ICON
		new /obj/effect/particle_effect/sparks(get_turf(src))
		playsound(get_turf(src), "sparks", 100, 1, 1)
		new /obj/effect/temp_visual/emp/pulse(get_turf(src))
		playsound(get_turf(src), 'sound/effects/pop.ogg', 100, 1, -6)
	else if(!deactive)
		if(!istype(wearer.head, /obj/item/clothing/head/helmet/space/vox/stealth))
			to_chat(wearer, "<span class='warning'>Стелс-режим не функционален без шлема.</span>")
			return
		if(last_try > world.time)
			return
		last_try = world.time + 4 SECONDS
		to_chat(wearer, "<span class='notice'>Активация стелс-режима...</span>")
		playsound(get_turf(src), 'sound/rig/stealthrig_starting_up.ogg', 100, 1, 1)
		if(do_after(wearer, 20, target = wearer))
			if(!istype(wearer) || wearer.wear_suit != src)
				return
			if(is_damaged(TRUE))
				return
			playsound(get_turf(src), 'sound/rig/stealthrig_turn_on.ogg', 100, 1, 1)
			on = TRUE
			to_chat(wearer, "<span class='notice'>Стелс-режим активирован!</span>")
			slowdown = 1.4
			new /obj/effect/temp_visual/emp/pulse(get_turf(src))
			playsound(get_turf(src), 'sound/effects/pop.ogg', 100, 1, -6)
			wearer.alpha = 6
			wearer.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
			START_PROCESSING(SSobj, src)

/obj/item/clothing/suit/space/vox/stealth/proc/is_damaged(low_damage_check = FALSE, damage)
	if(damage > 6)
		to_chat(wearer, "<span class='warning'>[src] слишком повреждён!</span>")
		new /obj/effect/particle_effect/sparks(get_turf(src))
		playsound(get_turf(src), "sparks", 100, 1, 1)
		return TRUE
	else if(low_damage_check)
		if(prob(33) && (damage > 3))
			to_chat(wearer, "<span class='warning'>[src] повреждён и не может войти в стелс-режим!</span>")
			return TRUE
	return FALSE

/obj/item/clothing/suit/space/vox/stealth/proc/overload()
	wearer.visible_message(
	"<span class='warning'>[wearer] появляется из ниоткуда!</span>"
	)
	to_chat(wearer, "<span class='warning'>Стелс-костюм был вынужденно отключён в результате перегрузки.</span>")
	new /obj/effect/particle_effect/sparks(get_turf(src))
	playsound(get_turf(src), "sparks", 100, 1, 1)
	toggle_stealth()

/obj/item/clothing/suit/space/vox/stealth/attack_reaction(mob/living/L, reaction_type, mob/living/carbon/human/T = null, damage)
	if(on)
		if(reaction_type == REACTION_ITEM_TAKE || reaction_type == REACTION_ITEM_TAKEOFF)
			var/charge_decrease = max(rand(20, 30), round((damage * 25) + rand(1, 5)))
			current_charge -= charge_decrease
			if(wearer)
				to_chat(wearer, "<span class='warning'>Перераспраделение [charge_decrease] единиц энергии</span>. Текущий заряд: <span class='electronicblue'>\[ [current_charge] \]</span>.")
				SEND_SOUND(wearer, sound('sound/machines/defib_SaftyOn.ogg'))

			return
		overload()

#undef MAX_STEALTH_SPACESUIT_CHARGE

///////////////////////////////////////////////////////////////////////////////////////////// Medical suit

/obj/item/clothing/head/helmet/space/vox/medic
	name = "alien medical helmet"
	icon_state = "vox-medic"
	item_state = "vox-medic"
	desc = "An alien helmet with enormous lenseю"
	armor = list(MELEE = 45, BULLET = 40, LASER = 45, ENERGY = 20, BOMB = 25, BIO = 30, RAD = 30)

/obj/item/clothing/suit/space/vox/medic
	name = "alien medical armor"
	icon_state = "vox-medic"
	item_state = "vox-medic"
	desc = "A nonhuman pressure suit."
	slowdown = 0.5
	var/mob/living/carbon/human/wearer
	armor = list(MELEE = 45, BULLET = 40, LASER = 45, ENERGY = 20, BOMB = 25, BIO = 30, RAD = 30)

/obj/item/clothing/suit/space/vox/medic/equipped(mob/user, slot)
	..()
	if(slot == ITEM_SLOT_OCLOTHING)
		wearer = user
		START_PROCESSING(SSobj, src)
		playsound(get_turf(src), 'sound/rig/shortbeep.ogg', 100, 1, 1)
		to_chat(wearer, "<span class='warning'>Медицинский интерфейс загружен. Убедитесь, что на вас надет соответствующий шлем.</span>")

/obj/item/clothing/suit/space/vox/medic/dropped(mob/user)
	wearer = null
	STOP_PROCESSING(SSobj, src)
	..()

/obj/item/clothing/suit/space/vox/medic/Destroy()
	STOP_PROCESSING(SSobj, src)
	wearer = null
	return ..()

/obj/item/clothing/suit/space/vox/medic/process(damage)
	if(!wearer)
		STOP_PROCESSING(SSobj, src)
		return
	if(wearer.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	if(!istype(wearer.head, /obj/item/clothing/head/helmet/space/vox/medic))
		return
	if(damage > 9)
		wearer.adjustToxLoss(0.7) // this will kill the wearer after a while if the suit is not repaired or removed
	else if(wearer.reagents.get_reagent_amount(/datum/reagent/medicine/tricordrazine) > 5)
		return // safe tricordrazine injection
	if(damage > 19)
		wearer.adjustToxLoss(1) // this will kill the wearer much faster
	wearer.reagents.add_reagent(/datum/reagent/medicine/tricordrazine, REAGENTS_METABOLISM)

////////////////////////////////////////////////////////////////////// Reinforced Vox combat carapace

/obj/item/clothing/head/helmet/space/hardsuit/syndi/vox
	name = "alien carapace helmet"
	desc = "A dark heavy helmet, made with unknown materials."
	icon_state = "hardsuit0-voxcarapace"
	item_state = "hardsuit0-voxcarapace"
	hardsuit_type = "voxcarapace"
	armor = list(MELEE = 65, BULLET = 50, LASER = 70, ENERGY = 20, BOMB = 30, BIO = 30, RAD = 30)

/obj/item/clothing/suit/space/hardsuit/syndi/vox
	name = "alien carapace hardsuit"
	desc = "An armoured, segmented carapace. It looks pretty run-down."
	icon_state = "hardsuit0-voxcarapace"
	item_state = "hardsuit0-voxcarapace"
	hardsuit_type = "voxcarapace"
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/syndi/vox
	armor = list(MELEE = 65, BULLET = 50, LASER = 70, ENERGY = 20, BOMB = 30, BIO = 30, RAD = 30)
	species_restricted = list("Vox")
	tail_state = ""


////////////////////////////////////////////////////////////////////////////// Арбалеты с иными пинами и ЕВА, помещающаяся в рюкзак. Не стал изменять прямо на картах, а сделал отдельные предметы. Пригодятся.

/obj/item/gun/energy/kinetic_accelerator/crossbow/large/pin
	pin = /obj/item/firing_pin

/obj/item/gun/energy/kinetic_accelerator/crossbow/large/pindicate
	pin = /obj/item/firing_pin/implant/pindicate

/obj/item/gun/energy/kinetic_accelerator/crossbow/pindicate
	pin = /obj/item/firing_pin/implant/pindicate

/obj/item/clothing/suit/space/eva/light
	w_class = WEIGHT_CLASS_SMALL

////////////////////////////////////////////////////////////////////////////// Vox pinning weapons
/obj/item/projectile/spike
	name = "spike"
	icon_state = "throwingstar"
	icon = 'icons/obj/items_and_weapons.dmi'
	damage = 40
	damage_type = BRUTE
	nodamage = 0
	eyeblur = 0
	slur = 0
	knockdown = 0
	stamina = 10
	knockdown_stamoverride = 0
	armour_penetration = 65
	embedding = list("pain_mult" = 4, "embed_chance" = 100, "fall_chance" = 0, "embed_chance_turf_mod" = 15)


/obj/item/ammo_casing/energy/bolt/spike
	projectile_type = /obj/item/projectile/spike
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/taser.ogg'

/obj/item/gun/energy/kinetic_accelerator/spikethrower
	name = "spike thrower"
	desc = "A vicious alien projectile weapon. Parts of it quiver gelatinously, as though the thing is insectile and alive."
	w_class = WEIGHT_CLASS_NORMAL
	suppressed = FALSE
	ammo_type = list(/obj/item/ammo_casing/energy/bolt/spike)
	weapon_weight = WEAPON_LIGHT
	inaccuracy_modifier = 0.25
	obj_flags = 0
	overheat_time = 20
	holds_charge = FALSE
	unique_frequency = TRUE
	can_flashlight = 0
	max_mod_capacity = 0
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "spikethrower"
	item_state = "spikethrower"
	lefthand_file = 'icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/guns_righthand.dmi'
	pin = /obj/item/firing_pin/implant/pindicate

/obj/item/gun/energy/kinetic_accelerator/spikethrower/attack(mob/living/user)
	if(ishuman(user))
		if(!isvox(user))
			to_chat(user, "<span class='warning'>The weapon does not respond to you!</span>")
			return
	else
		to_chat(user, "<span class='warning'>The weapon does not respond to you!</span>")
		return

//// Misc

/obj/item/card/emag/vox
	uses = 30


/////////////////////////////////////////////////////////

/obj/item/clothing/mask/gas/sechailer/syndicate/flektarn
	icon_state = "half_mask_flektarn"

/obj/item/clothing/mask/gas/sechailer/syndicate/green
	icon_state = "half_mask_green"

/obj/item/clothing/mask/gas/sechailer/syndicate/tan
	icon_state = "half_mask_tan"

/obj/item/storage/backpack/hipbag
	name = "Hipbag"
	icon_state = "hipbag"
	item_state = "hipbag"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	icon = 'icons/obj/clothing/belts.dmi'
	mob_overlay_icon = 'icons/mob/clothing/belt.dmi'

/obj/item/storage/backpack/hipbag/tan
	name = "Tan Hipbag"
	icon_state = "hipbag_tan"
	item_state = "hipbag_tan"

/obj/item/storage/backpack/hipbag/green
	name = "Green Hipbag"
	icon_state = "hipbag_green"
	item_state = "hipbag_green"

//////////////////////////////////////////////

/mob/living/simple_animal/pet/dog/corgi/pig/assistant
	name = "Danya"
	real_name = "Danya"
	icon = 'modular_bluemoon/kovac_shitcode/icons/animals.dmi'
	maxHealth = 250
	health = 250
	gender = MALE

/mob/living/simple_animal/pet/fox/fennec/eldritch
	icon = 'modular_bluemoon/kovac_shitcode/icons/animals.dmi'
	maxHealth = 100
	health = 100
	held_icon = "fennec_eldritch"

/mob/living/simple_animal/pet/cat/moro
	name = "Moro"
	desc = "He likes grechkya."
	icon_state = "moro"
	icon_living = "moro"
	icon_dead = "moro_dead"
	held_icon = "moro"
	unique_pet = TRUE
	mob_size = MOB_SIZE_LARGE
	maxHealth = 250
	health = 250
	gender = MALE
	speak = list("*meow", "*meow2", "*meow3", "*meow4", "*meow5", "*meow6", "*mrrp", "*mrrp3", "*purr", "*oink1")
	icon = 'modular_bluemoon/kovac_shitcode/icons/animals.dmi'

/mob/living/simple_animal/pet/cat/alta
	name = "Alta"
	desc = "A cute white cat."
	icon_state = "alta"
	icon_living = "alta"
	icon_dead = "alta_dead"
	held_icon = "alta"
	unique_pet = TRUE
	gender = FEMALE
	speak = list("*meow", "*meow2", "*meow3", "*meow4", "*meow5", "*meow6", "*mrrp", "*mrrp3", "*purr")
	icon = 'modular_bluemoon/kovac_shitcode/icons/animals.dmi'

/mob/living/simple_animal/pet/cat/space/alta
	name = "Space Alta"
	desc = "An ordinary Alta, except that she is wearing a special elite modsuit from a Cybersun to protect herself in space."
	icon_state = "spacealta"
	icon_living = "spacealta"
	icon_dead = "spacealta_dead"
	held_icon = "spacealta"
	unique_pet = TRUE
	gender = FEMALE
	speak = list("*meow", "*meow2", "*meow3", "*meow4", "*meow5", "*meow6", "*mrrp", "*mrrp3", "*purr")
	icon = 'modular_bluemoon/kovac_shitcode/icons/animals.dmi'

/mob/living/simple_animal/pet/cat/space/alta/Initialize(mapload)
	. = ..()
	if((NEW_YEAR || CHRISTMAS || FESTIVE_SEASON) in SSevents.holidays)
		icon_state = "spacealta_santa"
		icon_living = "spacealta_santa"
		icon_dead = "spacealta_dead_santa"
		held_icon = "spacealta_santa"

/mob/living/simple_animal/pet/cat/alta/dar
	name = "Dar Jr"
	desc = "A little kitten with a cool little bag and a cap! He is trying really hard to bring you your order and happiness!"
	icon_state = "dar"
	icon_living = "dar"
	icon_dead = "dar_dead"
	held_icon = "dar"
	unique_pet = TRUE
	gender = MALE
	speak = list("*meow", "*meow2", "*meow3", "*meow4", "*meow5", "*meow6", "*mrrp", "*mrrp3", "*purr")
	icon = 'modular_bluemoon/kovac_shitcode/icons/animals.dmi'

/mob/living/simple_animal/pet/dog/corgi/Lisa/ada
	name = "Ada"
	real_name = "Ada"
	gender = FEMALE
	desc = "She will bite your throat till you die."
	gold_core_spawnable = NO_SPAWN
	unique_pet = TRUE
	icon_state = "ada"
	icon_living = "ada"
	icon_dead = "ada_dead"
	held_icon = "ada"
	icon = 'modular_bluemoon/kovac_shitcode/icons/animals.dmi'

/mob/living/simple_animal/pet/dog/juda
	name = "Juda"
	desc = "Adorable shark that moves its paws funny and resembles a banana."
	icon_state = "juda"
	icon_living = "juda"
	icon_dead = "juda_dead"
	held_icon = "juda"
	unique_pet = TRUE
	gender = MALE
	speak = list("*growl", "*rawr2")
	emote_see = list("Булькает", "Булькает гениально", "Надувает пузырь", "Крутится вокруг себя")
	icon = 'modular_bluemoon/kovac_shitcode/icons/animals.dmi'

/mob/living/simple_animal/pet/dog/corgi/Lisa/zlatchek
	name = "Zlat"
	real_name = "Zlat"
	gender = MALE
	desc = "A happy coyote, in a green officer's cap with the name Zlat written on the back."
	gold_core_spawnable = NO_SPAWN
	unique_pet = TRUE
	icon_state = "zlat"
	icon_living = "zlat"
	icon_dead = "zlat_dead"
	held_icon = "ada"
	icon = 'modular_bluemoon/kovac_shitcode/icons/animals.dmi'

/mob/living/simple_animal/pet/fox/emma
	name = "Emma"
	icon_state = "emma"
	icon_living = "emma"
	icon_dead = "emma_dead"
	held_icon = "emma"
	see_in_dark = 10
	gender = FEMALE
	icon = 'modular_bluemoon/kovac_shitcode/icons/animals.dmi'

/mob/living/simple_animal/pet/cat/jruttie
	name = "Jruttie"
	desc = "A grey magical cat, full of funnies."
	icon_state = "jruttie"
	icon_living = "jruttie"
	icon_dead = "jruttie_dead"
	held_icon = "jruttie"
	unique_pet = TRUE
	gender = FEMALE
	speak = list("*meow3", "*meow4", "*meow5", "*mrrp", "*mrrp3", "*purr", "*mew")
	icon = 'modular_bluemoon/kovac_shitcode/icons/animals.dmi'
	vocal_bark_id = "meow"
	speak_chance = 10
	loot = list(/obj/item/clothing/head/wizard/fake = 1)

/mob/living/simple_animal/pet/dog/corgi/mothroach/wertyanmoth
	name = "Wertyan"
	real_name = "Wertyan"
	desc = "Серая инженерная мотылиха. Обожает эффективный контур, взрываться и молировать."
	icon = 'modular_bluemoon/icons/mob/pets.dmi'
	icon_state = "wertan"
	icon_living = "wertan"
	icon_dead = "wertan_dead"
	held_icon = "wertan_held"
	speak = list("Furrr.","Uhh.", "Hurrr.", "*chitter", "*chitter2", "*spin", "*flap")
	emote_see = list("мотает головой.", "крутится.", "дрожит.")
	emote_hear = list("дышит в противогаз.", "жужжит!", "хлопает крыльями.", "думает о контуре.")
	speak_emote = list("buzzes", "squeals")
	deathmessage = "explodes with huge buzz!"
	unique_pet = TRUE
	gender = FEMALE
	vocal_bark_id = "moff"
	speak_chance = 8
	maxHealth = 30
	health = 30
	emote_see = list("flutters", "mothes")
	gold_core_spawnable = null
	footstep_type = FOOTSTEP_MOB_CLAW
	loot = list(/obj/item/clothing/head/hardhat = 1)

/mob/living/simple_animal/pet/dog/corgi/mothroach/wertyanmoth/death(gibbed)
	explosion(src.loc, -1, -1, 2, 3)
	..()

/mob/living/simple_animal/pet/dog/corgi/mothroach/wertyanmoth/ComponentInitialize()
	. = ..()
	RemoveElement(/datum/element/wuv, "yaps happily!", EMOTE_AUDIBLE, /datum/mood_event/pet_animal, "growls!", EMOTE_AUDIBLE)
	RemoveElement(/datum/element/strippable, GLOB.strippable_corgi_items)
	RemoveElement(/datum/element/mob_holder, held_icon)
	AddElement(/datum/element/wuv, "mothin'!", EMOTE_AUDIBLE, /datum/mood_event/pet_animal, "buzzes!", EMOTE_AUDIBLE)
	AddElement(/datum/element/mob_holder, held_icon, inv_slots = ITEM_SLOT_HEAD)

/mob/living/simple_animal/pet/dog/corgi/mothroach/wertyanmoth/throw_at(atom/target, range, speed, mob/thrower, spin, diagonals_first, datum/callback/callback, force, quickstart)
	. = ..(target, range, speed, thrower, FALSE, diagonals_first, callback)
	emote("msqueak")

///////////////////

/obj/item/storage/backpack/ert_commander
	name = "Tactical Backpack"
	icon_state = "ert_commander"

/obj/item/storage/backpack/ert_commander/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_volume = STORAGE_VOLUME_BAG_OF_HOLDING

/obj/item/storage/backpack/ert_commander/ert_security
	icon_state = "ert_security"

/obj/item/storage/backpack/ert_commander/ert_medical
	icon_state = "ert_medical"

/obj/item/storage/backpack/ert_commander/ert_engineering
	icon_state = "ert_engineering"

/obj/item/storage/backpack/ert_commander/ert_janitor
	icon_state = "ert_janitor"

///////////////////////////////////////////////////////////////////////////

/obj/item/clothing/suit/space/hardsuit/engine
	unique_reskin = list(
		"Default" = list(
			"icon_state" = "hardsuit-engineering",
			"tail_state" = "engineer"
		),
		"Alt" = list(
			"icon_state" = "hardsuit-engineering2",
			"tail_state" = "engi-tail"
		)
	)

/obj/item/clothing/suit/space/hardsuit/engine/reskin_obj(mob/M)
	. = ..()

	var/obj/item/clothing/head/helmet/space/hardsuit/engine/mining_helmet
	if(istype(helmet))
		mining_helmet = helmet

	switch(current_skin)
		if("Default")

			if(mining_helmet)
				mining_helmet.icon_state = initial(mining_helmet.icon_state)

		if("Alt")

			if(mining_helmet)
				mining_helmet.icon_state = "hardsuit0-engineering2"

/obj/item/clothing/head/helmet/space/hardsuit/engine/update_icon_state()
	switch(suit.current_skin)
		if("Alt")
			icon_state = "hardsuit[on]-engineering2"
		else
			. = ..()


///////////////////////////////////////////////////////////////////////////////////////////

/obj/item/clothing/suit/space/hardsuit/engine/atmos
	unique_reskin = list(
		"Default" = list(
			"icon_state" = "hardsuit-atmospherics",
			"tail_state" = "atmos"
		),
		"Alt" = list(
			"icon_state" = "hardsuit-atmospherics2",
			"tail_state" = "atmos-tail"
		)
	)

/obj/item/clothing/suit/space/hardsuit/engine/atmos/reskin_obj(mob/M)
	. = ..()

	var/obj/item/clothing/head/helmet/space/hardsuit/engine/atmos/mining_helmet
	if(istype(helmet))
		mining_helmet = helmet

	switch(current_skin)
		if("Default")

			if(mining_helmet)
				mining_helmet.icon_state = initial(mining_helmet.icon_state)

		if("Alt")

			if(mining_helmet)
				mining_helmet.icon_state = "hardsuit0-atmospherics2"

/obj/item/clothing/head/helmet/space/hardsuit/engine/atmos/update_icon_state()
	switch(suit.current_skin)
		if("Alt")
			icon_state = "hardsuit[on]-atmospherics2"
		else
			. = ..()

///////////////////////////////////////////////////////////////////////////////////////////

/obj/item/clothing/suit/space/hardsuit/engine/elite
	unique_reskin = list(
		"Default" = list(
			"icon_state" = "hardsuit-white",
			"tail_state" = "ce"
		),
		"Alt" = list(
			"icon_state" = "hardsuit-white2",
			"tail_state" = "ce-tail"
		)
	)

/obj/item/clothing/suit/space/hardsuit/engine/elite/reskin_obj(mob/M)
	. = ..()

	var/obj/item/clothing/head/helmet/space/hardsuit/engine/elite/mining_helmet
	if(istype(helmet))
		mining_helmet = helmet

	switch(current_skin)
		if("Default")

			if(mining_helmet)
				mining_helmet.icon_state = initial(mining_helmet.icon_state)

		if("Alt")

			if(mining_helmet)
				mining_helmet.icon_state = "hardsuit0-white2"

/obj/item/clothing/head/helmet/space/hardsuit/engine/elite/update_icon_state()
	switch(suit.current_skin)
		if("Alt")
			icon_state = "hardsuit[on]-white2"
		else
			. = ..()
