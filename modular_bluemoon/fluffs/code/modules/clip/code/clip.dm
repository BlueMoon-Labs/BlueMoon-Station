// CLIP faction wardrobe (personal skins).
// Одежда (форма, пальто, пояса, очки, перчатки, маска) выдаётся через лодаут.
// Скафандры, шлемы, био-костюмы, броня riot и меха меняют внешний вид через улучшалки (коробка CLIP kit).
// Улучшалки меняют ТОЛЬКО внешний вид предмета (иконка, спрайт на персонаже, название): броня и все остальные параметры
// остаются теми, что были у вещи до переделки.
//
// Иконки: modular_bluemoon/fluffs/code/modules/clip/items/obj/*.dmi (предметы) и items/mob/*.dmi (на персонаже).


// //////////////////////////////////////////////////////// uniforms

/obj/item/clothing/under/clip
	name = "CLIP deck uniform"
	desc = "Практичный комбинезон, который носит палубная команда CLIP."
	icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/uniforms.dmi'
	icon_state = "clip_deck"
	can_adjust = FALSE
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/under/clip/minuteman
	name = "CLIP minuteman uniform"
	desc = "Прочная полевая форма, которую выдают минитменам CLIP."
	icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/uniforms.dmi'
	icon_state = "clip_minuteman"
	can_adjust = FALSE
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/under/clip/formal
	name = "CLIP formal uniform"
	desc = "Строгая парадная форма Конфедерации."
	icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/uniforms.dmi'
	icon_state = "clip_formal"
	can_adjust = FALSE
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/under/clip/formal_skirt
	name = "CLIP formal skirt"
	desc = "Строгая парадная форма Конфедерации с юбкой."
	icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/uniforms.dmi'
	icon_state = "clip_formal_skirt"
	can_adjust = FALSE
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	body_parts_covered = CHEST|GROIN|ARMS

/obj/item/clothing/under/clip/medic
	name = "CLIP medical uniform"
	desc = "Форма медицинского персонала CLIP."
	icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/uniforms.dmi'
	icon_state = "clip_medic"
	can_adjust = FALSE
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

// //////////////////////////////////////////////////////// coats (cosmetic suits)

/obj/item/clothing/suit/jacket/clip_general
	name = "CLIP general's coat"
	desc = "Нарядное пальто, которое носят генералы Конфедерации."
	icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/suits.dmi'
	icon_state = "clip_general"
	item_state = "clip_general"

/obj/item/clothing/suit/jacket/clip_admiral
	name = "CLIP admiral's coat"
	desc = "Нарядное пальто, которое носят адмиралы Конфедерации."
	icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/suits.dmi'
	icon_state = "clip_admiral"
	item_state = "clip_admiral"

/obj/item/clothing/suit/jacket/clip_captaincoat
	name = "CLIP captain's coat"
	desc = "Длинное пальто капитанов кораблей CLIP."
	icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/suits.dmi'
	icon_state = "clip_captaincoat"
	item_state = "clip_captaincoat"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/jacket/clip_trenchcoat
	name = "CLIP trenchcoat"
	desc = "Прочный плащ в цветах CLIP."
	icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/suits.dmi'
	icon_state = "clip_trenchcoat"
	item_state = "clip_trenchcoat"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

// //////////////////////////////////////////////////////// belts, eyes, hands, mask

/obj/item/storage/belt/military/clip_webbing
	name = "CLIP webbing"
	desc = "Набор разгрузки в цветах CLIP."
	icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/belt.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/belt.dmi'
	icon_state = "clipwebbing"
	item_state = "clipwebbing"

// Ограничение: пояс доступен с начала раунда, поэтому вместимость урезана относительно обычной разгрузки.
// Подправьте max_items / max_combined_w_class, если нужно иначе.
/obj/item/storage/belt/military/clip_webbing/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 5
	STR.max_w_class = WEIGHT_CLASS_SMALL
	STR.max_combined_w_class = 10

/obj/item/storage/belt/military/clip_webbing/alt
	name = "CLIP webbing (alt)"
	icon_state = "clipwebbing-alt"
	item_state = "clipwebbing-alt"

/obj/item/storage/belt/military/clip_webbing/med
	name = "CLIP medical webbing"
	icon_state = "clip-medwebbing"
	item_state = "clip-medwebbing"

// Очки наследуют обычные солнцезащитные (все параметры и возможность переделки в худ-очки сохраняются)

/obj/item/clothing/glasses/sunglasses/clip_goggles
	name = "CLIP ballistic goggles"
	desc = "Баллистические очки в стиле CLIP."
	icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/eyes.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/eyes.dmi'
	icon_state = "ballistic_goggles"
	item_state = "ballistic_goggles"

/obj/item/clothing/gloves/color/black/clip_combat
	name = "CLIP combat gloves"
	desc = "Перчатки в стиле CLIP."
	icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/hands.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/hands.dmi'
	icon_state = "combatgloves"
	item_state = "combatgloves"

/obj/item/clothing/mask/gas/clip
	name = "CLIP gas mask"
	desc = "Противогаз в цветах CLIP."
	icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/mask.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/mask.dmi'
	icon_state = "clip-gasmask"
	item_state = "clip-gasmask"

// //////////////////////////////////////////////////////// reskin kits
// Применяются кликом по любому предмету подходящего слота (костюм или головной убор).
// Меняют иконку, спрайт на персонаже и название, а броня и прочие параметры остаются прежними.
// У скафандров дополнительно меняется внешний вид шлема, который к ним прилагается.
// keep_mask_visible = TRUE: у переделанных шлемов убирается флаг, скрывающий маску на лице.

/obj/item/clip_reskin_kit
	name = "CLIP upgrade kit"
	desc = "Набор, придающий одежде внешний вид CLIP."
	icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/pack.dmi'
	icon_state = "clipupgrade"
	var/required_slot = ITEM_SLOT_OCLOTHING
	var/new_name = ""
	var/new_icon_state = ""
	var/obj_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/suit.dmi'
	var/worn_icon_file = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/suit.dmi'
	var/hardsuit_type = ""
	var/has_digi = FALSE
	var/keep_mask_visible = TRUE

/obj/item/clip_reskin_kit/proc/apply_skin(obj/item/clothing/C, state, obj_file, worn_file)
	C.icon = obj_file
	C.mob_overlay_icon = worn_file
	C.icon_state = state
	C.item_state = state
	if("anthro_mob_worn_overlay" in C.vars)
		C.vars["anthro_mob_worn_overlay"] = worn_file
	if(istype(C, /obj/item/clothing/head))
		if(keep_mask_visible)
			C.flags_inv &= ~HIDEMASK
	else if("mutantrace_variation" in C.vars)
		C.vars["mutantrace_variation"] = has_digi ? (STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON) : NONE

/obj/item/clip_reskin_kit/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(!proximity || !new_icon_state || !istype(target, /obj/item/clothing))
		return
	var/obj/item/clothing/C = target
	if(!(C.slot_flags & required_slot))
		to_chat(user, "<span class='warning'>Этот набор не подходит к [C].</span>")
		return
	apply_skin(C, new_icon_state, obj_icon, worn_icon_file)
	if(new_name)
		C.name = new_name
	if(hardsuit_type && ("hardsuit_type" in C.vars))
		C.vars["hardsuit_type"] = hardsuit_type
		if("helmet" in C.vars)
			var/obj/item/clothing/head/H = C.vars["helmet"]
			if(istype(H))
				H.vars["hardsuit_type"] = hardsuit_type
				apply_skin(H, "hardsuit0-[hardsuit_type]", 'modular_bluemoon/fluffs/code/modules/clip/items/obj/head.dmi', 'modular_bluemoon/fluffs/code/modules/clip/items/mob/head.dmi')
				H.update_icon()
	C.update_icon()
	C.update_slot_icon()
	to_chat(user, "<span class='notice'>Вы применяете набор к [C].</span>")
	qdel(src)

/obj/item/clip_reskin_kit/patrol
	name = "CLIP patrol hardsuit Kit"
	desc = "Набор, придающий костюму внешний вид «CLIP patrol hardsuit». Характеристики предмета остаются прежними."
	new_name = "CLIP patrol hardsuit"
	new_icon_state = "hardsuit-clip-patrol"
	obj_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/suit.dmi'
	worn_icon_file = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/suit.dmi'
	hardsuit_type = "clip-patrol"
	has_digi = TRUE

/obj/item/clip_reskin_kit/spotter
	name = "CLIP spotter hardsuit Kit"
	desc = "Набор, придающий костюму внешний вид «CLIP spotter hardsuit». Характеристики предмета остаются прежними."
	new_name = "CLIP spotter hardsuit"
	new_icon_state = "clip_spotter"
	obj_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/suit.dmi'
	worn_icon_file = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/suit.dmi'
	hardsuit_type = "clip_spotter"
	has_digi = TRUE

/obj/item/clip_reskin_kit/eod
	name = "CLIP EOD hardsuit Kit"
	desc = "Набор, придающий костюму внешний вид «CLIP EOD hardsuit». Характеристики предмета остаются прежними."
	new_name = "CLIP EOD hardsuit"
	new_icon_state = "hardsuit-clipeod"
	obj_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/suit.dmi'
	worn_icon_file = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/suit.dmi'
	hardsuit_type = "clipeod"

/obj/item/clip_reskin_kit/indus
	name = "CLIP industrial hardsuit Kit"
	desc = "Набор, придающий костюму внешний вид «CLIP industrial hardsuit». Характеристики предмета остаются прежними."
	new_name = "CLIP industrial hardsuit"
	new_icon_state = "hardsuit0-clipindus"
	obj_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/suit.dmi'
	worn_icon_file = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/suit.dmi'
	hardsuit_type = "clipindus"
	has_digi = TRUE

/obj/item/clip_reskin_kit/eva_suit
	name = "CLIP EVA suit Kit"
	desc = "Набор, придающий костюму внешний вид «CLIP EVA suit». Характеристики предмета остаются прежними."
	new_name = "CLIP EVA suit"
	new_icon_state = "space-clip"
	obj_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/suit.dmi'
	worn_icon_file = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/suit.dmi'

/obj/item/clip_reskin_kit/eva_armor_suit
	name = "CLIP armored EVA suit Kit"
	desc = "Набор, придающий костюму внешний вид «CLIP armored EVA suit». Характеристики предмета остаются прежними."
	new_name = "CLIP armored EVA suit"
	new_icon_state = "space-clip-armor"
	obj_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/suit.dmi'
	worn_icon_file = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/suit.dmi'

/obj/item/clip_reskin_kit/riot_armor
	name = "CLIP riot armor Kit"
	desc = "Набор, придающий костюму внешний вид «CLIP riot armor». Характеристики предмета остаются прежними."
	new_name = "CLIP riot armor"
	new_icon_state = "riot_clip"
	obj_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/suit.dmi'
	worn_icon_file = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/suit.dmi'

/obj/item/clip_reskin_kit/bard_suit
	name = "CLIP bard bio suit Kit"
	desc = "Набор, придающий костюму внешний вид «CLIP bard bio suit». Характеристики предмета остаются прежними."
	new_name = "CLIP bard bio suit"
	new_icon_state = "clip_bard_biosuit"
	obj_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/suit.dmi'
	worn_icon_file = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/suit.dmi'

/obj/item/clip_reskin_kit/bard_suit_medium
	name = "CLIP medium bard bio suit Kit"
	desc = "Набор, придающий костюму внешний вид «CLIP medium bard bio suit». Характеристики предмета остаются прежними."
	new_name = "CLIP medium bard bio suit"
	new_icon_state = "clip_bard_biosuit_medium"
	obj_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/suit.dmi'
	worn_icon_file = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/suit.dmi'

/obj/item/clip_reskin_kit/bard_suit_heavy
	name = "CLIP heavy bard bio suit Kit"
	desc = "Набор, придающий костюму внешний вид «CLIP heavy bard bio suit». Характеристики предмета остаются прежними."
	new_name = "CLIP heavy bard bio suit"
	new_icon_state = "clip_bard_biosuit_heavy"
	obj_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/suit.dmi'
	worn_icon_file = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/suit.dmi'

/obj/item/clip_reskin_kit/eva_helmet
	name = "CLIP EVA helmet Kit"
	desc = "Набор, придающий головному убору внешний вид «CLIP EVA helmet». Характеристики предмета остаются прежними."
	new_name = "CLIP EVA helmet"
	new_icon_state = "space-clip"
	required_slot = ITEM_SLOT_HEAD
	obj_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/head.dmi'
	worn_icon_file = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/head.dmi'

/obj/item/clip_reskin_kit/eva_armor_helmet
	name = "CLIP armored EVA helmet Kit"
	desc = "Набор, придающий головному убору внешний вид «CLIP armored EVA helmet». Характеристики предмета остаются прежними."
	new_name = "CLIP armored EVA helmet"
	new_icon_state = "space-clip-armor"
	required_slot = ITEM_SLOT_HEAD
	obj_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/head.dmi'
	worn_icon_file = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/head.dmi'

/obj/item/clip_reskin_kit/riot_helmet
	name = "CLIP riot helmet Kit"
	desc = "Набор, придающий головному убору внешний вид «CLIP riot helmet». Характеристики предмета остаются прежними."
	new_name = "CLIP riot helmet"
	new_icon_state = "riot_clip"
	required_slot = ITEM_SLOT_HEAD
	obj_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/head.dmi'
	worn_icon_file = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/head.dmi'

/obj/item/clip_reskin_kit/bard_hood
	name = "CLIP bard bio hood Kit"
	desc = "Набор, придающий головному убору внешний вид «CLIP bard bio hood». Характеристики предмета остаются прежними."
	new_name = "CLIP bard bio hood"
	new_icon_state = "clip_bard_bio"
	required_slot = ITEM_SLOT_HEAD
	obj_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/head.dmi'
	worn_icon_file = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/head.dmi'

/obj/item/clip_reskin_kit/bard_hood_armored
	name = "CLIP armored bard bio hood Kit"
	desc = "Набор, придающий головному убору внешний вид «CLIP armored bard bio hood». Характеристики предмета остаются прежними."
	new_name = "CLIP armored bard bio hood"
	new_icon_state = "clip_bard_bio_armored"
	required_slot = ITEM_SLOT_HEAD
	obj_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/head.dmi'
	worn_icon_file = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/head.dmi'

// //////////////////////////////////////////////////////// mech upgrade packs
// Меха не предметы, пак применяется кликом по меху и подменяет файл иконок.
// В mecha.dmi состояния названы как у обычных мехов (ripley, ripleymkii, gygax, durand и их -open / -broken),
// поэтому внутренняя логика мехов (вход / выход, поломка) продолжает находить свои спрайты.
// Подходит только базовым мехам (по началу названия текущего состояния), производные (firefighter, dark gygax и т.п.) не трогаются.

/obj/item/clip_mech_pack
	name = "CLIP mech upgrade pack"
	desc = "Пак улучшения, придающий меху внешний вид CLIP."
	icon = 'modular_bluemoon/fluffs/code/modules/clip/items/obj/pack.dmi'
	icon_state = "clipupgrade"
	var/mech_keyword = ""
	var/mech_icon = 'modular_bluemoon/fluffs/code/modules/clip/items/mob/mecha.dmi'

/obj/item/clip_mech_pack/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(!proximity || !ismecha(target))
		return
	if(target.icon == mech_icon)
		to_chat(user, "<span class='warning'>[target] уже имеет внешний вид CLIP.</span>")
		return
	if(findtext("[target.icon_state]", mech_keyword) != 1)
		to_chat(user, "<span class='warning'>Этот пак не подходит к [target].</span>")
		return
	target.icon = mech_icon
	target.update_icon()
	to_chat(user, "<span class='notice'>Вы применяете пак улучшения к [target].</span>")
	qdel(src)

/obj/item/clip_mech_pack/ripley
	name = "CLIP Ripley upgrade pack"
	desc = "Пак улучшения, придающий меху Ripley (Mk-I или Mk-II) внешний вид CLIP."
	mech_keyword = "ripley"

/obj/item/clip_mech_pack/gygax
	name = "CLIP Gygax upgrade pack"
	desc = "Пак улучшения, придающий меху Gygax внешний вид CLIP."
	mech_keyword = "gygax"

/obj/item/clip_mech_pack/durand
	name = "CLIP Durand upgrade pack"
	desc = "Пак улучшения, придающий меху Durand внешний вид CLIP."
	mech_keyword = "durand"

// //////////////////////////////////////////////////////// kit box

/obj/item/storage/box/clip_kit
	name = "CLIP kit"
	desc = "Армейский ящик с полным набором улучшений CLIP."
	icon_state = "ammobox"

/obj/item/storage/box/clip_kit/PopulateContents()
	new /obj/item/clip_reskin_kit/patrol(src)
	new /obj/item/clip_reskin_kit/spotter(src)
	new /obj/item/clip_reskin_kit/eod(src)
	new /obj/item/clip_reskin_kit/indus(src)
	new /obj/item/clip_reskin_kit/eva_suit(src)
	new /obj/item/clip_reskin_kit/eva_armor_suit(src)
	new /obj/item/clip_reskin_kit/riot_armor(src)
	new /obj/item/clip_reskin_kit/bard_suit(src)
	new /obj/item/clip_reskin_kit/bard_suit_medium(src)
	new /obj/item/clip_reskin_kit/bard_suit_heavy(src)
	new /obj/item/clip_reskin_kit/eva_helmet(src)
	new /obj/item/clip_reskin_kit/eva_armor_helmet(src)
	new /obj/item/clip_reskin_kit/riot_helmet(src)
	new /obj/item/clip_reskin_kit/bard_hood(src)
	new /obj/item/clip_reskin_kit/bard_hood_armored(src)
	new /obj/item/clip_mech_pack/ripley(src)
	new /obj/item/clip_mech_pack/gygax(src)
	new /obj/item/clip_mech_pack/durand(src)
