// Фальшивый имплант защиты разума: проецирует на секхуды иконку настоящего МЩ,
// но не даёт никакой защиты от вербовки, гипноза и промывания мозгов.
// Контрплей: продвинутый анализатор здоровья видит подделку, ЭМИ временно глушит проекцию,
// вживление настоящего импланта защиты разума сжигает передатчик с заметным эффектом.

/// Время глушения проекции после тяжёлого ЭМИ
#define FAKE_MINDSHIELD_EMP_DISABLE_HEAVY (2 MINUTES)
/// Время глушения проекции после лёгкого ЭМИ
#define FAKE_MINDSHIELD_EMP_DISABLE_LIGHT (1 MINUTES)

/obj/item/implant/fake_mindshield
	name = "Mindshield Implant"
	desc = "Кустарная копия импланта защиты разума. Вместо капсулы с наноботами внутри лишь передатчик, проецирующий сигнатуру настоящего импланта на сканеры систем безопасности."
	/// Включена ли проекция сигнатуры носителем (кнопка-действие)
	var/icon_enabled = TRUE
	/// Передатчик временно заглушен электромагнитным импульсом
	var/emp_disabled = FALSE

/obj/item/implant/fake_mindshield/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_IMPLANT_OTHER, PROC_REF(on_other_implant))

/obj/item/implant/fake_mindshield/get_data()
	var/dat = {"<b>Технические характеристики Импланта:</b><BR>
				<b>Название:</b> Подделка Импланта Защиты Разума неизвестного производства<BR>
				<b>Время Износа:</b> Неизвестно.<BR>
				<b>Дополнительные Сведения:</b> Не защищает носителя от какого-либо воздействия на разум.<BR>
				<HR>
				<b>Дополнительная информация по импланту:</b><BR>
				<b>Функционал:</b> Передатчик, проецирующий сигнатуру импланта защиты разума на визоры и сканеры безопасности. Носитель может включать и отключать проекцию по желанию.<BR>
				<b>Дополнительные Функции:</b> Не обнаружено.<BR>
				<b>Целостность:</b> Передатчик уязвим к электромагнитным импульсам и перегорает при контакте с настоящим имплантом защиты разума."}
	return dat

/obj/item/implant/fake_mindshield/implant(mob/living/target, mob/user, silent = FALSE, force = FALSE)
	if(HAS_TRAIT(target, TRAIT_MINDSHIELD))
		if(!silent && user)
			to_chat(user, "<span class='warning'>Имплантер отказывается срабатывать: передатчик не может перекрыть сигнатуру настоящего импланта защиты разума!</span>")
		return FALSE
	. = ..()
	if(!.)
		return FALSE
	if(imp_in != target) // родитель мог слить нас с уже стоящей фальшивкой и удалить - не оставляем сигналов от мёртвого импланта
		return .
	icon_enabled = TRUE
	emp_disabled = FALSE
	update_fake_signature()
	RegisterSignal(target, COMSIG_ATOM_EMP_ACT, PROC_REF(on_carrier_emp))
	if(!silent)
		to_chat(target, "<span class='notice'>Под кожей едва ощутимо завибрировал передатчик: сканеры безопасности теперь считают вас привитым от промывания мозгов.</span>")
	return TRUE

/obj/item/implant/fake_mindshield/removed(mob/living/source, silent = FALSE, special = 0)
	. = ..()
	if(!.)
		return FALSE
	UnregisterSignal(source, COMSIG_ATOM_EMP_ACT)
	if(isliving(source))
		REMOVE_TRAIT(source, TRAIT_FAKE_MINDSHIELD, "implant")
		source.sec_hud_set_implants()
	return TRUE

/obj/item/implant/fake_mindshield/activate()
	. = ..()
	if(!imp_in)
		return
	if(emp_disabled)
		to_chat(imp_in, "<span class='warning'>Передатчик не отвечает: электроника всё ещё восстанавливается после электромагнитного импульса!</span>")
		return
	icon_enabled = !icon_enabled
	to_chat(imp_in, "<span class='notice'>Передатчик [icon_enabled ? "снова проецирует" : "больше не проецирует"] сигнатуру защиты разума.</span>")
	update_fake_signature()

/// Синхронизирует трейт фальшивой сигнатуры с состоянием передатчика и обновляет секхуд носителя.
/obj/item/implant/fake_mindshield/proc/update_fake_signature()
	if(!imp_in)
		return
	if(icon_enabled && !emp_disabled)
		ADD_TRAIT(imp_in, TRAIT_FAKE_MINDSHIELD, "implant")
	else
		REMOVE_TRAIT(imp_in, TRAIT_FAKE_MINDSHIELD, "implant")
	imp_in.sec_hud_set_implants()

/// ЭМИ по носителю глушит проекцию: настоящий имплант на импульс не реагирует, внимательный офицер заметит пропавшую иконку.
/obj/item/implant/fake_mindshield/proc/on_carrier_emp(datum/source, severity)
	SIGNAL_HANDLER
	var/was_disabled = emp_disabled
	emp_disabled = TRUE
	update_fake_signature()
	if(!was_disabled)
		to_chat(imp_in, "<span class='warning'>Передатчик под кожей обжигающе искрит: проекция сигнатуры защиты разума сбита электромагнитным импульсом!</span>")
	// severity == 1 - тяжёлый импульс (эпицентр), всё остальное считаем лёгким
	addtimer(CALLBACK(src, PROC_REF(restore_after_emp)), (severity == 1) ? FAKE_MINDSHIELD_EMP_DISABLE_HEAVY : FAKE_MINDSHIELD_EMP_DISABLE_LIGHT, TIMER_UNIQUE | TIMER_OVERRIDE)

/// Восстанавливает работу передатчика после ЭМИ. Проекция вернётся только если носитель не выключал её кнопкой.
/obj/item/implant/fake_mindshield/proc/restore_after_emp()
	emp_disabled = FALSE
	update_fake_signature()
	if(imp_in)
		to_chat(imp_in, "<span class='notice'>Электроника передатчика под кожей восстановилась после электромагнитного импульса.</span>")

/// Настоящий имплант защиты разума сжигает фальшивку при вживлении - с искрами и дымом на всю комнату.
/obj/item/implant/fake_mindshield/proc/on_other_implant(datum/source, list/implant_args, obj/item/implant/new_implant)
	SIGNAL_HANDLER
	if(!istype(new_implant, /obj/item/implant/mindshield))
		return
	if(imp_in)
		do_sparks(2, TRUE, imp_in)
		imp_in.visible_message("<span class='warning'>Под кожей [imp_in] что-то громко трещит и искрит, пуская струйку дыма!</span>", \
			"<span class='userdanger'>Настоящий имплант защиты разума сжигает ваш поддельный передатчик!</span>")
	return COMPONENT_DELETE_OLD_IMPLANT

/obj/item/implanter/fake_mindshield
	name = "Implanter (Mindshield)"
	imp_type = /obj/item/implant/fake_mindshield

/obj/item/implantcase/fake_mindshield
	name = "implant case - 'Mindshield'"
	desc = "A glass case containing a mindshield implant."
	imp_type = /obj/item/implant/fake_mindshield

/obj/item/storage/box/syndie_kit/imp_fake_mindshield
	name = "boxed fake mindshield implant (with injector)"

/obj/item/storage/box/syndie_kit/imp_fake_mindshield/PopulateContents()
	new /obj/item/implanter/fake_mindshield(src)

#undef FAKE_MINDSHIELD_EMP_DISABLE_HEAVY
#undef FAKE_MINDSHIELD_EMP_DISABLE_LIGHT
