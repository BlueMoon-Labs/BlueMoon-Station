#define MOD_PRESET_DEFAULT list( \
			HELMET_LAYER = NECK_LAYER,\
			HELMET_FLAGS = list( \
				UNSEALED_CLOTHING = NONE,\
				SEALED_CLOTHING = THICKMATERIAL|STOPSPRESSUREDAMAGE|ALLOWINTERNALS,\
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR,\
				SEALED_INVISIBILITY = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR,\
				SEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,\
			),\
			CHESTPLATE_FLAGS = list( \
				UNSEALED_CLOTHING = THICKMATERIAL,\
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,\
				SEALED_INVISIBILITY = HIDEJUMPSUIT,\
			),\
			GAUNTLETS_FLAGS = list(\
				UNSEALED_CLOTHING = THICKMATERIAL,\
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,\
			),\
			BOOTS_FLAGS = list(\
				UNSEALED_CLOTHING = THICKMATERIAL,\
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,\
			),\
		)\

#define MOD_PRESET_WITHOUT_PRESSURE_PROTECT list( \
			HELMET_LAYER = NECK_LAYER,\
			HELMET_FLAGS = list( \
				UNSEALED_CLOTHING = NONE,\
				SEALED_CLOTHING = THICKMATERIAL|ALLOWINTERNALS,\
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR,\
				SEALED_INVISIBILITY = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR,\
				SEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,\
			),\
			CHESTPLATE_FLAGS = list( \
				UNSEALED_CLOTHING = THICKMATERIAL,\
				SEALED_INVISIBILITY = HIDEJUMPSUIT,\
			),\
			GAUNTLETS_FLAGS = list( \
				UNSEALED_CLOTHING = THICKMATERIAL,\
			),\
			BOOTS_FLAGS = list( \
				UNSEALED_CLOTHING = THICKMATERIAL,\
			),\
		),\

#define MOD_PRESET_WITHOUT_PRESSURE_PROTECT_NO_JUMSUIT_HIDE list( \
			HELMET_LAYER = NECK_LAYER,\
			HELMET_FLAGS = list( \
				UNSEALED_CLOTHING = NONE,\
				SEALED_CLOTHING = THICKMATERIAL|ALLOWINTERNALS,\
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR,\
				SEALED_INVISIBILITY = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR,\
				SEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES,\
			),\
			CHESTPLATE_FLAGS = list( \
				UNSEALED_CLOTHING = THICKMATERIAL,\
				SEALED_INVISIBILITY = null, \
			),\
			GAUNTLETS_FLAGS = list( \
				UNSEALED_CLOTHING = THICKMATERIAL,\
			),\
			BOOTS_FLAGS = list( \
				UNSEALED_CLOTHING = THICKMATERIAL,\
			),\
		)

#define ALLOWED_DEFAULT list(/obj/item/flashlight, /obj/item/tank/internals, /obj/item/device/cooler)

#define ALLOWED_ENGINERING list(/obj/item/t_scanner,\
								/obj/item/construction/rcd,\
								/obj/item/pipe_dispenser,)

//тоже самое что и GLOB.security_hardsuit_allowed
//Используется в: СБ, ГСБ, капитан, БЩ, киберсан, РД хев версия
#define ALLOWED_SECURITY list(/obj/item/ammo_box,\
								/obj/item/ammo_casing,\
								/obj/item/gun,\
								/obj/item/melee,\
								/obj/item/reagent_containers/spray,\
								/obj/item/electrostaff,\
								/obj/item/restraints,)

#define ALLOWED_MEDICAL list(/obj/item/storage/firstaid,\
							/obj/item/healthanalyzer,\
							/obj/item/stack/medical,\
							/obj/item/gun/medbeam,)

#define ALLOWED_SCIENCE list(/obj/item/gun/energy/wormhole_projector,\
							/obj/item/hand_tele,\
							/obj/item/aicard,)

#define ALLOWED_CARGO list(/obj/item/storage/bag/ore,\
							/obj/item/pickaxe,\
							/obj/item/resonator,\
							/obj/item/gun/energy/kinetic_accelerator,)

#define ALLOWED_ANTAG list(/obj/item/ammo_box,\
							/obj/item/ammo_casing,\
							/obj/item/gun,\
							/obj/item/melee,\
							/obj/item/reagent_containers/spray,\
							/obj/item/electrostaff,\
							/obj/item/restraints,\
							/obj/item/teleportation_scroll,)
