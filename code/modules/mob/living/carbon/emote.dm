/datum/emote/sound/human/carbon/airguitar
	name = "Воображаемая гитара"
	key = "airguitar"
	message = "играет на воображаемой гитаре и бьет головой, как шимпанзе в сафари."
	restraint_check = TRUE

/datum/emote/sound/human/carbon/blink
	name = "Моргать"
	key = "blink"
	key_third_person = "blinks"
	message = "моргает."

/datum/emote/sound/human/carbon/blink_r
	name = "Быстро Моргать"
	key = "blink3"
	message = "быстро моргает."

/datum/emote/sound/human/clap
	name = "Хлопать"
	key = "clap"
	key_third_person = "claps"
	message = "хлопает в ладони."
	muzzle_ignore = TRUE
	restraint_check = TRUE
	emote_type = EMOTE_AUDIBLE

/datum/emote/sound/human/clap/run_emote(mob/user, params)
	sound = pick('sound/misc/clap1.ogg', 'sound/misc/clap2.ogg', 'sound/misc/clap3.ogg', 'sound/misc/clap4.ogg')
	. = ..()

/datum/emote/sound/human/carbon/gnarl
	key = "gnarl"
	key_third_person = "gnarls"
	message = "gnarls and shows its teeth..."

/datum/emote/sound/human/carbon/moan
	name = "Постанывать"
	key = "moan"
	key_third_person = "moans"
	message = "постанывает!"
	message_mime = "делает вид, что издает стон!"
	emote_type = EMOTE_AUDIBLE
	stat_allowed = SOFT_CRIT
	emote_cooldown = 2 SECONDS

/datum/emote/sound/human/carbon/moan/run_emote(mob/user, params)
	if(user.gender == FEMALE || (user.gender == PLURAL && isfeminine(user)))
		sound = pick(GLOB.lewd_moans_female)
	else
		sound = pick(GLOB.lewd_moans_male)
	. = ..()

/datum/emote/sound/human/carbon/roll
	key = "roll"
	key_third_person = "rolls"
	message = "перекатывается."
	restraint_check = TRUE

/datum/emote/sound/human/carbon/screech
	key = "screech"
	key_third_person = "screeches"
	message = "громко скрипит."

/datum/emote/sound/human/carbon/scratch
	name = "Почесаться"
	key = "scratch"
	key_third_person = "scratches"
	message = "чешется."
	restraint_check = TRUE

/datum/emote/sound/human/carbon/sign
	key = "sign"
	key_third_person = "signs"
	message_param = "signs the number %t."
	restraint_check = TRUE

/datum/emote/sound/human/carbon/sign/select_param(mob/user, params)
	. = ..()
	if(!isnum(text2num(params)))
		return message

/datum/emote/sound/human/carbon/sign/signal
	key = "signal"
	key_third_person = "signals"
	message_param = "даёт сигнал для %t своими пальцами."

/datum/emote/sound/human/carbon/tail
	key = "tail"
	message = "начинает двигать своим хвостом."

/datum/emote/sound/human/carbon/wink
	name = "Подмигнуть"
	key = "wink"
	key_third_person = "winks"
	message = "подмигивает."

/datum/emote/sound/human/carbon/human/dap
	key = "dap"
	key_third_person = "daps"
	message = "делает ДЭП и... к сожалению, не может найти никого, кому можно было бы дать DAP. Стыдно."
	message_param = "ДЭПает при виде %t."
	restraint_check = TRUE

/datum/emote/sound/human/carbon/human/grumble
	name = "Ворчать"
	key = "grumble"
	key_third_person = "grumbles"
	message = "ворчит!"
	emote_type = EMOTE_AUDIBLE

/datum/emote/sound/human/carbon/human/mawp
	key = "mawp"
	key_third_person = "mawps"
	message = "раздраженно бормочет что-то на своём."
	emote_type = EMOTE_AUDIBLE
	emote_cooldown = 8 SECONDS

/datum/emote/sound/human/carbon/human/mawp/run_emote(mob/living/user, params)
	. = ..()
	if(.)
		if(ishuman(user))
			if(prob(10))
				user.adjustEarDamage(-5, -5)
	playsound(user, 'modular_citadel/sound/voice/purr.ogg', 50, 1, -1)	//почему мурчание?

/datum/emote/sound/human/carbon/lick
	name = "Облизать"
	key = "lick"
	key_third_person = "licks."
	restraint_check = TRUE

/datum/emote/sound/human/carbon/lick/run_emote(mob/user)
	. = ..()
	if(!iscarbon(user) || !.)
		return
	if(user.get_active_held_item())
		to_chat(user, span_warning("Ваша активная рука занята, и поэтому вы не можете ничего лизнуть! Не спрашивайте, почему!"))
		return
	var/obj/item/soap/tongue/organic/licky = new(user)
	if(user.put_in_active_hand(licky))
		to_chat(user, span_notice("Вы вытягиваете язык и готовитесь что-то лизнуть."))
	else
		qdel(licky)

/datum/emote/sound/human
	mob_type_allowed_typecache = list(/mob/living/)
	emote_type = EMOTE_AUDIBLE

/datum/emote/sound/human/salute
	name = "Исполнить Воинское Приветствие"
	key = "salute"
	key_third_person = "salutes"
	message = "исполняет воинское приветствие."
	message_param = "исполняет воинское приветствие при виде %t."
	sound = 'sound/voice/salute.ogg'
	restraint_check = TRUE

/datum/emote/sound/human/chime
	key = "chime"
	key_third_person = "chimes"
	message = "издаёт звон."
	sound = 'sound/machines/chime.ogg'

/datum/emote/sound/human/squeak
	key = "squeak"
	message = "пищит словно мышка."
	sound = 'sound/effects/mousesqueek.ogg'

/datum/emote/sound/human/shriek
	key = "shriek"
	key_third_person = "shrieks"
	message = "вскрикивает!"
	sound = 'sound/voice/shriek1.ogg'

/datum/emote/sound/human/growl2
	name = "Рычать Агрессивно"
	key = "growl2"
	key_third_person = "growls2"
	message = "издаёт особо агрессивное рычание."
	sound = 'sound/voice/growl2.ogg'

/datum/emote/sound/human/protect
	name = "Император Защищает"
	key = "protect"
	key_third_person = "protects"
	message = "складывает руки на груди, образуя аквилу."
	sound = 'sound/voice/emperorprotects.ogg'

/datum/emote/sound/human/zombie
	name = "Рычать как зомби"
	key = "zombie"
	key_third_person = "zombies"
	message = "рычит как зомби."
	sound = 'sound/voice/zombie.ogg'
	emote_cooldown = 3 SECONDS

/datum/emote/sound/human/zombie/select_message_type(mob/user)
	. = ..()
	if(. == message && iszombie(user)) // Родитель написан по дебильному, поэтому пока так
		return "рычит."
