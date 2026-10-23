GLOBAL_LIST_INIT(nifsoft_catalog, list(
	/datum/nifsoft/scryer,
	/datum/nifsoft/money_sense,
	/datum/nifsoft/action_granter/shapeshifter,
	/datum/nifsoft/action_granter/hypnosis,
	/datum/nifsoft/hud/job/medical,
	/datum/nifsoft/hud/job/security,
	/datum/nifsoft/hud/job/diagnostic,
	/datum/nifsoft/hud/job/science,
	/datum/nifsoft/hud/job/meson,
	/datum/nifsoft/summoner,
	/datum/nifsoft/summoner/book,
	/datum/nifsoft/summoner/dorms,
	/datum/nifsoft/summoner/job/tools,
	/datum/nifsoft/summoner/job/service,
	/datum/nifsoft/summoner/job/surgery,
	/datum/nifsoft/summoner/job/detective,
	/datum/nifsoft/soul_poem,
))

/obj/item/organ/cyberimp/brain/nif/proc/installation_error(program_type)
	if(!ispath(program_type, /datum/nifsoft))
		return "Неизвестная программа."
	if(!linked_mob || owner != linked_mob)
		return "Имплант не установлен."
	if(broken || durability <= 0)
		return "Сначала восстановите имплант."
	if(length(loaded_nifsofts) >= max_nifsofts)
		return "Нет свободных слотов."
	var/datum/nifsoft/program = program_type
	if(!istype(src, initial(program.compatible_nif)))
		return "Несовместимо с этой моделью NIF."
	for(var/datum/nifsoft/installed in loaded_nifsofts)
		if(installed.type == program_type)
			return "Уже установлено."
		if(initial(program.exclusive_group) && istype(installed, initial(program.exclusive_group)))
			return "Несовместимо с [installed.name]."
		if(installed.exclusive_group && ispath(program_type, installed.exclusive_group))
			return "Несовместимо с [installed.name]."
	return null

/obj/item/organ/cyberimp/brain/nif/proc/program_catalog()
	var/list/catalog = list()
	for(var/datum/nifsoft/program as anything in GLOB.nifsoft_catalog)
		catalog += list(list("id" = "[program]", "name" = initial(program.name), "description" = initial(program.program_desc),
			"price" = initial(program.purchase_price), "category" = initial(program.category), "reason" = installation_error(program)))
	return catalog

/obj/item/organ/cyberimp/brain/nif/proc/purchase_program(program_type)
	if(!(program_type in GLOB.nifsoft_catalog))
		return FALSE
	var/error = installation_error(program_type)
	if(error)
		to_chat(linked_mob, span_warning("NIF: [error]"))
		return FALSE
	var/datum/nifsoft/program = program_type
	var/price = initial(program.purchase_price)
	var/datum/bank_account/account = linked_mob.get_bank_account()
	if(price && (!account || !account.adjust_money(-price)))
		to_chat(linked_mob, span_warning(account ? "NIF: недостаточно средств." : "NIF: наденьте ID с банковским счётом или возьмите её в руку."))
		return FALSE
	var/datum/nifsoft/installed = new program_type(src)
	if(QDELETED(installed))
		if(price)
			account.adjust_money(price)
		return FALSE
	to_chat(linked_mob, span_notice("NIF: установлена программа [installed.name].[calibrating ? " Запуск станет доступен после калибровки." : ""]"))
	return TRUE

/datum/design/nif_hud_adapter
	name = "NIF HUD Retrofitter"
	id = "nif_hud_adapter"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT, /datum/material/glass = SHEET_MATERIAL_AMOUNT, /datum/material/plastic = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/nif_hud_adapter
	category = list("Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_ALL

/datum/design/nifsoft_disk
	name = "NIFSoft Scryer Disk"
	id = "nifsoft_scryer"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT, /datum/material/silver = HALF_SHEET_MATERIAL_AMOUNT, /datum/material/plastic = SHEET_MATERIAL_AMOUNT)
	build_path = /obj/item/disk/nifsoft_uploader/scryer
	category = list("Medical Designs")
	departmental_flags = DEPARTMENTAL_FLAG_ALL

/datum/design/nifsoft_disk/medical
	name = "Medical Scrying Lens NIFSoft Disk"
	id = "nifsoft_medical"
	build_path = /obj/item/disk/nifsoft_uploader/med_hud
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/nifsoft_disk/security
	name = "Security Scrying Lens NIFSoft Disk"
	id = "nifsoft_security"
	build_path = /obj/item/disk/nifsoft_uploader/sec_hud
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/design/nifsoft_disk/diagnostic
	name = "Diagnostic Scrying Lens NIFSoft Disk"
	id = "nifsoft_diagnostic"
	build_path = /obj/item/disk/nifsoft_uploader/diag_hud
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/nifsoft_disk/science
	name = "Science Scrying Lens NIFSoft Disk"
	id = "nifsoft_science"
	build_path = /obj/item/disk/nifsoft_uploader/sci_hud
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/nifsoft_disk/meson
	name = "Meson Scrying Lens NIFSoft Disk"
	id = "nifsoft_meson"
	build_path = /obj/item/disk/nifsoft_uploader/meson_hud
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/nifsoft_disk/appraisal
	name = "Automatic Appraisal NIFSoft Disk"
	id = "nifsoft_appraisal"
	build_path = /obj/item/disk/nifsoft_uploader/money_sense
	departmental_flags = DEPARTMENTAL_FLAG_CARGO
