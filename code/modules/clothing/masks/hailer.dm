GLOBAL_LIST_EMPTY(sechailers)

/datum/action/item_action/dispatch
    name = "Signal Dispatch"
    desc = "Открывает колесо быстрого выбора для сообщения о преступлениях, включая ваше текущее местоположение."
    icon_icon = 'icons/mob/actions/actions.dmi'
    button_icon_state = "dispatch"

/obj/item/clothing/mask/gas/sechailer/proc/dispatch(mob/user)
    var/area/A = get_area(src)

    // Проверка на кулдаун
    if(world.time < src.last_dispatch + src.dispatch_cooldown)
        to_chat(user, span_notice("Система Уведомления находится на перезарядке."))
        return FALSE
    var/list/options = list()
    for(var/option in list("69", "187", "404", "505", "996", "211"))  //Just hardcoded for now!
        options[option] = image(icon = 'icons/effects/aiming.dmi', icon_state = option)
    var/message = show_radial_menu(user, user, options)
    if(!message)
        return FALSE

    var/new_message
    switch(message)
        if("69")
            new_message = "69 (Акты Сексуального Характера)"
        if("187")
            new_message = "187 (Убийство)"
        if("404")
            new_message = "404 (Нарушитель)"
        if("505")
            new_message = "505 (Вооружённый Нарушитель)"
        if("996")
            new_message = "996 (Взрывчатка)"
        if("211")
            new_message = "211 (Проникновение/Ограбление)"

    if(src.radio)
        radio.talk_into(src, "Центр, Код [new_message], 10-20: [A], [A.x], [A.y], [A.z]. Офицеру [user] требуется поддержка.", src.radio_channel)
    src.last_dispatch = world.time
    for(var/atom/movable/hailer in GLOB.sechailers)
        if(hailer.loc && ismob(hailer.loc))
            playsound(hailer.loc, "sound/voice/dispatch_hailer.ogg", 100, FALSE)


// **** Security gas mask ****

/obj/item/clothing/mask/gas/sechailer
	name = "Security Gas Mask"
	desc = "Противогаз спецслужб стандартной комплектации со встроенным устройством Compli-o-Nator 3000. Проигрывает более десятка заранее записанных фраз. НЕ ВСКРЫВАЙТЕ ЭТО УСТРОЙСТВО."
	actions_types = list(/datum/action/item_action/halt, /datum/action/item_action/adjust, /datum/action/item_action/dispatch)
	icon_state = "sechailer"
	item_state = "sechailer"
	clothing_flags = BLOCK_GAS_SMOKE_EFFECT | ALLOWINTERNALS
	flags_inv = HIDEFACIALHAIR|HIDEFACE
	w_class = WEIGHT_CLASS_SMALL
	visor_flags = BLOCK_GAS_SMOKE_EFFECT | ALLOWINTERNALS
	visor_flags_inv = HIDEFACE
	flags_cover = MASKCOVERSMOUTH
	visor_flags_cover = MASKCOVERSMOUTH | MASKCOVERSEYES
	var/aggressiveness = 2
	var/cooldown_special
	var/recent_uses = 0
	var/broken_hailer = 0
	var/safety = TRUE
	var/obj/item/radio/radio //For engineering alerts.
	var/radio_key = /obj/item/encryptionkey/headset_sec
	var/radio_channel = "Security"
	var/dispatch_cooldown = 250
	var/last_dispatch = 0

/obj/item/clothing/mask/gas/sechailer/Initialize(mapload)
	. = ..()
	GLOB.sechailers += src
	radio = new(src)
	radio.keyslot = new radio_key
	radio.listening = FALSE
	radio.recalculateChannels()

/obj/item/clothing/mask/gas/sechailer/Destroy()
	QDEL_NULL(radio)
	GLOB.sechailers -= src
	. = ..()

/obj/item/clothing/mask/gas/sechailer/swat
	name = "\improper SWAT mask"
	desc = "Плотно прилегающая тактическая маска с особо агрессивным Compli-o-Nator 3000."
	actions_types = list(/datum/action/item_action/halt, /datum/action/item_action/dispatch)
	icon_state = "swat"
	item_state = "swat"
	aggressiveness = 3
	flags_inv = HIDEFACIALHAIR|HIDEFACE|HIDEEYES|HIDEEARS|HIDEHAIR
	flags_cover = MASKCOVERSMOUTH | MASKCOVERSEYES
	visor_flags_inv = 0

/obj/item/clothing/mask/gas/sechailer/swat/officer
	name = "\improper Officer SWAT mask"
	icon_state = "officermask"

/obj/item/clothing/mask/gas/sechailer/swat/hos
	name = "\improper HOS SWAT mask"
	icon_state = "hosmask"

/obj/item/clothing/mask/gas/sechailer/swat/blueshield
	name = "\improper Blueshield SWAT mask"
	icon_state = "blue_sechailer"

/obj/item/clothing/mask/gas/sechailer/cyborg
	name = "Security Hailer"
	desc = "Содержит набор заранее записанных сообщений, которые киборги могут использовать при задержании преступников."
	icon = 'icons/obj/device.dmi'
	icon_state = "taperecorder_idle"
	aggressiveness = 1 //Borgs are nicecurity!
	actions_types = list(/datum/action/item_action/halt, /datum/action/item_action/dispatch)

/obj/item/clothing/mask/gas/sechailer/screwdriver_act(mob/living/user, obj/item/I)
	if(..())
		return TRUE
	// BLUEMOON ADD - harm intent снимает модуль как device/hailer
	if(user.a_intent == INTENT_HARM)
		var/obj/item/device/hailer/H = new(get_turf(src))
		if(!safety)
			H.insults = rand(1,3)
		user.put_in_hands(H)
		broken_hailer = TRUE
		GLOB.sechailers -= src
		QDEL_NULL(radio)
		to_chat(user, span_notice("Вы выковыриваете Compli-o-Nator модуль из [src]."))
		return TRUE
	switch(aggressiveness)
		if(-1)
			to_chat(user, "<span class='notice'>You set the restrictor to the bottom position.</span>")
			aggressiveness = 0
		if(0)
			to_chat(user, "<span class='notice'>You set the restrictor to the top position.</span>")
			aggressiveness = -1
		if(1)
			to_chat(user, "<span class='notice'>You set the restrictor to the middle position.</span>")
			aggressiveness = 2
		if(2)
			to_chat(user, "<span class='notice'>You set the restrictor to the last position.</span>")
			aggressiveness = 3
		if(3)
			to_chat(user, "<span class='notice'>You set the restrictor to the first position.</span>")
			aggressiveness = 1
		if(4)
			to_chat(user, "<span class='danger'>You adjust the restrictor but nothing happens, probably because it's broken.</span>")
	return TRUE

/obj/item/clothing/mask/gas/sechailer/wirecutter_act(mob/living/user, obj/item/I)
	if(aggressiveness != 4)
		to_chat(user, "<span class='danger'>You broke the restrictor!</span>")
		aggressiveness = 4
	return TRUE

/obj/item/clothing/mask/gas/sechailer/ui_action_click(mob/user, action)
	if(istype(action, /datum/action/item_action/halt))
		halt()
	else if(istype(action, /datum/action/item_action/dispatch))
		dispatch(user)
	else
		adjustmask(user)

/obj/item/clothing/mask/gas/sechailer/attack_self()
	halt()

/obj/item/clothing/mask/gas/sechailer/emag_act(mob/user)
	. = ..()
	if(!safety)
		return
	safety = FALSE
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	to_chat(user, "<span class='warning'>You silently fry [src]'s vocal circuit with the cryptographic sequencer.</span>")
	return TRUE

/obj/item/clothing/mask/gas/sechailer/verb/halt()
	set category = "Object"
	set name = "HALT"
	set src in usr
	if(!isliving(usr))
		return
	if(!can_use(usr))
		return
	if(broken_hailer)
		to_chat(usr, "<span class='warning'>\The [src]'s hailing system is broken.</span>")
		return

	var/phrase = 0	//selects which phrase to use
	var/phrase_text = null
	var/phrase_sound = null


	if(cooldown < world.time - 30) // A cooldown, to stop people being jerks
		recent_uses++
		if(cooldown_special < world.time - 180) //A better cooldown that burns jerks
			recent_uses = initial(recent_uses)

		switch(recent_uses)
			if(3)
				to_chat(usr, "<span class='warning'>\The [src] is starting to heat up.</span>")
			if(4)
				to_chat(usr, "<span class='userdanger'>\The [src] is heating up dangerously from overuse!</span>")
			if(5) //overload
				broken_hailer = 1
				to_chat(usr, "<span class='userdanger'>\The [src]'s power modulator overloads and breaks.</span>")
				return

		switch(aggressiveness)		// checks if the user has unlocked the restricted phrases
			if(-1)
				phrase = rand(28,34) //Sub cop
			if(0)
				phrase = rand(19,27)  //Dom cop
			if(1)
				phrase = rand(1,5)	// set the upper limit as the phrase above the first 'bad cop' phrase, the mask will only play 'nice' phrases
			if(2)
				phrase = rand(1,11)	// default setting, set upper limit to last 'bad cop' phrase. Mask will play good cop and bad cop phrases
			if(3)
				phrase = rand(1,18)	// user has unlocked all phrases, set upper limit to last phrase. The mask will play all phrases
			if(4)
				phrase = rand(12,18)	// user has broke the restrictor, it will now only play shitcurity phrases
			if(999)
				phrase = rand(35,41)	// BLUEMOON CHANGE

		if(!safety)
			phrase_text = "ТЫ, СУКА, ОХУЕЛ? ДУМАЕШЬ САМЫЙ КРУТОЙ? Я ТЕБЕ СЕЙЧАС ЕБАЛО НАБЬЮ!!"
			phrase_sound = "emag"
		else

			switch(phrase)	//sets the properties of the chosen phrase
				if(1)
					phrase_text = "Не двигаться! Не двигаться!"
					phrase_sound = "halt"
				if(2)
					phrase_text = "Ни с места!"
					phrase_sound = "bobby"
				if(3)
					phrase_text = "Стоять! Стоять!"
					phrase_sound = "compliance"
				if(4)
					phrase_text = "Стоять на месте!"
					phrase_sound = "justice"
				if(5)
					phrase_text = "Давай, попробуй побежать. Безмозглый идиот."
					phrase_sound = "running"
				if(6)
					phrase_text = "Неудачник выбрал не тот день для нарушения закона."
					phrase_sound = "dontmove"
				if(7)
					phrase_text = "Сейчас узнаешь что такое настоящее правосудие, мудак."
					phrase_sound = "floor"
				if(8)
					phrase_text = "Стой! Преступное отродье."
					phrase_sound = "robocop"
				if(9)
					phrase_text = "Только двинешься и я оторву тебе бошку."
					phrase_sound = "god"
				if(10)
					phrase_text = "Укрыться от правосудия у тебя удастся только крышкой гроба."
					phrase_sound = "freeze"
				if(11)
					phrase_text = "Упал мордой в пол, тварь."
					phrase_sound = "imperial"
				if(12)
					phrase_text = "У вас есть только право закрыть свой пиздак нахуй."
					phrase_sound = "bash"
				if(13)
					phrase_text = "Виновен или невиновен - это лишь вопрос времени."
					phrase_sound = "harry"
				if(14)
					phrase_text = "Я - закон. Ты - убогое ничтожество."
					phrase_sound = "asshole"
				if(15)
					phrase_text = "Живым или мертвым - ты пиздуешь со мной."
					phrase_sound = "stfu"
				if(16)
					phrase_text = "Shut Up Crime!"
					phrase_sound = "shutup"
				if(17)
					phrase_text = "Face the wrath of the golden bolt."
					phrase_sound = "super"
				if(18)
					phrase_text = "Я. ЕСТЬ. ЗАКОН!"
					phrase_sound = "dredd"
				if(19)				// slut cop - dom
					phrase_text = "Твоя задница - моя!"
					phrase_sound = "ass"
				if(20) //Thank you Yappy for 19 & 20
					phrase_text = "Ваше согласие недействительно."
					phrase_sound = "consent"
				if(21)
					phrase_text = "Отъеби мои мозги, умоляю."
					phrase_sound = "brains"
				if(22)
					phrase_text = "Руки вверх, штаны вниз."
					phrase_sound = "pants"
				if(23)
					phrase_text = "Встань на колени и скажи: 'пожалуйста'."
					phrase_sound = "knees"
				if(24)
					phrase_text = "Пустое у меня тельце или нет, я кончу ради тебя!"
					phrase_sound = "empty"
				if(25) //Thank you Nata for 22-25
					phrase_text = "Лицом на землю, задницей вверх!"
					phrase_sound = "facedown"
				if(26)
					phrase_text = "Пожалуйста, займи на мне свою любимую позицию."
					phrase_sound = "fisto"
				if(27)
					phrase_text = "Ты пойдешь со мной, и тебе это понравится!"
					phrase_sound = "love"
				if(28)				// slut cop - sub
					phrase_text = "Пожалуйста, мне нужно больше!!"
					phrase_sound = "please"
				if(29)
					phrase_text = "Моё тело принадлежит тебе."
					phrase_sound = "body"
				if(30)
					phrase_text = "Я хороший питомец?"
					phrase_sound = "goodpet"
				if(31)
					phrase_text = "Я твоя вещь..."
					phrase_sound = "yours"
				if(32) //Thank you Kraxie for 31 & 32
					phrase_text = "Мастер..."
					phrase_sound = "master"
				if(33)
					phrase_text = "Я сделаю всё ради тебя..."
					phrase_sound = "anything"
				if(34)
					phrase_text = "Я живу, чтобы служить."
					phrase_sound = "serve"
				if(35) // BLUEMOON CHANGE start
					phrase_text = "Космодесантники, в атаку!"
					phrase_sound = "bluemoon_atack"
				if(36)
					phrase_text = "Очистить! Искоренить! Убить!"
					phrase_sound = "bluemoon_clean_purges"
				if(37)
					phrase_text = "Сдохни отброс!"
					phrase_sound = "bluemoon_die_scum"
				if(38)
					phrase_text = "За императора!"
					phrase_sound = "bluemoon_for_the_emperor"
				if(39)
					phrase_text = "Еретики."
					phrase_sound = "bluemoon_heretic"
				if(40)
					phrase_text = "Исколечить, убить, сжечь!"
					phrase_sound = "bluemoon_maim_kill_burn"
				if(41)
					phrase_text = "Смерть всем ксеносам."
					phrase_sound = "bluemoon_death_to_alien" // BLUEMOON CHANGE end

		if(aggressiveness <= 0)
			usr.audible_message("[usr]'s Slut-o-Nator: <font color=#D45592 size='2'><b>[phrase_text]</b></font>")
		else
			usr.audible_message("[usr]'s Compli-o-Nator: <font color='red' size='4'><b>[phrase_text]</b></font>")
		playsound(src.loc, "sound/voice/complionator/[phrase_sound].ogg", 100, 0, 4)
		cooldown = world.time
		cooldown_special = world.time

/obj/item/clothing/mask/gas/sechailer/swat/spacepol
	name = "spacepol mask"
	desc = "A close-fitting tactical mask created in cooperation with a certain megacorporation, comes with an especially aggressive Compli-o-nator 3000."
	icon_state = "spacepol"
	item_state = "spacepol"
	mutantrace_variation = STYLE_NO_ANTHRO_ICON
	flags_cover = MASKCOVERSMOUTH | MASKCOVERSEYES
	visor_flags_cover = MASKCOVERSMOUTH | MASKCOVERSEYES
