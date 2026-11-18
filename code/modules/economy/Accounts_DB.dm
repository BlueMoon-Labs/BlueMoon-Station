/obj/machinery/computer/account_database
	name = "treasury console"
	desc = "Консоль казны станции: налог, бюджеты отделов, запросы глав, счета экипажа и журнал денег NT. Управляют капитан и глава персонала."
	icon_screen = "vault"
	icon_keyboard = "teleport_key"
	req_one_access = list(ACCESS_HOP, ACCESS_CAPTAIN)
	circuit = /obj/item/circuitboard/computer/account_database
	light_color = LIGHT_COLOR_GREEN
	var/datum/computer_file/program/treasury/program

/obj/machinery/computer/account_database/Initialize(mapload, obj/item/circuitboard/C)
	. = ..()
	program = new
	program.console = src

/obj/machinery/computer/account_database/Destroy()
	QDEL_NULL(program)
	return ..()

/obj/machinery/computer/account_database/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TreasuryConsole", name)
		ui.open()

/obj/machinery/computer/account_database/ui_static_data(mob/user)
	return program.treasury_static_data()

/obj/machinery/computer/account_database/ui_data(mob/user)
	return program.treasury_data(user)

/obj/machinery/computer/account_database/ui_close(mob/user)
	. = ..()
	program.forget_user(user)

/obj/machinery/computer/account_database/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	return program.treasury_act(usr, action, params)

/obj/item/circuitboard/computer/account_database
	name = "Treasury Console (Computer Board)"
	icon_state = "command"
	build_path = /obj/machinery/computer/account_database
