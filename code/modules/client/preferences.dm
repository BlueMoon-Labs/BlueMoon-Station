GLOBAL_LIST_EMPTY(preferences_datums)

/datum/preferences
	var/client/parent
	var/path
	var/vr_path
	var/default_slot = 1				//Holder so it doesn't default to slot 1, rather the last one used
	var/max_save_slots = 40
	var/character_slot_name = ""
	var/last_ip
	/// Last CID the person was seen on
	var/last_id
	/// Do we log their clicks to disk?
	var/log_clicks = FALSE
	/// Characters they have joined the round under - Lazylist of names
	var/list/characters_joined_as
	/// Slots they have joined the round under - Lazylist of numbers
	var/list/slots_joined_as
	/// Are we currently subject to respawn restrictions? Usually set by us using the "respawn" verb, but can be lifted by admins.
	var/respawn_restrictions_active = FALSE
	/// time of death we consider for respawns
	var/respawn_time_of_death = -INFINITY
	/// did they DNR? used to prevent respawns.
	var/dnr_triggered = FALSE
	/// did they cryo on their last ghost?
	var/respawn_did_cryo = FALSE

	// Intra-round persistence end

	var/icon/custom_holoform_icon
	var/list/cached_holoform_icons
	var/last_custom_holoform = 0

	// Character Directory
	var/show_in_directory = 1	//Show in Character Directory
	var/directory_tag = "Unset" //Sorting tag to use in character directory
	var/directory_erptag = "Unset"	//ditto, but for non-vore scenes
	var/directory_gendertag = "Unset"	//Gender tag for character directory
	var/directory_ad = ""		// Char directory ERP tag
	var/directory_noncon = null	// Char directory Non-con tag

	//Cooldowns for saving/loading. These are four are all separate due to loading code calling these one after another
	COOLDOWN_DECLARE(saveprefcooldown)
	COOLDOWN_DECLARE(loadprefcooldown)
	COOLDOWN_DECLARE(savecharcooldown)
	COOLDOWN_DECLARE(loadcharcooldown)

	//game-preferences
	var/lastchangelog = ""				//Saved changlog filesize to detect if there was a change
	var/custom_colors = TOGGLES_DEFAULT_CUSTOM_COLORS
	var/ooccolor = "#c43b23"
	var/aooccolor = "#ce254f"
	var/enable_tips = TRUE
	var/tip_delay = 500 //tip delay in milliseconds

	//Antag preferences
	var/list/be_special = list()		//Special role selection. ROLE_INTEQ being missing means they will never be antag!
	var/tmp/old_be_special = 0			//Bitflag version of be_special, used to update old savefiles and nothing more
										//If it's 0, that's good, if it's anything but 0, the owner of this prefs file's antag choices were,
										//autocorrected this round, not that you'd need to check that.

	var/UI_style = null
	var/outline_enabled = TRUE
	var/outline_color = COLOR_THEME_MIDNIGHT
	var/screentip_pref = SCREENTIP_PREFERENCE_ENABLED
	var/screentip_color = "#ffd391"
	var/screentip_images = TRUE
	var/hotkeys = TRUE

	///Runechat preference. If true, certain messages will be displayed on the map, not ust on the chat area. Boolean.
	var/chat_on_map = TRUE
	///Runechat preference for looc
	var/chat_on_map_looc = TRUE
	///Limit preference on the size of the message. Requires chat_on_map to have effect.
	var/max_chat_length = CHAT_MESSAGE_MAX_LENGTH
	///Whether non-mob messages will be displayed, such as machine vendor announcements. Requires chat_on_map to have effect. Boolean.
	var/see_chat_non_mob = TRUE
	var/runechat_anim = RUNECHAT_ANIM_RISE
	/// Custom Keybindings
	var/list/key_bindings = list()
	/// List with a key string associated to a list of keybindings. Unlike key_bindings, this one operates on raw key, allowing for binding a key that triggers regardless of if a modifier is depressed as long as the raw key is sent.
	var/list/modless_key_bindings = list()

	var/tgui_fancy = TRUE
	var/tgui_lock = TRUE
	var/tgui_input_mode = TRUE			// All the Input Boxes (Text,Number,List,Alert)
	var/tgui_input_verbs = TRUE 		// Все частоиспользуемые вербы: SAY, ME, OOC и т.д.
	var/tgui_large_buttons = TRUE
	var/tgui_swapped_buttons = FALSE
	var/tgui_panel_theme = "default"
	var/tgui_panel_state = ""
	var/character_setup_theme = "default"
	var/character_setup_single_view = FALSE
	var/character_setup_autosave = FALSE
	var/character_setup_preset_autosave = FALSE
	var/character_slot_name_replace = FALSE
	var/list/ui_zoom_preferences = list()
	var/windowflashing = TRUE
	var/adminhelp_windowflash = TRUE
	var/windownoise = TRUE
	var/mood_vignette = TRUE
	var/toggles = TOGGLES_DEFAULT
	var/sound_toggles = SOUND_BUTTONS
	/// A separate variable for deadmin toggles, only deals with those.
	var/deadmin = DEADMIN_AUTODMENTOR
	var/mentor_toggles = SOUND_MENTORHELP
	var/db_flags
	var/chat_toggles = TOGGLES_DEFAULT_CHAT
	/// Bitfield for chat mutes (MUTE_* flags).
	var/muted = NONE
	var/ticket_nickname = ""
	var/ghost_form = "ghost"
	var/ghost_orbit = GHOST_ORBIT_CIRCLE
	var/ghost_accs = GHOST_ACCS_DEFAULT_OPTION
	var/ghost_others = GHOST_OTHERS_DEFAULT_OPTION
	var/inquisitive_ghost = 1
	var/allow_midround_antag = 1
	var/preferred_map = null
	var/disable_combat_cursor = FALSE
	var/disable_combat_mouse_lock = FALSE
	var/smartlink = TRUE //BLUEMOON ADD: показывать боевой HUD (счётчик патронов); выключается квирком "Несовместимость со смартлинком"
	var/tg_playerpanel = "TG"
	var/pda_style = MONO
	var/pda_color = "#808000"
	var/pda_skin = PDA_SKIN_ALT
	var/pda_ringtone = "beep"
	var/pda_theme = PDA_THEME_NTOS
	var/list/alt_titles_preferences = list()

	// Modern UI translations
	var/use_modern_translations = TRUE		// Enable modern translation system for UI elements
	var/modern_ui_language = 0				// 0 = English, 1 = Russian

	var/hardsuit_tail_style = null // Пока не используется. Вскоре нужно будет бахнуть новых спрайтов.
	var/custom_blood_color = FALSE
	var/blood_color = BLOOD_COLOR_UNIVERSAL

	var/uses_glasses_colour = 0
	var/surgical_disable_radial = FALSE 		// BLUEMOON ADD
	var/chem_dispenser_classic_view = TRUE		// BLUEMOON ADD - classic flat grid vs categorized view
	var/chem_dispenser_use_reagent_color = TRUE	// BLUEMOON ADD - show reagent color vs pH color on buttons
	var/chem_dispenser_show_icons = TRUE		// BLUEMOON ADD - show/hide reagent icons on buttons
	var/chem_dispenser_alphabetical_sort = TRUE	// BLUEMOON ADD - alphabetical vs declaration order in classic view
	var/ie_classic_circuit_ui = FALSE			// BLUEMOON ADD - integrated electronics: HTML browser UI vs TGUI
	var/neural_interface_visibility = TRUE      // BLUEMOON ADD - neural interface visibility flag

	// BLUEMOON ADD START || Colormate presets
	// Листы состоят из ключа, типа предмета и листа с именами престов и настройками цвета
	var/list/color_presets_tint = list() // Пример: list(/obj/item/clothing = list("Стандарт" = "#ffffff"))
	var/list/color_presets_hsv = list() // Пример: list(/obj/item/clothing = list("Стандарт" = list("hue" = 0, "sat" = 1, "val" = 1)))
	var/list/color_presets_matrix = list() // Пример: list(/obj/item/clothing = list("Стандарт" = list(1,0,0,0,1,0,0,0,1,0,0,0)))
	var/tmp/datum/loadout_color_handler/loadout_color_handler
	// BLUEMOON ADD END

	// BLUEMOON ADD START || Phobia selection
	var/phobia_type = null
	// BLUEMOON ADD END

	//character preferences
	var/real_name							//our character's name
	var/nameless = FALSE					//whether or not our character is nameless
	var/be_random_name = FALSE				//whether we'll have a random name every round
	var/be_random_body = FALSE				//whether we'll have a random body every round
	var/gender = MALE						//gender of character (well duh)
	var/age = 30							//age of character
	//Sandstorm CHANGES BEGIN
	var/erppref = "Ask"
	var/nonconpref = "No"
	var/vorepref = "Ask"
	var/mobsexpref = "No" 					//Added by Gardelin0 - Sex(mostly non-con) with hostile mobs(tentacles)
	var/tattoopref = "Ask"					//BLUEMOON ADD - Tattoo consent preference
	var/extremepref = "No" 					//This is for extreme shit, maybe even literal shit, better to keep it on no by default
	var/extremeharm = "No" 					//If "extreme content" is enabled, this option serves as a toggle for the related interactions to cause damage or not
	var/see_chat_emotes = TRUE
	var/view_pixelshift = FALSE
	var/enable_personal_chat_color = FALSE
	var/personal_chat_color = "#ffffff"
	var/lust_tolerance = 100
	var/sexual_potency = 15
	//Sandstorm CHANGES END
	var/underwear = "Nude"				//underwear type
	var/undie_color = "FFFFFF"
	var/undershirt = "Nude"				//undershirt type
	var/shirt_color = "FFFFFF"
	var/socks = "Nude"					//socks type
	var/socks_color = "FFFFFF"
	var/backbag = DBACKPACK				//backpack type
	var/jumpsuit_style = PREF_SUIT		//suit/skirt
	var/hair_style = "Bald"				//Hair type
	var/hair_color = "000000"				//Hair color
	var/facial_hair_style = "Shaved"	//Face hair type
	var/facial_hair_color = "000000"		//Facial hair color
	var/grad_style						//Hair gradient style
	var/grad_color = "FFFFFF"			//Hair gradient color
	var/skin_tone = "caucasian1"		//Skin color
	var/use_custom_skin_tone = FALSE
	var/left_eye_color = "000000"		//Eye color
	var/right_eye_color = "000000"
	var/eye_type = DEFAULT_EYES_TYPE	//Eye type
	var/split_eye_colors = FALSE
	var/datum/species/pref_species = new /datum/species/human()	//Mutant race
	var/list/features = list(
"mcolor" = "FFFFFF",
"mcolor2" = "FFFFFF",
"mcolor3" = "FFFFFF",
"tail_lizard" = "Smooth",
"tail_human" = "None",
"snout" = "Round",
"horns" = "None",
"horns_color" = "85615a",
"ears" = "None",
"wings" = "None",
"wings_color" = "FFF",
"insect_fluff_color" = null,
"insect_markings_color" = null,
"frills" = "None",
"deco_wings" = "None",
"spines" = "None",
"legs" = "Plantigrade",
"insect_wings" = "Plain",
"insect_fluff" = "None",
"insect_markings" = "None",
"arachnid_legs" = "Plain",
"arachnid_spinneret" = "Plain",
"arachnid_mandibles" = "Plain",
"mam_body_markings" = list(),
"allow_emissives" = FALSE,
"emissive_parts" = list(),
"mam_ears" = "None",
"mam_snouts" = "None",
"mam_tail" = "None",
"mam_tail_animated" = "None",
"xenodorsal" = "None",
"xenohead" = "None",
"xenotail" = "Xenomorph Tail",
"taur" = "None",
"hardsuit_with_tail" = FALSE,
"genitals_use_skintone" = FALSE,
"has_cock" = FALSE,
"cock_shape" = DEF_COCK_SHAPE,
"cock_length" = COCK_SIZE_DEF,
"cock_diameter_ratio" = COCK_DIAMETER_RATIO_DEF,
"cock_color" = "ffffff",
"cock_taur" = FALSE,
"has_balls" = FALSE,
"balls_color" = "ffffff",
"balls_shape" = DEF_BALLS_SHAPE,
"balls_size" = BALLS_SIZE_DEF,
"balls_cum_rate" = CUM_RATE,
"balls_cum_mult" = CUM_RATE_MULT,
"balls_fluid" = /datum/reagent/consumable/semen,
"balls_efficiency" = CUM_EFFICIENCY,
"has_breasts" = FALSE,
"breasts_color" = "ffffff",
"breasts_sprite_variant" = "New",
"breasts_nipples" = FALSE,
"breasts_nipples_color" = "ffffff",
"breasts_size" = BREASTS_SIZE_DEF,
"breasts_shape" = DEF_BREASTS_SHAPE,
"breasts_fluid" = /datum/reagent/consumable/milk,
"breasts_producing" = FALSE,
"has_vag" = FALSE,
"vag_shape" = DEF_VAGINA_SHAPE,
"vag_color" = "ffffff",
"has_womb" = FALSE,
"womb_fluid" = /datum/reagent/consumable/semen/femcum,
"has_butt" = FALSE,
"butt_color" = "ffffff",
"butt_size" = BUTT_SIZE_DEF,
"has_belly" = FALSE,
"has_anus" = FALSE,
"anus_color" = "ffffff",
"anus_shape" = DEF_ANUS_SHAPE,
"belly_color" = "ffffff",
"belly_size" = BELLY_SIZE_DEF,
"balls_visibility"  = GEN_VISIBLE_NO_UNDIES,
"breasts_visibility"= GEN_VISIBLE_NO_UNDIES,
"cock_visibility" = GEN_VISIBLE_NO_UNDIES,
"vag_visibility"   = GEN_VISIBLE_NO_UNDIES,
"butt_visibility" = GEN_VISIBLE_NO_UNDIES,
"belly_visibility" = GEN_VISIBLE_NO_UNDIES,
"anus_visibility" = GEN_VISIBLE_NO_UNDIES,
"breasts_accessible" = FALSE,
"cock_accessible" = FALSE,
"balls_accessible" = FALSE,
"vag_accessible" = FALSE,
"butt_accessible" = FALSE,
"anus_accessible" = FALSE,
"belly_accessible" = FALSE,
"cock_stuffing" = FALSE,
"balls_stuffing" = FALSE,
"vag_stuffing" = FALSE,
"breasts_stuffing" = FALSE,
"butt_stuffing" = FALSE,
"belly_stuffing" = FALSE,
"anus_stuffing" = FALSE,
"inert_eggs" = FALSE,
"ipc_screen" = "Sunburst",
"ipc_antenna" = "None",
"flavor_text" = "",
"naked_flavor_text" = "", //SPLURT edit
"silicon_flavor_text" = "",
"custom_species_lore" = "",
"custom_deathgasp" = "застывает и падает без сил, глаза мертвы и безжизненны...", // BLUEMOON ADD - пользовательский эмоут смерти
"custom_deathsound" = "По умолчанию", // BLUEMOON ADD - пользовательский эмоут смерти
"ooc_notes" = "",
"ass_photo" = "",
"meat_type" = "Mammalian",
"body_model" = MALE,
"body_size" = RESIZE_DEFAULT_SIZE,
"fuzzy" = FALSE,
"color_scheme" = OLD_CHARACTER_COLORING,
"neckfire" = FALSE,
"neckfire_color" = "ffffff",
"puddle_slime_fea" = FALSE
)

	var/list/custom_emote_panel = list() //user custom emote panel

	var/custom_speech_verb = "default" //if your say_mod is to be something other than your races
	var/custom_speech_verb_ru = FALSE // Булевый тумблер использования русских глаголов речи у куклы при сейлогах
	var/custom_tongue = "default" //if your tongue is to be something other than your races
	var/list/language = list() //additional language your character has
	var/modified_limbs = list() //prosthetic/amputated limbs
	var/organ_mods = list()
	var/implant_mods = list()
	var/chosen_limb_id //body sprite selected to load for the users limbs, null means default, is sanitized when loaded

	// Vocal bark prefs
	var/bark_id = "mutedc3"
	var/bark_speed = 4
	var/bark_pitch = 1
	var/bark_variance = 0.2
	COOLDOWN_DECLARE(bark_previewing)
	COOLDOWN_DECLARE(deathsound_preview)	// BLUEMOON ADD - пользовательский эмоут смерти
	COOLDOWN_DECLARE(laugh_preview)			// BLUEMOON ADD - выбор своего смеха

	/// Security record note section
	var/security_records
	/// Medical record note section
	var/medical_records

	var/list/custom_names = list()
	var/preferred_ai_core_display = "Blue"
	var/prefered_security_department = SEC_DEPT_RANDOM
	var/custom_species = null

	//Quirk list
	var/list/all_quirks = list()

	//Quirk category currently selected
	var/quirk_category = QUIRK_POSITIVE // defaults to positive, the first tab!

	//Job preferences 2.0 - indexed by job title , no key or value implies never
	var/list/job_preferences = list()

	// Want randomjob if preferences already filled - Donkie
	var/joblessrole = RETURNTOLOBBY  //defaults to 1 for fewer assistants // BLUEMOON EDIT - было BERANDOMJOB, выставил возвращение в лобби, чтобы не ливали в крио

	var/kb_capture_kb_name
	var/kb_capture_old_key
	var/kb_capture_independent = FALSE

	var/unlock_content = 0

	var/list/ignoring = list()

	var/clientfps = 120

	// Sound volume preferences
	var/sound_volume_midi = 100
	var/sound_volume_ambience = 27
	var/sound_volume_ship_ambience = 35
	var/sound_volume_announcements = 100
	var/sound_volume_bark = 70
	var/sound_volume_prayers = 100
	var/sound_volume_adminhelp = 100
	var/sound_volume_instruments = 100
	var/sound_volume_jukeboxes = 100
	var/sound_volume_personal_jukeboxes = 100
	var/sound_volume_heretic_dance = 100
	var/sound_volume_heretic_sky = 100
	var/sound_volume_emote = 100
	var/sound_volume_mentorhelp = 100
	var/sound_volume_fax = 100

	var/parallax = PARALLAX_INSANE

	var/fullscreen = TRUE

	var/ambientocclusion = TRUE
	var/lighting_blur = LIGHTING_BLUR_DEFAULT
	var/multiz_performance = MULTIZ_PERFORMANCE_DISABLE
	var/multiz_parallax = TRUE
	var/lighting_brightness = LIGHTING_BRIGHTNESS_DEFAULT
	var/lighting_lamp_brightness = LIGHTING_LAMP_BRIGHTNESS_DEFAULT
	var/lighting_bloom_intensity = LIGHTING_BLOOM_INTENSITY_DEFAULT
	var/lighting_quality = LIGHTING_QUALITY_DEFAULT
	///Should we automatically fit the viewport?
	var/auto_fit_viewport = FALSE
	///Should we be in the widescreen mode set by the config?
	var/widescreenpref = TRUE
	///Strip menu style
	var/long_strip_menu = TRUE
	/// Режим ПКМ, RIGHT_CLICK_MODE_*. null - игрок не выбирал, решает конфиг.
	var/right_click_choice = null
	/// Сообщение о режимах ПКМ уже было
	var/right_click_notice_seen = FALSE
	///What size should pixels be displayed as? 0 is strech to fit
	var/pixel_size = 0
	///What scaling method should we use?
	var/scaling_method = "normal"
	var/uplink_spawn_loc = UPLINK_PDA
	///The playtime_reward_cloak variable can be set to TRUE from the prefs menu only once the user has gained over 5K playtime hours. If true, it allows the user to get a cool looking roundstart cloak.
	var/playtime_reward_cloak = FALSE

	var/hud_toggle_flash = TRUE
	var/hud_toggle_color = "#ffffff"

	var/list/exp = list()
	var/list/menuoptions

	var/action_buttons_screen_locs = list()
	var/action_buttons_hide_on_spawn = FALSE

	//bad stuff
	var/vore_flags = 0
	var/list/belly_prefs = list()
	var/vore_taste = ""
	var/vore_smell = ""
	var/toggleeatingnoise = TRUE
	var/toggledigestionnoise = TRUE
	var/hound_sleeper = TRUE
	var/cit_toggles = TOGGLES_CITADEL
	var/body_weight = NAME_WEIGHT_NORMAL
	var/normalized_size = RESIZE_NORMAL
	var/custom_laugh = "Default"
	var/metadollar_minute_pool = 0
	var/list/metadollar_pending_items = list()
	var/list/favorite_interactions
	var/use_arousal_multiplier = FALSE
	var/arousal_multiplier = 100
	var/use_moaning_multiplier = FALSE
	var/moaning_multiplier = 65
	var/use_custom_moan_sounds = FALSE
	var/list/custom_moan_sounds = list()
	var/datum/character_offer_instance/offer

	//backgrounds
	var/mutable_appearance/character_background
	var/icon/bgstate = "steel"
	var/list/bgstate_options = list("000", "midgrey", "FFF", "white", "steel", "techmaint", "dark", "plating", "reinforced")

	var/show_mismatched_markings = FALSE //determines whether or not the markings lists should show markings that don't match the currently selected species. Intentionally left unsaved.

	var/character_settings_tab = GENERAL_CHAR_TAB
	var/preferences_tab = GAME_PREFS_TAB

	var/no_tetris_storage = FALSE

	///loadout stuff
	var/gear_points = 20 // Больше очков - сочнее персонажи.
	var/list/gear_categories
	var/list/list/loadout_data = list()
	var/list/unlockable_loadout_data = list()
	var/loadout_slot = 1 // LOADOUT_PRESET_SLOT или один из общих слотов 1..MAXIMUM_LOADOUT_SAVES.
	var/list/character_presets = list()
	var/active_character_preset
	var/loadout_enabled = TRUE // BLUEMOON ADD - переключатель: спавниться с лодаутом или нет
	var/gear_category
	var/gear_subcategory

	var/screenshake = 100
	var/damagescreenshake = 2
	var/recoil_screenshake = 100
	var/arousable = TRUE
	var/sexknotting = FALSE // BLUEMOON ADD
	var/autostand = TRUE
	var/auto_ooc = FALSE

	///This var stores the amount of points the owner will get for making it out alive.
	var/hardcore_survival_score = 0

	///Someone thought we were nice! We get a little heart in OOC until we join the server past the below time (we can keep it until the end of the round otherwise)
	var/hearted
	///If we have a hearted commendations, we honor it every time the player loads preferences until this time has been passed
	var/hearted_until
	/// If we have persistent scars enabled
	var/persistent_scars = TRUE
	///If we want to broadcast deadchat connect/disconnect messages
	var/broadcast_login_logout = TRUE
	///What outfit typepaths we've favorited in the SelectEquipment menu
	var/list/favorite_outfits = list()
	/// We have 5 slots for persistent scars, if enabled we pick a random one to load (empty by default) and scars at the end of the shift if we survived as our original person
	var/list/scars_list = list("1" = "", "2" = "", "3" = "", "4" = "", "5" = "")
	/// Which of the 5 persistent scar slots we randomly roll to load for this round, if enabled. Actually rolled in [/datum/preferences/proc/load_character(slot)]
	var/scars_index = 1

	var/hide_ckey = FALSE //pref for hiding if your ckey shows round-end or not

	var/list/tcg_cards = list()
	var/list/tcg_decks = list()

	//SPLURT EDIT - gregnancy
	/// Does john spaceman's cum actually impregnate people?
	var/virility = 0
	/// Can john spaceman get gregnant if all conditions are right? (has a womb and is not on contraceptives)
	var/fertility = 0
	/// Does john spaceman look like a gluttonous slob if he pregent?
	var/pregnancy_inflation = FALSE
	/// Self explanitory
	var/pregnancy_breast_growth = FALSE

	var/egg_shell = "chicken"
	//SPLURT END

	var/loadout_errors = 0

	var/pref_queue
	var/char_queue
	/// world.time, позже которого отложенную запись префов больше не переносят.
	/// Каждый вызов внутри кулдауна перевзводил таймер, и игрок, который щёлкает
	/// тумблеры чаще кулдауна, не сохранялся вообще - до самого логаута.
	var/pref_queue_deadline = 0
	/// То же самое для записи персонажа.
	var/char_queue_deadline = 0
	/// Буфер склейки одиночных записей в savefile: ключ -> значение.
	/// Открытие savefile стоит столько же, сколько сама запись, поэтому поток правок
	/// одного ключа копится тут и уходит на диск одним открытием. См. save_single_pref().
	var/list/pending_single_prefs
	/// id таймера, который сбросит буфер одиночных записей на диск.
	var/single_pref_queue
	/// world.time, позже которого сброс буфера одиночных записей больше не переносят.
	var/single_pref_queue_deadline = 0

	var/silicon_lawset

	var/preferred_chaos_level = 2
	var/auto_capitalize_enabled = FALSE

	/// Character Setup browser UI theme (used by the "new" character creator UI).
	/// Supported values: "classic", "modern", "modern_classic", "modern_purple", "modern_green", "modern_neutral"
	var/charcreation_theme = "modern"

	/// Modern character creator: button shape preset (persisted).
	/// Supported values: "rect", "soft", "round".
	var/modern_button_shape = "round"

	/// Modern custom theme (player-configurable palette).
	var/modern_custom_enabled = FALSE
	var/modern_custom_bg_primary = "121212"
	var/modern_custom_bg_secondary = "1c1c1c"
	var/modern_custom_text_primary = "e6e6e6"
	var/modern_custom_text_secondary = "a8a8a8"
	var/modern_custom_button_bg = "1f1f1f"
	var/modern_custom_button_hover = "2a2a2a"
	var/modern_custom_button_active = "4da3ff"
	var/modern_custom_button_text = "0b1c2f"
	var/modern_custom_border_color = "2f2f2f"
	var/modern_custom_accent_color = "4da3ff"
	/// 0 = none, 1 = subtle stripes
	var/modern_custom_bg_pattern = 0
	/// UI-only state (not persisted)
	var/tmp/modern_custom_editor_open = FALSE
	/// UI-only state (not persisted): collapse the top-right theme picker
	var/tmp/modern_theme_picker_collapsed = TRUE /// UI tweak
	/// UI-only state (not persisted): play a one-shot collapse/expand animation on next render
	var/tmp/modern_theme_picker_animate = FALSE
	/// UI-only state (not persisted): open/close the quick settings popover (WIP)
	var/tmp/modern_theme_settings_open = FALSE
	/// UI state: collapse empty character slots in the top slot list (persisted in preferences)
	var/collapse_empty_character_slots = FALSE
	/// Имена персонажей по номеру слота для окна настройки; null - перечитать из сейвфайла
	var/tmp/list/slot_names_cache
	var/tmp/list/slot_custom_names_cache
	/// UI decoration level for modern theme: "minimal" (performance), "standard" (current), "enhanced" (gradients)
	var/ui_decoration_level = "enhanced"
	var/unholypref = "No"
	var/unholyhardpref = "No"
	var/new_character_creator = TRUE
	var/list/gfluid_blacklist = list()
	var/fuzzy = FALSE
	var/list/vending_layouts = list()
	// Пресеты капсул сохраняются в профиле пользователя между раундами.
	var/list/podlauncher_presets = list()

/datum/preferences/proc/get_vending_layout(machine_type)
	return vending_layouts["[machine_type]"] || "grid"

/datum/preferences/proc/set_vending_layout(machine_type, layout)
	if(!(ispath(machine_type, /obj/machinery/vending) || ispath(machine_type, /obj/machinery/smartfridge) || ispath(machine_type, /obj/machinery/equipment_vendor)))
		return FALSE
	if(!(layout in list("grid", "list")) || get_vending_layout(machine_type) == layout)
		return FALSE
	vending_layouts["[machine_type]"] = layout
	save_single_pref("vending_layouts", vending_layouts.Copy())
	var/list/open_uis = parent?.mob?.tgui_open_uis
	for(var/datum/tgui/ui as anything in open_uis?.Copy())
		if(ui.src_object?.type == machine_type)
			ui.send_update()
	return TRUE

/datum/preferences/New(client/C)
	if(!GLOB.genital_fluids_list)
		build_genital_fluids_list()

	parent = C

	for(var/custom_name_id in GLOB.preferences_custom_names)
		custom_names[custom_name_id] = get_default_name(custom_name_id)

	UI_style = GLOB.available_ui_styles[1]
	if(istype(C))
		if(!IsGuestKey(C.key))
			load_path(C.ckey)
			unlock_content = C.IsByondMember() || IS_CKEY_DONATOR_GROUP(C.key, DONATOR_GROUP_TIER_1)
			if(unlock_content)
				max_save_slots += 8
			var/extra_slots = 0
			if(IS_CKEY_DONATOR_GROUP(C.key, DONATOR_GROUP_TIER_3))
				extra_slots = 30
			else if(IS_CKEY_DONATOR_GROUP(C.key, DONATOR_GROUP_TIER_2))
				extra_slots = 20
			else if(IS_CKEY_DONATOR_GROUP(C.key, DONATOR_GROUP_TIER_1))
				extra_slots = 10
			max_save_slots = max_save_slots + extra_slots
	var/loaded_preferences_successfully = load_preferences()
	if(loaded_preferences_successfully)
		if(load_character())
			return
	//we couldn't load character data so just randomize the character appearance + name
	random_character()		//let's create a random character then - rather than a fat, bald and naked man.
	key_bindings = deepCopyList(GLOB.hotkey_keybinding_list_by_key) // give them default keybinds and update their movement keys
	C?.ensure_keys_set(src)
	real_name = pref_species.random_name(gender,1)
	if(!loaded_preferences_successfully)
		save_preferences()
	save_character()		//let's save this new random character so it doesn't keep generating new ones.
	menuoptions = list()
	return

/datum/preferences/Destroy(force)
	// Буфер одиночных записей дописываем: это одно открытие файла и только если
	// в буфере что-то есть. Полную запись (pref_queue/char_queue) НЕ форсируем -
	// она стоит сотню WRITE_FILE, а её данные и так лежат в переменных датума.
	flush_single_prefs()
	if(pref_queue)
		deltimer(pref_queue)
		pref_queue = null
	if(char_queue)
		deltimer(char_queue)
		char_queue = null
	// Оффер персонажа лежит в GLOB.character_offers и нас не переживёт по смыслу: без qdel
	// в глобале остаётся висячая запись с сейвфайлом. Хендлер цвета лодаута держит обратную
	// ссылку на префы - живой хендлер превращает наш снос в харддел.
	QDEL_NULL(offer)
	QDEL_NULL(loadout_color_handler)
	QDEL_NULL(job_menu)
	QDEL_NULL(character_setup_ui)
	// GLOB.preferences_datums держит датум по ckey: удалённый, но не вычеркнутый оттуда
	// датум ушёл бы в харддел, а следующий вход этого ckey получил бы труп.
	for(var/registered_ckey in GLOB.preferences_datums)
		if(GLOB.preferences_datums[registered_ckey] != src)
			continue
		GLOB.preferences_datums -= registered_ckey
		break
	// Датум вида принадлежит только префам (все присвоения pref_species - new, мобу уходит
	// тип, а не экземпляр), ссылок со стороны нет - хватает отпустить, рефкаунт освободит.
	pref_species = null
	return ..()

/datum/preferences/proc/reset_modern_custom_theme()
	modern_custom_bg_primary = initial(modern_custom_bg_primary)
	modern_custom_bg_secondary = initial(modern_custom_bg_secondary)
	modern_custom_text_primary = initial(modern_custom_text_primary)
	modern_custom_text_secondary = initial(modern_custom_text_secondary)
	modern_custom_button_bg = initial(modern_custom_button_bg)
	modern_custom_button_hover = initial(modern_custom_button_hover)
	modern_custom_button_active = initial(modern_custom_button_active)
	modern_custom_button_text = initial(modern_custom_button_text)
	modern_custom_border_color = initial(modern_custom_border_color)
	modern_custom_accent_color = initial(modern_custom_accent_color)
	modern_custom_bg_pattern = initial(modern_custom_bg_pattern)

/datum/preferences/proc/set_modern_custom_color(color_key, raw_value)
	if(isnull(raw_value))
		return FALSE
	var/value = "[raw_value]"
	value = replacetext(value, "#", "")
	// normalize short forms like FFF -> FFFFFF
	if(length(value) == 3)
		value = "[copytext(value,1,2)][copytext(value,1,2)][copytext(value,2,3)][copytext(value,2,3)][copytext(value,3,4)][copytext(value,3,4)]"
	value = sanitize_hexcolor(value, 6, FALSE, null)
	if(!value)
		return FALSE
	color_key = "[color_key]"
	switch(color_key)
		if("bg_primary")
			modern_custom_bg_primary = value
			return TRUE
		if("bg_secondary")
			modern_custom_bg_secondary = value
			return TRUE
		if("text_primary")
			modern_custom_text_primary = value
			return TRUE
		if("text_secondary")
			modern_custom_text_secondary = value
			return TRUE
		if("button_bg")
			modern_custom_button_bg = value
			return TRUE
		if("button_hover")
			modern_custom_button_hover = value
			return TRUE
		if("button_active")
			modern_custom_button_active = value
			return TRUE
		if("button_text")
			modern_custom_button_text = value
			return TRUE
		if("border_color")
			modern_custom_border_color = value
			return TRUE
		if("accent_color")
			modern_custom_accent_color = value
			return TRUE
	return FALSE

/// Во сколько раз больше MAX_FLAVOR_PREVIEW_LEN символов текста разбирается ради превью: запас на теги разметки
#define FLAVOR_PREVIEW_PARSE_SLACK 4

/// Начало описания персонажа для превью в окне настройки: полный текст до 4096 символов не кодируется
/proc/flavor_text_preview(text)
	var/text_head = copytext_char(text, 1, MAX_FLAVOR_PREVIEW_LEN * FLAVOR_PREVIEW_PARSE_SLACK)
	return replacetext(parsemarkdown_basic(html_encode(text_head), hyperlink = FALSE), "\n", " ")

#undef FLAVOR_PREVIEW_PARSE_SLACK

/**
 * Единая точка входа в меню персонажа: открываем только TGUI-окно.
 * rebuild_preview сохранён в сигнатуре - на него ссылаются внешние вызовы.
 */
/datum/preferences/proc/ShowChoices(mob/user, rebuild_preview = TRUE)
	if(!user || !user.client)
		return
	if(rebuild_preview && !QDELETED(character_setup_ui))
		character_setup_ui.preview_dirty = TRUE
	open_character_setup(user)

/datum/preferences/proc/ClearKeybindingCapture()
	kb_capture_kb_name = null
	kb_capture_old_key = null
	kb_capture_independent = FALSE

/datum/preferences/proc/ApplyKeybindingSet(mob/user, list/input)
	var/kb_name = input["keybinding"]
	if(!kb_name)
		return FALSE

	var/independent = input["independent"]
	var/clear_key = text2num(input["clear_key"])
	var/old_key = input["old_key"]
	var/special = input["special"]

	if(clear_key)
		if(independent)
			modless_key_bindings -= old_key
		else if(key_bindings[old_key])
			key_bindings[old_key] -= kb_name
			var/has_buttons = FALSE
			for(var/key in key_bindings)
				var/list/temp = key_bindings[key]
				if(!islist(temp))
					continue
				if(temp.Find(kb_name))
					has_buttons = TRUE
					break
			if(!has_buttons)
				LAZYADD(key_bindings["Unbound"], kb_name)
			if(!length(key_bindings[old_key]))
				key_bindings -= old_key
		if(special && user?.client)
			user.client.ensure_keys_set(src)
		return TRUE

	var/new_key = input["key"]
	var/AltMod = text2num(input["alt"]) ? "Alt" : ""
	var/CtrlMod = text2num(input["ctrl"]) ? "Ctrl" : ""
	var/ShiftMod = text2num(input["shift"]) ? "Shift" : ""

	if(GLOB._kbMap[new_key])
		new_key = GLOB._kbMap[new_key]

	var/full_key
	switch(new_key)
		if("Alt")
			full_key = "[new_key][CtrlMod][ShiftMod]"
		if("Ctrl")
			full_key = "[AltMod][new_key][ShiftMod]"
		if("Shift")
			full_key = "[AltMod][CtrlMod][new_key]"
		else
			full_key = "[AltMod][CtrlMod][ShiftMod][new_key]"

	if(independent)
		modless_key_bindings -= old_key
		modless_key_bindings[full_key] = kb_name
	else
		if(key_bindings[old_key])
			key_bindings[old_key] -= kb_name
			if(!length(key_bindings[old_key]))
				key_bindings -= old_key
		//Из savefile прилетает 0 вместо пустого списка: "type mismatch: 0 |= /list".
		//Апстрим закрывает это через LAZYOR, но тот проверяет только !L и пропустил
		//бы ненулевой мусор в записи - здесь нужен именно islist().
		if(!islist(key_bindings[full_key]))
			key_bindings[full_key] = list()
		key_bindings[full_key] |= list(kb_name)
		key_bindings[full_key] = sort_list(key_bindings[full_key])

	if(special && user?.client)
		user.client.ensure_keys_set(src)
	return TRUE

/datum/preferences/proc/SetChoices(mob/user)
	if(!SSjob)
		return
	if(!ismob(user) || !user.client?.prefs)
		return
	open_job_menu(user) // думаем

/datum/preferences/proc/SetJobPreferenceLevel(datum/job/job, level)
	if (!job)
		return FALSE

	if (level == JP_HIGH) // to high
		//Set all other high to medium
		for(var/j in job_preferences)
			if(job_preferences["[j]"] == JP_HIGH)
				job_preferences["[j]"] = JP_MEDIUM
				//technically break here

	job_preferences["[job.title]"] = level
	return TRUE

/datum/preferences/proc/ResetJobs()
	job_preferences = list()

GLOBAL_LIST_INIT(body_mod_organ_groups, list(
	list(
		"slot" = ORGAN_SLOT_EYES,
		"base" = /obj/item/organ/eyes,
		"label" = "Глаза",
		"options" = list(
			list("id" = "organic", "label" = "Обычные", "cost" = 0),
			list("id" = "robotic", "label" = "Кибернетические", "cost" = 0, "path" = /obj/item/organ/eyes/robotic),
			list("id" = "glow", "label" = "Светящиеся", "cost" = 1, "path" = /obj/item/organ/eyes/robotic/toggled/glow),
		),
	),
	list(
		"slot" = ORGAN_SLOT_EARS,
		"base" = /obj/item/organ/ears,
		"label" = "Уши",
		"options" = list(
			list("id" = "organic", "label" = "Обычные", "cost" = 0),
			list("id" = "cyber", "label" = "Кибернетические", "cost" = 0, "path" = /obj/item/organ/ears/cybernetic),
			list("id" = "upgraded", "label" = "Улучшенные", "cost" = 1, "path" = /obj/item/organ/ears/cybernetic/upgraded),
		),
	),
	list(
		"slot" = ORGAN_SLOT_HEART,
		"base" = /obj/item/organ/heart,
		"label" = "Сердце",
		"options" = list(
			list("id" = "organic", "label" = "Обычное", "cost" = 0),
			list("id" = "cyber", "label" = "Кибернетическое", "cost" = 0, "path" = /obj/item/organ/heart/cybernetic),
			list("id" = "tier2", "label" = "Кибернетическое II", "cost" = 1, "path" = /obj/item/organ/heart/cybernetic/tier2),
			list("id" = "tier3", "label" = "Кибернетическое III", "cost" = 2, "path" = /obj/item/organ/heart/cybernetic/tier3),
		),
	),
	list(
		"slot" = ORGAN_SLOT_LUNGS,
		"base" = /obj/item/organ/lungs,
		"label" = "Лёгкие",
		"options" = list(
			list("id" = "organic", "label" = "Обычные", "cost" = 0),
			list("id" = "cyber", "label" = "Кибернетические", "cost" = 0, "path" = /obj/item/organ/lungs/cybernetic),
			list("id" = "tier2", "label" = "Кибернетические II", "cost" = 1, "path" = /obj/item/organ/lungs/cybernetic/tier2),
			list("id" = "tier3", "label" = "Кибернетические III", "cost" = 2, "path" = /obj/item/organ/lungs/cybernetic/tier3),
		),
	),
	list(
		"slot" = ORGAN_SLOT_LIVER,
		"base" = /obj/item/organ/liver,
		"label" = "Печень",
		"options" = list(
			list("id" = "organic", "label" = "Обычная", "cost" = 0),
			list("id" = "cyber", "label" = "Кибернетическая", "cost" = 0, "path" = /obj/item/organ/liver/cybernetic),
			list("id" = "tier2", "label" = "Кибернетическая II", "cost" = 1, "path" = /obj/item/organ/liver/cybernetic/tier2),
			list("id" = "tier3", "label" = "Кибернетическая III", "cost" = 2, "path" = /obj/item/organ/liver/cybernetic/tier3),
		),
	),
	list(
		"slot" = ORGAN_SLOT_STOMACH,
		"base" = /obj/item/organ/stomach,
		"label" = "Желудок",
		"options" = list(
			list("id" = "organic", "label" = "Обычный", "cost" = 0),
			list("id" = "cyber", "label" = "Кибернетический", "cost" = 0, "path" = /obj/item/organ/stomach/cybernetic),
			list("id" = "tier2", "label" = "Кибернетический II", "cost" = 1, "path" = /obj/item/organ/stomach/cybernetic/tier2),
			list("id" = "tier3", "label" = "Кибернетический III", "cost" = 2, "path" = /obj/item/organ/stomach/cybernetic/tier3),
		),
	),
	list(
		"slot" = ORGAN_SLOT_BREATHING_TUBE,
		"label" = "Дыхательная трубка",
		"options" = list(
			list("id" = "none", "label" = "Нет", "cost" = 0),
			list("id" = "tube", "label" = "Установить", "cost" = 1, "path" = /obj/item/organ/cyberimp/mouth/breathing_tube),
		),
	),
))

GLOBAL_LIST_INIT(body_mod_implants, list(
	list("id" = "hide_backpack", "label" = "Имплант Дорсуалифоба", "desc" = "Рюкзак на спине скрывается от посторонних глаз по кнопке.", "cost" = 0, "path" = /obj/item/implant/hide_backpack),
	list("id" = "disrobe", "label" = "Мгновенное раздевание", "desc" = "Кнопка мгновенно сбрасывает всю надетую одежду.", "cost" = 0, "path" = /obj/item/implant/disrobe),
	list("id" = "genital_fluid", "label" = "Жидкостный индуктор", "desc" = "Позволяет вырабатывать генитальную жидкость заданного реагента. (груди)", "cost" = 0, "path" = /obj/item/implant/genital_fluid),
))

/datum/preferences/proc/body_mod_organ_group(slot)
	for(var/list/group in GLOB.body_mod_organ_groups)
		if(group["slot"] == slot)
			return group
	return null

/datum/preferences/proc/body_mod_organ_option(slot, option_id)
	var/list/group = body_mod_organ_group(slot)
	if(!group)
		return null
	for(var/list/option in group["options"])
		if(option["id"] == option_id)
			return option
	return null

/datum/preferences/proc/body_mod_implant_option(implant_id)
	for(var/list/option in GLOB.body_mod_implants)
		if(option["id"] == implant_id)
			return option
	return null

/datum/preferences/proc/body_mod_organ_locked(slot)
	if(!pref_species)
		return FALSE
	switch(slot)
		if(ORGAN_SLOT_EYES)
			return pref_species.mutanteyes != /obj/item/organ/eyes
		if(ORGAN_SLOT_EARS)
			return pref_species.mutantears != /obj/item/organ/ears
		if(ORGAN_SLOT_LUNGS)
			return !!pref_species.mutantlungs
		if(ORGAN_SLOT_LIVER)
			return pref_species.mutantliver != /obj/item/organ/liver
		if(ORGAN_SLOT_STOMACH)
			return pref_species.mutantstomach != /obj/item/organ/stomach
		if(ORGAN_SLOT_HEART)
			if(pref_species.mutant_heart != /obj/item/organ/heart)
				return TRUE
			for(var/heart_path in pref_species.mutant_organs)
				if(ispath(heart_path, /obj/item/organ/heart))
					return TRUE
	return FALSE

/datum/preferences/proc/body_mod_organ_registered(path)
	for(var/list/group in GLOB.body_mod_organ_groups)
		if(group["base"] == path)
			return TRUE
		for(var/list/option in group["options"])
			if(option["path"] == path)
				return TRUE
	return FALSE

/datum/preferences/proc/body_mods_cost()
	. = 0
	for(var/slot in organ_mods)
		if(body_mod_organ_locked(slot))
			continue
		var/list/option = body_mod_organ_option(slot, organ_mods[slot])
		if(option)
			. += option["cost"]
	for(var/implant_id in implant_mods)
		var/list/option = body_mod_implant_option(implant_id)
		if(option)
			. += option["cost"]

/datum/preferences/proc/sanitize_body_mods()
	var/list/clean_organs = list()
	if(islist(organ_mods))
		for(var/slot in organ_mods)
			var/list/option = body_mod_organ_option("[slot]", organ_mods[slot])
			if(!option || !option["path"])
				continue
			clean_organs["[slot]"] = option["id"]
	organ_mods = clean_organs
	var/list/clean_implants = list()
	if(islist(implant_mods))
		for(var/implant_id in implant_mods)
			var/list/option = body_mod_implant_option("[implant_id]")
			if(!option)
				continue
			clean_implants[option["id"]] = TRUE
	implant_mods = clean_implants

/datum/preferences/proc/drop_locked_body_mods()
	var/list/dropped = list()
	for(var/slot in organ_mods)
		if(body_mod_organ_locked(slot))
			dropped += slot
	for(var/slot in dropped)
		organ_mods -= slot

/datum/preferences/proc/migrate_legacy_body_mods()
	if(!SSquirks || !length(SSquirks.quirks))
		return
	var/list/legacy_quirks = list(
		"Глаза с Повышенной Светимостью" = "eyes",
		"Трубка для Горлового Дыхания" = "tube",
		"Имплант Для Дорсуалифоба" = "hide_backpack",
		"Тядзин" = "genital_fluid",
	)
	var/list/migrated = list()
	for(var/quirk_name in legacy_quirks)
		if(quirk_name in all_quirks)
			all_quirks -= quirk_name
			migrated += legacy_quirks[quirk_name]
	if(!length(migrated))
		return
	var/budget = 0
	for(var/quirk_name in all_quirks)
		var/datum/quirk/quirk_datum = SSquirks.quirks[quirk_name]
		if(quirk_datum)
			budget -= initial(quirk_datum.value)
	for(var/modification in modified_limbs)
		var/limb_kind = modified_limbs[modification][1]
		if(limb_kind == LOADOUT_LIMB_PROSTHETIC)
			budget += 1
		else if(limb_kind == LOADOUT_LIMB_AMPUTATED)
			budget += 2
	budget -= mob_size_name_to_quirk_cost(body_weight)
	budget -= body_mods_cost()
	if(("tube" in migrated) && !organ_mods[ORGAN_SLOT_BREATHING_TUBE] && budget >= 1)
		organ_mods[ORGAN_SLOT_BREATHING_TUBE] = "tube"
		budget -= 1
	if(("eyes" in migrated) && !organ_mods[ORGAN_SLOT_EYES] && !body_mod_organ_locked(ORGAN_SLOT_EYES))
		if(budget >= 2)
			organ_mods[ORGAN_SLOT_EYES] = "glow"
			budget -= 2
		else if(budget >= 1)
			organ_mods[ORGAN_SLOT_EYES] = "robotic"
			budget -= 1
	if("hide_backpack" in migrated)
		implant_mods["hide_backpack"] = TRUE
	if("genital_fluid" in migrated)
		implant_mods["genital_fluid"] = TRUE

/datum/preferences/proc/apply_prefs_body_mods(mob/living/carbon/human/character)
	for(var/slot in organ_mods)
		if(body_mod_organ_locked(slot))
			continue
		var/list/group = body_mod_organ_group(slot)
		if(!group)
			continue
		var/list/option = body_mod_organ_option(slot, organ_mods[slot])
		if(!option || !option["path"])
			continue
		var/new_path = option["path"]
		var/obj/item/organ/old_organ = character.getorganslot(slot)
		if(old_organ)
			if(old_organ.type == new_path)
				continue
			if(old_organ.type != group["base"] && !body_mod_organ_registered(old_organ.type))
				continue
			old_organ.Remove()
			qdel(old_organ)
		var/obj/item/organ/new_organ = new new_path
		if(istype(new_organ, /obj/item/organ/eyes/robotic/toggled/glow))
			var/obj/item/organ/eyes/robotic/toggled/glow/glow_eyes = new_organ
			if(length(character.left_eye_color))
				glow_eyes.left_eye_color = character.left_eye_color
				glow_eyes.current_color_string = "#[character.left_eye_color]"
			if(length(character.right_eye_color))
				glow_eyes.right_eye_color = character.right_eye_color
		new_organ.Insert(character)
	for(var/implant_id in implant_mods)
		var/list/option = body_mod_implant_option(implant_id)
		if(!option || !option["path"])
			continue
		var/new_path = option["path"]
		if(locate(new_path) in character.implants)
			continue
		var/obj/item/implant/new_implant = new new_path
		if(!new_implant.implant(character, null, TRUE, TRUE))
			qdel(new_implant)

/datum/preferences/proc/GetQuirkBalance(mob/user)
	var/bal = 0
	for(var/V in all_quirks)
		var/datum/quirk/T = SSquirks.quirks[V]
		bal -= initial(T.value)
	for(var/modification in modified_limbs)
		var/limb_kind = modified_limbs[modification][1]
		if(limb_kind == LOADOUT_LIMB_PROSTHETIC)
			bal += 1
		else if(limb_kind == LOADOUT_LIMB_AMPUTATED)
			bal += 2
	bal -= mob_size_name_to_quirk_cost(body_weight) //BLUEMOON ADD вес влияет на доступные квирки
	bal -= body_mods_cost()
	if(bal < 0)
		to_chat(user, "<span class='danger'>Something goes wrong and quirk balance goes to [bal], quirks and character weight reseted.</span>") //BLUEMOON ADD
		all_quirks = list()
		body_weight = NAME_WEIGHT_NORMAL //BLUEMOON ADD сброс всего сбрасывает и вес
		organ_mods = list()
		implant_mods = list()
		return FALSE
	return bal

/datum/preferences/proc/GetPositiveQuirkCount()
	. = 0
	for(var/q in all_quirks)
		if(SSquirks.quirk_points[q] > 0)
			.++

/datum/preferences/proc/get_sound_volume(sound_id)
	var/varname = "sound_volume_[sound_id]"
	. = vars[varname]
	if(isnull(.))
		return 100

// Административная выдача пересоздаёт квирки со всеми стартовыми эффектами и вещами.
/datum/preferences/proc/apply_spawn_quirks(mob/living/character, obj/item/new_heirloom)
	if(QDELETED(character))
		return FALSE
	for(var/datum/quirk/quirk as anything in character.roundstart_quirks.Copy())
		character.remove_quirk(quirk.type)
	// Административная выдача использует только новую реликвию текущего комплекта, а не ссылку от прежнего тела.
	character.mind?.set_assigned_heirloom(new_heirloom)
	SSquirks.AssignQuirks(character, character.client, TRUE, TRUE, null, FALSE, character, spawn_items = TRUE, preferences_source = src)
	return TRUE

// Полное применение персонажа из админской панели; VV и актуализатор используют copy_to().
/datum/preferences/proc/apply_to_existing_character(mob/living/carbon/human/character)
	if(QDELETED(character))
		return FALSE
	for(var/datum/quirk/quirk as anything in character.roundstart_quirks.Copy())
		character.remove_quirk(quirk.type)
	copy_to(character, icon_updates = FALSE, roundstart_checks = FALSE, initial_spawn = TRUE)
	apply_spawn_quirks(character)
	SSlanguage.AssignLanguage(character, character.client)
	apply_tattoos_to_human(character)
	post_copy_to(character)
	character.dna.update_dna_identity()
	character.regenerate_icons()
	return TRUE

/datum/preferences/proc/copy_to(mob/living/carbon/human/character, icon_updates = 1, roundstart_checks = TRUE, initial_spawn = FALSE)
	if(be_random_name)
		real_name = pref_species.random_name(gender)

	if(be_random_body)
		random_character(gender)

	if(roundstart_checks)
		if(CONFIG_GET(flag/humans_need_surnames) && (pref_species.id == "human"))
			var/firstspace = findtext(real_name, " ")
			var/name_length = length(real_name)
			if(!firstspace)	//we need a surname
				real_name += " [pick(GLOB.last_names)]"
			else if(firstspace == name_length)
				real_name += "[pick(GLOB.last_names)]"

	character.mob_weight = mob_size_name_to_num(body_weight) //BLUEMOON ADD записываем вес персонажа как цифру
	character.laugh_override = custom_laugh != "Default" ? custom_laugh : null //BLUEMOON ADD записываем вес персонажа как цифру

	//reset size if applicable
	if(character.dna.features["body_size"])
		var/initial_old_size = character.dna.features["body_size"]
		character.update_size(RESIZE_DEFAULT_SIZE, initial_old_size)

	character.real_name = nameless ? "[real_name] #[rand(10000, 99999)]" : real_name
	character.name = character.real_name
	character.nameless = nameless
	character.custom_species = custom_species

	character.gender = gender
	character.age = age

	character.fuzzy = fuzzy

	character.update_weight(character.mob_weight)
	character.left_eye_color = left_eye_color
	character.right_eye_color = right_eye_color
	var/obj/item/organ/eyes/organ_eyes = character.getorgan(/obj/item/organ/eyes)
	if(organ_eyes)
		if(!initial(organ_eyes.left_eye_color))
			organ_eyes.left_eye_color = left_eye_color
			organ_eyes.right_eye_color = right_eye_color
		organ_eyes.old_left_eye_color = left_eye_color
		organ_eyes.old_right_eye_color = right_eye_color
	character.hair_color = hair_color
	character.facial_hair_color = facial_hair_color
	character.skin_tone = skin_tone
	character.dna.skin_tone_override = use_custom_skin_tone ? skin_tone : null
	character.hair_style = hair_style
	character.facial_hair_style = facial_hair_style
	character.grad_style = grad_style
	character.grad_color = grad_color
	/* skyrat edit
	character.underwear = underwear

	character.saved_underwear = underwear
	character.undershirt = undershirt
	character.saved_undershirt = undershirt
	character.socks = socks
	character.saved_socks = socks
	*/
	character.undie_color = undie_color
	character.shirt_color = shirt_color
	character.socks_color = socks_color
	character.taste_desc = vore_taste
	character.smell_desc = vore_smell

	var/datum/species/chosen_species
	if(!roundstart_checks || (pref_species.id in GLOB.roundstart_races))
		chosen_species = pref_species.type
	else
		chosen_species = /datum/species/human
		pref_species = new /datum/species/human
		save_character()

	character.dna.features = features.Copy()

	character.set_species(chosen_species, icon_update = FALSE, pref_load = TRUE)
	character.dna.species.eye_type = eye_type
	if(chosen_limb_id && (chosen_limb_id in character.dna.species.allowed_limb_ids))
		character.dna.species.mutant_bodyparts["limbs_id"] = chosen_limb_id
	character.dna.real_name = character.real_name
	character.dna.nameless = character.nameless
	// BLUEMOON EDIT START - привязка флавора и лора кастомных рас к ДНК
	character.dna.custom_species = character.custom_species
	character.dna.custom_species_lore = features["custom_species_lore"]
	character.dna.flavor_text = features["flavor_text"]
	character.dna.naked_flavor_text = features["naked_flavor_text"]

	var/list/headshot_temp = features["headshot_links"]
	character.dna.headshot_links = LAZYCOPY(headshot_temp)
	listclearnulls(character.dna.headshot_links)

	headshot_temp = features["headshot_naked_links"]
	character.dna.headshot_naked_links = LAZYCOPY(headshot_temp)
	listclearnulls(character.dna.headshot_naked_links)

	// BLUEMOON ADD END
	character.dna.ooc_notes = features["ooc_notes"]
	if(custom_blood_color)
		character.dna.species.exotic_blood_color = blood_color //а раньше эта строчка была немного выше и всё ломалось, думайте, когда делаете врезки
	// BLUEMOON EDIT END

	var/old_size = RESIZE_DEFAULT_SIZE
	if(isdwarf(character))
		character.dna.features["body_size"] = RESIZE_DEFAULT_SIZE

	if(parent?.can_have_part("meat_type") || pref_species.mutant_bodyparts["meat_type"])
		character.type_of_meat = GLOB.meat_types[features["meat_type"]]

	if((parent?.can_have_part("legs") || pref_species.mutant_bodyparts["legs"])  && (character.dna.features["legs"] == "Digitigrade" || character.dna.features["legs"] == "Avian"))
		pref_species.species_traits |= DIGITIGRADE
	else if(character.dna.species.mutant_bodyparts["limbs_id"] in list("sergal", "sergal2"))
		pref_species.species_traits |= DIGITIGRADE
	else
		pref_species.species_traits -= DIGITIGRADE

	character.dna.features["lust_tolerance"] = lust_tolerance
	character.dna.features["sexual_potency"] = sexual_potency

	if(features["anus_accessible"])
		character.toggle_anus_always_accessible(TRUE)

	character.give_genitals(TRUE) //character.update_genitals() is already called on genital.update_appearance()

	character.update_size(get_size(character), old_size)

	//speech stuff
	if(custom_tongue != "default")
		var/new_tongue = GLOB.roundstart_tongues[custom_tongue]
		if(new_tongue)
			character.dna.species.mutanttongue = new_tongue //this means we get our tongue when we clone
			var/obj/item/organ/tongue/T = character.getorganslot(ORGAN_SLOT_TONGUE)
			if(T)
				qdel(T)
			var/obj/item/organ/tongue/new_custom_tongue = new new_tongue
			new_custom_tongue.Insert(character, custom_speech_verb_ru = custom_speech_verb_ru)
	if(!get_default_speech_verb(custom_speech_verb))
		character.dna.species.say_mod = custom_speech_verb

	character.set_bark(bark_id)
	character.vocal_speed = bark_speed
	character.vocal_pitch = bark_pitch
	character.vocal_pitch_range = bark_variance

	if(initial_spawn)
		apply_prefs_modified_limbs(character)
		apply_prefs_body_mods(character)

	if(DIGITIGRADE in pref_species.species_traits)
		character.Digitigrade_Leg_Swap(FALSE)
	else
		character.Digitigrade_Leg_Swap(TRUE)

	SEND_SIGNAL(character, COMSIG_HUMAN_PREFS_COPIED_TO, src, icon_updates, roundstart_checks)

	//let's be sure the character updates
	if(icon_updates)
		character.update_body()
		character.update_hair()

/// Применяет к character сохранённые в префах модификации конечностей (протезы/ампутации).
/// Сбрасывает все робо-конечности до плотских, регенерирует отсутствующие и затем
/// накатывает modified_limbs из префов. Вызывается из copy_to() при initial_spawn,
/// а также из load_client_appearance() для гост-ролей, антагов и аналогичных спавнов
/// с загрузкой выбранного персонажа.
/datum/preferences/proc/apply_prefs_modified_limbs(mob/living/carbon/human/character)
	//delete any existing prosthetic limbs to make sure no remnant prosthetics are left over - But DO NOT delete those that are species-related
	for(var/obj/item/bodypart/part in character.bodyparts)
		if(part.is_robotic_limb(FALSE))
			qdel(part)
	character.regenerate_limbs() //regenerate limbs so now you only have normal limbs
	for(var/modified_limb in modified_limbs)
		var/modification = modified_limbs[modified_limb][1]
		var/obj/item/bodypart/old_part = character.get_bodypart(modified_limb)
		if(modification == LOADOUT_LIMB_PROSTHETIC)
			var/obj/item/bodypart/new_limb
			switch(modified_limb)
				if(BODY_ZONE_L_ARM)
					new_limb = new/obj/item/bodypart/l_arm/robot/surplus(character)
				if(BODY_ZONE_R_ARM)
					new_limb = new/obj/item/bodypart/r_arm/robot/surplus(character)
				if(BODY_ZONE_L_LEG)
					new_limb = new/obj/item/bodypart/l_leg/robot/surplus(character)
				if(BODY_ZONE_R_LEG)
					new_limb = new/obj/item/bodypart/r_leg/robot/surplus(character)
			var/prosthetic_type = modified_limbs[modified_limb][2]
			if(prosthetic_type != "prosthetic") //lets just leave the old sprites as they are
				new_limb.icon = file("icons/mob/augmentation/cosmetic_prosthetic/[prosthetic_type].dmi")
			new_limb.replace_limb(character)
		qdel(old_part)

/datum/preferences/proc/post_copy_to(mob/living/carbon/human/character)
	//if no legs, and not a paraplegic or a slime, give them a free wheelchair
	if(modified_limbs[BODY_ZONE_L_LEG] == LOADOUT_LIMB_AMPUTATED && modified_limbs[BODY_ZONE_R_LEG] == LOADOUT_LIMB_AMPUTATED && !character.has_quirk(/datum/quirk/paraplegic) && !isjellyperson(character))
		if(character.buckled)
			character.buckled.unbuckle_mob(character)
		var/turf/T = get_turf(character)
		var/obj/structure/chair/spawn_chair = locate() in T
		var/obj/vehicle/ridden/wheelchair/wheels = new(T)
		if(spawn_chair) // Makes spawning on the arrivals shuttle more consistent looking
			wheels.setDir(spawn_chair.dir)
		wheels.buckle_mob(character)

/datum/preferences/proc/get_default_name(name_id)
	switch(name_id)
		if("human")
			return random_unique_name()
		if("ai")
			return pick(GLOB.ai_names)
		if("cyborg")
			return DEFAULT_CYBORG_NAME
		if("clown")
			return pick(GLOB.clown_names)
		if("mime")
			return pick(GLOB.mime_names)
	return random_unique_name()

/datum/preferences/proc/get_default_speech_verb(value)
	return (value == GLOB.speech_verbs[1] || value == GLOB.speech_verbs_ru[1])

/// Подпись и подсказка поля «Особые имена» по-русски; идентификатор (human/...)
/// остаётся английским - по нему сохраняется само имя.
/datum/preferences/proc/get_custom_namedata(name_id)
	var/list/ru_namedata = GLOB.preferences_custom_names_ru[name_id]
	if(ru_namedata)
		return ru_namedata
	return GLOB.preferences_custom_names[name_id]

/datum/preferences/proc/get_filtered_holoform(filter_type)
	if(!custom_holoform_icon)
		return
	LAZYINITLIST(cached_holoform_icons)
	if(!cached_holoform_icons[filter_type])
		cached_holoform_icons[filter_type] = process_holoform_icon_filter(custom_holoform_icon, filter_type)
	return cached_holoform_icons[filter_type]

/// Resets the client's keybindings. Asks them for which
/datum/preferences/proc/force_reset_keybindings()
	var/choice = tgalert(parent.mob, "Your basic keybindings need to be reset, emotes will remain as before. Would you prefer 'hotkey' or 'classic' mode?", "Reset keybindings", "Hotkey", "Classic")
	hotkeys = (choice != "Classic")
	force_reset_keybindings_direct(hotkeys)

/// Does the actual reset
/datum/preferences/proc/force_reset_keybindings_direct(hotkeys = TRUE)
	var/list/oldkeys = key_bindings
	key_bindings = (hotkeys) ? deepCopyList(GLOB.hotkey_keybinding_list_by_key) : deepCopyList(GLOB.classic_keybinding_list_by_key)

	for(var/key in oldkeys)
		if(!key_bindings[key])
			key_bindings[key] = oldkeys[key]
	parent?.ensure_keys_set(src)

/datum/preferences/proc/is_loadout_slot_available(slot)
	return TRUE // No category limits - loadout points handle balance

// BLUEMOON ADD START - выбор вещей из лодаута как семейной реликвии
///Searching for loadout item which `property` ([LOADOUT_ITEM], [LOADOUT_COLOR], etc) equals to `value`; returns this items, or FALSE if no gear matched conditions
/datum/preferences/proc/find_gear_with_property(save_slot, property, value)
	var/list/gear_list = loadout_data["SAVE_[save_slot]"]
	for(var/loadout_gear in gear_list)
		if(loadout_gear[property] == value)
			return loadout_gear
	return FALSE

/datum/preferences/proc/has_loadout_gear(save_slot, gear_type)
	var/list/gear_list = loadout_data["SAVE_[save_slot]"]
	for(var/loadout_gear in gear_list)
		if(loadout_gear[LOADOUT_ITEM] == gear_type)
			return loadout_gear
	return FALSE

/datum/preferences/proc/remove_gear_from_loadout(save_slot, gear_type)
	var/find_gear = has_loadout_gear(save_slot, gear_type)
	if(find_gear)
		loadout_data["SAVE_[save_slot]"] -= list(find_gear)

/datum/preferences/proc/can_use_unlockable(datum/gear/unlockable/unlockable_gear)
	if(unlockable_loadout_data[unlockable_gear.progress_key] >= unlockable_gear.progress_required)
		return TRUE
	return FALSE

/**
 * Get the given client's chat toggle prefs.
 *
 * Getter function for prefs.chat_toggles which guards against null client and null prefs.
 * The client object is fickle and can go null at times, so use this instead of directly accessing the var
 * if you want to ensure no runtimes.
 *
 * returns client.prefs.chat_toggles or FALSE if something went wrong.
 *
 * Arguments:
 * * client/prefs_holder - the client to get the chat_toggles pref from.
 */
/proc/get_chat_toggles(client/prefs_holder)
	if(!prefs_holder)
		return FALSE
	if(prefs_holder && !prefs_holder?.prefs)
		stack_trace("[prefs_holder?.mob] ([prefs_holder?.ckey]) had null prefs, which shouldn't be possible!")
		return FALSE

	return prefs_holder?.prefs.chat_toggles

/datum/preferences/proc/toggle_language(lang)
	if(lang in language)
		language -= lang
		return TRUE
	else if(check_language_maxhit())
		if(CONFIG_GET(number/max_languages) == 1)
			tgui_alert(usr, "You can only have 1 additional language!", timeout = 5 SECONDS)
		else
			tgui_alert(usr, "You can only have up to [CONFIG_GET(number/max_languages)] additional languages!", timeout = 5 SECONDS)
		return FALSE
	else
		language += lang
		return TRUE

/datum/preferences/proc/check_language_maxhit()
	if(CONFIG_GET(number/max_languages) == -1)
		return FALSE
	else if(language.len >= CONFIG_GET(number/max_languages))
		return TRUE

#define ACTION_HEADSHOT_LINK_NOOP 0
#define ACTION_HEADSHOT_LINK_REMOVE -1
#define HEADSHOT_LINK_MAX_LENGTH 400

/datum/preferences/vv_edit_var(var_name, var_value, massedit)
	if(var_name == NAMEOF(src, metadollar_minute_pool) || var_name == NAMEOF(src, metadollar_pending_items))
		if(usr)
			to_chat(usr, span_warning("Метадоллары нельзя менять через VV. Используйте команду TGS <b>metadollars</b> (add / remove / set)."))
		var/path_display = path || "no path"
		log_admin("Metadollars: VV edit of [var_name] blocked for prefs [path_display] by [key_name(usr)].")
		return FALSE
	return ..()

/**
 * Валидация ссылки на фото для TGUI-меню: ввод идёт полем в окне,
 * здесь остаётся только проверка формата и длины.
 */
/datum/preferences/proc/validate_headshot_link(user, usr_input)
	var/static/link_regex = regex("^https?://.*\\.(jpg|png|jpeg|gif|webm|mp4)(\[?#].*)?$", "i")

	if (length(usr_input) > HEADSHOT_LINK_MAX_LENGTH)
		to_chat(user, span_warning("The link is too long! Max length: [HEADSHOT_LINK_MAX_LENGTH] characters!"))
		return ACTION_HEADSHOT_LINK_NOOP

	if(!findtext(usr_input, link_regex))
		to_chat(user, span_warning("The link must be a direct http(s):// image/video URL ending with .png, .jpg, .jpeg, .gif, .webm, or .mp4!"))
		return ACTION_HEADSHOT_LINK_NOOP

	var/static/list/repl_chars = list("\n"="#","\t"="#","'"="","\""=""," "="")
	return sanitize(usr_input, repl_chars)

/proc/headshot_preview_html(link, width = 140, height = 140)
	if(!link)
		return ""
	var/static/video_regex = regex("\\.(webm|mp4)(\[?#]|$)", "i")
	if(findtext(link, video_regex))
		return "<video src='[link]' autoplay loop muted playsinline style='border: 1px solid black; object-fit: contain;' width='[width]' height='[height]'></video>"
	return "<img src='[link]' referrerpolicy='no-referrer' style='border: 1px solid black; object-fit: contain;' width='[width]' height='[height]'>"

/datum/preferences/proc/mob_size_name_to_num(body_weight_name)
	switch(body_weight_name)
		if(NAME_WEIGHT_LIGHT)
			return MOB_WEIGHT_LIGHT
		if(NAME_WEIGHT_NORMAL)
			return MOB_WEIGHT_NORMAL
		if(NAME_WEIGHT_HEAVY)
			return MOB_WEIGHT_HEAVY
		if(NAME_WEIGHT_HEAVY_SUPER)
			return MOB_WEIGHT_HEAVY_SUPER
		else
			return MOB_WEIGHT_NORMAL

/datum/preferences/proc/mob_size_name_to_quirk_cost(body_weight_name)
	switch(body_weight_name)
		if(NAME_WEIGHT_HEAVY)
			return 1
		if(NAME_WEIGHT_HEAVY_SUPER)
			return 2
		else
			return 0

/**
 * Возвращает копию списка "имя -> аксессуар" без аксессуаров, недоступных для user_key.
 * Значения, не являющиеся аксессуарами, и элементы обычных (не ассоциативных) списков остаются как есть.
 */
/datum/preferences/proc/filter_accessories_by_ckey(list/accessories, user_key)
	. = list()
	for(var/name in accessories)
		var/value = accessories[name]
		if(istype(value, /datum/sprite_accessory))
			var/datum/sprite_accessory/accessory = value
			if(!accessory.is_allowed_for(user_key))
				continue
		if(isnull(value))
			. += name
		else
			.[name] = value

#undef HEADSHOT_LINK_MAX_LENGTH
#undef ACTION_HEADSHOT_LINK_NOOP
#undef ACTION_HEADSHOT_LINK_REMOVE
