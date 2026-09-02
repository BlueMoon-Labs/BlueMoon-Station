/obj/item/borg_shapeshifter
	name = "cyborg chameleon projector"
	icon = 'icons/obj/device.dmi'
	icon_state = "shield0"
	flags_1 = CONDUCT_1
	item_flags = NOBLUDGEON
	item_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	var/friendlyName
	var/savedName
	var/savedIcon
	var/savedBubbleIcon
	var/savedOverride
	var/savedPixelOffset
	var/savedModuleName
	var/active = FALSE
	var/activationCost = 150
	var/activationUpkeep = 5
	var/disguise = null
	var/disguise_icon_override = null
	var/disguise_pixel_offset = null
	var/disguise_dogborg = FALSE
	var/disguise_drakerest = FALSE	//DarkSer request by Gardelin0
	var/mob/listeningTo
	var/list/signalCache = list( // list here all signals that should break the camouflage
			COMSIG_PARENT_ATTACKBY,
			COMSIG_ATOM_ATTACK_HAND,
			COMSIG_MOVABLE_IMPACT_ZONE,
			COMSIG_ATOM_BULLET_ACT,
			COMSIG_ATOM_EX_ACT,
			COMSIG_ATOM_FIRE_ACT,
			COMSIG_ATOM_EMP_ACT,
			)
	var/mob/living/silicon/robot/user // needed for process()
	var/animation_playing = FALSE
	var/list/borgmodels = list(
							"(Standard) Default",
							"(Standard) Heavy",
							"(Standard) Sleek",
							"(Standard) Marina",
							"(Standard) Robot",
							"(Standard) Eyebot",
							"(Medical) Default",
							"(Medical) Heavy",
							"(Medical) Sleek",
							"(Medical) Marina",
							"(Medical) Droid",
							"(Medical) Eyebot",
							"(Medical) Medihound",
							"(Medical) Medihound Dark",
							"(Medical) Vale",
							"(Engineering) Default",
							"(Engineering) Default - Treads",
							"(Engineering) Loader",
							"(Engineering) Handy",
							"(Engineering) Sleek",
							"(Engineering) Can",
							"(Engineering) Marina",
							"(Engineering) Spider",
							"(Engineering) Heavy",
							"(Miner) Lavaland",
							"(Miner) Asteroid",
							"(Miner) Droid",
							"(Miner) Sleek",
							"(Miner) Marina",
							"(Miner) Can",
							"(Miner) Heavy",
							"(Service) Waitress",
							"(Service) Butler",
							"(Service) Bro",
							"(Service) Can",
							"(Service) Tophat",
							"(Service) Sleek",
							"(Service) Heavy",
							"(Janitor) Default",
							"(Janitor) Marina",
							"(Janitor) Sleek",
							"(Janitor) Can")

/obj/item/borg_shapeshifter/Initialize(mapload)
	. = ..()
	friendlyName = pick(GLOB.ai_names)

/obj/item/borg_shapeshifter/Destroy()
	return ..()

/obj/item/borg_shapeshifter/dropped(mob/user)
	. = ..()
	disrupt(user)

/obj/item/borg_shapeshifter/equipped(mob/user)
	. = ..()
	disrupt(user)

/**
  * check_menu: Checks if we are allowed to interact with a radial menu
  *
  * Arguments:
  * * user The mob interacting with a menu
  */
/obj/item/borg_shapeshifter/proc/check_menu(mob/user)
	if(!istype(user))
		return FALSE
	if(user.incapacitated() || !user.Adjacent(src))
		return FALSE
	return TRUE

/obj/item/borg_shapeshifter/attack_self(mob/living/silicon/robot/user)
	if(user && user.cell && user.cell.charge > activationCost)
		if(isturf(user.loc))
			toggle(user)
		else
			to_chat(user, "<span class='warning'>You can't use [src] while inside something!</span>")
	else
		to_chat(user, "<span class='warning'>You need at least [activationCost] charge in your cell to use [src]!</span>")

GLOBAL_LIST_INIT(borg_disguise_options, list(
	"Standard" = list(
		list("name" = "Default", "base" = "robot", "icon" = 'icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "MissM", "base" = "missm_sd", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Protectron", "base" = "protectron_standard", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Zoomba", "base" = "zoomba_standard", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Marina", "base" = "marinasd", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Heavy", "base" = "heavysd", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Eyebot", "base" = "eyebotsd", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "RoboMaid", "base" = "robomaid_sd", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "BootyF", "base" = "bootystandard", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "BootyM", "base" = "bootystandardM", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "BootyS", "base" = "bootystandardS", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Fembot", "base" = "fembot-clerc", "icon" = 'modular_bluemoon/icons/mob/robot/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Assaultron", "base" = "assaultron_standard", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Handy", "base" = "handy", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Robo-Brain", "base" = "robobrain", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Cyclone", "base" = "cyclone", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "SmollRaptor", "base" = "smolraptor", "icon" = 'icons/mob/smolraptor.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
	),
	"Medical" = list(
		list("name" = "Default", "base" = "medical", "icon" = 'icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Droid", "base" = "medical", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Sleek", "base" = "sleekmed", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Marina", "base" = "marinamed", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Eyebot", "base" = "eyebotmed", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Heavy", "base" = "heavymed", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "MissM", "base" = "missm_med", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Protectron", "base" = "protectron_medical", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Zoomba", "base" = "zoomba_med", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Arachne", "base" = "arachne", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Insekt", "base" = "insekt-Med", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Gibbs", "base" = "gibbs", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "RoboMaid", "base" = "robomaid_med", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Qualified Doctor", "base" = "qualified_doctor", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "BootyF", "base" = "bootymedical", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "BootyM", "base" = "bootymedicalM", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "BootyS", "base" = "bootymedicalS", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Haydee", "base" = "haydeemedical", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Fembot", "base" = "fembot-medic", "icon" = 'modular_bluemoon/icons/mob/robot/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Assaultron", "base" = "assaultron_medical", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Meka", "base" = "mekamed", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Meka (alt)", "base" = "mekamed_alt", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "M-Meka", "base" = "mmekamed", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "F-Meka", "base" = "fmekamed", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "K4T", "base" = "k4tmed", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "K4T (alt)", "base" = "k4tmed_alt1", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Handy", "base" = "handy_medical", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Mechoid", "base" = "mechoid-medical", "icon" = 'modular_bluemoon/icons/mob/robot/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Dullahan", "base" = "dullahanmed", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Dragon", "base" = "dragon-med", "icon" = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_med.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Medihound", "base" = "medihound", "icon" = 'modular_citadel/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Medihound Dark", "base" = "medihounddark", "icon" = 'modular_citadel/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Vale", "base" = "valemed", "icon" = 'modular_citadel/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Borgi", "base" = "borgi-medi", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Feline", "base" = "vixmed", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Raptor V-4", "base" = "medraptor", "icon" = 'modular_splurt/icons/mob/robots_64x45.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Raptor V-4 (alt)", "base" = "traumaraptor", "icon" = 'modular_splurt/icons/mob/robots_64x45.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "SmollRaptor", "base" = "smolraptor_med", "icon" = 'icons/mob/smolraptor.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Drake", "base" = "drakemed", "icon" = 'modular_sand/icons/mob/cyborg/drakemech.dmi', "dogborg" = TRUE, "drakerest" = TRUE, "pixel" = -16),
		list("name" = "DrakeTrauma", "base" = "draketrauma", "icon" = 'modular_sand/icons/mob/cyborg/drakemech.dmi', "dogborg" = TRUE, "drakerest" = TRUE, "pixel" = -16),
		list("name" = "Catborg", "base" = "meowdical", "icon" = 'modular_bluemoon/icons/mob/kittycatborgs/catborgs/catborg_medical.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Kittyborg", "base" = "medicat", "icon" = 'modular_bluemoon/icons/mob/kittycatborgs/kittyborg/Kittyborg_medicat.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Dullahan (Taur)", "base" = "dullahantaurmed", "icon" = 'modular_bluemoon/icons/mob/robot/dullahan_taur.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "HoundTrauma", "base" = "houndtrauma", "icon" = 'modular_bluemoon/icons/mob/robot/robots.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
	),
	"Engineer" = list(
		list("name" = "Default", "base" = "engineer", "icon" = 'icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Default - Treads", "base" = "engi-tread", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Loader", "base" = "loaderborg", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Sleek", "base" = "sleekeng", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Can", "base" = "caneng", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Marina", "base" = "marinaeng", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Spider", "base" = "spidereng", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Heavy", "base" = "heavyeng", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "MissM", "base" = "missm_eng", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Protectron", "base" = "protectron_eng", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Zoomba", "base" = "zoomba_engi", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Conagher", "base" = "conagher", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Eyebot", "base" = "eyeboteng", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Wide", "base" = "wide-engi", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "RoboMaid", "base" = "robomaid_eng", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "BootyF", "base" = "bootyengineer", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "BootyM", "base" = "bootyengineerM", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "BootyS", "base" = "bootyengineerS", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Handy", "base" = "handy_engineer", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Fembot", "base" = "fembot-engineering", "icon" = 'modular_bluemoon/icons/mob/robot/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Assaultron", "base" = "assaultron_engi", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Haydee", "base" = "haydeeengi", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Meka", "base" = "mekaengi", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Meka (alt)", "base" = "mekaengi_alt", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "M-Meka", "base" = "mmekaeng", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "F-Meka", "base" = "fmekaeng", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "K4T", "base" = "k4tengi", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "K4T (alt)", "base" = "k4tengi_alt1", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Mechoid", "base" = "mechoid-engineer", "icon" = 'modular_bluemoon/icons/mob/robot/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Dullahan", "base" = "dullahaneng", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Dullahan (Taur)", "base" = "dullahantaureng", "icon" = 'modular_bluemoon/icons/mob/robot/dullahan_taur.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Dragon", "base" = "dragon-engi", "icon" = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_engi.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Pup Dozer", "base" = "pupdozer", "icon" = 'modular_citadel/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Vale", "base" = "valeeng", "icon" = 'modular_citadel/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Borgi", "base" = "borgi-eng", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Engihound", "base" = "engihound", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Engihound Dark", "base" = "engihounddark", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Otie", "base" = "otiee", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Drake", "base" = "drakeeng", "icon" = 'modular_sand/icons/mob/cyborg/drakemech.dmi', "dogborg" = TRUE, "drakerest" = TRUE, "pixel" = -16),
		list("name" = "Feline", "base" = "vixengi", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Raptor V-4", "base" = "engiraptor", "icon" = 'modular_splurt/icons/mob/robots_64x45.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "SmollRaptor", "base" = "smolraptor_eng", "icon" = 'icons/mob/smolraptor.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Catborg", "base" = "engi", "icon" = 'modular_bluemoon/icons/mob/kittycatborgs/catborgs/catborg_engineering.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Kittyborg", "base" = "engi", "icon" = 'modular_bluemoon/icons/mob/kittycatborgs/kittyborg/Kittyborg_engi.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = 0),
	),
	"Security" = list(
		list("name" = "Default", "base" = "sec", "icon" = 'icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Default - Treads", "base" = "sec-tread", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Sleek", "base" = "sleeksec", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Can", "base" = "cansec", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Marina", "base" = "marinasec", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Spider", "base" = "spidersec", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Heavy", "base" = "heavysec", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "MissM", "base" = "missm_security", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Protectron", "base" = "protectron_security", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Zoomba", "base" = "zoomba_sec", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Woody", "base" = "woody", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Eyebot", "base" = "eyebotsec", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Insekt", "base" = "insekt-Sec", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "RoboMaid", "base" = "robomaid_sec", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "BootyF", "base" = "bootysecurity", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "BootyM", "base" = "bootysecurityM", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "BootyS", "base" = "bootysecurityS", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Handy", "base" = "handy_security", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Sentry Bot", "base" = "sentrybot", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Securitron", "base" = "securitron", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Fembot", "base" = "fembot-security", "icon" = 'modular_bluemoon/icons/mob/robot/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Assaultron", "base" = "assaultron_sec", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Haydee", "base" = "haydeesec", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "FMeka Syndie", "base" = "fmekasyndi", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Meka", "base" = "mekasec", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "M-Meka", "base" = "mmekasec", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "F-Meka", "base" = "fmekasec", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "K4T", "base" = "k4tsec", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Mechoid", "base" = "mechoid-security", "icon" = 'modular_bluemoon/icons/mob/robot/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Dullahan", "base" = "dullahanpeace", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Catborg", "base" = "sec", "icon" = 'modular_bluemoon/icons/mob/kittycatborgs/catborgs/catborg_security.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Kittyborg", "base" = "sec", "icon" = 'modular_bluemoon/icons/mob/kittycatborgs/kittyborg/Kittyborg_sec.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Dragon", "base" = "dragon-sec", "icon" = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_sec.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "K9", "base" = "k9", "icon" = 'modular_citadel/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "K9 Dark", "base" = "k9dark", "icon" = 'modular_citadel/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Vale", "base" = "valesec", "icon" = 'modular_citadel/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Borgi", "base" = "borgi-sec", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Otie", "base" = "oties", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Blade", "base" = "bladesec", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "EdgyBoy", "base" = "badboi", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "EdgyGirl", "base" = "prettyboi", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Syndicate", "base" = "syndihounddark", "icon" = 'modular_splurt/icons/mob/widerobot_synd.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Drake", "base" = "drakesec", "icon" = 'modular_sand/icons/mob/cyborg/drakemech.dmi', "dogborg" = TRUE, "drakerest" = TRUE, "pixel" = -16),
		list("name" = "Feline", "base" = "vixsec", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Raptor V-4", "base" = "secraptor", "icon" = 'modular_splurt/icons/mob/robots_64x45.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
	),
	"Service" = list(
		list("name" = "(Service) Waitress", "base" = "service_f", "icon" = 'icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Service) Butler", "base" = "service_m", "icon" = 'icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Service) Bro", "base" = "brobot", "icon" = 'icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Service) Can", "base" = "kent", "icon" = 'icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Service) Tophat", "base" = "tophat", "icon" = 'icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Service) Sleek", "base" = "sleekserv", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Service) Heavy", "base" = "heavyserv", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Service) MissM", "base" = "missm_service", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Service) Protectron", "base" = "protectron_service", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Service) Zoomba", "base" = "zoomba_green", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Service) Lloyd", "base" = "lloyd", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Service) Handy", "base" = "handy-service", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Service) BootyF", "base" = "bootyservice", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Service) BootyM", "base" = "bootyserviceM", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Service) BootyS", "base" = "bootyserviceS", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Service) Fembot", "base" = "fembot-service", "icon" = 'modular_bluemoon/icons/mob/robot/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Service) Meka", "base" = "mekaserve", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Service) M-Meka", "base" = "mmekaserv", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Service) F-Meka", "base" = "fmekaserv", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Service) K4T", "base" = "k4tserve", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Service Alt) K4T", "base" = "k4tserve_alt1", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Service) Feline", "base" = "vixserv", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "(Service) Raptor V-4", "base" = "serviraptor", "icon" = 'modular_splurt/icons/mob/robots_64x45.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "(Fancy) Raptor V-4", "base" = "fancyraptor", "icon" = 'modular_splurt/icons/mob/robots_64x45.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "(Service) SmollRaptor", "base" = "smolraptor_srv", "icon" = 'icons/mob/smolraptor.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "(Service) Dullahan", "base" = "dullahanserv", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Service) Mechoid", "base" = "mechoid-civi", "icon" = 'modular_bluemoon/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Service) Dragon", "base" = "dragon-serv", "icon" = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_service.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Waiter) Meka", "base" = "mekaserve_alt", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) Default", "base" = "janitor", "icon" = 'icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) Marina", "base" = "marinajan", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) Sleek", "base" = "sleekjan", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) Can", "base" = "canjan", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) Heavy", "base" = "heavyres", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) MissM", "base" = "missm_janitor", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) Protectron", "base" = "protectron_janitor", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) Zoomba", "base" = "zoomba_jani", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) Flynn", "base" = "flynn", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) Eyebot", "base" = "eyebotjani", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) Insekt", "base" = "insekt-Sci", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) Wide", "base" = "wide-jani", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) Spider", "base" = "spidersci", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) RoboMaid", "base" = "robomaid_jan", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) BootyF", "base" = "bootyjanitor", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) BootyM", "base" = "bootyjanitorM", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) BootyS", "base" = "bootyjanitorS", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) Handy", "base" = "handy_janitor", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) Fembot", "base" = "fembot-janitor", "icon" = 'modular_bluemoon/icons/mob/robot/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) Otie", "base" = "otiej", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "(Janitor) Ratge", "base" = "ratge", "icon" = 'modular_bluemoon/icons/mob/robot/ratge.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) Haydee", "base" = "haydeejan", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Slutvice) Haydee", "base" = "HaydeeServ", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) Meka", "base" = "mekajani", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) M-Meka", "base" = "mmekajani", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) F-Meka", "base" = "fmekajani", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) K4T", "base" = "k4tjani", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor Alt) K4T", "base" = "k4tjani_alt1", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) Feline", "base" = "vixjani", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "(Janitor Alt) Feline", "base" = "vixsci", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "(Janitor) Raptor V-4", "base" = "janiraptor", "icon" = 'modular_splurt/icons/mob/robots_64x45.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "(Janitor Alt) Raptor V-4", "base" = "sciraptor", "icon" = 'modular_splurt/icons/mob/robots_64x45.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "(Janitor) SmollRaptor", "base" = "smolraptor_jani", "icon" = 'icons/mob/smolraptor.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "(Janitor Alt) SmollRaptor", "base" = "smolraptor_sci", "icon" = 'icons/mob/smolraptor.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "(Janitor) Dullahan", "base" = "dullahanjani", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) Mechoid", "base" = "mechoid-janitor", "icon" = 'modular_bluemoon/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) Catborg", "base" = "service", "icon" = 'modular_bluemoon/icons/mob/kittycatborgs/catborgs/catborg_service.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) Kittyborg", "base" = "jani", "icon" = 'modular_bluemoon/icons/mob/kittycatborgs/kittyborg/Kittyborg_jani.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) Dullahan (Taur)", "base" = "dullahantaurjani", "icon" = 'modular_bluemoon/icons/mob/robot/dullahan_taur.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Janitor) Dragon", "base" = "dragon-jani", "icon" = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_jani.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Jester) Dragon", "base" = "dragon-clown", "icon" = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_jester.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "(Service) DarkK9", "base" = "k50", "icon" = 'modular_citadel/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "(Service) Vale", "base" = "valeserv", "icon" = 'modular_citadel/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "(Service) ValeDark", "base" = "valeservdark", "icon" = 'modular_citadel/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "(Service) K69", "base" = "k69", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "(Service) Borgi", "base" = "borgi-serv", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "(Janitor) Scrubpuppy", "base" = "scrubpup", "icon" = 'modular_citadel/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "(Janitor) Borgi", "base" = "borgi-jani", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "(Janitor) Drake", "base" = "drakejanit", "icon" = 'modular_sand/icons/mob/cyborg/drakemech.dmi', "dogborg" = TRUE, "drakerest" = TRUE, "pixel" = -16),
	),
	"Miner" = list(
		list("name" = "Lavaland", "base" = "miner", "icon" = 'icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Asteroid", "base" = "minerOLD", "icon" = 'icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Droid", "base" = "miner", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Sleek", "base" = "sleekmin", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Marina", "base" = "marinamin", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Can", "base" = "canmin", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Heavy", "base" = "heavymin", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "MissM", "base" = "missm_miner", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Protectron", "base" = "protectron_mining", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Zoomba", "base" = "zoomba_mining", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Ishimura", "base" = "ishimura", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Mining Drone", "base" = "minidrone", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "RoboMaid", "base" = "robomaid_mining", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "BootyF", "base" = "bootyminer", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "BootyM", "base" = "bootyminerM", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "BootyS", "base" = "bootyminerS", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Handy", "base" = "handy_mining", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Fembot", "base" = "fembot-miner", "icon" = 'modular_bluemoon/icons/mob/robot/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Assaultron", "base" = "assaultron_mining", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Haydee", "base" = "haydeemining", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Meka", "base" = "mekamining", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Meka (alt)", "base" = "mekaminingalt", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "M-Meka", "base" = "mmekamining", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "F-Meka", "base" = "fmekamining", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "K4T", "base" = "k4tmining", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "K4T (alt)", "base" = "k4tminingalt1", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Mechoid", "base" = "mechoid-miner", "icon" = 'modular_bluemoon/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "SmollRaptor", "base" = "smolraptor_mining", "icon" = 'icons/mob/smolraptor.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Dullahan", "base" = "dullahanmining", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Dullahan (Taur)", "base" = "dullahantaurmining", "icon" = 'modular_bluemoon/icons/mob/robot/dullahan_taur.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Dragon", "base" = "dragon-mine", "icon" = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_miner.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Blade", "base" = "blademining", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Vale", "base" = "valemining", "icon" = 'modular_citadel/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Cargohound", "base" = "cargohound", "icon" = 'modular_splurt/icons/mob/widerobots_cargo.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Cargohound Dark", "base" = "cargohounddark", "icon" = 'modular_splurt/icons/mob/widerobots_cargo.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Otie", "base" = "otiem", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Drake", "base" = "drakemining", "icon" = 'modular_sand/icons/mob/cyborg/drakemech.dmi', "dogborg" = TRUE, "drakerest" = TRUE, "pixel" = -16),
		list("name" = "Feline", "base" = "vixmin", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Raptor V-4", "base" = "mineraptor", "icon" = 'modular_splurt/icons/mob/robots_64x45.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Catborg", "base" = "mine", "icon" = 'modular_bluemoon/icons/mob/kittycatborgs/catborgs/catborg_mining.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Kittyborg", "base" = "mine", "icon" = 'modular_bluemoon/icons/mob/kittycatborgs/kittyborg/Kittyborg_mine.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = 0),
	),
	"Peacekeeper" = list(
		list("name" = "Default", "base" = "peacekeeper", "icon" = 'icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Borgi", "base" = "borgi-peace", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Spider", "base" = "spiderpeace", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Protectron", "base" = "protectron_peacekeeper", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Marina", "base" = "marinapeace", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Sleek", "base" = "sleekpk", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Omoikane", "base" = "omoikane", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Insekt", "base" = "insekt-Peace", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "BootyF", "base" = "bootypeacekeeper", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "BootyM", "base" = "bootypeacekeeperM", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "BootyS", "base" = "bootypeacekeeperS", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Vale", "base" = "valepeace", "icon" = 'modular_citadel/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Drake", "base" = "drakepeace", "icon" = 'modular_sand/icons/mob/cyborg/drakemech.dmi', "dogborg" = TRUE, "drakerest" = TRUE, "pixel" = -16),
		list("name" = "Fembot", "base" = "fembot-peacekeeper", "icon" = 'modular_bluemoon/icons/mob/robot/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Assaultron", "base" = "assaultron_peace", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Haydee", "base" = "haydeepeace", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Meka", "base" = "mekapk", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "M-Meka", "base" = "mmekapk", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "F-Meka", "base" = "fmekapk", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "K4T", "base" = "k4tpk", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Feline", "base" = "vixpeace", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Raptor V-4", "base" = "peaceraptor", "icon" = 'modular_splurt/icons/mob/robots_64x45.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "SmollRaptor", "base" = "smolraptor_pk", "icon" = 'icons/mob/smolraptor.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Handy", "base" = "handy_peace", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Dullahan", "base" = "dullahanpk", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Catborg", "base" = "peace", "icon" = 'modular_bluemoon/icons/mob/kittycatborgs/catborgs/catborg_service.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Kittyborg", "base" = "peace", "icon" = 'modular_bluemoon/icons/mob/kittycatborgs/kittyborg/Kittyborg_jani.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Dragon", "base" = "dragon-pk", "icon" = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_peacekeeper.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = 0),
	),
	"Clown" = list(
		list("name" = "ClownMech", "base" = "clownbot", "icon" = 'icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "ClownMan", "base" = "clownbotman", "icon" = 'icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "ClownBot", "base" = "clownbot", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Garish", "base" = "garish", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Clowne", "base" = "clowne", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Marina", "base" = "marinaclown", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "BootyF", "base" = "bootyclown", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "BootyM", "base" = "bootyclownM", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "BootyS", "base" = "bootyclownS", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Dullahan", "base" = "dullahanclown", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Dullahan (Taur)", "base" = "dullahantaurclown", "icon" = 'modular_bluemoon/icons/mob/robot/dullahan_taur.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Kitty Clown", "base" = "clown", "icon" = 'modular_bluemoon/icons/mob/robot/kitty_clown.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Dragon", "base" = "dragon-clown", "icon" = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_jester.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = 0),
	),
	"Syndicate" = list(
		list("name" = "SyndiMech", "base" = "syndicate", "icon" = 'icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "SyndiMech - Treads", "base" = "syndicate-tread", "icon" = 'icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Spider", "base" = "spidersyndi", "icon" = 'icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Sleek", "base" = "sleeksyndi", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Heavy", "base" = "heavysyndi", "icon" = 'modular_citadel/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "MissM", "base" = "missm_syndie", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Protectron", "base" = "protectron_syndi", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Zoomba", "base" = "zoomba_syndi", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "MAX", "base" = "maxwell", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Eyebot", "base" = "eyebotsyndi", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "RoboMaid", "base" = "robomaid_syndi", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "BootyF", "base" = "bootysyndi", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "BootyM", "base" = "bootysyndiM", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "BootyS", "base" = "bootysyndiS", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Handy", "base" = "handy_syndi", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Fembot", "base" = "fembot-syndicate", "icon" = 'modular_bluemoon/icons/mob/robot/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Assaultron", "base" = "assaultron_syndi", "icon" = 'modular_splurt/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Meka", "base" = "mekasyndi", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "M-Meka", "base" = "mmekasyndi", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "F-Meka", "base" = "fmekasyndi", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "K4T", "base" = "k4tsyndi", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Mechoid", "base" = "mechoid-syndi", "icon" = 'modular_bluemoon/icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Dullahan", "base" = "dullahansyndi", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Dullahan (Taur)", "base" = "dullahantaursyndi", "icon" = 'modular_bluemoon/icons/mob/robot/dullahan_taur.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Catborg", "base" = "syndie", "icon" = 'modular_bluemoon/icons/mob/kittycatborgs/catborgs/catborg_security.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Kittyborg", "base" = "syndie", "icon" = 'modular_bluemoon/icons/mob/kittycatborgs/kittyborg/Kittyborg_sec.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Dragon", "base" = "dragon-syndi", "icon" = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_sec.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "K9", "base" = "k9syndi", "icon" = 'modular_citadel/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "K9 Dark", "base" = "k9syndidark", "icon" = 'modular_citadel/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Syndicate", "base" = "syndihounddark", "icon" = 'modular_splurt/icons/mob/widerobot_synd.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Drake", "base" = "drakesyndi", "icon" = 'modular_sand/icons/mob/cyborg/drakemech.dmi', "dogborg" = TRUE, "drakerest" = TRUE, "pixel" = -16),
		list("name" = "Feline", "base" = "vixsyndi", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Raptor V-4", "base" = "syndiraptor", "icon" = 'modular_splurt/icons/mob/robots_64x45.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Borgi", "base" = "borgi-syndi", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Otie", "base" = "otiesyndi", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
	),
	"Cargo" = list(
		list("name" = "Default", "base" = "cargoborg", "icon" = 'icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Bird Cargo", "base" = "bird_cargo", "icon" = 'icons/mob/robots.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "MissM", "base" = "missm_cargo", "icon" = 'modular_splurt/icons/mob/robots_cargo.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Zoomba", "base" = "zoomba_cargo", "icon" = 'modular_splurt/icons/mob/robots_cargo.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Borgi", "base" = "borgi-cargo", "icon" = 'modular_splurt/icons/mob/widerobots_cargo.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Drake", "base" = "drakecargo", "icon" = 'modular_sand/icons/mob/cyborg/drakemech.dmi', "dogborg" = TRUE, "drakerest" = TRUE, "pixel" = -16),
		list("name" = "Assaultron", "base" = "assaultron_cargo", "icon" = 'modular_splurt/icons/mob/robots_cargo.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Meka", "base" = "mekacargo", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "M-Meka", "base" = "mmekacargo", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "F-Meka", "base" = "fmekacargo", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "K4T", "base" = "k4tcargo", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "K4T (alt)", "base" = "k4tcargoalt1", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Raptor V-4", "base" = "cargoraptor", "icon" = 'modular_splurt/icons/mob/robots_64x45.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "SmollRaptor", "base" = "smolraptor_cargo", "icon" = 'icons/mob/smolraptor.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Dullahan", "base" = "dullahancargo", "icon" = 'modular_splurt/icons/mob/robots_32x64.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Dullahan (Taur)", "base" = "dullahantaurcargo", "icon" = 'modular_bluemoon/icons/mob/robot/dullahan_taur.dmi', "dogborg" = FALSE, "drakerest" = FALSE, "pixel" = 0),
		list("name" = "Cargohound", "base" = "cargohound", "icon" = 'modular_splurt/icons/mob/widerobots_cargo.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Cargohound Dark", "base" = "cargohounddark", "icon" = 'modular_splurt/icons/mob/widerobots_cargo.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Vale", "base" = "valecargo", "icon" = 'modular_citadel/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
		list("name" = "Feline", "base" = "vixcargo", "icon" = 'modular_splurt/icons/mob/widerobot.dmi', "dogborg" = TRUE, "drakerest" = FALSE, "pixel" = -16),
	),
))

/obj/item/borg_shapeshifter/proc/toggle(mob/living/silicon/robot/user)
	if(active)
		playsound(src, 'sound/effects/pop.ogg', 100, TRUE, -6)
		to_chat(user, "<span class='notice'>You deactivate \the [src].</span>")
		deactivate(user)
	else
		if(animation_playing)
			to_chat(user, "<span class='notice'>\the [src] is recharging.</span>")
			return
		var/mob/living/silicon/robot/R = loc
		var/static/list/module_icons = sort_list(list(
		"Standard" = image(icon = 'icons/mob/robots.dmi', icon_state = "robot"),
		"Medical" = image(icon = 'icons/mob/robots.dmi', icon_state = "medical"),
		"Engineer" = image(icon = 'icons/mob/robots.dmi', icon_state = "engineer"),
		"Security" = image(icon = 'icons/mob/robots.dmi', icon_state = "sec"),
		"Service" = image(icon = 'icons/mob/robots.dmi', icon_state = "service_f"),
		"Miner" = image(icon = 'icons/mob/robots.dmi', icon_state = "miner"),
		"Peacekeeper" = image(icon = 'icons/mob/robots.dmi', icon_state = "peace"),
		"Clown" = image(icon = 'icons/mob/robots.dmi', icon_state = "clown"),
		"Syndicate" = image(icon = 'icons/mob/robots.dmi', icon_state = "synd_sec"),
		"Cargo" = image(icon = 'modular_splurt/icons/mob/robots_cargo.dmi', icon_state = "cargoborg")
		))
		var/module_selection = show_radial_menu(R, R , module_icons, custom_check = CALLBACK(src, PROC_REF(check_menu), R), radius = 42, require_near = TRUE)
		if(!module_selection)
			return FALSE

		var/list/cat = GLOB.borg_disguise_options[module_selection]
		if(isnull(cat))
			return FALSE
		var/list/option_icons = list()
		var/list/option_keys = list()
		for(var/list/opt in cat)
			var/image/img = image(icon = opt["icon"], icon_state = opt["base"], layer = FALSE)
			if(opt["pixel"])
				img.pixel_x = opt["pixel"]
			option_icons[opt["name"]] = img
			option_keys[opt["name"]] = opt
		var/choice = show_radial_menu(R, R, option_icons, require_near = TRUE)
		if(!choice)
			return FALSE
		var/list/chosen = option_keys[choice]
		disguise = chosen["base"]
		disguise_icon_override = chosen["icon"]
		disguise_pixel_offset = chosen["pixel"]
		disguise_dogborg = chosen["dogborg"]
		disguise_drakerest = chosen["drakerest"]

		animation_playing = TRUE
		to_chat(user, "<span class='notice'>You activate \the [src].</span>")
		playsound(src, 'sound/effects/seedling_chargeup.ogg', 100, TRUE, -6)
		var/start = user.filters.len
		var/X,Y,rsq,i,f
		for(i=1, i<=7, ++i)
			do
				X = 60*rand() - 30
				Y = 60*rand() - 30
				rsq = X*X + Y*Y
			while(rsq<100 || rsq>900)
			user.filters += filter(type="wave", x=X, y=Y, size=rand()*2.5+0.5, offset=rand())
		for(i=1, i<=7, ++i)
			f = user.filters[start+i]
			animate(f, offset=f:offset, time=0, loop=3, flags=ANIMATION_PARALLEL)
			animate(offset=f:offset-1, time=rand()*20+10)
		if (do_after(user, 5 SECONDS, user) && user.cell.use(activationCost))
			playsound(src, 'sound/effects/bamf.ogg', 100, TRUE, -6)
			to_chat(user, "<span class='notice'>You are now disguised as the Nanotrasen cyborg \"[friendlyName]\".</span>")
			activate(user, module_selection)
		else
			to_chat(user, "<span class='warning'>The chameleon field fizzles.</span>")
			do_sparks(3, FALSE, user)
			for(i=1, i<=min(7, user.filters.len), ++i) // removing filters that are animating does nothing, we gotta stop the animations first
				f = user.filters[start+i]
				animate(f)
		user.filters = null
		animation_playing = FALSE

/obj/item/borg_shapeshifter/process()
	if (user)
		if (!user.cell || !user.cell.use(activationUpkeep))
			disrupt(user)
	else
		return PROCESS_KILL

/obj/item/borg_shapeshifter/proc/activate(mob/living/silicon/robot/user, disguiseModuleName)
	START_PROCESSING(SSobj, src)
	src.user = user
	savedName = user.name
	savedIcon = user.module.cyborg_base_icon
	savedBubbleIcon = user.bubble_icon //tf is that
	savedOverride = user.module.cyborg_icon_override
	savedPixelOffset = user.module.cyborg_pixel_offset
	savedModuleName = user.module.name
	user.name = friendlyName
	user.module.name = disguiseModuleName
	user.module.cyborg_base_icon = disguise
	user.module.cyborg_icon_override = disguise_icon_override
	user.module.cyborg_pixel_offset = disguise_pixel_offset
	user.module.dogborg = disguise_dogborg
	user.module.drakerest = disguise_drakerest		//DarkSer request by Gardelin0
	user.bubble_icon = "robot"
	active = TRUE
	user.update_icons()

	if(listeningTo == user)
		return
	if(listeningTo)
		UnregisterSignal(listeningTo, signalCache)
	RegisterSignal(user, signalCache, PROC_REF(disrupt))
	listeningTo = user

/obj/item/borg_shapeshifter/proc/deactivate(mob/living/silicon/robot/user)
	STOP_PROCESSING(SSobj, src)
	if(listeningTo)
		UnregisterSignal(listeningTo, signalCache)
		listeningTo = null
	do_sparks(5, FALSE, user)
	user.name = savedName
	user.module.name = savedModuleName
	user.module.cyborg_base_icon = savedIcon
	user.module.cyborg_icon_override = savedOverride
	user.module.cyborg_pixel_offset = 0
	user.module.dogborg = FALSE
	user.module.drakerest = FALSE		//DarkSer request by Gardelin0
	user.bubble_icon = savedBubbleIcon
	active = FALSE
	user.update_icons()
	disguise_pixel_offset = 0
	disguise_dogborg = FALSE
	disguise_drakerest = FALSE		//DarkSer request by Gardelin0
	src.user = user

/obj/item/borg_shapeshifter/proc/disrupt(mob/living/silicon/robot/user)
	if(active)
		to_chat(user, "<span class='danger'>Your chameleon field deactivates.</span>")
		deactivate(user)

/obj/item/borg_shapeshifter/stable
	signalCache = list()
	activationCost = 0
	activationUpkeep = 0

/obj/item/borg_shapeshifter/stable/activate(mob/living/silicon/robot/user, disguiseModuleName)
	friendlyName = user.name
	. = ..()
