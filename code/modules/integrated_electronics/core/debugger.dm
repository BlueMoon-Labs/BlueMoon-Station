/obj/item/integrated_electronics/debugger
	name = "circuit debugger"
	desc = "Этот небольшой инструмент позволяет тем, кто работает с нестандартным оборудованием, напрямую записывать данные в конкретный контакт, что удобно при записи \
	настроек в определенные цепи или для отладки.  Он также может генерировать импульсы на выводах активации."
	icon = 'icons/obj/assemblies/electronic_tools.dmi'
	icon_state = "debugger"
	flags_1 = CONDUCT_1
	item_flags = NOBLUDGEON
	w_class = WEIGHT_CLASS_SMALL
	var/data_to_write = null
	var/accepting_refs = FALSE
	var/copy_values = FALSE
	var/copy_id = FALSE

/obj/item/integrated_electronics/debugger/attack_self(mob/user)
	var/type_to_use = input("Выберите тип.","[src] type setting") as null|anything in list("string","number","ref","copy","null")
	if(!user.IsAdvancedToolUser())
		return

	var/new_data = null
	switch(type_to_use)
		if("string")
			accepting_refs = FALSE
			copy_values = FALSE
			copy_id = FALSE
			new_data = stripped_input(user, "Теперь введите строку.","[src] string writing", no_trim = TRUE)
			if(istext(new_data) && user.IsAdvancedToolUser())
				data_to_write = new_data
				to_chat(user, "<span class='notice'>Вы устанавливаете память \the [src] в \"[new_data]\".</span>")
		if("number")
			accepting_refs = FALSE
			copy_values = FALSE
			new_data = input(user, "Теперь введите число.","[src] number writing") as null|num
			if(isnum(new_data) && user.IsAdvancedToolUser())
				data_to_write = new_data
				to_chat(user, "<span class='notice'>Вы устанавливаете память \the [src] в [new_data].</span>")
		if("ref")
			accepting_refs = TRUE
			copy_values = FALSE
			copy_id = FALSE
			to_chat(user, "<span class='notice'>Включите сканер ссылок \the [src]. Проведите им по \
            объекту, чтобы получить ссылку на этот объект и сохранить её в памяти.</span>")
		if("copy")
			accepting_refs = FALSE
			copy_values = TRUE
			copy_id = FALSE
			to_chat(user, "<span class='notice'>Вы включаете устройство копирования значений \the [src].  Используйте его на выводе, \
            чтобы сохранить его текущее значение в памяти.</span>")
		if("null")
			accepting_refs = FALSE
			data_to_write = null
			copy_values = FALSE
			copy_id = FALSE
			to_chat(user, "<span class='notice'>Вы сбросили память \the [src] до нуля</span>")

/obj/item/integrated_electronics/debugger/afterattack(atom/target, mob/living/user, proximity)
	. = ..()
	if(accepting_refs && proximity)
		data_to_write = WEAKREF(target)
		visible_message("<span class='notice'>[user] проводит \a [src] над \the [target].</span>")
		to_chat(user, "<span class='notice'>Вы установили в память \the [src] ссылку на [target.name] \[Ref\].  Сканер ссылок \
		теперь выключен.</span>")
		accepting_refs = FALSE

/obj/item/integrated_electronics/debugger/proc/write_data(var/datum/integrated_io/io, mob/user)
	//If the pin can take data:
	if(io.io_type == DATA_CHANNEL)
		//If the debugger is set to copy, copy the data in the pin onto it
		if(copy_values)
			data_to_write = io.data
			to_chat(user, "<span class='notice'>Вы разрешили отладчику копировать данные.</span>")
			copy_values = FALSE
			return

		//Else, write the data to the pin
		io.write_data_to_pin(data_to_write)
		var/data_to_show = data_to_write
		//This is only to convert a weakref into a name for better output
		if(isweakref(data_to_write))
			var/datum/weakref/w = data_to_write
			var/atom/A = w.resolve()
			data_to_show = A.name
		to_chat(user, "<span class='notice'>Вы вписываете '[data_to_write ? data_to_show : "NULL"]' в пин '[io]', находящийся в \the [io.holder].</span>")

	//If the pin can only be pulsed
	else if(io.io_type == PULSE_CHANNEL)
		io.holder.check_then_do_work(io.ord,ignore_power = TRUE)
		to_chat(user, "<span class='notice'>Вы отправляете импульс в [io] устройства [io.holder].</span>")

	io.holder.interact(user) // This is to update the UI.
