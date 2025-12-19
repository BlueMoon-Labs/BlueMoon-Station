// BLUEMOON EDITED - реворк разрешений на оружие

GLOBAL_VAR_INIT(weapon_permits_issued, 0)
/obj/item/clothing/accessory/permit
	name = "Weapons permit"
	desc = "Небольшая карточка с блюспейс-электроникой для упрощения контроля за трафиком оружия на станции."
	icon = 'modular_splurt/icons/obj/permits.dmi'
	icon_state = "permit"
	mob_overlay_icon = 'icons/mob/clothing/accessories.dmi'
	w_class = WEIGHT_CLASS_TINY
	resistance_flags = FIRE_PROOF
	max_stack = 2
	max_stack_path = /obj/item/clothing/accessory/permit
	var/permit_id
	var/owner_name = ""
	var/owner_assignment = ""
	var/issuer_name = ""
	var/issuer_assignment = ""
	var/permitted_weapons = ""
	var/notes = ""
	var/issue_time = ""
	var/locked = FALSE
	// Выдан ли роли при спавне
	var/special = FALSE
	var/access_to_issue = ACCESS_ARMORY

/obj/item/clothing/accessory/permit/Initialize(mapload)
	. = ..()
	GLOB.weapon_permits_issued++
	permit_id = GLOB.weapon_permits_issued
	name += " #[permit_id]"

/obj/item/clothing/accessory/permit/ui_status(mob/user)
	if(!can_see_permit(user))
		return UI_CLOSE
	else
		return UI_INTERACTIVE

/obj/item/clothing/accessory/permit/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "WeaponPermit")
		ui.open()

/obj/item/clothing/accessory/permit/ui_data(mob/user)
	var/list/data = list()
	if(!can_see_permit(user))
		return data
	data["owner_name"] = owner_name
	data["owner_assignment"] = owner_assignment
	data["issuer_name"] = issuer_name
	data["issuer_assignment"] = issuer_assignment
	data["permitted_weapons"] = permitted_weapons
	data["issue_time"] = issue_time
	data["notes"] = notes
	data["locked"] = locked
	data["centcomm_issued"] = special
	data["can_interact"] = can_redact_permit(user)
	data["has_access"] = has_access_to_issuing(user)
	return data

/obj/item/clothing/accessory/permit/ui_act(action, params)
	if(..())
		return
	if(!can_redact_permit(usr))
		return
	switch(action)
		if("submit_license")
			if(!has_access_to_issuing(usr))
				to_chat(usr, span_warning("У вас нет прав на это действие!"))
				return
			if(!owner_name || !owner_assignment || !permitted_weapons)
				to_chat(usr, span_warning("Сначала заполните все необходимые поля!"))
				return
			var/mob/living/carbon/human/user = usr
			var/obj/item/card/id/redactor_card = user.get_id_card()
			if(!redactor_card || !redactor_card.registered_name || !redactor_card.assignment)
				balloon_alert(user, "Наденьте ID-карту в специальный слот, чтобы активировать данное разрешение.")
				return
			issuer_name = redactor_card.registered_name
			issuer_assignment = redactor_card.assignment
			issue_time = STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)
			playsound(src, 'sound/machines/chime.ogg', 20)
			locked = TRUE
		if("reopen_license")
			if(!has_access_to_issuing(usr))
				to_chat(usr, span_warning("У вас нет прав на это действие!"))
				return
			issuer_name = ""
			issuer_assignment = ""
			issue_time = ""
			playsound(src, 'sound/machines/beep.ogg', 20)
			locked = FALSE
		if("submit_owner")
			if(!ishuman(usr))
				return
			var/mob/living/carbon/human/user = usr
			var/obj/item/card/id/owner_card = user.get_id_card()
			if(!owner_card || !owner_card.registered_name || !owner_card.assignment)
				balloon_alert(user, "Наденьте ID-карту в специальный слот, чтобы привязать данное разрешение.")
				return
			owner_name = owner_card.registered_name
			owner_assignment = owner_card.assignment
			playsound(src, 'sound/machines/beep.ogg', 20)
			locked = FALSE
		if("input_weapons")
			var/new_weapons_list = tgui_input_text(usr, "Введите новый перечень разрешённого оружия и снаряжения (максимум 150 символов).", "Новый перечень оружия", permitted_weapons, 150, TRUE, TRUE)
			if(new_weapons_list)
				permitted_weapons = new_weapons_list
		if("input_notes")
			var/new_notes = tgui_input_text(usr, "Введите новый набор заметок для службы безопасности по поводу данного разрешения (максимум 300 символов).", "Новые заметки", notes, 300, TRUE, TRUE)
			if(new_notes)
				notes = new_notes

/obj/item/clothing/accessory/permit/attack_self(mob/user)
    if(can_redact_permit(user))
        ui_interact(user)

/obj/item/clothing/accessory/permit/examine(mob/user)
	. = ..()
	if(special)
		. += span_notice("Данная карточка была выдана Центральным Командованием перед началом смены. Её нельзя изменить.")
	else if(locked)
		. += span_notice("Данная карточка заблокирована. Используйте её в руке и разблокируйте, если у вас есть доступ выше смотрителя.")
	else
		. += span_notice("Данная карточка разблокирована. Используйте её в руке, чтобы изменить параметры.")
	if(can_see_permit(user))
		. += span_boldnotice(" <center><a href='?src=[REF(src)];check=1'>\[Проверить\]</a></center>")

/obj/item/clothing/accessory/permit/proc/can_see_permit(mob/user)
	if(!istype(user))
		return FALSE
	if(isobserver(user))
		return TRUE
	if(!isliving(user))
		return FALSE
	var/mob/living/our_mob = user
	if(our_mob.stat == UNCONSCIOUS || our_mob.stat == DEAD)
		return FALSE
	if(get_dist(user, loc) > 5)
		return FALSE
	return TRUE

/obj/item/clothing/accessory/permit/proc/can_redact_permit(mob/user)
	if(!can_see_permit(user))
		return FALSE
	if(!istype(user, /mob/living/carbon/human))
		return FALSE
	var/mob/living/carbon/human/redactor = user
	if(src in redactor.held_items)
		return TRUE
	return FALSE

/obj/item/clothing/accessory/permit/proc/has_access_to_issuing(mob/user)
	if(ishuman(user))
		var/mob/living/carbon/human/redactor = user
		var/obj/item/card/id/redactor_card = redactor.get_id_card()
		if(!redactor_card)
			return FALSE
		if(access_to_issue in redactor_card.GetAccess())
			return TRUE
	return FALSE

/obj/item/clothing/accessory/permit/get_examine_string(mob/user, thats)
	. = ..()
	if(!current_uniform)
		return
	var/obj/item/clothing/under/unif = current_uniform
	if(istype(unif) && ishuman(unif.loc))
		var/mob/living/carbon/human/wearer = unif.loc
		if(wearer.get_visible_name() != owner_name)
			. += span_warning("(!)")
	. += span_notice(" <a href='?src=[REF(src)];check=1'>\[Проверить\]</a>")

/obj/item/clothing/accessory/permit/Topic(href, href_list)
	..()
	if (href_list["check"])
		var/mob/user = usr
		if(!user || !istype(user))
			return
		if(!can_see_permit(user))
			to_chat(user, span_warning("Вы не можете осмотреть эту карточку. Возможно, стоит подойти поближе?"))
			return
		if(istype(user, /mob/living))
			user.visible_message("[user] осматривает [src] [current_uniform ? ", прикреплённый к [current_uniform]" : ""].", "Вы осматриваете [src]")
		ui_interact(user)
	return

/obj/item/clothing/accessory/permit/proc/register()
	return


// База для заранее созданных пермитов
/obj/item/clothing/accessory/permit/special
	name = "Coder's special shitcoding permit"
	desc = "Если вы это видите - напишите багрепорт"
	issuer_name = "ЦЕНТРАЛЬНОЕ КОМАНДОВАНИЕ"
	issuer_assignment = "N/A"
	issue_time = "Перед началом текущей смены"
	special = TRUE
	var/first_inited = FALSE // Карточку нужно использовать в руке, чтобы она записалась. Как со старыми пермитами

/obj/item/clothing/accessory/permit/special/examine(mob/user)
	. = ..()
	if(!first_inited)
		. += span_boldnotice("Разрешение не инициализировано. Используйте его в руке, имея ID-карту на поясе, чтобы присвоить себе.")

/obj/item/clothing/accessory/permit/special/attack_self(mob/user)
	if(!can_redact_permit(user))
		return
	if(!first_inited)
		bind_to_user(user, FALSE)
	else
		. = ..()

/obj/item/clothing/accessory/permit/special/proc/bind_to_user(mob/user, silent)
	if(!ishuman(user))
		if(!silent && ismob(user))
			balloon_alert(user, "Пользователь не распознан. Обратитесь к станционному генетику для проверки своего генома.")
		return
	var/mob/living/carbon/human/man_behind_the_permit = user
	var/obj/item/card/id/man_card = man_behind_the_permit.get_id_card()
	if(!man_card || !man_card.registered_name || !man_card.assignment)
		if(!silent)
			balloon_alert(man_behind_the_permit, "Наденьте ID-карту в специальный слот, чтобы привязать данное разрешение.")
		return
	if(man_card.registered_name == man_behind_the_permit.dna?.real_name)
		owner_name = man_card.registered_name
		owner_assignment = man_card.assignment
		first_inited = TRUE
		if(!silent)
			playsound(src, 'sound/machines/chime.ogg', 20)
			balloon_alert(man_behind_the_permit, "Привязка успешна.")
		return
	else
		balloon_alert(user, "Привязка не удалась. Проверьте, чтобы ваша ID-карта была на нужном месте и имена совпадали.")
		return

// Заранее созданные пермиты, выдающиеся разным ролям при спавне.
// Было бы классно, если бы кто-то правил список оружия и примечания после правок КЗ и НРП, да?
/obj/item/clothing/accessory/permit/special/captain
	name = "Captain's weapons permit"
	icon_state = "compermit"
	desc = "Кто-то сомневается в праве КАПИТАНА носить оружие?! Скормить его космо-акулам!"
	permitted_weapons = "Любое неконтрабандное вооружение"
	notes = "Капитан имеет право использовать любое неконтрабандное вооружение, исключительно в рамках самозащиты, начиная с Синего уровня тревоги. В случаях, если применение силы не вызвано критической ситуацией, подставляющей жизнь капитана под угрозу, данный пункт не снимает ответственности за ущерб причинённый в рамках самообороны."

/obj/item/clothing/accessory/permit/special/head_of_personnel
	name = "Head's of Personnel weapons permit"
	desc = "Как тебе ТАКАЯ бюрократия, ублюдок?!"
	permitted_weapons = "Стандартное вооружение командного состава"
	notes = "Глава персонала имеет право пользоваться стандартной экипировкой и вооружением, а также применять её в рамках самозащиты."

/obj/item/clothing/accessory/permit/special/bridge_officer
	name = "Bridge Officer's weapons permit"
	desc = "Боевая горничная капитана на посту!"
	permitted_weapons = "Стандартное вооружение офицера мостика, в том числе гражданский энергопистолет"
	notes = "Офицер мостика имеет право использовать своё стандартное вооружение исключительно для самозащиты."

/obj/item/clothing/accessory/permit/special/blueshield
	name = "Blueshield's weapons permit"
	desc = "ОЧЕНЬ БОЕВАЯ горничная капитана на страже!"
	permitted_weapons = "Любое неконтрабандное вооружение"
	notes = "Офицер \"Синий Щит\" имеет право использовать любое неконтрабандное вооружение для защиты своих целей и себя. Использование летальной силы разрешено лишь в случае угрозы жизни или цветового кода угрозы выше синего."

/obj/item/clothing/accessory/permit/special/head_of_sec
	name = "Head's of Security weapons permit"
	desc = "Ты не можешь вооружить станцию, не вооружив сначала себя."
	permitted_weapons = "Любое неконтрабандное вооружение"
	notes = "Будучи сотрудником службы безопасности, её глава имеет право носить любое неконтрабандное вооружение и применять его в соответствии с Боевой Политикой."

/obj/item/clothing/accessory/permit/special/chief_engineer
	name = "Chief Engineer's weapons permit"
	desc = "На самом деле, главному инженеру не нужно оружие. Удар ломом по голове является самым эффективным методом самозащиты с 1998 года."
	permitted_weapons = "Стандартное вооружение командного состава"
	notes = "Главный инженер имеет право пользоваться стандартной экипировкой и вооружением, а также применять её в рамках самозащиты."

/obj/item/clothing/accessory/permit/special/research_director
	name = "Research Director's weapons permit"
	desc = "Порой лучше несколько раз пустить в ход телескопическую дубинку, чем потом плакать над взорванным отделом."
	permitted_weapons = "Стандартное вооружение командного состава и реактивная броня"
	notes = "Директор исследований имеет право пользоваться стандартной экипировкой и вооружением, а также применять её в рамках самозащиты. Помимо этого, он имеет право носить реактивную броню, а также, начиная с синего кода - активировать её."

/obj/item/clothing/accessory/permit/special/chief_medic
	name = "Chief Medical Officer's weapons permit"
	desc = "Кусок пластика, пара микросхем и щепотка блюспейса - и вот, от клятвы Гиппократа уже ничего не осталось. Это многое говорит об обществе."
	permitted_weapons = "Стандартное вооружение командного состава и шприцемёт"
	notes = "Главный врач имеет право пользоваться стандартной экипировкой и вооружением, включая шприцемёт, а также применять её в рамках самозащиты."

/obj/item/clothing/accessory/permit/special/quartermaster
	name = "Quartermaster's weapons permit"
	desc = "Да, завхоз, тебе не нужен этот ящик дробовиков, тебе хватит и телескопички. Договорились?"
	permitted_weapons = "Стандартное вооружение командного состава"
	notes = "Квартирмейстер имеет право пользоваться стандартной экипировкой и вооружением, а также применять её в рамках самозащиты."

/obj/item/clothing/accessory/permit/special/representative
	name = "Pact Representative's weapons permit"
	desc = "Нет гаранта соблюдения процедур лучше, чем энергокарабин у виска."
	permitted_weapons = "Стандартное вооружение командного состава, а также тактическую дубинку, роскошную трость и энергетический карабин"
	notes = "Представитель ПАКТа имеет право пользоваться своей стандартной экипировкой и вооружением, в том числе энергокарабином, роскошной тростью и тактической дубинкой, а также применять всё это в рамках самозащиты."

/obj/item/clothing/accessory/permit/special/lawyer
	name = "Lawyer's weapons permit"
	desc = "Я протестую! А это - моё вещественное доказательство!"
	permitted_weapons = "Стандартное вооружение агента внутренних дел"
	notes = "Агент внутренних дел имеет право пользоваться стандартной экипировкой и вооружением, а также применять её в рамках самозащиты."

/obj/item/clothing/accessory/permit/special/chaplain
	name = "Chaplain's weapons permit"
	desc = "Caedite eos. Novit enim Dominus qui sunt eius."
	permitted_weapons = "Нулевой жезл и его вариации"
	notes = "Священнику разрешно носить и использовать его священное оружие, сиречь вариации нулевого жезла, если это не противоречит космическому закону."

/obj/item/clothing/accessory/permit/special/bartender
	name = "Bartender's weapons permit"
	desc = "Я точно не вынесу этот чертовски большой, длинный и привлекательный... дробовик за пределы отдела. Честно-честно."
	permitted_weapons = "Барменский дробовик с нелетальными патронами"
	notes = "Бармену разрешено хранить и использовать свой дробовик с нелетальными патронами для успокоения буйных посетителей на территории бара в рамках своих норм рабочих процедур и космического закона."

/obj/item/clothing/accessory/permit/special/bouncer
	name = "Bouncer's weapons permit"
	desc = "Ну надо же вышибале чем-то вышибать, да?"
	permitted_weapons = "Вооружение вторичной категории и специализированного типа, в том числе пистолеты и парализаторы, наручники и их варианты, болы, а также перцовый баллончик; Указанное выше вооружение допускается к ношению и использованию с любым ударно-спусковым механизмом (бойком)."
	notes = "Сотрудник охраны сервиса имеет право использовать своё вооружение только в случае защиты своей жизни или жизни других. Применение вооружения также допустимо против неадекватных членов персонала, что игнорируют просьбы и предупреждения от сотрудников сервисного отдела."

/obj/item/clothing/accessory/permit/special/security
	name = "Security weapons permit"
	desc = "У охраны есть оружие? Вот это новость!"
	permitted_weapons = "Любое неконтрабандное вооружение, если иное не указано боевой политикой и НРП"
	notes = "Сотрудники службы безопасности имеют право использовать своё табельное вооружение для охраны станции в соответствии со своими процедурами и боевой политикой."

/obj/item/clothing/accessory/permit/special/explorer
	name = "Explorer's weapons permit"
	desc = "Нет, храбрый исследователь, этот двойной лазерный меч в сделку НЕ входит!"
	permitted_weapons = "Любое неконтрабандное вооружение"
	notes = "Исследователи имеют право владеть любым неконтрабандным вооружением, однако использование на территории станции против персонала запрещено."

/obj/item/clothing/accessory/permit/special/disk_keeper
	name = "Syndicate nuclear disk keeper permit"
	desc = "Спи спокойно диск..."
	permitted_weapons = "Любая экипировкой синдиката, включая контрабандную. Любое оружие и боеприпасы, включая контрабандные."
	notes = "Специалист по защите ядерного диска вправе обеспечивать его первичную безопасность любыми необходимыми средствами и не подлежит ответственности за действия, непосредственно связанные с выполнением этих обязанностей (Например, проникновение в ЗОД).\n\
	Специалист имеет право носить и защищать ядерный диск, однако если диск находится у уполномоченного лица (например, у Капитана), он не вправе изымать его силой, но может запросить добровольную передачу.\n\
	Хранитель диска несёт полную ответственность за нарушение КЗ, за исключением случаев, предусмотренных выше."
