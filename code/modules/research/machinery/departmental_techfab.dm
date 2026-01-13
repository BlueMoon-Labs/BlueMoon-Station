/obj/machinery/rnd/production/techfab/department
	name = "department techfab"
	desc = "Продвинутый фабрикатор для распечатки новейших прототипов и схем, исследованных в НИО. \
	Оборудован комплектующими для синхронизации с научной сетью. Этот фабрикатор принадлежит конкретному отделу и имеет ограниченный набор расшифровочных ключей."
	icon_state = "protolathe"
	circuit = /obj/item/circuitboard/machine/techfab/department

/obj/machinery/rnd/production/techfab/department/engineering
	name = "department techfab (Engineering)"
	allowed_department_flags = DEPARTMENTAL_FLAG_ALL|DEPARTMENTAL_FLAG_ENGINEERING
	department_tag = "Engineering"
	stripe_color = "#EFB341"
	circuit = /obj/item/circuitboard/machine/techfab/department/engineering

/obj/machinery/rnd/production/techfab/department/service
	name = "department techfab (Service)"
	allowed_department_flags = DEPARTMENTAL_FLAG_ALL|DEPARTMENTAL_FLAG_SERVICE
	department_tag = "Service"
	stripe_color = "#83ca41"
	circuit = /obj/item/circuitboard/machine/techfab/department/service

/obj/machinery/rnd/production/techfab/department/medical
	name = "department techfab (Medical)"
	allowed_department_flags = DEPARTMENTAL_FLAG_ALL|DEPARTMENTAL_FLAG_MEDICAL
	department_tag = "Medical"
	stripe_color = "#52B4E9"
	circuit = /obj/item/circuitboard/machine/techfab/department/medical

/obj/machinery/rnd/production/techfab/department/cargo
	name = "department techfab (Cargo)"
	allowed_department_flags = DEPARTMENTAL_FLAG_ALL|DEPARTMENTAL_FLAG_CARGO
	department_tag = "Cargo"
	stripe_color = "#956929"
	circuit = /obj/item/circuitboard/machine/techfab/department/cargo

/obj/machinery/rnd/production/techfab/department/science
	name = "department techfab (Science)"
	allowed_department_flags = DEPARTMENTAL_FLAG_ALL|DEPARTMENTAL_FLAG_SCIENCE
	department_tag = "Science"
	stripe_color = "#D381C9"
	circuit = /obj/item/circuitboard/machine/techfab/department/science

/obj/machinery/rnd/production/techfab/department/security
	name = "department techfab (Security)"
	allowed_department_flags = DEPARTMENTAL_FLAG_ALL|DEPARTMENTAL_FLAG_SECURITY
	department_tag = "Security"
	stripe_color = "#DE3A3A"
	circuit = /obj/item/circuitboard/machine/techfab/department/security
	lathe_prod_time = 0.75
