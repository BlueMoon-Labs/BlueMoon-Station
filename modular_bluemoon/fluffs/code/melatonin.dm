// Melatonin1 Custom Items - ckey melatonin1

// ========== 1. Lycanthrope's Reinforced Coat - Заменяет plate carrier ==========
/obj/item/clothing/suit/armor/hos/platecarrier/melatonin
	name = "Lycanthrope's Reinforced Coat"
	desc = "Тяжелая кожаная куртка со следами долгого износа. Ткань на груди и спине заметно уплотнена — изнутри она прошита защитным слоем кевлара. По швам и воротнику куртки идут массивные клёпки из серебристого металла, а на рукавах затянуты грубые ремни. Шов между рукавом и правым плечом небрежно порван, обнажая подкладку, а чуть ниже пришита нашивка в форме полумесяца. Из-под потертой кожаной кобуры на плече отчетливо несет стойким запахом сигаретного дыма и перегара."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/melatonin/melatonin_carrier.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/melatonin/melatonin_carrier.dmi'
	icon_state = "icon"
	item_state = "melatonin-carrier-coat-0"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/armor/hos/platecarrier/melatonin/build_worn_icon(default_layer, default_icon_file, isinhands, femaleuniform, override_state, style_flags, use_mob_overlay_icon, alpha_mask)
	if(!isinhands && item_state)
		override_state = item_state
	return ..()

/obj/item/clothing/suit/armor/hos/platecarrier/melatonin/update_icon_state()
	. = ..()
	if(current_equipped_slot == ITEM_SLOT_OCLOTHING && istype(loc, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = loc
		var/obj/item/organ/genital/breasts/B = H.getorganslot(ORGAN_SLOT_BREASTS)
		var/s = B ? B.size : 0
		var/t = clamp(round(s), 0, 8)
		item_state = "melatonin-carrier-coat-[t]"
		H.update_inv_wear_suit()

/obj/item/clothing/suit/armor/hos/platecarrier/melatonin/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_OCLOTHING)
		update_icon_state()

/obj/item/clothing/suit/armor/hos/platecarrier/melatonin/dropped(mob/user)
	. = ..()
	update_icon_state()

/obj/item/clothing/suit/armor/hos/platecarrier/melatonin/cosmetic
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0, WOUND = 0)

/obj/item/modkit/melatonin_carrier_kit
	name = "Lycanthrope's Reinforced Coat Kit"
	desc = "A modkit for making a plate carrier into a Lycanthrope's Reinforced Coat."
	product = /obj/item/clothing/suit/armor/hos/platecarrier/melatonin
	fromitem = list(/obj/item/clothing/suit/armor/hos/platecarrier)

// ========== 2. Lycanthrope's Form-Fitting Bodysuit - Отдельный предмет ==========
/obj/item/clothing/under/donator/bm/melatonin_bodysuit
	name = "Lycanthrope's Form-Fitting Bodysuit"
	desc = "Практически новый темно-серый бодисьют в безупречном состоянии, без единого следа износа. Светлые эластичные вставки по бокам и плотные шорты туго облегают тело, выгодно подчеркивая каждый изгиб фигуры — грудь, бедра и ягодицы. Длинные рукава закрывают руки вплоть до самых кистей. Со стороны костюм выглядит настолько утягивающим, будто готов пережать всё что угодно, но на удивление он ощущается невероятно удобным и совершенно не сковывает движения. На левом бедре аккуратно вышит фирменный полумесяц."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/melatonin/melatonin_uniform.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/melatonin/melatonin_uniform.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/fluffs/icons/mob/clothing/melatonin/melatonin_uniform.dmi'
	icon_state = "icon"
	item_state = "melatonin-uniform-0"
	can_adjust = FALSE
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/under/donator/bm/melatonin_bodysuit/build_worn_icon(default_layer, default_icon_file, isinhands, femaleuniform, override_state, style_flags, use_mob_overlay_icon, alpha_mask)
	if(!isinhands && item_state)
		override_state = item_state
	return ..()

/obj/item/clothing/under/donator/bm/melatonin_bodysuit/update_icon_state()
	. = ..()
	if(current_equipped_slot == ITEM_SLOT_ICLOTHING && istype(loc, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = loc
		var/obj/item/organ/genital/breasts/B = H.getorganslot(ORGAN_SLOT_BREASTS)
		var/s = B ? B.size : 0
		var/t = clamp(round(s), 0, 8)
		item_state = "melatonin-uniform-[t]"
		H.update_inv_w_uniform()

/obj/item/clothing/under/donator/bm/melatonin_bodysuit/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_ICLOTHING)
		update_icon_state()

/obj/item/clothing/under/donator/bm/melatonin_bodysuit/dropped(mob/user)
	. = ..()
	update_icon_state()

// ========== 3. Lycanthrope's Heavy Tactical Belt - Заменяет Brig Officer Webbing ==========
/obj/item/storage/belt/security/webbing/ds/melatonin
	name = "Lycanthrope's Heavy Tactical Belt"
	desc = "Массивный тактический пояс, который когда-то служил обычным утяжеленным ремнем. Со временем он оброс модификациями: к нему добавились прочная кожаная кобура, дополнительный поддерживающий ремень, подсумки для патронов и незаметные ножны для складного клинка. Вся эта конструкция выглядит исключительно надежной, хоть и неоправданно тяжелой. На крупной металлической пряжке по центру выгравирован оскал свирепого волка."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/melatonin/melatonin_belt.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/melatonin/melatonin_belt.dmi'
	icon_state = "icon"
	item_state = "on-body"

/obj/item/modkit/melatonin_belt_kit
	name = "Lycanthrope's Heavy Tactical Belt Kit"
	desc = "A modkit for making a brig officer webbing into a Lycanthrope's Heavy Tactical Belt."
	product = /obj/item/storage/belt/security/webbing/ds/melatonin
	fromitem = list(/obj/item/storage/belt/security/webbing/ds)

// ========== 4. Nebula Workshop's 'Original Guilt' - Заменяет Double-Barreled Shotgun ==========
/obj/item/gun/ballistic/revolver/doublebarrel/melatonin
	name = "Nebula Workshop's 'Original Guilt'"
	desc = "Модернизированное двуствольное ружье, собранное на заказ из прочных полимеров. Оружие оснащено компактным тактическим прицелом-точкой, облегченным спусковым механизмом, системой автоматического взведения курков и умным электронным предохранителем. Несмотря на кастомную сборку, по строгим технологическим меркам Небульского Конкорда эта модель считается сильно устаревшей. Под блоком стволов красуется аккуратная каллиграфическая гравировка: «Nobody's evil»."
	icon = 'modular_bluemoon/fluffs/icons/obj/melatonin/melatonin_shotgun.dmi'
	icon_state = "DB"
	item_state = "DB"
	mob_overlay_icon = null

/obj/item/gun/ballistic/revolver/doublebarrel/sawn/melatonin
	name = "Sawn-Off Nebula Workshop's 'Original Guilt'"
	desc = "Модернизированное двуствольное ружье, собранное на заказ из прочных полимеров. Оружие оснащено компактным тактическим прицелом-точкой, облегченным спусковым механизмом, системой автоматического взведения курков и умным электронным предохранителем. Несмотря на кастомную сборку, по строгим технологическим меркам Небульского Конкорда эта модель считается сильно устаревшей. Под блоком стволов красуется аккуратная каллиграфическая гравировка: «Nobody's evil»."
	icon = 'modular_bluemoon/fluffs/icons/obj/melatonin/melatonin_shotgun.dmi'
	icon_state = "DB-SO"
	item_state = "DB-SO"
	w_class = WEIGHT_CLASS_NORMAL
	weapon_weight = WEAPON_MEDIUM
	slot_flags = ITEM_SLOT_BELT
	mob_overlay_icon = null

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

// ========== 5. Mallorian Arms 'The Parade' - Заменяет Enforcer .45 ==========
/obj/item/gun/ballistic/automatic/pistol/enforcer/melatonin
	name = "Mallorian Arms 'The Parade'"
	desc = "Эксклюзивный пистолет, выпущенный компанией Mallorian Arms на базе единичной модели 3516 крайне ограниченным тиражом в Великобритании. Оружие переделано под облегченный калибр .45 ACP и штатно оснащено массивным утяжеленным и удлиненным стволом, а также подствольным отсеком под тактический фонарь или лазерный целеуказатель. Сложная автоматика делает его далеко не самым надежным пистолетом в галактике, но его хищный силуэт определенно заслуживает внимания. На замененной кастомной рукоятке отчетливо видны глубокие потертости и царапины, напоминающие следы от волчьих когтей."
	icon = 'modular_bluemoon/fluffs/icons/obj/melatonin/melatonin_enforcer.dmi'
	mob_overlay_icon = null
	icon_state = "werewolf"
	item_state = "werewolf"

/obj/item/gun/ballistic/automatic/pistol/enforcer/melatonin/update_icon_state()
	icon_state = "[initial(icon_state)][chambered ? "" : "-e"][suppressed ? "-suppressed" : "" ][magazine && istype(magazine, /obj/item/ammo_box/magazine/e45/e45_extended) ? "-expended" : ""][magazine && istype(magazine, /obj/item/ammo_box/magazine/e45/e45_drum) ? "-drum" : ""]"

/obj/item/modkit/melatonin_enforcer_kit
	name = "Mallorian Arms 'The Parade' Kit"
	desc = "A modkit for making an Enforcer into a Mallorian Arms 'The Parade'."
	product = /obj/item/gun/ballistic/automatic/pistol/enforcer/melatonin
	fromitem = list(/obj/item/gun/ballistic/automatic/pistol/enforcer/nomag, /obj/item/gun/ballistic/automatic/pistol/enforcer, /obj/item/gun/ballistic/automatic/pistol/enforcerred, /obj/item/gun/ballistic/automatic/pistol/enforcergold)

// ========== 6. Dishonored "Star Dust" Combat Rebreather - Заменяет противогаз СБ ==========
/obj/item/clothing/mask/gas/sechailer/melatonin
	name = "Dishonored \"Star Dust\" Combat Rebreather"
	desc = "Измененный и переделанный боевой ребризер ранней серии «Star Dust», некогда поставлявшийся ополчению Небулы и бойцам запаса Конкорда. Конструктивное отличие этой старой модели — дыхательные пазухи, расположенные по всему внешнему ободу корпуса, а не у основания, как на современных образцах. В отличие от фабричного оригинала, предназначенного для распыления аэрозольных медикаментов, этот прибор полностью заглушен. Его корпус запечатан глухими заглушками, намертво изолируя дыхательные пути пользователя от окружающей среды и превращая медицинское устройство в сугубо защитную маску."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/melatonin/melatonin_gasmask.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/melatonin/melatonin_gasmask.dmi'
	icon_state = "icon"
	item_state = "equipped-down"
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
		item_state = "equipped-up"
		if(!just_flavor)
			gas_transfer_coefficient = initial(gas_transfer_coefficient)
			permeability_coefficient = initial(permeability_coefficient)
			slot_flags = initial(slot_flags)
			flags_cover |= visor_flags_cover
			clothing_flags |= visor_flags
		flags_inv |= visor_flags_inv
	else
		item_state = "equipped-down"
		if(!just_flavor)
			gas_transfer_coefficient = null
			permeability_coefficient = null
			clothing_flags &= ~visor_flags
			flags_cover &= ~visor_flags_cover
			if(adjusted_flags)
				slot_flags = adjusted_flags
		flags_inv &= ~visor_flags_inv
	icon_state = "icon"
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

// ========== 7. Refurbished Concord Riot Helmet - Заменяет Riot Helmet ==========
/obj/item/clothing/head/helmet/riot/melatonin
	name = "Refurbished Concord Riot Helmet"
	desc = "Списанный и устаревший шлем противоударной защиты, некогда принадлежавший Небульскому Конкорду. Сам он выглядит как старая, возможно, дефектная модель, которую кропотливо восстанавливали вручную. Его защитные «уши» заметно отличаются по материалу и состоянию от остального корпуса — очевидно, их пришлось переделать, чтобы подогнать под анатомию Ликантропа. Несмотря на кустарный ремонт, шлем выглядит исключительно надежным и крепким. Внутри установлена простая операционная система, выводящая интерфейс на минималистичный дисплей теплого желтого оттенка, а само забрало оснащено функцией автоматического поднятия, избавляя от необходимости открывать его вручную."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/melatonin/melatonin_riot.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/melatonin/melatonin_riot.dmi'
	icon_state = "icon-close"
	item_state = "equipped-close"
	flags_inv = HIDEEARS|HIDEFACE|HIDEHAIR
	can_toggle = TRUE
	toggle_message = "You pull the visor down on"
	alt_toggle_message = "You push the visor up on"
	actions_types = list(/datum/action/item_action/toggle)
	visor_flags_inv = HIDEFACE
	visor_flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH

/obj/item/clothing/head/helmet/riot/melatonin/build_worn_icon(default_layer, default_icon_file, isinhands, femaleuniform, override_state, style_flags, use_mob_overlay_icon, alpha_mask)
	if(!isinhands && item_state)
		override_state = item_state
	return ..()

/obj/item/clothing/head/helmet/riot/melatonin/attack_self(mob/user)
	. = ..()
	if(up)
		icon_state = "icon-open"
		item_state = "equipped-open"
	else
		icon_state = "icon-close"
		item_state = "equipped-close"
	user.update_inv_head()
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		C.head_update(src, forced = 1)

/obj/item/clothing/head/helmet/riot/melatonin/cosmetic
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0, WOUND = 0)

/obj/item/modkit/melatonin_riot_kit
	name = "Refurbished Concord Riot Helmet Kit"
	desc = "A modkit for making a riot helmet into a Refurbished Concord Riot Helmet."
	product = /obj/item/clothing/head/helmet/riot/melatonin
	fromitem = list(/obj/item/clothing/head/helmet/riot)

// ========== 8. Dunwall Folding Stun-Sword - Заменяет Stun Sword ==========
/obj/item/melee/baton/stunsword/melatonin
	name = "Dunwall Folding Stun-Sword"
	desc = "Раритетное оружие, выполненное на заказ по сложной складной схеме, неуловимо напоминающей клинок лорда-защитника Дануолла. Оно оснащено компактной деревянной рукоятью со стальным кольцом на торце для быстрого извлечения из поясных ножен. Внутрь рукояти аккуратно встроены батарея и индикатор заряда. Острое лезвие угрожающе переливается искрами бледно-синей электрической энергии, которая, вопреки хищному и смертоносному виду клинка, предназначена лишь для мгновенного оглушения цели."
	icon = 'modular_bluemoon/fluffs/icons/obj/melatonin/melatonin_stunsword.dmi'
	mob_overlay_icon = null
	icon_state = "Off"
	item_state = "Off"
	slot_flags = ITEM_SLOT_BELT
	turn_on_sound = 'modular_bluemoon/fluffs/sound/weapon/stunblade.ogg'
	hit_sound = 'modular_bluemoon/fluffs/sound/weapon/stunblade.ogg'

/obj/item/melee/baton/stunsword/melatonin/update_icon_state()
	if(turned_on)
		icon_state = "On"
		item_state = "On"
	else if(!cell)
		icon_state = "No-cell"
		item_state = "No-cell"
	else
		icon_state = "Off"
		item_state = "Off"

/obj/item/melee/baton/stunsword/melatonin/get_belt_overlay()
	return mutable_appearance('modular_bluemoon/fluffs/icons/obj/clothing/melatonin/melatonin_belt.dmi', "overlay-stunsword")

/obj/item/modkit/melatonin_stunsword_kit
	name = "Dunwall Folding Stun-Sword Kit"
	desc = "A modkit for making a stunbaton into a Dunwall Folding Stun-Sword."
	product = /obj/item/melee/baton/stunsword/melatonin
	fromitem = list(/obj/item/melee/baton, /obj/item/melee/baton/loaded)

/obj/item/storage/box/melatonin_kit
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
	new /obj/item/modkit/melatonin_stunsword_kit(src)

// ========== Donator Gear for Melatonin1 ==========
/datum/gear/donator/bm/melatonin_bodysuit
	name = "Lycanthrope's Form-Fitting Bodysuit"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/melatonin_bodysuit
	ckeywhitelist = list("melatonin1")

/datum/gear/donator/bm/melatonin_carrier_cosmetic
	name = "Lycanthrope's Reinforced Coat (Cosmetic)"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/armor/hos/platecarrier/melatonin/cosmetic
	ckeywhitelist = list("melatonin1")

/datum/gear/donator/bm/melatonin_riot_cosmetic
	name = "Refurbished Concord Riot Helmet (Cosmetic)"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/helmet/riot/melatonin/cosmetic
	ckeywhitelist = list("melatonin1")

/datum/gear/donator/bm/melatonin_kit
	name = "Melatonin Kit Box"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/melatonin_kit
	ckeywhitelist = list("melatonin1")

