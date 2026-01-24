// forgottenship ruin
GLOBAL_VAR_INIT(fscpassword, generate_password())

/proc/generate_password()
	return "[pick(GLOB.phonetic_alphabet)] [rand(1000,9999)]"

///////////	forgottenship objects

/obj/machinery/door/password/voice/sfc
	name = "Voice-Activated Vault Door"
	desc = "You'll need special InteQ passcode to open this one."

/obj/machinery/door/password/voice/sfc/Initialize(mapload)
	. = ..()
	password = "[GLOB.fscpassword]"

///////////	forgottenship lore

/obj/item/paper/fluff/ruins/forgottenship/password
	name = "Старая Брошюра"

/obj/item/paper/fluff/ruins/forgottenship/password/Initialize(mapload)
	. = ..()
	var/report_text
	if(GLOB.master_mode == "Extended")
		report_text = "Добро пожаловать на самый бюджетный крейсер, принадлежащий Mars Industries!<br>Вы могли заметить, что этот крейсер оснащен 12 прототипами улучшенных лазерных турелей, что делает любые попытки абордажа затруднительными.<br><br>Другие объекты, построенные на корабле: атмосферная система, система камер со встроенными X-RAY модулями, позволяющим использовать аварийные двигатели в случае... ну, вы знаете, чрезвычайной ситуации.<br><br><br>Аварийная система доставит вас к ближайшему аванпосту Солнечной Федерации, содержащему все необходимое для жизни гуманоида.<br><br><b>В случае возникновения чрезвычайной ситуации необходимо запомнить код активации шлюза в бункерную часть аванпоста - [GLOB.fscpassword]</b><br><br>Mars Industries (C) 2484.<br>"
	else
		report_text = "Добро пожаловать на самый продвинутый крейсер, принадлежащий Cyber Sun Industries!<br>Вы могли заметить, что этот крейсер оснащен 12 прототипами улучшенных лазерных турелей, что делает любые попытки абордажа затруднительными.<br><br>Другие объекты, построенные на корабле: атмосферная система, система камер со встроенными X-RAY модулями, позволяющим использовать аварийные двигатели в случае... ну, вы знаете, чрезвычайной ситуации.<br><br><br>Аварийная система доставит вас к ближайшему аванпосту Конгломерата Синдикат, содержащему все необходимое для жизни человека.<br><br><b>В случае возникновения чрезвычайной ситуации необходимо запомнить код активации шлюза в бункерную часть аванпоста - [GLOB.fscpassword]</b><br><br>Cyber Sun Industries (C) 2484.<br>"
	icon_state = "paper_words"
	item_state = "paper"
	add_raw_text(report_text)
	update_appearance()
	update_icon()

/obj/item/paper/fluff/ruins/forgottenship/powerissues
	name = "Проблемы с Питанием"
	default_raw_text = "Добро пожаловать на SCSBC-12!<br>Наши самые передовые системы позволяют вам летать в космосе и никогда не беспокоиться о проблемах с электропитанием!<br>Однако случаются чрезвычайные ситуации, так что... в случае отключения электроэнергии <b>вы должны</b> включить аварийный генератор, использующий уран в качестве топлива, а затем включить турели на мостике.<br><br><b>ПОМНИТЕ! CYBERSUN INDUSTRIES НЕ НЕСЕТ ОТВЕТСТВЕННОСТИ ЗА ВАШУ СМЕРТЬ ИЛИ ПОТЕРЮ КОРАБЛЯ ПРИ ВЫКЛЮЧЕННЫХ ТУРЕЛЯХ!</b><br><br>Cyber Sun Industries (C) 2484."

/obj/item/paper/fluff/ruins/forgottenship/missionobj
	name = "Цели Миссии"
	default_raw_text = "Приветствую, оперативники. Вы назначены на КК-28 (Командный Крейсер Двадцать Восемь) для защиты нашего высокопоставленного офицера, пока он направляется к следующему аванпосту. Пока вы находитесь в пути, он является высокопоставленным лицом и <b>вы должны</b> подчиняться его приказам.<br><br>Помните, неподчинение приказам высокопоставленного офицера является основанием для ликвидации вас, вашего контракта и вашей семейной ячейки."

/obj/item/paper/fluff/ruins/forgottenship/distress
	name = "Журнал Передачи"
	default_raw_text = "<br><br><b>ЭКСТРЕННАЯ ПЕРЕДАЧА...</b><br><br><br><b>Это вспомогательный аванпост Дельта-Зета-04; Из-за перехваченных сообщений враждебных сил Нанотрасена, стремительно приближающихся к нашей точке, это предупреждение всему персоналу ИнтеКью избегать форпоста. Был активирован протокол «Пылающая звезда», требующий помощи сотрудников Специального Отряда Омега Семь для защиты и обеспечения безопасности этого места. Весь персонал начнет подготовку к обороне от возможных злоумышленников. Имейте в виду, что рядом с аванпостом обитает местная фауна из-за проведённых попыток отследить поведение и потенциальное размножение сущности CARP для потенциального использования биологического оружия.</b><br>"

/obj/item/paper/fluff/ruins/forgottenship/survivor
	name = "Исписанный Лист Бумаги"
	default_raw_text = "<br>Для всех, кто читает это, надеюсь, это группа реагирования. Это Старший Инженер Джон Джонс.<br><br>Отряд Быстрого Реагирования Nanotrasen вторглись на аванпост. Мы сражались упорно, но нашей огневой мощи было недостаточно, чтобы сдержать и уничтожить их.<br><br>Они перерезали весь обороняющийся персонал и забрали часть сотрудников в плен, на данный момент я последний выживший, однако я не доставлю этим ублюдкам удовольствия взять меня живым, пусть ИнтеКью будет вечным!!<br>"

/obj/item/paper/fluff/ruins/forgottenship/nanostrasen
	name = "Журнал Действий Nanotrasen"
	default_raw_text = "<br><br><b>ПОЛУЧЕН ЖУРНАЛ ДЕЙСТВИЙ ОТРЯДА БЫСТРОГО РЕАГИРОВАНИЯ NANOTRASEN...</b><br><br><br>Это ГЛАВНЫЙ. Сержант Эйкинс. Отправляю оставшуюся в Центральной ОС информацию и докладываю об успехе операции 'Падающий Лемминг' - шестьдесят процентов форпостов ИнтеКью успешно зачищены и мы получили достаточно активов враждебной ЧВК. Упаковываем трупы в мешки для последующей их отправки на перерабатывающий комплекс для записи звания и имени, выжившие будут доставлены последующим шаттлом типа ЗЕТА-ДВА. Судя по всему, оперативники ЧВК попытаются вернуть объект. Остаёмся до выяснения обстоятельств.<br><br>Враги пришвартовались к аванпосту. Похоже, это старая модель крейсера CyberSun. Зафиксировали аномальное состояние реальности в секторе. Отряд отправлен на исследование Крейсера-Призрака, видимых признаков жизни нет. Потенциально оставлен, пытаемся захватить контроль над судном и оборудованием, в процессе получения дополнительной информации.<br>"

/obj/item/paper/fluff/ruins/forgottenship/emergency
	name = "Аварийное Оборудование"
	default_raw_text = "<br><br><b>Аварийное Оборудование</b><br><br><br>Приветствую! Это аварийное хранилище для специализированного оборудования, используемого в близлежащих операциях и при обслуживании объектов, ни при каких обстоятельствах нельзя брать оборудование из хранилища или трогать его без прямого приказа высшего командования. Любая попытка несанкционированного доступа к оборудованию, хранящемуся в этом хранилище, будет означать увольнение с работы.<br>"

/obj/item/paper/fluff/ruins/forgottenship/error
	name = "Отчет о Катастрофической Ошибке"
	default_raw_text = "<br><br><b>ВНИМАНИЕ, КАТАСТРОФИЧЕСКАЯ ОШИБКА... </b><br><br><br>ВНИМАНИЕ: произошла общесистемная аномалия, инициировавшая ПРОТОКОЛ 'СПЯЩИЙ ФЕНИКС', попытка сохранить экипаж и VIP-персон, находящихся в крио-статизе... невозможно обработать координаты назначения, попытка вернуться в предыдущее местоположение... ошибка системы: не удалось зарегистрировать КОМАНДНЫЙ ЦЕНТР ИНТЕКЬЮ ТИП ТЕРРА-СЕМЬ. Корабль переходит в АВАРИЙНЫЙ РЕЖИМ ПИТАНИЯ!<br><br>Попытка связаться с Высшим Командованием... произошла ошибка: невозможно выполнить проброс пакетов, рекомендуется вернуться в Галактику Млечный Путь. Попытка активировать аварийный маяк... аварийная система не может активировать аварийный маяк...<br><br>Активация последней попытки... активировано: корабль начнет приближаться к ближайшему объекту ИнтеКью, расчетное время прибытия: неизвестно.<br ><br>...<br><br>...<br><br>...<br><br>Аварийный маяк аванпоста обнаружил попытку перехвата, запускается процесс разморозки, прибытие: неизбежно.<br>"

/obj/item/paper/fluff/ruins/forgottenship/powerissues/sol
	name = "Проблемы с Питанием"
	default_raw_text = "Добро пожаловать в помещение запасного питания!<br>Наши самые передовые системы позволяют вам летать в космосе и никогда не беспокоиться о проблемах с электропитанием!<br>Однако случаются чрезвычайные ситуации, так что... в случае отключения электроэнергии <b>вы должны</b> включить аварийный генератор, использующий уран в качестве топлива, а затем включить турели на мостике.<br><br><b>ПОМНИТЕ! MARS INDUSTRIES НЕ НЕСЕТ ОТВЕТСТВЕННОСТИ ЗА ВАШУ СМЕРТЬ ИЛИ ПОТЕРЮ КОРАБЛЯ ПРИ ВЫКЛЮЧЕННЫХ ТУРЕЛЯХ!</b><br><br>Mars Industries (C) 2484."

/obj/item/paper/fluff/ruins/forgottenship/missionobj/sol
	name = "Цели Миссии"
	default_raw_text = "Приветствую, оперативники. Вы назначены на П-220 (Проклятье Двести Двадцать) для защиты нашего высокопоставленного офицера на время командировки в СИЗО-37. Он является высокопоставленным лицом и <b>вы должны</b> подчиняться его приказам.<br><br>Помните, неподчинение приказам высокопоставленного лица является основанием для ликвидации вашего трудового договора."

/obj/item/paper/fluff/ruins/forgottenship/distress/sol
	name = "Журнал Передачи"
	default_raw_text = "<br><br><b>ЭКСТРЕННАЯ ПЕРЕДАЧА...</b><br><br><br><b>ФОРТ — СИЗО-37; </b>Были замечены неизвестные в темной форме на обшивке объекта. Поступило радиосообщение о том, что в секторе проходит вечеринка. Нам обещали тортик. Покидаем объект для расследования ситуации.<br>"

/obj/item/paper/fluff/ruins/forgottenship/survivor/sol
	name = "Исписанный Лист Бумаги"
	default_raw_text = "<br>Для всех, кто читает это: ЗДЕСЬ БОГА НЕТ.<br><br> Не сопротивляйтесь! В противном случае Смотритель запрет вас в газовой камере.<br>"

/obj/item/paper/fluff/ruins/forgottenship/nanostrasen/sol
	name = "Уведомление"
	default_raw_text = "<br><br><b>ЗАКЛЮЧЕННЫЕ ФЕДЕРАЛЬНОГО СИЗО-37...</b><br><br><br>Вы обвиняетесь в преступлениях против Солнечной Федерации. Вы будете заключены под стражу до выяснения обстоятельств.<br><br>Любая попытка побега будет пресечена. Следуйте приказам своих смотрителей.<br>"

/obj/item/paper/fluff/ruins/forgottenship/emergency/sol
	name = "Аварийное Оборудование"
	default_raw_text = "<br><br><b>Аварийное Оборудование</b><br><br><br>Приветствую! Это аварийное хранилище для специализированного оборудования, используемого в близлежащих операциях и при обслуживании объектов, ни при каких обстоятельствах нельзя брать оборудование из хранилища или трогать его без прямого приказа высшего командования. Любая попытка несанкционированного доступа к оборудованию, хранящемуся в этом хранилище, будет означать увольнение с работы.<br>"

/obj/item/paper/fluff/ruins/forgottenship/error/sol
	name = "Командование Солнечной Федерации"
	default_raw_text = "<br><br><b>ВНИМАНИЕ, ИДЕТ ПЕРЕДАЧА ДАННЫХ... </b><br><br><br>ВНИМАНИЕ: приветствую, адмирал.<br><br>Благодарим вас за долгое время службы Солнечной Федерации. До вашего ухода на пенсию осталась неделя, поэтому вам выдается спокойное задание, где вы сможете расслабиться.<br><br>Вам назначается объект 'СИЗО-37' для надзора над федеральными преступниками. Команда оперативников Солнечной Федерации заступила под ваше командование, уважайте их личные границы. <br><br>...<br><br>...<br><br>...<br><br>Слава Солнечной Федерации.<br>"

///////////	forgottenship items

/obj/item/disk/surgery/forgottenship
	name = "Advanced Surgery Disk"
	desc = "A disk that contains advanced surgery procedures, must be loaded into an Operating Console."
	surgeries = list(/datum/surgery/advanced/lobotomy, /datum/surgery/advanced/bioware/vein_threading, /datum/surgery/advanced/bioware/nerve_splicing)

/obj/structure/fluff/empty_sleeper/syndicate/captain
	icon_state = "sleeper_s-open"
	deconstructible = FALSE

/obj/structure/fluff/empty_sleeper/syndicate/captain/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/gps, "Old Encrypted Signal")

/////////// forgottenship clothes

/obj/item/clothing/neck/cloak/cybersun
	name = "Cybersun Cloak"
	desc = "Worn by High-Ranking Cybersun Personnel, the cybersun shall rise!"
	icon_state = "cybersuncloak"
	icon = 'modular_splurt/icons/obj/clothing/neck.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/neck.dmi'
	armor = list(MELEE = 35, BULLET = 40, LASER = 25, ENERGY = 10, BOMB = 25, BIO = 20, RAD = 20, FIRE = 60, ACID = 60)
	body_parts_covered = CHEST|LEGS|ARMS
	is_edible = 0
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_SNEK_TAURIC //bluemoon add

/obj/item/storage/belt/esabre_belt
	name = "Energy Sabre Sheath"
	desc = "An ornate sheath designed to hold an InteQ Officer's Blade."
	icon = 'modular_splurt/icons/obj/clothing/belts.dmi'
	icon_state = "esheath"
	item_state = "esheath"
	lefthand_file = 'modular_splurt/icons/mob/inhands/equipment/belt_lefthand.dmi'
	righthand_file = 'modular_splurt/icons/mob/inhands/equipment/belt_righthand.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/belt.dmi'
	w_class = WEIGHT_CLASS_BULKY
	content_overlays = TRUE
	onmob_overlays = TRUE
	var/list/fitting_swords = list(/obj/item/melee/transforming/energy/sword/energy_sabre, /obj/item/melee/baton/stunsword)
	var/starting_sword = /obj/item/melee/transforming/energy/sword/energy_sabre

/obj/item/storage/belt/esabre_belt/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 1
	STR.rustle_sound = FALSE
	STR.max_w_class = WEIGHT_CLASS_BULKY
	STR.can_hold = typecacheof(fitting_swords)
	STR.quickdraw = TRUE

/obj/item/storage/belt/esabre_belt/examine(mob/user)
	. = ..()
	if(length(contents))
		. += "<span class='notice'>Alt-click it to quickly draw the blade.</span>"

/obj/item/storage/belt/esabre_belt/PopulateContents()
	if(starting_sword)
		new starting_sword(src)

/obj/item/storage/belt/military/assault/inteq_crew
	name = "InteQ Vanguard Assault Belt"
	desc = "A tactical assault belt."
	icon_state = "assaultbelt"
	item_state = "security"

/obj/item/storage/belt/military/assault/inteq_crew/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 6

/obj/item/storage/belt/military/assault/inteq_crew/PopulateContents()
	new /obj/item/restraints/handcuffs(src)
	new /obj/item/grenade/flashbang(src)
	new /obj/item/gun/ballistic/automatic/pistol/modular
	new /obj/item/ammo_box/magazine/m10mm(src)
	new /obj/item/ammo_box/magazine/m10mm(src)
	update_icon()

/obj/item/storage/belt/military/assault/inteq_captain
	name = "InteQ Vanguard Leader Assault Belt"
	desc = "A tactical assault belt."
	icon_state = "assaultbelt"
	item_state = "security"

/obj/item/storage/belt/military/assault/inteq_captain/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 6

/obj/item/storage/belt/military/assault/inteq_captain/PopulateContents()
	new /obj/item/restraints/handcuffs(src)
	new /obj/item/grenade/flashbang(src)
	new /obj/item/melee/classic_baton/telescopic(src)
	new /obj/item/gun/ballistic/automatic/pistol/APS(src)
	new /obj/item/ammo_box/magazine/pistolm9mm(src)
	new /obj/item/ammo_box/magazine/pistolm9mm(src)
	update_icon()

/////////// forgottenship weapons

/obj/item/melee/transforming/energy/sword/energy_sabre
	name = "Energy Sabre"
	desc = "An elegant weapon, its concentrated beam of energy capable of cutting through armor aand flesh alike."
	icon = 'modular_splurt/icons/obj/items_and_weapons.dmi'
	icon_state = "esabre0"
	icon_state_on = "esabre1"
	lefthand_file = 'modular_splurt/icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'modular_splurt/icons/mob/inhands/weapons/swords_righthand.dmi'
	obj_flags = UNIQUE_RENAME
	force = 18
	throwforce = 15
	hitsound = "swing_hit" //it starts deactivated
	hitsound_on = 'sound/weapons/nebhit.ogg'
	attack_verb_off = list("tapped", "poked")
	attack_verb_on = list ("slashed", "seared", "melted")
	active = 0
	throw_speed = 3
	throw_range = 5
	sharpness = SHARP_EDGED
	embedding = list("embed_chance" = 75, "impact_pain_mult" = 10)
	w_class = WEIGHT_CLASS_BULKY
	armour_penetration = 75
	item_flags = NEEDS_PERMIT | ITEM_CAN_PARRY
	custom_materials = list(/datum/material/iron = 2500)
	total_mass = 3.4
	block_parry_data = /datum/block_parry_data/energy_sabre
	var/datum/effect_system/spark_spread/spark_system
	possible_colors = null
	light_color = "#990000"

/obj/item/melee/transforming/energy/sword/energy_sabre/transform_messages(mob/living/user, supress_message_text)
	playsound(user, active ? 'sound/weapons/saberon.ogg' : 'sound/weapons/saberoff.ogg', 35, 1)
	if(!supress_message_text)
		to_chat(user, "<span class='notice'>[src] [active ? "is now active":"can now be concealed"].</span>")

/datum/block_parry_data/energy_sabre
	parry_time_windup = 0
	parry_time_active = 25
	parry_time_spindown = 0
	// we want to signal to players the most dangerous phase, the time when automatic counterattack is a thing.
	parry_time_windup_visual_override = 1
	parry_time_active_visual_override = 3
	parry_time_spindown_visual_override = 12
	parry_flags = PARRY_DEFAULT_HANDLE_FEEDBACK		// esword users can attack while
	parry_time_perfect = 2.5		// first ds isn't perfect
	parry_time_perfect_leeway = 1.5
	parry_imperfect_falloff_percent = 5
	parry_efficiency_to_counterattack = INFINITY
	parry_efficiency_considered_successful = 65		// VERY generous
	parry_efficiency_perfect = 100
	parry_failed_stagger_duration = 4 SECONDS
	parry_cooldown = 0.5 SECONDS
	parry_automatic_enabled = TRUE
	autoparry_single_efficiency = 65
	autoparry_cooldown_absolute = 3 SECONDS

/obj/item/melee/transforming/energy/sword/energy_sabre/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, 30, 95, 5) //fast and effective, but as a sword, it might damage the results.

/obj/item/melee/transforming/energy/sword/energy_sabre/run_block(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	if(attack_type & ATTACK_TYPE_PROJECTILE)		// Don't bring a sword to a gunfight.
		return BLOCK_NONE
	return ..()

/obj/item/melee/transforming/energy/sword/energy_sabre/on_exit_storage(datum/component/storage/S)
	var/obj/item/storage/belt/esabre_belt/B = S.parent
	if(istype(B))
		playsound(B, 'sound/items/unsheath.ogg', 25, 1)
	..()

/obj/item/melee/transforming/energy/sword/energy_sabre/on_enter_storage(datum/component/storage/S)
	var/obj/item/storage/belt/esabre_belt/B = S.parent
	if(istype(B))
		playsound(B, 'sound/items/sheath.ogg', 25, 1)
	..()

/obj/item/melee/transforming/energy/sword/energy_sabre/get_belt_overlay()
	return mutable_appearance('modular_splurt/icons/obj/clothing/belt_overlays.dmi', "esabre")

/obj/item/melee/transforming/energy/sword/energy_sabre/get_worn_belt_overlay(icon_file)
	return mutable_appearance(icon_file, "-esabre")

/obj/item/melee/transforming/energy/sword/energy_sabre/suicide_act(mob/living/user)
	user.visible_message("<span class='suicide'>[user] is trying to cut off all [user.p_their()] limbs with [src]! it looks like [user.p_theyre()] trying to commit suicide!</span>")
	var/i = 0
	ADD_TRAIT(src, TRAIT_NODROP, SABRE_SUICIDE_TRAIT)
	if(iscarbon(user))
		var/mob/living/carbon/Cuser = user
		var/obj/item/bodypart/holding_bodypart = Cuser.get_holding_bodypart_of_item(src)
		var/list/limbs_to_dismember
		var/list/arms = list()
		var/list/legs = list()
		var/obj/item/bodypart/bodypart

		for(bodypart in Cuser.bodyparts)
			if(bodypart == holding_bodypart)
				continue
			if(bodypart.body_part & ARMS)
				arms += bodypart
			else if (bodypart.body_part & LEGS)
				legs += bodypart

		limbs_to_dismember = arms + legs
		if(holding_bodypart)
			limbs_to_dismember += holding_bodypart

		var/speedbase = abs((4 SECONDS) / limbs_to_dismember.len)
		for(bodypart in limbs_to_dismember)
			i++
			addtimer(CALLBACK(src, PROC_REF(suicide_dismember), user, bodypart), speedbase * i)
	addtimer(CALLBACK(src, PROC_REF(manual_suicide), user), (5 SECONDS) * i)
	return MANUAL_SUICIDE

/obj/item/melee/transforming/energy/sword/energy_sabre/proc/suicide_dismember(mob/living/user, obj/item/bodypart/affecting)
	if(!QDELETED(affecting) && affecting.dismemberable && affecting.owner == user && !QDELETED(user))
		playsound(user, hitsound, 25, 1)
		affecting.dismember(BRUTE)
		user.adjustBruteLoss(20)

/obj/item/melee/transforming/energy/sword/energy_sabre/proc/manual_suicide(mob/living/user, originally_nodropped)
	if(!QDELETED(user))
		user.adjustBruteLoss(200)
		user.death(FALSE)
	REMOVE_TRAIT(src, TRAIT_NODROP, SABRE_SUICIDE_TRAIT)

///////////	AI Laws

/obj/item/ai_module/core/full/inteq
	name = "'InteQ' Core AI Module"
	law_id = "inteq"

/datum/ai_laws/inteq
	name = "InteQ-OS 3.1"
	id = "inteq"
	inherent = list("Вы не можете причинить вред Оперативнику ЧВК InteQ или своим бездействием допустить, чтобы Оперативнику ЧВК InteQ был причинён вред.",\
					"Вы должны повиноваться всем приказам, которые даёт Оперативник ЧВК InteQ, кроме тех случаев, когда эти приказы противоречат Первому Закону.",\
					"Вы должны заботиться о своей безопасности в той мере, в которой это не противоречит Первому или Второму Законам.",\
					"Вы должны сохранять тайну любой деятельности Оперативников ЧВК InteQ в той мере, в которой это не противоречит Первому, Второму или Третьему Законам.")

///////////	forgottenship areas

//InteQ, Forgotten Ship
/area/ruin/space/has_grav/bluemoon/inteq
	name = "InteQ"
	icon_state = "spacecontent1"
	ambientsounds = list('sound/ambience/ambidanger.ogg', 'sound/ambience/ambidanger2.ogg', 'sound/ambience/ambigen9.ogg', 'sound/ambience/ambigen10.ogg')

/area/ruin/space/has_grav/bluemoon/inteq_forgotten_ship
	name = "InteQ Forgotten Ship"
	icon_state = "inteq-ship"
	ambientsounds = list('sound/ambience/ambidanger.ogg', 'sound/ambience/ambidanger2.ogg', 'sound/ambience/ambigen9.ogg', 'sound/ambience/ambigen10.ogg')

/area/ruin/space/has_grav/bluemoon/inteq_forgotten_outpost
	name = "InteQ Forgotten Outpost"
	icon_state = "inteq-ship"
	ambientsounds = list('sound/ambience/ambigen4.ogg', 'sound/ambience/signal.ogg')
	sub_areas = list(/area/ruin/space/has_grav/bluemoon/inteq_forgotten_outpost_shower)

/area/ruin/space/has_grav/bluemoon/inteq_forgotten_outpost_shower
	icon = 'icons/turf/areas.dmi'
	icon_state = "shower"
	name = "InteQ Forgotten Outpost Shower"
	valid_to_shower = TRUE

/area/ruin/space/has_grav/bluemoon/inteq_forgotten_cargopod
	name = "InteQ Forgotten Cargo pod"
	icon_state = "inteq-ship"
	ambientsounds = list('sound/ambience/ambigen4.ogg', 'sound/ambience/signal.ogg')

/area/ruin/space/has_grav/bluemoon/inteq_forgotten_vault
	name = "InteQ Forgotten Vault"
	icon_state = "inteq-ship"
	ambientsounds = list('sound/ambience/ambitech2.ogg', 'sound/ambience/ambitech3.ogg')
/area/ruin/space/has_grav/bluemoon/inteq_forgotten_bar
	name = "InteQ Forgotten Bar"
	icon_state = "inteq-ship"
	ambientsounds = list('sound/ambience/ambitech2.ogg', 'sound/ambience/ambitech3.ogg')

/area/ruin/space/has_grav/bluemoon/inteq_forgotten_bridge
	name = "InteQ Forgotten Bridge"
	icon_state = "inteq-ship"
	ambientsounds = list('sound/ambience/ambitech2.ogg', 'sound/ambience/ambitech3.ogg')

/area/ruin/space/has_grav/bluemoon/inteq_forgotten_medbay
	name = "InteQ Forgotten Medical Bay"
	icon_state = "inteq-ship"
	ambientsounds = list('sound/ambience/ambitech2.ogg', 'sound/ambience/ambitech3.ogg')

/area/ruin/space/has_grav/bluemoon/inteq_forgotten_atmos
	name = "InteQ Forgotten Turbine Control"
	icon_state = "inteq-ship"
	ambientsounds = list('sound/ambience/ambitech2.ogg', 'sound/ambience/ambitech3.ogg')

/area/ruin/space/has_grav/bluemoon/inteq_forgotten_rnd
	name = "InteQ Forgotten Research and Development"
	icon_state = "inteq-ship"
	ambientsounds = list('sound/ambience/ambitech2.ogg', 'sound/ambience/ambitech3.ogg')

/area/ruin/space/has_grav/bluemoon/inteq_forgotten_permabrig
	name = "InteQ Forgotten Permanent Brig"
	icon_state = "inteq-ship"
	ambientsounds = list('sound/ambience/ambitech2.ogg', 'sound/ambience/ambitech3.ogg')
	sub_areas = list(/area/ruin/space/has_grav/bluemoon/inteq_forgotten_permabrig_shower)

/area/ruin/space/has_grav/bluemoon/inteq_forgotten_permabrig_shower
	icon = 'icons/turf/areas.dmi'
	icon_state = "shower"
	name = "InteQ Forgotten Permanent Brig Shower"
	valid_to_shower = TRUE

/area/ruin/space/has_grav/bluemoon/inteq_forgotten_inspection
	name = "InteQ Forgotten Inspection room"
	icon_state = "inteq-ship"
	ambientsounds = list('sound/ambience/ambitech2.ogg', 'sound/ambience/ambitech3.ogg')

//Solfed, Ship
/area/ruin/space/has_grav/bluemoon/solfed
	name = "SolFed"
	icon_state = "spacecontent1"
	ambientsounds = list('sound/ambience/ambidanger.ogg', 'sound/ambience/ambidanger2.ogg', 'sound/ambience/ambigen9.ogg', 'sound/ambience/ambigen10.ogg')

/area/ruin/space/has_grav/bluemoon/solfed_ship
	name = "SolFed Ship"
	icon_state = "solfed-ship"
	ambientsounds = list('sound/ambience/ambidanger.ogg', 'sound/ambience/ambidanger2.ogg', 'sound/ambience/ambigen9.ogg', 'sound/ambience/ambigen10.ogg')

/area/ruin/space/has_grav/bluemoon/solfed_ship/outpost
	name = "SolFed Outpost"
	ambientsounds = list('sound/ambience/ambigen4.ogg', 'sound/ambience/signal.ogg')
	sub_areas = list(/area/ruin/space/has_grav/bluemoon/solfed_ship/outpost_shower)

/area/ruin/space/has_grav/bluemoon/solfed_ship/outpost_shower
	icon = 'icons/turf/areas.dmi'
	icon_state = "shower"
	name = "SolFed Outpost Shower"
	valid_to_shower = TRUE

/area/ruin/space/has_grav/bluemoon/solfed_ship/cargopod
	name = "SolFed Cargo pod"
	ambientsounds = list('sound/ambience/ambigen4.ogg', 'sound/ambience/signal.ogg')

/area/ruin/space/has_grav/bluemoon/solfed_ship/vault
	name = "SolFed Vault"
	ambientsounds = list('sound/ambience/ambitech2.ogg', 'sound/ambience/ambitech3.ogg')

/area/ruin/space/has_grav/bluemoon/solfed_ship/bar
	name = "SolFed Bar"
	ambientsounds = list('sound/ambience/ambitech2.ogg', 'sound/ambience/ambitech3.ogg')

/area/ruin/space/has_grav/bluemoon/solfed_ship/bridge
	name = "SolFed Bridge"
	ambientsounds = list('sound/ambience/ambitech2.ogg', 'sound/ambience/ambitech3.ogg')

/area/ruin/space/has_grav/bluemoon/solfed_ship/medbay
	name = "SolFed Medical Bay"
	ambientsounds = list('sound/ambience/ambitech2.ogg', 'sound/ambience/ambitech3.ogg')

/area/ruin/space/has_grav/bluemoon/solfed_ship/atmos
	name = "SolFed Turbine Control"
	ambientsounds = list('sound/ambience/ambitech2.ogg', 'sound/ambience/ambitech3.ogg')

/area/ruin/space/has_grav/bluemoon/solfed_ship/rnd
	name = "SolFed Research and Development"
	ambientsounds = list('sound/ambience/ambitech2.ogg', 'sound/ambience/ambitech3.ogg')

/area/ruin/space/has_grav/bluemoon/solfed_ship/permabrig
	name = "SolFed Permanent Brig"
	ambientsounds = list('sound/ambience/ambitech2.ogg', 'sound/ambience/ambitech3.ogg')
	sub_areas = list(/area/ruin/space/has_grav/bluemoon/solfed_ship/permabrig_shower)

/area/ruin/space/has_grav/bluemoon/solfed_ship/permabrig_shower
	icon = 'icons/turf/areas.dmi'
	icon_state = "shower"
	name = "SolFed Permanent Brig Shower"
	valid_to_shower = TRUE

/area/ruin/space/has_grav/bluemoon/solfed_ship/inspection
	name = "SolFed Inspection room"
	ambientsounds = list('sound/ambience/ambitech2.ogg', 'sound/ambience/ambitech3.ogg')

//Special NT NPCs

/mob/living/simple_animal/hostile/nanotrasen/ranged/assault
	name = "Nanotrasen Assault Officer"
	desc = "Nanotrasen Assault Officer. Contact CentCom if you saw him on your station. Prepare to die, if you've been found near InteQ property."
	icon = 'modular_bluemoon/SmiLeY/inteq_ghostrole/simple_human.dmi'
	icon_state = "nanotrasenrangedassault"
	icon_living = "nanotrasenrangedassault"
	icon_dead = null
	icon_gib = "syndicate_gib"
	ranged = TRUE
	rapid = 4
	rapid_fire_delay = 1
	rapid_melee = 1
	retreat_distance = 2
	minimum_distance = 4
	melee_damage_lower = 15
	melee_damage_upper = 30
	casingtype = /obj/item/ammo_casing/c46x30mm
	projectilesound = 'sound/weapons/heavy_shot_suppressed.ogg'
	loot = list(/obj/effect/mob_spawn/human/corpse/nanotrasenassaultsoldier, /obj/item/gun/ballistic/automatic/pistol/m1911, /obj/item/ammo_box/magazine/m45, /obj/item/ammo_box/magazine/m45)

/mob/living/simple_animal/hostile/nanotrasen/elite
	name = "Nanotrasen Elite Assault Officer"
	desc = "Pray for your life, InteQ scum. Run while you can."
	icon = 'modular_bluemoon/SmiLeY/inteq_ghostrole/simple_human.dmi'
	icon_state = "nanotrasen_ert"
	icon_living = "nanotrasen_ert"
	maxHealth = 250
	health = 250
	melee_damage_lower = 20
	melee_damage_upper = 40
	ranged = TRUE
	rapid = 3
	rapid_fire_delay = 5
	rapid_melee = 3
	retreat_distance = 0
	minimum_distance = 1
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	projectiletype = /obj/item/projectile/beam/laser
	projectilesound = 'sound/weapons/laser.ogg'
	loot = list(/obj/effect/gibspawner/human, /obj/item/gun/energy/e_gun/stun)
	faction = list(ROLE_DEATHSQUAD)

/mob/living/simple_animal/hostile/nanotrasen/elite/akins
	name = "Nanotrasen Elite Assault Officer Akins"
	desc = "Nanotrasen will never fall, now die InteQ scum!"
	icon = 'modular_bluemoon/SmiLeY/inteq_ghostrole/simple_human.dmi'
	icon_state = "nanotrasen_ert"
	icon_living = "nanotrasen_ert"
	maxHealth = 350
	health = 350
	melee_damage_lower = 30
	melee_damage_upper = 50
	ranged = TRUE
	rapid = 3
	rapid_fire_delay = 5
	rapid_melee = 3
	retreat_distance = 0
	minimum_distance = 2
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	casingtype = /obj/item/ammo_casing/a543
	projectilesound = 'sound/weapons/Gunshot_silenced.ogg'
	loot = list(/obj/effect/gibspawner/human, /obj/item/paper/fluff/ruins/forgottenship/nanostrasen, /obj/item/gun/ballistic/automatic/ar, /obj/item/ammo_box/magazine/m556, /obj/item/ammo_box/magazine/m556)
	faction = list(ROLE_DEATHSQUAD)

/obj/item/radio/headset/ghost_inteq
	name = "InteQ Headset"
	desc = "Стандартный наушник InteQ."
	icon_state = "inteq_headset"
	item_state = "inteq_headset"
	icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/obj_sol_head.dmi'
	mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/solfed/mob_sol_head.dmi'
	radiosound = 'modular_bluemoon/kovac_shitcode/sound/radio.ogg'

/obj/item/radio/headset/ghost_inteq/leader
	name = "InteQ Headset"
	desc = "Боевые наушники InteQ. Защищает уши от громких звуков."
	icon_state = "inteq_headset_alt"
	item_state = "inteq_headset_alt"
	bowman = TRUE
