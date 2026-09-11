/mob/living/carbon/human
	var/infiltrator_active = FALSE

/obj/item/mod/module/infiltrator
	name = "infiltrator MOD module"
	desc = "Скрывает ваше лицо от трекинга ИИ и чужих глаз, делая полностью неузнаваемым."
	icon_state = "infiltrator"
	module_type = MODULE_TOGGLE
	complexity = 1
	idle_power_cost = 0
	removable = FALSE
	required_modpart_index = MOD_PART_HEAD
	startup_with_suit = TRUE

/obj/item/mod/module/infiltrator/on_install()
	. = ..()
	var/obj/item/clothing/mod_part/head/head = mod.mod_parts[MOD_PART_HEAD]
	head.blockTracking = TRUE

/obj/item/mod/module/infiltrator/on_uninstall()
	. = ..()
	var/obj/item/clothing/mod_part/head/head = mod.mod_parts[MOD_PART_HEAD]
	head.blockTracking = FALSE

/obj/item/mod/module/infiltrator/on_activation()
	. = ..()
	if(!mod.wearer || !.) //если родитель выдал FALSE
		return
	mod.wearer.infiltrator_active = TRUE
	mod.wearer.set_bark("bump")
	mod.wearer.digitalcamo = TRUE
	mod.wearer.digitalinvis = TRUE

/obj/item/mod/module/infiltrator/on_deactivation()
	. = ..()
	mod.wearer.infiltrator_active = FALSE
	mod.wearer.set_bark(mod.wearer.client.prefs.bark_id)
	mod.wearer.digitalinvis = FALSE
	mod.wearer.digitalcamo = FALSE

/mob/living/carbon/human/GetVoice()
	. = ..()
	if(. == src.real_name && src.infiltrator_active == TRUE)
		return "Unknown"

/mob/living/carbon/human/examine(mob/user, silent)
	var/mob/living/carbon/human/H
	if(istype(user, /mob/living/carbon/human))
		H = user
	if(H && infiltrator_active && !H.infiltrator_active) //Если осматривающий это человек, у осматриваемого инфильтраторка активна и осматривающий не имеет активной инфильтраторки
		return . = span_big_warning("Вы не можете разглядеть совершенно ничего на теле этого существа.")
	else
		. = ..()

/mob/living/carbon/human/examine_more(mob/user)
	var/mob/living/carbon/human/H
	if(istype(user, /mob/living/carbon/human))
		H = user
	if(H && infiltrator_active && !H.infiltrator_active)
		return . = span_warning("Это существо одето в странный желтый МОД, но лицо и любые возможные приметы скрыты белым шумом.")
	else
		. = ..()

/obj/item/mod/module/storage_upgrader
	name = "MOD Storage Upgrader"
	desc = "Модуль расширения для хранилища МОДа, работающий за счёт технологии BLUESPACE.\
	Позволяет увеличить размер встроенного рюкзака до уровня БС сумки."
	icon_state = "storage_updater"
	incompatible_modules = list(/obj/item/mod/module/storage_upgrader)
	var/datum/component/storage/storage_module_datum
	var/old_max_volume

/obj/item/mod/module/storage_upgrader/on_install()
	. = ..()
	storage_module_datum = mod.GetComponent(/datum/component/storage)
	if(!storage_module_datum)
		return
	old_max_volume = storage_module_datum.max_volume
	storage_module_datum.max_volume = STORAGE_VOLUME_MOD_UPLINK_UPDATER

/obj/item/mod/module/storage_upgrader/on_uninstall()
	. = ..()
	if(!storage_module_datum || !old_max_volume)
		return
	storage_module_datum.max_volume = old_max_volume

/obj/item/mod/module/power_kick
	name = "MOD PowerKick Module"
	desc = "Модуль, устанавливающийся в ботинки костюма и позволяющий пинать цель \
			с силой, отправляющей ту в полёт."
	icon_state = "power_kick"
	module_type = MODULE_ACTIVE
	cooldown_time = 15 SECONDS
	device = /obj/item/melee/baseball_bat/powerkick

/obj/item/melee/baseball_bat/powerkick
	name = "Powerkick Boots"
	desc = "Отправьте кого-нибудь в полёт!"
	icon = 'icons/obj/clothing/modsuit/mod_modules.dmi'
	lefthand_file = null //не должно отображаться в руках
	righthand_file = null
	icon_state = "power_kick"
	force = 35
	wound_bonus = 12

/obj/item/melee/baseball_bat/powerkick/attack(mob/living/target, mob/living/user)
	. = ..()
	doMove(drop_location()) //чтобы после одного использования уйти на кулдаун.

/obj/item/mod/module/anti_magic/wizard
	name = "Magic Neutralizer"
	desc = "Свиток защищающий носителя от магии, при условии, что тот вставлен в костюм. Имеет печать Федерации магов."
	icon_state = "magic_neutralizer"

/obj/item/mod/module/energy_shield/syndie
	name = "Cybersun Energy Shield module"
	desc = "Одна из совершенных версий модулярных энергощитов, способная выдерживать до 5-ти попаданий. \
	Является разработкой Синдиката в соответствующем стиле, со встроенным микро-ядерным реактором, почти полностью \
	покрывающим затраты щита."
	icon_state = "syndie_energy_shield"
	shield_state = "shield-red"
	used_modificator = MOD_MINIMUM_CELL_CHARGE_SHIELD_ANTAG
	recharge_delay = 17 SECONDS
	max_charges = 5

/obj/item/mod/module/energy_shield/syndie/inteq
	name = "InteQ Energy Shield module"
	desc = "Украденный у Синдиката незавершенный модуль щита, доработанный уже в лабораториях ЧВК. Всё ещё достаточно сильный,\
	однако не способен выдерживать столько же много попаданий, как старшая версия."
	icon_state = "inteq_energy_shield"
	shield_state = "shield-yellow"
	minimum_cell_charge = MOD_ANTAG_SHIELD_CELL_DRAIN_MODIFICATOR
	recharge_delay = 18 SECONDS
	max_charges = 3

/obj/item/mod/module/energy_shield/wizard
	name = "Battlemage Shield"
	desc = "Свиток благославленный лучшими монахами Федерации и защищающий носителя магическим силовым полем."
	icon_state = "battlemage_shield"
	shield_state = "at_shield1"
	recharge_delay = 15 SECONDS //на 10 секунд лучше станционного и на 5 лучше дефолтного от рига.
	need_drain_power = FALSE
	max_charges = 3

/obj/item/mod/module/stealth/adv
	name = "Improved Cloaking module"
	desc = "Улучшенная версия прототипа модуля визуальной маскировки для модулярного костюма, которая \
	, к сожалению, не обрела массового производства. Маскировка этого модуля более стабильная и не сбивается \
	при столкновениях."
	icon_state = "cloak_traitor"
	bumpoff = FALSE
	stealth_alpha = 45


/obj/item/mod/module/jump_jet/ninja
	name = "Spider Clan Jump Module"
	desc = "Идейное продолжение прыжкового модуля, но уже под началом специалистов из клана Паука.\
	Скорость прыжков этого модуля настолько быстра, что сравнима с телепортацией и пользователь способен \
	выбирать несколько целей одновременно, дабы прыгнуть дальше обычного."
	icon_state = "jump_jet_ninja"
	beam_icon = 'icons/obj/clothing/modsuit/mod_modules.dmi'
	beam_state = "net_beam"
	incompatible_modules = list()

/obj/item/mod/module/jump_jet/inteq
	name = "InteQ Jump Jet Module"
	desc = ""
	icon_state = "jump_jet_inteq"
	incompatible_modules = list()
