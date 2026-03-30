// -----------------------------------------------[Инфильтраторка]-------------------------------------------
/obj/item/clothing/head/helmet/infiltrator/inteq
	name = "SpecOps Helmet"
	desc = "Лёгкий шлем с панорамным визором. Покрыт защитной плёнкой, спасающей владельца от ярких вспышек, а армированный визор сможет выдержать не одну пулю во время твоей 'скрытной' миссии."
	icon_state = "infiltrator_h"
	item_state = "infiltrator_h"
	icon = 'modular_bluemoon/Ren/Icons/Obj/infiltrator.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Ren/Icons/Mob/clothing_digi.dmi'

/obj/item/clothing/head/helmet/infiltrator/inteq/equipped(mob/living/carbon/human/user, slot)
	..()
	if (slot == ITEM_SLOT_HEAD)
		user.digitalcamo = TRUE
		user.digitalinvis = TRUE

/obj/item/clothing/head/helmet/infiltrator/inteq/dropped(mob/living/carbon/human/user)
	..()
	if (user.head == src)
		user.digitalcamo = FALSE
		user.digitalinvis = FALSE

/obj/item/clothing/gloves/tackler/combat/insulated/infiltrator/inteq
	name = "SpecOps Guerrilla Gloves"
	desc = "Боевые перчатки предназначенные для усиления навыков владельца. Встроенные наночипы напрямую посылают сигналы в нервные окончания рук, доводя движения владельца до идеала, что позволяет укладывать жертв на землю и перетаскивать их с максимальной эффективностью."
	icon_state = "infiltrator_g"
	item_state = "infiltrator_g"
	icon = 'modular_bluemoon/Ren/Icons/Obj/infiltrator.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Ren/Icons/Mob/clothing_digi.dmi'

/obj/item/clothing/mask/infiltrator/inteq
	name = "SpecOps Balaclava"
	desc = "Необычная балаклава со встроенным блоком изменения голоса. Выглядит немного кустарно, но идеально справляется со своими задачами"
	icon_state = "infiltrator_m"
	item_state = "infiltrator_m"
	icon = 'modular_bluemoon/Ren/Icons/Obj/infiltrator.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Ren/Icons/Mob/clothing_digi.dmi'

/obj/item/clothing/suit/armor/vest/infiltrator/inteq
	name = "SpecOps combat vest"
	desc = "Качественный бронежилет с броне пластиной из многослойной пластали. Совмещает в себе лёгкость и прочность, имеет буферный подкладки и идеально прилегает к телу, не издавая лишних звуков при ношении."
	icon_state = "infiltrator_a"
	item_state = "infiltrator_a"
	icon = 'modular_bluemoon/Ren/Icons/Obj/infiltrator.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'

/obj/item/clothing/under/inteq/tactical_gorka
	name = "SpecOps gorka"
	desc = "Костюм данной модели, выполнен на основе классической модели Горка. Изготавливается из особо прочной ткани Рип Стоп с водоотталкивающей пропиткой и высоким содержанием хлопка и полиэфирных нитей. Идеально подогнан под пропорции клиента и прекрасно подходит для грязной работы."
	icon_state = "infiltrator_u"
	item_state = "infiltrator_u"
	armor = list(MELEE = 10, BULLET = 10, LASER = 10,ENERGY = 10, BOMB = 0, BIO = 0, RAD = 10, FIRE = 50, ACID = 20, WOUND = 5)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	can_adjust = FALSE
	icon = 'modular_bluemoon/Ren/Icons/Obj/infiltrator.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Ren/Icons/Mob/clothing_digi.dmi'

/obj/item/clothing/shoes/combat/sneakboots/inteq
	name = "SpecOps sneakboots"
	desc = "Пара ботинок с высоким берцем. Подошва покрыта звукопоглощающим слоем, почти полностью сводя шум шагов на нет. Выполнены в карго стиле, воплощая в себе саму идею практичности."
	icon_state = "sneakboots"
	item_state = "sneakboots"
	icon = 'modular_bluemoon/Ren/Icons/Obj/infiltrator.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Ren/Icons/Mob/clothing_digi.dmi'

// -----------------------------------------------[Железное надгробие]-------------------------------------------
/obj/item/clothing/head/helmet/space/hardsuit/iron_tombstone
	name = "Iron Tombstone helmet"
	desc = "Ты чувствуешь тяжесть  просто смотря на эту броню."
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Ren/Icons/Mob/clothing_digi.dmi'
	item_state = "hardsuit0-iron_tombstone"
	icon_state = "hardsuit0-iron_tombstone"
	hardsuit_type = "iron_tombstone"
	armor = list(MELEE = 50, BULLET = 70, LASER = 10,ENERGY = 10, BOMB = 40, BIO = 70, RAD = 10, FIRE = 10, ACID = 10, WOUND = 30)
	flash_protect = 2
	strip_delay = 90
	equip_delay_self = 15
	actions_types = list()
	flags_inv = HIDEHAIR|HIDEEARS|HIDEFACIALHAIR|HIDEFACE|HIDEMASK|HIDESNOUT

/obj/item/clothing/suit/space/hardsuit/iron_tombstone
	name = "Iron Tombstone armor"
	desc = "Ты чувствуешь тяжесть просто смотря на эту броню."
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Ren/Icons/Mob/clothing_digi.dmi'
	item_state = "hardsuit-iron_tombstone"
	icon_state = "hardsuit-iron_tombstone"
	tail_state = "syndicate-elite"
	hardsuit_type = "iron_tombstone"
	armor = list(MELEE = 50, BULLET = 70, LASER = 10,ENERGY = 10, BOMB = 40, BIO = 70, RAD = 10, FIRE = 10, ACID = 10, WOUND = 30)
	allowed = list(/obj/item/gun, /obj/item/ammo_box,/obj/item/ammo_casing, /obj/item/melee/baton, /obj/item/melee/transforming/energy/sword/saber, /obj/item/restraints/handcuffs, /obj/item/tank/internals)
	strip_delay = 120
	equip_delay_self = 20
	slowdown = 0.3
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/iron_tombstone
	actions_types = list(/datum/action/item_action/toggle_helmet)
	mutantrace_variation = STYLE_DIGITIGRADE

// -----------------------------------------------[Космодесантник]-------------------------------------------
// Взрыв при экипировке
/obj/item/clothing/suit/space/syndicate/darktemplar/equipped(mob/user, slot)
	..()
	if(slot == ITEM_SLOT_OCLOTHING)
		if(!IS_INTEQ(user))
			to_chat(user, "<span class='danger'><B>Запуск проверки генетического кода</B><br> Обнаружены неавторизованные сигнатуры. <B>ПРОИЗВОДИТСЯ ОЧИСТКА</B></span>")
			playsound(get_turf(src), 'sound/machines/nuke/confirm_beep.ogg', 65, 1, 1)
			addtimer(CALLBACK(src, PROC_REF(explode)), 3 SECONDS)

/obj/item/clothing/suit/space/syndicate/darktemplar/proc/explode()
	do_sparks(3, 1, src)
	explosion(src.loc,0,1,1,1)
	qdel(src)
// Шлем
/obj/item/clothing/head/helmet/space/syndicate/darktemplar
	name = "Dark Power Armour helmet"
	desc = "Громоздкий шлем, созданный что бы вселять страх в сердца предателей и ксеносов."
	icon_state = "darktemplar_helm"
	item_state = "darktemplar_helm"
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'
	lefthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_l.dmi'
	righthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_r.dmi'
	equip_delay_self = 50
	resistance_flags = FIRE_PROOF | ACID_PROOF
	heat_protection = HEAD
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	alternate_screams = SPASEMAR_SCREAMS
	armor = list(MELEE = 50, BULLET = 50, LASER = 35, ENERGY = 30, BOMB = 60, BIO = 100, RAD = 100, FIRE = 100, ACID = 100, WOUND = 20)
	equip_sound = 'modular_bluemoon/Ren/Sound/equp1.ogg'
	mutantrace_variation = NONE
	unique_reskin = list("Dark Power Armour helmet holy patern" = list(RESKIN_ICON_STATE = "darktemplar_chaplai_helm"), "Dark Power Armour helmet InteQ patern MKI" = list(RESKIN_ICON_STATE = "darktemplar_helm_inteq"), "Dark Power Armour helmet InteQ patern MKII" = list(RESKIN_ICON_STATE = "darktemplar_helm_inteq_alt"))

/obj/item/clothing/head/helmet/space/syndicate/darktemplar/equipped(mob/living/carbon/human/user, slot)
	..()
	if (slot == ITEM_SLOT_HEAD)
		var/datum/atom_hud/DHUD = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
		DHUD.add_hud_to(user)

/obj/item/clothing/head/helmet/space/syndicate/darktemplar/dropped(mob/living/carbon/human/user)
	..()
	if (user.head == src)
		var/datum/atom_hud/DHUD = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
		DHUD.remove_hud_from(user)
//броня
/obj/item/clothing/suit/space/syndicate/darktemplar
	name = "Dark Power Armour"
	desc = "Силовая броня древнего паттерна которому уже несколько сотен лет. Хоть и успела морально устареть по сравнению с современной бронёй, но до сих пор отлично защищает носителя от разной ксеноугрозы. "
	icon_state = "darktemplar"
	item_state = "darktemplar"
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	equip_delay_self = 50
	resistance_flags = FIRE_PROOF | ACID_PROOF
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	alternate_screams = SPASEMAR_SCREAMS
	armor = list(MELEE = 50, BULLET = 50, LASER = 35, ENERGY = 30, BOMB = 60, BIO = 100, RAD = 100, FIRE = 100, ACID = 100, WOUND = 20)
	equip_sound = 'modular_bluemoon/Ren/Sound/equp.ogg'
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_SNEK_TAURIC
	anthro_mob_worn_overlay = 'modular_bluemoon/Ren/Icons/Mob/clothing_digi.dmi'
	unique_reskin = list("Dark Power Armour holy patern" = list(RESKIN_ICON_STATE = "darktemplar_chaplai"), "Dark Power Armour InteQ patern MKI" = list(RESKIN_ICON_STATE = "darktemplar_inteq"), "Dark Power Armour InteQ patern MKII" = list(RESKIN_ICON_STATE = "darktemplar_inteq_alt") )

///Кричалка с крутыми фразами. Они прописаны в коде хайлера.
/obj/item/clothing/mask/gas/sechailer/angrymarin
	name = "Space Marine Gas Mask"
	desc = "Древняя система подачи кислорода объединённая с вокс системой, усиливающей голос пользователя"
	resistance_flags = FIRE_PROOF | ACID_PROOF
	actions_types = list(/datum/action/item_action/halt)
	aggressiveness = 999 ///Очень злой
	recent_uses = -10

///Ботинки с крутым звуком топота
/obj/item/clothing/shoes/jackboots/powerbots
	name = "Power boots"
	desc = "Тяжёлые латные ботинки созданные, что бы ходить по трупам поверженных врагов."
	clothing_flags = NOSLIP
	resistance_flags = FIRE_PROOF | ACID_PROOF
	armor = list(MELEE = 15, BULLET = 15, LASER = 15, ENERGY = 15, BOMB = 0, BIO = 0, RAD = 0, FIRE = 40, ACID = 75)

/obj/item/clothing/shoes/jackboots/powerbots/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/squeak, list('modular_bluemoon/Ren/Sound/step/ast_step1.ogg'=1,'modular_bluemoon/Ren/Sound/step/ast_step2.ogg'=1), 60)

/obj/item/clothing/shoes/jackboots/powerbots/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_FEET)
		ADD_TRAIT(user, TRAIT_SILENT_STEP, SHOES_TRAIT)

/obj/item/clothing/shoes/jackboots/powerbots/dropped(mob/user)
	. = ..()
	REMOVE_TRAIT(user, TRAIT_SILENT_STEP, SHOES_TRAIT)

///Орган космодесанта. От него идут основные силы
/obj/item/organ/organic_implants/ossmodula
	name = "Ossmodula"
	desc = "Strange small gland"
	icon_state = "pheropod"
	slot = ORGAN_SLOT_ORGANIC_IMPLANT

/obj/item/organ/organic_implants/ossmodula/Insert(mob/living/carbon/M, drop_if_replaced = TRUE)
	..()
	ADD_TRAIT(owner, TRAIT_GIANT, GENETIC_MUTATION)
	ADD_TRAIT(owner, TRAIT_NOSOFTCRIT, GENETIC_MUTATION)
	ADD_TRAIT(owner, TRAIT_NOHARDCRIT, GENETIC_MUTATION)
	ADD_TRAIT(owner, TRAIT_STUNIMMUNE, GENETIC_MUTATION)
	ADD_TRAIT(owner, TRAIT_PUSHIMMUNE, GENETIC_MUTATION)
	var/size = get_size(owner)
	owner.update_size(size * 1.35)
	owner.visible_message("<span class='danger'>[owner] Внезапно становится больше!</span>", "<span class='notice'>Всё вокруг неожиданно уменьшается..</span>")

/obj/item/organ/organic_implants/ossmodula/Remove(special = FALSE)
	if(!QDELETED(owner))
		REMOVE_TRAIT(owner, TRAIT_NOSOFTCRIT, GENETIC_MUTATION)
		REMOVE_TRAIT(owner, TRAIT_NOHARDCRIT, GENETIC_MUTATION)
		REMOVE_TRAIT(owner, TRAIT_STUNIMMUNE, GENETIC_MUTATION)
		REMOVE_TRAIT(owner, TRAIT_PUSHIMMUNE, GENETIC_MUTATION)
	return ..()

/obj/item/autosurgeon/syndicate/inteq/astartes
	desc = "Последний шаг, разделяющий жизнь человека от жизни ангела смерти"
	uses = 1
	starting_organ = /obj/item/organ/organic_implants/ossmodula

/obj/item/nullrod/claymore/chainsaw_sword/real
	force = 35

//безумие
/obj/item/clothing/head/helmet/hank
	name = "Black old bandana"
	desc = "Чёрная бандана на голову, призванная скрыть бинты. В этих красных очках виднелось отражение не одной сотни смертей."
	icon_state = "hank_m"
	item_state = "hank_m"
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	armor = list(MELEE = 20, BULLET = 20, LASER = 20, ENERGY = 10, BOMB = 0, BIO = 50, RAD = 0, FIRE = 50, ACID = 50, WOUND = 35)
	flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDEFACIALHAIR|HIDESNOUT
	flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH
	resistance_flags = FIRE_PROOF | ACID_PROOF
	flash_protect = 2
	mutantrace_variation = NONE

/obj/item/clothing/head/helmet/hank/equipped(mob/user, slot)
	..()
	if(slot == ITEM_SLOT_HEAD)
		if((!IS_INTEQ(user)) && (user.client))
			if(!HAS_TRAIT(user, TRAIT_FEARLESS))
				SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "anxiety_head", /datum/mood_event/inteq_habar, src.name)
	else
		SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "anxiety_head", /datum/mood_event/inteq_drop)

/obj/item/clothing/suit/armor/hank
	name = "Old black coat"
	desc = "Поношенный временем костюм. Его чернота отдаёт красным оттенком, а сам он удивительно хорошо прилегает к телу."
	icon_state = "hank"
	item_state = "hank"
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	armor = list(MELEE = 20, BULLET = 20, LASER = 20, ENERGY = 10, BOMB = 0, BIO = 50, RAD = 0, FIRE = 50, ACID = 50, WOUND = 35)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	mutantrace_variation = NONE

/obj/item/clothing/suit/armor/hank/equipped(mob/user, slot)
	..()
	if(slot == ITEM_SLOT_OCLOTHING)
		if((!IS_INTEQ(user)) && (user.client))
			if(!HAS_TRAIT(user, TRAIT_FEARLESS))
				SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "anxiety_upon", /datum/mood_event/inteq_habar, src.name)
	else
		SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "anxiety_upon", /datum/mood_event/inteq_drop)

/obj/item/clothing/suit/armor/hank/run_block(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	. = ..()
	if((!IS_INTEQ(owner)) && (owner.client))
		return BULLET_ACT_HIT
	if(owner.incapacitated(FALSE, TRUE))
		return BULLET_ACT_HIT
	if(!CHECK_ALL_MOBILITY(owner, MOBILITY_USE|MOBILITY_STAND))
		return BULLET_ACT_HIT
	if(!isturf(owner.loc))
		return BULLET_ACT_HIT
	if((attack_type & ATTACK_TYPE_PROJECTILE) && (rand(3) != 1))
		owner.visible_message(pick("<span class='danger'>[owner] чудом уворачивается от пули, выгнувшись спиной в последний момент!</span>", "<span class='danger'>[owner] ловко уходит в сторону, предугадав траекторию выстрела!</span>", "<span class='danger'>[owner] делает резкий рывок, едва успевая уйти из под огня!</span>"))
		playsound(src, pick('sound/weapons/bulletflyby.ogg', 'sound/weapons/bulletflyby2.ogg', 'sound/weapons/bulletflyby3.ogg'), 75, 1)
		return BLOCK_SUCCESS | BLOCK_PHYSICAL_EXTERNAL
	return ..()

///Ошейники для заложников.
/obj/item/electropack/shockcollar/bomb
	name = "Bomb collar"
	desc = "Металлический ошейник с покрытием из кожи. В центре красуется странное устройство с мигающей лампочкой. Он.. точно должен пикать?"
	icon = 'modular_bluemoon/Ren/Icons/Obj/infiltrator.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	icon_state = "bombcollar"
	item_state = "bombcollar"
	equip_delay_other = 40
	strip_delay = 360

/obj/item/electropack/shockcollar/bomb/receive_signal(datum/signal/signal)
	if(!signal || signal.data["code"] != code)
		return

	if(isliving(loc))
		playsound(get_turf(src), 'sound/machines/nuke/confirm_beep.ogg', 65, 1, 1)
		addtimer(CALLBACK(src, PROC_REF(explode)), 3 SECONDS)

	if(master)
		master.receive_signal()

/obj/item/electropack/shockcollar/bomb/proc/explode()
	do_sparks(3, 1, src)
	explosion(src.loc,1,0,2,0)
	qdel(src)

/obj/item/clothing/glasses/inteq_xray
	name = "X-ray visor"
	desc = "На столько же высокотехнологичные, на столько же и хрупкие очки полного виденья. Держать подальше от ЭМИ"
	icon_state = "xray"
	item_state = "xray"
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	flags_cover = GLASSESCOVERSEYES
	darkness_view = 3
	flash_protect = -3
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	vision_flags = SEE_TURFS|SEE_MOBS|SEE_OBJS
	glass_colour_type = /datum/client_colour/glass_colour/orange


/obj/item/clothing/glasses/inteq_xray/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	vision_flags = NONE
	darkness_view = 0
	flash_protect = 0
	thermal_overload()

///Наборы бронирования
/// Тело
/obj/item/armorkit/inteq
	name = "Quiet kid armor kit"
	desc = "Набор гибких армированных пластин которые будут совершенно незаметно сидеть под твоей толстовкой, с которой ты так не захотел расставаться даже на миссии, хиккан."
	icon_state = "inteq_armor_kit"
	icon = 'modular_bluemoon/Ren/Icons/Obj/misc.dmi'
	w_class = WEIGHT_CLASS_SMALL

/obj/item/armorkit/inteq/afterattack(obj/item/target, mob/user, proximity_flag, click_parameters)
	var/used = FALSE
	if(!isclothing(target))
		return
	if(!(isobj(target) && target.slot_flags & ITEM_SLOT_OCLOTHING))
		return
	if(target.type in typesof(/obj/item/clothing/suit/toggle/captains_parade, /obj/item/clothing/suit/space, /obj/item/clothing/suit/armor))
		to_chat(user, span_danger("You cannot modify [target], as it already has armor or is a part of special equipment."))
		return
	var/obj/item/clothing/C = target
	var/obj/item/clothing/suit/armor/vest/bluesheid/A = new /obj/item/clothing/suit/armor/vest/bluesheid(src)
	C.set_armor(A.armor)
	C.body_parts_covered = A.body_parts_covered
	C.cold_protection = A.cold_protection
	C.heat_protection = A.heat_protection
	C.resistance_flags = A.resistance_flags
	C.clothing_flags = A.clothing_flags
	C.min_cold_protection_temperature = A.min_cold_protection_temperature
	C.max_heat_protection_temperature = A.max_heat_protection_temperature
	used = TRUE
	if(used)
		C.allowed = GLOB.security_vest_allowed
		user.visible_message("<span class = 'notice'>[user] reinforces [C] with [src].</span>", \
		"<span class = 'notice'>You reinforce [C] with [src], making it as protective as a armored vest.</span>")
		C.name = "quiet [C.name]"
		C.upgrade_prefix = "quiet"
		qdel(src)
		return
	else
		to_chat(user, "<span class = 'notice'>You don't need to reinforce [C] any further.")
		return
//Голова
/obj/item/armorkit/helmet/inteq
	name = "Quiet kid helmet kit"
	desc = "Набор гибких армированных пластин которые будут совершенно незаметно сидеть под твоей кепкой, с которой ты так не захотел расставаться даже на миссии, хиккан."
	icon_state = "inteq_helm_kit"
	icon = 'modular_bluemoon/Ren/Icons/Obj/misc.dmi'
	w_class = WEIGHT_CLASS_SMALL

/obj/item/armorkit/helmet/afterattack(obj/item/target, mob/user, proximity_flag, click_parameters)
	var/used = FALSE
	if(!isclothing(target))
		return
	if(!(isobj(target) && target.slot_flags & ITEM_SLOT_HEAD))
		return
	if(target.type in typesof(/obj/item/clothing/head/helmet))
		to_chat(user, span_danger("You cannot modify [target], as it already has armor or is a part of special equipment."))
		return
	var/obj/item/clothing/C = target
	var/obj/item/clothing/head/helmet/sec/blueshield/A = new /obj/item/clothing/head/helmet/sec/blueshield(src)
	C.set_armor(A.armor)
	C.body_parts_covered = A.body_parts_covered
	C.cold_protection = A.cold_protection
	C.heat_protection = A.heat_protection
	C.resistance_flags = A.resistance_flags
	C.clothing_flags = A.clothing_flags
	C.min_cold_protection_temperature = A.min_cold_protection_temperature
	C.max_heat_protection_temperature = A.max_heat_protection_temperature
	used = TRUE
	if(used)
		user.visible_message("<span class = 'notice'>[user] reinforces [C] with [src].</span>", \
		"<span class = 'notice'>You reinforce [C] with [src], making it as protective as a helmet.</span>")
		C.name = "quiet [C.name]"
		C.upgrade_prefix = "quiet"
		qdel(src)
		return
	else
		to_chat(user, "<span class = 'notice'>You don't need to reinforce [C] any further.")
		return
// ретекстур бейсбол набора
/obj/item/clothing/under/inteq/baseball
	name = "Striped white shirt"
	desc = "Just a striped shirt whith turtleneck under it."
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Ren/Icons/Mob/clothing_digi.dmi'
	icon_state = "ghostbaseball"
	item_state = "ghostbaseball"
	armor = list(MELEE = 15, BULLET = 20, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 50, ACID = 40, WOUND = 10)

/obj/item/clothing/head/soft/inteq/baseball
	name = "Baseball cap"
	desc = "Soft, cozy, grim."
	icon_state = "baseballsoft"
	soft_type = "baseball"
	item_state = "baseballsoft"
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	flags_inv = HIDEEYES|HIDEFACE
	armor = list(MELEE = 35, BULLET = 35, LASER = 25, ENERGY = 10, BOMB = 25, BIO = 0, RAD = 0, FIRE = 20, ACID = 90, WOUND = 5)
	strip_delay = 90 //You dont take a Major Leage cap
	dog_fashion = null

///Исследовательский риг
/obj/item/tank/jetpack/suit/fast
	full_speed = TRUE

/obj/item/clothing/head/helmet/space/hardsuit/security/explorer
	name = "Expedition hardsuit helmet"
	desc = "Армированный шлем, в котором не страшно сунуть свой нос даже в самые опасные заброшенные станции и обломки кораблей."
	icon_state = "hardsuit0-explorer"
	item_state = "hardsuit0-explorer"
	hardsuit_type = "explorer"
	armor = list(MELEE = 20, BULLET = 40, LASER = 20, ENERGY = 50, BOMB = 30, BIO = 100, RAD = 50, FIRE = 75, ACID = 75, WOUND = 50)
	mob_overlay_icon = 'modular_sand/icons/mob/clothing/head.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'
	anthro_mob_worn_overlay = 'modular_sand/icons/mob/clothing/head_muzzled.dmi'
	brightness_on = 12 // Эу ты куда прёш на дальнем свете

/obj/item/clothing/suit/space/hardsuit/security/explorer
	name = "Expedition hardsuit"
	desc = "Армированный костюм, в котором не страшно ступить даже в самые опасные заброшенные станции и обломки кораблей."
	icon_state = "hardsuit-explorer"
	item_state = "hardsuit-explorer"
	armor = list(MELEE = 20, BULLET = 40, LASER = 20, ENERGY = 50, BOMB = 30, BIO = 100, RAD = 50, FIRE = 75, ACID = 75, WOUND = 50) // сниженная защита от лазеров и пуль - ценой повешенной мобильности и защиты от бомб
	mob_overlay_icon = 'modular_sand/icons/mob/clothing/suit.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/security/explorer
	anthro_mob_worn_overlay = 'modular_sand/icons/mob/clothing/suit_digi.dmi' // у нас забрали джет, терпим.
	unique_reskin = list()
	tail_state = "bombsuit_sci"

//-----------------------------------------------------------[Одежда FTU]---------------------------------------------------------------------------------------
///Боевой риг
/obj/item/clothing/head/helmet/space/hardsuit/security/ftu
	name = "Fleet security hardsuit helmet"
	desc = "Носи с гордостью."
	icon_state = "hardsuit0-ftu_combat"
	item_state = "hardsuit0-ftu_combat"
	hardsuit_type = "ftu_combat"
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Ren/Icons/Mob/clothing_digi.dmi'

/obj/item/clothing/suit/space/hardsuit/security/ftu
	name = "Fleet security hardsuit"
	desc = "Боевой костюм, рассчитанный на длительные сражения в космосе с превосходящими силами противника. После многолетних чисток целых секторов от пиратства, теперь заставляет многих нервно сглотнуть от одного своего вида."
	icon_state = "hardsuit-ftu_combat"
	item_state = "hardsuit-ftu_combat"
	tail_state = "syndicate-winter"
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/security/ftu
	anthro_mob_worn_overlay = 'modular_bluemoon/Ren/Icons/Mob/clothing_digi.dmi'
	equip_sound = 'modular_bluemoon/Ren/Sound/equp.ogg'
	slowdown = 0.1
	jetpack = /obj/item/tank/jetpack/suit/fast
	unique_reskin = list()

///Инженерный риг
/obj/item/clothing/head/helmet/space/hardsuit/engine/ftu
	name = "Ship engineering hardsuit helmet"
	desc = "Стандартный шлем инженерного костюма для технического обслуживания судов торгового флота."
	icon_state = "hardsuit0-odst"
	item_state = "hardsuit0-odst"
	hardsuit_type = "odst"
	mob_overlay_icon = 'modular_sand/icons/mob/clothing/head.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'
	anthro_mob_worn_overlay = 'modular_sand/icons/mob/clothing/head_muzzled.dmi'
	heat_protection = HEAD
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	armor = list(MELEE = 30, BULLET = 5, LASER = 10, ENERGY = 5, BOMB = 60, BIO = 100, RAD = 100, FIRE = 100, ACID = 100, WOUND = 15)

/obj/item/clothing/suit/space/hardsuit/engine/ftu
	name = "Ship engineering hardsuit"
	desc = "Стандартный инженерный костюм для технического обслуживания судов торгового флота."
	icon_state = "hardsuit-odst"
	item_state = "hardsuit-odst"
	tail_state = "juggernaut"
	mob_overlay_icon = 'modular_sand/icons/mob/clothing/suit.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/engine/ftu
	anthro_mob_worn_overlay = 'modular_sand/icons/mob/clothing/suit_digi.dmi'
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	armor = list(MELEE = 30, BULLET = 5, LASER = 10, ENERGY = 5, BOMB = 60, BIO = 100, RAD = 100, FIRE = 100, ACID = 100, WOUND = 15)
	unique_reskin = list()
	jetpack = /obj/item/tank/jetpack/suit

/obj/item/clothing/suit/armor/vest/ftu
	name = "FTU Security Armor"
	desc = "Стандартный бронежилет охраны свободных торговцев. Обеспечивает оптимальную защиту жизненно важных органов в тесных коридорах кораблей и трюмов."
	icon_state = "epic_bp_armor"
	item_state = "epic_bp_armor"
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'
	body_parts_covered = CHEST|GROIN|ARMS
	cold_protection = CHEST|GROIN|ARMS
	heat_protection = CHEST|GROIN|ARMS
	armor = list(MELEE = 30, BULLET = 60, LASER = 25, ENERGY = 20, BOMB = 25, BIO = 0, RAD = 0, FIRE = 50, ACID = 50, WOUND = 30)

/obj/item/clothing/suit/armor/vest/ftu/ComponentInitialize()
	. = ..()
	var/datum/component/storage/concrete/storage = AddComponent(/datum/component/storage/concrete)
	storage.max_items = 5

/obj/item/clothing/under/inteq/tactical_gorka/ftu
	name = "Cargo gorka"
	armor = list()

/obj/item/clothing/head/helmet/skull/ftu
	name = "FTU Combat Skull"
	desc = "Бронированная маска из полимеров стилизованная под череп. Вселяет страх в каждого пирата."
	anthro_mob_worn_overlay = 'modular_bluemoon/Ren/Icons/Mob/clothing_digi.dmi'
	flash_protect = 2
	armor = list(MELEE = 30, BULLET = 60, LASER = 25, ENERGY = 20, BOMB = 25, BIO = 0, RAD = 0, FIRE = 50, ACID = 50, WOUND = 30)
	flags_inv = HIDEEYES | HIDEFACE | HIDEMASK

/obj/item/card/id/away/ftu
	name = "Ship access card"
	desc = "Личная карта каждого члена экипажа карабля"
	icon_state = "retro"
	access = list(ACCESS_AWAY_GENERIC4)

//----------------------------------------------------------------------[косметика]----------------------------------------------------------------------------
/obj/item/clothing/neck/cloak/miner
	name = "Miner Cape"
	desc = "Мой бур пронзит небеса!"
	icon_state = "kaminacape"
	item_state = "kaminacape"
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/suit.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'

/obj/item/clothing/neck/cloak/ftu
	name = "FTU Cape"
	desc = "Плащ флота объединённых свободных торговцев. Теперь и ты стал частью чего-то великого."
	icon_state = "ftu_cape"
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'

/obj/item/clothing/neck/cloak/inteq
	name = "Inteq cloak"
	desc = "Плащ членов группировки InteQ."
	icon_state = "inteq_cape"
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'

/obj/item/clothing/neck/cloak/diver
	name = "Diver cloak"
	desc = "Солидный плащ, который отлично подошёл бы настоящему герою"
	icon_state = "mittle_brown"
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'
	unique_reskin = list(
		"Red" = list("icon_state" = "mittle_red"),
		"Black" = list("icon_state" = "mittle_black"),
		"Blank" = list("icon_state" = "mittle_blank"),
	)
///Баллистическая маска
/obj/item/clothing/mask/gas/inteq
	name = "Ballistic mask"
	desc = "Чёрная маска из кевлара. Защитит тебя от осколков и опознания."
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Ren/Icons/Mob/clothing_digi.dmi'
	icon_state = "ballistic"
	item_state = "ballistic"
	flags_inv = HIDEFACE|HIDEFACIALHAIR
	mutantrace_variation = STYLE_MUZZLE
	unique_reskin = list("With balaclava" = list(RESKIN_ICON_STATE = "ballistic_balaclava"))

/obj/item/clothing/mask/gas/inteq/reskin_obj(mob/user)
	if(current_skin == "With balaclava")
		mutantrace_variation = STYLE_MUZZLE
		flags_inv = HIDEMASK|HIDEEYES|HIDEFACE|HIDEHAIR|HIDESNOUT
///Личный жетон
/obj/item/clothing/accessory/indiv_number
	desc = "Небольшой металлический жетон. На нём виднеется цифровой код, плата микрочипа с данными о владельце и немного свободного места для гравировки."
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	lefthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_l.dmi'
	righthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_r.dmi'
	icon_state = "tag"
	item_state = "tag"
	obj_flags = UNIQUE_RENAME

/obj/item/clothing/accessory/indiv_number/Initialize(mapload)
	. = ..()
	var/class = pickweight(list("<span class='danger'>ALEPH</span>" = 1, "<span class='hierophant_warning'>WAW</span>" = 2, "<span class='engradio'>HE</span>" = 6, "<span class='binarysay'>TETH</span>" = 12, "<span class='nicegreen'>ZAIN</span>" = 25))
	name = "[rand(999)]-[class]/[rand(99)]"
	if(class == "<span class='danger'>ALEPH</span>")
		custom_price = 10000
	if(class == "<span class='hierophant_warning'>WAW</span>")
		custom_price = 5000
	if(class == "<span class='engradio'>HE</span>")
		custom_price = 3000
	if(class == "<span class='binarysay'>TETH</span>")
		custom_price = 1000
	if(class == "<span class='nicegreen'>ZAIN</span>")
		custom_price = 500
//донат вещи


///Чулки чулки чулки блять
/obj/item/clothing/underwear/socks/thigh/stockings/socks_garterbelt
	name = "Socks garterbelt"
	icon_state = "socks_garterbelt"
	icon = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings_digi.dmi'

/obj/item/clothing/underwear/socks/thigh/stockings/stocking_2strip
	name = "Two strip stocking"
	icon_state = "stocking_2strip"
	icon = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings_digi.dmi'

/obj/item/clothing/underwear/socks/thigh/stockings/stocking_checkered
	name = "Checkered stocking"
	icon_state = "stocking_checkered"
	icon = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings_digi.dmi'

/obj/item/clothing/underwear/socks/thigh/stockings/stocking_1strip
	name = "One strip stocking"
	icon_state = "stocking_1strip"
	icon = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings_digi.dmi'

/obj/item/clothing/underwear/socks/thigh/stockings/stocking_line
	name = "Line stocking"
	icon_state = "stocking_line"
	icon = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings_digi.dmi'

/obj/item/clothing/underwear/socks/socks_2strip
	name = "Two strip socks"
	icon_state = "socks_2strip"
	icon = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings_digi.dmi'

/obj/item/clothing/underwear/socks/socks_checkered
	name = "Checkered socks"
	icon_state = "socks_checkered"
	icon = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings_digi.dmi'

/obj/item/clothing/underwear/socks/socks_2strip
	name = "Two strip socks"
	icon_state = "socks_2strip"
	icon = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings_digi.dmi'

/obj/item/clothing/underwear/socks/socks_line
	name = "Line socks"
	icon_state = "socks_line"
	icon = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Ren/Icons/Mob/random_cloth/more_stockings_digi.dmi'
