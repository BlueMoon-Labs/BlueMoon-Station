/obj/machinery/rnd/production/circuit_imprinter/department
	name = "department circuit imprinter"
	desc = "Специальный принтер плат со встроенным интерфейсом для использования конкретным отделом, \
	и встроеннымыми приёмниками ExoSync для распечатки исследованных проектов, совместимых с ROM-закодированным типом отделения."
	icon_state = "circuit_imprinter"
	circuit = /obj/item/circuitboard/machine/circuit_imprinter/department
	requires_console = FALSE

/obj/machinery/rnd/production/circuit_imprinter/department/science
	name = "department circuit imprinter (Science)"
	circuit = /obj/item/circuitboard/machine/circuit_imprinter/department/science
	allowed_department_flags = DEPARTMENTAL_FLAG_ALL|DEPARTMENTAL_FLAG_SCIENCE
	department_tag = "Science"
