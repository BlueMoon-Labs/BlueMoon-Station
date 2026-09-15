/datum/component/techweb_holder
	var/datum/techweb/linked_techweb

/datum/component/techweb_holder/Initialize(...)
	. = ..()
	RegisterSignal(parent, COMSIG_ATOM_TOOL_ACT(TOOL_MULTITOOL), PROC_REF(on_multitool_act))
	RegisterSignal(parent, COMSIG_ATOM_GET_TECHWEB, PROC_REF(GetTechWeb))
	RegisterSignal(parent, COMSIG_ATOM_SET_TECHWEB, PROC_REF(on_set_techweb))

/datum/component/techweb_holder/Destroy(force, silent)
	. = ..()
	linked_techweb = null

/datum/component/techweb_holder/proc/on_set_techweb(datum/source, new_web)
	SIGNAL_HANDLER
	if(!new_web)
		return null

	linked_techweb = new_web
	SEND_SIGNAL(parent, COMSIG_ATOM_TECHWEB_CHANGED, linked_techweb)

/datum/component/techweb_holder/proc/on_multitool_act(datum/source, mob/living/user, obj/item/I, list/mutable_recipes)
	SIGNAL_HANDLER
	var/obj/item/multitool/tool = I
	if(istype(tool.buffer, /datum/techweb))
		var/datum/techweb/new_web = tool.buffer
		if(new_web == linked_techweb)
			to_chat(user, span_notice("Объект уже подключён к [new_web.organization]."))
			return TRUE
		linked_techweb = new_web
		SEND_SIGNAL(parent, COMSIG_ATOM_TECHWEB_CHANGED, linked_techweb)
		to_chat(user, span_notice("Вы подключаете объект к [new_web.organization]."))
	else if(!tool.buffer)
		if(linked_techweb)
			tool.buffer = linked_techweb
			to_chat(user, span_notice("Вы сохраняете базу данных исследований [linked_techweb.organization] в буфер мультитула."))
		else
			to_chat(user, span_notice("Объект не подключён ни к одной исследовательской сети."))
	else
		to_chat(user, span_notice("Буфер мультитула занят посторонним объектом."))

/datum/component/techweb_holder/proc/GetTechWeb()
	SIGNAL_HANDLER

	return linked_techweb
