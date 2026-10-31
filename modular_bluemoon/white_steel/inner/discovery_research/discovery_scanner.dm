/obj/item/discovery_scanner
	name = "нюхер"
	desc = "Используется учёными для сканирования различных артефактов и неизвестных форм жизни."
	icon = 'modular_bluemoon/white/valtos/icons/objects.dmi'
	icon_state = "nuher"
	item_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	var/datum/techweb/linked_techweb

/obj/item/discovery_scanner/Initialize()
	. = ..()
	AddComponent(/datum/component/techweb_holder)
	RegisterSignal(src, COMSIG_ATOM_TECHWEB_CHANGED, PROC_REF(on_research_binding))
	SEND_SIGNAL(src, COMSIG_ATOM_SET_TECHWEB, find_rnd_network_for_object(src))

/obj/item/discovery_scanner/proc/on_research_binding(datum/source, datum/techweb/web)
	SIGNAL_HANDLER
	linked_techweb = web

/obj/item/discovery_scanner/Destroy()
	linked_techweb = null	//Note: Shouldn't hard del anyway since techwebs don't get deleted, however if they do then troubles will arise and this will need to be changed.
	. = ..()

/obj/item/discovery_scanner/examine(mob/user)
	. = ..()
	. += "<hr><span class='notice'>Левый клик по чему угодно для начала исследований.</span>"
	. += "\n<span class='notice'>[capitalize(src.name)] имеет безлимитный радиус, можете сканировать хоть через камеры.</span>"
	. += "\n<span class='notice'>Научные очки помогут узнать что может оказаться полезным.</span>"

/obj/item/discovery_scanner/attack_obj(obj/O, mob/living/user)
	if(istype(O, /obj/machinery/computer/rdconsole))
		to_chat(user, span_notice("Привязываю [src] к [O]."))
		var/obj/machinery/computer/rdconsole/rdconsole = O
		SEND_SIGNAL(src, COMSIG_ATOM_SET_TECHWEB, netrun_atom_techweb(rdconsole))
		return
	. = ..()

/obj/item/discovery_scanner/proc/begin_scanning(mob/user, datum/component/discoverable/discoverable)
	if(!netrun_research_snapshot())
		to_chat(user, span_warning("Исследовательский сервер недоступен. Повторите сканирование после соединения."))
		return
	to_chat(user, span_notice("Начинаю сканировать [discoverable.parent]..."))
	if(do_after(user, 50, target=get_turf(user)))
		discoverable.discovery_scan(linked_techweb, user, src)
