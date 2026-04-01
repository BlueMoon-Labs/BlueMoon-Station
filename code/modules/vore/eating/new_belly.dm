//DESC - START
#define BELLY_MAIN_DESC "main_desc"
#define BELLY_ABSORBED_DESC "absorb_desc"
#define BELLY_EGG

//DESC - END

//BELLY DAMAGES - START
#define ALLOWED_BELLY_TYPES_DAMAGE list(BRUTE, BURN, TOX, OXY, CLONE, STAMINA)
#define MAX_BELLY_DAMAGE 30

//BELLY DAMAGES - END

//VORE VERBS - START
#define VORE_VERB_INGEST "ingest_vore_verb"
#define VORE_VERB_RELEASE "release_vore_verb"

//VORE VERBS - END

//VORE EMOTES - START

#define VORE_EMOTE_DELAY (60 SECONDS)

//VORE EMOTES - END

//VORE BELLY FLAGS - START

#define VORE_BELLY_FLAG_IMMUTABLE (1 << 0)	//Удалять нельзя, помиловать
#define VORE_BELLY_FLAG_ESCAPABLE (1 << 1)	//Сбегать нельзя, помиловать
#define VORE_BELLY_FLAG_NO_MODE_DESCS (1 << 2)	//Не менять описание под режим
#define VORE_BELLY_FLAG_NO_ABSORB_DESC (1 << 3)	//Не юзать сообщение абсорба

//VORE BELLY FLAGS - END

//VORE SOUNDS - START
#define VORE_BELLY_INGEST_SOUND "ingest_sound"
#define VORE_BELLY_RELEASE_SOUND "release_sound"
#define VORE_BELLY_TRANSFER_SOUND "transfer_sound"

//VORE SOUNDS - END

/mob/atom/var/list/new_belly/belly_prototypes


/obj/new_belly
	name = "belly"

	var/belly_flags = NONE
	var/belly_mode = DM_HOLD

	var/mob/_owner
	var/list/modifers

	var/list/dm_mode/digest_modes = list()
	var/list/dm_modifer/dm_modifers


	//Основной лист с описанием
	var/list/static_descs = list(
		BELLY_MAIN_DESC = "It's a belly! You're in it!",
		BELLY_ABSORBED_DESC = ""
	)

	//Вспомогательный лист с описаниями, будет дополнятся к первому описывая режим работы
	var/list/belly_mode_descs = list(
		DM_HOLD = "Вы просто лежите"
	)

	var/list/vore_verbs = list(
		VORE_VERB_INGEST = "ingest",

	)

	var/list/vore_sounds = list(
		VORE_BELLY_INGEST_SOUND = "Gulp",
		VORE_BELLY_RELEASE_SOUND = "Splatter",
		VORE_BELLY_TRANSFER_SOUND = "Swallow"

	)

	var/list/damage_types = list(
		BRUTE = 2,
		BURN = 2,
		TOX = 0,
		OXY = 0,
		CLONE = 0,
		STAMINA = 0
	)
	//Шанс врубить определенный режим при резисте
	var/list/mode_chances = list(
		DM_ABSORB = 0,
		DM_DIGEST = 0,
		DM_HEAL = 0,
		DM_HOLD = 0,
		DM_NOISY = 0,
		DM_UNABSORB = 0
	)

	var/list/transfer_locations = list() // : string[]

	var/transfer_chance = 0; //0 - Трансфера нет

	var/list/auto_transfer_locations = list()  // : string[]

	var/auto_transfer_time = 0; //0 - Трансфера нет
	var/auto_transfer_chance  = 0; //0 - Трансфера нет

	//Для визуальной хуеты
	var/color1 = "#692525"
	var/color2 = "#ffffff"
	var/color3 = "#ffffff"
	var/color4 = "#ffffff"
	var/background_vore_type

	var/list/atom/movable/_atoms_to_process

/mob/var/vore_prefs

/obj/new_belly/proc/link_to(mob/mob_to_link)
	LAZYACCESS()



/obj/new_belly/proc/process_belly(var/delta_time = 1)
	for(var/atom/atom_to_process as anything in src.contents)
		var/i = 0

