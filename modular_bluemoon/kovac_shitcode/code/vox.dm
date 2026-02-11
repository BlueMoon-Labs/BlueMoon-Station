#define SPECIES_VOX		"vox"

///Костыли. Морда невидима, как и хвост, который изначально привязан к телу.
/datum/sprite_accessory/tails/mam_tails/vox
	name = "Vox"
	icon_state = "vox_tail"
	icon = 'modular_bluemoon/kovac_shitcode/icons/species/vox_body.dmi'
	color_src = MUTCOLORS
	recommended_species = list("vox")

/datum/sprite_accessory/snouts/mam_snouts/vox
	name = "Vox"
	icon_state = "vox_snout"
	color_src = MUTCOLORS
	icon = 'modular_bluemoon/kovac_shitcode/icons/species/vox_body.dmi'
	recommended_species = list("vox")

///Внутренние органы вокса. Дыхание с помощью азота
//////////////////////////////////////////////////////////////////////////////////

/obj/item/organ/lungs/vox
	name = "vox lungs"
	desc = "A regular Vox usually needs nitrogen instead of oxygen."
	icon_state = "vox_lungs"
	breathing_class = BREATH_NITROGEN
	maxHealth = INFINITY

/obj/item/organ/lungs/vox/populate_gas_info()
	..()
	gas_max -= GAS_N2

/datum/breathing_class/nitrogen
	gases = list(
		GAS_N2 = 1
	)
	products = list(
		GAS_CO2 = 1
	)
	low_alert_category = "too_much_nitro"
	low_alert_datum = /atom/movable/screen/alert/too_much_nitro
	high_alert_category = "not_enough_nitro"
	high_alert_datum = /atom/movable/screen/alert/not_enough_nitro

/obj/item/organ/tongue/vox
	name = "vox tongue"
	desc = "Generic Vox tongue."
	icon_state = "vox_tongue"
	say_mod = "shrieks"
	taste_sensitivity = 101
	maxHealth = 75
	initial_accents = list(/datum/accent/bird)

/obj/item/organ/heart/vox
	name = "vox heart"
	desc = "Vox hearts are placed in groin."
	icon_state = "vox_heart"
	zone = BODY_ZONE_PRECISE_GROIN

/obj/item/organ/liver/vox
	name = "vox liver"
	icon_state = "vox_liver"

/obj/item/organ/stomach/vox
	name = "vox stomach"
	icon_state = "vox_stomach"

/obj/item/organ/brain/vox
	name = "cortical stack"
	desc = "What is this?"
	icon = 'icons/obj/surgery.dmi'
	icon_state = "stack"

//Собственно раса
/////////////////////////////////////////////////////////////////////////////////
/datum/species/mammal/vox
	name = "Vox"
	id = SPECIES_VOX
	inherent_biotypes = MOB_ROBOTIC|MOB_ORGANIC|MOB_HUMANOID|MOB_REPTILE // Их биология гибридна
	say_mod = "says"
	eye_type = "vox"
	mutant_bodyparts = list("mcolor" = "F8F8F8", "mcolor2" = "F8F8F8", "mcolor3" = "F8F8F8", "mam_snouts" = "Vox",  "mam_tail" = "Vox", "deco_wings" = "None",
						"horns" = "None", "legs" = "Digitigrade", "meat_type" = "Mammalian", "mam_body_markings" = list())
	allowed_limb_ids = null

	limbs_id = SPECIES_VOX
	icon_limbs = 'modular_splurt/icons/mob/human_parts_greyscale.dmi'
	damage_overlay_type = "vox"

	attack_verb = "claw"
	attack_sound = 'sound/weapons/slash.ogg'
	miss_sound = 'sound/weapons/slashmiss.ogg'

	tail_type = "mam_tail"
	species_category = SPECIES_CATEGORY_FURRY
	//sexes = 0
	breathid = "n2"

	mutant_heart = /obj/item/organ/heart/vox
	mutantlungs = /obj/item/organ/lungs/vox
	mutanttongue = /obj/item/organ/tongue/vox
	mutant_brain = /obj/item/organ/brain/vox
	mutantliver = /obj/item/organ/liver/vox
	mutantstomach = /obj/item/organ/stomach/vox
	mutantappendix = null // аппендикс? убран!

	disliked_food = null
	liked_food = GROSS | TOXIC | MEAT | RAW // Пофиг чё жрать, хоть от мусора кайфуйте

	icon_eyes = 'modular_splurt/icons/mob/clothing/species/vox/eyes.dmi'
	icon_head = 'icons/mob/clothing/head_vox.dmi'
	icon_mask = 'icons/mob/clothing/mask_vox.dmi'

//Вокс получает пиздюлей сильнее
	burnmod = 1.3
	heatmod = 1.3
	brutemod = 1.3
//Но и лапками дерёт морды в кровь
	punchdamagelow = 5
	punchdamagehigh = 10
	punchstunthreshold = 4
	punchwoundbonus = 3

	attack_verb = "claw"
	attack_sound = 'sound/weapons/slash.ogg'
	miss_sound = 'sound/weapons/slashmiss.ogg'

	//languagewhitelist = list("Vox-Pidgin")
	no_equip = list(ITEM_SLOT_GLOVES) // Запрещаем носить перчатки - ручища не позволяют
	species_language_holder = /datum/language_holder/vox // Воксы изначально знают свой язык

	species_traits = list(HAS_BONE,HAS_FLESH,EYECOLOR,LIPS,HAIR,NOAROUSAL)
	inherent_traits = list(TRAIT_RESISTCOLD,TRAIT_STABLEHEART,TRAIT_STABLELIVER,TRAIT_EASYDISMEMBER,TRAIT_SILENT_STEP,TRAIT_DNC_ORDER) //Сердце и печень не гниют, устойчивость к холоду, тихий шаг. Вдобавок к минусам выше - конечности проще отрываются
///25.08.2023 - убрана защита от космоса, но не баланса ради - воксов тупо невозможно содержать в местах навроде пермабрига. В компенсанцию снижены множителя урона по воксам.

	ass_image = 'icons/ass/asslizard.png'

//Форсим стандартные цвета, кривые ноги и морду с хвостом на случай чего. Добавляем такл.
/datum/species/mammal/vox/on_species_gain(mob/living/carbon/human/C, datum/species/old_species)
	if((C.dna.features["mam_tail"] != "Vox"))
		C.dna.features["mam_tail"] = "Vox"
	if(C.dna.features["legs"] != "Digitigrade")
		C.dna.features["legs"] = "Digitigrade"
	if(C.dna.features["mam_snouts"] != "Vox")
		C.dna.features["mam_snouts"] = "Vox"
		for(var/obj/item/bodypart/leggie in C.bodyparts)
			if(leggie.body_zone == BODY_ZONE_L_LEG || leggie.body_zone == BODY_ZONE_R_LEG)
				leggie.update_limb(FALSE, C)
	C.dna.features["mcolor"] = "F8F8F8"
	C.dna.features["mcolor2"] = "F8F8F8"
	C.dna.features["mcolor3"] = "F8F8F8"

	C.update_body()

	var/datum/component/tackler/T = C.LoadComponent(/datum/component/tackler)
	T.stamina_cost = 25
	T.base_knockdown = 2.5 SECONDS
	T.range = 5
	T.speed = 0.9
	T.skill_mod = 4
	T.min_distance = 2
	return ..()

/datum/species/mammal/vox/on_species_loss(mob/living/carbon/C)

	qdel(C.GetComponent(/datum/component/tackler))
	return ..()

/datum/species/mammal/vox/random_name(gender,unique,lastname)
	if(unique)
		return random_unique_vox_name()

	var/randname = vox_name()

	if(lastname)
		randname += " [lastname]"

	return randname

/proc/random_unique_vox_name(attempts_to_find_unique_name=10)
	for(var/i in 1 to attempts_to_find_unique_name)
		. = capitalize(vox_name())

		if(!findname(.))
			break

/proc/vox_name()
	return "[pick(GLOB.vox_names)]"

////////////////////////////////////////////////////////////////////////////////

/mob/living/carbon/human/species/mammal/vox
	race = /datum/species/mammal/vox



///Далее идут предметы и прочий стаф
/////////////////////////////////////////////////////////////////////////////////
/*
 * Nitrogen tank
 */
/obj/item/tank/internals/emergency_nitrogen
	name = "nitrogen tank"
	desc = "A bit extended capacity tank for nitrogen breathing species"
	icon_state = "nitrogen"
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL
	force = 4
	distribute_pressure = TANK_DEFAULT_RELEASE_PRESSURE
	volume = 6


/obj/item/tank/internals/emergency_nitrogen/populate_gas()
	air_contents.set_moles(GAS_N2, (3*ONE_ATMOSPHERE)*volume/(R_IDEAL_GAS_EQUATION*T20C))
	return

/obj/item/tank/internals/emergency_nitrogen/empty/populate_gas()
	return


///////////////////////////////////////////////////////////////////

/obj/item/tank/internals/emergency_nitrogen/double
	name = "double nitrogen tank"
	desc = "Two combined red tanks for nitrogen breathing species"
	icon_state = "nitrogen_double"
	force = 6
	volume = 7


/obj/item/tank/internals/emergency_nitrogen/populate_gas()
	air_contents.set_moles(GAS_N2, (6*ONE_ATMOSPHERE)*volume/(R_IDEAL_GAS_EQUATION*T20C))
	return

/obj/item/tank/internals/emergency_nitrogen/empty/populate_gas()
	return


/////////////

/obj/item/tank/internals/emergency_nitrogen_ext
	name = "extended nitrogen tank"
	desc = "Huge tank for nitrogen breathing species"
	icon_state = "nitrogen_ext"
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	force = 4
	distribute_pressure = TANK_DEFAULT_RELEASE_PRESSURE
	volume = 12
	w_class = WEIGHT_CLASS_NORMAL


/obj/item/tank/internals/emergency_nitrogen_ext/populate_gas()
	air_contents.set_moles(GAS_N2, (3*ONE_ATMOSPHERE)*volume/(R_IDEAL_GAS_EQUATION*T20C))
	return

/obj/item/tank/internals/emergency_nitrogen_ext/empty/populate_gas()
	return

////////////////////////////////////////

/datum/sprite_accessory/hair/vox_afro
	name = "Vox Afro"
	icon_state = "hair_vox_afro"
	icon = 'modular_bluemoon/kovac_shitcode/icons/hair.dmi'
	recommended_species = list("Vox")

/datum/sprite_accessory/hair/vox_afro/vox_crestedquills
	name = "Vox Crestedquills"
	icon_state = "hair_vox_crestedquills"

/datum/sprite_accessory/hair/zoey/vox_emperorquills
	name = "Vox Emperorquills"
	icon_state = "hair_vox_emperorquills"

/datum/sprite_accessory/hair/vox_afro/vox_horns
	name = "Vox Horns"
	icon_state = "hair_vox_horns"

/datum/sprite_accessory/hair/vox_afro/vox_keelquills
	name = "Vox Keelquills"
	icon_state = "hair_vox_keelquills"

/datum/sprite_accessory/hair/vox_afro/vox_keetquills
	name = "Vox Keetquills"
	icon_state = "hair_vox_keetquillss"

/datum/sprite_accessory/hair/vox_afro/vox_kingly
	name = "Vox Kingly"
	icon_state = "hair_vox_kingly"

/datum/sprite_accessory/hair/vox_afro/vox_mohawk
	name = "Vox Mohawk"
	icon_state = "hair_vox_mohawk"

/datum/sprite_accessory/hair/vox_afro/vox_nights
	name = "Vox Nights"
	icon_state = "hair_vox_nights"

/datum/sprite_accessory/hair/vox_afro/vox_razorclipped
	name = "Vox Razorclipped"
	icon_state = "hair_vox_razorclipped"

/datum/sprite_accessory/hair/vox_afro/vox_razor
	name = "Vox Razor"
	icon_state = "hair_vox_razor"

/datum/sprite_accessory/hair/vox_afro/vox_shortquills
	name = "Vox Shortquills"
	icon_state = "hair_vox_shortquills"

/datum/sprite_accessory/hair/vox_afro/vox_tielquills
	name = "Vox Tielquills"
	icon_state = "hair_vox_tielquills"

/datum/sprite_accessory/hair/vox_afro/vox_yasu
	name = "Vox Yasu"
	icon_state = "hair_vox_yasu"

/datum/sprite_accessory/hair/vox_afro/vox_surf
	name = "Vox Surf"
	icon_state = "vox_surf"

/datum/sprite_accessory/hair/vox_afro/vox_cropped
	name = "Vox Cropped"
	icon_state = "vox_cropped"

/datum/sprite_accessory/hair/vox_afro/vox_rows
	name = "Vox Rows"
	icon_state = "vox_rows"

/datum/sprite_accessory/hair/vox_afro/vox_pony
	name = "Vox Pony"
	icon_state = "vox_pony"

/datum/sprite_accessory/hair/vox_afro/vox_mange
	name = "Vox Mange"
	icon_state = "vox_mange"

/datum/sprite_accessory/hair/vox_afro/vox_ruffhawk
	name = "Vox Ruffhawk"
	icon_state = "vox_ruffhawk"
