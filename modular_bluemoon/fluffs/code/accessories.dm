/obj/item/clothing/neck/cloak/coopie_cloak
	name = "Coopie's cloak"
	desc = "Именной плащ слаймика. Виднеется большая буква 'С'. Ниже, мелким шрифтом, написано: 'если вы нашли его, значит я его потеряла. Верните, пожалуйста. Владелец: Coopie'"
	icon_state = "coopie_cloak"
	item_state = "coopie_cloak"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/accessories.dmi'

/////

/obj/item/modkit/pomogator_kit
	name = "Pomogator Modification Kit"
	desc = "A modkit for making a default backpack into a Pomogator."
	product = /obj/item/storage/backpack/pomogator
	fromitem = list(/obj/item/storage/backpack)

/obj/item/storage/backpack/pomogator
	name = "Pomogator"
	desc = "It's a satchel that holds fixie tools and other things."
	icon_state = "pomogator"
	item_state = "pomogator"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/accessories.dmi'

////////////////////////////////

/obj/item/modkit/sponge_kit
	name = "Sponge Vloes Modification Kit"
	desc = "A modkit for making a default boxing gloves into a yellow gloves."
	product = /obj/item/clothing/gloves/boxing/sponge
	fromitem = list(/obj/item/clothing/gloves/boxing, /obj/item/clothing/gloves/boxing/blue, /obj/item/clothing/gloves/boxing/green)

/obj/item/clothing/gloves/boxing/sponge
	icon_state = "sponge"
	item_state = "sponge"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/hands.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/hands.dmi'

/////////

/obj/item/clothing/neck/tie/cross/shielded
	name = "Radiant relic"
	desc = "Данный артефакт был известен еще во времена затухания звёзд. Он стал знаменит тем, что излучает направленные лучи света, которые образуют купол вокруг носителя. Поколениями его носили верховные христианские жрецы. Теперь же это не более чем очень дорогой уникальный аксессуар."
	icon_state = "cross_shielded"
	//var/cached_vis_overlay

//Декоративный оверлей при надевании предмета в слот шеи. Убран по просьбе заказчика, но мало ли
///obj/item/clothing/neck/tie/cross/shielded/equipped(mob/living/L, slot)
	//..()
	//if(slot == ITEM_SLOT_NECK)
		//var/layer = (L.layer > MOB_LAYER ? L.layer : MOB_LAYER) + 0.01
		//cached_vis_overlay = SSvis_overlays.add_vis_overlay(L, 'icons/effects/effects.dmi', "shield-golden", layer, GAME_PLANE, L.dir)

///obj/item/clothing/neck/tie/cross/shielded/dropped(mob/living/L)
	//areaif(cached_vis_overlay)
		//SSvis_overlays.remove_vis_overlay(L, cached_vis_overlay)
		//cached_vis_overlay = null
	//..()

///obj/item/clothing/neck/tie/cross/shielded/Destroy(mob/living/L)
	//if(cached_vis_overlay)
		//SSvis_overlays.remove_vis_overlay(L, cached_vis_overlay)
		//cached_vis_overlay = null
	//return ..()


////////

/obj/item/clothing/glasses/shiro
	name = "Shiro's Sunglasses"
	desc = "These silver aviators belong to Shiro Silverhand."
	icon_state = "shiro"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/accessories.dmi'


////////////////////////

/obj/item/clothing/accessory/booma_patch
	name = "BSF ArmPatch"
	desc = "«BoomahSpecialForces» — предплечевая выполненная на заказ нашивка, означающая о принадлежности к некоему отряду Бумахов, или, для более углублённых в тему людей, Бустеров!"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/accessories.dmi'
	icon_state = "booma"
	item_state = "booma"

////////////////////////

/obj/item/clothing/accessory/hateredsoul_dogtag
	name = "Combat Dogtag"
	desc = "Связка боевых жетонов с резиновым ободком по их краям. Выполнены из прочного и износостойкого сплава, с маленьким весом, от чего стали практически незаметными для самого носителя. На правом жетоне выбиты основные данные его владельца, в виде полного имени, группы крови и принадлежности к подразделению. На левом жетоне выбита дополнительная информация и очертания владельца."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/accessories.dmi'
	icon_state = "hateredsoul_dogtag_1"
	item_state = "hateredsoul_dogtag_1"
	slot_flags = ITEM_SLOT_NECK
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/small/collar
	var/tagname = null
	unique_reskin = list(
		"Combat dogtag" = list(
			RESKIN_ICON_STATE = "hateredsoul_dogtag_1",
			RESKIN_ITEM_STATE = "hateredsoul_dogtag_1"
		),
		"Combat Dogtag" = list(
			RESKIN_ICON_STATE = "hateredsoul_dogtag_2",
			RESKIN_ITEM_STATE = "hateredsoul_dogtag_2"
		)
	)

/obj/item/clothing/accessory/hateredsoul_dogtag/attack_self(mob/user)
	tagname = stripped_input(user, "Would you like to change the name on the tag?", "Name your new tag", tagname, MAX_NAME_LEN)
	name = tagname ? "[initial(name)] - [tagname]" : initial(name)

/obj/item/clothing/accessory/hateredsoul_dogtag/nt
	name = "NT Combat Dogtag"
	desc = "Связка боевых жетонов с резиновым ободком по их краям. Выполнены из прочного и износостойкого сплава, с маленьким весом, от чего стали практически незаметными для самого носителя. На правом жетоне выбиты основные данные его владельца, в виде полного имени, группы крови и принадлежности к подразделению. На левом жетоне изображён логотип корпорации NanoTrasen."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/accessories.dmi'
	icon_state = "hateredsoul_dogtag_nt_1"
	item_state = "hateredsoul_dogtag_nt_1"
	unique_reskin = list(
		"NT Combat Dogtag" = list(
			RESKIN_ICON_STATE = "hateredsoul_dogtag_nt_1",
			RESKIN_ITEM_STATE = "hateredsoul_dogtag_nt_1"
		),
		"NT Combat dogtag" = list(
			RESKIN_ICON_STATE = "hateredsoul_dogtag_nt_2",
			RESKIN_ITEM_STATE = "hateredsoul_dogtag_nt_2"
		),
		"NT combat dogtag" = list(
			RESKIN_ICON_STATE = "hateredsoul_dogtag_nt_3",
			RESKIN_ITEM_STATE = "hateredsoul_dogtag_nt_3"
		)
	)

/obj/item/clothing/accessory/hateredsoul_dogtag/syndie
	name = "Syndie Combat Dogtag"
	desc = "Связка боевых жетонов с резиновым ободком по их краям. Выполнены из прочного и износостойкого сплава, с маленьким весом, от чего стали практически незаметными для самого носителя. На правом жетоне выбиты основные данные его владельца, в виде полного имени, группы крови и принадлежности к подразделению. На левом жетоне изображена трёхглавая змея Синдиката."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/accessories.dmi'
	icon_state = "hateredsoul_dogtag_syndie_1"
	item_state = "hateredsoul_dogtag_syndie_1"
	unique_reskin = list(
		"Syndie Combat Dogtag" = list(
			RESKIN_ICON_STATE = "hateredsoul_dogtag_syndie_1",
			RESKIN_ITEM_STATE = "hateredsoul_dogtag_syndie_1"
		),
		"Syndie Combat dogtag" = list(
			RESKIN_ICON_STATE = "hateredsoul_dogtag_syndie_2",
			RESKIN_ITEM_STATE = "hateredsoul_dogtag_syndie_2"
		),
		"Syndie combat dogtag" = list(
			RESKIN_ICON_STATE = "hateredsoul_dogtag_syndie_3",
			RESKIN_ITEM_STATE = "hateredsoul_dogtag_syndie_3"
		)
	)

////////////////////////

/obj/item/clothing/neck/tie/dogtag
	name = "Dog tag"
	desc = "The first tag indicates personal number - AG-003288 and affiliation with the AC mercenaries.  The second tag contains the first and last name - Althea Gantia, along with the blood type."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/accessories.dmi'
	icon_state = "dogtag"
	item_state = "dogtag"

////////////////////////

/obj/item/clothing/neck/tie/pendantcape
	name = "Corvus Pendant"
	desc = "Ravens in black with eyes so keen, steal pendants bright with silver sheen."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/neck.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/neck.dmi'
	icon_state = "cp" //Сделано специально, человек попросил защиту от хамелионки.
	item_state = "cp"
	unique_reskin = list(
		"Corvus Pendant" = list(
			RESKIN_ICON_STATE = "pendant",
			RESKIN_ITEM_STATE = "pendant"
		),
		"Corvus Cape" = list(
			RESKIN_ICON_STATE = "cape",
			RESKIN_ITEM_STATE = "cape"
		)
	)

////////////////////////

/obj/item/clothing/neck/tie/f_haori
	name = "Flaming Haori"
	desc = "A white haori with a flaming pattern on the end. It seems to radiate heat and energy."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/accessories.dmi'
	icon_state = "f_haori"
	item_state = "f_haori"

////////////////////////

/obj/item/clothing/neck/tie/oftok
	name = "Holographical Token"
	desc = "A strange holographic token made of strong material to mark something."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/accessories.dmi'
	icon_state = "oftok"
	item_state = "oftok"
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/accessories_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/accessories_right.dmi'

////////////////////////

/obj/item/clothing/neck/tie/dread_neck
	name = "Наплечники судьи"
	desc = "Довольно большой полу-жилет что крепится на тонкую ткань, на плечах большие и довольно массивные словно отлитые из золота регалии, где на правом плече красовался Орёл, и на втором уже простое покрытие брусками, и на левой стороне передней части жилетки виднеется массивный значок с потертым именем Дредд что кажется вам знакомым. Одевая эти регалии вас переполняет чуство груза за решения что вы принимаете вынося вердикт."
	icon_state = "dread_neck"
	item_state = "dread_neck"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/accessories.dmi'
	alternate_worn_layer = ABOVE_HEAD_LAYER

////////////////////////

/obj/item/clothing/gloves/fingerless/monolith_gloves
	name = "Monolith gloves"
	desc = "The gloves of the jumpsuit Granite M1 from the Monolith group, the manufacturer is unknown."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/gloves.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/gloves.dmi'
	icon_state = "monolithgloves"
	item_state = "monolithgloves"

/obj/item/clothing/gloves/SATT_gloves
	name = "SATT gloves"
	desc = "High-quality clothes made of a mixture of fleece and cotton. The logo in the form of an eagle and the caption of the Strategic Assault Tactical Team are visible on the tag. If you inhale the smell, you can smell the slices of a war crime."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/gloves.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/gloves.dmi'
	icon_state = "SATTgloves"
	item_state = "SATTgloves"

/obj/item/clothing/gloves/fingerless/SATT_gloves_finger
	name = "Fingerless SATT gloves"
	desc = "High-quality clothes made of a mixture of fleece and cotton. The logo in the form of an eagle and the caption of the Strategic Assault Tactical Team are visible on the tag. If you inhale the smell, you can smell the slices of a war crime."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/gloves.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/gloves.dmi'
	icon_state = "SATTgloves_fingerless"
	item_state = "SATTgloves_fingerless"

/obj/item/clothing/shoes/jackboots/SATT_jackboots
	name = "SATT jackboots"
	desc = "High-quality clothes made of a mixture of fleece and cotton. The logo in the form of an eagle and the caption of the Strategic Assault Tactical Team are visible on the tag. If you inhale the smell, you can smell the slices of a war crime."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/shoes.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/shoes.dmi'
	icon_state = "SATTjackboots"
	item_state = "SATTjackboots"

////////////////////////

/obj/item/clothing/suit/kimono/warai
	name = "Кимоно 笑い"
	desc = "Дорогая одежда на восточный мотив. Слишком большая для ношения существами без дополнительных пар лап. При детальном осмотре выясняется что соткана она из необычного материала, а именно сушеных сухожилий и чьей то шерсти. Вдоль всего кимоно виднеются позвонки и выпирающие ребра, что улучшают прочность одеяния. Так же имеется что то типа самурайской пластинчатой брони под кимоно, состоящих из плоских костей. А еще местами виднеется орнамент в виде странных цветов... вам показалось или они моргают?"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_ALL_TAURIC
	icon = 'icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'icons/mob/clothing/uniform_digi.dmi'
	taur_mob_worn_overlay = 'modular_sand/icons/mob/suits_taur.dmi'

///////////////////////////

/obj/item/storage/belt/scabbard
	name = "Scabbard for a officer's cleaver"
	desc = "The special scabbard is well suited for the officer's cleaver issued to high-ranking Adler officers and their officials. You could call it superfluous, it is made of the skin of some rare creature and perhaps even intelligent, the scabbard itself is attached to the belt in the belt area at the back for the convenience of sharply removing the blade and striking, which is taught to officers when they learn how to use this specialized cleaver. For ordinary people, they are inconvenient and difficult to use."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/belts.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/belt.dmi'
	icon_state = "scabbard"
	item_state = "scabbard"
	w_class = WEIGHT_CLASS_BULKY
	content_overlays = TRUE
	onmob_overlays = TRUE
	var/list/fitting_swords = list(/obj/item/melee/sabre/cleaver)

/obj/item/storage/belt/scabbard/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 1
	STR.rustle_sound = FALSE
	STR.max_w_class = WEIGHT_CLASS_BULKY
	STR.can_hold = typecacheof(fitting_swords)
	STR.quickdraw = TRUE

/obj/item/storage/belt/scabbard/examine(mob/user)
	. = ..()
	if(length(contents))
		. += "<span class='notice'>Alt-click it to quickly draw the blade.</span>"

////////////////////////

/obj/item/clothing/neck/tie/shoulder_coat
	name = "Officer's shoulder coat"
	desc = "The officer's raincoat is also usually worn by Adler's officers as an additional identification mark, it is made of nanofibers of light fabric, it is usually given to officers who have passed advanced training and have at least the second rank in the hierarchy of officers. For officials and senior officers, it is usually not used since their rank is much higher. But for tactical designation in the officer corps, it is necessary to wear. Even a second-rank officer can already give full orders to a first-rank officer, despite the small gap in ranks. White stripes can also be applied to the cloak as a rank identifier, but this practice is usually used only in regular forces."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/accessories.dmi'
	icon_state = "shoulder_coat"
	item_state = "shoulder_coat"

/obj/item/clothing/underwear/socks/savannah_piercing
	name = "piercings and bracers"
	desc = "A gold piercings and bracers."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/accessories.dmi'
	icon_state = "pier"
	slot_flags = ITEM_SLOT_SOCKS
	body_parts_covered = 0

////////////////////////

/obj/item/clothing/neck/tie/h_soul_coat
	name = "Black coat"
	desc = "Обычное чёрное пальто, выполненное из высококачественного материла, хоть и выглядящим старым, но всё ещё приятное на вид и даже на ощупь, однако всё ещё слишком длинное, чтобы его носить как обычно, но что мешает его продолжать носить иным способом, верно? Во внутреннем кармане пальто заметен логотив в виде чёрной розы и надпись Black Rose atelier."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/accessories.dmi'
	icon_state = "h_soul_coat"
	item_state = "h_soul_coat"

////////////////////////

/obj/item/clothing/neck/tie/mu88_tie
	name = "M.U. 88 New hope tie"
	desc = "Кол, представляющий собой белый воротник и светло-зелёного оттенка галстук, носящие за собой смысл лишь декорации, хоть и выполнены из износостойкой ткани, для работ в области повышенной опасности. Во внутренней части галстука имеется логотип в виде чёрной розы, а также надпись - Black Rose atelier."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/accessories.dmi'
	icon_state = "mu88_tie"
	item_state = "mu88_tie"

////////////////////////

/obj/item/clothing/neck/tie/hahun_cape
	name = "Praxil Mk.6"
	desc = "A cape that awarded to trusted agents of Syndicate, pleasant to the touch and look very stylish, doesn't even restrict movement"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/accessories.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/accessories_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/accessories_right.dmi'
	icon_state = "hahun_cape"
	item_state = "hahun_cape"

/obj/item/clothing/gloves/color/latex/nitrile/hahun_eidolon
	name = "Eidolon's gloves"
	desc = "Medical gloves with Eidolon Corporation markings, have a built-in computer with information, that tied with medical scan and huds. Have distinctive red-green coloring."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/gloves.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/gloves.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_right.dmi'
	icon_state = "hahun_gloves"
	item_state = "hahun_gloves"

/obj/item/modkit/hahun_eidolon_nitrile
	name = "Eidolon medical gloves Kit"
	desc = "A modkit for making a nitrile gloves into a Eidolon's gloves."
	product = /obj/item/clothing/gloves/color/latex/nitrile/hahun_eidolon
	fromitem = list(/obj/item/clothing/gloves/color/latex/nitrile)

/obj/item/clothing/gloves/color/yellow/hahun_eidolon
	name = "Eidolon engineering gloves"
	desc = "Engineering gloves with Eidolon Corporation markings, have a built-in computer with information, \
			that tied with wire scan and meson huds. Have distinctive red-black coloring"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/gloves.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/gloves.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_right.dmi'
	icon_state = "hahun_gloves"
	item_state = "hahun_gloves"

/obj/item/modkit/hahun_eidolon_isulated
	name = "Eidolon engineering gloves Kit"
	desc = "A modkit for making a Insulated Gloves into a Eidolon engineering gloves."
	product = /obj/item/clothing/gloves/color/yellow/hahun_eidolon
	fromitem = list(/obj/item/clothing/gloves/color/yellow)

/obj/item/storage/box/hahun_eidolon/PopulateContents()
	new /obj/item/modkit/hahun_eidolon_nitrile(src)
	new /obj/item/modkit/hahun_eidolon_isulated(src)

////////////////////////

/obj/item/storage/belt/military/srt_chesrig
	name = "SRT Bluerock chest-rig"
	desc = "A custom-made chest rig for wearing on top of body armor in CQC operations. Sturdy and versatile, it features both MOLLE and ALICE attachment systems. Seems like it already has old-fashioned holster attached to it."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/accessories.dmi'
	icon_state = "srt_chestrig"
	item_state = "srt_chestrig"

//////////////////////// БАНЕРЫ

/obj/item/banner/irellia
	name = "Banner of the Irellia"
	icon = 'modular_bluemoon/fluffs/icons/obj/accessories.dmi'
	icon_state = "banner-irellia"
	desc = "Banner of the Irellia"

/obj/item/banner/rohai
	name = "Banner of the Rohai empire"
	icon = 'modular_bluemoon/fluffs/icons/obj/accessories.dmi'
	icon_state = "banner-rohai"
	desc = "Banner of the Rohai empire"

/obj/item/banner/norn
	name = "Banner of kingdom Norn"
	icon = 'modular_bluemoon/fluffs/icons/obj/accessories.dmi'
	icon_state = "banner-norn"
	desc = "Banner of kingdom Norn"

//////////////////////// БАНЕРЫ


/obj/item/storage/box/fall_out_kit
	name = "Ranger kit"
	desc = "Military box that contains a full kit of Ranger uniform."
	icon_state = "ammobox"

/obj/item/storage/box/fall_out_kit/PopulateContents()
	new /obj/item/clothing/suit/donator/bm/ranger_coat(src)
	new /obj/item/clothing/head/ranger_helmet(src)
	new /obj/item/clothing/under/donator/bm/ranger_uniform(src)
	new /obj/item/clothing/mask/gas/syndicate/ranger_gasmask(src)

////////////////////////

/obj/item/clothing/glasses/halvedspectacles
	name = "halved violet spectacles"
	desc = "\"Половинки\"-очки в оправе тёмно-золотого оттенка. В них вставлены линзы фиалкового цвета. Пахнут фундуком."
	icon_state = "coldhalved_s"
	item_state = "coldhalved_s"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/accessories.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/accessories.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/accessories_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/accessories_right.dmi'

////////////////////////
