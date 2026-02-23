#define SPECIES_NUCLEATION		"nucleation"

// ОРГАНЫ. НУ ПЕЧОНОЧКА ТАМ, СЕРДЕЧКО.
/obj/item/organ/nucleation
	name = "орган нуклеации"
	icon = 'modular_bluemoon/krashly/code/modules/mobs/carbon/nucleation/icons/surgery.dmi'
	desc = "Кристаллизированный орган человека. /red Имеет странное переливающееся свечение."

/obj/item/organ/resonant_crystal
	name = "колеблющийся кристалл"
	icon = 'modular_bluemoon/krashly/code/modules/mobs/carbon/nucleation/icons/surgery.dmi'
	icon_state = "resonant-crystal"

/obj/item/organ/heart/strange_crystal
	name = "странный кристалл"
	icon = 'modular_bluemoon/krashly/code/modules/mobs/carbon/nucleation/icons/surgery.dmi'
	icon_state = "strange-crystal"

/obj/item/organ/eyes/luminescent_crystal
	name = "люминесцентные глаза"
	icon = 'modular_bluemoon/krashly/code/modules/mobs/carbon/nucleation/icons/surgery.dmi'
	icon_state = "crystal-eyes"
	light_color = "#1C1C00"

/obj/item/organ/eyes/luminescent_crystal/New()
	set_light(2) // ГЛАЗА СВЕТЯТ КАК БАНКА ПИВА НА МЕНЯ НОЧЬЮ ИЗ ХОЛОДИЛЬНИКА.
	..()

/obj/item/organ/brain/crystal // ДУМАЛКА НУКЛЕАЦИИ.
	name = "кристаллизованный мозг"
	icon = 'modular_bluemoon/krashly/code/modules/mobs/carbon/nucleation/icons/surgery.dmi'
	icon_state = "crystal-brain"

// БОМБЕЗНЫЕ ЧУРКИ.
/datum/species/nucleation
	name = "Nucleation"
	id = SPECIES_NUCLEATION
	inherent_biotypes = MOB_ORGANIC|MOB_HUMANOID
	mutant_bodyparts = list("mcolor" = "F8F8F8", "mcolor2" = "F8F8F8", "mcolor3" = "F8F8F8", "mam_snouts" = "None",  "mam_tail" = "None", "deco_wings" = "None",
						"horns" = "None")
	override_bp_icon = 'modular_bluemoon/krashly/code/modules/mobs/carbon/nucleation/icons/r_nucleation.dmi'

	limbs_id = SPECIES_NUCLEATION
	icon_limbs = 'modular_splurt/icons/mob/human_parts_greyscale.dmi'
	damage_overlay_type = "human" // В ДУШЕ МЫ ХУМАН.
	hair_color = "FFFF00" // ВОЛОСЫ ВСЕГДА САЛЬНО-МОЧЕВОГО ЦВЕТА. ДАДИМ ОТПОР НЕФАРАМ С СИНИМИ ВОЛОСАМИ.

	mutanteyes = /obj/item/organ/eyes/luminescent_crystal // А ЗАЧЕМ ТЕБЕ ТАКИЕ БОЛЬШИЕ ГЛАЗА??? ЧТОБЫ ЛУЧШЕ ТЕБЯ ВИДЕТЬ, ВНУЧЕНЬКА.
	mutant_organs = list(/obj/item/organ/heart/strange_crystal)
	mutant_brain = /obj/item/organ/brain/crystal

	disliked_food = VEGETABLES // МЫ ТОКСИЧНЫЕ УЕБАНЫ, ЧТО ПИТАЕМСЯ СИЛОЙ СОЛНЦА И РАДИАЦИЕЙ. КАКИНЕ ЕЩЕ ОПРАВДАНИЯ.
	liked_food = TOXIC | MEAT | RAW // ЖРЁМ ВСЯКИЙ КАЛЛ.
	toxic_food = ANTITOXIC

	burnmod = 4 // ГАЙД КАК СДОХНУТЬ ЗА 4 СЕКУНДЫ ОТ ОГНЯ.
	heatmod = 4
	brutemod = 2

	species_traits = list(NOGENITALS,LIPS,NOBLOOD,NOAROUSAL,HAIR) // НЕТ СИСИК, НЕТ ПИСИК, НЕТ КРОВИ (МЫ ВСЁ ТАКИ ФЭМЭЛИ ФРЕНДЛИ СЕРВЕР), А ТАК ЖЕ НИКАКИХ ПОШЛОСТЕЙ.
	inherent_traits = list(TRAIT_NOBREATH,TRAIT_RADIMMUNE,TRAIT_VIRUSIMMUNE,TRAIT_NOBLEED) // ДЫШАТЬ ДЛЯ НУБОВ. РАДЕЙКА НАС НЕ ЕБАШИТ, КАК И ВИРУСЫ.

//
/mob/living/carbon/human/species/nucleation
	race = /datum/species/nucleation

//
// НЕ РАБОТАЕТ, ПОТОМ ПОЧИНЮ.
//
// /mob/living/carbon/human/species/nucleation/proc/crystall_off(mob/living/carbon/human/H)
// 	for(!H.getorganslot(ORGAN_SLOT_HEART))
// 		H.adjustBruteLoss(6*REM, 0)
// 		H.adjustFireLoss(6*REM, 0)
// 	return ..()
//

// СТАРАЯ ВЕРСИЯ ОТХИЛА ОТ РАДИЯ. Я ТАМ ПО ДРУГОМУ ПЕРЕПИСАЛ НИЖЕ. //
// ОТХИЛ НУКЛЕАЦИЙ ОТ РАДИЯ.
// /datum/species/nucleation/proc/handle_reagents(mob/living/carbon/human/H, datum/reagent/R)
//	if(R.name == "Radium") // ПЬЁМ РАДИЙ.
//		if(R.volume >= 1) // ПЬЁМ ДО ДНА.
//			H.adjustBruteLoss(-3) // ЛЕЧИМ 3 БУРЯТА.
//			H.adjustFireLoss(-3) // ЛЕЧИМ 3 ОГНЯ.
//			H.reagents.remove_reagent(R.name, 1) //ВЫВОДИМ ЗА ТИК РАДИЙ ИЗ-ЗА ЛЕЧЕНИЯ.
//			if(H.radiation < 80) // ЕСЛИ МЫ НЕ В РАДИАЦИИ.
//				H.apply_effect(4, EFFECT_IRRADIATE) // ТО ЗАРАЖАЕМСЯ ЕЮ НА 4 ТИКЕ, НУ ШОБ ТЕ КТО РЯДОМ НЕ ВТЫКАЛИ.
//			return FALSE
//	return ..()

/datum/reagent/radium/on_mob_life(mob/living/carbon/human/species/nucleation/M) // ПЬЁМ РАДИУМ БАЙКАЛЬСКИЙ
	if(isnucleation(M))
		M.adjustBruteLoss(-3*REM, 0) // ДА ЗАЖИВЛЯЕМСЯ.
		M.adjustFireLoss(-3*REM, 0)
	return ..()

/datum/action/innate/ability/shahid // НУ ТИПА ТАКОЙ ЖЕ ВЗРЫВ КАК И ПРИ СМЕРТИ - ТОЛЬКО НАМЕРЕННЫЙ И В ДВА РАЗА СИЛЬНЕЕ.
	name = "Blow yourself up"
	check_flags = AB_CHECK_CONSCIOUS
	button_icon_state = "explosion"
	icon_icon = 'icons/mob/actions/actions.dmi'
	background_icon_state = "bg_alien"
	required_mobility_flags = NONE

/datum/action/innate/ability/shahid/Activate() // АКТИВАЦИЯ ВЗРЫВА НАМЕРЕННОГО.
	var/turf/T = get_turf(usr)
	explosion(T, 0, 1, 6, 9, flame_range = 6) // ЕСЛИ ТЫ БЫЛ РЯДОМ - Я ТЕБЕ СОЖАЛЕЮ.
	qdel(usr)

// НУ ПУСТЬ СВЕТИТСЯ КАК СОЛНЫШКО, А ЕМУ ТИПА ПОКЛОНЯТЬСЯ БУДУТ, КАК ПИДОРЫ ЕГИПЕТСКИЕ.
/datum/species/nucleation/on_species_gain(mob/living/carbon/human/H)
	..()
	H.light_color = "#1C1C00" // ДАЁМ СВЕТ ЧЕЛИКАМ.
	H.set_light(4)
//	H.grant_ability_from_source(list(INNATE_ABILITY_NUCLEATID_SHAHID), ABILITY_SOURCE_SPECIES) // ДАЁМ АБИЛКУ ШАХИДА.

/datum/species/nucleation/on_species_loss(mob/living/carbon/human/H)
	..()
	H.light_color = null
	H.set_light(0)

// СГОРЕЛ = ПРОИГРАЛ. БУКВАЛЬНО. ЛУЧШЕ ЕГО НЕ ТРОГАТЬ, ОТВЕЧАЮ.

/datum/species/nucleation/spec_death(gibbed, mob/living/carbon/human/H) // ВЗРЫВ ПРИ СМЕРТИ. ДОВОЛЬНО МАЛЕНЬКИЙ.
	var/turf/T = get_turf(H)
	H.visible_message("<span class='warning'>Тело [H] взрывается, оставляя после себя множество микроскопических кристаллов!</span>")
	explosion(T, 0, 1, 4, 6, flame_range = 5) // ЕСЛИ ТЫ БЫЛ РЯДОМ - Я ТЕБЕ СОЖАЛЕЮ.
	qdel(H)

// БОМБЕЗНОГО ЯЗЫКА У НИХ НЕ БУДЕТ, ПОТОМУ ЧТО ЭТО ЛЮДИ. ЧТО-ТО ТИПА ПЛАЗМАМЕНОВ.

// ЗА ТО БУДУТ КРУТЫЕ ПРИЧЕСКИ.

/datum/sprite_accessory/hair/nucleation // ТОП 7 НЕФАРСКИХ СТРИЖЕК ЧТОБ ТЕБЯ ОТПИЗДИЛИ В ПОДВОРОТНЯХ.
	name = "Nucleation Hair 1"
	icon_state = "crystal_s"
	icon = 'modular_bluemoon/krashly/code/modules/mobs/carbon/nucleation/icons/nucleation_face.dmi'
	do_colouration = FALSE
	recommended_species = list(SPECIES_NUCLEATION)

/datum/sprite_accessory/hair/nucleation/betaburns
	name = "Nucleation Hair 2"
	icon_state = "betaburns_s"

/datum/sprite_accessory/hair/nucleation/fallout
	name = "Nucleation Hair 3"
	icon_state = "fallout_s"

/datum/sprite_accessory/hair/nucleation/frission
	name = "Nucleation Hair 4"
	icon_state = "frission_s"

/datum/sprite_accessory/hair/nucleation/gammaray
	name = "Nucleation Hair 5"
	icon_state = "gammaray_s"

/datum/sprite_accessory/hair/nucleation/neutron
	name = "Nucleation Hair 6"
	icon_state = "neutron_s"

/datum/sprite_accessory/hair/nucleation/radical
	name = "Nucleation Hair 7"
	icon_state = "radical_s"
