//Magic Nullifier
/obj/item/mod/module/anti_magic
	name = "MOD magic nullifier module"
	desc = "Ряд обсидиановых стержней, установленных в критических точках костюма, \
		вибрирующих на определённой низкой частоте для создания резонанса. \
		Это создаёт малорадиусное, но сильное поле нейтрализации магии вокруг пользователя, \
		при поддержке полной замены обычного охлаждающего агента костюма святой водой. \
		Заклинания будут отскакивать от этого поля, хотя это никак не поможет другим поверить вам во всё это."
	icon_state = "magic_nullifier"
	removable = FALSE
	incompatible_modules = list(/obj/item/mod/module/anti_magic)

/obj/item/mod/module/anti_magic/on_suit_activation()
	ADD_TRAIT(mod.wearer, TRAIT_ANTIMAGIC, MOD_TRAIT)
	ADD_TRAIT(mod.wearer, TRAIT_HOLY, MOD_TRAIT)

/obj/item/mod/module/anti_magic/on_suit_deactivation()
	REMOVE_TRAIT(mod.wearer, TRAIT_ANTIMAGIC, MOD_TRAIT)
	REMOVE_TRAIT(mod.wearer, TRAIT_HOLY, MOD_TRAIT)

/obj/item/mod/module/kinesis //TODO POST-MERGE MAKE NOT SUCK ASS, MAKE BALLER AS FUCK
	name = "MOD kinesis module"
	desc = "Модульное дополнение к предплечью, этот модуль считался утерянным многие годы, \
		nесмотря на то, что костюмы, на которые он раньше устанавливался, всё ещё встречаются. \
		Эта технология позволяет пользователю генерировать точные антигравитационные поля, \
		позволяя ему перемещать объекты — от титанового стержня до промышленного оборудования. \
		Странно, но он, кажется, не работает на живых существах."
	icon_state = "kinesis"
//	module_type = MODULE_ACTIVE
	module_type = MODULE_TOGGLE
//	complexity = 3
	complexity = 0
	active_power_cost = DEFAULT_CHARGE_DRAIN*0.75
//	use_power_cost = DEFAULT_CHARGE_DRAIN*3
	removable = FALSE
	incompatible_modules = list(/obj/item/mod/module/kinesis)
	cooldown_time = 0.5 SECONDS
	var/has_tk = FALSE

/obj/item/mod/module/kinesis/on_activation()
	. = ..()
	if(!.)
		return
	if(mod.wearer.dna.check_mutation(TK))
		has_tk = TRUE
	else
		mod.wearer.dna.add_mutation(TK)

/obj/item/mod/module/kinesis/on_deactivation()
	. = ..()
	if(!.)
		return
	if(has_tk)
		has_tk = FALSE
		return
	mod.wearer.dna.remove_mutation(TK)

/obj/item/mod/module/insignia
	name = "MOD insignia module"
	desc = "Несмотря на существование систем IFF, радиосвязи и современных методов дедуктивного рассуждения с помощью \
		собственных глаз носителя, цветные окраски остаются популярным способом для различных фракций галактики показать, кто \
		они. Эта система использует ряд крошечных движущихся краскораспылителей для нанесения и удаления различных \
		цветовых узоров на костюм."
	icon_state = "insignia"
	removable = FALSE
	incompatible_modules = list(/obj/item/mod/module/insignia)
	overlay_state_inactive = "insignia"

/obj/item/mod/module/insignia/generate_worn_overlay()
	overlay_state_inactive = "[initial(overlay_state_inactive)]-[mod.skin]"
	. = ..()
	for(var/mutable_appearance/appearance as anything in .)
		appearance.color = color

/obj/item/mod/module/insignia/commander
	color = "#4980a5"

/obj/item/mod/module/insignia/security
	color = "#b30d1e"

/obj/item/mod/module/insignia/engineer
	color = "#e9c80e"

/obj/item/mod/module/insignia/medic
	color = "#ebebf5"

/obj/item/mod/module/insignia/janitor
	color = "#7925c7"

/obj/item/mod/module/insignia/clown
	color = "#ff1fc7"

/obj/item/mod/module/insignia/chaplain
	color = "#f0a00c"

/obj/item/mod/module/noslip
	name = "MOD anti slip module"
	desc = "Это модифицированный вариант стандартных магнитных ботинок, использующий пьезоэлектрические кристаллы на подошвах. \
		Две пластины на дне ботинок автоматически выдвигаются и намагничиваются при шаге пользователя; \
		притяжение слишком слабое, чтобы позволить им прикрепиться к корпусу, но достаточно сильное, \
		чтобы защитить от того факта, что вы не прочитали знак мокрого пола. Honk Co. неоднократно выступала \
		против легализации этих модулей."
	icon_state = "noslip"
	complexity = 1
	idle_power_cost = DEFAULT_CHARGE_DRAIN * 0.1
	incompatible_modules = list(/obj/item/mod/module/noslip)

/obj/item/mod/module/noslip/on_suit_activation()
	ADD_TRAIT(mod.wearer, TRAIT_NOSLIPWATER, MOD_TRAIT)

/obj/item/mod/module/noslip/on_suit_deactivation()
	REMOVE_TRAIT(mod.wearer, TRAIT_NOSLIPWATER, MOD_TRAIT)
