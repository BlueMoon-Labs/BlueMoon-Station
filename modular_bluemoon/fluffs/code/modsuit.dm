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

/obj/item/mod/control/pre_equipped/security/syndicate
	theme = /datum/mod_theme/security/syndicate

/obj/item/mod/construction/armor/security/syndicate
	theme = /datum/mod_theme/security/syndicate

/datum/mod_theme/security/syndicate
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
