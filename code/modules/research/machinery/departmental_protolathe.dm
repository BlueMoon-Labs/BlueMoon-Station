/obj/machinery/rnd/production/protolathe/department
	name = "Department Protolathe"
	desc = "Специальный протолат со встроенным интерфейсом для использования конкретным отделом, \
	и встроеннымыми приёмниками ExoSync для распечатки исследованных проектов, совместимых с ROM-закодированным типом отделения."
	icon_state = "protolathe"
	circuit = /obj/item/circuitboard/machine/protolathe/department
	requires_console = FALSE

/obj/machinery/rnd/production/protolathe/department/engineering
	name = "Department Protolathe (Engineering)"
	allowed_department_flags = DEPARTMENTAL_FLAG_ALL|DEPARTMENTAL_FLAG_ENGINEERING
	department_tag = "Engineering"
	stripe_color = "#EFB341"
	circuit = /obj/item/circuitboard/machine/protolathe/department/engineering

/obj/machinery/rnd/production/protolathe/department/service
	name = "Department Protolathe (Service)"
	allowed_department_flags = DEPARTMENTAL_FLAG_ALL|DEPARTMENTAL_FLAG_SERVICE
	department_tag = "Service"
	stripe_color = "#83ca41"
	circuit = /obj/item/circuitboard/machine/protolathe/department/service

/obj/machinery/rnd/production/protolathe/department/medical
	name = "Department Protolathe (Medical)"
	allowed_department_flags = DEPARTMENTAL_FLAG_ALL|DEPARTMENTAL_FLAG_MEDICAL
	department_tag = "Medical"
	stripe_color = "#52B4E9"
	circuit = /obj/item/circuitboard/machine/protolathe/department/medical

/obj/machinery/rnd/production/protolathe/department/cargo
	name = "Department Protolathe (Cargo)"
	allowed_department_flags = DEPARTMENTAL_FLAG_ALL|DEPARTMENTAL_FLAG_CARGO
	department_tag = "Cargo"
	stripe_color = "#956929"
	circuit = /obj/item/circuitboard/machine/protolathe/department/cargo

/obj/machinery/rnd/production/protolathe/department/science
	name = "Department Protolathe (Science)"
	allowed_department_flags = DEPARTMENTAL_FLAG_ALL|DEPARTMENTAL_FLAG_SCIENCE
	department_tag = "Science"
	stripe_color = "#D381C9"
	circuit = /obj/item/circuitboard/machine/protolathe/department/science

/obj/machinery/rnd/production/protolathe/department/security
	name = "Department Protolathe (Security)"
	allowed_department_flags = DEPARTMENTAL_FLAG_ALL|DEPARTMENTAL_FLAG_SECURITY
	department_tag = "Security"
	stripe_color = "#DE3A3A"
	circuit = /obj/item/circuitboard/machine/protolathe/department/security
