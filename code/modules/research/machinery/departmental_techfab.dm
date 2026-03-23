/obj/machinery/rnd/production/techfab/department
	name = "Department Techfab"
	desc = "Продвинутый фабрикатор для распечатки новейших прототипов и схем, исследованных в НИО. \
	Оборудован комплектующими для синхронизации с научной сетью. Этот фабрикатор принадлежит конкретному отделу и имеет ограниченный набор расшифровочных ключей."
	icon_state = "protolathe"
	circuit = /obj/item/circuitboard/machine/techfab/department

/obj/machinery/rnd/production/techfab/department/engineering
	name = "Department Techfab (Engineering)"
	allowed_department_flags = DEPARTMENTAL_FLAG_ALL|DEPARTMENTAL_FLAG_ENGINEERING
	req_one_access = list(ACCESS_ENGINE, ACCESS_AWAY_GENERAL, ACCESS_SYNDICATE)
	department_tag = "Engineering"
	stripe_color = "#EFB341"
	circuit = /obj/item/circuitboard/machine/techfab/department/engineering

/obj/machinery/rnd/production/techfab/department/service
	name = "Department Techfab (Service)"
	allowed_department_flags = DEPARTMENTAL_FLAG_ALL|DEPARTMENTAL_FLAG_SERVICE
	req_one_access = list(ACCESS_BAR, ACCESS_KITCHEN, ACCESS_HYDROPONICS, ACCESS_JANITOR, ACCESS_AWAY_GENERAL, ACCESS_SYNDICATE)
	department_tag = "Service"
	stripe_color = "#83ca41"
	circuit = /obj/item/circuitboard/machine/techfab/department/service

/obj/machinery/rnd/production/techfab/department/medical
	name = "Department Techfab (Medical)"
	allowed_department_flags = DEPARTMENTAL_FLAG_ALL|DEPARTMENTAL_FLAG_MEDICAL
	req_one_access = list(ACCESS_MEDICAL, ACCESS_AWAY_GENERAL, ACCESS_SYNDICATE)
	department_tag = "Medical"
	stripe_color = "#52B4E9"
	circuit = /obj/item/circuitboard/machine/techfab/department/medical

/obj/machinery/rnd/production/techfab/department/cargo
	name = "Department Techfab (Cargo)"
	allowed_department_flags = DEPARTMENTAL_FLAG_ALL|DEPARTMENTAL_FLAG_CARGO
	req_one_access = list(ACCESS_CARGO, ACCESS_MINING, ACCESS_AWAY_GENERAL, ACCESS_SYNDICATE)
	department_tag = "Cargo"
	stripe_color = "#956929"
	circuit = /obj/item/circuitboard/machine/techfab/department/cargo

/obj/machinery/rnd/production/techfab/department/science
	name = "Department Techfab (Science)"
	allowed_department_flags = DEPARTMENTAL_FLAG_ALL|DEPARTMENTAL_FLAG_SCIENCE
	req_one_access = list(ACCESS_RESEARCH, ACCESS_AWAY_GENERAL, ACCESS_SYNDICATE)
	department_tag = "Science"
	stripe_color = "#D381C9"
	circuit = /obj/item/circuitboard/machine/techfab/department/science

/obj/machinery/rnd/production/techfab/department/security
	name = "Department Techfab (Security)"
	allowed_department_flags = DEPARTMENTAL_FLAG_ALL|DEPARTMENTAL_FLAG_SECURITY
	req_one_access = list(ACCESS_SECURITY, ACCESS_AWAY_GENERAL, ACCESS_SYNDICATE)
	department_tag = "Security"
	stripe_color = "#DE3A3A"
	circuit = /obj/item/circuitboard/machine/techfab/department/security
	lathe_prod_time = 0.75
