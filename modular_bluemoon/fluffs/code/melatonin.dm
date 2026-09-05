/obj/item/clothing/suit/armor/hos/platecarrier/melatonin
	DONATE_ITEM_TOOLTIP_PARENT
	name = "Lycanthrope's Reinforced Coat"
	desc = "Тяжелая кожаная куртка со следами долгого износа. Ткань на груди и спине заметно уплотнена — изнутри она прошита защитным слоем кевлара. По швам и воротнику куртки идут массивные клёпки из серебристого металла, а на рукавах затянуты грубые ремни. Шов между рукавом и правым плечом небрежно порван, обнажая подкладку, а чуть ниже пришита нашивка в форме полумесяца. Из-под потертой кожаной кобуры на плече отчетливо несет стойким запахом сигаретного дыма и перегара."
	icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit_digi.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit_digi.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/fluffs/icons/mob/clothing/suit_digi.dmi'
	icon_state = "melatonin-carrier-coat-0"
	unique_reskin = null
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0, WOUND = 0)
	clothing_flags = NONE
	strip_delay = 40
	equip_delay_other = 20
	slowdown = 0
	body_parts_covered = CHEST|GROIN|ARMS
	cold_protection = CHEST|GROIN|ARMS
	heat_protection = CHEST|GROIN|ARMS
	allowed = null

/obj/item/clothing/suit/armor/hos/platecarrier/melatonin/ComponentInitialize()
	return

/obj/item/clothing/suit/armor/hos/platecarrier/melatonin/Initialize(mapload)
	. = ..()
	allowed = null

/obj/item/clothing/suit/armor/hos/platecarrier/melatonin/equipped(mob/user, slot)
	. = ..()
	update_icon()

/obj/item/clothing/suit/armor/hos/platecarrier/melatonin/update_icon_state()
	. = ..()
	var/base_state = "melatonin-carrier-coat"
	icon_state = base_state
	if(!istype(loc, /mob/living/carbon/human))
		icon_state = "melatonin-carrier-coat-0"
		return
	var/mob/living/carbon/human/wearer = loc
	var/obj/item/organ/genital/breasts/breast = wearer.getorganslot(ORGAN_SLOT_BREASTS)
	var/breast_size = clamp(round(breast?.size || 0)-1, 0, 8)
	icon_state = "[base_state]-[breast_size]"
	if(wearer.get_item_by_slot(ITEM_SLOT_OCLOTHING) == src)
		wearer.update_inv_wear_suit()
		wearer.update_body()

/obj/item/clothing/suit/armor/hos/platecarrier
	var/obj/item/clothing/suit/armor/hos/platecarrier/melatonin/attached_coat
	var/initial_plate_name
	var/initial_plate_desc
	var/initial_plate_icon
	var/initial_plate_icon_state
	var/initial_plate_mob_overlay_icon
	var/initial_plate_anthro_mob_worn_overlay
	var/list/initial_plate_unique_reskin

/obj/item/clothing/suit/armor/hos/platecarrier/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/clothing/suit/armor/hos/platecarrier/melatonin))
		if(attached_coat)
			to_chat(user, span_warning("[src] уже имеет надетую куртку! Снимите её Alt+кликом."))
			return TRUE
		if(istype(src, /obj/item/clothing/suit/armor/hos/platecarrier/melatonin))
			return ..()
		var/obj/item/clothing/suit/armor/hos/platecarrier/melatonin/coat = I
		initial_plate_name = name
		initial_plate_desc = desc
		initial_plate_icon = icon
		initial_plate_icon_state = icon_state
		initial_plate_mob_overlay_icon = mob_overlay_icon
		initial_plate_anthro_mob_worn_overlay = anthro_mob_worn_overlay
		initial_plate_unique_reskin = unique_reskin
		if(ismob(coat.loc))
			var/mob/M = coat.loc
			M.temporarilyRemoveItemFromInventory(coat)
		coat.forceMove(src)
		attached_coat = coat
		name = coat.name
		desc = coat.desc
		icon = coat.icon
		icon_state = coat.icon_state
		mob_overlay_icon = coat.mob_overlay_icon
		anthro_mob_worn_overlay = coat.anthro_mob_worn_overlay
		unique_reskin = null
		to_chat(user, span_notice("Вы надеваете [coat] на [src]. Плитка сохраняет защиту плитника, но выглядит как куртка. Alt+клик по плитнику — снять."))
		update_icon()
		if(iscarbon(user))
			var/mob/living/carbon/C = user
			C.update_inv_wear_suit()
		return TRUE
	return ..()

/obj/item/clothing/suit/armor/hos/platecarrier/AltClick(mob/user)
	if(attached_coat && user.canUseTopic(src, BE_CLOSE))
		var/obj/item/clothing/suit/armor/hos/platecarrier/melatonin/coat = attached_coat
		name = initial_plate_name
		desc = initial_plate_desc
		icon = initial_plate_icon
		icon_state = initial_plate_icon_state
		mob_overlay_icon = initial_plate_mob_overlay_icon
		anthro_mob_worn_overlay = initial_plate_anthro_mob_worn_overlay
		unique_reskin = initial_plate_unique_reskin
		if(islist(unique_reskin) && length(unique_reskin))
			AddElement(/datum/element/object_reskinning)
		initial_plate_name = null
		initial_plate_desc = null
		initial_plate_icon = null
		initial_plate_icon_state = null
		initial_plate_mob_overlay_icon = null
		initial_plate_anthro_mob_worn_overlay = null
		initial_plate_unique_reskin = null
		attached_coat = null
		coat.forceMove(get_turf(src))
		if(user.put_in_hands(coat))
			to_chat(user, span_notice("Вы снимаете [coat] с [src], возвращая куртке её характеристики."))
		else
			to_chat(user, span_notice("Вы снимаете [coat] с [src]."))
		update_icon()
		if(iscarbon(user))
			var/mob/living/carbon/C = user
			C.update_inv_wear_suit()
		return TRUE
	return ..()

/obj/item/clothing/suit/armor/hos/platecarrier/examine(mob/user)
	. = ..()
	if(attached_coat)
		. += span_notice("На плитнике надета куртка [attached_coat]. Alt+клик чтобы снять.")

/obj/item/clothing/suit/armor/hos/platecarrier/Destroy()
	if(attached_coat)
		attached_coat.forceMove(get_turf(src))
		attached_coat = null
	return ..()

/obj/item/clothing/suit/armor/hos/platecarrier/equipped(mob/user, slot)
	. = ..()
	if(attached_coat)
		update_icon()

/obj/item/clothing/suit/armor/hos/platecarrier/update_icon_state()
	. = ..()
	if(attached_coat)
		var/base_state = "melatonin-carrier-coat"
		icon_state = base_state
		if(!istype(loc, /mob/living/carbon/human))
			icon_state = "melatonin-carrier-coat-0"
			return
		var/mob/living/carbon/human/wearer = loc
		var/obj/item/organ/genital/breasts/breast = wearer.getorganslot(ORGAN_SLOT_BREASTS)
		var/breast_size = clamp(round(breast?.size || 0)-1, 0, 8)
		icon_state = "[base_state]-[breast_size]"
		if(wearer.get_item_by_slot(ITEM_SLOT_OCLOTHING) == src)
			wearer.update_inv_wear_suit()
			wearer.update_body()

/obj/item/clothing/under/donator/bm/melatonin_bodysuit
	DONATE_ITEM_TOOLTIP_PARENT
	name = "Lycanthrope's Form-Fitting Bodysuit"
	desc = "Практически новый темно-серый бодисьют в безупречном состоянии, без единого следа износа. Светлые эластичные вставки по бокам и плотные шорты туго облегают тело, выгодно подчеркивая каждый изгиб фигуры — грудь, бедра и ягодицы. Длинные рукава закрывают руки вплоть до самых кистей. Со стороны костюм выглядит настолько утягивающим, будто готов пережать всё что угодно, но на удивление он ощущается невероятно удобным и совершенно не сковывает движения. На левом бедре аккуратно вышит фирменный полумесяц."
	mutantrace_variation = STYLE_DIGITIGRADE
	icon_state = "melatonin_uniform"
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/under.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/fluffs/icons/mob/clothing/under_digi.dmi'
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/under.dmi'
	can_adjust = FALSE
	fitted = NO_FEMALE_UNIFORM

/obj/item/clothing/under/donator/bm/melatonin_bodysuit/equipped(mob/user, slot)
	. = ..()
	if(slot != ITEM_SLOT_ICLOTHING)
		return
	update_icon()

/obj/item/clothing/under/donator/bm/melatonin_bodysuit/update_icon_state()
	. = ..()
	icon_state = initial(icon_state)
	if(!istype(loc, /mob/living/carbon/human))
		return
	var/mob/living/carbon/human/wearer = loc
	if(adjusted || !(DIGITIGRADE in wearer.dna.species.species_traits))
		return
	var/obj/item/organ/genital/breasts/breast = wearer.getorganslot(ORGAN_SLOT_BREASTS)
	var/breast_size = clamp(round(breast?.size || 0)-1, 0, 8)
	icon_state = "[initial(icon_state)]_[breast_size]"
	wearer.update_inv_w_uniform()
	wearer.update_body()

/obj/item/clothing/under/donator/bm/melatonin_bodysuit/toggle_jumpsuit_adjust()
	. = ..()
	if(.)
		update_icon()

/obj/item/storage/belt/security/webbing/ds/melatonin_belt
	DONATE_ITEM_TOOLTIP_PARENT
	name = "Lycanthrope's Heavy Tactical Belt"
	desc = "Массивный тактический пояс, который когда-то служил обычным утяжеленным ремнем. Со временем он оброс модификациями: к нему добавились прочная кожаная кобура, дополнительный поддерживающий ремень, подсумки для патронов и незаметные ножны для складного клинка. Вся эта конструкция выглядит исключительно надежной, хоть и неоправданно тяжелой. На крупной металлической пряжке по центру выгравирован оскал свирепого волка."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/belts.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/belt.dmi'
	icon_state = "melatonin_belt"
	item_state = "melatonin_belt"
	content_overlays = TRUE

/obj/item/melee/baton/get_belt_overlay()
	if(istype(loc, /obj/item/storage/belt/security/webbing/ds/melatonin_belt))
		return mutable_appearance('modular_bluemoon/fluffs/icons/obj/clothing/belts.dmi', "melatonin_baton")

	return ..()

/obj/item/melee/baton/stunsword/get_belt_overlay()
	if(istype(loc, /obj/item/storage/belt/security/webbing/ds/melatonin_belt))
		return mutable_appearance('modular_bluemoon/fluffs/icons/obj/clothing/belts.dmi',"melatonin_stunsword")

	return ..()

/obj/item/melee/baton/stunsword/stunkatana/get_belt_overlay()
	if(istype(loc, /obj/item/storage/belt/security/webbing/ds/melatonin_belt))
		return mutable_appearance('modular_bluemoon/fluffs/icons/obj/clothing/belts.dmi',"melatonin_stunsword")

	return ..()

/obj/item/modkit/melatonin_belt_kit
	name = "Lycanthrope's Heavy Tactical Belt Kit"
	desc = "A modkit for making a brig officer webbing into a Lycanthrope's Heavy Tactical Belt."
	product = /obj/item/storage/belt/security/webbing/ds/melatonin_belt
	fromitem = list(/obj/item/storage/belt/security/webbing/ds)

/obj/item/gun/ballistic/revolver/doublebarrel/melatonin
	DONATE_ITEM_TOOLTIP_PARENT
	name = "Nebula Workshop's 'Original Guilt'"
	desc = "Модернизированное двуствольное ружье, собранное на заказ из прочных полимеров. Оружие оснащено компактным тактическим прицелом-точкой, облегченным спусковым механизмом, системой автоматического взведения курков и умным электронным предохранителем. Несмотря на кастомную сборку, по строгим технологическим меркам Небульского Конкорда эта модель считается сильно устаревшей. Под блоком стволов красуется аккуратная каллиграфическая гравировка: «Nobody's evil»."
	unique_reskin = list()
	icon = 'modular_bluemoon/fluffs/icons/obj/48x32.dmi'
	icon_state = "melatonin_db"
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	item_state = "melatonin_db"

/obj/item/gun/ballistic/revolver/doublebarrel/sawn/melatonin
	DONATE_ITEM_TOOLTIP_PARENT
	name = "Sawn-Off Nebula Workshop's 'Original Guilt'"
	desc = "Модернизированное двуствольное ружье, собранное на заказ из прочных полимеров. Оружие оснащено компактным тактическим прицелом-точкой, облегченным спусковым механизмом, системой автоматического взведения курков и умным электронным предохранителем. Несмотря на кастомную сборку, по строгим технологическим меркам Небульского Конкорда эта модель считается сильно устаревшей. Под блоком стволов красуется аккуратная каллиграфическая гравировка: «Nobody's evil»."
	unique_reskin = list()
	icon = 'modular_bluemoon/fluffs/icons/obj/48x32.dmi'
	icon_state = "melatonin_db-so"
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	item_state = "melatonin_db"
	w_class = WEIGHT_CLASS_NORMAL
	weapon_weight = WEAPON_MEDIUM
	slot_flags = ITEM_SLOT_BELT

/obj/item/modkit/melatonin_shotgun_kit
	name = "Nebula Workshop's 'Original Guilt' Kit"
	desc = "A modkit for making a double-barreled shotgun into a Nebula Workshop's 'Original Guilt'."
	product = /obj/item/gun/ballistic/revolver/doublebarrel/melatonin
	fromitem = list(/obj/item/gun/ballistic/revolver/doublebarrel)

/obj/item/modkit/melatonin_shotgun_sawn_kit
	name = "Sawn-Off Nebula Workshop's 'Original Guilt' Kit"
	desc = "A modkit for making a sawn-off double-barreled shotgun into a Sawn-Off Nebula Workshop's 'Original Guilt'."
	product = /obj/item/gun/ballistic/revolver/doublebarrel/sawn/melatonin
	fromitem = list(/obj/item/gun/ballistic/revolver/doublebarrel/sawn)

/obj/item/gun/ballistic/automatic/pistol/enforcer/melatonin
	DONATE_ITEM_TOOLTIP_PARENT
	name = "Malorian Arms 'The Parade'"
	desc = "Эксклюзивный пистолет, выпущенный компанией Malorian Arms на базе единичной модели 3516 крайне ограниченным тиражом в Великобритании. Оружие переделано под облегченный калибр .45 ACP и штатно оснащено массивным утяжеленным и удлиненным стволом, а также подствольным отсеком под тактический фонарь или лазерный целеуказатель. Сложная автоматика делает его далеко не самым надежным пистолетом в галактике, но его хищный силуэт определенно заслуживает внимания. На замененной кастомной рукоятке отчетливо видны глубокие потертости и царапины, напоминающие следы от волчьих когтей."
	unique_reskin = list()
	icon = 'modular_bluemoon/fluffs/icons/obj/48x32.dmi'
	icon_state = "melatonin_werewolf"
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	item_state = "melatonin_werewolf"
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/parade/the_parade_firing_sound.ogg'
	load_sound = 'modular_bluemoon/fluffs/sound/weapon/parade/the_parade_mag_in.ogg'
	load_empty_sound = 'modular_bluemoon/fluffs/sound/weapon/parade/the_parade_mag_in.ogg'
	eject_sound = 'modular_bluemoon/fluffs/sound/weapon/parade/the_parade_mag_out.ogg'
	eject_empty_sound = 'modular_bluemoon/fluffs/sound/weapon/parade/the_parade_mag_out.ogg'
	lock_back_sound = 'modular_bluemoon/fluffs/sound/weapon/parade/the_parade_rack.ogg'

/obj/item/gun/ballistic/automatic/pistol/enforcer/melatonin/update_icon_state()
	. = ..()
	var/new_state = "[initial(icon_state)][chambered ? "" : "-e"][suppressed ? "-suppressed" : "" ][magazine && istype(magazine, /obj/item/ammo_box/magazine/e45/e45_extended) ? "-expended" : ""][magazine && istype(magazine, /obj/item/ammo_box/magazine/e45/e45_drum) ? "-drum" : ""]"
	icon_state = new_state
	item_state = new_state
	if(ismob(loc))
		var/mob/M = loc
		M.update_inv_hands()

/obj/item/modkit/melatonin_enforcer_kit
	name = "Malorian Arms 'The Parade' Kit"
	desc = "A modkit for making an Enforcer into a Malorian Arms 'The Parade'."
	product = /obj/item/gun/ballistic/automatic/pistol/enforcer/melatonin
	fromitem = list(/obj/item/gun/ballistic/automatic/pistol/enforcer/nomag, /obj/item/gun/ballistic/automatic/pistol/enforcer, /obj/item/gun/ballistic/automatic/pistol/enforcerred, /obj/item/gun/ballistic/automatic/pistol/enforcergold)

/obj/item/clothing/mask/gas/sechailer/melatonin
	DONATE_ITEM_TOOLTIP_PARENT
	name = "Dishonored \"Star Dust\" Combat Rebreather"
	desc = "Измененный и переделанный боевой ребризер ранней серии «Star Dust», некогда поставлявшийся ополчению Небулы и бойцам запаса Конкорда. Конструктивное отличие этой старой модели — дыхательные пазухи, расположенные по всему внешнему ободу корпуса, а не у основания, как на современных образцах. В отличие от фабричного оригинала, предназначенного для распыления аэрозольных медикаментов, этот прибор полностью заглушен. Его корпус запечатан глухими заглушками, намертво изолируя дыхательные пути пользователя от окружающей среды и превращая медицинское устройство в сугубо защитную маску."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/mask.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/mask.dmi'
	icon_state = "melatonin_gasmask"
	item_state = "melatonin_gasmask_equipped_down"
	flags_inv = HIDEFACIALHAIR|HIDEFACE
	visor_flags = BLOCK_GAS_SMOKE_EFFECT | ALLOWINTERNALS
	visor_flags_inv = HIDEFACE
	visor_flags_cover = MASKCOVERSMOUTH | MASKCOVERSEYES
	flags_cover = MASKCOVERSMOUTH
	alternate_worn_layer = BACK_LAYER
	actions_types = list(/datum/action/item_action/halt, /datum/action/item_action/adjust, /datum/action/item_action/dispatch)

/obj/item/clothing/mask/gas/sechailer/melatonin/build_worn_icon(default_layer, default_icon_file, isinhands, femaleuniform, override_state, style_flags, use_mob_overlay_icon, alpha_mask)
	if(!isinhands && item_state)
		override_state = item_state
	return ..()

/obj/item/clothing/mask/gas/sechailer/melatonin/attack_self(mob/user)
	adjustmask(user)

/obj/item/clothing/mask/gas/sechailer/melatonin/adjustmask(mob/living/user, just_flavor = FALSE)
	if(user && user.incapacitated())
		return FALSE
	mask_adjusted = !mask_adjusted
	if(!mask_adjusted)
		item_state = "melatonin_gasmask_equipped_up"
		if(!just_flavor)
			gas_transfer_coefficient = initial(gas_transfer_coefficient)
			permeability_coefficient = initial(permeability_coefficient)
			slot_flags = initial(slot_flags)
			flags_cover |= visor_flags_cover
			clothing_flags |= visor_flags
		flags_inv |= visor_flags_inv
	else
		item_state = "melatonin_gasmask_equipped_down"
		if(!just_flavor)
			gas_transfer_coefficient = null
			permeability_coefficient = null
			clothing_flags &= ~visor_flags
			flags_cover &= ~visor_flags_cover
			if(adjusted_flags)
				slot_flags = adjusted_flags
		flags_inv &= ~visor_flags_inv
	icon_state = "melatonin_gasmask"
	if(user)
		if(!just_flavor)
			to_chat(user, "<span class='notice'>You push \the [src] [mask_adjusted ? "out of the way" : "back into place"].</span>")
			user.wear_mask_update(src, toggle_off = mask_adjusted)
			user.update_action_buttons_icon()
		else
			to_chat(usr, "<span class='notice'>You adjust [src], it will now [mask_adjusted ? "not" : ""] obscure your identity while worn.</span>")
		user.update_inv_wear_mask()
	return TRUE

/obj/item/modkit/melatonin_gasmask_kit
	name = "Dishonored \"Star Dust\" Combat Rebreather Kit"
	desc = "A modkit for making a Security Gas Mask into a Dishonored \"Star Dust\" Combat Rebreather."
	product = /obj/item/clothing/mask/gas/sechailer/melatonin
	fromitem = list(/obj/item/clothing/mask/gas/sechailer)

/obj/item/clothing/head/helmet/riot/melatonin
	DONATE_ITEM_TOOLTIP_PARENT
	name = "Refurbished Concord Riot Helmet"
	desc = "Списанный и устаревший шлем противоударной защиты, некогда принадлежавший Небульскому Конкорду. Сам он выглядит как старая, возможно, дефектная модель, которую кропотливо восстанавливали вручную. Его защитные «уши» заметно отличаются по материалу и состоянию от остального корпуса — очевидно, их пришлось переделать, чтобы подогнать под анатомию Ликантропа. Несмотря на кустарный ремонт, шлем выглядит исключительно надежным и крепким. Внутри установлена простая операционная система, выводящая интерфейс на минималистичный дисплей теплого желтого оттенка, а само забрало оснащено функцией автоматического поднятия, избавляя от необходимости открывать его вручную."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/head.dmi'
	icon_state = "melatonin_helmet"
	flags_inv = HIDEEARS|HIDEFACE|HIDESNOUT
	visor_flags_inv = HIDEFACE|HIDESNOUT

/obj/item/modkit/melatonin_riot_kit
	name = "Refurbished Concord Riot Helmet Kit"
	desc = "A modkit for making a riot helmet into a Refurbished Concord Riot Helmet."
	product = /obj/item/clothing/head/helmet/riot/melatonin
	fromitem = list(/obj/item/clothing/head/helmet/riot)

/obj/item/melee/baton/stunsword/melatonin
	DONATE_ITEM_TOOLTIP_PARENT
	name = "Dunwall Folding Stun-Sword"
	desc = "Раритетное оружие, выполненное на заказ по сложной складной схеме, неуловимо напоминающей клинок лорда-защитника Дануолла. Оно оснащено компактной деревянной рукоятью со стальным кольцом на торце для быстрого извлечения из поясных ножен. Внутрь рукояти аккуратно встроены батарея и индикатор заряда. Острое лезвие угрожающе переливается искрами бледно-синей электрической энергии, которая, вопреки хищному и смертоносному виду клинка, предназначена лишь для мгновенного оглушения цели."
	icon = 'modular_bluemoon/fluffs/icons/obj/melee.dmi'
	icon_state = "melatonin_stunsword"
	item_state = "melatonin_stunsword"
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	turn_on_sound = 'modular_bluemoon/fluffs/sound/weapon/stunblade.ogg'
	hit_sound = 'modular_bluemoon/fluffs/sound/weapon/stunblade.ogg'

/obj/item/melee/baton/stunsword/melatonin/update_icon_state()
	. = ..()
	if(turned_on)
		icon_state = "melatonin_stunsword_on"
		item_state = "melatonin_stunsword_on"
	else if(!cell)
		icon_state = "melatonin_stunsword_no_cell"
		item_state = "melatonin_stunsword_no_cell"
	else
		icon_state = "melatonin_stunsword"
		item_state = "melatonin_stunsword"
	if(ismob(loc))
		var/mob/M = loc
		M.update_inv_hands()

/obj/item/melee/baton/stunsword/melatonin/get_belt_overlay()
	return mutable_appearance('modular_bluemoon/fluffs/icons/obj/clothing/belts.dmi', "melatonin_stunsword_overlay")

/obj/item/modkit/melatonin_stunsword_kit
	name = "Dunwall Folding Stun-Sword Kit"
	desc = "A modkit for making a stunbaton into a Dunwall Folding Stun-Sword."
	product = /obj/item/melee/baton/stunsword/melatonin
	fromitem = list(/obj/item/melee/baton/stunsword)

/obj/item/storage/box/melatonin_kit
	DONATE_ITEM_TOOLTIP_PARENT
	name = "Melatonin weapon case"
	desc = "Кейс с полным набором оружейных китов Melatonin. Содержит киты для модификации стандартного вооружения в кастомное."
	icon_state = "ammobox"

/obj/item/storage/box/melatonin_kit/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_combined_w_class = 21

/obj/item/storage/box/melatonin_kit/PopulateContents()
	new /obj/item/modkit/melatonin_belt_kit(src)
	new /obj/item/modkit/melatonin_shotgun_kit(src)
	new /obj/item/modkit/melatonin_shotgun_sawn_kit(src)
	new /obj/item/modkit/melatonin_enforcer_kit(src)
	new /obj/item/modkit/melatonin_gasmask_kit(src)
	new /obj/item/modkit/melatonin_riot_kit(src)
	new /obj/item/modkit/melatonin_stunsword_kit(src)

/datum/gear/donator/bm/melatonin_bodysuit
	name = "Lycanthrope's Form-Fitting Bodysuit"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/melatonin_bodysuit
	ckeywhitelist = list("melatonin1")

/datum/gear/donator/bm/melatonin_coat
	name = "Lycanthrope's Reinforced Coat"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/armor/hos/platecarrier/melatonin
	ckeywhitelist = list("melatonin1")

/datum/gear/donator/bm/melatonin_kit
	name = "Melatonin Kit Box"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/melatonin_kit
	ckeywhitelist = list("melatonin1")
