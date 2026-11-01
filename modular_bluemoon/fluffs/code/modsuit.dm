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
	to_chat(user, span_notice("Оформление MOD-костюма изменено."))
	qdel(src)
	return TRUE

/obj/item/modsuit_modkit/pre_attack(atom/target, mob/living/user, params, attackchain_flags, damage_multiplier)
	if(!istype(target, /obj/item/mod/control))
		return ..()
	apply_skin(target, user)
	return STOP_ATTACK_PROC_CHAIN

/obj/item/modsuit_modkit/armolex
	name = "Armolex MODsuit theme Kit"
	new_theme = /datum/mod_theme/armolex

/datum/mod_theme/armolex
	name = "Armolex"
	default_skin = "armolex"
	skins = list("armolex" = MOD_PRESET_DEFAULT)

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
