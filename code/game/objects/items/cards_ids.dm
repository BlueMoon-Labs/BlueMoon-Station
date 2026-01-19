/* Cards
 * Contains:
 *		DATA CARD
 *		ID CARD
 *		FINGERPRINT CARD HOLDER
 *		FINGERPRINT CARD
 */

/*
 * DATA CARDS - Used for the IC data card reader
 */
/obj/item/card
	name = "card"
	desc = "Does card things."
	icon = 'icons/obj/card.dmi'
	w_class = WEIGHT_CLASS_TINY

	var/list/files = list()

/obj/item/card/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] begins to swipe [user.ru_ego()] neck with \the [src]! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	return BRUTELOSS

/obj/item/card/data
	name = "data card"
	desc = "A plastic magstripe card for simple and speedy data storage and transfer. This one has a stripe running down the middle."
	icon_state = "data_1"
	obj_flags = UNIQUE_RENAME
	var/function = "storage"
	var/data = "null"
	var/special = null
	item_state = "card-id"
	lefthand_file = 'icons/mob/inhands/equipment/idcards_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/idcards_righthand.dmi'
	var/detail_color = COLOR_ASSEMBLY_ORANGE

/obj/item/card/data/Initialize(mapload)
	.=..()
	update_icon()

/obj/item/card/data/update_overlays()
	. = ..()
	if(detail_color == COLOR_FLOORTILE_GRAY)
		return
	var/mutable_appearance/detail_overlay = mutable_appearance('icons/obj/card.dmi', "[icon_state]-color")
	detail_overlay.color = detail_color
	. += detail_overlay

/obj/item/card/data/attackby(obj/item/I, mob/living/user)
	if(istype(I, /obj/item/integrated_electronics/detailer))
		var/obj/item/integrated_electronics/detailer/D = I
		detail_color = D.detail_color
		update_icon()
	return ..()

/obj/item/proc/GetCard()

/obj/item/card/data/GetCard()
	return src

/obj/item/card/data/full_color
	desc = "A plastic magstripe card for simple and speedy data storage and transfer. This one has the entire card colored."
	icon_state = "data_2"

/obj/item/card/data/disk
	desc = "Пластиковая карта с магнитной полосой для простой и скоростной передачи-записи данных. Этот выглядит ну прямо как дискета."
	icon_state = "data_3"

/*
 * ID CARDS
 */
/obj/item/card/emag
	desc = "Это карта с какими-то магнитными полосами на её схемах."
	name = "cryptographic sequencer"
	icon_state = "emag"
	item_state = "card-id"
	lefthand_file = 'icons/mob/inhands/equipment/idcards_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/idcards_righthand.dmi'
	item_flags = NO_MAT_REDEMPTION | NOBLUDGEON
	var/prox_check = TRUE //If the emag requires you to be in range
	var/uses = 30

/obj/item/card/emag/bluespace
	name = "bluespace cryptographic sequencer"
	desc = "Это синяя карта с какими-то магнитными полосами на её схемах... На ней видно некий передатчик."
	icon_state = "emag_bs"
	prox_check = FALSE

/obj/item/card/emag/attack()
	return

/obj/item/card/emag/afterattack(atom/target, mob/user, proximity)
	. = ..()
	var/atom/A = target
	if(!proximity && prox_check || !(isobj(A) || issilicon(A) || isbot(A) || isdrone(A)))
		return
	if(istype(A, /obj/item/storage) && !(istype(A, /obj/item/storage/lockbox) || istype(A, /obj/item/storage/pod)))
		return
	if(!uses)
		user.visible_message("<span class='warning'>[src] вспыхивает с небольшой искрой. Карта сожжена!</span>")
		playsound(src, 'sound/effects/light_flicker.ogg', 100, 1)
		return
	else if(uses <= 3)
		playsound(src, 'sound/effects/light_flicker.ogg', 30, 1)	//Tiiiiiiny warning sound to let ya know your emag's almost dead
	if(!A.emag_act(user))
		return
	uses = max(uses - 1, 0)
	if(!uses)
		user.visible_message("<span class='warning'>[src] шипит и искрится. Похоже, зарядов не осталось.</span>")
		playsound(src, 'sound/effects/light_flicker.ogg', 100, 1)

/obj/item/card/emag/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Зарядов осталось: <b>[uses ? uses : "0"]</b>.</span>"

/obj/item/card/id/examine_more(mob/user)
	var/list/msg = list("<span class='notice'><i>Вы осмотрели [src] поближе и заметили следующее...</i></span>")

	if(mining_points)
		msg += "У карты в наличии [mining_points] ед. очков шахтёрского оборудования."
	if(registered_account)
		msg += "Привязанный к ID-карте аккаунт записан на имя \"[registered_account.account_holder]\" и сообщает о балансе [registered_account.account_balance] кр."
		if(registered_account.account_job)
			var/datum/bank_account/D = SSeconomy.get_dep_account(registered_account.account_job.paycheck_department)
			if(D)
				msg += "На балансе [budget_to_ru_genitive(D.account_holder)] находится [D.account_balance] кр."
		msg += "<span class='info'>Alt-Click по ID, чтобы достать деньги из аккаунта в форме голочипов.</span>"
		msg += "<span class='info'>Вы может добавить кредиты на аккаунт, прижимая голочипы, наличные или монеты к ID.</span>"
		if(registered_account.account_holder == user.real_name)
			msg += "<span class='boldnotice'>Если вы потеряете эту ID-карту, вы можете переподключить свой аккаунт путём Alt-Click по пустой карте, держа её и введя свой ID-номер.</span>"
	else
		msg += "<span class='info'>У данной карты нет зарегистрированного акканта. Alt-Click, чтобы добавить.</span>"

	return msg

/obj/item/card/emag/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/emagrecharge))
		var/obj/item/emagrecharge/ER = W
		if(ER.uses)
			uses += ER.uses
			to_chat(user, "<span class='notice'>Вы добавили [ER.uses] ед. зарядов к [src]. Теперь осталось [uses] использований.</span>")
			playsound(src, "sparks", 100, 1)
			ER.uses = 0
		else
			to_chat(user, "<span class='warning'>У [ER] не осталось зарядов.</span>")
		return
	. = ..()

/obj/item/card/emag/empty
	uses = 0

/obj/item/emagrecharge
	name = "electromagnet charging device"
	desc = "Небольшой аккумулятор двумя лениво воткнутыми штырями. Похоже, она нужна для заряжения небольших батарей в электромагнитных устройствах и, к несчастью, без возможности нормальной зарядки."
	icon = 'icons/obj/module.dmi'
	icon_state = "cell_mini"
	item_flags = NOBLUDGEON
	var/uses = 5	//Dictates how many charges the device adds to compatible items

/obj/item/emagrecharge/examine(mob/user)
	. = ..()
	if(uses)
		. += "<span class='notice'>Вы можете добавить до [uses] ед. зарядов к подходящим устройствам.</span>"
	else
		. += "<span class='warning'>Видна маленький, красный, мигающий свет изнутри. Израсходовано.</span>"

/obj/item/card/emagfake
	desc = "Это карта с какими-то магнитными полосами на её схемах."
	name = "cryptographic sequencer"
	icon_state = "emag"
	item_state = "card-id"
	lefthand_file = 'icons/mob/inhands/equipment/idcards_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/idcards_righthand.dmi'

/obj/item/card/emagfake/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += "Вблизи видно, что эта карта - просто дешёвая имитация с лого \"DonkCo\" сзади."

/obj/item/card/emagfake/afterattack()
	. = ..()
	playsound(src, 'sound/items/bikehorn.ogg', 50, 1)

/obj/item/card/id
	name = "Identification Card"
	desc = "ID-карта для идентификации экипажа и определения доступов по станции."
	icon_state = "id"
	item_state = "card-id"
	lefthand_file = 'icons/mob/inhands/equipment/idcards_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/idcards_righthand.dmi'
	slot_flags = ITEM_SLOT_ID
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 100, ACID = 100)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	var/id_type_name = "Identification Card"
	var/mining_points = 0 //For redeeming at mining equipment vendors
	var/mining_points_total = 0 //Для отслеживания рабты шахтёров
	var/list/access = list()
	var/registered_name = null // The name registered_name on the card
	var/assignment = null
	var/custom_job = ""
	var/access_txt // mapping aid
	var/bank_support = ID_FREE_BANK_ACCOUNT
	var/withdraw_allowed = TRUE // BLUEMOON ADD
	var/datum/bank_account/registered_account
	var/obj/machinery/paystand/my_store
	var/uses_overlays = TRUE
	var/icon/cached_flat_icon
	var/obj/item/card_sticker/sticker //BLUEMOON ADD Стикеры на карточку
	var/special_assignment = null // BLUEMOOD ADD для особых карт и их HUD, техническое

/obj/item/card/id/Initialize(mapload)
	. = ..()
	if(mapload && access_txt)
		access = text2access(access_txt)
	switch(bank_support)
		if(ID_FREE_BANK_ACCOUNT)
			var/turf/T = get_turf(src)
			if(T && is_vr_level(T.z)) //economy is exploitable on VR in so many ways.
				bank_support = ID_NO_BANK_ACCOUNT
		if(ID_LOCKED_BANK_ACCOUNT)
			registered_account = new /datum/bank_account/remote/non_transferable(pick(GLOB.redacted_strings))

/obj/item/card/id/Destroy()
	if(bank_support == ID_LOCKED_BANK_ACCOUNT)
		QDEL_NULL(registered_account)
	else
		registered_account = null
	if(my_store)
		my_store.my_card = null
		my_store = null
	cached_flat_icon = null //SPLURT edit
	QDEL_NULL(access)
	return ..()

/obj/item/card/id/vv_edit_var(var_name, var_value)
	. = ..()
	if(.)
		switch(var_name)
			if(NAMEOF(src, assignment),NAMEOF(src, registered_name),NAMEOF(src, sticker),NAMEOF(src, custom_job)) //,NAMEOF(src, registered_age))
				update_label()

/obj/item/card/id/attack_self(mob/user)
	if(Adjacent(user))
		user.visible_message("<span class='notice'>[user] показывает вам: [icon2html(src, viewers(user))] [src.name].</span>", \
					"<span class='notice'>Вы показали \the [src.name].</span>")
		add_fingerprint(user)

/obj/item/card/id/attackby(obj/item/W, mob/user, params)
	//BLUEMOON ADD стикеры на карту
	if(istype(W, /obj/item/card_sticker))
		var/obj/item/card_sticker/card_sticker = W
		card_sticker.wrap(src, user)
		return
	//BLUEMOON ADD END

	if(!bank_support)
		return ..()
	if((istype(W, /obj/item/holochip) || istype(W, /obj/item/stack/spacecash) || istype(W, /obj/item/coin)))
		insert_money(W, user)
	else if(istype(W, /obj/item/storage/bag/money))
		var/obj/item/storage/bag/money/money_bag = W
		var/list/money_contained = money_bag.contents
		var/money_added = mass_insert_money(money_contained, user)
		if (money_added)
			to_chat(user, "<span class='notice'>Вы приставляете содержимое к карте! Оно исчезает в облаке блюспейса, добавляя [money_added] кр. на связанный счёт.</span>")
	else
		return ..()

/obj/item/card/id/proc/insert_money(obj/item/I, mob/user)
	if(!bank_support || !registered_account) // BLUEMOON EDIT
		to_chat(user, "<span class='warning'>К [src] нет привязанного аккаунт для зачисления [I]!</span>")
		return
	var/cash_money = I.get_item_credit_value()
	if(!cash_money)
		to_chat(user, "<span class='warning'>[I] не кажется стоящим что-либо!</span>")
		return
	registered_account.adjust_money(cash_money)
	if(istype(I, /obj/item/stack/spacecash) || istype(I, /obj/item/coin))
		to_chat(user, "<span class='notice'>Вы приставляете [I] в [src]. Они исчезают в облаке блюспейса, добавляя [cash_money] кр. на связанный счёт.</span>")
	else
		to_chat(user, "<span class='notice'>Вы вставляете [I] в [src], добавляя [cash_money] кр. на связанный счёт.</span>")
	// после успешного зачисления:
	if(registered_account)
		registered_account.makeTransactionLog(
			cash_money,
			"Deposit via [I.name]",
			"[src.name]",
			user ? user.real_name : "Unknown depositor",
			FALSE
		)

	to_chat(user, "<span class='notice'>Привязанный аккаунт докладывает о балансе в [registered_account.account_balance] кр.</span>")
	qdel(I)

/obj/item/card/id/proc/mass_insert_money(list/money, mob/user)
	if(!bank_support || !registered_account)
		to_chat(user, "<span class='warning'>У [src] нет привязанного аккаунта для зачисления!</span>")
		return FALSE

	if (!money || !money.len)
		return FALSE

	var/total = 0

	for (var/obj/item/physical_money in money)
		total += physical_money.get_item_credit_value()
		CHECK_TICK

	registered_account.adjust_money(total)
	if(registered_account && total > 0)
		registered_account.makeTransactionLog(
			total,
			"Deposit via money bag",
			"[src.name]",
			user ? user.real_name : "Unknown depositor",
			FALSE
		)

	QDEL_LIST(money)

	return total

/obj/item/card/id/proc/alt_click_can_use_id(mob/living/user)
	if(!isliving(user))
		return
	if(!user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return

	return TRUE

// Returns true if new account was set.
/obj/item/card/id/proc/set_new_account(mob/living/user)
	if(bank_support != ID_FREE_BANK_ACCOUNT)
		to_chat(user, "<span class='warning'>Эта ID-карта не имеет модульного банковского счета. Должно быть, устаревшая модель...</span>")
		return
	. = FALSE
	var/datum/bank_account/old_account = registered_account

	var/new_bank_id = input(user, "Введите номер вашего банковского счета.", "Восстановление аккаунта", 111111) as num | null

	if (isnull(new_bank_id))
		return

	if(!alt_click_can_use_id(user))
		return
	if(!new_bank_id || new_bank_id < 111111 || new_bank_id > 999999)
		to_chat(user, "<span class='warning'>Номер банковского счета должен быть между 111111 и 999999.</span>")
		return
	if (registered_account && registered_account.account_id == new_bank_id)
		to_chat(user, "<span class='warning'>Номер банковского счета уже привязан к этой карте.</span>")
		return

	for(var/A in SSeconomy.bank_accounts)
		var/datum/bank_account/B = A
		if(B.account_id == new_bank_id)
			if (old_account)
				old_account.bank_cards -= src

			B.bank_cards += src
			registered_account = B
			to_chat(user, "<span class='notice'>Предоставленный аккаунт был привязан к этой ID-карте.</span>")

			return TRUE

	to_chat(user, "<span class='warning'>Предоставленный номер банковского счета недействителен.</span>")
	return

/obj/item/card/id/AltClick(mob/living/user)
	. = ..()
	//BLUEMOON ADD стикеры на карту
	if(sticker)
		var/response = tgui_alert(user, "Что вы хотите сделать?", src.name, list("Снять наличные", "Убрать наклейку"), autofocus = TRUE)
		if(!response)
			return
		else if(response == "Убрать наклейку")
			sticker.unwrap(src, user)
			return
	//BLUEMOON ADD END

	if(!bank_support || !alt_click_can_use_id(user))
		return

	if(!registered_account && bank_support == ID_FREE_BANK_ACCOUNT)
		set_new_account(user)
		return

	if(!withdraw_allowed)
		if(!HAS_TRAIT(user.mind, TRAIT_FENCER))
			if(user.mind?.antag_datums && !user.mind?.has_antag_datum(/datum/antagonist/ghost_role))
				var/message = span_warning("ОШИБКА: Замечена попытка кр... добро пожаловать в систему, Джон Доу.")
				playsound(src, "sparks", 100, 1)
				if(registered_account)
					registered_account.bank_card_talk(message)
				else
					to_chat(user, message)
			else
				var/message = span_warning("ОШИБКА: С этой карты нельзя снимать кредиты.")
				if(registered_account)
					registered_account.bank_card_talk(message)
				else
					to_chat(user, message)
				return

	if (world.time < registered_account.withdrawDelay)
		registered_account.bank_card_talk("<span class='warning'>ОШИБКА: НЕВОЗМОЖНО ВОЙТИ ВВИДУ ЗАПЛАНИРОВАННОГО ТЕХОБСЛУЖИВАНИЯ. РАБОТЫ ЗАПЛАНИРОВАНЫ К ЗАВЕРШЕНИЮ В ТЕЧЕНИЕ [(registered_account.withdrawDelay - world.time)/10] СЕКУНД.</span>", TRUE)
		return

	var/amount_to_remove =  input(user, "Как много кредитов вы хотите снять? Текущий баланс: [registered_account.account_balance]", "Снятие средств", 5) as num|null

	if(!amount_to_remove || amount_to_remove < 0)
		return
	if(!alt_click_can_use_id(user))
		return
	amount_to_remove = FLOOR(min(amount_to_remove, registered_account.account_balance), 1)
	if(amount_to_remove && registered_account.adjust_money(-amount_to_remove))
		var/obj/item/holochip/holochip = new (user.drop_location(), amount_to_remove)
		user.put_in_hands(holochip)
		to_chat(user, "<span class='notice'>Вы сняли [amount_to_remove] кр. в форме голочипа.</span>")

		// 🧾 Добавляем запись о снятии в историю транзакций
		registered_account.makeTransactionLog(
			-amount_to_remove,
			"Withdrawal via ID Card",
			"[src.name]",
			user ? user.real_name : "Unknown user",
			FALSE
		)
		return
	registered_account.bank_card_talk("<span class='warning'>ОШИБКА: У привязанного аккаунта недостаточно средств для выполнения этой операции.</span>", TRUE)

/obj/item/card/id/examine(mob/user)
	. = ..()
	if(mining_points)
		. += "У этой карты [mining_points] рудокопных очков карго; всего было заработано [mining_points_total] очков."
	if(!bank_support || (bank_support == ID_LOCKED_BANK_ACCOUNT && !registered_account))
		. += "<span class='info'>Эта ID-карта не имеет банковского счёта. Должно быть, устаревшая модель...</span>"
	else if(registered_account)
		. += "Привязанный к ID-карте аккаунт записан на имя \"[registered_account.account_holder]\" и сообщает о балансе [registered_account.account_balance] кр."
		if(registered_account.account_job)
			var/datum/bank_account/D = SSeconomy.get_dep_account(registered_account.account_job.paycheck_department)
			if(D)
				. += "На балансе [budget_to_ru_genitive(D.account_holder)] находится [D.account_balance] кр."
		. += "<span class='info'>Alt-Click по ID-карте, чтобы снять деньги с аккаунта в форме голочипов.</span>"
		. += "<span class='info'>Вы можете внести кредиты на аккаунт, приложив голочипы, наличные или монеты к ID-карте.</span>"
		if(registered_account.civilian_bounty)
			. += "<span class='info'><b>Есть активное гражданское баунти:</b>"
			. += "<span class='info'><i>[registered_account.bounty_text()]</i></span>"
			. += "<span class='info'>Количество: [registered_account.bounty_num()]</span>"
			. += "<span class='info'>Награда: [registered_account.bounty_value()]</span>"
		if(registered_account.account_holder == user.real_name)
			. += "<span class='boldnotice'>Если вы потеряете эту ID-карту, вы можете восстановить свой аккаунт, нажав Alt-Click по пустой ID-карту, держа её в руках, и введя номер своего банковского счёта.</span>"
	else
		. += "<span class='info'>Нет зарегистрированного аккаунта. Alt-Click, чтобы добавить.</span>"

/obj/item/card/id/GetAccess()
	return access

/obj/item/card/id/GetID()
	return src

/obj/item/card/id/RemoveID()
	return src

/obj/item/card/id/update_overlays()
    . = ..()
    if(!uses_overlays)
        return
    cached_flat_icon = null
    var/job = assignment ? ckey(get_job_name()) : null
    var/list/specialjobs = list(/obj/item/card/id/syndicate/advanced/ds) // Для спец. ролей с уникальными картами
    job = replacetext(job, " ", "")
    job = replacetext(job, "-", "") // Для учёта более сложных assigment'ов, как на DS-1/2
    job = lowertext(job)
    if(registered_name && registered_name != "Captain" && !is_type_in_list(src, specialjobs))
        . += mutable_appearance(icon, "assigned")
    if(job)
        . += mutable_appearance(icon, "id[job]")

/obj/item/card/id/proc/get_cached_flat_icon()
	if(!cached_flat_icon)
		cached_flat_icon = getFlatIcon(src)
	return cached_flat_icon


/obj/item/card/id/get_examine_string(mob/user, thats = FALSE)
	if(uses_overlays)
		return "[icon2html(get_cached_flat_icon(), user)] [thats? "That's ":""][get_examine_name(user)]" //displays all overlays in chat
	return ..()

/obj/item/card/id/proc/update_label(newname, newjob)
	var/effective_name = newname ? newname : registered_name

	var/base = effective_name ? "[effective_name] - ID Card" : "Identification card"

	var/job_name = get_assignment_name(newjob)
	if(job_name)
		job_name = " ([job_name])"

	name = "[base][job_name]"
	update_icon()

/obj/item/card/id/proc/get_assignment_name(newjob)
	. = ""
	var/effective_job = newjob || custom_job || assignment
	if(!effective_job)
		return

	. = effective_job

	if(!sticker)
		return

	// Ищем префикс и запрещенные слова в работе
	if(sticker.prefix)
		var/list/temp = sticker.prefix_not_allowed_with.Copy()
		temp |= sticker.prefix
		for(var/forbidden in temp)
			var/regex/R = regex("(^|\[^A-Za-zА-Яа-я0-9\])[forbidden](\[^A-Za-zА-Яа-я0-9\]|$)", "i")
			if(R.Find(effective_job))
				return // есть совпадение — возвращаем без префикса

	. = "[sticker.prefix] [effective_job]"

/obj/item/card/id/proc/update_manifest()
	GLOB.data_core.manifest_modify(registered_name, get_assignment_name(), assignment)

/obj/item/card/id/silver
	name = "silver identification card"
	desc = "Серебряная ID-карточка для честных и преданных корпоративных работников."
	icon_state = "silver"
	item_state = "silver_id"
	lefthand_file = 'icons/mob/inhands/equipment/idcards_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/idcards_righthand.dmi'

/obj/item/card/id/silver/reaper
	name = "Thirteen's ID Card (Reaper)"
	access = list(ACCESS_MAINT_TUNNELS)
	icon_state = "reaper"
	assignment = "Reaper"
	registered_name = "Thirteen"

/obj/item/card/id/gold
	name = "Gold Identification Card"
	desc = "Золотая ID-карточка, символизирующая власть и могущество."
	icon_state = "gold"
	item_state = "gold_id"
	lefthand_file = 'icons/mob/inhands/equipment/idcards_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/idcards_righthand.dmi'

/obj/item/card/id/syndicate
	name = "Agent Card"
	icon_state = "card_black"
	assignment = "Syndicate Operative"
	access = list(ACCESS_MAINT_TUNNELS, ACCESS_SYNDICATE)
	var/anyone = FALSE //Can anyone forge the ID or just syndicate?
	var/forged = FALSE //have we set a custom name and job assignment, or will we use what we're given when we chameleon change?

/obj/item/card/id/syndicate/advanced
	name = "Agent Card"
	icon_state = "card_black"

/obj/item/card/id/syndicate/Initialize(mapload)
	. = ..()
	var/datum/action/item_action/chameleon/change/chameleon_action = new(src)
	chameleon_action.chameleon_type = /obj/item/card/id
	chameleon_action.chameleon_name = "ID Card"
	chameleon_action.initialize_disguises()
	if(!anyone)
		AddComponent(/datum/component/identification/syndicate, ID_COMPONENT_DEL_ON_IDENTIFY, ID_COMPONENT_EFFECT_NO_ACTIONS, NONE)		//no deconstructive analyzer usage.

/obj/item/card/id/syndicate/afterattack(obj/item/O, mob/user, proximity)
	if(!proximity)
		return
	if(istype(O, /obj/item/card/id) && !uses)
		to_chat(usr, "<span class='notice'>Микросканеры устройства издают отрицательное жужжание при попытке использовать их ещё раз.</span>")
		playsound(src, 'sound/effects/light_flicker.ogg', 100, 1)
		return
	if(istype(O, /obj/item/card/id))
		var/obj/item/card/id/I = O
		src.access |= I.access
		uses = max(uses - 1, 0)
		to_chat(usr, "<span class='notice'>Микросканеры устройства активизируются при проведении ею по Идентификационной Карте и копируют её доступ.</span>")
		playsound(src, 'sound/effects/light_flicker.ogg', 100, 1)

/obj/item/card/id/syndicate/attack_self(mob/user)
	if(isliving(user) && user.mind)
		var/first_use = registered_name ? FALSE : TRUE
		if(!(user.mind.special_role || anyone)) //Unless anyone is allowed, only syndies can use the card, to stop metagaming.
			if(first_use) //If a non-syndie is the first to forge an unassigned agent ID, then anyone can forge it.
				anyone = TRUE
			else
				return ..()

		var/popup_input
		if(bank_support == ID_FREE_BANK_ACCOUNT)
			popup_input = alert(user, "Choose Action", "Agent ID", "Show", "Forge/Reset", "Change Account ID")
		else
			popup_input = alert(user, "Choose Action", "Agent ID", "Show", "Forge/Reset")
		if(!user.canUseTopic(src, BE_CLOSE, FALSE))
			return
		if(popup_input == "Forge/Reset" && !forged)
			var/input_name = stripped_input(user, "Какое имя вы хотите присвоить карте? Оставьте пустым для случайной генерации.", "Имя агентской карточки", registered_name ? registered_name : (ishuman(user) ? user.real_name : user.name), MAX_NAME_LEN)
			input_name = reject_bad_name(input_name)
			if(!input_name)
				// Invalid/blank names give a randomly generated one.
				if(user.gender == MALE)
					input_name = "[pick(GLOB.first_names_male)] [pick(GLOB.last_names)]"
				else if(user.gender == FEMALE)
					input_name = "[pick(GLOB.first_names_female)] [pick(GLOB.last_names)]"
				else
					input_name = "[pick(GLOB.first_names)] [pick(GLOB.last_names)]"

			var/target_occupation = stripped_input(user, "Какую должность вы хотите присвоить карте?\nИмейте ввиду: это не даст соответствующих доступов.", "Должность агентской карточки", assignment ? assignment : "Assistant", MAX_MESSAGE_LEN)
			if(!target_occupation)
				return
			registered_name = input_name
			assignment = target_occupation
			update_label()
			forged = TRUE
			to_chat(user, "<span class='notice'>Вы успешно подделали ID-карту.</span>")
			log_game("[key_name(user)] has forged \the [initial(name)] with name \"[registered_name]\" and occupation \"[assignment]\".")

			// First time use automatically sets the account id to the user.
			if (first_use && !registered_account)
				if(ishuman(user))
					var/mob/living/carbon/human/accountowner = user

					for(var/bank_account in SSeconomy.bank_accounts)
						var/datum/bank_account/account = bank_account
						if(account.account_id == accountowner.account_id)
							account.bank_cards += src
							registered_account = account
							to_chat(user, "<span class='notice'>Ваш номер счёта был автоматически присвоен.</span>")
			return
		else if (popup_input == "Forge/Reset" && forged)
			registered_name = initial(registered_name)
			assignment = initial(assignment)
			log_game("[key_name(user)] has reset \the [initial(name)] named \"[src]\" to default.")
			update_label()
			forged = FALSE
			to_chat(user, "<span class='notice'>Вы успешно сбросили ID-карту.</span>")
			return
		else if (popup_input == "Change Account ID")
			set_new_account(user)
			return
	return ..()

/obj/item/card/id/syndicate/anyone
	anyone = TRUE
	assignment = "Lavaland Syndicate Agent"

/obj/item/card/id/syndicate/anyone/shaft
	anyone = TRUE
	assignment = "Lavaland Syndicate Security Agent"
	access = list(ACCESS_MAINT_TUNNELS, ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)

/obj/item/card/id/syndicate/anyone/comms
	anyone = TRUE
	assignment = "Syndicate Comms Agent"
	access = list(ACCESS_MAINT_TUNNELS, ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)

/obj/item/card/id/syndicate/nuke_leader
	name = "Lead Agent Card"
	access = list(ACCESS_MAINT_TUNNELS, ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)

/obj/item/card/id/syndicate/syndicate_command
	name = "syndicate ID card"
	desc = "ID-карта выпуска Триглава Синдиката."
	registered_name = "Syndicate"
	assignment = "Syndicate Overlord"
	access = list(ACCESS_SYNDICATE)

/obj/item/card/id/no_banking
	bank_support = ID_NO_BANK_ACCOUNT

/obj/item/card/id/locked_banking
	bank_support = ID_LOCKED_BANK_ACCOUNT

/obj/item/card/id/syndicate/locked_banking
	bank_support = ID_LOCKED_BANK_ACCOUNT

/obj/item/card/id/pirate
	access = list(ACCESS_SYNDICATE)

/obj/item/card/id/syndicate/vox_scavenger
	icon_state = "retro"
	assignment = "Trader"
	access = list(ACCESS_SYNDICATE)

/obj/item/card/id/captains_spare
	name = "captain's spare ID"
	desc = "Запасная ID-карта самого властителя станции."
	icon_state = "gold"
	item_state = "gold_id"
	lefthand_file = 'icons/mob/inhands/equipment/idcards_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/idcards_righthand.dmi'
	registered_name = "Captain"
	assignment = "Captain"

/obj/item/card/id/captains_spare/Initialize(mapload)
	var/datum/job/captain/J = new/datum/job/captain
	access = J.get_access()
	. = ..()

/obj/item/card/id/centcom
	name = "\improper CentCom ID"
	desc = "ID-карта выпуска Центрального Командования Nanotrasen."
	icon_state = "centcom"
	registered_name = "Central Command"
	assignment = "General"

/obj/item/card/id/centcom/Initialize(mapload)
	access = get_all_centcom_access()
	. = ..()

/obj/item/card/id/ert
	name = "\improper CentCom ID"
	desc = "ID-карта оперативников ОБР."
	icon_state = "ert_commander"
	registered_name = "Emergency Response Team Commander"
	assignment = "Emergency Response Team Commander"

/obj/item/card/id/ert/Initialize(mapload)
	access = get_all_accesses()+get_ert_access("commander")-ACCESS_CHANGE_IDS
	registered_account = SSeconomy.get_dep_account(ACCOUNT_CAR)
	. = ..()

/obj/item/card/id/ert/Security
	icon_state = "ert_security"
	registered_name = "Security Response Officer"
	assignment = "Security Response Officer"

/obj/item/card/id/ert/Security/Initialize(mapload)
	access = get_all_accesses()+get_ert_access("sec")-ACCESS_CHANGE_IDS
	. = ..()

/obj/item/card/id/ert/Engineer
	icon_state = "ert_engineer"
	registered_name = "Engineer Response Officer"
	assignment = "Engineer Response Officer"

/obj/item/card/id/ert/Engineer/Initialize(mapload)
	access = get_all_accesses()+get_ert_access("eng")-ACCESS_CHANGE_IDS
	. = ..()

/obj/item/card/id/ert/Medical
	icon_state = "ert_medic"
	registered_name = "Medical Response Officer"
	assignment = "Medical Response Officer"

/obj/item/card/id/ert/Medical/Initialize(mapload)
	access = get_all_accesses()+get_ert_access("med")-ACCESS_CHANGE_IDS
	. = ..()

/obj/item/card/id/ert/chaplain
	icon_state = "ert_chaplain"
	registered_name = "Religious Response Officer"
	assignment = "Religious Response Officer"

/obj/item/card/id/ert/chaplain/Initialize(mapload)
	access = get_all_accesses()+get_ert_access("sec")-ACCESS_CHANGE_IDS
	. = ..()

/obj/item/card/id/prisoner
	name = "prisoner ID card"
	desc = "Теперь вы - номер, вы - не свободный человек."
	icon_state = "orange"
	item_state = "orange-id"
	lefthand_file = 'icons/mob/inhands/equipment/idcards_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/idcards_righthand.dmi'
	assignment = "Prisoner"
	access = list(ACCESS_ENTER_GENPOP)

	//Lavaland labor camp
	var/goal = 0 //How far from freedom?
	var/points = 0
	//Genpop
	var/sentence = 0	//When world.time is greater than this number, the card will have its ACCESS_ENTER_GENPOP access replaced with ACCESS_LEAVE_GENPOP the next time it's checked, unless this value is 0/null
	var/crime= "\[REDACTED\]"

/obj/item/card/id/prisoner/GetAccess()
	if((sentence && world.time >= sentence) || (goal && points >= goal))
		access = list(ACCESS_LEAVE_GENPOP)
	return ..()

/obj/item/card/id/prisoner/process()
	if(!sentence)
		STOP_PROCESSING(SSobj, src)
		return
	if(world.time >= sentence)
		playsound(loc, 'sound/machines/ping.ogg', 50, 1)
		if(isliving(loc))
			to_chat(loc, "<span class='boldnotice'>[src]</span><span class='notice'> buzzes: Вы отбыли свой срок! Теперь вы можете покинуть пермабриг и забрать свои вещи.</span>")
		STOP_PROCESSING(SSobj, src)
	return

/obj/item/card/id/prisoner/examine(mob/user)
	. = ..()
	if(sentence && world.time < sentence)
		. += "<span class='notice'>Вы отбываете срок за [crime]. <b>[DisplayTimeText(sentence - world.time)]</b> осталось.</span>"
	else if(goal)
		. += "<span class='notice'>Вы накопили [points] из [goal] очков, необходимых для освобождения.</span>"
	else if(!sentence)
		. += "<span class='warning'>Вы отбываете пожизненное заключение за [crime].</span>"
	else
		. += "<span class='notice'>Ваш срок истёк! Вы свободны!</span>"

/obj/item/card/id/prisoner/one
	icon_state = "prisoner_001"
	name = "Prisoner #13-001"
	registered_name = "Prisoner #13-001"

/obj/item/card/id/prisoner/two
	icon_state = "prisoner_002"
	name = "Prisoner #13-002"
	registered_name = "Prisoner #13-002"

/obj/item/card/id/prisoner/three
	icon_state = "prisoner_003"
	name = "Prisoner #13-003"
	registered_name = "Prisoner #13-003"

/obj/item/card/id/prisoner/four
	icon_state = "prisoner_004"
	name = "Prisoner #13-004"
	registered_name = "Prisoner #13-004"

/obj/item/card/id/prisoner/five
	icon_state = "prisoner_005"
	name = "Prisoner #13-005"
	registered_name = "Prisoner #13-005"

/obj/item/card/id/prisoner/six
	icon_state = "prisoner_006"
	name = "Prisoner #13-006"
	registered_name = "Prisoner #13-006"

/obj/item/card/id/prisoner/seven
	icon_state = "prisoner_007"
	name = "Prisoner #13-007"
	registered_name = "Prisoner #13-007"

/obj/item/card/id/mining
	name = "mining ID"
	icon_state = "retro"
	access = list(ACCESS_MINING, ACCESS_MINING_STATION, ACCESS_MAILSORTING, ACCESS_MINERAL_STOREROOM)

/obj/item/card/id/away
	name = "A Perfectly Generic Identification Card"
	desc = "Идеально безликая ID-карточка. Этой не помешало бы украшение."
	icon_state = "retro"
	access = list(ACCESS_AWAY_GENERAL)

/obj/item/card/id/away/hotel
	name = "Staff ID"
	desc = "ID-карта сотрудника, используемая для доступа в космическом отеле."
	access = list(ACCESS_AWAY_GENERAL, ACCESS_AWAY_MAINT)

/obj/item/card/id/away/hotel/securty
	name = "Officer ID"
	access = list(ACCESS_AWAY_GENERAL, ACCESS_AWAY_MAINT, ACCESS_AWAY_SEC)

/obj/item/card/id/away/old
	name = "A Perfectly Generic Identification Card"
	desc = "Идеально безликая ID-карточка. Этой не помешало бы украшение."
	icon_state = "centcom"

/obj/item/card/id/away/old/sec
	name = "Charlie Station Security Officer's ID card"
	desc = "Старая ID-карта Чарли Станции. Вы можете разглядеть должность: \"Офицер безопасности\"."
	assignment = "Charlie Station Security Officer"
	access = list(ACCESS_AWAY_GENERAL, ACCESS_AWAY_SEC)

/obj/item/card/id/away/old/sci
	name = "Charlie Station Scientist's ID card"
	desc = "Старая ID-карта Чарли Станции. Вы можете разглядеть должность: \"Ученый\"."
	assignment = "Charlie Station Scientist"
	access = list(ACCESS_AWAY_GENERAL)

/obj/item/card/id/away/old/eng
	name = "Charlie Station Engineer's ID card"
	desc = "Старая ID-карта Чарли Станции. Вы можете разглядеть должность: \"Инженер станции\"."
	assignment = "Charlie Station Engineer"
	access = list(ACCESS_AWAY_GENERAL, ACCESS_AWAY_ENGINE)

/obj/item/card/id/away/old/apc
	name = "APC Access ID"
	desc = "ID-карта, имеющая доступ к терминалам APC."
	access = list(ACCESS_ENGINE_EQUIP)

/obj/item/card/id/away/old/tarkoff
	name = "Tarkov Visitor's Pass"
	desc = "ID-карта посетителя, покрытая пылью. Маленькая бирка сообщает: \"Порт Тарков, первый шаг к гражданскому партнерству в космическом освоении\"."
	access = list(ACCESS_AWAY_GENERAL, ACCESS_TARKOFF)

/obj/item/card/id/away/old/tarkoff/cargo
	assignment = "P-T Cargo Personell"
	desc = "ID-карта, предназначенная для \"лучших грузчиков\". Вы также являетесь шахтёром на полставки, когда в Каргонии тихо."
	access = list(ACCESS_AWAY_GENERAL, ACCESS_TARKOFF)

/obj/item/card/id/away/old/tarkoff/sec
	assignment = "P-T Port Guard"
	desc = "ID-карта, предназначенная для \"членов охраны\". Все хотят ваши пушки, партнёр. Йи-ха."
	access = list(ACCESS_AWAY_GENERAL, ACCESS_WEAPONS, ACCESS_SEC_DOORS, ACCESS_TARKOFF)

/obj/item/card/id/away/old/tarkoff/med
	assignment = "P-T Trauma Medic"
	desc = "ID-карта, предназначенная для \"медицинского персонала\". Вы предоставляете медицинские сумки."
	access = list(ACCESS_MEDICAL, ACCESS_AWAY_GENERAL, ACCESS_TARKOFF, ACCESS_SURGERY)

/obj/item/card/id/away/old/tarkoff/eng
	assignment = "P-T Maintenance Crew"
	desc = "ID-карта, предназначенная для \"инженерного персонала\". Вы будете тем, на кого все указывают, чтобы починить что-то, честно говоря."
	access = list(ACCESS_AWAY_GENERAL, ACCESS_TARKOFF, ACCESS_ENGINE_EQUIP, ACCESS_ATMOSPHERICS)

/obj/item/card/id/away/old/tarkoff/sci
	assignment = "P-T Field Researcher"
	desc = "ID-карта, предназначенная для \"научной команды\". Вы будете забыты практически сразу, когда дело дойдет до экспериментов."
	access = list(ACCESS_ROBOTICS, ACCESS_AWAY_GENERAL, ACCESS_WEAPONS, ACCESS_TARKOFF)

/obj/item/card/id/away/old/tarkoff/ensign
	assignment = "Tarkov Ensign"
	desc = "ID-карта, предназначенная для \"мичманов Таркова\". Никто не обязан вас слушать... Но вы - ближайший к командованию."
	access = list(ACCESS_MEDICAL, ACCESS_ROBOTICS, ACCESS_AWAY_GENERAL, ACCESS_TARKOFF, ACCESS_WEAPONS, ACCESS_ENGINE_EQUIP, ACCESS_ATMOSPHERICS)

/obj/item/card/id/departmental_budget
	name = "departmental card (FUCK)"
	desc = "Предоставляет доступ к бюджету отдела."
	icon_state = "budgetcard"
	withdraw_allowed = FALSE // BLUEMOON ADD
	var/department_ID = ACCOUNT_CIV
	var/department_name = ACCOUNT_CIV_NAME

/obj/item/card/id/departmental_budget/Initialize(mapload)
	. = ..()
	var/datum/bank_account/B = SSeconomy.get_dep_account(department_ID)
	if(B)
		registered_account = B
		if(!B.bank_cards.Find(src))
			B.bank_cards += src
		name = "departmental card ([department_name])"
		desc = "К этой карте привязан [lowertext(budget_to_ru_nominative(department_name))]."
		icon_state = "[lowertext(department_ID)]_budget"
	SSeconomy.dep_cards += src

/obj/item/card/id/departmental_budget/Destroy()
	SSeconomy.dep_cards -= src
	registered_account.bank_cards -= src
	return ..()

/obj/item/card/id/departmental_budget/update_label()
	return

/obj/item/card/id/departmental_budget/civ
	department_ID = ACCOUNT_CIV
	department_name = ACCOUNT_CIV_NAME

/obj/item/card/id/departmental_budget/eng
	department_ID = ACCOUNT_ENG
	department_name = ACCOUNT_ENG_NAME

/obj/item/card/id/departmental_budget/sci
	department_ID = ACCOUNT_SCI
	department_name = ACCOUNT_SCI_NAME

/obj/item/card/id/departmental_budget/med
	department_ID = ACCOUNT_MED
	department_name = ACCOUNT_MED_NAME

/obj/item/card/id/departmental_budget/srv
	department_ID = ACCOUNT_SRV
	department_name = ACCOUNT_SRV_NAME

/obj/item/card/id/departmental_budget/car
	department_ID = ACCOUNT_CAR
	department_name = ACCOUNT_CAR_NAME

/obj/item/card/id/departmental_budget/sec
	department_ID = ACCOUNT_SEC
	department_name = ACCOUNT_SEC_NAME

//Polychromatic Knight Badge

/obj/item/card/id/knight
	name = "knight badge"
	icon_state = "knight"
	desc = "A badge denoting the owner as a knight! It has a strip for swiping like an ID."
	var/id_color = "#00FF00" //defaults to green
	var/mutable_appearance/id_overlay

/obj/item/card/id/knight/Initialize(mapload)
	. = ..()
	id_overlay = mutable_appearance(icon, "knight_overlay")
	update_icon()

/obj/item/card/id/knight/update_label(newname, newjob)
	if(newname || newjob)
		name = "[(!newname)	? "knight badge"	: "[newname]'s Knight Badge"][(!newjob) ? "" : " ([newjob])"]"
		return

	name = "[(!registered_name)	? "knight badge"	: "[registered_name]'s Knight Badge"][(!assignment) ? "" : " ([assignment])"]"

/obj/item/card/id/knight/update_overlays()
	. = ..()
	id_overlay.color = id_color
	. += id_overlay

/obj/item/card/id/knight/AltClick(mob/living/user)
	. = ..()
	if(!in_range(src, user))	//Basic checks to prevent abuse
		return
	if(user.incapacitated() || !istype(user))
		to_chat(user, "<span class='warning'>You can't do that right now!</span>")
		return TRUE
	if(alert("Are you sure you want to recolor your id?", "Confirm Repaint", "Yes", "No") == "Yes")
		var/energy_color_input = input(usr,"","Choose Energy Color",id_color) as color|null
		if(!in_range(src, user) || !energy_color_input)
			return TRUE
		if(user.incapacitated() || !istype(user))
			to_chat(user, "<span class='warning'>You can't do that right now!</span>")
			return TRUE
		id_color = sanitize_hexcolor(energy_color_input, desired_format=6, include_crunch=1)
		update_icon()
		return TRUE

/obj/item/card/id/knight/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Alt-click to recolor it.</span>"

/obj/item/card/id/knight/blue
	id_color = "#0000FF"

/obj/item/card/id/knight/captain
	id_color = "#FFD700"

/obj/item/card/id/debug
	name = "\improper Debug ID"
	desc = "A debug ID card. Has ALL the all access, you really shouldn't have this."
	icon_state = "ert_janitor"
	assignment = "Jannie"

/obj/item/card/id/debug/Initialize(mapload)
	access = get_all_accesses()+get_all_centcom_access()+get_all_syndicate_access()+get_all_ghost_access()
	registered_account = SSeconomy.get_dep_account(ACCOUNT_CAR)
	. = ..()


/obj/item/card/id/death
	name = "\improper Death Commando ID"
	icon_state = "deathsquad"
	assignment = "Death Commando"
	special_assignment = "deathcommando"

/obj/item/forensic_card
    name = "Fingerprint card"
    desc = "Пустая карточка для снятия отпечатков пальцев."
    icon = 'icons/obj/card.dmi'
    icon_state = "fingerprint0"
    w_class = WEIGHT_CLASS_TINY
    var/has_print = FALSE
    var/fingerprint_data = null

/obj/item/forensic_card/attack(mob/living/carbon/human/target, mob/user)
    if(has_print)
        to_chat(user, "<span class='notice'>Эта карточка уже содержит отпечаток.</span>")
        return

    if(!ishuman(target))
        to_chat(user, "<span class='warning'>Можно снять отпечатки только с человека.</span>")
        return

    var/mob/living/carbon/human/H = target

    if(H.gloves)
        to_chat(user, "<span class='warning'>У [H] надеты перчатки — отпечатков не видно.</span>")
        return

    to_chat(user, "<span class='notice'>Ты начинаешь аккуратно снимать отпечатки с [H]...</span>")
    user.visible_message(
        "<span class='info'>[user] прикладывает карточку к руке [H], пытаясь снять отпечатки.</span>",
        "<span class='notice'>Ты осторожно прижимаешь карточку к пальцам [H].</span>"
    )

    // 5 секунд неподвижности для дела
    if(!do_after(user, 5 SECONDS, target = H))
        to_chat(user, "<span class='warning'>Ты прерываешь процесс, отпечаток не снят.</span>")
        return

    if(H.gloves) // повторная проверка если одели в момент перчатки.
        to_chat(user, "<span class='warning'>Пока ты возился, [H] надел перчатки!</span>")
        return

    fingerprint_data = md5(H.dna.uni_identity)
    has_print = TRUE
    icon_state = "fingerprint1"

    to_chat(user, "<span class='notice'>Ты успешно снял отпечатки пальцев с [H].</span>")
    playsound(src, 'sound/items/taperecorder/taperecorder_print.ogg', 40, FALSE)

/obj/item/forensic_card/examine(mob/user)
    . = ..()
    if(has_print)
        . += "<span class='info'>На карточке виден отпечаток с кодом: [fingerprint_data]</span>"
    else
        . += "<span class='notice'>Карточка пуста. Используй её на человеке без перчаток, чтобы снять отпечатки.</span>"
