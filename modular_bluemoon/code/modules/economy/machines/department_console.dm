/obj/machinery/computer/department_budget
	name = "department budget console"
	desc = "Консоль бюджета отдела: заявки на закупку из каталога, контракты и оплаченная работа отдела. Глава отдела одобряет заявки, выписывает премии и просит деньги из казны."
	icon_screen = null
	circuit = /obj/item/circuitboard/computer/department_budget
	light_color = LIGHT_COLOR_GREEN
	/// Отдел консоли; без него консоль показывает отдел того, кто за ней
	var/department_id
	var/datum/computer_file/program/department_budget/program

/obj/machinery/computer/department_budget/Initialize(mapload, obj/item/circuitboard/C)
	. = ..()
	program = new
	program.console = src
	program.fixed_department = department_id
	var/obj/item/circuitboard/computer/department_budget/board = circuit
	if(istype(board))
		board.department_id = department_id

/obj/machinery/computer/department_budget/Destroy()
	QDEL_NULL(program)
	return ..()

/obj/machinery/computer/department_budget/on_construction()
	. = ..()
	var/obj/item/circuitboard/computer/department_budget/board = circuit
	if(istype(board))
		set_department(board.department_id)

/obj/machinery/computer/department_budget/proc/set_department(id)
	department_id = id
	program.fixed_department = id
	update_appearance()

/obj/machinery/computer/department_budget/update_overlays()
	. = ..()
	if(machine_stat & (NOPOWER|BROKEN))
		return
	var/screen = "screen_[department_id ? lowertext(department_id) : "any"]"
	. += mutable_appearance('icons/obj/machines/economy/department_console.dmi', screen)
	. += emissive_appearance('icons/obj/machines/economy/department_console.dmi', screen, offset_spokesman = src)

/obj/machinery/computer/department_budget/examine(mob/user)
	. = ..()
	var/datum/economy_department/department = SSeconomy.get_department(department_id)
	. += span_notice((department ? "Привязана к отделу «[department.name]». Права главы проверяются как обычно: глав и капитана узнают по доступу ID-карты, ГП - по должности и доступу ГП на карте." : "Не привязана к отделу: показывает отдел того, кто за ней. Отдел выбирается мультитулом на плате."))

/obj/machinery/computer/department_budget/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "DepartmentConsole", name)
		ui.open()

/obj/machinery/computer/department_budget/ui_static_data(mob/user)
	return program.budget_static_data(user)

/obj/machinery/computer/department_budget/ui_data(mob/user)
	return program.budget_data(user)

/obj/machinery/computer/department_budget/ui_close(mob/user)
	. = ..()
	program.forget_user(user)

/obj/machinery/computer/department_budget/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	return program.budget_act(usr, action, params)

/obj/machinery/computer/department_budget/medical
	name = "medical budget console"
	department_id = ACCOUNT_MED

/obj/machinery/computer/department_budget/engineering
	name = "engineering budget console"
	department_id = ACCOUNT_ENG

/obj/machinery/computer/department_budget/science
	name = "science budget console"
	department_id = ACCOUNT_SCI

/obj/machinery/computer/department_budget/security
	name = "security budget console"
	department_id = ACCOUNT_SEC

/obj/machinery/computer/department_budget/service
	name = "service budget console"
	department_id = ACCOUNT_SRV

/obj/machinery/computer/department_budget/cargo
	name = "cargo budget console"
	department_id = ACCOUNT_CAR

/obj/item/circuitboard/computer/department_budget
	name = "Department Budget Console (Computer Board)"
	icon_state = "supply"
	build_path = /obj/machinery/computer/department_budget
	var/department_id

/obj/item/circuitboard/computer/department_budget/examine(mob/user)
	. = ..()
	var/datum/economy_department/department = SSeconomy.get_department(department_id)
	. += span_notice("Отдел: [department ? department.name : "по счёту пользователя"]. Мультитул переключает отдел.")

/obj/item/circuitboard/computer/department_budget/multitool_act(mob/living/user, obj/item/tool)
	. = TRUE
	var/list/choices = list(null)
	for(var/id in SSeconomy.departments)
		if(id != ACCOUNT_CMD)
			choices += id
	var/position = choices.Find(department_id)
	department_id = choices[(position % length(choices)) + 1]
	var/datum/economy_department/department = SSeconomy.get_department(department_id)
	to_chat(user, span_notice("Плата настроена: [department ? "отдел «[department.name]»" : "отдел по счёту пользователя"]."))

/datum/design/board/department_budget
	name = "Computer Design (Department Budget Console)"
	desc = "Плата консоли бюджета отдела."
	id = "department_budget"
	build_path = /obj/item/circuitboard/computer/department_budget
	category = list("Computer Boards")
	departmental_flags = DEPARTMENTAL_FLAG_ALL

/datum/techweb_node/comptech/New()
	. = ..()
	design_ids += "department_budget"
