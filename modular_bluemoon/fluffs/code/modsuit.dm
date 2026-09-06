/obj/item/modsuit_modkit
	name = "MODsuit theme modification Kit"
	desc = "Набор для изменения стиля МОД костюма на особый, персонализированный окрас."
	icon = 'modular_bluemoon/fluffs/icons/obj/MOD_modkit.dmi'
	icon_state = "base_modkit"
	var/datum/mod_theme/new_theme = /datum/mod_theme
	var/datum/mod_theme/from_theme = /datum/mod_theme

/obj/item/modsuit_modkit/Initialize(mapload)
	. = ..()
	new_theme = GLOB.mod_themes[new_theme]
	from_theme = GLOB.mod_themes[from_theme]

/obj/item/modsuit_modkit/proc/apply_theme(obj/item/mod/control/modsuit, mob/living/user)
	if(!new_theme)
		return
	if(from_theme != modsuit.theme)
		to_chat(user, span_big_warning("Не подходит!"))
		return
	modsuit.theme = new_theme
	modsuit.theme.setup_theme(modsuit, new_theme.default_skin)
	modsuit.skin = new_theme.default_skin
	if(modsuit.theme.name == new_theme.name)
		new_theme = null
		qdel(src)

/obj/item/mod/control/attackby(obj/item/attacking_item, mob/living/user, params)
	var/obj/item/modsuit_modkit/modkit
	if(istype(attacking_item, /obj/item/modsuit_modkit))
		modkit = attacking_item
		modkit.apply_theme(src, user)
	. = ..()

/obj/item/mod/control/pre_equipped/mining/anomalous_archeotech
	desc = "Высокотехнологичный MOD костюм, который встраивается напрямую в тело, невидимое энергетическое поле, защищает владельца от давления извне. \
	Управление происходит через специальный интерфейс мозг компьютер, который подключается не инвазивно. \
	Встроенные ядра аномалий, обеспечивают стабильность работы и работу энергетического поля"
	alternate_worn_layer = BACK_LAYER
	theme = /datum/mod_theme/mining/anomalous_archeotech

/obj/item/mod/construction/armor/anomalous_archeotech
	theme = /datum/mod_theme/mining/anomalous_archeotech

/datum/mod_theme/mining/anomalous_archeotech
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
//Описание темы изменено по запросу владельца донатерки.
/obj/item/modsuit_modkit/syndicate_sec
	name = "Syndicate MODsuit theme Kit"
	new_theme = /datum/mod_theme/security/syndicate
	from_theme = /datum/mod_theme/security

/obj/item/mod/control/pre_equipped/security/syndicate
	theme = /datum/mod_theme/security/syndicate

/obj/item/mod/construction/armor/security/syndicate
	theme = /datum/mod_theme/security/syndicate

/datum/mod_theme/security/syndicate
	name = "Syndicate Vanguard Security"
	desc = "Экспериментальный модульный скафандр службы безопасности Syndicate, построенный на легализованном базисе \
	  технологий NanoTrasen и модификаций компании Cybersun Industries. Комплект совмещает бронирование СБ с технологиями\
	  автономности для контроля бунтов, задержания опасных целей и долгой работы в разгерметизированных отсеках. \
	  В основе конструкции лежит стандартный костюм Охраны перехваченный, переработанный и оптимизированный Syndicate"
	ui_theme = "syndicate"
	default_skin = "syndicate"
	skins = list(
		"syndicate" = list(
			HELMET_LAYER = null,
			HELMET_FLAGS = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE|ALLOWINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR|HIDEEARS|HIDEHAIR|HIDESNOUT,
				SEALED_INVISIBILITY = HIDEMASK|HIDEEYES|HIDEFACE,
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

/obj/item/mod/control/pre_equipped/magnate/heavy
	theme = /datum/mod_theme/magnate/heavy

/obj/item/mod/construction/armor/magnate/heavy
	theme = /datum/mod_theme/magnate/heavy

/datum/mod_theme/magnate/heavy
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
	new_theme = /datum/mod_theme/security/catcrin
	from_theme = /datum/mod_theme/security

/datum/mod_theme/security/catcrin
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
	new_theme = /datum/mod_theme/security/concord
	from_theme = /datum/mod_theme/security

/obj/item/mod/control/pre_equipped/concord
	theme = /datum/mod_theme/security/concord

/obj/item/mod/construction/armor/concord
	theme = /datum/mod_theme/security/concord

/datum/mod_theme/security/concord
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

//////////////////////////////////////////////////////////
