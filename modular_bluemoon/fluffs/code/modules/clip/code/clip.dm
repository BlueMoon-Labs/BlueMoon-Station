// CLIP faction wardrobe (personal skins).
// Port of the CLIP faction clothing, same layout as suns.dm.
// Одежда выдаётся через лодаут без статов (параметры берутся у обычных родителей).
// Скафандры, шлемы, био-костюмы, броня riot и меха выдаются только через улучшалки (коробка CLIP kit).
//
// Иконки: modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/*.dmi (предметы) и items/mob/*.dmi (на персонаже).


// //////////////////////////////////////////////////////// uniforms

/obj/item/clothing/under/syndicate/clip
	name = "CLIP deck uniform"
	desc = "A utilitarian jumpsuit worn by CLIP deck crew."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/uniforms.dmi'
	icon_state = "clip_deck"
	can_adjust = FALSE
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/under/syndicate/clip/minuteman
	name = "CLIP minuteman uniform"
	desc = "A hard-wearing field uniform issued to CLIP minutemen."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/uniforms.dmi'
	icon_state = "clip_minuteman"
	can_adjust = FALSE
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/under/syndicate/clip/formal
	name = "CLIP formal uniform"
	desc = "A crisp formal uniform of the Confederated League."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/uniforms.dmi'
	icon_state = "clip_formal"
	can_adjust = FALSE
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/under/syndicate/clip/formal_skirt
	name = "CLIP formal skirt"
	desc = "A crisp formal uniform of the Confederated League, with a skirt."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/uniforms.dmi'
	icon_state = "clip_formal_skirt"
	can_adjust = FALSE
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	body_parts_covered = CHEST|GROIN|ARMS

/obj/item/clothing/under/syndicate/clip/medic
	name = "CLIP medical uniform"
	desc = "A uniform worn by CLIP medical staff."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/uniforms.dmi'
	icon_state = "clip_medic"
	can_adjust = FALSE
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

// //////////////////////////////////////////////////////// coats (cosmetic suits)

/obj/item/clothing/suit/jacket/clip_general
	name = "CLIP general's coat"
	desc = "A decorated coat worn by generals of the Confederated League."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/suits.dmi'
	icon_state = "clip_general"
	item_state = "clip_general"

/obj/item/clothing/suit/jacket/clip_admiral
	name = "CLIP admiral's coat"
	desc = "A decorated coat worn by admirals of the Confederated League."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/suits.dmi'
	icon_state = "clip_admiral"
	item_state = "clip_admiral"

/obj/item/clothing/suit/jacket/clip_captaincoat
	name = "CLIP captain's coat"
	desc = "A long coat worn by CLIP ship captains."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/suits.dmi'
	icon_state = "clip_captaincoat"
	item_state = "clip_captaincoat"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/jacket/clip_trenchcoat
	name = "CLIP trenchcoat"
	desc = "A sturdy trenchcoat in CLIP colors."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/suits.dmi'
	icon_state = "clip_trenchcoat"
	item_state = "clip_trenchcoat"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

// //////////////////////////////////////////////////////// belts, eyes, hands, mask

/obj/item/storage/belt/military/clip_webbing
	name = "CLIP webbing"
	desc = "A set of webbing in CLIP colors."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/belt.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/belt.dmi'
	icon_state = "clipwebbing"
	item_state = "clipwebbing"

/obj/item/storage/belt/military/clip_webbing/alt
	name = "CLIP webbing (alt)"
	icon_state = "clipwebbing-alt"
	item_state = "clipwebbing-alt"

/obj/item/storage/belt/military/clip_webbing/med
	name = "CLIP medical webbing"
	icon_state = "clip-medwebbing"
	item_state = "clip-medwebbing"

/obj/item/clothing/glasses/clip_goggles
	name = "CLIP ballistic goggles"
	desc = "Goggles in CLIP style."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/eyes.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/eyes.dmi'
	icon_state = "ballistic_goggles"
	item_state = "ballistic_goggles"

/obj/item/clothing/gloves/color/black/clip_combat
	name = "CLIP combat gloves"
	desc = "Gloves in CLIP style."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/hands.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/hands.dmi'
	icon_state = "combatgloves"
	item_state = "combatgloves"

/obj/item/clothing/mask/gas/clip
	name = "CLIP gas mask"
	desc = "A gas mask in CLIP colors."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/mask.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/mask.dmi'
	icon_state = "clip-gasmask"
	item_state = "clip-gasmask"

// //////////////////////////////////////////////////////// hardsuits and helmets (modkit products)

/obj/item/clothing/head/helmet/space/hardsuit/security/clip_patrol
	name = "CLIP patrol hardsuit helmet"
	desc = "A helmet for the CLIP patrol hardsuit."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/head.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/head.dmi'
	icon_state = "hardsuit0-clip-patrol"
	item_state = "hardsuit0-clip-patrol"
	hardsuit_type = "clip-patrol"
	unique_reskin = null

/obj/item/clothing/suit/space/hardsuit/security/clip_patrol
	name = "CLIP patrol hardsuit"
	desc = "A spacesuit of the Confederated League: CLIP patrol hardsuit."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/suit.dmi'
	icon_state = "hardsuit-clip-patrol"
	item_state = "hardsuit-clip-patrol"
	hardsuit_type = "clip-patrol"
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/security/clip_patrol
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	unique_reskin = null

/obj/item/clothing/head/helmet/space/hardsuit/security/clip_spotter
	name = "CLIP spotter hardsuit helmet"
	desc = "A helmet for the CLIP spotter hardsuit."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/head.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/head.dmi'
	icon_state = "hardsuit0-clip_spotter"
	item_state = "hardsuit0-clip_spotter"
	hardsuit_type = "clip_spotter"
	unique_reskin = null

/obj/item/clothing/suit/space/hardsuit/security/clip_spotter
	name = "CLIP spotter hardsuit"
	desc = "A spacesuit of the Confederated League: CLIP spotter hardsuit."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/suit.dmi'
	icon_state = "clip_spotter"
	item_state = "clip_spotter"
	hardsuit_type = "clip_spotter"
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/security/clip_spotter
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	unique_reskin = null

/obj/item/clothing/head/helmet/space/hardsuit/security/clip_eod
	name = "CLIP EOD hardsuit helmet"
	desc = "A helmet for the CLIP EOD hardsuit."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/head.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/head.dmi'
	icon_state = "hardsuit0-clipeod"
	item_state = "hardsuit0-clipeod"
	hardsuit_type = "clipeod"
	unique_reskin = null

/obj/item/clothing/suit/space/hardsuit/security/clip_eod
	name = "CLIP EOD hardsuit"
	desc = "A spacesuit of the Confederated League: CLIP EOD hardsuit."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/suit.dmi'
	icon_state = "hardsuit-clipeod"
	item_state = "hardsuit-clipeod"
	hardsuit_type = "clipeod"
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/security/clip_eod
	unique_reskin = null

/obj/item/clothing/head/helmet/space/hardsuit/mining/clip_indus
	name = "CLIP industrial hardsuit helmet"
	desc = "A helmet for the CLIP industrial hardsuit."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/head.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/head.dmi'
	icon_state = "hardsuit0-clipindus"
	item_state = "hardsuit0-clipindus"
	hardsuit_type = "clipindus"
	unique_reskin = null

/obj/item/clothing/suit/space/hardsuit/mining/clip_indus
	name = "CLIP industrial hardsuit"
	desc = "A spacesuit of the Confederated League: CLIP industrial hardsuit."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/suit.dmi'
	icon_state = "hardsuit0-clipindus"
	item_state = "hardsuit0-clipindus"
	hardsuit_type = "clipindus"
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/mining/clip_indus
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	unique_reskin = null
// EVA

/obj/item/clothing/head/helmet/space/eva/clip
	name = "CLIP EVA helmet"
	desc = "A CLIP EVA helmet for low-budget tasks in space."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/head.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/head.dmi'
	icon_state = "space-clip"
	item_state = "space-clip"
	unique_reskin = null

/obj/item/clothing/suit/space/eva/clip
	name = "CLIP EVA suit"
	desc = "A CLIP EVA suit for low-budget tasks in space."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/suit.dmi'
	icon_state = "space-clip"
	item_state = "space-clip"
	unique_reskin = null

/obj/item/clothing/head/helmet/space/eva/clip_armor
	name = "CLIP armored EVA helmet"
	desc = "A CLIP EVA helmet with extra plating."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/head.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/head.dmi'
	icon_state = "space-clip-armor"
	item_state = "space-clip-armor"
	unique_reskin = null

/obj/item/clothing/suit/space/eva/clip_armor
	name = "CLIP armored EVA suit"
	desc = "A CLIP EVA suit with extra plating."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/suit.dmi'
	icon_state = "space-clip-armor"
	item_state = "space-clip-armor"
	unique_reskin = null

// //////////////////////////////////////////////////////// riot gear and bio suits (modkit products)

/obj/item/clothing/head/helmet/riot/clip
	name = "CLIP riot helmet"
	desc = "A riot helmet in CLIP colors."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/head.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/head.dmi'
	icon_state = "riot_clip"
	item_state = "riot_clip"
	unique_reskin = null

/obj/item/clothing/suit/armor/riot/clip
	name = "CLIP riot armor"
	desc = "A set of riot armor in CLIP colors."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/suit.dmi'
	icon_state = "riot_clip"
	item_state = "riot_clip"
	unique_reskin = null

/obj/item/clothing/head/bio_hood/clip_bard
	name = "CLIP bard bio hood"
	desc = "A biohazard hood of the CLIP bard line."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/head.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/head.dmi'
	icon_state = "clip_bard_bio"
	item_state = "clip_bard_bio"
	unique_reskin = null

/obj/item/clothing/head/bio_hood/clip_bard_armored
	name = "CLIP armored bard bio hood"
	desc = "An armored biohazard hood of the CLIP bard line."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/head.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/head.dmi'
	icon_state = "clip_bard_bio_armored"
	item_state = "clip_bard_bio_armored"
	unique_reskin = null

/obj/item/clothing/suit/bio_suit/clip_bard
	name = "CLIP bard bio suit"
	desc = "A biohazard suit of the CLIP bard line."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/suit.dmi'
	icon_state = "clip_bard_biosuit"
	item_state = "clip_bard_biosuit"
	unique_reskin = null

/obj/item/clothing/suit/bio_suit/clip_bard_medium
	name = "CLIP medium bard bio suit"
	desc = "A medium-weight biohazard suit of the CLIP bard line."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/suit.dmi'
	icon_state = "clip_bard_biosuit_medium"
	item_state = "clip_bard_biosuit_medium"
	unique_reskin = null

/obj/item/clothing/suit/bio_suit/clip_bard_heavy
	name = "CLIP heavy bard bio suit"
	desc = "A heavy biohazard suit of the CLIP bard line."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/suit.dmi'
	icon_state = "clip_bard_biosuit_heavy"
	item_state = "clip_bard_biosuit_heavy"
	unique_reskin = null

// //////////////////////////////////////////////////////// conversion kits (иконка улучшалки: pack.dmi, clipupgrade)

/obj/item/modkit/clip_patrol_kit
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/pack.dmi'
	icon_state = "clipupgrade"
	name = "CLIP patrol hardsuit Kit"
	desc = "A modkit for making any suit into a CLIP patrol hardsuit."
	product = /obj/item/clothing/suit/space/hardsuit/security/clip_patrol
	fromitem = list(/obj/item/clothing/suit)

/obj/item/modkit/clip_patrol_kit/Initialize(mapload)
	. = ..()
	// modkit сверяет точный тип предмета, поэтому раскрываем родителя во все его подтипы
	fromitem = typesof(/obj/item/clothing/suit)

/obj/item/modkit/clip_spotter_kit
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/pack.dmi'
	icon_state = "clipupgrade"
	name = "CLIP spotter hardsuit Kit"
	desc = "A modkit for making any suit into a CLIP spotter hardsuit."
	product = /obj/item/clothing/suit/space/hardsuit/security/clip_spotter
	fromitem = list(/obj/item/clothing/suit)

/obj/item/modkit/clip_spotter_kit/Initialize(mapload)
	. = ..()
	// modkit сверяет точный тип предмета, поэтому раскрываем родителя во все его подтипы
	fromitem = typesof(/obj/item/clothing/suit)

/obj/item/modkit/clip_eod_kit
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/pack.dmi'
	icon_state = "clipupgrade"
	name = "CLIP EOD hardsuit Kit"
	desc = "A modkit for making any suit into a CLIP EOD hardsuit."
	product = /obj/item/clothing/suit/space/hardsuit/security/clip_eod
	fromitem = list(/obj/item/clothing/suit)

/obj/item/modkit/clip_eod_kit/Initialize(mapload)
	. = ..()
	// modkit сверяет точный тип предмета, поэтому раскрываем родителя во все его подтипы
	fromitem = typesof(/obj/item/clothing/suit)

/obj/item/modkit/clip_indus_kit
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/pack.dmi'
	icon_state = "clipupgrade"
	name = "CLIP industrial hardsuit Kit"
	desc = "A modkit for making any suit into a CLIP industrial hardsuit."
	product = /obj/item/clothing/suit/space/hardsuit/mining/clip_indus
	fromitem = list(/obj/item/clothing/suit)

/obj/item/modkit/clip_indus_kit/Initialize(mapload)
	. = ..()
	// modkit сверяет точный тип предмета, поэтому раскрываем родителя во все его подтипы
	fromitem = typesof(/obj/item/clothing/suit)

/obj/item/modkit/clip_eva_suit_kit
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/pack.dmi'
	icon_state = "clipupgrade"
	name = "CLIP EVA suit Kit"
	desc = "A modkit for making any suit into a CLIP EVA suit."
	product = /obj/item/clothing/suit/space/eva/clip
	fromitem = list(/obj/item/clothing/suit)

/obj/item/modkit/clip_eva_suit_kit/Initialize(mapload)
	. = ..()
	// modkit сверяет точный тип предмета, поэтому раскрываем родителя во все его подтипы
	fromitem = typesof(/obj/item/clothing/suit)

/obj/item/modkit/clip_eva_helmet_kit
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/pack.dmi'
	icon_state = "clipupgrade"
	name = "CLIP EVA helmet Kit"
	desc = "A modkit for making any headwear into a CLIP EVA helmet."
	product = /obj/item/clothing/head/helmet/space/eva/clip
	fromitem = list(/obj/item/clothing/head)

/obj/item/modkit/clip_eva_helmet_kit/Initialize(mapload)
	. = ..()
	// modkit сверяет точный тип предмета, поэтому раскрываем родителя во все его подтипы
	fromitem = typesof(/obj/item/clothing/head)

/obj/item/modkit/clip_eva_armor_suit_kit
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/pack.dmi'
	icon_state = "clipupgrade"
	name = "CLIP armored EVA suit Kit"
	desc = "A modkit for making any suit into a CLIP armored EVA suit."
	product = /obj/item/clothing/suit/space/eva/clip_armor
	fromitem = list(/obj/item/clothing/suit)

/obj/item/modkit/clip_eva_armor_suit_kit/Initialize(mapload)
	. = ..()
	// modkit сверяет точный тип предмета, поэтому раскрываем родителя во все его подтипы
	fromitem = typesof(/obj/item/clothing/suit)

/obj/item/modkit/clip_eva_armor_helmet_kit
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/pack.dmi'
	icon_state = "clipupgrade"
	name = "CLIP armored EVA helmet Kit"
	desc = "A modkit for making any headwear into a CLIP armored EVA helmet."
	product = /obj/item/clothing/head/helmet/space/eva/clip_armor
	fromitem = list(/obj/item/clothing/head)

/obj/item/modkit/clip_eva_armor_helmet_kit/Initialize(mapload)
	. = ..()
	// modkit сверяет точный тип предмета, поэтому раскрываем родителя во все его подтипы
	fromitem = typesof(/obj/item/clothing/head)

/obj/item/modkit/clip_riot_helmet_kit
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/pack.dmi'
	icon_state = "clipupgrade"
	name = "CLIP riot helmet Kit"
	desc = "A modkit for making any headwear into a CLIP riot helmet."
	product = /obj/item/clothing/head/helmet/riot/clip
	fromitem = list(/obj/item/clothing/head)

/obj/item/modkit/clip_riot_helmet_kit/Initialize(mapload)
	. = ..()
	// modkit сверяет точный тип предмета, поэтому раскрываем родителя во все его подтипы
	fromitem = typesof(/obj/item/clothing/head)

/obj/item/modkit/clip_riot_armor_kit
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/pack.dmi'
	icon_state = "clipupgrade"
	name = "CLIP riot armor Kit"
	desc = "A modkit for making any suit into CLIP riot armor."
	product = /obj/item/clothing/suit/armor/riot/clip
	fromitem = list(/obj/item/clothing/suit)

/obj/item/modkit/clip_riot_armor_kit/Initialize(mapload)
	. = ..()
	// modkit сверяет точный тип предмета, поэтому раскрываем родителя во все его подтипы
	fromitem = typesof(/obj/item/clothing/suit)

/obj/item/modkit/clip_bard_hood_kit
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/pack.dmi'
	icon_state = "clipupgrade"
	name = "CLIP bard bio hood Kit"
	desc = "A modkit for making any headwear into a CLIP bard bio hood."
	product = /obj/item/clothing/head/bio_hood/clip_bard
	fromitem = list(/obj/item/clothing/head)

/obj/item/modkit/clip_bard_hood_kit/Initialize(mapload)
	. = ..()
	// modkit сверяет точный тип предмета, поэтому раскрываем родителя во все его подтипы
	fromitem = typesof(/obj/item/clothing/head)

/obj/item/modkit/clip_bard_hood_armored_kit
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/pack.dmi'
	icon_state = "clipupgrade"
	name = "CLIP armored bard bio hood Kit"
	desc = "A modkit for making any headwear into a CLIP armored bard bio hood."
	product = /obj/item/clothing/head/bio_hood/clip_bard_armored
	fromitem = list(/obj/item/clothing/head)

/obj/item/modkit/clip_bard_hood_armored_kit/Initialize(mapload)
	. = ..()
	// modkit сверяет точный тип предмета, поэтому раскрываем родителя во все его подтипы
	fromitem = typesof(/obj/item/clothing/head)

/obj/item/modkit/clip_bard_suit_kit
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/pack.dmi'
	icon_state = "clipupgrade"
	name = "CLIP bard bio suit Kit"
	desc = "A modkit for making any suit into a CLIP bard bio suit."
	product = /obj/item/clothing/suit/bio_suit/clip_bard
	fromitem = list(/obj/item/clothing/suit)

/obj/item/modkit/clip_bard_suit_kit/Initialize(mapload)
	. = ..()
	// modkit сверяет точный тип предмета, поэтому раскрываем родителя во все его подтипы
	fromitem = typesof(/obj/item/clothing/suit)

/obj/item/modkit/clip_bard_suit_medium_kit
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/pack.dmi'
	icon_state = "clipupgrade"
	name = "CLIP medium bard bio suit Kit"
	desc = "A modkit for making any suit into a CLIP medium bard bio suit."
	product = /obj/item/clothing/suit/bio_suit/clip_bard_medium
	fromitem = list(/obj/item/clothing/suit)

/obj/item/modkit/clip_bard_suit_medium_kit/Initialize(mapload)
	. = ..()
	// modkit сверяет точный тип предмета, поэтому раскрываем родителя во все его подтипы
	fromitem = typesof(/obj/item/clothing/suit)

/obj/item/modkit/clip_bard_suit_heavy_kit
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/pack.dmi'
	icon_state = "clipupgrade"
	name = "CLIP heavy bard bio suit Kit"
	desc = "A modkit for making any suit into a CLIP heavy bard bio suit."
	product = /obj/item/clothing/suit/bio_suit/clip_bard_heavy
	fromitem = list(/obj/item/clothing/suit)

/obj/item/modkit/clip_bard_suit_heavy_kit/Initialize(mapload)
	. = ..()
	// modkit сверяет точный тип предмета, поэтому раскрываем родителя во все его подтипы
	fromitem = typesof(/obj/item/clothing/suit)

// //////////////////////////////////////////////////////// mech upgrade packs
// Меха не предметы, поэтому обычный modkit на них не работает. Пак применяется кликом по меху и подменяет файл иконок.
// В mecha.dmi состояния названы как у обычных мехов (ripley, gygax, durand и их -open / -broken),
// поэтому внутренняя логика мехов (вход / выход, поломка) продолжает находить свои спрайты.
// Подходит только базовым мехам (по началу названия текущего состояния), производные (firefighter, dark gygax и т.п.) не трогаются.

/obj/item/clip_mech_pack
	name = "CLIP mech upgrade pack"
	desc = "An upgrade pack that gives a mech a CLIP appearance."
	icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/obj/pack.dmi'
	icon_state = "clipupgrade"
	var/mech_keyword = ""
	var/mech_icon = 'modular_bluemoon/fluffs/code/modules/clip.interdyne/items/mob/mecha.dmi'

/obj/item/clip_mech_pack/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(!proximity || !ismecha(target))
		return
	if(target.icon == mech_icon)
		to_chat(user, "<span class='warning'>[target] already has a CLIP appearance.</span>")
		return
	if(findtext("[target.icon_state]", mech_keyword) != 1)
		to_chat(user, "<span class='warning'>This pack does not fit [target].</span>")
		return
	target.icon = mech_icon
	target.update_icon()
	to_chat(user, "<span class='notice'>You apply the upgrade pack to [target].</span>")
	qdel(src)

/obj/item/clip_mech_pack/ripley
	name = "CLIP Ripley upgrade pack"
	desc = "An upgrade pack that gives a Ripley a CLIP appearance."
	mech_keyword = "ripley"

/obj/item/clip_mech_pack/gygax
	name = "CLIP Gygax upgrade pack"
	desc = "An upgrade pack that gives a Gygax a CLIP appearance."
	mech_keyword = "gygax"

/obj/item/clip_mech_pack/durand
	name = "CLIP Durand upgrade pack"
	desc = "An upgrade pack that gives a Durand a CLIP appearance."
	mech_keyword = "durand"

// //////////////////////////////////////////////////////// kit box

/obj/item/storage/box/clip_kit
	name = "CLIP kit"
	desc = "Military box that contains a full set of CLIP upgrade kits."
	icon_state = "ammobox"

/obj/item/storage/box/clip_kit/PopulateContents()
	new /obj/item/modkit/clip_patrol_kit(src)
	new /obj/item/modkit/clip_spotter_kit(src)
	new /obj/item/modkit/clip_eod_kit(src)
	new /obj/item/modkit/clip_indus_kit(src)
	new /obj/item/modkit/clip_eva_suit_kit(src)
	new /obj/item/modkit/clip_eva_helmet_kit(src)
	new /obj/item/modkit/clip_eva_armor_suit_kit(src)
	new /obj/item/modkit/clip_eva_armor_helmet_kit(src)
	new /obj/item/modkit/clip_riot_helmet_kit(src)
	new /obj/item/modkit/clip_riot_armor_kit(src)
	new /obj/item/modkit/clip_bard_hood_kit(src)
	new /obj/item/modkit/clip_bard_hood_armored_kit(src)
	new /obj/item/modkit/clip_bard_suit_kit(src)
	new /obj/item/modkit/clip_bard_suit_medium_kit(src)
	new /obj/item/modkit/clip_bard_suit_heavy_kit(src)
	new /obj/item/clip_mech_pack/ripley(src)
	new /obj/item/clip_mech_pack/gygax(src)
	new /obj/item/clip_mech_pack/durand(src)
