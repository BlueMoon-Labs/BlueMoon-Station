#define JACKAL_ANTAG "jackal"

/datum/antagonist/jackal
	parent_type = /datum/antagonist/hatred
	name = "Jackal"
	antagpanel_category = "Jackal"
	roundend_category = "Jackal"
	job_rank = ROLE_MASS_SHOOTER
	ui_name = "AntagInfoHatred"

/datum/antagonist/jackal/greet()
	owner.announce_objectives()

/datum/antagonist/jackal/on_gain()
	. = ..()
	var/mob/living/carbon/human/H = owner?.current
	if(!istype(H))
		return
	H.remove_quirk(/datum/quirk/monochromatic)
	H.update_body()

/datum/antagonist/jackal/make_authentic_body()
	var/mob/living/carbon/human/H = owner.current
	H.real_name = "Jackal"
	H.name = H.real_name
	H.dna.real_name = H.real_name
	H.mind?.name = H.real_name
	H.set_species(/datum/species/human)
	H.set_gender(MALE, TRUE, forced = TRUE)
	H.dna.remove_all_mutations()
	H.skin_tone = "caucasian1"
	H.hair_style = "Business Hair 2"
	H.hair_color = sanitize_hexcolor("#552a00")
	H.facial_hair_style = "Beard (7 o'Clock)"
	H.facial_hair_color = sanitize_hexcolor("#552a00")
	H.set_bark("mutedc2")
	H.dna.update_ui_block(DNA_GENDER_BLOCK)
	H.dna.update_ui_block(DNA_SKIN_TONE_BLOCK)
	H.dna.update_ui_block(DNA_HAIR_STYLE_BLOCK)
	H.dna.update_ui_block(DNA_HAIR_COLOR_BLOCK)
	H.dna.update_ui_block(DNA_FACIAL_HAIR_STYLE_BLOCK)
	H.dna.update_ui_block(DNA_FACIAL_HAIR_COLOR_BLOCK)
	H.dna.features["legs"] = "Plantigrade"
	H.dna.species.mutant_bodyparts["legs"] = "Plantigrade"
	H.update_body()
	H.update_hair()

/datum/antagonist/jackal/alarm_station()
	if(istype(src) && owner?.current && owner.current.stat != DEAD)
		priority_announce("Дипломатический Корпус Федерации предупреждает: в вашем секторе зафиксирован взлом частоты особо опасным ликвидатором. Он находится в состоянии глубокого психоза из-за боевой химии, тяжёлых наркотиков и алкоголя. Цель вооружена крупнокалиберным револьвером и ликвидирует всех на своем пути. Всем сотрудникам: разрешено открытие огня на поражение без предупреждения\n\n...Просто диллер мудак. Вот и всё...", "DIPLOMATIC CORPS ALERT", 'modular_bluemoon/code/modules/antagonists/hatred/jackal_spawned.ogg', has_important_message = TRUE)

/datum/outfit/jackal
	parent_type = /datum/outfit/hatred
	name = "Jackal"
	head = null
	glasses = /obj/item/clothing/glasses/hud/health/sunglasses/jackal
	uniform = /obj/item/clothing/under/jackal
	suit = null
	belt = /obj/item/storage/belt/holster/jackal
	suit_store = null
	back = null
	backpack_contents = null

/datum/outfit/jackal/pre_equip(mob/living/carbon/human/H, visualsOnly, client/preference_source)
	return

/datum/outfit/jackal/post_equip(mob/living/carbon/human/H, visualsOnly, client/preference_source)
	if(!istype(H) || QDELETED(H))
		return
	var/obj/item/clothing/under/U = H.get_item_by_slot(ITEM_SLOT_ICLOTHING)
	if(U)
		U.has_sensor = NO_SENSORS
		U.resistance_flags = FIRE_PROOF | ACID_PROOF
		U.unique_reskin = null
		U.max_restricted_accessories = 1
		ADD_TRAIT(U, TRAIT_NODROP, JACKAL_ANTAG)
	for(var/slot in list(ITEM_SLOT_OCLOTHING, ITEM_SLOT_EYES, ITEM_SLOT_BELT, ITEM_SLOT_GLOVES, ITEM_SLOT_FEET))
		var/obj/item/I = H.get_item_by_slot(slot)
		if(I)
			I.resistance_flags |= FIRE_PROOF
			if(slot in list(ITEM_SLOT_OCLOTHING, ITEM_SLOT_BELT))
				ADD_TRAIT(I, TRAIT_NODROP, JACKAL_ANTAG)

/obj/item/clothing/under/jackal
	name = "Jackal combat uniform"
	desc = "A fitted combat uniform reinforced against gunfire, blasts, and heat. It is tailored for a single ruthless operator."
	icon = 'modular_bluemoon/code/modules/antagonists/hatred/misccloth.dmi'
	mob_overlay_icon = 'modular_bluemoon/code/modules/antagonists/hatred/misccloth.dmi'
	item_state = "jackalsuit"
	icon_state = "jackalsuit"
	body_parts_covered = CHEST|GROIN|ARMS
	resistance_flags = FIRE_PROOF | ACID_PROOF
	armor = list(MELEE = 35, BULLET = 45, LASER = 35, ENERGY = 35, BOMB = 45, BIO = 20, RAD = 20, FIRE = 80, ACID = 35, WOUND = 35)

/obj/item/clothing/glasses/hud/health/sunglasses/jackal
	name = "Jackal optical shield"
	desc = "Orange combat lenses with a medical HUD and hardened flash protection. Bright flashes cannot blind the wearer."
	icon = 'modular_bluemoon/code/modules/antagonists/hatred/misccloth.dmi'
	mob_overlay_icon = 'modular_bluemoon/code/modules/antagonists/hatred/misccloth.dmi'
	icon_state = "jackalglasses"
	item_state = "jackalglasses"
	flash_protect = 2
	tint = 0

/obj/item/gun/ballistic/revolver/jackal357
	name = "Jackal .357 revolver"
	desc = "A custom .357 revolver built for a single purpose: ending a fight before the target can react."
	icon = 'modular_bluemoon/code/modules/antagonists/hatred/miscweapons.dmi'
	icon_state = "jackal357"
	item_state = "jackal357"
	mag_type = /obj/item/ammo_box/magazine/internal/cylinder
	fire_sound = 'modular_bluemoon/sound/weapons/jackal357.ogg'
	recoil = 0.5
	fire_delay = 1
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS | ITEM_SLOT_SUITSTORE
	var/glory_kills = 0

/obj/item/gun/ballistic/revolver/jackal357/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, JACKAL_ANTAG)
	RegisterSignal(src, COMSIG_PROJECTILE_ON_HIT, PROC_REF(on_jackal_projectile_hit))

/obj/item/gun/ballistic/revolver/jackal357/proc/on_jackal_projectile_hit(obj/item/gun/source, mob/living/firer, atom/target, angle)
	SIGNAL_HANDLER
	if(!ishuman(target) || !ishuman(firer) || !firer.mind?.has_antag_datum(/datum/antagonist/jackal))
		return
	var/mob/living/carbon/human/target_human = target
	if(target_human.stat in list(SOFT_CRIT, UNCONSCIOUS))
		addtimer(CALLBACK(src, PROC_REF(execute_critical_target), target_human, firer), 1, TIMER_STOPPABLE|TIMER_DELETE_ME)

/obj/item/gun/ballistic/revolver/jackal357/proc/execute_critical_target(mob/living/carbon/human/target, mob/living/carbon/human/firer)
	if(QDELETED(src) || QDELETED(target) || QDELETED(firer) || target.stat == DEAD || target.stat == CONSCIOUS)
		return
	target.death(0)
	check_glory_kill(firer, target)

/obj/item/gun/ballistic/revolver/jackal357/equipped(mob/user, slot, initial)
	. = ..()
	if(ismob(user) && user.mind?.has_antag_datum(/datum/antagonist/jackal))
		ADD_TRAIT(src, TRAIT_NODROP, JACKAL_ANTAG)

/obj/item/gun/ballistic/revolver/jackal357/update_overlays()
	. = ..()
	if(glory_kills >= 5)
		. += mutable_appearance(icon, "bloodmask")

/obj/item/gun/ballistic/revolver/jackal357/check_glory_kill(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!QDELETED(user) && user.mind?.has_antag_datum(/datum/antagonist/jackal) && (QDELETED(target) || target?.stat == DEAD))
		glory_kills++
		if(glory_kills == 5)
			recoil = 0.2
			fire_delay = 0
			to_chat(user, span_userdanger("Кровавая маска проступает на [src]. Револьвер становится легче и быстрее в руке."))
		update_icon()

/obj/item/storage/belt/holster/jackal
	name = "Jackal assault holster"
	desc = "A reinforced shoulder holster with deep internal storage. It carries the Jackal's revolver, knives, ammunition, cigarettes, and lighter without slowing its wearer."
	icon_state = "holster"
	item_state = "jackalholster"
	mob_overlay_icon = 'modular_bluemoon/code/modules/antagonists/hatred/misccloth.dmi'
	w_class = WEIGHT_CLASS_BULKY

/obj/item/storage/belt/holster/jackal/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 20
	STR.max_combined_w_class = INFINITY
	STR.max_w_class = WEIGHT_CLASS_BULKY
	STR.can_hold = typecacheof(list(/obj/item/gun/ballistic/revolver/jackal357, /obj/item/ammo_box/a357, /obj/item/kitchen/knife/combat, /obj/item/storage/fancy/cigarettes/jackal, /obj/item/lighter, /obj/item/reagent_containers/hypospray/medipen/stimpack, /obj/item/reagent_containers/hypospray/medipen))
	STR.quickdraw = TRUE

/obj/item/storage/belt/holster/jackal/PopulateContents()
	new /obj/item/gun/ballistic/revolver/jackal357(src)
	new /obj/item/ammo_box/a357(src)
	new /obj/item/ammo_box/a357(src)
	new /obj/item/ammo_box/a357(src)
	new /obj/item/kitchen/knife/combat(src)
	new /obj/item/kitchen/knife/combat(src)
	new /obj/item/kitchen/knife/combat(src)
	new /obj/item/storage/fancy/cigarettes/jackal(src)
	new /obj/item/storage/fancy/cigarettes/jackal(src)
	new /obj/item/lighter(src)
	new /obj/item/reagent_containers/hypospray/medipen/stimpack(src)
	new /obj/item/reagent_containers/hypospray/medipen/stimpack(src)
	new /obj/item/reagent_containers/hypospray/medipen/stimpack(src)
	new /obj/item/reagent_containers/hypospray/medipen(src)
	new /obj/item/reagent_containers/hypospray/medipen(src)

/obj/item/storage/belt/holster/jackal/Exited(atom/movable/gone, atom/newLoc)
	. = ..()
	if(istype(gone, /obj/item/ammo_box/a357))
		addtimer(CALLBACK(src, PROC_REF(replace_speedloaders)), 1 SECONDS, TIMER_STOPPABLE|TIMER_DELETE_ME)

/obj/item/storage/belt/holster/jackal/proc/replace_speedloaders()
	if(QDELETED(src))
		return
	var/loaded_speedloaders = 0
	for(var/obj/item/ammo_box/a357/loader in contents)
		if(length(loader.stored_ammo))
			loaded_speedloaders++
	while(loaded_speedloaders < 3)
		new /obj/item/ammo_box/a357(src)
		loaded_speedloaders++

/obj/item/gun/ballistic/revolver/jackal357/attackby(obj/item/A, mob/user, params)
	. = ..()
	if(istype(A, /obj/item/ammo_box/a357))
		var/obj/item/storage/belt/holster/jackal/H = user?.get_item_by_slot(ITEM_SLOT_BELT)
		if(H)
			addtimer(CALLBACK(H, TYPE_PROC_REF(/obj/item/storage/belt/holster/jackal, replace_speedloaders)), 1 SECONDS, TIMER_STOPPABLE|TIMER_DELETE_ME)

/obj/item/clothing/mask/cigarette/jackal
	name = "Jackal cigarette"
	desc = "A harsh cigarette laced with a small dose of Omnizine instead of the usual cheap filler."
	list_reagents = list(/datum/reagent/drug/nicotine = 15, /datum/reagent/medicine/omnizine = 10)

/obj/item/storage/fancy/cigarettes/jackal
	name = "Jackal cigarette packet"
	desc = "A battered packet of field cigarettes prepared for a violent, prolonged hunt."
	icon_state = "syndie"
	spawn_type = /obj/item/clothing/mask/cigarette/jackal
