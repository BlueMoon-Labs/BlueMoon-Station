/datum/nifsoft/hud
	name = "Scrying Lens"
	program_desc = "Выводит данные на очки с адаптером NIF. Одновременно можно установить только одну рабочую HUD-программу."
	purchase_price = 300
	category = "HUD"
	active_cost = 0.5
	compatible_nif = /obj/item/organ/cyberimp/brain/nif/standard
	var/hud_type
	var/list/vision_traits = list()
	var/datum/weakref/eyewear
	var/datum/component/neural_interface/interface
	var/list/monitors = list()

/datum/nifsoft/hud/activate()
	if(active)
		deactivate()
		return TRUE
	var/obj/item/clothing/glasses/glasses = linked_mob?.glasses
	if(!istype(glasses) || !HAS_TRAIT(glasses, TRAIT_NIF_HUD))
		to_chat(linked_mob, span_warning("NIF: нужны надетые очки с адаптером NIF HUD."))
		return FALSE
	if(!..())
		return FALSE
	eyewear = WEAKREF(glasses)
	RegisterSignal(glasses, COMSIG_ITEM_DROPPED, PROC_REF(on_glasses_removed))
	RegisterSignal(glasses, COMSIG_PARENT_QDELETING, PROC_REF(on_glasses_removed))
	if(hud_type)
		var/datum/atom_hud/hud = GLOB.huds[hud_type]
		hud.add_hud_to(linked_mob)
		interface = linked_mob.LoadComponent(/datum/component/neural_interface)
		RegisterSignal(interface, COMSIG_PARENT_QDELETING, PROC_REF(on_interface_deleted))
		interface.AddSource(REF(src))
		if(length(monitors))
			interface.add_monitors_by_types(REF(src), monitors)
	for(var/trait in vision_traits)
		ADD_TRAIT(linked_mob, trait, REF(src))
	linked_mob.update_sight()
	return TRUE

/datum/nifsoft/hud/deactivate()
	if(!active)
		return ..()
	var/obj/item/clothing/glasses/glasses = eyewear?.resolve()
	if(glasses)
		UnregisterSignal(glasses, list(COMSIG_ITEM_DROPPED, COMSIG_PARENT_QDELETING))
	eyewear = null
	clear_interface()
	if(linked_mob)
		if(hud_type)
			var/datum/atom_hud/hud = GLOB.huds[hud_type]
			hud.remove_hud_from(linked_mob)
		for(var/trait in vision_traits)
			REMOVE_TRAIT(linked_mob, trait, REF(src))
		linked_mob.update_sight()
	return ..()

/datum/nifsoft/hud/proc/on_glasses_removed(datum/source)
	SIGNAL_HANDLER
	deactivate()

/datum/nifsoft/hud/proc/clear_interface()
	var/datum/component/neural_interface/old_interface = interface
	interface = null
	if(!old_interface)
		return
	UnregisterSignal(old_interface, COMSIG_PARENT_QDELETING)
	if(!QDELETED(old_interface))
		old_interface.RemoveSource(REF(src))

/datum/nifsoft/hud/proc/on_interface_deleted(datum/source)
	SIGNAL_HANDLER
	interface = null

/datum/nifsoft/hud/job
	exclusive_group = /datum/nifsoft/hud/job

/datum/nifsoft/hud/job/medical
	name = "Medical Scrying Lens"
	hud_type = DATA_HUD_MEDICAL_ADVANCED
	monitors = list(/datum/neural_monitor/health_scan, /datum/neural_monitor/health, /datum/neural_monitor/wound)

/datum/nifsoft/hud/job/security
	name = "Security Scrying Lens"
	hud_type = DATA_HUD_SECURITY_ADVANCED

/datum/nifsoft/hud/job/diagnostic
	name = "Diagnostic Scrying Lens"
	hud_type = DATA_HUD_DIAGNOSTIC_ADVANCED

/datum/nifsoft/hud/job/science
	name = "Science Scrying Lens"
	vision_traits = list(TRAIT_REAGENT_SCANNER, TRAIT_RESEARCH_SCANNER)

/datum/nifsoft/hud/job/meson
	name = "Meson Scrying Lens"
	vision_traits = list(TRAIT_MESON_VISION)

/datum/nifsoft/hud/thermal
	name = "Thermal Lens"
	program_desc = "Военная NIFSoft для теплового зрения. Требует очки с адаптером NIF HUD."
	active_cost = 1
	vision_traits = list(TRAIT_THERMAL_VISION)

/obj/item/nif_hud_adapter
	name = "NIF HUD Retrofitter"
	desc = "Одноразовый адаптер очков для работы с HUD-программами NIF."
	icon = 'icons/obj/clothing/modsuit/nif_devices.dmi'
	icon_state = "nifsoft_remover"
	var/uses = 1

/obj/item/nif_hud_adapter/afterattack(obj/item/clothing/glasses/glasses, mob/user, proximity)
	. = ..()
	if(!proximity || !istype(glasses) || HAS_TRAIT(glasses, TRAIT_NIF_HUD) || !uses)
		return
	ADD_TRAIT(glasses, TRAIT_NIF_HUD, INNATE_TRAIT)
	to_chat(user, span_notice("[glasses] теперь поддерживают HUD-программы NIF."))
	if(!--uses)
		qdel(src)

/datum/nifsoft/money_sense
	name = "Automatic Appraisal"
	program_desc = "При осмотре предмета показывает его экспортную стоимость вместе с содержимым. Не продаёт предмет."
	purchase_price = 300
	active_cost = 0.5
	category = "Утилиты"
	compatible_nif = /obj/item/organ/cyberimp/brain/nif/standard

/datum/nifsoft/money_sense/activate()
	if(active)
		deactivate()
		return TRUE
	if(!..())
		return FALSE
	RegisterSignal(linked_mob, COMSIG_MOB_EXAMINATE, PROC_REF(on_examine))
	return TRUE

/datum/nifsoft/money_sense/deactivate()
	if(linked_mob)
		UnregisterSignal(linked_mob, COMSIG_MOB_EXAMINATE)
	return ..()

/datum/nifsoft/money_sense/proc/on_examine(mob/source, atom/target)
	SIGNAL_HANDLER
	if(!isitem(target))
		return
	var/price = appraise(target)
	to_chat(linked_mob, span_notice("NIF: экспортная стоимость [target] с содержимым — [price] кр."))

/datum/nifsoft/money_sense/proc/appraise(obj/item/target)
	var/datum/export_report/report = export_item_and_contents(target, dry_run = TRUE)
	var/price = 0
	for(var/export in report.total_value)
		price += report.total_value[export]
	qdel(report)
	return price

/datum/nifsoft/action_granter
	activation_cost = 10
	active_cost = 1
	var/action_type
	var/datum/action/granted_action

/datum/nifsoft/action_granter/activate()
	if(active)
		deactivate()
		return TRUE
	if(!action_type || !..())
		return FALSE
	granted_action = new action_type(src)
	granted_action.Grant(linked_mob)
	return TRUE

/datum/nifsoft/action_granter/deactivate()
	QDEL_NULL(granted_action)
	return ..()

/datum/nifsoft/action_granter/shapeshifter
	name = "Polymorph"
	program_desc = "Позволяет менять внешность текущего тела с помощью способности «Изменить тело». Раса не меняется."
	purchase_price = 350
	category = "Внешность"
	compatible_nif = /obj/item/organ/cyberimp/brain/nif/standard
	action_type = /datum/action/innate/ability/humanoid_customization/nif

/datum/action/innate/ability/humanoid_customization/nif
	name = "Polymorph"
	background_icon_state = "bg_tech_blue"

/datum/action/innate/ability/humanoid_customization/nif/IsAvailable(silent = FALSE)
	var/datum/nifsoft/program = target
	return ..() && istype(program) && program.active && program.can_activate()

/datum/nifsoft/action_granter/hypnosis
	name = "Libidine Eye"
	program_desc = "Даёт способность гипнотизировать гуманоида в усиленном захвате. Работает только на предрасположенных к гипнозу."
	purchase_price = 150
	active_cost = 0.1
	category = "Развлечения"
	action_type = /datum/action/cooldown/hypnotize/nif

/datum/action/cooldown/hypnotize/nif
	background_icon_state = "bg_tech_blue"

/datum/action/cooldown/hypnotize/nif/IsAvailable(silent = FALSE)
	var/datum/nifsoft/program = target
	return ..() && istype(program) && program.active && program.can_activate()

/obj/item/disk/nifsoft_uploader/money_sense
	name = "Automatic Appraisal NIFSoft disk"
	loaded_nifsoft = /datum/nifsoft/money_sense

/obj/item/disk/nifsoft_uploader/shapeshifter
	name = "Polymorph NIFSoft disk"
	loaded_nifsoft = /datum/nifsoft/action_granter/shapeshifter

/obj/item/disk/nifsoft_uploader/hypnosis
	name = "Libidine Eye NIFSoft disk"
	loaded_nifsoft = /datum/nifsoft/action_granter/hypnosis

/obj/item/disk/nifsoft_uploader/med_hud
	name = "Medical Scrying Lens NIFSoft disk"
	loaded_nifsoft = /datum/nifsoft/hud/job/medical

/obj/item/disk/nifsoft_uploader/sec_hud
	name = "Security Scrying Lens NIFSoft disk"
	loaded_nifsoft = /datum/nifsoft/hud/job/security

/obj/item/disk/nifsoft_uploader/diag_hud
	name = "Diagnostic Scrying Lens NIFSoft disk"
	loaded_nifsoft = /datum/nifsoft/hud/job/diagnostic

/obj/item/disk/nifsoft_uploader/sci_hud
	name = "Science Scrying Lens NIFSoft disk"
	loaded_nifsoft = /datum/nifsoft/hud/job/science

/obj/item/disk/nifsoft_uploader/meson_hud
	name = "Meson Scrying Lens NIFSoft disk"
	loaded_nifsoft = /datum/nifsoft/hud/job/meson

/obj/item/disk/nifsoft_uploader/mil_grade/thermal
	name = "Thermal Lens NIFSoft disk"
	loaded_nifsoft = /datum/nifsoft/hud/thermal
