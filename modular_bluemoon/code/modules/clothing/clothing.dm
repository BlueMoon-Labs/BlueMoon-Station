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
	var/usrinput = stripped_input(usr, "Какое у предмета будет дополнительное описание при осмотре? Cancel - очистить.", "Дополнительное описание", custom_examine_tooltip[1], MAX_MESSAGE_LEN)
	custom_examine_tooltip[1] = usrinput
	if(!usrinput)
		return
	usrinput = alert(usr, "Оставить описание даже после снятия предмета?", "Постоянное описание", "Да", "Нет")
	custom_examine_tooltip[2] = (usrinput == "Да") ? FALSE : TRUE

/obj/item/clothing/get_examine_name(mob/user)
	. = ..()
	if(custom_examine_tooltip[1])
		. = " <span class='chat-tooltip green bold'; style='text-decoration: underline dashed green;'>[.]<span class='chat-tooltip__content'>[custom_examine_tooltip[1]]</span></span>"

/obj/item/clothing/dropped(mob/user)
	. = ..()
	if(custom_examine_tooltip[1] && custom_examine_tooltip[2])
		if(current_equipped_slot & slot_flags)
			custom_examine_tooltip[1] = ""
