#define VORE_SOUND_FALLOFF 0.1
#define VORE_SOUND_RANGE 3

// Загрязнение предметов нутром
/obj/item
	var/vore_contaminated = FALSE
	var/vore_original_color
	var/vore_original_desc

/obj/item/proc/vore_contaminate(var/new_color, var/flavor)
	if(vore_contaminated)
		return
	vore_contaminated = TRUE
	vore_original_color = color
	vore_original_desc = desc
	color = new_color
	if(flavor)
		desc = "[desc] [flavor]"

/obj/item/proc/vore_clean()
	if(!vore_contaminated)
		return
	vore_contaminated = FALSE
	color = vore_original_color
	desc = vore_original_desc

//
//  Belly system 2.0, now using objects instead of datums because EH at datums.
//	How many times have I rewritten bellies and vore now? -Aro
//

// If you change what variables are on this, then you need to update the copy() proc.

//
// Parent type of all the various "belly" varieties.
//
/obj/belly
	name = "belly"							// Name of this location
	desc = "Это нутро! Ты внутри!"			// Flavor text description of inside sight/sound/smells/feels.
	var/display_name						// Имя для чата и UI
	var/absorbed_desc						// Описание для поглощённой добычи
	var/list/vore_types = list("Oral Vore")	// Информационные типы нутра
	var/list/mode_addons = list()			// Дополнения режима с эффектами
	rad_flags = RAD_NO_CONTAMINATE | RAD_PROTECT_CONTENTS
	var/vore_sound = "Gulp"					// Sound when ingesting someone
	var/vore_verb = "ingest"				// Verb for eating with this in messages
	var/release_verb = "выпускает"			// Глагол освобождения в сообщениях
	var/release_sound = "Splatter"			// Sound for letting someone out.
	var/sound_volume = 75					// Громкость звуков воре (0-100)
	var/noise_freq = 0						// Частота звука (0 = случайная высота)
	var/human_prey_swallow_time = 100		// Time in deciseconds to swallow /mob/living/carbon/human
	var/nonhuman_prey_swallow_time = 30		// Time in deciseconds to swallow anything else
	var/emote_time = 60 SECONDS				// How long between stomach emotes at prey
	var/emote_active = TRUE					// Показывать авто-эмоты добыче
	var/digest_brute = 2					// Brute damage per tick in digestion mode
	var/digest_burn = 2						// Burn damage per tick in digestion mode
	var/digest_oxy = 0						// Suffocation damage per tick in digestion mode
	var/digest_tox = 0						// Toxin damage per tick in digestion mode
	var/digest_clone = 0					// Clone damage per tick in digestion mode
	var/nutrition_percent = 100				// Множитель питательности от переваривания (0-100%)
	var/item_mode = "Follow"				// Режим предметов Follow/Hold/Digest
	var/belly_temperature = 293.15			// Температура внутри нутра
	var/temperature_damage = FALSE			// Наносить урон за слишком горячую/холодную температуру
	var/immutable = FALSE					// Prevents this belly from being deleted
	var/escapable = TRUE					// Belly can be resisted out of at any time
	var/escapetime = 20 SECONDS				// Deciseconds, how long to escape this belly
	var/digestchance = 0					// % Chance of stomach beginning to digest if prey struggles
	var/absorbchance = 0					// % Chance of stomach beginning to absorb if prey struggles
	var/escapechance = 0 					// % Chance of prey beginning to escape if prey struggles.
	var/can_taste = FALSE					// If this belly prints the flavor of prey when it eats someone.
	var/feedable = TRUE						// Можно ли скармливать добычу в это нутро со стороны
	var/bulge_size = 0.25					// The minimum size the prey has to be in order to show up on examine.
//	var/shrink_grow_size = 1				// This horribly named variable determines the minimum/maximum size it will shrink/grow prey to.

	var/transferlocation					// Location that the prey is released if they struggle and get dropped off.
	var/transferchance = 0 					// % Chance of prey being transferred to transfer location when resisting
	var/autotransferchance = 0 				// % Chance of prey being autotransferred to transfer location
	var/autotransferwait = 10 				// Time between trying to transfer.
	var/swallow_time = 10 SECONDS			// for mob transfering automation
	var/vore_capacity = 1					// simple animal nom capacity
	var/destination							// Куда перемещать всё содержимое (имя другого нутра)
	var/show_liquids = FALSE				// Производить и хранить жидкости
	var/show_liq_fullness = FALSE			// Показывать плеск жидкости при осмотре
	var/contaminates = FALSE				// Пачкать предметы содержимым
	var/contaminate_color = "#A06A8A"		// Цвет загрязнения
	var/contaminate_flavor = ""				// Текст, добавляемый к описанию предмета
	var/liquid_reagent = "/datum/reagent/water" // Тип производимой жидкости
	var/liquid_rate = 1						// Единиц жидкости за тик
	var/datum/reagents/liquids				// Хранилище жидкости
	var/tmp/next_liquid = 0					// Следующий тик производства
	var/is_wet = TRUE						// Is this belly inside slimy parts?
	var/wet_loop = TRUE						// Does this belly have a slimy internal loop?
	var/can_victim_see = FALSE				// Can victim see from inside
	var/eating_privacy = "Default"			// Приватность сообщений поглощения: Default/Subtle/Loud
	var/private_struggle = FALSE			// Скрывать сообщения сопротивления от окружающих
	var/drain_mode = "Absorb"				// Что делать после полного слива: Absorb/Release
	var/entrance_logs = TRUE				// Писать хищнику о попадании чего-либо в нутро
	var/item_digest_logs = FALSE			// Писать хищнику о переваренных предметах
	var/absorbedrename_enabled = FALSE		// Переименовывать поглощённую добычу
	var/absorbedrename_name = "%pred's %belly" // Шаблон имени поглощённой добычи
	var/save_digest_mode = FALSE			// Сохранять текущий режим нутра между раундами
	var/belly_fullscreen					// Стиль полноэкранного оверлея добычи (dark/blue/flesh)
	var/fullscreen_color					// Цвет наложения (hex) или null
	var/fullscreen_alpha = 255				// Прозрачность оверлея (0-255)

	//I don't think we've ever altered these lists. making them static until someone actually overrides them somewhere.
	var/tmp/static/list/digest_modes = list(DM_HOLD,DM_DIGEST,DM_HEAL,DM_NOISY,DM_ABSORB,DM_UNABSORB)	// Possible digest modes

	var/tmp/mob/living/owner					// The mob whose belly this is.
	var/tmp/digest_mode = DM_HOLD				// Current mode the belly is set to from digest_modes (+transform_modes if human)
	var/tmp/next_process = 0					// Waiting for this SSbellies times_fired to process again.
	var/tmp/list/items_preserved = list()		// Stuff that wont digest so we shouldn't process it again.
	var/tmp/next_emote = 0						// When we're supposed to print our next emote, as a belly controller tick #
	var/tmp/recent_sound						// Prevent audio spam
	var/tmp/last_hearcheck = 0
	var/tmp/list/hearing_mobs

	// Don't forget to watch your commas at the end of each line if you change these.
	var/list/struggle_messages_outside = list(
		"Живот %pred вздрагивает от бьющейся добычи.",
		"%belly %pred подрагивает от движения.",
		"%belly %pred ненадолго вздувается - кто-то толкается изнутри.",
		"%belly %pred ёрзает с запертой внутри добычей.",
		"%belly %pred колышется от движений изнутри.",
		"%belly %pred плещется.",
		"%belly %pred мягко хлюпает.",
		"%belly %pred издаёт влажный хлюпающий звук.")

	var/list/struggle_messages_inside = list(
		"Твоё бесполезное барахтанье заставляет скользкий %belly %pred смачно сжаться вокруг тебя.",
		"Твои попытки выбраться лишь заставляют %belly %pred мягко хлюпать вокруг тебя.",
		"От твоих движений %belly %pred плещется вокруг.",
		"Твои движения заставляют %belly %pred колыхаться.",
		"Ты ёрзаешь внутри %belly %pred.",
		"Ты упираешься в стенки %belly %pred, и оно ненадолго вздувается.",
		"Ты толкаешь %belly %pred своими движениями.",
		"Ты извиваешься внутри %belly %pred, заставляя его колыхаться.")

	var/list/digest_messages_owner = list(
		"Ты чувствуешь, как тело %prey уступает твоей пищеварительной системе и превращается в мягкую кашицу.",
		"Ты слышишь пошлый «глюрп»: мышцы твоего %belly перемалывают %prey в тёплую пульпу.",
		"Твой %belly урчит, переплавляя %prey в жижу.",
		"Ты чувствуешь мягкое урчание: тело %prey теряет форму в твоём %belly. Теперь это лишь тёплая масса.",
		"Твой %belly проталкивает остатки %prey по телу, добавляя немного веса бёдрам.",
		"Твой %belly проталкивает остатки %prey по телу, добавляя немного веса ягодицам.",
		"Твой %belly проталкивает остатки %prey по телу, добавляя немного веса животу.",
		"Твой %belly стонет: %prey распадается в густой суп. Ты чувствуешь, как остатки текут глубже в тело.",
		"Твой %belly разминает каждую частичку %prey, превращая их в месиво для следующей охоты.",
		"Твой %belly перемалывает %prey в горячую жижу. Питательные вещества разбегаются по пищеварительному тракту с долгими влажными «глорпами».")

	var/list/digest_messages_prey = list(
		"Твоё тело уступает пищеварительной системе %pred и превращается в мягкую кашицу.",
		"Из %belly %pred раздаётся пошлый «глорп»: мышцы перемалывают тебя в тёплую пульпу.",
		"%belly %pred урчит, переплавляя тебя в жижу.",
		"Ты слышишь мягкое урчание: твоё тело теряет форму в %belly %pred. Теперь ты лишь тёплая масса.",
		"%belly %pred проталкивает твои остатки по телу, добавляя немного веса бёдрам %pred.",
		"%belly %pred проталкивает твои остатки по телу, добавляя немного веса ягодицам %pred.",
		"%belly %pred проталкивает твои остатки по телу, добавляя немного веса животу %pred.",
		"%belly %pred стонет: ты распадаешься в густой суп. Твои остатки текут глубже в тело %pred.",
		"%belly %pred разминает каждую частичку твоего тела, превращая их в месиво для следующей охоты.",
		"%belly %pred перемалывает тебя в горячую жижу. Питательные остатки разбегаются по пищеварительному тракту с долгими влажными «глорпами».")

	var/list/examine_messages = list(
		"У них что-то в %belly!",
		"Похоже, у них что-то в %belly!")

	// Отдельные сообщения для поглощённой добычи (ключи те же)
	var/list/absorbed_messages = list()

	//Mostly for being overridden on precreated bellies on mobs. Could be VV'd into
	//a carbon's belly if someone really wanted. No UI for carbons to adjust this.
	//List has indexes that are the digestion mode strings, and keys that are lists of strings.
	var/tmp/list/emote_lists = list()

//For serialization, keep this updated AND IN ORDER OF VARS LISTED ABOVE AND IN DUPE AT THE BOTTOM!!, required for bellies to save correctly.
/obj/belly/vars_to_save()
	return ..() + list(
		"name",
		"desc",
		"absorbed_desc",
		"display_name",
		"vore_types",
		"mode_addons",
		"vore_sound",
		"vore_verb",
		"release_verb",
		"release_sound",
		"sound_volume",
		"noise_freq",
		"human_prey_swallow_time",
		"nonhuman_prey_swallow_time",
		"emote_time",
		"emote_active",
		"digest_brute",
		"digest_burn",
		"digest_oxy",
		"digest_tox",
		"digest_clone",
		"nutrition_percent",
		"item_mode",
		"belly_temperature",
		"temperature_damage",
		"immutable",
		"escapable",
		"escapetime",
		"digestchance",
		"absorbchance",
		"escapechance",
		"can_taste",
		"feedable",
		"bulge_size",
		"transferlocation",
		"transferchance",
		"autotransferchance",
		"autotransferwait",
		"swallow_time",
		"vore_capacity",
		"destination",
		"show_liquids",
		"show_liq_fullness",
		"contaminates",
		"contaminate_color",
		"contaminate_flavor",
		"liquid_reagent",
		"liquid_rate",
		"struggle_messages_outside",
		"struggle_messages_inside",
		"digest_messages_owner",
		"digest_messages_prey",
		"examine_messages",
		"absorbed_messages",
		"emote_lists",
		"is_wet",
		"wet_loop",
		"can_victim_see",
		"eating_privacy",
		"private_struggle",
		"drain_mode",
		"entrance_logs",
		"item_digest_logs",
		"absorbedrename_enabled",
		"absorbedrename_name",
		"save_digest_mode",
		"belly_fullscreen",
		"fullscreen_color",
		"fullscreen_alpha",
		)

		//ommitted list
		// "shrink_grow_size",

// Режим нутра сохраняется между раундами только при включённом save_digest_mode
/obj/belly/serialize()
	. = ..()
	if(save_digest_mode)
		.["digest_mode"] = digest_mode
	return .

/obj/belly/deserialize(var/list/data)
	. = ..()
	if(save_digest_mode && (data["digest_mode"] in digest_modes))
		digest_mode = data["digest_mode"]
	return .

/obj/belly/Initialize(mapload)
	. = ..()
	liquids = new /datum/reagents(200)
	liquids.my_atom = src
	take_ownership(src.loc)

/obj/belly/proc/take_ownership(var/newloc)
	//If not, we're probably just in a prefs list or something.
	if(isliving(newloc))
		owner = loc
		owner.vore_organs |= src
		SSbellies.belly_list += src

// Имя, которое видят игроки: display_name имеет приоритет над name
/obj/belly/proc/get_display_name()
	return display_name || name

/obj/belly/proc/get_display_name_lower()
	return lowertext(display_name || name)

// Радиус сообщений о поглощении/выпуске: subtle и глобальная приватность скрывают их от чужих
/obj/belly/proc/get_privacy_range()
	switch(lowertext(eating_privacy))
		if("subtle")
			return 1
		if("default")
			if(owner?.eating_privacy_global)
				return 1
	return world.view

// Звук нутра с учётом громкости; list - GLOB-список, key - имя звука
/obj/belly/proc/get_sound(var/list/sound_list, var/key)
	var/path = sound_list[key]
	if(!path)
		return
	var/sound/S = sound(path, repeat = 0, wait = 0, channel = 0, volume = sound_volume)
	if(noise_freq)
		S.frequency = noise_freq
	return S

// Полноэкранный оверлей добычи (Vore FX)
/atom/movable/screen/fullscreen/scaled/vore
	icon = 'icons/mob/vore_fullscreens/belly_overlays.dmi'
	icon_state = "flesh"
	size_x = 15
	size_y = 15

/obj/belly/proc/apply_fullscreen(mob/living/L)
	if(!istype(L) || !L.client)
		return
	if(!belly_fullscreen)
		L.clear_fullscreen("vore_belly", 0)
		return
	var/atom/movable/screen/fullscreen/scaled/vore/S = L.overlay_fullscreen("vore_belly", /atom/movable/screen/fullscreen/scaled/vore)
	if(!S)
		return
	S.icon_state = belly_fullscreen
	S.alpha = fullscreen_alpha
	S.color = fullscreen_color || null

/obj/belly/proc/update_fullscreen()
	for(var/mob/living/M in contents)
		apply_fullscreen(M)

// Подстановка переменных в сообщения нутра (%pred/%prey/%belly/%count/%countprey)
/obj/belly/proc/apply_message_vars(var/text, var/mob/living/prey)
	var/count_prey = 0
	for(var/mob/living/M in contents)
		if(!(M.vore_flags & ABSORBED))
			count_prey++
	if(prey)
		text = replacetext(text, "%prey", prey)
	text = replacetext(text, "%pred", owner)
	text = replacetext(text, "%belly", get_display_name_lower())
	text = replacetext(text, "%countprey", count_prey)
	text = replacetext(text, "%count", LAZYLEN(contents))
	return text

/obj/belly/Destroy()
	SSbellies.belly_list -= src
	for(var/mob/living/M in contents)
		M.clear_fullscreen("vore_belly", 0)
	qdel(liquids)
	liquids = null
	if(owner?.vore_organs)
		owner.vore_organs -= src
		if(owner.vore_selected == src)
			owner.vore_selected = null
		owner = null
	. = ..()

// Called whenever an atom enters this belly
/obj/belly/Entered(atom/movable/thing, atom/OldLoc)
	. = ..()
	var/mob/living/L //for chat messages and blindness
	if(isliving(thing))
		L = thing
		set_blinding(L)
		apply_fullscreen(L)
	if(OldLoc in contents)
		return //Someone dropping something (or being stripdigested)

	if(contaminates && isitem(thing))
		var/obj/item/contaminated_item = thing
		contaminated_item.vore_contaminate(contaminate_color, contaminate_flavor)

	//Generic entered message
	if(entrance_logs)
		to_chat(owner, span_notice("[thing.name] соскальзывает в ваш [get_display_name_lower()]."))

	//Sound w/ antispam flag setting
	if(vore_sound && !recent_sound)
		if((world.time + NORMIE_HEARCHECK) > last_hearcheck)
			LAZYCLEARLIST(hearing_mobs)
			for(var/mob/living/H in get_hearers_in_view(VORE_SOUND_RANGE, owner))
				if(!H.client || !(H.client.prefs.cit_toggles & EATING_NOISES))
					continue
				LAZYADD(hearing_mobs, H)
			last_hearcheck = world.time
		for(var/mob/living/H in hearing_mobs)
			if(H && H.client && (isturf(H.loc) || (H.loc != src.contents)))
				SEND_SOUND(H, get_sound(GLOB.pred_vore_sounds, vore_sound))
			else if(H?.client && (H in contents))
				SEND_SOUND(H, get_sound(GLOB.prey_vore_sounds, vore_sound))
			recent_sound = TRUE

	if(L && desc)
		to_chat(L, "<span class='notice'><B>[desc]</B></span>")

/obj/belly/Exited(atom/movable/AM, atom/newloc)
	. = ..()
	if(isliving(AM))
		set_blinding(AM, TRUE)
		var/mob/living/L = AM
		L.clear_fullscreen("vore_belly", 0)

/obj/belly/get_remote_view_fullscreens(mob/user)
	user.overlay_fullscreen("remote_view", /atom/movable/screen/fullscreen/scaled/impaired, 1)

/obj/belly/proc/set_blinding(mob/living/target, clear)
	if(!istype(target))
		return
	if(isnull(clear))
		clear = can_victim_see
	if(clear)
		target.cure_blind("belly_[REF(src)]")
	else
		target.become_blind("belly_[REF(src)]")

// Release all contents of this belly into the owning mob's location.
// If that location is another mob, contents are transferred into whichever of its bellies the owning mob is in.
// Returns the number of mobs so released.
/obj/belly/proc/release_all_contents(var/include_absorbed = FALSE, var/silent = FALSE)
//	var/atom/destination = drop_location()
	//Don't bother if we don't have contents
	if(!contents.len)
		return FALSE

	var/count = 0
	for(var/thing in contents)
		var/atom/movable/AM = thing
		if(isliving(AM))
			var/mob/living/L = AM
			var/mob/living/OW = owner
			if(L.vore_flags & ABSORBED && !include_absorbed)
				continue
			L.vore_flags &= ~ABSORBED
			L.stop_sound_channel(CHANNEL_PREYLOOP)
			SEND_SIGNAL(OW, COMSIG_CLEAR_MOOD_EVENT, "fedpred", /datum/mood_event/fedpred)
			SEND_SIGNAL(L, COMSIG_CLEAR_MOOD_EVENT, "fedprey", /datum/mood_event/fedprey)
			SEND_SIGNAL(OW, COMSIG_ADD_MOOD_EVENT, "emptypred", /datum/mood_event/emptypred)
			SEND_SIGNAL(L, COMSIG_ADD_MOOD_EVENT, "emptyprey", /datum/mood_event/emptyprey)
		count += release_specific_contents(AM, silent = TRUE)

	//Clean up our own business
	items_preserved.Cut()
	owner.update_icons()

	if(!silent)
		if(release_sound && !recent_sound)
			if((world.time + NORMIE_HEARCHECK) > last_hearcheck)
				LAZYCLEARLIST(hearing_mobs)
				for(var/mob/living/H in get_hearers_in_view(VORE_SOUND_RANGE, owner))
					if(!H.client || !(H.client.prefs.cit_toggles & EATING_NOISES))
						continue
					LAZYADD(hearing_mobs, H)
				last_hearcheck = world.time
			for(var/mob/living/H in hearing_mobs)
				if(H && H.client && (isturf(H.loc) || (H.loc != src.contents)))
					var/sound/releasement = get_sound(GLOB.pred_release_sounds, release_sound)
					H.playsound_local(owner.loc, releasement, sound_volume, TRUE, noise_freq)
				else if(H?.client && (H in contents))
					SEND_SOUND(H, get_sound(GLOB.prey_release_sounds, release_sound))
				recent_sound = TRUE
		owner.visible_message("<font color='green'><b>[owner.name] [release_verb] всё из своего [get_display_name_lower()]!</b></font>", vision_distance = get_privacy_range())

	return count

// Release a specific atom from the contents of this belly into the owning mob's location.
// If that location is another mob, the atom is transferred into whichever of its bellies the owning mob is in.
// Returns the number of atoms so released.
/obj/belly/proc/release_specific_contents(var/atom/movable/M, var/silent = FALSE)
	if (!(M in contents))
		return FALSE // They weren't in this belly anyway

	M.forceMove(drop_location())  // Move the belly contents into the same location as belly's owner.
	items_preserved -= M


	if(istype(M,/mob/living))
		var/mob/living/ML = M
		var/mob/living/OW = owner
		if(ML.client)
			ML.stop_sound_channel(CHANNEL_PREYLOOP) //Stop the internal loop, it'll restart if the isbelly check on next tick anyway
		SEND_SIGNAL(OW, COMSIG_CLEAR_MOOD_EVENT, "fedpred", /datum/mood_event/fedpred)
		SEND_SIGNAL(ML, COMSIG_CLEAR_MOOD_EVENT, "fedprey", /datum/mood_event/fedprey)
		SEND_SIGNAL(OW, COMSIG_ADD_MOOD_EVENT, "emptypred", /datum/mood_event/emptypred)
		SEND_SIGNAL(ML, COMSIG_ADD_MOOD_EVENT, "emptyprey", /datum/mood_event/emptyprey)

		if((ML.vore_flags & ABSORBED))
			ML.vore_flags &= ~(ABSORBED)
			restore_absorbed_name(ML)
			if(ishuman(M) && ishuman(OW))
				var/mob/living/carbon/human/Prey = M
				var/mob/living/carbon/human/Pred = OW
				var/absorbed_count = 2 //Prey that we were, plus the pred gets a portion
				for(var/mob/living/P in contents)
					if((P.vore_flags & ABSORBED))
						absorbed_count++
				Pred.reagents.trans_to(Prey, Pred.reagents.total_volume / absorbed_count)

	//Clean up our own business
	owner.update_icons()

	if(!silent)
		if(release_sound && !recent_sound)
			if((world.time + NORMIE_HEARCHECK) > last_hearcheck)
				LAZYCLEARLIST(hearing_mobs)
				for(var/mob/living/H in get_hearers_in_view(3, owner))
					if(!H.client || !(H.client.prefs.cit_toggles & EATING_NOISES))
						continue
					LAZYADD(hearing_mobs, H)
					last_hearcheck = world.time
			for(var/mob/living/H in hearing_mobs)
				if(H && H.client && (isturf(H.loc) || (H.loc != src.contents)))
					var/sound/releasement = get_sound(GLOB.pred_release_sounds, release_sound)
					H.playsound_local(owner.loc, releasement, sound_volume, TRUE, noise_freq)
				else if(H?.client && (H in contents))
					SEND_SOUND(H, get_sound(GLOB.prey_release_sounds, release_sound))
				recent_sound = TRUE
		owner.visible_message("<font color='green'><b>[owner.name] [release_verb] [M.name] из своего [get_display_name_lower()]!</b></font>", vision_distance = get_privacy_range())

	return TRUE

// Actually perform the mechanics of devouring the tasty prey.
// The purpose of this method is to avoid duplicate code, and ensure that all necessary
// steps are taken.
/obj/belly/proc/nom_mob(var/mob/prey, var/mob/user)
	if(owner.stat == DEAD)
		return
	if (prey.buckled)
		prey.buckled.unbuckle_mob(prey,TRUE)

	if(!isbelly(prey.loc))
		SEND_SIGNAL(owner, COMSIG_ADD_MOOD_EVENT, "fedpred", /datum/mood_event/fedpred)
		SEND_SIGNAL(prey, COMSIG_ADD_MOOD_EVENT, "fedprey", /datum/mood_event/fedprey)
	else
		SEND_SIGNAL(owner, COMSIG_CLEAR_MOOD_EVENT, "emptypred", /datum/mood_event/emptypred)
		SEND_SIGNAL(prey, COMSIG_CLEAR_MOOD_EVENT, "emptyprey", /datum/mood_event/emptyprey)

	prey.forceMove(src)
	prey.forceMove(src)

	owner.updateVRPanel()

	for(var/mob/living/M in contents)
		M.updateVRPanel()

	// Setup the autotransfer checks if needed
	if(transferlocation != null && autotransferchance > 0)
		addtimer(CALLBACK(src, TYPE_PROC_REF(/obj/belly, check_autotransfer), prey), autotransferwait)

/obj/belly/proc/check_autotransfer(var/mob/prey, var/obj/belly/target)
	// Some sanity checks
	if(transferlocation && (autotransferchance > 0) && (prey in contents))
		if(isliving(prey))
			var/mob/living/L = prey
			if(L.vore_flags & NO_AUTOTRANSFER)
				return
		if(prob(autotransferchance))
			transfer_contents(prey, transferlocation)
		else
			// Didn't transfer, so wait before retrying
			addtimer(CALLBACK(src, TYPE_PROC_REF(/obj/belly, check_autotransfer), prey), autotransferwait)

//Transfers contents from one belly to another
/obj/belly/proc/transfer_contents(var/atom/movable/content, var/obj/belly/target, silent = FALSE)
	if(!(content in src) || !istype(target))
		return
	content.forceMove(target)

	if(vore_sound && !recent_sound && !silent)
		if((world.time + NORMIE_HEARCHECK) > last_hearcheck)
			LAZYCLEARLIST(hearing_mobs)
			for(var/mob/living/H in get_hearers_in_view(VORE_SOUND_RANGE, owner))
				if(!H.client || !(H.client.prefs.cit_toggles & EATING_NOISES))
					continue
				LAZYADD(hearing_mobs, H)
				last_hearcheck = world.time
		for(var/mob/living/H in hearing_mobs)
			if(H && H.client && (isturf(H.loc) || (H.loc != src.contents)))
				H.playsound_local(owner.loc, get_sound(GLOB.pred_vore_sounds, vore_sound), sound_volume, TRUE, noise_freq)
			else if(H?.client && (H in contents))
				SEND_SOUND(H, get_sound(GLOB.prey_vore_sounds, vore_sound))
			recent_sound = TRUE

	owner.updateVRPanel()
	for(var/mob/living/M in contents)
		M.updateVRPanel()

// Get the line that should show up in Examine message if the owner of this belly
// is examined.   By making this a proc, we not only take advantage of polymorphism,
// but can easily make the message vary based on how many people are inside, etc.
// Returns a string which shoul be appended to the Examine output.
/obj/belly/proc/get_examine_msg()
	if(contents.len)
		var/list/message_pool = examine_messages
		var/has_absorbed = FALSE
		for(var/mob/living/P in contents)
			if(P.vore_flags & ABSORBED)
				has_absorbed = TRUE
				break
		if(has_absorbed && LAZYLEN(absorbed_messages["em"]))
			message_pool = absorbed_messages["em"]
		if(message_pool.len)
			var/formatted_message
			var/raw_message = pick(message_pool)
			var/total_bulge = 0

			formatted_message = apply_message_vars(raw_message)
			formatted_message = replacetext(formatted_message,"%prey",english_list(contents))
			for(var/mob/living/P in contents)
				if(!(P.vore_flags & ABSORBED)) //This is required first, in case there's a person absorbed and not absorbed in a stomach.
					total_bulge += P.mob_size
			if(total_bulge >= bulge_size && bulge_size != 0)
				return("<span class='warning'>[formatted_message]</span><BR>")
			else
				return ""

	if(show_liq_fullness && liquids && liquids.total_volume >= 20)
		return "<span class='warning'>[apply_message_vars("В %belly %pred слышно, как плещется жидкость.")]</span><BR>"

// The next function gets the messages set on the belly, in human-readable format.
// This is useful in customization boxes and such. The delimiter right now is \n\n so
// in message boxes, this looks nice and is easily delimited.
/obj/belly/proc/get_messages(var/type, var/delim = "\n\n")
	ASSERT(type == "smo" || type == "smi" || type == "dmo" || type == "dmp" || type == "em")
	var/list/raw_messages

	switch(type)
		if("smo")
			raw_messages = struggle_messages_outside
		if("smi")
			raw_messages = struggle_messages_inside
		if("dmo")
			raw_messages = digest_messages_owner
		if("dmp")
			raw_messages = digest_messages_prey
		if("em")
			raw_messages = examine_messages

	var/messages = raw_messages.Join(delim)
	return messages

// The next function sets the messages on the belly, from human-readable var
// replacement strings and linebreaks as delimiters (two \n\n by default).
// They also sanitize the messages.
/obj/belly/proc/get_emote_messages(var/mode)
	var/list/L = emote_lists[mode]
	return L ? L.Join("\n\n") : ""

/obj/belly/proc/set_emote_messages(var/raw_text, var/mode)
	if(!(mode in digest_modes))
		return
	var/list/raw_list = splittext(strip_control_chars(html_encode(html_decode(raw_text))), "\n\n")
	if(raw_list.len > 10)
		raw_list.Cut(11)
	for(var/i = 1, i <= raw_list.len, i++)
		if(length(raw_list[i]) > 160 || !length(raw_list[i]))
			raw_list.Cut(i, i)
		else
			raw_list[i] = readd_quotes(raw_list[i])
			raw_list[i] = replacetext(raw_list[i], "&#37;", "%")
	emote_lists[mode] = raw_list
	return

/obj/belly/proc/sanitize_message_list(var/raw_text, var/delim = "\n\n")
	// html_decode first so re-submitting already-encoded text (get_messages feeds the
	// stored value back as the input default) normalizes instead of double-encoding
	// (& -> &amp; -> &amp;amp;). strip_control_chars keeps the \n\n delimiters.
	var/list/raw_list = splittext(strip_control_chars(html_encode(html_decode(raw_text))),delim)
	if(raw_list.len > 10)
		raw_list.Cut(11)
		testing("[owner] tried to set [lowertext(name)] with 11+ messages")

	for(var/i = 1, i <= raw_list.len, i++)
		if(length(raw_list[i]) > 160 || length(raw_list[i]) < 10) //160 is fudged value due to htmlencoding increasing the size
			raw_list.Cut(i,i)
			testing("[owner] tried to set [lowertext(name)] with >121 or <10 char message")
		else
			raw_list[i] = readd_quotes(raw_list[i])
			//Also fix % sign for var replacement
			raw_list[i] = replacetext(raw_list[i],"&#37;","%")

	ASSERT(raw_list.len <= 10) //Sanity
	return raw_list

/obj/belly/proc/set_messages(var/raw_text, var/type, var/delim = "\n\n")
	ASSERT(type == "smo" || type == "smi" || type == "dmo" || type == "dmp" || type == "em")
	var/list/raw_list = sanitize_message_list(raw_text, delim)

	switch(type)
		if("smo")
			struggle_messages_outside = raw_list
		if("smi")
			struggle_messages_inside = raw_list
		if("dmo")
			digest_messages_owner = raw_list
		if("dmp")
			digest_messages_prey = raw_list
		if("em")
			examine_messages = raw_list

	return

/obj/belly/proc/get_absorbed_messages(var/type, var/delim = "\n\n")
	var/list/raw_list = absorbed_messages[type]
	return raw_list ? raw_list.Join(delim) : ""

/obj/belly/proc/set_absorbed_messages(var/raw_text, var/type, var/delim = "\n\n")
	ASSERT(type == "smo" || type == "smi" || type == "dmo" || type == "dmp" || type == "em")
	absorbed_messages[type] = sanitize_message_list(raw_text, delim)
	return

// Handle the death of a mob via digestion.
// Called from the process_Life() methods of bellies that digest prey.
// Default implementation calls M.death() and removes from internal contents.
// Indigestable items are removed, and M is deleted.
/obj/belly/proc/digestion_death(var/mob/living/M)
	//M.death(1) // "Stop it he's already dead..." Basically redundant and the reason behind screaming mouse carcasses.
	if(M.ckey)
		message_admins("[key_name(owner)] has digested [key_name(M)] in their [lowertext(name)] ([owner ? "<a href='?_src_=holder;adminplayerobservecoodjump=1;X=[owner.x];Y=[owner.y];Z=[owner.z]'>JMP</a>" : "null"])")
		log_attack("[key_name(owner)] digested [key_name(M)].")

	// If digested prey is also a pred... anyone inside their bellies gets moved up.
	if(has_vore_belly(M))
		M.release_vore_contents(include_absorbed = TRUE, silent = TRUE)

	//Drop all items into the belly
	for(var/obj/item/W in M)
		if(!M.dropItemToGround(W))
			qdel(W)

	//Incase they have the loop going, let's double check to stop it.
	M.stop_sound_channel(CHANNEL_PREYLOOP)
	M.clear_fullscreen("vore_belly", 0)

	// Delete the digested mob
	if(("Leave Remains" in mode_addons) && !(M.vore_flags & NO_REMAINS))
		var/remain_path = /obj/effect/decal/remains/human
		if(iscyborg(M))
			remain_path = /obj/effect/decal/remains/robot
		else if(!ishuman(M))
			remain_path = /obj/effect/decal/remains/xeno
		new remain_path(owner ? owner.loc : get_turf(src))
	qdel(M)

	//Update owner
	owner.updateVRPanel()

// Handle a mob being absorbed
/obj/belly/proc/absorb_living(var/mob/living/M)
	M.vore_flags |= ABSORBED
	to_chat(M, span_notice("[name] [owner.name] впитывает ваше тело и делает частью себя."))
	to_chat(owner, span_notice("Ваш [get_display_name_lower()] впитывает тело [M.name] и делает частью вас."))

	if(absorbedrename_enabled && !M.vore_absorbed_old_name)
		M.vore_absorbed_old_name = M.name
		M.name = replacetext(replacetext(absorbedrename_name, "%pred", owner), "%belly", get_display_name_lower())

	if(absorbed_desc)
		to_chat(M, span_notice("<b>[apply_message_vars(absorbed_desc, M)]</b>"))

	if(M.loc != src)
		M.forceMove(src)

	//Seek out absorbed prey of the prey, absorb them too.
	//This in particular will recurse oddly because if there is absorbed prey of prey of prey...
	//it will just move them up one belly. This should never happen though since... when they were
	//absobred, they should have been absorbed as well!
	for(var/belly in M.vore_organs)
		var/obj/belly/B = belly
		for(var/mob/living/Mm in B)
			if((Mm.vore_flags & ABSORBED))
				absorb_living(Mm)

	//Update owner
	owner.updateVRPanel()

// Вернуть имя добыче, которую переименовали при поглощении
/obj/belly/proc/restore_absorbed_name(var/mob/living/M)
	if(M?.vore_absorbed_old_name)
		M.name = M.vore_absorbed_old_name
		M.vore_absorbed_old_name = null

//Digest a single item
//Receives a return value from digest_act that's how much nutrition
//the item should be worth
/obj/belly/proc/digest_item(var/obj/item/item)
	var/item_name = item.name
	var/digested = item.digest_act(src, owner)
	if(!digested)
		items_preserved |= item
	else
		if(item_digest_logs && owner)
			to_chat(owner, span_notice("Ваш [get_display_name_lower()] переваривает [item_name]."))
//		owner.adjust_nutrition(5 * digested) // haha no.
		if(iscyborg(owner))
			var/mob/living/silicon/robot/R = owner
			R.cell.charge += (50 * digested)

//Determine where items should fall out of us into.
//Typically just to the owner's location.
/obj/belly/drop_location()
	//Should be the case 99.99% of the time
	if(owner)
		return owner.drop_location()
	//Sketchy fallback for safety, put them somewhere safe.
	else if(ismob(src))
		testing("[src] (\ref[src]) doesn't have an owner, and dropped someone at a latespawn point!")
		SSjob.SendToLateJoin(src)
		// wew lad. let's see if this never gets used, hopefully
	else
		qdel(src) //final option, I guess.
		testing("[src] (\ref[src]) was QDEL'd for not having a drop_location!")

//Yes, it's ""safe"" to drop items here
/obj/belly/AllowDrop()
	return TRUE

//Handle a mob struggling
// Called from /mob/living/carbon/relaymove()
/obj/belly/proc/relay_resist(mob/living/R)
	if (!(R in contents))
		return  // User is not in this belly

	if(owner.stat) //If owner is stat (dead, KO) we can actually escape
		to_chat(R, span_warning("Вы патаетесь покинуть [get_display_name_lower()]. (Это займёт [escapetime/10] секунд.)"))
		to_chat(owner, span_warning("Кто-то старается покинуть ваш [get_display_name_lower()]!"))

		if(do_after(R, escapetime, owner, (IGNORE_TARGET_LOC_CHANGE|IGNORE_HELD_ITEM)))
			if((owner.stat || escapable) && (R.loc == src)) //Can still escape?
				release_specific_contents(R)
				return
			else if(R.loc != src) //Aren't even in the belly. Quietly fail.
				return
			else //Belly became inescapable or mob revived
				to_chat(R, span_warning("Ваша попытка покинуть [get_display_name_lower()] провалилась!"))
				to_chat(owner, span_notice("Попытка покинуть ваш [get_display_name_lower()] провалилась!"))
				return

	var/struggle_outer_message
	var/struggle_user_message
	if(R.vore_flags & ABSORBED)
		var/list/outer_pool = LAZYLEN(absorbed_messages["smo"]) ? absorbed_messages["smo"] : struggle_messages_outside
		var/list/inner_pool = LAZYLEN(absorbed_messages["smi"]) ? absorbed_messages["smi"] : struggle_messages_inside
		struggle_outer_message = apply_message_vars(pick(outer_pool), R)
		struggle_user_message = apply_message_vars(pick(inner_pool), R)
	else
		struggle_outer_message = apply_message_vars(pick(struggle_messages_outside), R)
		struggle_user_message = apply_message_vars(pick(struggle_messages_inside), R)

	struggle_outer_message = "<span class='alert'>" + struggle_outer_message + "</span>"
	struggle_user_message = "<span class='alert'>" + struggle_user_message + "</span>"

	var/sound/pred_struggle_snuggle = sound(get_sfx("struggle_sound"))
	var/sound/prey_struggle_snuggle = sound(get_sfx("prey_struggle"))
	var/sound/struggle_rustle = sound(get_sfx("rustle"))

	LAZYCLEARLIST(hearing_mobs)
	if(!private_struggle)
		for(var/mob/living/H in get_hearers_in_view(VORE_SOUND_RANGE, owner))
			if(!H.client || !(H.client.prefs.cit_toggles & EATING_NOISES))
				continue
			LAZYADD(hearing_mobs, H)

	if(private_struggle)
		to_chat(owner, struggle_outer_message)
		if(R.client)
			if(is_wet)
				SEND_SOUND(R, prey_struggle_snuggle)
			else
				SEND_SOUND(R, struggle_rustle)
	else
		if(is_wet)
			for(var/mob/living/H in hearing_mobs)
				if(H && H.client && (isturf(H.loc) || (H.loc != src.contents)))
					H.playsound_local(owner.loc, pred_struggle_snuggle, 75, TRUE)
				else if(H && H.client && (H in contents))
					SEND_SOUND(H,prey_struggle_snuggle)

		else
			for(var/mob/living/H in hearing_mobs)
				if(H && H.client)
					H.playsound_local(owner.loc, struggle_rustle, 75, TRUE)

		for(var/mob/living/H in hearing_mobs)
			if(H && H.client && (isturf(H.loc)))
				H.show_message(struggle_outer_message, MSG_VISUAL) // visible

	to_chat(R,struggle_user_message)

	if(escapable) //If the stomach has escapable enabled.
		if(prob(escapechance)) //Let's have it check to see if the prey escapes first.
			to_chat(R, span_warning("Вы пытаетесь покинуть [get_display_name_lower()]."))
			to_chat(owner, span_warning("Кто-то пытается покинуть ваш [get_display_name_lower()]!"))
			if(do_after(R, escapetime, owner, (IGNORE_TARGET_LOC_CHANGE|IGNORE_HELD_ITEM)))
				if((escapable) && (R.loc == src)) //Can still escape?
					release_specific_contents(R)
					to_chat(R, span_warning("Вы покидаете [get_display_name_lower()]."))
					to_chat(owner, span_warning("[R] покидает ваш [get_display_name_lower()]!"))
					return
				else if(R.loc != src) //Aren't even in the belly. Quietly fail.
					return
				else //Belly became inescapable or mob revived
					to_chat(R, span_warning("Ваша попытка покинуть [get_display_name_lower()] провалилась!"))
					to_chat(owner, span_notice("Попытка покинуть ваш [get_display_name_lower()] провалилась!"))
					return
		else if(prob(transferchance) && transferlocation) //Next, let's have it see if they end up getting into an even bigger mess then when they started.
			var/obj/belly/dest_belly
			for(var/belly in owner.vore_organs)
				var/obj/belly/B = belly
				if(B.name == transferlocation)
					dest_belly = B
					break

			if(!dest_belly)
				to_chat(owner, span_warning("Something went wrong with your belly transfer settings. Настройки шанса перемещения и места перемещения были сброшены для вашего <b>\[[get_display_name_lower()]\]</b> в мерах предосторожности."))
				transferchance = 0
				transferlocation = null
				return

			to_chat(R, span_warning("Ваши попытки покинуть [get_display_name_lower()] провалились и в результате вы соскальзываете в [transferlocation] [owner]!"))
			to_chat(owner, span_warning("Кто-то соскользнул в ваш [transferlocation] вследствии своих попыток покинуть [get_display_name_lower()]!"))
			transfer_contents(R, dest_belly)
			return

		else if(prob(absorbchance) && digest_mode != DM_ABSORB) //After that, let's have it run the absorb chance.
			to_chat(R, span_warning("В ответ на ваше сопротивление [get_display_name_lower()] начинает всё больше сжиматься вокруг..."))
			to_chat(owner, span_warning("Вы ощущаете как ваш [get_display_name_lower()] начинает всё больше сжиматься вокруг своего содержимого..."))
			digest_mode = DM_ABSORB
			return

		else if(prob(digestchance) && digest_mode != DM_DIGEST) //Finally, let's see if it should run the digest chance.
			to_chat(R, span_warning("В ответ на ваше сопротивление [get_display_name_lower()] становится всё активнее..."))
			to_chat(owner, span_warning("Вы ощущаете как ваш [get_display_name_lower()] становится всё активнее!"))
			digest_mode = DM_DIGEST
			return

		else //Nothing interesting happened.
			to_chat(R, span_warning("Вы не делаете успехов покинуть [get_display_name_lower()] [owner]."))
			to_chat(owner, span_warning("Ваша жертва, похоже, не делает успехов покинуть [get_display_name_lower()]."))
			return

/obj/belly/proc/get_mobs_and_objs_in_belly()
	var/list/see = list()
	var/list/belly_mobs = list()
	see["mobs"] = belly_mobs
	var/list/belly_objs = list()
	see["objs"] = belly_objs
	for(var/mob/living/L in loc.contents)
		belly_mobs |= L
	for(var/obj/O in loc.contents)
		belly_objs |= O

	return see


// Belly copies and then returns the copy
// Needs to be updated for any var changes AND KEPT IN ORDER OF THE VARS ABOVE AS WELL!
/obj/belly/proc/copy(mob/new_owner)
	var/obj/belly/dupe = new /obj/belly(new_owner)

	//// Non-object variables
	dupe.name = name
	dupe.desc = desc
	dupe.absorbed_desc = absorbed_desc
	dupe.display_name = display_name
	dupe.vore_types = vore_types.Copy()
	dupe.mode_addons = mode_addons.Copy()
	dupe.vore_sound = vore_sound
	dupe.vore_verb = vore_verb
	dupe.release_verb = release_verb
	dupe.release_sound = release_sound
	dupe.sound_volume = sound_volume
	dupe.noise_freq = noise_freq
	dupe.human_prey_swallow_time = human_prey_swallow_time
	dupe.nonhuman_prey_swallow_time = nonhuman_prey_swallow_time
	dupe.emote_time = emote_time
	dupe.emote_active = emote_active
	dupe.digest_brute = digest_brute
	dupe.digest_burn = digest_burn
	dupe.digest_oxy = digest_oxy
	dupe.digest_tox = digest_tox
	dupe.digest_clone = digest_clone
	dupe.nutrition_percent = nutrition_percent
	dupe.item_mode = item_mode
	dupe.belly_temperature = belly_temperature
	dupe.temperature_damage = temperature_damage
	dupe.immutable = immutable
	dupe.escapable = escapable
	dupe.escapetime = escapetime
	dupe.digestchance = digestchance
	dupe.absorbchance = absorbchance
	dupe.escapechance = escapechance
	dupe.can_taste = can_taste
	dupe.feedable = feedable
	dupe.bulge_size = bulge_size
	dupe.transferlocation = transferlocation
	dupe.transferchance = transferchance
	dupe.autotransferchance = autotransferchance
	dupe.autotransferwait = autotransferwait
	dupe.swallow_time = swallow_time
	dupe.vore_capacity = vore_capacity
	dupe.destination = destination
	dupe.show_liquids = show_liquids
	dupe.show_liq_fullness = show_liq_fullness
	dupe.contaminates = contaminates
	dupe.contaminate_color = contaminate_color
	dupe.contaminate_flavor = contaminate_flavor
	dupe.liquid_reagent = liquid_reagent
	dupe.liquid_rate = liquid_rate
	dupe.is_wet = is_wet
	dupe.wet_loop = wet_loop
	dupe.can_victim_see = can_victim_see
	dupe.eating_privacy = eating_privacy
	dupe.private_struggle = private_struggle
	dupe.drain_mode = drain_mode
	dupe.entrance_logs = entrance_logs
	dupe.item_digest_logs = item_digest_logs
	dupe.absorbedrename_enabled = absorbedrename_enabled
	dupe.absorbedrename_name = absorbedrename_name
	dupe.save_digest_mode = save_digest_mode
	dupe.belly_fullscreen = belly_fullscreen
	dupe.fullscreen_color = fullscreen_color
	dupe.fullscreen_alpha = fullscreen_alpha
	if(save_digest_mode)
		dupe.digest_mode = digest_mode

	//// Object-holding variables
	//struggle_messages_outside - strings
	dupe.struggle_messages_outside.Cut()
	for(var/I in struggle_messages_outside)
		dupe.struggle_messages_outside += I

	//struggle_messages_inside - strings
	dupe.struggle_messages_inside.Cut()
	for(var/I in struggle_messages_inside)
		dupe.struggle_messages_inside += I

	//digest_messages_owner - strings
	dupe.digest_messages_owner.Cut()
	for(var/I in digest_messages_owner)
		dupe.digest_messages_owner += I

	//digest_messages_prey - strings
	dupe.digest_messages_prey.Cut()
	for(var/I in digest_messages_prey)
		dupe.digest_messages_prey += I

	//examine_messages - strings
	dupe.examine_messages.Cut()
	for(var/I in examine_messages)
		dupe.examine_messages += I

	//absorbed_messages - assoc list of message lists
	dupe.absorbed_messages.Cut()
	for(var/K in absorbed_messages)
		dupe.absorbed_messages[K] = list()
		for(var/I in absorbed_messages[K])
			dupe.absorbed_messages[K] += I

	//emote_lists - index: digest mode, key: list of strings
	dupe.emote_lists.Cut()
	for(var/K in emote_lists)
		dupe.emote_lists[K] = list()
		for(var/I in emote_lists[K])
			dupe.emote_lists[K] += I
	return dupe
