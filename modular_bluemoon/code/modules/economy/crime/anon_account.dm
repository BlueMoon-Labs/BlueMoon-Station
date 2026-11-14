GLOBAL_VAR_INIT(econ_anon_account_counter, 100)

/// Счёт без имени владельца и вне манифеста: сам по себе не получает выплат экипажу, снятие наличных с него помечается аудитом.
/datum/bank_account/anonymous
	offstation = TRUE

/datum/bank_account/anonymous/New(newname, job)
	..("Анонимный счёт №[++GLOB.econ_anon_account_counter]")

/// Любое снятие наличных с анонимного счёта - дело аудита с местом снятия.
/datum/controller/subsystem/economy/proc/note_anon_cashout(datum/bank_account/source, amount, reason, mob/actor)
	if(reason != ECON_CASH_OUT || !istype(source, /datum/bank_account/anonymous))
		return
	var/place = actor ? get_area_name(actor) : "место неизвестно"
	var/datum/econ_audit_flag/flag = add_audit_flag(source, AUDIT_FLAG_ANON_CASHOUT, "Снятие наличных с анонимного счёта: [place]", amount, null, actor)
	if(!findtext(flag.text, place))
		flag.text += ", [place]"

/obj/item/anon_account_card
	name = "prepaid payment card"
	desc = "Безымянная платёжная карта со своим банковским счётом."
	icon = 'icons/obj/economy/items.dmi'
	icon_state = "anon_card"
	item_state = "anon_card"
	lefthand_file = 'icons/mob/inhands/economy_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/economy_righthand.dmi'
	w_class = WEIGHT_CLASS_TINY
	var/datum/bank_account/anonymous/account

/obj/item/anon_account_card/Initialize(mapload)
	. = ..()
	account = new
	account.bank_cards += src

/obj/item/anon_account_card/Destroy()
	if(account)
		account.bank_cards -= src
	account = null
	return ..()

/obj/item/anon_account_card/examine(mob/user)
	. = ..()
	if(!account)
		return
	. += span_notice("[account.account_holder], номер счёта [account.account_id], баланс [account.account_balance] кр.")
	. += span_notice("Счёт без имени владельца и вне манифеста экипажа: по имени его не найти, сам по себе он не получает зарплаты и выплат NT. Переводить на него и привязывать к нему ID-карту можно по номеру.")
	. += span_notice("Это не тайник: финансовый аудит видит все движения по счёту и след денег через него, а в базе счетов у ГП видны его баланс и история. Используйте карту в руке, чтобы снять наличные; каждое снятие, с этой карты или с привязанной ID-карты, попадает в аудит вместе с местом. Замороженный счёт не обналичить. Потеря карты счёт не закрывает.")

/obj/item/anon_account_card/attack_self(mob/user)
	. = ..()
	if(!account)
		return
	if(account.state == ACCOUNT_FROZEN)
		to_chat(user, span_warning("Счёт заморожен финансовым аудитом, снятие наличных закрыто."))
		return
	var/amount = tgui_input_number(user, "Сколько снять? На счёте [account.account_balance] кр.", name, 0, account.account_balance, 0, round_value = TRUE)
	if(!amount || QDELETED(src) || !user.is_holding(src))
		return
	var/obj/item/holochip/chip = cash_out(amount, user)
	if(!chip)
		to_chat(user, span_warning((account.state == ACCOUNT_FROZEN ? "Счёт заморожен финансовым аудитом, снятие наличных закрыто." : "Недостаточно средств.")))
		return
	user.put_in_hands(chip)
	to_chat(user, span_notice("Вы сняли [amount] кр. голочипом."))

/// Снять наличные голочипом у ног user; null, если банк отказал.
/obj/item/anon_account_card/proc/cash_out(amount, mob/user)
	amount = round(amount)
	if(amount < 1 || !account || !SSeconomy.move(account, SSeconomy.cash_account, amount, ECON_CASH_OUT, user))
		return null
	return new /obj/item/holochip(user ? user.drop_location() : drop_location(), amount)
