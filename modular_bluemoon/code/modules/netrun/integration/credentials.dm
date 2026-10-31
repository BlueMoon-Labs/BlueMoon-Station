/// A copied access list is a snapshot of a real ID source, never machine requirements.
/datum/netrun_file/access
	var/list/accesses = list()

/datum/netrun_file/access/New(file_name, list/source_access)
	accesses = list()
	for(var/access in source_access)
		if(isnum(access))
			accesses |= access
	var/list/lines = list("Сохранённые учётные данные:")
	for(var/access in accesses)
		lines += "[get_access_desc(access) || "Доступ [access]"]"
	..(netrun_file_name(file_name, "credentials.access"), NETRUN_FILE_ACCESS, jointext(lines, "\n"), max(1, CEILING(length(accesses) / 10, 1)))

/datum/netrun_file/access/copy()
	var/datum/netrun_file/access/result = new(name, accesses)
	result.data_receipt = data_receipt
	return result

/datum/netrun_file/access/proc/access_for(datum/netrun_console/console)
	return accesses

/datum/netrun_file/access/ui_entry(selected_uid)
	. = ..()
	.["preview"] = "Учётные данные: [length(accesses)] доступов"

/datum/netrun_file/access/show(mob/user)
	if(!user?.client)
		return
	var/datum/browser/popup = new(user, "netrun_file_[uid]", html_encode(name), 450, 500)
	popup.set_content("<tt>[replacetext(html_encode(content), "\n", "<br>")]</tt>")
	popup.open()

/datum/netrun_file/access/Destroy()
	accesses = null
	return ..()

/// A new source explicitly publishes actual credentials; default machines publish none.
/atom/proc/netrun_credential_access()
	return null

/// Exact native ID objects, used to distinguish an operator's own removed card from loot.
/atom/proc/netrun_credential_cards()
	return list()

/mob/living/carbon/netrun_credential_cards()
	var/obj/item/card/id/card = get_idcard(FALSE)
	return card ? list(card) : list()

/obj/effect/netrun_endpoint/neural/netrun_credential_cards()
	return interface?.host_mob?.netrun_credential_cards() || list()

/obj/item/modular_computer/netrun_credential_cards()
	. = list()
	for(var/slot_id in list(MC_CARD, MC_CARD2))
		var/obj/item/computer_hardware/card_slot/slot = all_components[slot_id]
		if(istype(slot) && slot.holder == src && !QDELETED(slot.stored_card) && slot.stored_card.loc == slot)
			. |= slot.stored_card

/obj/machinery/modular_computer/netrun_credential_cards()
	return !QDELETED(cpu) && cpu.loc == src ? cpu.netrun_credential_cards() : list()

/atom/proc/netrun_credential_commands()
	return length(netrun_credential_access()) ? list("extract_credentials") : list()

/// Only physical ID-bearing carbons are a source. Silicon privileges are not an ID dump.
/mob/living/carbon/netrun_credential_access()
	if(QDELETED(src))
		return null
	var/list/carried_access = netrun_mob_access(src)
	. = carried_access.Copy()
	var/obj/item/card/id/card = get_idcard(FALSE)
	if(card)
		. |= card.GetAccess()

/mob/living/carbon/netrun_extra_commands()
	. = ..()
	. |= netrun_credential_commands()

/obj/effect/netrun_endpoint/neural/netrun_credential_access()
	var/mob/living/carbon/carrier = interface?.host_mob
	if(!istype(carrier) || QDELETED(carrier))
		return null
	return carrier.netrun_credential_access()

/obj/effect/netrun_endpoint/neural/netrun_extra_commands()
	. = ..()
	. |= netrun_credential_commands()

/// Read both real RFID slots, including the cards used by the native ID-editing program.
/obj/item/modular_computer/netrun_credential_access()
	. = list()
	for(var/slot_id in list(MC_CARD, MC_CARD2))
		var/obj/item/computer_hardware/card_slot/slot = all_components[slot_id]
		if(!istype(slot) || slot.holder != src)
			continue
		var/obj/item/card/id/card = slot.stored_card
		if(!QDELETED(card) && card.loc == slot)
			. |= card.GetAccess()

/obj/item/modular_computer/netrun_extra_commands()
	. = ..()
	. |= netrun_credential_commands()

/obj/machinery/modular_computer/netrun_credential_access()
	if(QDELETED(cpu) || cpu.loc != src)
		return null
	return cpu.netrun_credential_access()

/obj/machinery/modular_computer/netrun_extra_commands()
	. = ..()
	. |= netrun_credential_commands()

/datum/netrun_console/proc/credential_access(fresh = FALSE)
	. = list()
	for(var/datum/netrun_file/access/file as anything in all_files(fresh))
		if(istype(file) && file.kind == NETRUN_FILE_ACCESS)
			. |= file.access_for(src)

/// Native allowed() consumes only copied ID rights, never a hacked network privilege.
/mob/camera/netrun_entity/proc/on_credential_access_check(datum/source, obj/target)
	SIGNAL_HANDLER
	if(QDELETED(target) || QDELETED(console))
		return FALSE
	return target.check_access_list(console.user_access(TRUE))

/datum/netrun_command/extract_credentials
	id = "extract_credentials"
	name = "Извлечь учётные данные"
	desc = "Скопировать доступы реальной ID-карты носителя или карты, вставленной в компьютер."
	help = "Нужен ROOT к источнику. Сохраняется отдельный файл access: копия текущих ID-доступов, занимающая одну ячейку за каждые 10 доступов. Сетевая сущность использует файлы в своей памяти и подключённом шарде. Требования доступа самой машины не копируются; пустой слот не содержит учётных данных."
	access = NETRUN_ACCESS_ROOT
	trace = 8
	icon = "id-card"

/datum/netrun_command/extract_credentials/execute(datum/component/netrun_node/node, datum/netrun_console/console, arg, datum/netrun_request/request)
	var/atom/source = node.parent
	var/list/accesses = source.netrun_credential_access()
	if(!length(accesses))
		return "В источнике больше нет ID-доступов для копирования."
	var/datum/netrun_file/access/file = new("[node.address].access", accesses)
	console.stamp_data_export(file, node, "access", accesses)
	if(!length(file.accesses) || !console.store_file(file))
		qdel(file)
		return "Недостаточно памяти для сохранения учётных данных."
	console.inventory.selected_file_uid = file.uid
	return "Учётные данные сохранены: [length(file.accesses)] доступов, [file.size] ячеек."
