
//Reminders-
// If you add something to this list, please group it by type and sort it alphabetically instead of just jamming it in like an animal
// cost = 700- Minimum cost, or infinite points are possible.
//////////////////////////////////////////////////////////////////////////////
//////////////////////////// Medical /////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/medical
	group = "Medical"
	crate_type = /obj/structure/closet/crate/medical

//////////////////////////////////////////////////////////////////////////////
/////////////////////////////// Equipment ////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/medical/bodybags
	name = "Bodybags"
	desc = "Когда тела устелают на пол. Содержит 4 коробки с мешками для тел."
	cost = 1200
	contains = list(/obj/item/storage/box/bodybags,
					/obj/item/storage/box/bodybags,
					/obj/item/storage/box/bodybags,
					/obj/item/storage/box/bodybags,)
	crate_name = "bodybag crate"

/datum/supply_pack/medical/bloodpacks
	name = "Blood Pack Variety Crate"
	desc = "Содержит девять различных наборов крови для  введения пациентам, а также два универсальных набора синтетической крови."
	cost = 3000
	contains = list(/obj/item/reagent_containers/blood/synthetics,
					/obj/item/reagent_containers/blood/synthetics,
					/obj/item/reagent_containers/blood/random,
					/obj/item/reagent_containers/blood/APlus,
					/obj/item/reagent_containers/blood/AMinus,
					/obj/item/reagent_containers/blood/BPlus,
					/obj/item/reagent_containers/blood/BMinus,
					/obj/item/reagent_containers/blood/OPlus,
					/obj/item/reagent_containers/blood/OMinus,
					/obj/item/reagent_containers/blood/lizard,
					/obj/item/reagent_containers/blood/jellyblood,
					/obj/item/reagent_containers/blood/insect)
	crate_name = "blood freezer"
	crate_type = /obj/structure/closet/crate/freezer

// BLUEMOON ADD START - кровь для синтетиков
/datum/supply_pack/medical/oilblood
	name = "Hydraulic Fluid Cans Crate"
	desc = "Содержит три канистры с гидравлической жидкостью. Обычно, применяется в механике и для замены жидкостей внутри синтетиков."
	cost = 1500
	contains = list(/obj/item/reagent_containers/blood/oilblood,
					/obj/item/reagent_containers/blood/oilblood,
					/obj/item/reagent_containers/blood/oilblood)
	crate_name = "hydraulic fluid crate"
	crate_type = /obj/structure/closet/crate

/datum/supply_pack/medical/oilblood_deluxe
	name = "Super-Pressurized Hydraulic Fluid Crate"
	desc = "Содержит пять ёмкостей с инновационной гидравлической жидкостью, способной усваиваться гораздо быстрее и в большем объёме."
	cost = 4000
	contains = list(/obj/item/reagent_containers/glass/bottle/synthblood_deluxe,
					/obj/item/reagent_containers/glass/bottle/synthblood_deluxe,
					/obj/item/reagent_containers/glass/bottle/synthblood_deluxe,
					/obj/item/reagent_containers/glass/bottle/synthblood_deluxe,
					/obj/item/reagent_containers/glass/bottle/synthblood_deluxe)
	crate_name = "deluxe hydraulic fluid crate"
	crate_type = /obj/structure/closet/crate
// BLUEMOON ADD END

/datum/supply_pack/medical/chemical
	name = "Chemical Starter Kit Crate"
	desc = "Содержит двенадцать различных химических веществ для всех забавных экспериментов, которые вы можете провести."
	cost = 1700
	contains = list(/obj/item/reagent_containers/glass/bottle/hydrogen,
					/obj/item/reagent_containers/glass/bottle/carbon,
					/obj/item/reagent_containers/glass/bottle/nitrogen,
					/obj/item/reagent_containers/glass/bottle/oxygen,
					/obj/item/reagent_containers/glass/bottle/fluorine,
					/obj/item/reagent_containers/glass/bottle/phosphorus,
					/obj/item/reagent_containers/glass/bottle/silicon,
					/obj/item/reagent_containers/glass/bottle/chlorine,
					/obj/item/reagent_containers/glass/bottle/radium,
					/obj/item/reagent_containers/glass/bottle/sacid,
					/obj/item/reagent_containers/glass/bottle/ethanol,
					/obj/item/reagent_containers/glass/bottle/potassium,
					/obj/item/clothing/glasses/science,
					/obj/item/reagent_containers/dropper,
					/obj/item/storage/box/beakers)
	crate_name = "chemical crate"

/datum/supply_pack/medical/defibs
	name = "Defibrillator Crate"
	desc = "Содержит два дефибриллятора для возвращения к жизни."
	cost = 2500
	contains = list(/obj/item/defibrillator/loaded,
					/obj/item/defibrillator/loaded)
	crate_name = "defibrillator crate"

/datum/supply_pack/medical/iv_drip
	name = "IV Drip Crate"
	desc = "Содержит три подставки для капельницы."
	cost = 800
	contains = list(/obj/machinery/iv_drip,
					/obj/machinery/iv_drip,
					/obj/machinery/iv_drip)
	crate_name = "iv drip crate"

/datum/supply_pack/medical/medicalhardsuit
	name = "Medical Hardsuits crate"
	desc = "Есть люди, которых вынесло в космос? Пробоина в той комнате, где труп вашего товарища? Не бойтесь, теперь вы можете купить три медицинских скафандра с масками и баллонами для воздуха, чтобы спасти своих товарищей по экипажу. Требуется медицинский доступ для открытия."
	cost = 8250
	access = ACCESS_MEDICAL
	contains = list(/obj/item/tank/internals/air,
					/obj/item/clothing/mask/gas,
					/obj/item/clothing/suit/space/hardsuit/medical,
					/obj/item/tank/internals/air,
					/obj/item/clothing/mask/gas,
					/obj/item/clothing/suit/space/hardsuit/medical,
					/obj/item/tank/internals/air,
					/obj/item/clothing/mask/gas,
					/obj/item/clothing/suit/space/hardsuit/medical)
	crate_name = "medical hardsuit"
	crate_type = /obj/structure/closet/crate/secure/medical

/datum/supply_pack/medical/paramedicevasuit
	name = "Paramedic EVA Suit"
	desc = "Станьте спасителем, в котором отчаянно нуждается эта станция, и получите свой EVA костюм парамедика уже сегодня! Требуется медицинский доступ для открытия."
	cost = 1975
	access = ACCESS_MEDICAL
	contains = list(/obj/item/tank/internals/emergency_oxygen,
					/obj/item/clothing/head/helmet/space/eva/paramedic,
					/obj/item/clothing/suit/space/eva/paramedic,
					/obj/item/clothing/mask/breath)
	crate_name = "paramedic EVA suit"
	crate_type = /obj/structure/closet/crate/secure/medical

/datum/supply_pack/medical/supplies
	name = "Medical Supplies Crate"
	desc = "Содержит семь мензурок, шприцы и мешки для трупов. Три пузырька с морфием, четыре таблетки инсулина. Две бутылки с  углем, бутылки с адреналином, бутылки с антитоксином и большие мензурки, а также флакон стимулирующих таблеток на долгие, тяжелые рабочие дни. Немецкий врач в комплект не входит."
	cost = 2500
	contains = list(/obj/item/reagent_containers/glass/bottle/charcoal,
					/obj/item/reagent_containers/glass/bottle/charcoal,
					/obj/item/reagent_containers/glass/bottle/epinephrine,
					/obj/item/reagent_containers/glass/bottle/epinephrine,
					/obj/item/reagent_containers/glass/bottle/morphine,
					/obj/item/reagent_containers/glass/bottle/morphine,
					/obj/item/reagent_containers/glass/bottle/morphine,
					/obj/item/reagent_containers/glass/bottle/toxin,
					/obj/item/reagent_containers/glass/bottle/toxin,
					/obj/item/reagent_containers/glass/beaker/large,
					/obj/item/reagent_containers/glass/beaker/large,
					/obj/item/reagent_containers/pill/insulin,
					/obj/item/reagent_containers/pill/insulin,
					/obj/item/reagent_containers/pill/insulin,
					/obj/item/reagent_containers/pill/insulin,
					/obj/item/stack/medical/gauze,
					/obj/item/storage/box/beakers,
					/obj/item/storage/box/medsprays,
					/obj/item/storage/box/syringes,
					/obj/item/storage/box/bodybags,
					/obj/item/storage/pill_bottle/stimulant,
					/obj/item/stack/medical/bone_gel,
					/obj/item/stack/medical/bone_gel)
	crate_name = "medical supplies crate"

/datum/supply_pack/medical/adv_surgery_tools
	name = "Med-Co Advanced Surgery Tools"
	desc = "В этот ящик входит полный набор хирургических инструментов MedCo advanced, а также банка синтетической плоти. Требуется Хирургический доступ для открытия"
	cost = 5500
	access = ACCESS_SURGERY
	contains = list(/obj/item/storage/belt/medical/surgery_belt_adv,
					/obj/item/reagent_containers/medspray/synthflesh,
					/obj/item/reagent_containers/medspray/sterilizine)
	crate_name = "medco surgery tools"
	crate_type = /obj/structure/closet/crate/secure/medical

/datum/supply_pack/medical/surgery
	name = "Surgical Supplies Crate"
	desc = "Вы хотите сделать операцию, но у вас нет ни одной из этих модных докторских степеней? Просто начните с этого ящика, содержащего медицинскую сумку, стерилизующий спрей, складную кровать на роликах и набор анестетика."
	cost = 1500
	contains = list(/obj/item/storage/backpack/duffelbag/med/surgery,
					/obj/item/reagent_containers/medspray/sterilizine,
					/obj/item/roller,
					/obj/item/tank/internals/anesthetic,
					/obj/item/clothing/mask/breath/medical)
	crate_name = "surgical supplies crate"

// BLUEMOON ADD START
/datum/supply_pack/medical/anesthetic
	name = "Anesthetic Tank Crate"
	desc = "Много пациентов, нехватка сонного газа? Не беда, этот ящик содержит сразу три набора для анестезии."
	cost = 1200
	access = ACCESS_SURGERY
	contains = list(/obj/item/tank/internals/anesthetic,
					/obj/item/tank/internals/anesthetic,
					/obj/item/tank/internals/anesthetic,
					/obj/item/clothing/mask/breath/medical,
					/obj/item/clothing/mask/breath/medical,
					/obj/item/clothing/mask/breath/medical)
	crate_name = "anesthetic tank crate"
// BLUEMOON ADD END

//////////////////////////////////////////////////////////////////////////////
///////////////////////////// Medical Kits ///////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/medical/sprays
	name = "Medical Sprays"
	desc = "Содержит две банки of Styptic Spray, Silver Sulfadiazine Spray, Synthflesh Spray и Sterilizer Compound Spray."
	cost = 2250
	contains = list(/obj/item/reagent_containers/medspray/styptic,
					/obj/item/reagent_containers/medspray/styptic,
					/obj/item/reagent_containers/medspray/silver_sulf,
					/obj/item/reagent_containers/medspray/silver_sulf,
					/obj/item/reagent_containers/medspray/synthflesh,
					/obj/item/reagent_containers/medspray/synthflesh,
					/obj/item/reagent_containers/medspray/sterilizine,
					/obj/item/reagent_containers/medspray/sterilizine)
	crate_name = "medical supplies crate"

/datum/supply_pack/medical/advrad
	name = "Radiation Treatment Crate Deluxe"
	desc = "Ящик на случай, если радиация выйдет из-под контроля... содержит два набора rad-b-gone, один флакон роскошных таблеток от радиации, а также флакон роскошных таблеток для лучевой терапии."
	cost = 3500
	contains = list(/obj/item/storage/pill_bottle/antirad_plus,
					/obj/item/storage/pill_bottle/mutarad,
					/obj/item/storage/firstaid/radbgone,
					/obj/item/storage/firstaid/radbgone,
					/obj/item/geiger_counter,
					/obj/item/geiger_counter)
	crate_name = "radiation protection crate"
	crate_type = /obj/structure/closet/crate/radiation

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////// Virology ////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/medical/virus
	name = "Virus Crate"
	desc = "Содержит двенадцать различных флаконов, содержащих несколько образцов вирусов для вирусологических исследований. Также включает в себя семь мензурок и шприцы. Скомканные джинсы в комплект не входят. Для открытия требуется доступ CMO."
	cost = 2500
	access = ACCESS_CMO
	contains = list(/obj/item/reagent_containers/glass/bottle/flu_virion,
					/obj/item/reagent_containers/glass/bottle/cold,
					/obj/item/reagent_containers/glass/bottle/random_virus,
					/obj/item/reagent_containers/glass/bottle/random_virus,
					/obj/item/reagent_containers/glass/bottle/random_virus,
					/obj/item/reagent_containers/glass/bottle/random_virus,
					/obj/item/reagent_containers/glass/bottle/fake_gbs,
					/obj/item/reagent_containers/glass/bottle/magnitis,
					/obj/item/reagent_containers/glass/bottle/pierrot_throat,
					/obj/item/reagent_containers/glass/bottle/brainrot,
					/obj/item/reagent_containers/glass/bottle/anxiety,
					/obj/item/reagent_containers/glass/bottle/beesease,
					/obj/item/storage/box/syringes,
					/obj/item/storage/box/beakers,
					/obj/item/reagent_containers/glass/bottle/mutagen)
	crate_name = "virus crate"
	crate_type = /obj/structure/closet/crate/secure/plasma
	dangerous = TRUE
	can_private_buy = FALSE

/datum/supply_pack/medical/anitvirus
	name = "Virus Containment Crate"
	desc = "Вирусолог снова выпустил смертельную чуму Mk II? Кто-то не помыл руки? Старые язвы, рожденные заново? Что ж, этот ящик для вас! Надеюсь, вы вылечите его до того, как он вырвется за пределы станции... Для открытия этого ящика требуется медицинский доступ, и в нем есть два биокостюма, коробка с шприцами и мензурками, пять шприцов с космоциллином и медибот."
	cost = 3000
	access = ACCESS_MEDICAL
	contains = list(/mob/living/simple_animal/bot/medbot,
					/obj/item/clothing/head/bio_hood,
					/obj/item/clothing/head/bio_hood,
					/obj/item/clothing/suit/bio_suit,
					/obj/item/clothing/suit/bio_suit,
					/obj/item/reagent_containers/syringe/antiviral,
					/obj/item/reagent_containers/syringe/antiviral,
					/obj/item/reagent_containers/syringe/antiviral,
					/obj/item/reagent_containers/syringe/antiviral,
					/obj/item/reagent_containers/syringe/antiviral,
					/obj/item/storage/box/syringes,
					/obj/item/storage/box/beakers)
	crate_name = "virus containment unit crate"
	crate_type = /obj/structure/closet/crate/secure/plasma

/datum/supply_pack/medical/medipen_variety
	name = "Medipen Variety-Pak"
	desc = "Содержит восемь различных медикаментов в трех различных вариантах, чтобы помочь в быстром лечении пациентов с серьезными травмами."
	cost = 2000
	contains = list(/obj/item/reagent_containers/hypospray/medipen,
					/obj/item/reagent_containers/hypospray/medipen,
					/obj/item/reagent_containers/hypospray/medipen/ekit,
					/obj/item/reagent_containers/hypospray/medipen/ekit,
					/obj/item/reagent_containers/hypospray/medipen/ekit,
					/obj/item/reagent_containers/hypospray/medipen/blood_loss,
					/obj/item/reagent_containers/hypospray/medipen/blood_loss,
					/obj/item/reagent_containers/hypospray/medipen/blood_loss)
	crate_name = "medipen crate"

/datum/supply_pack/medical/medbeamgun
	name = "Two Civilian Medbeam Guns"
	desc = "Содержит одну слабую версию медицинского орудия, которое хорошо подходит для стабилизации пациентов в критическом состоянии."
	cost = 25000
	contains = list(/obj/item/gun/medbeam/weak,
					/obj/item/gun/medbeam/weak)
	crate_name = "Two Civilian Medbeam Guns Crate"
