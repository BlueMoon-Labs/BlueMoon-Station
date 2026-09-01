/datum/dog_fashion
	var/name
	var/desc
	var/emote_see
	var/emote_hear
	var/speak
	var/speak_emote

	// This isn't applied to the dog, but stores the icon_state of the
	// sprite that the associated item uses
	var/icon_file
	var/obj_icon_state
	var/obj_alpha
	var/obj_color
	/// Запасной источник спрайта: носимая иконка вещи, если нарисованной для питомца нет.
	var/fallback_icon_file
	/// На сколько опустить запасной оверлей - голова питомца ниже человеческой.
	var/fallback_pixel_y = 0

/datum/dog_fashion/New(mob/M)
	name = replacetext(name, "REAL_NAME", M.real_name)
	desc = replacetext(desc, "NAME", name)

/datum/dog_fashion/proc/apply(mob/living/simple_animal/pet/dog/D)
	if(name)
		D.name = name
	if(desc)
		D.desc = desc
	if(emote_see)
		D.emote_see = emote_see
	if(emote_hear)
		D.emote_hear = emote_hear
	if(speak)
		D.speak = speak
	if(speak_emote)
		D.speak_emote = speak_emote

/// Кеш пригодных имён стейтов по файлу иконки: icon_states() строит новый список на каждый
/// вызов, а разбирать 660-стейтный head.dmi на каждое надевание шапки незачем.
GLOBAL_LIST_EMPTY(dog_fashion_icon_states)

/// Имена стейтов файла, если он вообще годится питомцу. Файл разбирается один раз за раунд.
/proc/dog_fashion_icon_states(icon_path)
	if(!icon_path)
		return list()
	var/file_key = "[icon_path]"
	var/list/known_states = GLOB.dog_fashion_icon_states[file_key]
	if(!isnull(known_states))
		return known_states
	known_states = list()
	var/icon/probe = icon(icon_path)
	// Спрайты крупнее тайла (64x64 шлемы из large-worn-icons) на корги смотрятся мусором:
	// такой файл целиком считаем непригодным и оставляем вещь без оверлея, как раньше.
	if(probe.Width() <= world.icon_size && probe.Height() <= world.icon_size)
		for(var/state in icon_states(icon_path))
			known_states[state] = TRUE
	GLOB.dog_fashion_icon_states[file_key] = known_states
	return known_states

/**
 * Оверлей вещи на питомце.
 *
 * Нарисованных для корги стейтов всего 37 (corgi_head.dmi), а head-слот принимает по
 * dog_fashion почти две сотни вещей: у остальных image() строился на несуществующем
 * стейте и BYOND молча рисовал ПУСТОТУ. Отсюда и жалоба - в шапку на Иане можно спрятать
 * ядерный диск, и шапки на нём не видно. Если своего спрайта нет, берём носимый спрайт
 * вещи и опускаем его на голову питомца.
 */
/datum/dog_fashion/proc/get_overlay(dir, obj/item/worn_item)
	var/image/pet_overlay
	if(dog_fashion_icon_states(icon_file)[obj_icon_state])
		pet_overlay = image(icon_file, obj_icon_state, dir = dir)
	else if(worn_item && fallback_icon_file)
		var/fallback_state = worn_item.icon_state
		var/fallback_file = worn_item.mob_overlay_icon //донатные респрайты живут здесь
		if(!dog_fashion_icon_states(fallback_file)[fallback_state])
			fallback_file = fallback_icon_file
		if(dog_fashion_icon_states(fallback_file)[fallback_state])
			pet_overlay = image(fallback_file, fallback_state, dir = dir)
			pet_overlay.pixel_y = fallback_pixel_y
	if(!pet_overlay)
		return
	pet_overlay.alpha = obj_alpha
	pet_overlay.color = obj_color
	return pet_overlay

/// Голова питомца ниже человеческой ровно на восемь пикселей.
#define PET_FALLBACK_HEAD_OFFSET -8

/datum/dog_fashion/head
	icon_file = 'icons/mob/corgi_head.dmi'
	fallback_icon_file = 'icons/mob/clothing/head.dmi'
	fallback_pixel_y = PET_FALLBACK_HEAD_OFFSET

#undef PET_FALLBACK_HEAD_OFFSET

/datum/dog_fashion/back
	icon_file = 'icons/mob/corgi_back.dmi'

/datum/dog_fashion/head/helmet
	name = "Sergeant REAL_NAME"
	desc = "The ever-loyal, the ever-vigilant."

/datum/dog_fashion/head/chef
	name = "Sous chef REAL_NAME"
	desc = "Your food will be taste-tested.  All of it."

/datum/dog_fashion/head/captain
	name = "Captain REAL_NAME"
	desc = "Probably better than the last captain."

/datum/dog_fashion/head/kitty
	name = "Runtime"
	emote_see = list("coughs up a furball", "stretches")
	emote_hear = list("purrs")
	speak = list("Purrr", "Meow!", "MAOOOOOW!", "HISSSSS", "MEEEEEEW")
	desc = "It's a cute little kitty-cat! ... wait ... what the hell?"

/datum/dog_fashion/head/rabbit
	name = "Hoppy"
	emote_see = list("twitches its nose", "hops around a bit")
	desc = "This is Hoppy. It's a corgi-...urmm... bunny rabbit."

/datum/dog_fashion/head/beret
	name = "Yann"
	desc = "Mon dieu! C'est un chien!"
	speak = list("le woof!", "le bark!", "JAPPE!!")
	emote_see = list("cowers in fear.", "surrenders.", "plays dead.","looks as though there is a wall in front of him.")


/datum/dog_fashion/head/detective
	name = "Detective REAL_NAME"
	desc = "NAME sees through your lies..."
	emote_see = list("investigates the area.","sniffs around for clues.","searches for scooby snacks.","takes a candycorn from the hat.")


/datum/dog_fashion/head/nurse
	name = "Nurse REAL_NAME"
	desc = "NAME needs 100cc of beef jerky... STAT!"

/datum/dog_fashion/head/pirate
	name = "Pirate-title Pirate-name"
	desc = "Yaarghh!! Thar' be a scurvy dog!"
	emote_see = list("hunts for treasure.","stares coldly...","gnashes his tiny corgi teeth!")
	emote_hear = list("growls ferociously!", "snarls.")
	speak = list("Arrrrgh!!","Grrrrrr!")

/datum/dog_fashion/head/pirate/New(mob/M)
	..()
	name = "[pick("Ol'","Scurvy","Black","Rum","Gammy","Bloody","Gangrene","Death","Long-John")] [pick("kibble","leg","beard","tooth","poop-deck","Threepwood","Le Chuck","corsair","Silver","Crusoe")]"

/datum/dog_fashion/head/ushanka
	name = "Communist-title Realname"
	desc = "A follower of Karl Barx."
	emote_see = list("contemplates the failings of the capitalist economic model.", "ponders the pros and cons of vanguardism.")

/datum/dog_fashion/head/ushanka/New(mob/M)
	..()
	name = "[pick("Comrade","Commissar","Glorious Leader")] [M.real_name]"

/datum/dog_fashion/head/warden
	name = "Officer REAL_NAME"
	emote_see = list("drools.","looks for donuts.")
	desc = "Stop right there criminal scum!"

/datum/dog_fashion/head/blue_wizard
	name = "Grandwizard REAL_NAME"
	speak = list("YAP", "Woof!", "Bark!", "AUUUUUU", "EI  NATH!")

/datum/dog_fashion/head/red_wizard
	name = "Pyromancer REAL_NAME"
	speak = list("YAP", "Woof!", "Bark!", "AUUUUUU", "ONI SOMA!")

/datum/dog_fashion/head/cardborg
	name = "Borgi"
	speak = list("Ping!","Beep!","Woof!")
	emote_see = list("goes rogue.", "sniffs out non-humans.")
	desc = "Result of robotics budget cuts."

/datum/dog_fashion/head/ghost
	name = "\improper Ghost"
	speak = list("WoooOOOooo~","AUUUUUUUUUUUUUUUUUU")
	emote_see = list("stumbles around.", "shivers.")
	emote_hear = list("howls!","groans.")
	desc = "Spooky!"
	obj_icon_state = "sheet"

/datum/dog_fashion/head/santa
	name = "Santa's Corgi Helper"
	emote_hear = list("barks Christmas songs.", "yaps merrily!")
	emote_see = list("looks for presents.", "checks his list.")
	desc = "He's very fond of milk and cookies."

/datum/dog_fashion/head/cargo_tech
	name = "Corgi Tech REAL_NAME"
	desc = "The reason your yellow gloves have chew-marks."

/datum/dog_fashion/head/reindeer
	name = "REAL_NAME the red-nosed Corgi"
	emote_hear = list("lights the way!", "illuminates.", "yaps!")
	desc = "He has a very shiny nose."

/datum/dog_fashion/head/sombrero
	name = "Segnor REAL_NAME"
	desc = "You must respect Elder Dogname"

/datum/dog_fashion/head/sombrero/New(mob/M)
	..()
	desc = "You must respect Elder [M.real_name]."

/datum/dog_fashion/head/hop
	name = "Lieutenant REAL_NAME"
	desc = "Can actually be trusted to not run off on his own."

/datum/dog_fashion/head/deathsquad
	name = "Trooper REAL_NAME"
	desc = "That's not red paint. That's real corgi blood."

/datum/dog_fashion/head/clown
	name = "REAL_NAME the Clown"
	desc = "Honkman's best friend."
	speak = list("HONK!", "Honk!")
	emote_see = list("plays tricks.", "slips.")

/datum/dog_fashion/back/deathsquad
	name = "Trooper REAL_NAME"
	desc = "That's not red paint. That's real corgi blood."

/datum/dog_fashion/head/telegram
	name = "Messenger REAL_NAME"
	desc = "Dont shoot the messenger..."
	emote_see = list("licks an envelope.","looks ready to set off to send a letter...","works on barking!")
