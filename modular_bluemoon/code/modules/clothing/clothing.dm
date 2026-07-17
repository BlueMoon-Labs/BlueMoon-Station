/obj/item/clothing
	/**
	 * Всплывающая подсказка с дополнительным описанием у имени при осмотре.
	 * Вторая переменная является флагом очистки подсказки при снятии предмета.
	 */
	var/list/custom_examine_tooltip = list("", TRUE)

/obj/item/clothing/verb/set_custom_examine_text()
	set name = "Set custom examine text"
	set category = "Object"
	set src in view(0)

	if(!isliving(usr))
		return
	if(item_flags & ABSTRACT)
		return
	var/usrinput = stripped_input(usr, "Это описание предмета будет видно при осмотре персонажа, носящего предмет. Cancel - очистить.", "Дополнительное описание", custom_examine_tooltip[1], MAX_MESSAGE_LEN)
	custom_examine_tooltip[1] = usrinput
	if(!usrinput)
		return
	usrinput = alert(usr, "Оставлять описание даже после снятия предмета с персонажа?", "Постоянное описание", "Да", "Нет")
	custom_examine_tooltip[2] = (usrinput == "Да") ? FALSE : TRUE

/obj/item/clothing/get_examine_name(mob/user)
	. = ..()
	if(custom_examine_tooltip[1])
		. = " [span_tooltip(custom_examine_tooltip[1], ., "", "green bold", "text-decoration: underline dashed green;")]"

/obj/item/clothing/dropped(mob/user)
	. = ..()
	if(custom_examine_tooltip[1] && custom_examine_tooltip[2])
		if(current_equipped_slot & slot_flags)
			custom_examine_tooltip[1] = ""

/obj/item/clothing/AltClick(mob/user)
	. = ..()
	if(istype(src, /obj/item/clothing/under))
		var/obj/item/clothing/under/U = src
		if(length(U.attached_accessories))
			return // аксессуары снимаются в приоритете
	var/datum/component/condom_clipping/cc = GetComponent(/datum/component/condom_clipping)
	if(cc?.unclip_condom(user))
		return TRUE

/obj/item/clothing/get_examine_string(mob/user, thats)
	. = ..()
	var/datum/component/condom_clipping/cc = GetComponent(/datum/component/condom_clipping)
	if(cc?.attached_condoms)
		. +=  " with <span bold class='love'><b>[cc.attached_condoms]</b> filled condom[cc.attached_condoms > 1 ? "s" : ""] attached onto it</span>"
