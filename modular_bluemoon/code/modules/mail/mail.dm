/// Info block for mails examine
#define mail_info_box(str) ("<div class='mail_info_box'>" + str + "</div>")

/**
 *
 * ПОЧТОВЫЕ КОНВЕРТЫ И ОСНОВНАЯ ЛОГИКА
 *
 */

/obj/item/mail
	name = "Postal Envelope"
	gender = NEUTER
	desc = "Сертифицированный ПАКТом современный™ почтовый конверт из сверхпрочной бумаги с небольшим датчиком отпечатков пальцев. Всё ещё сильно дешевле блюспейс-доставки."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "mail_small"
	item_state = "paper"
	var/open_state = "mail_small_tempered"
	item_flags = NOBLUDGEON
	w_class = WEIGHT_CLASS_SMALL
	// drop_sound = 'sound/items/handling/paper_drop.ogg'
	// pickup_sound =  'sound/items/handling/paper_pickup.ogg'
	mouse_drag_pointer = MOUSE_ACTIVE_POINTER

	// Свойства, относящиеся к самому письму

	/// Destination tagging for the mail sorter.
	var/sort_tag = 0
	/// Fingerprint of recipient
	var/recipient_fingerprint = null
	/// Whether mail is opened or not
	var/opened = FALSE
	/// Whether mail is postmarked or not
	var/postmarked = TRUE
	/// Does the letter have a stamp overlay?
	var/stamped = TRUE
	/// List of all stamp overlays on the letter.
	var/list/stamps = list()
	/// Maximum number of stamps on the letter.
	var/stamp_max = 1
	/// Physical offset of stamps on the object. X direction.
	var/stamp_offset_x = 0
	/// Physical offset of stamps on the object. Y direction.
	var/stamp_offset_y = 2
	/// Mail will have the color of the department the recipient is in.
	var/static/list/department_colors

	// Свойства, относящиеся к наполнению

	var/datum/mail_pattern/pattern

	var/obj/item/paper/included_letter

	var/sender_name = "НЕИЗВЕСТЕН"
	var/recipient_name = "???"
	var/recipient_job = "N/A"
	var/arrive_time = ""
	var/open_time = "N/A"

/obj/item/mail/Initialize()
	. = ..()
	RegisterSignal(src, COMSIG_MOVABLE_DISPOSING, PROC_REF(disposal_handling))
	AddElement(/datum/element/item_scaling, 0.5, 1)
	if(isnull(department_colors))
		department_colors = list(
			ACCOUNT_CIV = COLOR_WHITE,
			ACCOUNT_ENG = COLOR_PALE_ORANGE,
			ACCOUNT_SCI = COLOR_PALE_PURPLE_GRAY,
			ACCOUNT_MED = COLOR_PALE_BLUE_GRAY,
			ACCOUNT_SRV = COLOR_PALE_GREEN_GRAY,
			ACCOUNT_CAR = COLOR_BEIGE,
			ACCOUNT_SEC = COLOR_PALE_RED_GRAY,
		)
	// Icons
	// Add some random stamps.
	if(stamped == TRUE)
		var/stamp_count = rand(1, stamp_max)
		for(var/i = 1, i <= stamp_count, i++)
			stamps += list("stamp_[rand(2, 6)]")
	update_icon()
	SSmail.total_mails_count++

/obj/item/mail/Destroy()
	qdel(pattern)
	pattern = null
	stamps = null
	included_letter = null
	for(var/atom/content in contents)
		contents -= content
		qdel(content)
	var/datum/component/storage/concrete/STR = GetComponent(/datum/component/storage/concrete)
	qdel(STR)
	if(!opened)
		SSmail.unregister_mail(src)
	if(istype(loc, /obj/machinery/mailmat))
		var/obj/machinery/mailmat/holder = loc
		holder.mails -= src
	. = ..()

/obj/item/mail/proc/disappear()
	if(opened)
		return
	do_fake_sparks(2, 2, src)
	qdel(src)

/obj/item/mail/proc/manual_destroy(mob/destroyer = null, automatic = FALSE)
	if(!automatic)
		if(QDELETED(src) || !istype(destroyer))
			return
		if(isobserver(destroyer) || !destroyer.canUseTopic(src, BE_CLOSE))
			return
		if(!opened)
			return
	say("Конверт распакован, пользователем [destroyer ? destroyer : "СИСТЕМНЫЙ_АДМИНИСТРАТОР"] запрошена ликвидация оболочки...")
	var/datum/component/storage/concrete/STR = GetComponent(/datum/component/storage/concrete)
	STR.drop_all_on_destroy = TRUE
	sleep(3 SECONDS)
	do_fake_sparks(2, 2, src)
	qdel(STR)
	qdel(src)

/obj/item/mail/update_overlays()
	. = ..()
	var/bonus_stamp_offset = 0
	for(var/stamp in stamps)
		var/image/stamp_image = image(
			icon = icon,
			icon_state = stamp,
			pixel_x = stamp_offset_x,
			pixel_y = stamp_offset_y + bonus_stamp_offset
		)
		stamp_image.appearance_flags |= RESET_COLOR
		bonus_stamp_offset -= 5
		. += stamp_image

	if(postmarked)
		var/image/postmark_image = image(
			icon = icon,
			icon_state = "postmark",
			pixel_x = stamp_offset_x + rand(-3, 1),
			pixel_y = stamp_offset_y + rand(bonus_stamp_offset + 3, 1)
		)
		postmark_image.appearance_flags |= RESET_COLOR
		. += postmark_image

/obj/item/mail/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/storage/concrete)
	var/datum/component/storage/concrete/STR = GetComponent(/datum/component/storage/concrete)
	STR.storage_flags = STORAGE_FLAGS_VOLUME_DEFAULT
	STR.max_volume = DEFAULT_VOLUME_TINY * 4
	STR.max_w_class = WEIGHT_CLASS_TINY
	STR.allow_quick_empty = TRUE
	STR.drop_all_on_deconstruct = FALSE
	STR.max_items = 3
	STR.locked = TRUE

/obj/item/mail/proc/disposal_handling(disposal_source, obj/structure/disposalholder/disposal_holder, obj/machinery/disposal/disposal_machine, hasmob)
	SIGNAL_HANDLER
	if(!opened && !hasmob)
		disposal_holder.destinationTag = sort_tag

/obj/item/mail/examine(mob/user)
	. = ..()
	. += span_notice("<br>Вы видите красную панель с текстом на упаковке. <a href='?src=[REF(src)];check_mail_info=1'>Осмотреть</a>")
	. += span_info("<br>Используйте таггер, чтобы отправить письмо по станционной системе труб.")
	if(pattern && isobserver(user))
		. += span_info("<br>Будучи неупокоенным и очень любознательным духом, вы понимаете, что это <b>[pattern.name]</b>")
	if(opened)
		. += span_info("<br>Письмо уже открыто, и вы видите мигающую кнопку самоуничтожения конверта <a href='?src=[REF(src)];destroy=1'>Нажать</a>")

/obj/item/mail/Topic(href, list/href_list)
	. = ..()
	if(href_list["check_mail_info"])
		mail_info_display(usr)
		return
	if(href_list["destroy"])
		manual_destroy(usr)
		return

/obj/item/mail/proc/mail_info_display(mob/user)
	if(QDELETED(src) || !istype(user))
		return
	if(!isobserver(user) && !user.canUseTopic(src, BE_CLOSE))
		return
	var/mail_info = ""
	mail_info += "<center><b>ПОЧТОВОЕ АГЕНТСТВО ЦЕНТРАЛЬНОГО КОМАНДОВАНИЯ</b></center><hr>"
	mail_info += "<u>ОТПРАВИТЕЛЬ</u> - [sender_name]<br>"
	mail_info += "<u>ПУНКТ НАЗНАЧЕНИЯ</u> - [GLOB.station_name]<br>"
	mail_info += "<u>ПОЛУЧАТЕЛЬ</u> - [recipient_name]<br>"
	mail_info += "<u>ДОЛЖНОСТЬ ПОЛУЧАТЕЛЯ</u> - [recipient_job]<br>"
	mail_info += "<u>ДАТА ПРИБЫТИЯ</u> - [arrive_time]<hr>"
	mail_info += "<u>ВСКРЫТО</u> - [open_time]"
	. += mail_info_box(mail_info)
	to_chat(user, mail_info)

/obj/item/mail/attackby(obj/item/W, mob/user, params)
	// Destination tagging
	if(istype(W, /obj/item/dest_tagger))
		var/obj/item/dest_tagger/destination_tag = W

		if(sort_tag != destination_tag.currTag)
			var/tag = uppertext(GLOB.TAGGERLOCATIONS[destination_tag.currTag])
			to_chat(user, span_notice("*[tag]*"))
			sort_tag = destination_tag.currTag
			playsound(loc, 'sound/machines/twobeep_high.ogg', vol = 100, vary = TRUE)
		return
	. = ..()

/obj/item/mail/attack_self(mob/user)
	if(opened)
		return ..()
	try_open(user)

/// Opening mail if user's fingerprint is identical to recipient's
/obj/item/mail/proc/try_open(mob/user)
	if(!istype(user, /mob/living/carbon/human))
		to_chat(user, span_warning("Вы не понимаете, что делать с этим свёртком..."))
		return
	var/mob/living/carbon/human/opener = user
	opener.visible_message(span_notice("[opener] вдавливает палец в сканер отпечатков на [src]"))

	if(recipient_fingerprint)
		if(!opener.dna.uni_identity)
			to_chat(opener, span_warning("Сканер свёртка не реагирует на ваш палец!"))
			return
		if(md5(opener.dna.uni_identity) != recipient_fingerprint)
			balloon_alert_to_viewers("ОТКАЗАНО В ДОСТУПЕ: отпечатки не совпадают")
			return
		if(pattern && !pattern.special_open_check(opener))
			return
	open(opener)

/obj/item/mail/proc/open(mob/living/carbon/human/opener = null)
	balloon_alert_to_viewers("ДОСТУП РАЗРЕШЕН. Приятного пользования, [opener ? opener : "аноним"]!")
	playsound(src, 'sound/machines/chime.ogg', 20)
	opened = TRUE
	if(open_state)
		icon_state = open_state
	var/datum/component/storage/concrete/STR = GetComponent(/datum/component/storage/concrete)
	STR.locked = FALSE
	open_time = "[GLOB.current_date_string] [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)]"
	SSmail.unregister_mail(src)
	on_mail_open(opener)

/// Proc that called when mail is succesfully opened with special effects
/obj/item/mail/proc/on_mail_open(mob/living/carbon/human/opener)
	if(!istype(opener))
		return
	if(istype(included_letter))
		if(!opener.get_inactive_held_item())
			opener.put_in_inactive_hand(included_letter)
			opener.swap_hand()
		included_letter.attempt_examinate(opener)
	var/datum/component/storage/concrete/STR = GetComponent(/datum/component/storage/concrete)
	STR.user_show_to_mob(opener)
	if(istype(pattern))
		pattern.on_mail_open(opener)
	addtimer(CALLBACK(src, PROC_REF(manual_destroy), null, TRUE), 7 MINUTES)

/// Proc that converts mail envelope into mail package
/obj/item/mail/proc/convert_to_package()
	name = "Postal Package"
	if(recipient_name && recipient_job)
		name += " for [recipient_name] ([recipient_job])"
	desc = "Сертифицированный ПАКТом современный™ почтовый контейнер из сверхпрочной бумаги с небольшим датчиком отпечатков пальцев. Всё ещё сильно дешевле блюспейс-доставки."
	icon_state = "mail_large"
	open_state = "mail_large_tampered"
	w_class = WEIGHT_CLASS_NORMAL
	var/datum/component/storage/concrete/STR = GetComponent(/datum/component/storage/concrete)
	STR.max_volume = DEFAULT_VOLUME_SMALL * 6
	STR.max_w_class = WEIGHT_CLASS_SMALL

/**
 *
 * ПРЕ-СОЗДАННЫЕ ЯЩИКИ С ПОЧТОЙ
 *
 */
/obj/structure/closet/crate/mail
	name = "mail crate"
	desc = "A certified post crate from CentCom."
	icon_state = "mail"
	base_icon_state = "mail"
	storage_capacity = 50
	///if it'll show the nt mark on the crate
	var/postmarked = TRUE
	var/arrive_time = "N/A"
	var/initial_mails_count = 0

/obj/structure/closet/crate/mail/proc/wrap()
	arrive_time = "[GLOB.current_date_string] [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)]"
	for(var/obj/item/mail/envelope_in_container in contents)
		initial_mails_count++
		SSmail.register_mail(envelope_in_container)
		envelope_in_container.arrive_time = "[GLOB.current_date_string] [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)]"
	desc = initial(desc)
	name = initial(name)
	if(resistance_flags & INDESTRUCTIBLE)
		resistance_flags &= ~INDESTRUCTIBLE

/obj/structure/closet/crate/mail/examine(mob/user)
	. = ..()
	. += span_notice("Дата прибытия - [arrive_time]")
	. += span_notice("Количество прибывших в контейнере писем и посылок - [initial_mails_count]")

/obj/structure/closet/crate/mail/update_icon_state()
	. = ..()
	if(opened)
		icon_state = "[base_icon_state]open"
		if(locate(/obj/item/mail) in src)
			icon_state = base_icon_state
	else
		icon_state = "[base_icon_state]sealed"

/obj/structure/closet/crate/mail/update_overlays()
	. = ..()
	if(postmarked)
		. += "mail_nt"

/// Opened mail crate
/obj/structure/closet/crate/mail/preopen
	opened = TRUE
	icon_state = "mailopen"

/**
 *
 * МЕШОК ДЛЯ ПИСЕМ
 *
 */
/obj/item/storage/bag/mail
	name = "mail bag"
	desc = "A bag for letters, envelopes, and other postage."
	icon = 'icons/obj/library.dmi'
	w_class = WEIGHT_CLASS_BULKY
	icon_state = "bookbag"
	item_state = "bookbag"
	resistance_flags = FLAMMABLE

/obj/item/storage/bag/mail/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_NORMAL
	STR.max_combined_w_class = 62
	STR.max_items = 40
	STR.display_numerical_stacking = FALSE
	STR.click_gather = TRUE
	STR.allow_quick_gather = TRUE
	STR.quick_gather_storages = TRUE
	STR.can_hold = typecacheof(list(
		/obj/item/mail,
		/obj/item/small_delivery,
		/obj/item/paper
	))

/**
 *
 * МЕСТО, ГДЕ БУДУТ СПАВНИТЬСЯ ПОЧТОВЫЕ ЯЩИКИ
 *
 */

/area/mail_spawner
	name = "Centcomm Mail Teleporter Chamber"
	icon_state = "yellow"
	requires_power = FALSE
	has_gravity = TRUE
	area_flags = NOTELEPORT | HIDDEN_AREA | UNIQUE_AREA

/obj/structure/marker_beacon/yellow/mail_beacon
	name = "Почтовый маяк"
	desc = "Этот неразрушимый маяк генерирует энергию для своей работы, собирает письма со всей галактики, пакует их в контейнеры и телепортирует их на шаттл карго. Это блюспейс, я не обязан ничего объяснять."
	resistance_flags = INDESTRUCTIBLE

/obj/structure/marker_beacon/yellow/mail_beacon/Destroy()
	message_admins("[ADMIN_VERBOSEJMP(SSmail.main_storage_spawnpoint)] Почтовый маяк был уничтожен!")
	. = ..()

/**
 *
 * РАЗДАТЧИК ПИСЕМ
 *
 */

/obj/item/mailmat_deployer
	name = "Mail Dispenser Assembly"
	desc = "Очень тяжёлая коробка с гидравлическими механизмами. Видимо, её тоже пытались прислать по почте..."
	icon = 'icons/obj/mining.dmi'
	icon_state = "deploycrate"
	w_class = WEIGHT_CLASS_HUGE

/obj/item/mailmat_deployer/examine(mob/user)
	. = ..()
	. += span_boldnotice("Вы можете развернуть структуру, использовав [src] в руке!")

/obj/item/mailmat_deployer/attack_self(mob/user)
	var/turf/placeloc = get_turf(user)
	if(!isturf(placeloc))
		to_chat(user, span_warning("Вы не можете поставить его здесь!"))
		return
	if(placeloc.density || locate(/obj/structure) in placeloc || locate(/obj/machinery) in placeloc)
		to_chat(user, span_warning("Тут уже что-то есть!"))
		return
	to_chat(user, span_notice("Вы начинаете развёртывать [src]..."))
	if(!do_after(user, 7 SECONDS, placeloc))
		return

	// Те же проверки, что и выше. Ситуация за семь секунд могла смениться
	if(!isturf(placeloc) || placeloc.density || locate(/obj/structure) in placeloc || locate(/obj/machinery) in placeloc)
		to_chat(user, span_warning("Вы не можете поставить его здесь!"))
		return

	visible_message(span_boldnotice("[user] развёртвывает [src]!"))
	var/obj/machinery/mailmat/dispenser = new(placeloc)
	dispenser.say("Развёртывание успешно!")
	playsound(dispenser, 'sound/machines/ping.ogg', 50, TRUE)
	qdel(src)
	return

/obj/machinery/mailmat
	name = "Mail Dispenser"
	desc = "<i>Postman Pat, Postman Pat, Postman Pat and his black and white cat, All the birds are singing, And the day is just beginning, Pat feels he's a really happy man, Pat feels he's a really happy man, Pat feels he's a really happy man!</i>"
	icon = 'icons/obj/vending.dmi'
	icon_state = "mail"
	layer = BELOW_OBJ_LAYER
	density = TRUE
	verb_say = "beeps"
	verb_ask = "beeps"
	verb_exclaim = "beeps"
	max_integrity = 400
	integrity_failure = 0.33
	armor = list(MELEE = 20, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 50, ACID = 70)
	light_power = 0.5
	light_range = MINIMUM_USEFUL_LIGHT_RANGE

	var/list/obj/item/mail/mails = list()

/obj/machinery/mailmat/Destroy()
	drop_all_mails()
	. = ..()

/obj/machinery/mailmat/examine(mob/user)
	. = ..()
	. += span_notice("Внутри [src] <b>[mails.len ? mails.len : "нет"]</b> писем и посылок.")
	. += span_notice("Вы можете загрузить письма внутрь вручную или при помощи <i>мешка для писем</i>, которым их можно и выгружать.")
	. += span_notice("Вы можете свернуть этот автомат при помощи <b>гаечного ключа</b>.")
	. += span_notice("Вы можете сбросить все письма и посылки при помощи <b>Alt+Click</b>.")

	if(mails.len && istype(user, /mob/living/carbon/human))
		var/mob/living/carbon/human/checker = user
		var/user_fingerprint = md5(checker.dna.uni_identity)
		var/my_mails_count = 0
		for(var/obj/item/mail/M in mails)
			if(M.recipient_fingerprint == user_fingerprint)
				my_mails_count++
		if(my_mails_count)
			. += span_green("<br><b>Тут есть [my_mails_count] писем и посылок для вас!</b>")
		else
			. += span_warning("<br>Тут нет писем и посылок для вас...")

/obj/machinery/mailmat/attackby(obj/item/I, mob/living/user, params)
	if(user.a_intent == INTENT_HARM)
		return ..()

	if(istype(I, /obj/item/storage/bag/mail))
		var/obj/item/storage/bag/mail/mailbag = I
		var/datum/component/storage/STR = mailbag.GetComponent(/datum/component/storage)
		if(I.contents.len)
			to_chat(user, span_notice("Вы загружаете письма в [src]..."))
			if(!do_after(user, 2 SECONDS, src))
				return
			for(var/obj/item/mail/M in mailbag.contents)
				STR.remove_from_storage(M, src)
				mails += M
			mailbag.do_squish()
			return
		else if(mails.len > 0)
			to_chat(user, span_notice("Вы выгружаете письма из [src]..."))
			if(!do_after(user, 2 SECONDS, src))
				return
			for(var/obj/item/mail/M in mails)
				if(STR.can_be_inserted(M, TRUE, user))
					STR.handle_item_insertion(M, TRUE, user)
					mails -= M
			mailbag.do_squish()
			return
		else
			to_chat(user, span_warning("[mailbag] и [src] пусты!"))
			return

	if(istype(I, /obj/item/mail))
		I.forceMove(src)
		mails += I
		to_chat(user, span_notice("Вы загружаете [I] в [src]!"))

	if(I.tool_behaviour == TOOL_WRENCH)
		if(!user.canUseTopic(src, BE_CLOSE))
			return
		if(machine_stat & BROKEN)
			to_chat(user, span_warning("Механизмы сборки-разборки критически повреждены! Остаётся только доломать..."))
			return
		var/turf/deconstruct_turf = get_turf(src)
		if(!isturf(deconstruct_turf))
			to_chat(user, span_warning("[src] находится на нестабильной поверхности. Разборка невозможна."))
			return
		to_chat(user, span_notice("Вы начинаете складывать [src] при помощи [I]..."))
		if(!I.use_tool(src, user, 7 SECONDS))
			return
		say("Свёртывание успешно!")
		playsound(src, 'sound/machines/buzz-sigh.ogg', 50, TRUE)
		visible_message(span_warning("[user] складывает [src] при помощи [I]!"))
		drop_all_mails()
		new /obj/item/mailmat_deployer(deconstruct_turf)
		qdel(src)
		return
	. = ..()

/obj/machinery/mailmat/attack_hand(mob/user, act_intent, attackchain_flags)
	if(user.a_intent == INTENT_HARM)
		return ..()
	if(!istype(user, /mob/living/carbon/human))
		return
	if(!user.canUseTopic(src, BE_CLOSE))
		return
	if(!mails.len)
		to_chat(user, span_warning("Внутри [src] нет писем и посылок!"))
		return
	var/turf/our_turf = get_turf(user)
	if(!isturf(our_turf))
		to_chat(user, span_warning("Вы находитесь на нестабильном покрытии!"))
		return
	var/mob/living/carbon/human/checker = user
	var/user_fingerprint = md5(checker.dna.uni_identity)
	var/my_mails_count = 0
	for(var/obj/item/mail/M in mails)
		if(M.recipient_fingerprint == user_fingerprint)
			my_mails_count++
			mails -= M
			M.forceMove(our_turf)
	if(my_mails_count)
		checker.visible_message(span_warning("[checker] прикладывает палец к сканеру [src], и выдаёт себе [my_mails_count] конвертов."))
	else
		checker.visible_message(span_warning("[checker] прикладывает палец к сканеру [src], но внутри не оказывается посылок для н[checker.ru_ego()]..."))

/obj/machinery/mailmat/AltClick(mob/user)
	. = ..()
	if(!istype(user, /mob/living/carbon/human))
		return
	if(!user.canUseTopic(src, BE_CLOSE))
		return
	if(!mails.len)
		to_chat(user, span_warning("Внутри [src] нет писем и посылок!"))
		return
	to_chat(user, span_notice("Вы начинаете опустошать [src]..."))
	if(!do_after(user, 3 SECONDS, src))
		return
	visible_message(span_warning("[user] опустошает внутреннее хранилище писем [src]."))
	drop_all_mails()

/obj/machinery/mailmat/update_appearance(updates=ALL)
	. = ..()
	if(machine_stat & BROKEN)
		set_light(0)
		return
	set_light(powered() ? MINIMUM_USEFUL_LIGHT_RANGE : 0)

/obj/machinery/mailmat/update_icon_state()
	if(machine_stat & BROKEN)
		icon_state = "[initial(icon_state)]-broken"
		return ..()
	icon_state = "[initial(icon_state)][powered() ? null : "-off"]"
	return ..()

/obj/machinery/mailmat/obj_break(damage_flag)
	. = ..()
	if(!.)
		return
	drop_all_mails()

/obj/machinery/mailmat/proc/drop_all_mails(damage_flag)
	if(!isturf(get_turf(src)))
		stack_trace("[src] не смог сбросить своё содержимое")
		for(var/obj/item/mail in mails)
			qdel(mail)
		return
	var/turf/dropturf = get_turf(src)
	for(var/obj/item/mail in mails)
		mail.forceMove(dropturf)
