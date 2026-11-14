#define PRINTER_TIMEOUT 10

/obj/machinery/computer/bounty
	name = "\improper Nanotrasen contract console"
	desc = "Доска контрактов NT всех отделов станции. Здесь же контракт можно взять на себя."
	icon_screen = "bounty"
	circuit = /obj/item/circuitboard/computer/bounty
	light_color = "#E2853D"//orange
	var/printer_ready = 0 //cooldown var

/obj/machinery/computer/bounty/Initialize(mapload)
	. = ..()
	printer_ready = world.time + PRINTER_TIMEOUT

/obj/machinery/computer/bounty/examine(mob/user)
	. = ..()
	. += span_notice(econ_contracts_examine_note())

/obj/machinery/computer/bounty/proc/print_paper()
	new /obj/item/paper/bounty_printout(loc)

/obj/item/paper/bounty_printout
	name = "paper - NT contracts"
	default_raw_text = "<h2>Контракты NT</h2></br>"

/obj/item/paper/bounty_printout/Initialize(mapload)
	for(var/datum/econ_contract/contract as anything in SSeconomy.all_contracts())
		if(contract.owner)
			continue
		var/list/entry = contract.ui_entry()
		default_raw_text += {"<h3>[entry["title"]] ([entry["department_name"]])</h3>
		<ul><li>Награда: [entry["reward"]] кр.</li>
		<li>Прогресс: [entry["progress"] || "-"]</li></ul>"}
	. = ..()

/obj/machinery/computer/bounty/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ContractBoard", name)
		ui.open()

/obj/machinery/computer/bounty/ui_static_data(mob/user)
	return list("mode" = "console", "contracts_help_topics" = econ_contracts_help_topics())

/obj/machinery/computer/bounty/ui_data(mob/user)
	var/list/data = list()
	var/datum/bank_account/cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	data["stored_cash"] = cargo?.account_balance
	data += econ_contracts_ui_data(user)
	return data

/obj/machinery/computer/bounty/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(econ_contract_console_act(usr, action, params, src))
		return TRUE
	switch(action)
		if("Print")
			if(printer_ready < world.time)
				printer_ready = world.time + PRINTER_TIMEOUT
				print_paper()
			return TRUE

#undef PRINTER_TIMEOUT
