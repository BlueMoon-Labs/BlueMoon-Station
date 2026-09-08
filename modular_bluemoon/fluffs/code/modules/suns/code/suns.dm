// SUNS faction wardrobe (personal skins for noterravija & dagran)
// Ported from Shiptest (code/modules/clothing/factions/suns.dm).
// Policy: donator loadout may only contain non-gameplay skins.
// Suits / gloves / glasses-with-HUD / welding visors / hoods are provided
// exclusively as conversion modkits for existing in-game items.

// //////////////////////////////////////////////////////// uniforms

/obj/item/clothing/under/syndicate/suns
	name = "SUNS formal suit"
	desc = "A fancy-looking tailored suit with purple slacks. Worn typically by students in the first half of their academic journey."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/uniforms.dmi'
	icon_state = "suns_uniform1"
	can_adjust = FALSE
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/under/syndicate/suns/uniform2
	name = "SUNS senior formal suit"
	desc = "A uniform typically worn by students in the final years of their academic journey."
	icon_state = "suns_uniform2"

/obj/item/clothing/under/syndicate/suns/uniform3
	name = "SUNS graduate suit"
	desc = "A suit typically worn by SUNS graduates and SUNS academic staff. You've come a long way, friend."
	icon_state = "suns_uniform3"

/obj/item/clothing/under/syndicate/suns/pkuniform
	name = "SUNS peacekeeper uniform"
	desc = "A uniform designed for ease of movement for both the classroom and the frontier."
	icon_state = "suns_pkuniform"

/obj/item/clothing/under/syndicate/suns/workerjumpsuit
	name = "SUNS work jumpsuit"
	desc = "A casual uniform worn by students and staff to protect from blue collar work."
	icon_state = "suns_workerjumpsuit"

/obj/item/clothing/under/syndicate/suns/captain
	name = "SUNS captain suit"
	desc = "An elaborate uniform to set high ranking staff from academia apart from the rest."
	icon_state = "suns_captain"

/obj/item/clothing/under/syndicate/suns/xo
	name = "SUNS academic suit"
	desc = "A style of suit typically worn by academic staff."
	icon_state = "suns_xo"

/obj/item/clothing/under/syndicate/suns/sciencejumpsuit
	name = "SUNS lab jumpsuit"
	desc = "A comfortable suit meant to protect the individual from exposure to harmful objects."
	icon_state = "suns_sciencejumpsuit"

/obj/item/clothing/under/syndicate/suns/doctorscrubs
	name = "SUNS medical scrubs"
	desc = "Work safe medical scrubs for both the professionals and the trainees."
	icon_state = "suns_doctorscrubs"

// //////////////////////////////////////////////////////// hats (loadout, cosmetic only)

/obj/item/clothing/head/suns
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/head.dmi'

/obj/item/clothing/head/suns/staffberet
	name = "academic staff beret"
	desc = "A soft beret sporting a discontinued inkwell quill feather. If only it could hold ink once more."
	icon_state = "suns_xoberet"

/obj/item/clothing/head/suns/workerhelmet
	name = "SUNS worker helmet"
	desc = "A piece of headgear used in dangerous working conditions to protect the head."
	icon_state = "suns_workerhelmet"
	flags_inv = HIDEHAIR

/obj/item/clothing/head/suns/pkcap
	name = "SUNS peacekeeper cap"
	desc = "A black cap worn by the more eccentric peacekeepers."
	icon_state = "suns_pkcap"

/obj/item/clothing/head/suns/surgerycap
	name = "SUNS surgery cap"
	desc = "A surgery cap used by academic students and professionals alike."
	icon_state = "suns_doctorcap"
	flags_inv = HIDEHAIR

/obj/item/clothing/head/suns/captainbicorne
	name = "SUNS bicorne hat"
	desc = "A unique bicorne hat given to SUNS Captains to display academic seniority."
	icon_state = "suns_captainbicorne"

/obj/item/clothing/head/suns/doctorhat
	name = "SUNS medical instructor hat"
	desc = "A hat worn by the more eccentric medical staff."
	icon_state = "suns_doctorhat"

// //////////////////////////////////////////////////////// welding visors (modkit products)

/obj/item/clothing/head/welding/suns_visor
	name = "SUNS peacekeeper visor"
	desc = "A head-mounted helmet designed to protect those on the field from bright lights, while also allowing a life support connection. The warnings on this helmet suggest it is not spaceworthy."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/head.dmi'
	icon_state = "sunsvisor"
	item_state = "sunsvisor"

/obj/item/clothing/head/welding/suns_visor/hos
	name = "gilded SUNS peacekeeper visor"
	desc = "A head-mounted helmet designed to protect those on the field, this one has a gold lining to indicate rank. The warnings on this helmet suggest it is not spaceworthy."
	icon_state = "sunslpkvisor"
	item_state = "sunslpkvisor"

// //////////////////////////////////////////////////////// masks

/obj/item/clothing/mask/gas/suns
	name = "SUNS black gas mask"
	desc = "A black face covering that allows the user to connect to a personal gas supply. Surprisingly not great at preventing gas inhalation."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/mask.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/mask.dmi'
	icon_state = "suns_gasmask"

/obj/item/clothing/mask/surgical/suns
	name = "SUNS purple sterile mask"
	desc = "A sterile mask designed to help prevent the spread of diseases. Now in purple! Pretty!"
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/mask.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/mask.dmi'
	icon_state = "suns_sterile"

/obj/item/clothing/mask/breath/suns
	name = "SUNS half face mask"
	desc = "A close-fitting mask that covers JUST enough to connect an air supply."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/mask.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/mask.dmi'
	icon_state = "suns_captainmask"

// //////////////////////////////////////////////////////// cloaks

/obj/item/clothing/neck/cloak/suns
	name = "SUNS short cloak"
	desc = "Worn by both the young and old alike. You can almost feel the academic pride."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/neck.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/neck.dmi'
	icon_state = "suns_shouldercape"

/obj/item/clothing/neck/cloak/suns/xo
	name = "SUNS academic staff cloak"
	desc = "Worn by SUNS staff, you can almost smell all of the failing grades this cloak has given."
	icon_state = "suns_xocape"

/obj/item/clothing/neck/cloak/suns/cap
	name = "SUNS captain's cloak"
	desc = "Worn by SUNS captains. This cloak has a very imposing aura to it."
	icon_state = "suns_captaincloak"

// //////////////////////////////////////////////////////// shoes

/obj/item/clothing/shoes/sneakers/suns
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/feet.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/feet.dmi'

/obj/item/clothing/shoes/sneakers/suns/doctorclogs
	name = "SUNS white clogs"
	desc = "Comfortable clogs for general use."
	icon_state = "suns_doctorclogs"

/obj/item/clothing/shoes/combat/suns
	name = "SUNS fancy combat boots"
	desc = "Decent traction combat boots worn by high ranking academic staff."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/feet.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/feet.dmi'
	icon_state = "suns_captainboots"

/obj/item/clothing/shoes/jackboots/suns
	name = "SUNS work safe jackboots"
	desc = "Academic issued steel toed boots. For those with physically demanding majors."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/feet.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/feet.dmi'
	icon_state = "suns_jackboots"

/obj/item/clothing/shoes/jackboots/suns/long
	name = "SUNS peacekeeper longboots"
	desc = "Longboots worn by academic security staff and trainees."
	icon_state = "suns_longboots"

/obj/item/clothing/shoes/laceup/suns
	name = "SUNS academy laceup shoes"
	desc = "Standard issue laceups from the syndicates resident academy."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/feet.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/feet.dmi'
	icon_state = "suns_laceups"

// //////////////////////////////////////////////////////// accessories

/obj/item/clothing/accessory/waistcoat/suns
	name = "SUNS waistcoat"
	desc = "An academic issued run of the mill waistcoat."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/accessory.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/accessory.dmi'
	icon_state = "suns_waistcoat"
	minimize_when_attached = TRUE

/obj/item/clothing/accessory/waistcoat/suns/ribbon
	name = "SUNS ribbon"
	desc = "An academic issued bow, for when you want to feel pretty."
	icon_state = "suns_ribbon"

/obj/item/clothing/accessory/waistcoat/suns/gembow
	name = "SUNS gem bow"
	desc = "An academic issued bow, for when you want to feel REALLY pretty."
	icon_state = "suns_gembow"

/obj/item/clothing/accessory/waistcoat/suns/poof
	name = "SUNS chest poof"
	desc = "An academic issued bow, for when you want to feel sophisticated."
	icon_state = "suns_poof"

// //////////////////////////////////////////////////////// spacesuits & hardsuits (modkit products)

/obj/item/clothing/head/helmet/space/eva/suns
	name = "SUNS EVA helmet"
	desc = "An academic standard EVA helmet. Normally reserved for low budget tasks in space."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/head.dmi'
	icon_state = "suns_vachelm"
	item_state = "suns_vachelm"

/obj/item/clothing/suit/space/eva/suns
	name = "SUNS EVA suit"
	desc = "An academic standard EVA suit. Normally reserved for low budget tasks in space."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/suits.dmi'
	icon_state = "suns_vacsuit"
	item_state = "suns_vacsuit"

/obj/item/clothing/head/helmet/space/hardsuit/security/suns
	name = "SUNS peacekeeper hardsuit helmet"
	desc = "An academic standard spacesuit helmet, reinforced for peacekeeping duties."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/head.dmi'
	icon_state = "hardsuit0-suns_pk"
	item_state = "hardsuit0-suns_pk"
	hardsuit_type = "suns_pk"
	unique_reskin = null

/obj/item/clothing/suit/space/hardsuit/security/suns
	name = "SUNS peacekeeper hardsuit"
	desc = "An academic standard spacesuit reinforced for peacekeeping duties on the frontier."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/suits.dmi'
	icon_state = "suns_pkhardsuit"
	item_state = "suns_pkhardsuit"
	hardsuit_type = "suns_pk"
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/security/suns
	unique_reskin = null

/obj/item/clothing/head/helmet/space/hardsuit/mining/suns
	name = "SUNS industrial hardsuit helmet"
	desc = "An academic standard spacesuit helmet, built for industrial work."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/head.dmi'
	icon_state = "hardsuit0-suns_mining"
	item_state = "hardsuit0-suns_mining"
	hardsuit_type = "suns_mining"

/obj/item/clothing/suit/space/hardsuit/mining/suns
	name = "SUNS industrial hardsuit"
	desc = "An academic standard spacesuit built for industrial work and excavation."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/suits.dmi'
	icon_state = "suns_miningsuit"
	item_state = "suns_miningsuit"
	hardsuit_type = "suns_mining"
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/mining/suns

/obj/item/clothing/head/helmet/space/hardsuit/captain/suns
	name = "SUNS captain's hardsuit helmet"
	desc = "An armored spaceproof helmet, the white glass on the side signifies a captain level rank."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/head.dmi'
	icon_state = "hardsuit0-suns_solgov"
	item_state = "hardsuit0-suns_solgov"
	hardsuit_type = "suns_solgov"

/obj/item/clothing/suit/space/hardsuit/captain/suns
	name = "SUNS captain's hardsuit"
	desc = "A well decorated spaceworthy suit. The design was co-created by SolGov and SUNS academics."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/suits.dmi'
	icon_state = "suns_commandsuit"
	item_state = "suns_commandsuit"
	hardsuit_type = "suns_solgov"
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/captain/suns

// //////////////////////////////////////////////////////// armored coats (modkit products)
// Все скины наследуют от armor/vest и конвертятся из его стат-эквивалентных
// вариантов (peacekeeper/alt — см. harness_kit в fluffs/code/suit.dm).

/obj/item/clothing/suit/armor/vest/suns
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/suits.dmi'
	dog_fashion = null

/obj/item/clothing/suit/armor/vest/suns/pkarmor
	name = "SUNS peacekeeper plating"
	desc = "A standard issue set of plate assigned to peacekeepers, both durable and stylish."
	icon_state = "suns_pkarmor"

/obj/item/clothing/suit/armor/vest/suns/hos
	name = "gilded SUNS peacekeeper plating"
	desc = "A set of plate assigned to peacekeepers, both durable and stylish. This one has a gold lining to indicate rank."
	icon_state = "suns_lpkarmor"

/obj/item/clothing/suit/armor/vest/suns/greatcoat
	name = "SUNS peacekeeper greatcoat"
	desc = "A funky armored coat worn by eccentric peacekeepers. Closing the coat is socially improper."
	icon_state = "suns_greatcoat"

/obj/item/clothing/suit/armor/vest/suns/captaincoat
	name = "SUNS decorated academic coat"
	desc = "An armored coat intended for SUNS captains on the frontier. Go forth, and spread the message of the academy."
	icon_state = "suns_captaincoat"

/obj/item/clothing/suit/armor/vest/suns/xojacket
	name = "SUNS academic staff coat"
	desc = "A white coat used by SUNS academic staff. It designates the second in command on the ship."
	icon_state = "suns_xojacket"

// //////////////////////////////////////////////////////// labcoats (modkit products)
// Каждый скин наследует от той разновидности labcoat, которую подменяет:
// обычный labcoat и CMO-лабрат — разные типы, киты и продукты тоже разные.
// Худ-лабатник не может наследовать от labcoat (механика капюшона живёт в
// suit/hooded), поэтому его характеристики совпадают с локальным labcoat явно.

/obj/item/clothing/suit/toggle/labcoat/suns
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/suits.dmi'

/obj/item/clothing/suit/toggle/labcoat/suns/doctorlabcoat
	name = "SUNS doctor's labcoat"
	desc = "A stylized white labcoat frequently worn by SUNS medical staff."
	icon_state = "suns_doctorlabcoat"

/obj/item/clothing/suit/toggle/labcoat/cmo/suns
	name = "SUNS medical instructor coat"
	desc = "A labcoat often worn by the more eccentric medical instructors."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/suits.dmi'
	icon_state = "suns_cmocoat"

/obj/item/clothing/head/hooded/winterhood/suns_labcoathood
	name = "SUNS labcoat hood"
	desc = "A hood to protect you from chemical spills."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/head.dmi'
	icon_state = "suns_labcoathood"
	item_state = "suns_labcoathood"

/obj/item/clothing/suit/hooded/suns_labcoat
	name = "SUNS labcoat"
	desc = "An academic labcoat designed to protect the wearer from chemical and non chemical spills."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/suits.dmi'
	icon_state = "suns_labcoat"
	item_state = "suns_labcoat"
	hoodtype = /obj/item/clothing/head/hooded/winterhood/suns_labcoathood
	blood_overlay_type = "coat"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	species_exception = list(/datum/species/golem)
	allowed = list(
		/obj/item/analyzer,
		/obj/item/stack/medical,
		/obj/item/dnainjector,
		/obj/item/reagent_containers/dropper,
		/obj/item/reagent_containers/syringe,
		/obj/item/reagent_containers/hypospray,
		/obj/item/healthanalyzer,
		/obj/item/flashlight/pen,
		/obj/item/reagent_containers/glass/bottle,
		/obj/item/reagent_containers/glass/beaker,
		/obj/item/reagent_containers/pill,
		/obj/item/storage/pill_bottle,
		/obj/item/paper,
		/obj/item/melee/classic_baton/telescopic,
		/obj/item/soap,
		/obj/item/sensor_device,
		/obj/item/tank/internals/emergency_oxygen,
		/obj/item/tank/internals/plasmaman,
		)
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 50, RAD = 0, FIRE = 50, ACID = 50)
	togglename = "buttons"
	body_parts_covered = CHEST|ARMS

// //////////////////////////////////////////////////////// gloves (modkit products)

/obj/item/clothing/gloves/fingerless/suns
	name = "SUNS stitched fingerless gloves"
	desc = "These gloves offer style, purely and plainly."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/hands.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/hands.dmi'
	icon_state = "suns_glovesfingerless"
	item_state = "suns_glovesfingerless"

/obj/item/clothing/gloves/color/black/suns
	name = "SUNS captain's gloves"
	desc = "Fancy black gloves for trusted SUNS members."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/hands.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/hands.dmi'
	icon_state = "suns_captaingloves"
	item_state = "suns_captaingloves"

/obj/item/clothing/gloves/color/white/suns
	name = "SUNS academic staff gloves"
	desc = "White gloves that offer a good grip with writing utensils."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/hands.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/hands.dmi'
	icon_state = "suns_xogloves"
	item_state = "suns_xogloves"

/obj/item/clothing/gloves/color/yellow/suns
	name = "SUNS insulated gloves"
	desc = "Padded academic gloves that hopefully keep students out of the nurses office."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/hands.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/hands.dmi'
	icon_state = "suns_insulated"
	item_state = "suns_insulated"

/obj/item/clothing/gloves/color/latex/nitrile/suns
	name = "SUNS white nitrile gloves"
	desc = "Thick sterile white gloves that reach up to the elbows. The nanochips that transfer basic paramedic knowledge are disabled during finals week."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/hands.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/hands.dmi'
	icon_state = "suns_latexgloves"
	item_state = "suns_latexgloves"

/obj/item/clothing/gloves/color/latex/nitrile/hsc/suns
	name = "SUNS white nitrile gloves"
	desc = "Thick sterile white gloves that reach up to the elbows. The nanochips that transfer basic paramedic knowledge are disabled during finals week."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/hands.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/hands.dmi'
	icon_state = "suns_latexgloves"
	item_state = "suns_latexgloves"

/obj/item/clothing/gloves/tackler/dolphin/suns
	name = "SUNS peacekeeper tackle gloves"
	desc = "Sleek tackle gloves that allows the user to sail through the air. The main cause of accidents during finals week."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/hands.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/hands.dmi'
	icon_state = "suns_longglovesblack"
	item_state = "suns_longglovesblack"

// //////////////////////////////////////////////////////// eye masks (modkit products)
// Каждая маска наследует от тех очков, которые она подменяет
// (science goggles / health HUD / security HUD sunglasses).

/obj/item/clothing/glasses/science/suns
	name = "SUNS eye mask science goggles"
	desc = "A fancy looking mask to help against chemical spills. This one is fitted with an analyzer for scanning items and reagents."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/eyes.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/eyes.dmi'
	icon_state = "suns_sciencemask"
	item_state = "suns_sciencemask"
	glass_colour_type = /datum/client_colour/glass_colour/purple

/obj/item/clothing/glasses/hud/health/suns
	name = "SUNS eye mask health scanner HUD"
	desc = "A peculiar looking mask commonly seen at academic functions. This one has a health HUD lense in it."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/eyes.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/eyes.dmi'
	icon_state = "suns_doctormask"
	item_state = "suns_doctormask"
	glass_colour_type = /datum/client_colour/glass_colour/lightblue

/obj/item/clothing/glasses/hud/security/sunglasses/suns
	name = "SUNS eye mask security HUD"
	desc = "A peculiar looking mask commonly seen at academic functions. This one gives a heads-up display that scans the humanoids in view and provides accurate data about their ID status and security records."
	icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/obj/eyes.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/suns/icons/mob/eyes.dmi'
	icon_state = "suns_pkmask"
	item_state = "suns_pkmask"
	glass_colour_type = /datum/client_colour/glass_colour/red

// //////////////////////////////////////////////////////// conversion modkits

/obj/item/modkit/suns_evasuit_kit
	name = "SUNS EVA suit Kit"
	desc = "A modkit for making a civilian EVA suit into a SUNS EVA suit."
	product = /obj/item/clothing/suit/space/eva/suns
	fromitem = list(/obj/item/clothing/suit/space/eva)

/obj/item/modkit/suns_evahelmet_kit
	name = "SUNS EVA helmet Kit"
	desc = "A modkit for making a civilian EVA helmet into a SUNS EVA helmet."
	product = /obj/item/clothing/head/helmet/space/eva/suns
	fromitem = list(/obj/item/clothing/head/helmet/space/eva)

/obj/item/modkit/suns_pkhardsuit_kit
	name = "SUNS peacekeeper hardsuit Kit"
	desc = "A modkit for making a security hardsuit into a SUNS peacekeeper hardsuit."
	product = /obj/item/clothing/suit/space/hardsuit/security/suns
	fromitem = list(/obj/item/clothing/suit/space/hardsuit/security)

/obj/item/modkit/suns_mininghardsuit_kit
	name = "SUNS industrial hardsuit Kit"
	desc = "A modkit for making a mining hardsuit into a SUNS industrial hardsuit."
	product = /obj/item/clothing/suit/space/hardsuit/mining/suns
	fromitem = list(/obj/item/clothing/suit/space/hardsuit/mining)

/obj/item/modkit/suns_captainhardsuit_kit
	name = "SUNS captain's hardsuit Kit"
	desc = "A modkit for making a captain's SWAT hardsuit into a SUNS captain's hardsuit."
	product = /obj/item/clothing/suit/space/hardsuit/captain/suns
	fromitem = list(/obj/item/clothing/suit/space/hardsuit/captain)

/obj/item/modkit/suns_visor_kit
	name = "SUNS peacekeeper visor Kit"
	desc = "A modkit for making a welding helmet into a SUNS peacekeeper visor."
	product = /obj/item/clothing/head/welding/suns_visor
	fromitem = list(/obj/item/clothing/head/welding)

/obj/item/modkit/suns_visor_hos_kit
	name = "Gilded SUNS peacekeeper visor Kit"
	desc = "A modkit for making a welding helmet into a gilded SUNS peacekeeper visor."
	product = /obj/item/clothing/head/welding/suns_visor/hos
	fromitem = list(/obj/item/clothing/head/welding)

/obj/item/modkit/suns_pkarmor_kit
	name = "SUNS peacekeeper plating Kit"
	desc = "A modkit for making an armor vest into SUNS peacekeeper plating."
	product = /obj/item/clothing/suit/armor/vest/suns/pkarmor
	fromitem = list(/obj/item/clothing/suit/armor/vest, /obj/item/clothing/suit/armor/vest/alt, /obj/item/clothing/suit/armor/vest/peacekeeper)

/obj/item/modkit/suns_pkarmor_hos_kit
	name = "Gilded SUNS peacekeeper plating Kit"
	desc = "A modkit for making an armor vest into gilded SUNS peacekeeper plating."
	product = /obj/item/clothing/suit/armor/vest/suns/hos
	fromitem = list(/obj/item/clothing/suit/armor/vest, /obj/item/clothing/suit/armor/vest/alt, /obj/item/clothing/suit/armor/vest/peacekeeper)

/obj/item/modkit/suns_greatcoat_kit
	name = "SUNS peacekeeper greatcoat Kit"
	desc = "A modkit for making an armor vest into a SUNS peacekeeper greatcoat."
	product = /obj/item/clothing/suit/armor/vest/suns/greatcoat
	fromitem = list(/obj/item/clothing/suit/armor/vest, /obj/item/clothing/suit/armor/vest/alt, /obj/item/clothing/suit/armor/vest/peacekeeper)

/obj/item/modkit/suns_captaincoat_kit
	name = "SUNS decorated academic coat Kit"
	desc = "A modkit for making an armor vest into a SUNS decorated academic coat."
	product = /obj/item/clothing/suit/armor/vest/suns/captaincoat
	fromitem = list(/obj/item/clothing/suit/armor/vest, /obj/item/clothing/suit/armor/vest/alt, /obj/item/clothing/suit/armor/vest/peacekeeper)

/obj/item/modkit/suns_xojacket_kit
	name = "SUNS academic staff coat Kit"
	desc = "A modkit for making an armor vest into a SUNS academic staff coat."
	product = /obj/item/clothing/suit/armor/vest/suns/xojacket
	fromitem = list(/obj/item/clothing/suit/armor/vest, /obj/item/clothing/suit/armor/vest/alt, /obj/item/clothing/suit/armor/vest/peacekeeper)

/obj/item/modkit/suns_doctorlabcoat_kit
	name = "SUNS doctor's labcoat Kit"
	desc = "A modkit for making a labcoat into a SUNS doctor's labcoat."
	product = /obj/item/clothing/suit/toggle/labcoat/suns/doctorlabcoat
	fromitem = list(/obj/item/clothing/suit/toggle/labcoat)

/obj/item/modkit/suns_cmolabcoat_kit
	name = "SUNS medical instructor coat Kit"
	desc = "A modkit for making a CMO labcoat into a SUNS medical instructor coat."
	product = /obj/item/clothing/suit/toggle/labcoat/cmo/suns
	fromitem = list(/obj/item/clothing/suit/toggle/labcoat/cmo)

/obj/item/modkit/suns_hoodedlabcoat_kit
	name = "SUNS hooded labcoat Kit"
	desc = "A modkit for making a labcoat into a SUNS hooded labcoat."
	product = /obj/item/clothing/suit/hooded/suns_labcoat
	fromitem = list(/obj/item/clothing/suit/toggle/labcoat, /obj/item/clothing/suit/toggle/labcoat/cmo)

/obj/item/modkit/suns_fingerless_kit
	name = "SUNS fingerless gloves Kit"
	desc = "A modkit for making fingerless gloves into SUNS stitched fingerless gloves."
	product = /obj/item/clothing/gloves/fingerless/suns
	fromitem = list(/obj/item/clothing/gloves/fingerless)

/obj/item/modkit/suns_blackgloves_kit
	name = "SUNS captain's gloves Kit"
	desc = "A modkit for making black gloves into SUNS captain's gloves."
	product = /obj/item/clothing/gloves/color/black/suns
	fromitem = list(/obj/item/clothing/gloves/color/black)

/obj/item/modkit/suns_whitegloves_kit
	name = "SUNS academic staff gloves Kit"
	desc = "A modkit for making white gloves into SUNS academic staff gloves."
	product = /obj/item/clothing/gloves/color/white/suns
	fromitem = list(/obj/item/clothing/gloves/color/white)

/obj/item/modkit/suns_insulated_kit
	name = "SUNS insulated gloves Kit"
	desc = "A modkit for making insulated gloves into SUNS insulated gloves."
	product = /obj/item/clothing/gloves/color/yellow/suns
	fromitem = list(/obj/item/clothing/gloves/color/yellow)

/obj/item/modkit/suns_nitrile_kit
	name = "SUNS nitrile gloves Kit"
	desc = "A modkit for making nitrile gloves into SUNS white nitrile gloves."
	product = /obj/item/clothing/gloves/color/latex/nitrile/suns
	fromitem = list(/obj/item/clothing/gloves/color/latex/nitrile)

/obj/item/modkit/suns_nitrile_hsc_kit
	name = "SUNS HSC nitrile gloves Kit"
	desc = "A modkit for making HSC nitrile gloves into SUNS white nitrile gloves."
	product = /obj/item/clothing/gloves/color/latex/nitrile/hsc/suns
	fromitem = list(/obj/item/clothing/gloves/color/latex/nitrile/hsc)

/obj/item/modkit/suns_tackler_kit
	name = "SUNS peacekeeper tackle gloves Kit"
	desc = "A modkit for making dolphin tackle gloves into SUNS peacekeeper tackle gloves."
	product = /obj/item/clothing/gloves/tackler/dolphin/suns
	fromitem = list(/obj/item/clothing/gloves/tackler/dolphin)

/obj/item/modkit/suns_scienceglasses_kit
	name = "SUNS eye mask science goggles Kit"
	desc = "A modkit for making science goggles into a SUNS eye mask science goggles."
	product = /obj/item/clothing/glasses/science/suns
	fromitem = list(/obj/item/clothing/glasses/science)

/obj/item/modkit/suns_healthglasses_kit
	name = "SUNS eye mask health scanner HUD Kit"
	desc = "A modkit for making health scanner HUD glasses into a SUNS eye mask health scanner HUD."
	product = /obj/item/clothing/glasses/hud/health/suns
	fromitem = list(/obj/item/clothing/glasses/hud/health)

/obj/item/modkit/suns_securityglasses_kit
	name = "SUNS eye mask security HUD Kit"
	desc = "A modkit for making security HUD sunglasses into a SUNS eye mask security HUD."
	product = /obj/item/clothing/glasses/hud/security/sunglasses/suns
	fromitem = list(/obj/item/clothing/glasses/hud/security/sunglasses)

// //////////////////////////////////////////////////////// kit box

/obj/item/storage/box/suns_kit
	name = "SUNS kit"
	desc = "Military box that contains a full kit of SUNS conversion kits."
	icon_state = "ammobox"

/obj/item/storage/box/suns_kit/PopulateContents()
	new /obj/item/modkit/suns_evasuit_kit(src)
	new /obj/item/modkit/suns_evahelmet_kit(src)
	new /obj/item/modkit/suns_pkhardsuit_kit(src)
	new /obj/item/modkit/suns_mininghardsuit_kit(src)
	new /obj/item/modkit/suns_captainhardsuit_kit(src)
	new /obj/item/modkit/suns_visor_kit(src)
	new /obj/item/modkit/suns_visor_hos_kit(src)
	new /obj/item/modkit/suns_pkarmor_kit(src)
	new /obj/item/modkit/suns_pkarmor_hos_kit(src)
	new /obj/item/modkit/suns_greatcoat_kit(src)
	new /obj/item/modkit/suns_captaincoat_kit(src)
	new /obj/item/modkit/suns_xojacket_kit(src)
	new /obj/item/modkit/suns_doctorlabcoat_kit(src)
	new /obj/item/modkit/suns_cmolabcoat_kit(src)
	new /obj/item/modkit/suns_hoodedlabcoat_kit(src)
	new /obj/item/modkit/suns_fingerless_kit(src)
	new /obj/item/modkit/suns_blackgloves_kit(src)
	new /obj/item/modkit/suns_whitegloves_kit(src)
	new /obj/item/modkit/suns_insulated_kit(src)
	new /obj/item/modkit/suns_nitrile_kit(src)
	new /obj/item/modkit/suns_nitrile_hsc_kit(src)
	new /obj/item/modkit/suns_tackler_kit(src)
	new /obj/item/modkit/suns_scienceglasses_kit(src)
	new /obj/item/modkit/suns_healthglasses_kit(src)
	new /obj/item/modkit/suns_securityglasses_kit(src)
