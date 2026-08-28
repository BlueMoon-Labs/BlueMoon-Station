//Used in storage.
/datum/numbered_display
	var/obj/item/sample_object
	var/number

/datum/numbered_display/New(obj/item/sample, _number = 1, datum/component/storage/parent)
	if(!istype(sample))
		//Без return дальше шёл new на битом образце: датум уже в очереди на
		//удаление, а заведённый им экранный объект оставался бы ничьим.
		qdel(src)
		return
	//Экран берётся из пула хранилища и туда же вернётся. Собственный new
	//заводил новый /atom/movable/screen/storage/item_holder на каждый тип
	//предмета при КАЖДОЙ перерисовке числового режима, а _recycle_ui_objects
	//складывал показанные экраны в GLOB.storage_item_holder_pool, откуда числовой режим
	//их никогда не доставал: пул рос до конца раунда (перепись прода: +219 и
	//+170 item_holder за интервал).
	sample_object = parent._acquire_item_holder(null, sample)
	number = _number

/datum/numbered_display/Destroy()
	//Ссылку отпускаем, но экран не удаляем: он уже уехал в список показанных
	//объектов и вернётся в пул через _recycle_ui_objects при закрытии UI.
	sample_object = null
	return ..()
