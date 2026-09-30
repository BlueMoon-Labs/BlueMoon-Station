//WHITE-STEEL PORT - Тактический кислородный баллон рейнджеров

/obj/item/tank/internals/tactical
	name = "Тактический кислородный баллон"
	desc = "Кислородный баллон военно-космического назначения. Конструкция весьма массивна и может быть закреплена только на скафандрах и тяжелой верхней одежде. Представляет собой систему магнитных креплений и стабилизирующих ремней для фиксации большинства стандартных видов вооружения. В комплект также входит универсальный оружейный кейс для нестандартных образцов."
	icon = 'modular_bluemoon/white/Feline/icons/tank_tactical.dmi'
	icon_state = "tank"
	item_state = "empty"
	distribute_pressure = TANK_DEFAULT_RELEASE_PRESSURE
	force = 15
	dog_fashion = null
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_SUITSTORE
	equip_sound = 'sound/items/equip/toolbelt_equip.ogg'
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals/emergency_oxygen)

//Наполнение баллона воздухом (стандарт)
/obj/item/tank/internals/tactical/populate_gas()
	air_contents.set_moles(GAS_O2, (6*ONE_ATMOSPHERE)*volume/(R_IDEAL_GAS_EQUATION*T20C))

//Параметры кармана
/datum/component/storage/concrete/pockets/tactical
	max_items = 1
	max_w_class = WEIGHT_CLASS_BULKY
	rustle_sound = FALSE
	attack_hand_interact = TRUE

//Загрузка кармана
/obj/item/tank/internals/tactical/Initialize()
	. = ..()
	LoadComponent(/datum/component/storage/concrete/pockets/tactical)
	update_appearance()

//Тип хранимого
/datum/component/storage/concrete/pockets/tactical/Initialize()
	. = ..()
	can_hold = typecacheof(list(/obj/item/gun/ballistic,
					  /obj/item/gun/energy)
					  )

//Быстрое извлечение через ЛКМ
/obj/item/tank/internals/tactical/attack_hand(mob/user)
	if(loc == user)
		if(user.get_item_by_slot(ITEM_SLOT_SUITSTORE) == src)
			if(!user.canUseTopic(src, TRUE, FALSE, FALSE, TRUE))
				return
			if(length(contents))
				var/obj/item/I = contents[1]
				user.visible_message(span_notice("[user] достаёт [I] из [src]."), span_notice("Достаю [I] из [src]."))
				user.put_in_hands(I)
				update_appearance()
			else
				to_chat(user, span_warning("Крепления расстегнуты, [capitalize(src.name)] пуст."))
				..()
		else ..()
	else ..()
	return

//Изменение картинки в зависимости от содержания
/obj/item/tank/internals/tactical/update_icon_state()
	icon_state = initial(icon_state)
	item_state = initial(item_state)
	if(length(contents))
		var/obj/item/I = contents[1]
		item_state = "full"
		if(istype(I, /obj/item/gun))
			icon_state = "box"
		if(istype(I, /obj/item/gun/ballistic/automatic/pistol))
			icon_state = "pistol"
		if(istype(I, /obj/item/gun/ballistic/revolver))
			icon_state = "pistol"
		if(istype(I, /obj/item/gun/ballistic/automatic/wt550))
			icon_state = "wt550"
		if(istype(I, /obj/item/gun/energy/e_gun))
			icon_state = "egun"
		if(istype(I, /obj/item/gun/energy/e_gun/stun))
			icon_state = "egun_taser"
		if(istype(I, /obj/item/gun/energy/pulse))
			icon_state = "pulse"
	return ..()

//WHITE-STEEL PORT - Хранилище с антипаразитами

/obj/item/storage/secure/safe/rangers
	name = "чрезвычайное хранилище"
	desc = "Содержит в себе несколько доз препаратов от паразитов таких как Раккун-2 и Ностромо-7, способных обратить процесс заражения ксеноугрозой."
	icon = 'modular_bluemoon/white/Feline/icons/safe.dmi'
	icon_state = "rangers"

/obj/item/storage/secure/safe/rangers/PopulateContents()
	new /obj/item/reagent_containers/hypospray/medipen/raccoon(src)
	new /obj/item/reagent_containers/hypospray/medipen/nostromo(src)
	new /obj/item/paper/rangers(src)

/obj/item/paper/rangers
	name = "отказ от претензий"
	default_raw_text = "<center>Инструкция по применению</center><BR><BR>Перед использованием препаратов Раккун-2 и Ностромо-7 рекомендуется:<BR>1) Составить завещание<BR>* Решить вопросы опекунства над детьми (при их наличии)<BR>* Решить вопросы наследования<BR>2) Надежно зафиксировать пациента любыми доступными способами, рекомендуется смирительная рубашка и кляп<BR>* Вколоть пациенту обезболивающее<BR>* Вколоть пациенту седативные средства<BR>* Вколоть пациенту противошоковое<BR>3) Произнести молитву о здравии и за упокой души пациента любому богу из одобренного компанией списка. Список одобренных богов:<BR>* Нанотрейзен<BR>* Космический Иисус<BR>* Верховная Кошка<BR>* Великий Ящер<BR>* <font color=#006699><i>Капитан</i></font><BR>Компания Нанотрейзен не несет никакой ответственности за последствия использования препарата<BR>В случае получения в процессе необратимых случайных мутаций каких либо сверхъестественных сил, вы ОБЯЗАНЫ составить рапорт и самолично явиться в лабораторию для продления текущего контракта до пожизненного статуса.<BR><BR> Удачной миссии! Компания Нанотрейзен всегда готова поддержать вас в трудную минуту!"
