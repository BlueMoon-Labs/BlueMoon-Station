/obj/machinery/rnd/production/circuit_imprinter/department
	name = "Department Circuit Imprinter"
	desc = "Специальный принтер плат со встроенным интерфейсом для использования конкретным отделом, \
	и встроеннымыми приёмниками ExoSync для распечатки исследованных проектов, совместимых с ROM-закодированным типом отделения."
	icon_state = "circuit_imprinter"
	circuit = /obj/item/circuitboard/machine/circuit_imprinter/department
	requires_console = FALSE

/obj/machinery/rnd/production/circuit_imprinter/department/science
	name = "Department Circuit Imprinter (Science)"
	circuit = /obj/item/circuitboard/machine/circuit_imprinter/department/science
	allowed_department_flags = DEPARTMENTAL_FLAG_ALL|DEPARTMENTAL_FLAG_SCIENCE
	req_one_access = list(ACCESS_RESEARCH, ACCESS_AWAY_GENERAL, ACCESS_SYNDICATE)
	department_tag = "Science"
