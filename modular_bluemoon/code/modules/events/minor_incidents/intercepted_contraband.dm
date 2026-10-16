#define CONTRABAND_LEDGER_REWARD 300
/// Премия бюджету СБ, если наличные из шкатулки сданы вместе с журналом.
#define CONTRABAND_CASH_BONUS 150
#define CONTRABAND_STASH_CASH 250
#define CONTRABAND_STASH_PRY_TIME (4 SECONDS)
#define CONTRABAND_BOX_FORCE_TIME (6 SECONDS)
#define CONTRABAND_NOTE_DECODE_TIME (4 SECONDS)
#define CONTRABAND_PARCEL_OPEN_TIME (1.5 SECONDS)
#define CONTRABAND_CIPHER_SHIFT 3
#define CONTRABAND_ICON 'modular_bluemoon/icons/obj/minor_incidents/intercepted_contraband.dmi'

/datum/round_event_control/paperwork/intercepted_contraband
	name = "Intercepted Contraband"
	typepath = /datum/round_event/paperwork/intercepted_contraband
	family = "intercepted_contraband"
	min_players = 8
	var/list/parcel_areas = list(/area/cargo/storage, /area/cargo/warehouse, /area/cargo/sorting, /area/cargo/office)

/datum/round_event_control/paperwork/intercepted_contraband/New()
	description = "В грузовой отсек прилетает перехваченная посылка на имя бывшего сотрудника, уволенного три смены назад: нелетальная контрабанда и шифрованная записка о тайнике в техтоннелях. В тайнике шкатулка с [CONTRABAND_STASH_CASH] кр и журналом контрабандиста; журнал, зарегистрированный надзирателем или ГСБ на консоли записей СБ, приносит [CONTRABAND_LEDGER_REWARD] кр бюджету СБ. Если у регистрирующего при себе [CONTRABAND_STASH_CASH] кр наличными, их изымают как улику (с крупной купюры - сдача голочипом), и бюджет СБ получает ещё [CONTRABAND_CASH_BONUS] кр, иначе консоль печатает акт о несданных деньгах. На записке и шкатулке отпечатки сообщника «Г.»."
	return ..()

/datum/round_event_control/paperwork/intercepted_contraband/preflight_failure()
	if(!find_delivery_turf(parcel_areas))
		return "Нет свободного пола в грузовом отсеке."
	if(!length(find_hideouts(1)))
		return "В техтоннелях нет места для тайника."
	return null

/datum/round_event/paperwork/intercepted_contraband
	var/smuggler_name
	var/parcel_area_name

/datum/round_event/paperwork/intercepted_contraband/start()
	var/datum/round_event_control/paperwork/intercepted_contraband/contraband = control
	var/turf/drop_spot = contraband.find_delivery_turf(contraband.parcel_areas)
	var/list/hideouts = contraband.find_hideouts(1)
	if(!drop_spot || !length(hideouts))
		return
	var/turf/hideout = hideouts[1]
	smuggler_name = generate_smuggler_name()
	new /obj/structure/smuggler_stash(hideout, smuggler_name)
	var/obj/item/smuggler_parcel/parcel = new(null, smuggler_name, describe_hideout(hideout))
	deliver(drop_spot, list(parcel))
	parcel_area_name = get_area_name(drop_spot)
	log_game("DIRECTOR: [control.name], посылка на имя [smuggler_name] в [parcel_area_name], тайник в [AREACOORD(hideout)].")

/datum/round_event/paperwork/intercepted_contraband/announce(fake)
	if(!parcel_area_name)
		return
	priority_announce("Таможенный пост перехватил посылку на имя бывшего сотрудника станции [smuggler_name], уволенного три смены назад. Посылка опечатана и доставлена в отсек [parcel_area_name] для досмотра. Найденные записи о контрабанде передайте надзирателю или главе службы безопасности.", "Таможенная служба NanoTrasen")
	paperwork_radio("Ориентировка таможни: [smuggler_name], бывший сотрудник станции, уволенный три смены назад, подозревается в контрабанде. Перехваченная посылка в отсеке [parcel_area_name]; по данным таможни, в техтоннелях остался тайник. Журнал контрабандиста регистрирует надзиратель или ГСБ на консоли записей СБ: бюджету СБ положено [CONTRABAND_LEDGER_REWARD] кр и ещё [CONTRABAND_CASH_BONUS] кр, если вместе с журналом сданы наличные из тайника - [CONTRABAND_STASH_CASH] кр.", RADIO_CHANNEL_SECURITY)

/// Вымышленное имя, которого нет у живого экипажа.
/proc/generate_smuggler_name()
	var/list/taken = list()
	for(var/mob/living/carbon/human/crew as anything in GLOB.human_list)
		if(crew.real_name)
			taken[crew.real_name] = TRUE
	for(var/attempt in 1 to 10)
		var/list/first_names = pick(GLOB.first_names_male, GLOB.first_names_female)
		var/candidate = "[pick(first_names)] [pick(GLOB.last_names)]"
		if(!taken[candidate])
			return candidate
	return "Gregor Vossberg"

/// Отпечаток вымышленного сообщника «Г.»: один и тот же на записке, посылке, шкатулке и журнале одного контрабандиста.
/proc/smuggler_accomplice_print(smuggler_name)
	return md5("[smuggler_name] Г.")

/proc/leave_smuggler_accomplice_print(atom/target, smuggler_name)
	var/accomplice_print = smuggler_accomplice_print(smuggler_name)
	LAZYINITLIST(target.fingerprints)
	target.fingerprints[accomplice_print] = accomplice_print

/// Сдвиг букв по кругу алфавита, кириллица и латиница отдельно.
/proc/smuggler_cipher(text, shift)
	var/static/list/alphabets = list(
		"абвгдеёжзийклмнопрстуфхцчшщъыьэюя",
		"АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ",
		"abcdefghijklmnopqrstuvwxyz",
		"ABCDEFGHIJKLMNOPQRSTUVWXYZ",
	)
	var/list/result = list()
	for(var/position in 1 to length_char(text))
		var/symbol = copytext_char(text, position, position + 1)
		for(var/alphabet in alphabets)
			var/index = findtextEx_char(alphabet, symbol)
			if(!index)
				continue
			var/size = length_char(alphabet)
			var/shifted = (((index - 1 + shift) % size) + size) % size + 1
			symbol = copytext_char(alphabet, shifted, shifted + 1)
			break
		result += symbol
	return jointext(result, "")

/obj/item/smuggler_parcel
	name = "sealed parcel"
	desc = "Плотный свёрток в коричневой бумаге, перетянутый лентой таможенного поста NanoTrasen со штампом «ПЕРЕХВАЧЕНО»."
	icon = CONTRABAND_ICON
	icon_state = "parcel"
	item_state = "syringe_kit"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	w_class = WEIGHT_CLASS_NORMAL
	var/recipient_name

/obj/item/smuggler_parcel/Initialize(mapload, recipient, hideout_hint)
	. = ..()
	recipient_name = recipient || "unknown"
	name = "sealed parcel ([recipient_name])"
	new /obj/item/storage/fancy/cigarettes/cigpack_syndicate(src)
	new /obj/item/reagent_containers/food/drinks/bottle/absinthe(src)
	new /obj/item/poster/random_contraband(src)
	var/obj/item/card/id/forged = new(src)
	forged.bank_support = ID_NO_BANK_ACCOUNT
	forged.registered_name = recipient_name
	forged.assignment = "Cargo Technician"
	forged.update_label()
	forged.desc = "Поддельная ID-карта: голограмма смазана, чип пустой, доступов нет."
	var/obj/item/paper/smuggler_note/note = new(src, recipient_name, hideout_hint)
	leave_smuggler_accomplice_print(note, recipient_name)
	leave_smuggler_accomplice_print(src, recipient_name)

/obj/item/smuggler_parcel/examine(mob/user)
	. = ..()
	. += span_notice("Получатель: [recipient_name]. Ленту можно сорвать, взяв посылку в руку и использовав её.")

/obj/item/smuggler_parcel/attack_self(mob/user)
	to_chat(user, span_notice("Вы срываете таможенную ленту..."))
	if(!do_after(user, CONTRABAND_PARCEL_OPEN_TIME, user))
		return
	unwrap(user)

/obj/item/smuggler_parcel/proc/unwrap(mob/user)
	var/turf/spot = get_turf(src)
	if(user)
		user.temporarilyRemoveItemFromInventory(src, TRUE)
	for(var/obj/item/content as anything in contents)
		content.forceMove(spot)
		user?.put_in_hands(content)
	playsound(spot, 'sound/items/poster_ripped.ogg', 50, TRUE)
	new /obj/effect/decal/cleanable/wrapping(spot)
	log_game("DIRECTOR: Intercepted Contraband, [key_name(user)] вскрыл посылку на имя [recipient_name] в [AREACOORD(spot)].")
	qdel(src)

/obj/item/paper/smuggler_note
	name = "paper - 'coded note'"
	icon_state = "scrap"
	show_written_words = FALSE
	var/plain_text
	var/decoded = FALSE

/obj/item/paper/smuggler_note/Initialize(mapload, recipient, hideout_hint)
	plain_text = "[recipient || "Друг"], груз забрали, остаток не сдан. Тайник: [hideout_hint || "там, где договаривались"]. Плитку поддень ломом. Шкатулку без меня не вскрывай. Г."
	. = ..()
	add_raw_text(smuggler_cipher(plain_text, CONTRABAND_CIPHER_SHIFT))
	update_appearance()

/obj/item/paper/smuggler_note/examine(mob/user)
	. = ..()
	if(!decoded)
		. += span_notice("Буквы сдвинуты простым шифром. Если посидеть над запиской с ручкой, шифр поддастся.")

/obj/item/paper/smuggler_note/attackby(obj/item/item, mob/living/user, params)
	if(decoded || !istype(item, /obj/item/pen))
		return ..()
	to_chat(user, span_notice("Вы выписываете буквы столбиком и подбираете сдвиг..."))
	if(do_after(user, CONTRABAND_NOTE_DECODE_TIME, src))
		decode(user)
	return TRUE

/obj/item/paper/smuggler_note/proc/decode(mob/user)
	if(decoded)
		return FALSE
	decoded = TRUE
	clear_paper()
	add_raw_text(plain_text)
	name = "paper - 'decoded note'"
	update_appearance()
	update_static_data_for_all_viewers()
	if(user)
		to_chat(user, span_notice("Шифр поддался: каждая буква сдвинута на [CONTRABAND_CIPHER_SHIFT] вперёд по алфавиту."))
	return TRUE

/// Тайная плитка в техтоннелях. Издали не отличить от пола, вблизи виден поддетый край.
/obj/structure/smuggler_stash
	name = "floor"
	desc = "Обычная плитка пола."
	icon = CONTRABAND_ICON
	icon_state = "stash"
	anchored = TRUE
	density = FALSE
	plane = FLOOR_PLANE
	layer = ABOVE_OPEN_TURF_LAYER
	// Рисунок почти прозрачен, а клик по этой клетке должен попадать в тайник, а не в пол.
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	var/opened = FALSE

/obj/structure/smuggler_stash/Initialize(mapload, owner_name)
	. = ..()
	var/obj/item/storage/lockbox/smuggler/box = new(src)
	leave_smuggler_accomplice_print(box, owner_name)
	var/obj/item/smuggler_ledger/ledger = locate() in box
	if(!ledger)
		return
	ledger.smuggler_name = owner_name
	leave_smuggler_accomplice_print(ledger, owner_name)

/obj/structure/smuggler_stash/Destroy()
	var/turf/spot = get_turf(src)
	for(var/atom/movable/content as anything in contents)
		if(spot)
			content.forceMove(spot)
		else
			qdel(content)
	return ..()

/obj/structure/smuggler_stash/examine(mob/user)
	. = ..()
	if(opened)
		return
	if(get_dist(user, src) <= 1)
		. += span_notice("Край этой плитки чуть приподнят, швы вокруг недавно вычищены. Похоже, её можно поддеть ломом.")

/obj/structure/smuggler_stash/crowbar_act(mob/living/user, obj/item/tool)
	if(opened)
		to_chat(user, span_notice("Ниша под плиткой уже пуста."))
		return TRUE
	to_chat(user, span_notice("Вы поддеваете край плитки..."))
	if(tool.use_tool(src, user, CONTRABAND_STASH_PRY_TIME, volume = 50))
		open_stash(user)
	return TRUE

/obj/structure/smuggler_stash/proc/open_stash(mob/user)
	if(opened)
		return FALSE
	opened = TRUE
	name = "loose floor panel"
	desc = "Снятая плитка пола, под ней тесная ниша."
	icon_state = "stash_open"
	mouse_opacity = MOUSE_OPACITY_ICON
	for(var/atom/movable/content as anything in contents)
		content.forceMove(loc)
	if(user)
		user.visible_message(span_notice("[user] поддевает плитку пола: под ней тайник."), span_notice("Плитка поддаётся. Под ней тесная ниша со шкатулкой."))
	log_game("DIRECTOR: Intercepted Contraband, [key_name(user)] вскрыл тайник в [AREACOORD(src)].")
	return TRUE

/obj/item/storage/lockbox/smuggler
	name = "battered strongbox"
	desc = "Помятая стальная шкатулка с кодовым замком. Кода нет, но замок слабый: его можно сорвать ломом. Карта с доступом службы безопасности открывает его без взлома."
	req_access = list(ACCESS_SECURITY)

/obj/item/storage/lockbox/smuggler/Initialize(mapload)
	. = ..()
	LAZYINITLIST(suit_fibers)
	suit_fibers += "Волокна серых перчаток без пальцев."

/obj/item/storage/lockbox/smuggler/PopulateContents()
	new /obj/item/smuggler_ledger(src)
	new /obj/item/stack/spacecash/c200(src)
	new /obj/item/stack/spacecash/c50(src)

/obj/item/storage/lockbox/smuggler/crowbar_act(mob/living/user, obj/item/tool)
	if(broken || !SEND_SIGNAL(src, COMSIG_IS_STORAGE_LOCKED))
		return FALSE
	to_chat(user, span_notice("Вы вставляете лом под крышку шкатулки..."))
	if(tool.use_tool(src, user, CONTRABAND_BOX_FORCE_TIME, volume = 50))
		force_open(user)
	return TRUE

/obj/item/storage/lockbox/smuggler/proc/force_open(mob/user)
	if(broken)
		return FALSE
	broken = TRUE
	SEND_SIGNAL(src, COMSIG_TRY_STORAGE_SET_LOCKSTATE, FALSE)
	icon_state = icon_broken
	desc = "Помятая стальная шкатулка с сорванным замком."
	if(user)
		user.visible_message(span_notice("[user] срывает замок шкатулки."), span_notice("Замок со скрежетом поддаётся."))
	return TRUE

/obj/item/smuggler_ledger
	name = "smuggler's ledger"
	desc = "Засаленный блокнот: даты, суммы, клички и номера шлюзов. Для суда это улика. Надзиратель или глава службы безопасности может зарегистрировать его, приложив к консоли записей СБ; наличные из шкатулки, принесённые вместе с журналом, тоже идут в дело."
	icon = CONTRABAND_ICON
	icon_state = "ledger"
	item_state = "album"
	lefthand_file = 'icons/mob/inhands/misc/books_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/books_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	var/smuggler_name
	var/registered = FALSE

/obj/item/smuggler_ledger/examine(mob/user)
	. = ..()
	if(registered)
		. += span_notice("На обложке штамп СБ: журнал зарегистрирован как улика.")
		return
	if(smuggler_name)
		. += span_notice("Последняя запись: «[smuggler_name]: остаток в тайнике, [CONTRABAND_STASH_CASH] кр, не сдан. Связной - Г.».")
	. += span_notice("Если у регистрирующего при себе будут [CONTRABAND_STASH_CASH] кр наличными, консоль изымет их как деньги из шкатулки, а бюджет СБ получит ещё [CONTRABAND_CASH_BONUS] кр.")

/obj/item/smuggler_ledger/pre_attack(atom/target, mob/living/user, params, attackchain_flags, damage_multiplier)
	if(istype(target, /obj/machinery/computer/secure_data) || istype(target, /obj/machinery/computer/prisoner))
		register_evidence(target, user)
		return STOP_ATTACK_PROC_CHAIN
	return ..()

/// Купюры тайника неотличимы от своих и сливаются с ними в пачку, поэтому считается сумма купюр при регистрирующем.
/proc/smuggler_cash_on(mob/living/user)
	. = 0
	for(var/obj/item/stack/spacecash/bill in user.GetAllContents())
		. += bill.get_item_credit_value()

/// Изымает ровно amount кредитов купюрами при регистрирующем; с крупной купюры отдаёт сдачу голочипом.
/proc/smuggler_seize_cash(mob/living/user, amount)
	var/list/obj/item/stack/spacecash/bills = list()
	for(var/obj/item/stack/spacecash/bill in user.GetAllContents())
		if(bill.value > 0)
			bills += bill
	var/remaining = amount
	while(remaining > 0)
		var/obj/item/stack/spacecash/fitting
		var/obj/item/stack/spacecash/breaking
		for(var/obj/item/stack/spacecash/bill as anything in bills)
			if(QDELETED(bill))
				continue
			if(bill.value <= remaining)
				if(!fitting || bill.value > fitting.value)
					fitting = bill
			else if(!breaking || bill.value < breaking.value)
				breaking = bill
		if(fitting)
			var/count = min(fitting.amount, round(remaining / fitting.value))
			remaining -= count * fitting.value
			fitting.use(count)
			continue
		if(!breaking)
			return FALSE
		var/change = breaking.value - remaining
		breaking.use(1)
		remaining = 0
		var/obj/item/holochip/change_chip = new(user.drop_location(), change)
		user.put_in_hands(change_chip)
	return TRUE

/obj/item/smuggler_ledger/proc/register_evidence(obj/machinery/computer/console, mob/living/user)
	if(registered)
		to_chat(user, span_notice("Журнал уже зарегистрирован как улика."))
		return FALSE
	if(console.machine_stat & (NOPOWER|BROKEN))
		to_chat(user, span_warning("[console] не отвечает."))
		return FALSE
	var/obj/item/card/id/card = user.get_idcard(TRUE)
	if(!card || !(ACCESS_ARMORY in card.GetAccess()))
		playsound(console, 'sound/machines/terminal_prompt_deny.ogg', 30, FALSE)
		to_chat(user, span_warning("Улику регистрирует надзиратель или глава службы безопасности: нужна ID-карта с доступом к арсеналу."))
		return FALSE
	registered = TRUE
	var/handed_cash = min(smuggler_cash_on(user), CONTRABAND_STASH_CASH)
	var/cash_complete = handed_cash >= CONTRABAND_STASH_CASH && smuggler_seize_cash(user, CONTRABAND_STASH_CASH)
	var/payout = CONTRABAND_LEDGER_REWARD
	var/cash_line
	if(cash_complete)
		payout += CONTRABAND_CASH_BONUS
		cash_line = "Наличные из тайника, [CONTRABAND_STASH_CASH] кр по журналу, изъяты и приобщены к делу."
	else
		cash_line = "Наличные из тайника не сданы: по журналу в шкатулке оставалось [CONTRABAND_STASH_CASH] кр[handed_cash ? ", при журнале только [handed_cash] кр" : ""]."
	var/datum/bank_account/budget = SSeconomy.get_dep_account(ACCOUNT_SEC)
	budget?.adjust_money(payout, "ЦК: вознаграждение за журнал контрабандиста")
	playsound(console, 'sound/machines/terminal_success.ogg', 40, FALSE)
	console.say("Журнал контрабандиста зарегистрирован как улика. Бюджету службы безопасности начислено [payout] кр.[cash_complete ? "" : " Наличные из тайника не сданы."]")
	paperwork_print(console.drop_location(), "paper - 'Evidence Receipt'", "<center><b>СЛУЖБА БЕЗОПАСНОСТИ</b><br>Акт приёма улик</center><br>Журнал контрабандиста [smuggler_name || "без имени"] зарегистрирован как улика. Принял: [user.real_name].<br>[cash_line]<br>Бюджету службы безопасности начислено [payout] кр.")
	log_game("DIRECTOR: Intercepted Contraband решено: [key_name(user)] зарегистрировал журнал на [console] в [AREACOORD(console)], наличных сдано [handed_cash] из [CONTRABAND_STASH_CASH] кр, бюджету СБ начислено [payout] кр.")
	return TRUE

#undef CONTRABAND_LEDGER_REWARD
#undef CONTRABAND_CASH_BONUS
#undef CONTRABAND_STASH_CASH
#undef CONTRABAND_STASH_PRY_TIME
#undef CONTRABAND_BOX_FORCE_TIME
#undef CONTRABAND_NOTE_DECODE_TIME
#undef CONTRABAND_PARCEL_OPEN_TIME
#undef CONTRABAND_CIPHER_SHIFT
#undef CONTRABAND_ICON
