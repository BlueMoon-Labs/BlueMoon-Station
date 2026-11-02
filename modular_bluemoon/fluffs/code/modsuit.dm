/obj/item/modsuit_modkit
	name = "MODsuit theme modification Kit"
	desc = "Одноразовый набор персонального оформления для любого MOD-костюма. Меняет только внешний вид, сохраняя характеристики и модули."
	icon = 'modular_bluemoon/fluffs/icons/obj/MOD_modkit.dmi'
	icon_state = "base_modkit"
	var/datum/mod_theme/new_theme = /datum/mod_theme

/obj/item/modsuit_modkit/Initialize(mapload)
	. = ..()
	new_theme = GLOB.mod_themes[new_theme]

/obj/item/modsuit_modkit/Destroy()
	new_theme = null
	return ..()

/obj/item/modsuit_modkit/proc/apply_skin(obj/item/mod/control/modsuit, mob/living/user)
	if(QDELETED(modsuit) || !new_theme || !modsuit.set_visual_skin(new_theme.default_skin))
		return FALSE
	modsuit.restore_modkit_style()
	apply_style(modsuit)
	to_chat(user, span_notice("Оформление MOD-костюма изменено."))
	qdel(src)
	return TRUE

/obj/item/modsuit_modkit/proc/apply_style(obj/item/mod/control/modsuit)
	return

/obj/item/mod/control/proc/restore_modkit_style()
	QDEL_NULL(armolex_hud)
	if(!isnull(modkit_name))
		name = modkit_name
		modkit_name = null
	if(!isnull(modkit_desc))
		desc = modkit_desc
		modkit_desc = null
	activation_sound = null
	deactivation_sound = null

/obj/item/modsuit_modkit/pre_attack(atom/target, mob/living/user, params, attackchain_flags, damage_multiplier)
	if(!istype(target, /obj/item/mod/control))
		return ..()
	apply_skin(target, user)
	return STOP_ATTACK_PROC_CHAIN

/obj/item/modsuit_modkit/armolex
	name = "Armolex MODsuit theme Kit"
	desc = "Персональный набор Armolex: меняет оформление и комплектацию MOD, сохраняя характеристики основы."
	new_theme = /datum/mod_theme/armolex
	var/control_name = "Armolex Vanguard MOD control unit"
	var/hud_type = /datum/armolex_hud
	var/control_desc = "Специализированный для узких кругов МОД костюм от компании Армолекс для своих почётных сотрудников или приоритетных клиентов. Данная модель была спроектирована так, чтобы вся область тела была прикрыта высокотехнологической множеством сплавом из разных сталей, для более крепкой защиты. Также как бонусом, идёт сам прототип модуль телекинеза, для перемещения сверх тяжких грузов на расстоянии. Ну или чтобы кинуть кому-то острый предмет в лицо."

/obj/item/modsuit_modkit/armolex/proc/get_module_types()
	return list(/obj/item/mod/module/holster, /obj/item/mod/module/anomaly_locked/kinesis/plus)

/obj/item/modsuit_modkit/armolex/proc/get_removed_modules(obj/item/mod/control/modsuit)
	var/list/removed = list()
	for(var/obj/item/mod/module/module in modsuit.modules)
		if(istype(module, /obj/item/mod/module/flashlight) || istype(module, /obj/item/mod/module/gps))
			removed += module
	return removed

/obj/item/modsuit_modkit/armolex/proc/create_modules(obj/item/mod/control/modsuit)
	var/list/added = list()
	for(var/module_type in get_module_types())
		if(!ispath(module_type, /obj/item/mod/module/armor) && (locate(module_type) in modsuit.modules))
			continue
		added += new module_type()
	return added

/obj/item/modsuit_modkit/armolex/proc/check_module(obj/item/mod/control/modsuit, obj/item/mod/module/module, list/planned, mob/user)
	if(!module.can_install(modsuit, user) || is_type_in_list(module, modsuit.theme.module_blacklist))
		return FALSE
	if(module.is_armor_module() && !check_armor(modsuit, module, planned, user))
		return FALSE
	for(var/obj/item/mod/module/installed in planned)
		if(!modsuit.check_modules_in_restricted_list(installed, module, module, user))
			return FALSE
	return TRUE

/obj/item/modsuit_modkit/armolex/proc/check_armor(obj/item/mod/control/modsuit, obj/item/mod/module/armor/plate, list/planned, mob/user)
	if(!modsuit.check_compatible_theme_with_armor(user) || (locate(/obj/item/mod/module/stealth/wraith) in planned))
		return FALSE
	var/count = 0
	for(var/obj/item/mod/module/armor/installed in planned)
		if(installed.armor_module_type == plate.armor_module_type)
			count++
	return modsuit.check_max_count_armor(count, plate, user)

/obj/item/modsuit_modkit/armolex/proc/check_modules(obj/item/mod/control/modsuit, list/removed, list/added, mob/user)
	var/complexity = modsuit.complexity
	var/list/planned = modsuit.modules - removed
	for(var/obj/item/mod/module/module in removed)
		complexity -= module.complexity
	for(var/obj/item/mod/module/module in added)
		if(!check_module(modsuit, module, planned, user))
			return FALSE
		complexity += module.complexity
		planned += module
	if(complexity > modsuit.complexity_max)
		to_chat(user, span_warning("Комплектация Armolex превышает вместимость этого MOD."))
		return FALSE
	return TRUE

/obj/item/modsuit_modkit/armolex/proc/install_modules(obj/item/mod/control/modsuit, list/removed, list/added)
	for(var/obj/item/mod/module/module in removed)
		modsuit.uninstall(module)
	for(var/obj/item/mod/module/module in added)
		modsuit.install(module)
		if(module.mod == modsuit)
			continue
		for(var/obj/item/mod/module/installed in added)
			if(installed.mod == modsuit)
				modsuit.uninstall(installed, deleting = TRUE)
		for(var/obj/item/mod/module/original in removed)
			modsuit.install(original)
		return FALSE
	return TRUE

/obj/item/modsuit_modkit/armolex/apply_skin(obj/item/mod/control/modsuit, mob/living/user)
	if(QDELETED(modsuit) || !new_theme || modsuit.is_active() || modsuit.is_activating())
		to_chat(user, span_warning("Сначала отключите MOD перед заменой комплектации."))
		return FALSE
	var/list/removed = get_removed_modules(modsuit)
	var/list/added = create_modules(modsuit)
	if(!check_modules(modsuit, removed, added, user) || !install_modules(modsuit, removed, added))
		QDEL_LIST(added)
		to_chat(user, span_warning("Комплектация Armolex несовместима с этим MOD. Набор сохранён."))
		return FALSE
	for(var/obj/item/mod/module/module in removed)
		module.forceMove(modsuit.drop_location())
	return ..()

/obj/item/modsuit_modkit/armolex/apply_style(obj/item/mod/control/modsuit)
	modsuit.modkit_name = modsuit.name
	modsuit.modkit_desc = modsuit.desc
	modsuit.name = control_name
	modsuit.desc = control_desc
	modsuit.activation_sound = 'sound/items/modsuit/armolex_activation.ogg'
	modsuit.deactivation_sound = 'sound/items/modsuit/armolex_deactivation.ogg'
	modsuit.armolex_hud = new hud_type(modsuit)
	SStgui.close_uis(modsuit)

/datum/mod_theme/armolex
	name = "Armolex"
	default_skin = "armolex"
	skins = list("armolex" = MOD_PRESET_DEFAULT)

/obj/item/modsuit_modkit/armolex_so
	parent_type = /obj/item/modsuit_modkit/armolex
	hud_type = /datum/armolex_hud/special_ops
	name = "Armolex SO MODsuit theme Kit"
	new_theme = /datum/mod_theme/armolex/so
	control_name = "Armolex Special-Ops MOD control unit"
	control_desc = "Военизированный костюм от оружейной компании Армолекс. МОД-Костюм имеет уникальную обшивку, тонкий слой неизвестного для ПАКТа материала, который поглощает большую часть кинетический и физическо-термальный урон. При этом в добавок сохранилась конструкция герметизации самого костюма, которая поддерживается лишь в включённом состоянии из-за активности нано-ботов на поверхности костюма, что делает его повреждения в край минимальным."

/obj/item/modsuit_modkit/armolex_so/get_module_types()
	return list(
		/obj/item/mod/module/holster,
		/obj/item/mod/module/armor/prebuild/melee,
		/obj/item/mod/module/armor/prebuild/bullet,
		/obj/item/mod/module/armor/prebuild/laser,
		/obj/item/mod/module/armor/prebuild/energy,
		/obj/item/mod/module/armor/prebuild/bomb,
		/obj/item/mod/module/armor/prebuild/bio,
		/obj/item/mod/module/armor/prebuild/rad,
		/obj/item/mod/module/armor/prebuild/fire,
		/obj/item/mod/module/armor/prebuild/acid,
		/obj/item/mod/module/armor/prebuild/magic,
		/obj/item/mod/module/armor/prebuild/wound,
	)

/datum/mod_theme/armolex/so
	name = "Armolex SO"
	default_skin = "armolex_so"
	skins = list("armolex_so" = MOD_PRESET_DEFAULT)

#define ARMOLEX_HUD_FRAME "armolex_frame"
#define ARMOLEX_HUD_TITLE "armolex_title"
#define ARMOLEX_HUD_CHARGE "armolex_charge"

/datum/armolex_hud
	var/obj/item/mod/control/mod
	var/mob/living/carbon/human/viewer
	var/list/screens = list()
	var/frame_type = /atom/movable/screen/fullscreen/scaled/armolex
	var/charge_type = /atom/movable/screen/fullscreen/armolex_text/charge

/datum/armolex_hud/New(obj/item/mod/control/modsuit)
	..()
	mod = modsuit
	bind_wearer()

/datum/armolex_hud/Destroy()
	unbind_wearer()
	mod = null
	screens = null
	return ..()

/datum/armolex_hud/proc/bind_wearer()
	if(viewer == mod?.wearer)
		return
	unbind_wearer()
	viewer = mod?.wearer
	if(!viewer)
		return
	RegisterSignal(viewer, COMSIG_MOB_EQUIPPED_ITEM, PROC_REF(on_equipped))
	RegisterSignal(viewer, COMSIG_MOB_UNEQUIPPED_ITEM, PROC_REF(on_unequipped))
	RegisterSignal(viewer, list(COMSIG_MOB_CLIENT_LOGIN, COMSIG_MOB_STATCHANGE), PROC_REF(on_state_change))
	RegisterSignal(viewer, COMSIG_MOB_CLIENT_LOGOUT, PROC_REF(on_logout))
	update()

/datum/armolex_hud/proc/unbind_wearer()
	hide()
	if(viewer)
		UnregisterSignal(viewer, list(COMSIG_MOB_EQUIPPED_ITEM, COMSIG_MOB_UNEQUIPPED_ITEM, COMSIG_MOB_CLIENT_LOGIN, COMSIG_MOB_CLIENT_LOGOUT, COMSIG_MOB_STATCHANGE))
	viewer = null

/datum/armolex_hud/proc/on_equipped(datum/source, obj/item/item)
	SIGNAL_HANDLER
	if(item == mod?.get_helmet())
		update()

/datum/armolex_hud/proc/on_unequipped(datum/source, obj/item/item)
	SIGNAL_HANDLER
	if(item == mod?.get_helmet())
		hide()

/datum/armolex_hud/proc/on_state_change(datum/source)
	SIGNAL_HANDLER
	update()

/datum/armolex_hud/proc/on_logout(datum/source)
	SIGNAL_HANDLER
	hide()

/datum/armolex_hud/proc/update()
	if(QDELETED(mod) || !viewer || !mod.is_active() || viewer.head != mod.get_helmet() || viewer.stat == DEAD)
		hide()
		return
	screens[ARMOLEX_HUD_FRAME] = viewer.overlay_fullscreen(ARMOLEX_HUD_FRAME, frame_type)
	screens[ARMOLEX_HUD_TITLE] = viewer.overlay_fullscreen(ARMOLEX_HUD_TITLE, /atom/movable/screen/fullscreen/armolex_text)
	var/atom/movable/screen/fullscreen/armolex_text/charge/readout = viewer.overlay_fullscreen(ARMOLEX_HUD_CHARGE, charge_type)
	screens[ARMOLEX_HUD_CHARGE] = readout
	var/charge = mod.core?.max_charge_amount() ? clamp(round(mod.get_charge_percent()), 0, 100) : 0
	readout.set_charge(charge)

/datum/armolex_hud/proc/hide()
	for(var/category in screens)
		if(viewer?.fullscreens[category] == screens[category])
			viewer.clear_fullscreen(category, 0)
	screens.Cut()

/datum/armolex_hud/special_ops
	frame_type = /atom/movable/screen/fullscreen/scaled/armolex/special_ops
	charge_type = /atom/movable/screen/fullscreen/armolex_text/charge/special_ops

/atom/movable/screen/fullscreen/scaled/armolex
	icon = 'modular_bluemoon/fluffs/icons/armolex_visor.dmi'
	icon_state = "panoramic"

/atom/movable/screen/fullscreen/scaled/armolex/SetSeverity(severity)
	src.severity = severity

/atom/movable/screen/fullscreen/scaled/armolex/special_ops
	icon_state = "special_ops"

/atom/movable/screen/fullscreen/armolex_text
	icon = null
	screen_loc = "CENTER:-64,NORTH:-20"
	maptext_width = 160
	maptext_height = 20
	maptext = "<div align='center' style='font-family: Consolas; font-size: 9pt; color: #dce8ef; -dm-text-outline: 1px #080d13'>ARMOLEX</div>"

/atom/movable/screen/fullscreen/armolex_text/SetSeverity(severity)
	src.severity = severity

/atom/movable/screen/fullscreen/armolex_text/charge
	icon = 'modular_bluemoon/fluffs/icons/armolex_charge.dmi'
	icon_state = "base"
	screen_loc = "WEST:48,SOUTH:56"
	maptext_width = 128
	maptext_height = 32
	maptext_y = 8
	maptext = ""
	var/last_charge
	var/text_color = "#c7a2ff"
	var/mutable_appearance/bar

/atom/movable/screen/fullscreen/armolex_text/charge/Initialize(mapload)
	. = ..()
	bar = mutable_appearance(icon, "fill")
	bar.color = text_color

/atom/movable/screen/fullscreen/armolex_text/charge/Destroy()
	bar = null
	return ..()

/atom/movable/screen/fullscreen/armolex_text/charge/proc/set_charge(charge)
	if(!isnull(last_charge) && charge == last_charge)
		return
	last_charge = charge
	var/fraction = charge / 100
	bar.transform = matrix(fraction, 0, (fraction - 1) * maptext_width / 2, 0, 1, 0)
	overlays = list(bar)
	maptext = "<span style='font-family: Consolas; font-size: 8pt; color: [text_color]; -dm-text-outline: 1px #080d13'>ЗАРЯД [charge]%</span>"

/atom/movable/screen/fullscreen/armolex_text/charge/special_ops
	screen_loc = "WEST:34,CENTER:72"
	text_color = "#8ad6ef"

#undef ARMOLEX_HUD_FRAME
#undef ARMOLEX_HUD_TITLE
#undef ARMOLEX_HUD_CHARGE

/obj/item/mod/control/pre_equipped/mining/anomalous_archeotech
	desc = "Высокотехнологичный MOD костюм, который встраивается напрямую в тело, невидимое энергетическое поле, защищает владельца от давления извне. \
	Управление происходит через специальный интерфейс мозг компьютер, который подключается не инвазивно. \
	Встроенные ядра аномалий, обеспечивают стабильность работы и работу энергетического поля"
	alternate_worn_layer = BACK_LAYER
	theme = /datum/mod_theme/cargo_default/mining/anomalous_archeotech

/obj/item/mod/construction/armor/anomalous_archeotech
	theme = /datum/mod_theme/cargo_default/mining/anomalous_archeotech

/datum/mod_theme/cargo_default/mining/anomalous_archeotech
	name = "anomalous archeotech"
	default_skin = "anom_arch"
	ui_theme = "hackerman"
	skins = list(
		"anom_arch" = list(
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR|HIDEEARS|HIDEHAIR|HIDESNOUT,
				SEALED_INVISIBILITY = HIDEEYES|HIDEFACE,
				SEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = null
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			CONTROL_LAYER = BACK_LAYER
		),
	)

//////////////////////////////////////////////////////////
/obj/item/modsuit_modkit/syndicate_sec
	name = "Syndicate MODsuit theme Kit"
	new_theme = /datum/mod_theme/antagonist/syndicate

/obj/item/mod/control/pre_equipped/magnate/heavy
	theme =/datum/mod_theme/centcom/magnate/heavy

/obj/item/mod/construction/armor/magnate/heavy
	theme = /datum/mod_theme/centcom/magnate/heavy

/datum/mod_theme/centcom/magnate/heavy
	name = "heavy magnate"
	ui_theme = "magnateHeavy"
	default_skin = "magnateHeavy"
	skins = list(
		"magnateHeavy" = list(
			HELMET_LAYER = NECK_LAYER,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = NONE,
				SEALED_CLOTHING = THICKMATERIAL|STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR,
				SEALED_INVISIBILITY = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDESNOUT,
				SEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
	)

//////////////////////////////////////////////////////////

/obj/item/modsuit_modkit/catcrin
	name = "Mark45 MODsuit theme Kit"
	icon_state = "mk45"
	new_theme = /datum/mod_theme/station_combat/security/catcrin

/datum/mod_theme/station_combat/security/catcrin
	name = "Mark45"
	default_skin = "mark45mod"
	skins = list(
		"mark45mod" = list(
			HELMET_LAYER = null,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR|HIDEEARS,
				SEALED_INVISIBILITY = HIDEMASK|HIDEEYES|HIDEFACE|HIDEHAIR,
				UNSEALED_COVER = HEADCOVERSMOUTH,
				SEALED_COVER = HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
)
//////////////////////////////////////////////////////////

/obj/item/modsuit_modkit/lapkee
	name = "Concord MODsuit theme Kit"
	icon_state = "lapkee_modkit"
	new_theme = /datum/mod_theme/station_combat/security/concord

/obj/item/mod/control/pre_equipped/concord
	theme = /datum/mod_theme/station_combat/security/concord

/obj/item/mod/construction/armor/concord
	theme = /datum/mod_theme/station_combat/security/concord

/datum/mod_theme/station_combat/security/concord
	name = "Concord"
	default_skin = "concord"
	skins = list(
		"concord" = list(
			HELMET_LAYER = null,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR,
				SEALED_INVISIBILITY = HIDEMASK|HIDEEYES|HIDEHAIR,
				UNSEALED_COVER = HEADCOVERSMOUTH,
				SEALED_COVER = HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
)

/obj/item/modsuit_modkit/melatonin
	name = "Fairweather MODsuit theme Kit"
	icon_state = "melatonin_modkit"
	new_theme = /datum/mod_theme/station_combat/security/melatonin

/obj/item/mod/control/pre_equipped/melatonin
	theme = /datum/mod_theme/station_combat/security/melatonin

/obj/item/mod/construction/armor/melatonin
	theme = /datum/mod_theme/station_combat/security/melatonin

/datum/mod_theme/station_combat/security/melatonin
	name = "Fairweather L-601"
	desc = "Лёгкий экспериментальный прототип, никогда не предназначавшийся для публики. Сильно повреждён и восстановлен кустарным образом вдали от лабораторий Fairweather. Бывшая белая окраска скрыта под матовым чёрным покрытием, потемневшим вместе с неокрашиваемыми элементами. На броне — потёртости, следы когтей и старого ремонта. Поверх новой окраски нанесены едва различимые галогеновые знаки Ревашольской Гражданской Милиции."
	overwrite_desc = TRUE
	default_skin = "luna"
	skins = list(
		"luna" = list(
			HELMET_LAYER = null,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR,
				SEALED_INVISIBILITY = HIDEMASK|HIDEEYES|HIDEHAIR,
				UNSEALED_COVER = HEADCOVERSMOUTH,
				SEALED_COVER = HEADCOVERSEYES,
			),
			CHESTPLATE_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT|HIDETAIL,
			),
			GAUNTLETS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
			BOOTS_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
			),
		),
)
