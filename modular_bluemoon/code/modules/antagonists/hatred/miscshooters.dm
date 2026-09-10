#define JACKAL_ANTAG "jackal"
#define JACKAL_DEPENDENCY_BASE_DAMAGE 0.1
#define JACKAL_DEPENDENCY_BRUTE_MULTIPLIER 0.4
#define JACKAL_DEPENDENCY_FIRE_MULTIPLIER 0.2
#define JACKAL_DEPENDENCY_WARNING_CHANCE 10

/datum/antagonist/jackal/greet()
	var/greet_text = "Ты — [span_red(span_bold("Безымянный Ликвидатор"))]. Твое имя стерто из баз данных Солнечной Федерации, а твое прошлое давно сгорело в пепле грязных контрактов.<br>"
	greet_text += "Твоя кровь кипит от чудовищной дозы боевых стимуляторов, а реальность давно превратилась в психоделический кошмар. Окружающие люди для тебя — не более чем мишени, глупый и бесполезный шум в твоей раскалывающейся голове.<br>"
	greet_text += "У тебя осталась лишь одна цель: [span_red(span_bold("закрыть этот финальный контракт, выкосив станцию подчистую"))], и красиво сгореть в неоновой вспышке собственной смерти под аплодисменты воображаемого друга.<br><br>"
	greet_text += "Твои особые сигареты лечат тебя. Если в крови не останется алкоголя, Omnizine или стимуляторов, тело начнет постепенно разрушаться.<br>"
	greet_text += "В холстере лежат два stimpack medipen, три эпипена и один боевой нож. Эпипены почти не лечат, зато останавливают кровотечение.<br>"
	greet_text += "Казнь выполняется выстрелом из револьвера по критованной цели. После пяти казней на револьвер накладывается особая маска, уменьшая отдачу и увеличивая темп стрельбы.<br>"
	greet_text += span_red(span_bold("Докуривай сигарету — и погнали"))
	to_chat(owner.current, greet_text)
	antag_memory = greet_text
	owner.announce_objectives()

/datum/antagonist/jackal/on_gain()
	. = ..()
	var/mob/living/carbon/human/H = owner?.current
	if(!istype(H))
		return
	H.remove_quirk(/datum/quirk/monochromatic)
	H.update_body()
	RegisterSignal(H, COMSIG_LIVING_BIOLOGICAL_LIFE, PROC_REF(handle_dependency))

/datum/antagonist/jackal/on_removal()
	var/mob/living/carbon/human/H = owner?.current
	if(istype(H))
		UnregisterSignal(H, COMSIG_LIVING_BIOLOGICAL_LIFE)
	. = ..()

/datum/antagonist/jackal/proc/handle_dependency(mob/living/carbon/human/H, delta_time, times_fired)
	SIGNAL_HANDLER
	if(!istype(H) || H.stat == DEAD || dependency_satisfied(H))
		return
	H.adjustBruteLoss(max(JACKAL_DEPENDENCY_BASE_DAMAGE, delta_time * JACKAL_DEPENDENCY_BRUTE_MULTIPLIER), TRUE)
	H.adjustFireLoss(max(JACKAL_DEPENDENCY_BASE_DAMAGE, delta_time * JACKAL_DEPENDENCY_FIRE_MULTIPLIER), TRUE)
	if(prob(JACKAL_DEPENDENCY_WARNING_CHANCE))
		to_chat(H, span_userdanger("Тело ломается без сигарет, алкоголя или стимуляторов. Найди дозу."))

/datum/antagonist/jackal/proc/dependency_satisfied(mob/living/carbon/human/H)
	if(!H.reagents)
		return FALSE
	for(var/datum/reagent/R as anything in H.reagents.reagent_list)
		if(istype(R, /datum/reagent/consumable/ethanol) || istype(R, /datum/reagent/medicine/omnizine) || istype(R, /datum/reagent/medicine/stimulants))
			return TRUE
	return FALSE

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
	return // Prevent parent hatred pre_equip from running (weapon selection dialog)

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
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_righthand.dmi'
	mag_type = /obj/item/ammo_box/magazine/internal/cylinder
	fire_sound = 'modular_bluemoon/sound/weapons/jackal357.ogg'
	recoil = 0.5
	fire_delay = 1
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS | ITEM_SLOT_SUITSTORE
	var/glory_kills = 0

/obj/item/gun/ballistic/revolver/jackal357/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, JACKAL_ANTAG)

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
	STR.can_hold = typecacheof(list(/obj/item/gun/ballistic/revolver/jackal357, /obj/item/ammo_box/a357, /obj/item/kitchen/knife/combat, /obj/item/storage/fancy/cigarettes/jackal, /obj/item/lighter, /obj/item/reagent_containers/hypospray/medipen/stimulants, /obj/item/reagent_containers/hypospray/medipen))
	STR.quickdraw = TRUE

/obj/item/storage/belt/holster/jackal/PopulateContents()
	new /obj/item/gun/ballistic/revolver/jackal357(src)
	new /obj/item/ammo_box/a357(src)
	new /obj/item/ammo_box/a357(src)
	new /obj/item/ammo_box/a357(src)
	new /obj/item/kitchen/knife/combat(src)
	new /obj/item/storage/fancy/cigarettes/jackal(src)
	new /obj/item/lighter(src)
	new /obj/item/reagent_containers/hypospray/medipen/stimulants(src)
	new /obj/item/reagent_containers/hypospray/medipen/stimulants(src)
	new /obj/item/reagent_containers/hypospray/medipen(src)
	new /obj/item/reagent_containers/hypospray/medipen(src)
	new /obj/item/reagent_containers/hypospray/medipen(src)

/obj/item/storage/belt/holster/jackal/Exited(atom/movable/gone, atom/newLoc)
	. = ..()
	if(istype(gone, /obj/item/ammo_box/a357) && !QDELETED(src))
		new /obj/item/ammo_box/a357(src)

/obj/item/clothing/mask/cigarette/jackal
	name = "Jackal cigarette"
	desc = "A harsh cigarette laced with a small dose of Omnizine instead of the usual cheap filler."
	list_reagents = list(/datum/reagent/drug/nicotine = 15, /datum/reagent/medicine/omnizine = 10)

/obj/item/storage/fancy/cigarettes/jackal
	name = "Jackal cigarette packet"
	desc = "A battered packet of field cigarettes prepared for a violent, prolonged hunt."
	icon_state = "syndie"
	spawn_type = /obj/item/clothing/mask/cigarette/jackal
