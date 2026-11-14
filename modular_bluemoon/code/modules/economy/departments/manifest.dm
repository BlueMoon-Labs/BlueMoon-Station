/obj/item/export_manifest
	name = "export manifest"
	desc = "Экспортная накладная отдела. Положите её в любой ящик, даже снабжения, перед отгрузкой шаттлом: выручка за этот ящик уйдёт отделу за вычетом сбора снабжения. На закрытом ящике с накладной видна бирка отдела, с накладной спецзаказа - бирка спецзаказа."
	icon = 'icons/obj/economy/items.dmi'
	icon_state = "manifest"
	item_state = "manifest"
	lefthand_file = 'icons/mob/inhands/economy_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/economy_righthand.dmi'
	w_class = WEIGHT_CLASS_TINY
	resistance_flags = FLAMMABLE
	var/department_id
	var/special_offer_id

/obj/item/export_manifest/Initialize(mapload)
	. = ..()
	update_appearance()

/obj/item/export_manifest/update_icon_state()
	icon_state = special_offer_id ? "manifest_special" : "manifest"
	return ..()

/obj/item/export_manifest/Moved(atom/OldLoc, Dir, Forced = FALSE)
	. = ..()
	if(istype(OldLoc, /obj/structure/closet/crate))
		UnregisterSignal(OldLoc, COMSIG_ATOM_UPDATE_OVERLAYS)
		OldLoc.update_appearance(UPDATE_OVERLAYS)
	if(istype(loc, /obj/structure/closet/crate))
		RegisterSignal(loc, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(on_crate_overlays))
		loc.update_appearance(UPDATE_OVERLAYS)

/obj/item/export_manifest/Destroy()
	var/obj/structure/closet/crate/crate = loc
	if(istype(crate))
		UnregisterSignal(crate, COMSIG_ATOM_UPDATE_OVERLAYS)
	. = ..()
	if(istype(crate) && !QDELETED(crate))
		crate.update_appearance(UPDATE_OVERLAYS)

/// Бирка на закрытом ящике: от накладной спецзаказа, иначе от накладной отдела, по которой ящик и продастся.
/obj/item/export_manifest/proc/on_crate_overlays(obj/structure/closet/crate/source, list/new_overlays)
	SIGNAL_HANDLER
	if(source.opened || econ_crate_label_manifest(source) != src)
		return
	if(!special_offer_id && !department_id)
		return
	var/label = special_offer_id ? "label_special" : "label_[lowertext(department_id)]"
	new_overlays += mutable_appearance('icons/obj/economy/crate_labels.dmi', label, FLOAT_LAYER + 0.01)

/proc/econ_crate_label_manifest(atom/movable/crate)
	for(var/obj/item/export_manifest/manifest in crate)
		if(manifest.special_offer_id)
			return manifest
	return econ_crate_manifest(crate)

/obj/item/export_manifest/examine(mob/user)
	. = ..()
	if(special_offer_id)
		var/datum/market_offer/offer = SSmarket.offer_by_uid(special_offer_id)
		. += offer ? span_notice(offer.manifest_text()) : span_warning("Спецзаказ по этой накладной закрыт: ящик продастся обычным порядком.")
		return
	var/datum/economy_department/department = SSeconomy.get_department(department_id)
	if(department)
		. += span_notice("Отправитель: [department.name]. Сбор снабжения: [SSeconomy.settings.cargo_handling_fee]% выручки ящика.")

/datum/economy_department/proc/print_manifest(atom/where, mob/user)
	var/obj/item/export_manifest/manifest = new(where)
	manifest.department_id = id
	manifest.name = "export manifest ([name])"
	if(user)
		log_econ("[key_name(user)] получил экспортную накладную отдела [name]")
	return manifest

/// Отдел, на который пользователь может выписать накладную: свой отдел, кроме самого снабжения.
/proc/econ_manifest_department_for(mob/user)
	var/datum/bank_account/account = econ_account_of(user)
	if(!account?.department_id || account.department_id == ACCOUNT_CAR)
		return null
	return SSeconomy.get_department(account.department_id)

/datum/bank_account
	COOLDOWN_DECLARE(manifest_print_cooldown)
	COOLDOWN_DECLARE(contract_drop_cooldown)

/// Печать накладной с консоли: свой отдел, кулдаун по счёту сотрудника, а не по консоли.
/proc/econ_print_manifest(mob/user, obj/machinery/printer)
	var/datum/economy_department/department = econ_manifest_department_for(user)
	if(!department)
		printer.say("Экспортные накладные выдаются сотрудникам отделов станции, кроме снабжения.")
		return null
	var/datum/bank_account/account = econ_account_of(user)
	if(!COOLDOWN_FINISHED(account, manifest_print_cooldown))
		to_chat(user, span_warning("Накладную можно печатать не чаще раза в [DisplayTimeText(ECON_MANIFEST_PRINT_COOLDOWN)]."))
		return null
	COOLDOWN_START(account, manifest_print_cooldown, ECON_MANIFEST_PRINT_COOLDOWN)
	playsound(printer, 'sound/effects/printer.ogg', 50, FALSE)
	var/obj/item/export_manifest/manifest = department.print_manifest(printer.drop_location(), user)
	user.put_in_hands(manifest)
	return manifest

/// Накладная отдела в ящике; накладная спецзаказа отделом не считается.
/proc/econ_crate_manifest(atom/movable/crate)
	for(var/obj/item/export_manifest/manifest in crate)
		if(!manifest.special_offer_id)
			return manifest

/// Спецзаказ по накладной в ящике; в ящике учитывается только один, о лишних накладных - строка в отчёт.
/proc/econ_crate_offer(atom/movable/crate, datum/export_report/report)
	var/offer_manifests = 0
	for(var/obj/item/export_manifest/manifest in crate)
		if(!manifest.special_offer_id)
			continue
		offer_manifests++
		var/datum/market_offer/offer = SSmarket.offer_by_uid(manifest.special_offer_id)
		if(offer && !.)
			. = offer
	if(offer_manifests > 1)
		report?.offer_notes += "В ящике учитывается только один спецзаказ, остальные накладные спецзаказов в нём не действуют."

/proc/econ_export_report_value(datum/export_report/report)
	. = 0
	for(var/datum/export/export as anything in report.total_value)
		. += report.total_value[export]
	for(var/reagent_name in report.reagents_value)
		. += report.reagents_value[reagent_name]

/// Продаёт ящик со всем содержимым и раскладывает выручку. Сначала таможенный досмотр, затем спецзаказ по накладной забирает своё. department_shares собирает доли отделов по имени.
/proc/econ_sell_crate(atom/movable/crate, datum/export_report/report, allowed_categories = EXPORT_CARGO, list/department_shares)
	. = 0
	var/list/released = list()
	econ_customs_scan(crate, report, released)
	if(QDELETED(crate))
		for(var/atom/movable/thing as anything in released)
			if(!QDELETED(thing))
				. += econ_sell_crate(thing, report, allowed_categories, department_shares)
		return
	var/obj/item/export_manifest/manifest = econ_crate_manifest(crate)
	var/datum/economy_department/department = manifest ? SSeconomy.get_department(manifest.department_id) : null
	var/datum/market_offer/offer = econ_crate_offer(crate, report)
	if(offer)
		var/offer_memo = "Спецзаказ: [offer.partner_name()]"
		. += econ_pay_crate(round(offer.deliver(crate, report, allowed_categories)), department, offer_memo, department_shares)
		. += offer.margin_paid
	var/before = econ_export_report_value(report)
	export_item_and_contents(crate, allowed_categories, dry_run = FALSE, external_report = report)
	. += econ_pay_crate(round(econ_export_report_value(report) - before), department, "Продажа грузов ЦК", department_shares)

/// Выручка ящика: без накладной отдела - снабжению, с ней - отделу за вычетом сбора снабжения.
/proc/econ_pay_crate(revenue, datum/economy_department/department, memo, list/department_shares)
	if(revenue <= 0)
		return 0
	var/datum/bank_account/cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	if(!department || department.id == ACCOUNT_CAR)
		cargo.credit(revenue, ECON_EXPORT, memo = memo)
		return revenue
	var/fee = round(revenue * SSeconomy.settings.cargo_handling_fee / 100)
	if(fee)
		cargo.credit(fee, ECON_HANDLING_FEE, memo = "Сбор с накладной: [department.name]")
	if(revenue > fee)
		department.account.credit(revenue - fee, ECON_EXPORT, memo = "Экспорт по накладной")
		if(department_shares)
			department_shares[department.name] += revenue - fee
	return revenue
