/obj/item/export_scanner
	name = "export scanner"
	desc = "Сканер экспорта: показывает, сколько NT сейчас заплатит за предмет или ящик по рынку и покупателю, вместе с реагентами и содержимым. Сначала привяжите его к консоли снабжения, ударив по ней сканером."
	icon = 'icons/obj/device.dmi'
	icon_state = "export_scanner"
	item_state = "radio"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	item_flags = NOBLUDGEON
	w_class = WEIGHT_CLASS_SMALL
	siemens_coefficient = 1
	var/obj/machinery/computer/cargo/cargo_console = null

/obj/item/export_scanner/examine(user)
	. = ..()
	if(!cargo_console)
		. += span_notice("Сканер не привязан к консоли снабжения.")
	. += span_notice("Купленное через снабжение или в торговом автомате NT выкупает не дороже [round(econ_import_resale_factor() * 100)]% базовой цены, собранное на станции - не дороже его материалов. Контрабанду NT не покупает.")

/// Что будет с контрабандой в грузе шаттла привязанной консоли.
/obj/item/export_scanner/proc/contraband_warning()
	var/buyer_note = cargo_console?.has_contraband_permit() && SSmarket.contraband_buyer() ? "её купят Вольные торговцы: шаттл этой консоли идёт с допуском контрабанды" : "она вернётся шаттлом"
	return "В грузе контрабанда Синдиката: NT её не покупает, [buyer_note], а таможня NT может её изъять и оштрафовать отдел накладной ящика или снабжение."

/obj/item/export_scanner/afterattack(obj/O, mob/user, proximity)
	. = ..()
	if(!istype(O) || !proximity)
		return

	if(istype(O, /obj/machinery/computer/cargo))
		var/obj/machinery/computer/cargo/C = O
		if(!C.requestonly)
			cargo_console = C
			to_chat(user, span_notice("Сканер привязан к [C]."))
	else if(!istype(cargo_console))
		to_chat(user, span_warning("Сначала привяжите [src] к консоли снабжения."))
	else
		// Before you fix it:
		// yes, checking manifests is a part of intended functionality.

		var/datum/export_report/ex = export_item_and_contents(O, cargo_console.get_export_categories(), dry_run=TRUE)
		var/price = 0
		for(var/x in ex.total_amount)
			price += ex.total_value[x]
		for(var/x in ex.reagents_value)
			price += ex.reagents_value[x]

		if(price)
			to_chat(user, span_notice("[O]: NT заплатит <b>[price]</b> кр.[O.contents.len ? " вместе с содержимым" : ""]."))
		else
			to_chat(user, span_warning("[O]: NT за это ничего не заплатит."))
		if(O.econ_vended)
			to_chat(user, span_notice("Товар куплен: NT заплатит за [O] не больше [econ_cap_value(O.econ_print_cap)] кр., реагенты из покупки не оплачиваются, контракты NT покупку не засчитывают."))
		else if(islist(O.econ_print_cap))
			to_chat(user, span_notice("Собрано на станции: NT заплатит за [O] не больше цены его материалов или деталей - [econ_cap_value(O.econ_print_cap)] кр., содержимое оплачивается отдельно."))
		for(var/atom/movable/thing as anything in O.GetAllContents())
			if(thing.econ_imported)
				to_chat(user, span_notice("Часть груза куплена через снабжение: NT выкупает её не дороже [round(econ_import_resale_factor() * 100)]% базовой цены, цена выше уже учитывает это. Ящик - залог, возвращается полностью."))
				break
		for(var/obj/item/thing in O.GetAllContents())
			if(econ_is_contraband(thing))
				to_chat(user, span_warning(contraband_warning()))
				break
