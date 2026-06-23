//Visor modules for MODsuits

///Base Visor - Adds a specific HUD and traits to you.
/obj/item/mod/module/visor
	name = "MOD visor module"
	desc = "Дисплей, установленный в забрало костюма. Говорят, они также позволяют видеть то, что позади вас."
	module_type = MODULE_TOGGLE
	complexity = 2
	active_power_cost = DEFAULT_CHARGE_DRAIN * 0.3
	incompatible_modules = list(/obj/item/mod/module/visor)
	cooldown_time = 0.5 SECONDS
	/// The HUD type given by the visor.
	var/hud_type
	/// The traits given by the visor.
	var/list/visor_traits = list()
	mod_module_flags = MOD_MODULE_VISOR // BLUEMOON ADD
	var/datum/component/neural_interface/interface
	var/list/monitors = list()
	var/interface_source

/obj/item/mod/module/visor/on_activation()
	. = ..()
	if(!.)
		return
	if(hud_type)
		var/datum/atom_hud/hud = GLOB.huds[hud_type]
		hud.add_hud_to(mod.wearer)
		interface = mod.wearer.LoadComponent(/datum/component/neural_interface)
		interface_source = "MOD HUD[hud_type]"
		interface.AddSource(interface_source)
		if(monitors?.len)
			interface.add_monitors_by_types(interface_source, monitors)
	for(var/trait in visor_traits)
		ADD_TRAIT(mod.wearer, trait, MOD_TRAIT)
	mod.wearer.update_sight()


/obj/item/mod/module/visor/on_deactivation(display_message = TRUE, deleting = FALSE)
	. = ..()
	if(!.)
		return
	if(hud_type)
		var/datum/atom_hud/hud = GLOB.huds[hud_type]
		hud.remove_hud_from(mod.wearer)
		interface?.RemoveSource(interface_source)
	for(var/trait in visor_traits)
		REMOVE_TRAIT(mod.wearer, trait, MOD_TRAIT)
	mod.wearer.update_sight()

//Medical Visor - Gives you a medical HUD.
/obj/item/mod/module/visor/medhud
	name = "MOD medical visor module"
	desc = "Дисплей, установленный в забрало костюма. Сопоставляет данные сенсоров костюма с современным \
		биологическим сканером, позволяя пользователю визуализировать текущее состояние здоровья органических форм жизни, а также \
		получать доступ к данным, таким как файлы пациентов, в удобном формате. Говорят, они также позволяют видеть то, что позади вас."
	icon_state = "medhud_visor"
	hud_type = DATA_HUD_MEDICAL_ADVANCED
	monitors = list(
		/datum/neural_monitor/health_scan,
		/datum/neural_monitor/health,
		/datum/neural_monitor/wound
	)

//Diagnostic Visor - Gives you a diagnostic HUD.
/obj/item/mod/module/visor/diaghud
	name = "MOD diagnostic visor module"
	desc = "Дисплей, установленный в забрало костюма. Использует ряд продвинутых датчиков для доступа к данным \
		сложной техники, экзокостюмов и других устройств, позволяя пользователю визуализировать текущий уровень заряда \
		и целостность таковых. Говорят, они также позволяют видеть то, что позади вас."
	icon_state = "diaghud_visor"
	hud_type = DATA_HUD_DIAGNOSTIC_ADVANCED

//Security Visor - Gives you a security HUD.
/obj/item/mod/module/visor/sechud
	name = "MOD security visor module"
	desc = "Дисплей, установленный в забрало костюма. Этот модуль — серьёзно модифицированная система наведения, \
		подключённая к различным криминальным базам данных для просмотра записей об арестах, управления простыми роботами безопасности \
		и общего понимания, в кого стрелять. Говорят, они также позволяют видеть то, что позади вас."
	icon_state = "sechud_visor"
	hud_type = DATA_HUD_SECURITY_ADVANCED

//Meson Visor - Gives you meson vision.
/obj/item/mod/module/visor/meson
	name = "MOD meson visor module"
	desc = "Дисплей, установленный в забрало костюма. Этот модуль основан на любимой всеми технологии мезонных сканеров, \
		используемой строителями и шахтёрами по всей галактике для просмотра базовых структурных и ландшафтных планов \
		сквозь стены, независимо от условий освещения. Говорят, они также позволяют видеть то, что позади вас."
	icon_state = "meson_visor"
	visor_traits = list(TRAIT_MESON_VISION)

//Thermal Visor - Gives you thermal vision.
/obj/item/mod/module/visor/thermal
	name = "MOD thermal visor module"
	desc = "Дисплей, установленный в забрало костюма. Использует небольшой ИК-сканер для обнаружения и определения \
		теплового излучения объектов рядом с пользователем. Хотя он может обнаружить тепловое излучение даже чего-то такого малого, \
		как грызун, он всё ещё создаёт раздражающую красную подсветку. Говорят, они также позволяют видеть то, что позади вас."
	icon_state = "thermal_visor"
	visor_traits = list(TRAIT_THERMAL_VISION)

//Night Visor - Gives you night vision.
/obj/item/mod/module/visor/night
	name = "MOD night visor module"
	desc = "Дисплей, установленный в забрало костюма. Типичен как для гражданских, так и для военных применений, \
		позволяя пользователю воспринимать окружение в полной темноте, усиливая изображение в десять раз; \
		при этом всё становится жутким зелёным свечением. Говорят, они также позволяют видеть то, что позади вас."
	icon_state = "night_visor"
	visor_traits = list(TRAIT_TRUE_NIGHT_VISION)
