/obj/item/clothing/mask
	name = "mask"
	icon = 'icons/obj/clothing/masks.dmi'
	body_parts_covered = HEAD
	slot_flags = ITEM_SLOT_MASK
	strip_delay = 40
	equip_delay_other = 40
	var/modifies_speech = FALSE
	var/mask_adjusted = 0
	var/adjusted_flags = null
	var/firstpickup = TRUE
	var/pickupsound = TRUE
	var/datum/beepsky_fashion/beepsky_fashion //the associated datum for applying this to a secbot
	var/face_hidden = FALSE
	var/face_hide_capable = FALSE
	var/face_base_flags = null
	// BLUEMOON ADD - hailer in any mask (using SecTech device/hailer)
	var/has_hailer = FALSE
	var/hailer_aggressiveness = 2
	var/hailer_cooldown = 0
	var/hailer_cooldown_special = 0
	var/hailer_recent_uses = 0
	var/hailer_broken = FALSE
	var/hailer_safety = TRUE
	var/obj/item/radio/hailer_radio
	var/hailer_radio_key = /obj/item/encryptionkey/headset_sec
	var/hailer_radio_channel = "Security"
	var/hailer_dispatch_cooldown = 250
	var/hailer_last_dispatch = 0

/obj/item/clothing/mask/attack_self(mob/user)
	if(has_hailer)
		hailer_halt(user)
		return
	if((clothing_flags & VOICEBOX_TOGGLABLE))
		(clothing_flags ^= VOICEBOX_DISABLED)
		var/status = !(clothing_flags & VOICEBOX_DISABLED)
		to_chat(user, "<span class='notice'>You turn the voice box in [src] [status ? "on" : "off"].</span>")

/obj/item/clothing/mask/equipped(mob/M, slot)
	. = ..()
	if (slot == ITEM_SLOT_MASK && modifies_speech)
		RegisterSignal(M, COMSIG_MOB_SAY, PROC_REF(handle_speech))
	else
		UnregisterSignal(M, COMSIG_MOB_SAY)

/obj/item/clothing/mask/dropped(mob/M)
	. = ..()
	UnregisterSignal(M, COMSIG_MOB_SAY)

/obj/item/clothing/mask/proc/handle_speech()

/obj/item/clothing/mask/worn_overlays(isinhands = FALSE, icon_file, used_state, style_flags = NONE)
	. = ..()
	if(!isinhands)
		if(body_parts_covered & HEAD)
			if(damaged_clothes)
				. += mutable_appearance('icons/effects/item_damage.dmi', "damagedmask")
			if(blood_DNA)
				. += mutable_appearance('icons/effects/blood.dmi', "maskblood", color = blood_DNA_to_color(), blend_mode = blood_DNA_to_blend())

/obj/item/clothing/mask/update_clothes_damaged_state()
	..()
	if(ismob(loc))
		var/mob/M = loc
		M.update_inv_wear_mask()

/**
  * Proc that moves gas/breath masks out of the way, disabling them and allowing pill/food consumption
  * The flavor_details variable is for masks that use this function only to toggle HIDEFACE for identity.
  */
/obj/item/clothing/mask/proc/adjustmask(mob/living/user, just_flavor = FALSE)
	if(user && user.incapacitated())
		return FALSE
	if(src.reinforced)
		to_chat(user, "<span class='warning'>Набор бронепластин сделал [src] слишком плотным, чтобы изменить его стиль ношения.</span>")
		return FALSE
	mask_adjusted = !mask_adjusted
	if(!mask_adjusted)
		if(!just_flavor)
			src.icon_state = initial(icon_state)
			gas_transfer_coefficient = initial(gas_transfer_coefficient)
			permeability_coefficient = initial(permeability_coefficient)
			slot_flags = initial(slot_flags)
			flags_cover |= visor_flags_cover
			clothing_flags |= visor_flags
		flags_inv |= visor_flags_inv
	else
		if(!just_flavor)
			icon_state += "_up"
			gas_transfer_coefficient = null
			permeability_coefficient = null
			clothing_flags &= ~visor_flags
			flags_cover &= ~visor_flags_cover
			if(adjusted_flags)
				slot_flags = adjusted_flags
		flags_inv &= ~visor_flags_inv
	if(user)
		if(!just_flavor)
			to_chat(user, "<span class='notice'>You push \the [src] [mask_adjusted ? "out of the way" : "back into place"].</span>")
			user.wear_mask_update(src, toggle_off = mask_adjusted)
			user.update_action_buttons_icon() //when mask is adjusted out, we update all buttons icon so the user's potential internal tank correctly shows as off.
		else
			to_chat(usr, "<span class='notice'>You adjust [src], it will now [mask_adjusted ? "not" : ""] obscure your identity while worn.</span>")
	return TRUE

/obj/item/clothing/mask/Initialize(mapload)
	. = ..()
	face_base_flags = flags_inv
	face_hide_capable = (flags_inv & HIDEFACE) ? TRUE : FALSE
	face_hidden = face_hide_capable // по умолчанию — как задумано маской (лицо скрыто)
	if(face_hide_capable)
		register_context()

/obj/item/clothing/mask/examine(mob/user)
	. = ..()
	if(face_hide_capable)
		. += span_notice("Alt-клик по маске — [face_hidden ? "показать" : "скрыть"] лицо/описание персонажа (сейчас: [face_hidden ? "скрыто" : "видно"]).")
	if(has_hailer)
		. += span_notice("В маску установлен Compli-o-Nator модуль (агрессивность [hailer_aggressiveness]). Отвёртка — снять модуль.")
	else
		. += span_notice("В эту маску можно установить hailer-модуль из СБТеха (используй hailer на маске).")

/obj/item/clothing/mask/proc/toggle_face_hiding(mob/user)
	if(isnull(face_base_flags))
		face_base_flags = initial(flags_inv)
		face_hide_capable = (face_base_flags & HIDEFACE) ? TRUE : FALSE
	if(!face_hide_capable)
		return
	face_hidden = !face_hidden
	// Только HIDEFACE тогглим, остальное (HIDEEARS/HIDEHAIR/HIDEEYES) не трогаем
	if(face_hidden)
		flags_inv |= HIDEFACE
	else
		flags_inv &= ~HIDEFACE
	if(isliving(loc))
		var/mob/living/L = loc
		L.update_inv_wear_mask()
		// BLUEMOON FIX: мгновенное обновление имени/описания без переодевания
		if(ishuman(L))
			var/mob/living/carbon/human/H = L
			H.name = H.get_visible_name()
			H.sec_hud_set_ID()
			H.sec_hud_set_security_status()
			if(H.profile)
				SStgui.update_uis(H.profile)
	if(user)
		to_chat(user, span_notice("Маска теперь [face_hidden ? "" : "не "]будет скрывать ваше лицо и описание персонажа."))

/obj/item/clothing/mask/AltClick(mob/user)
	if(face_hide_capable)
		if(!user.canUseTopic(src, BE_CLOSE))
			return ..()
		toggle_face_hiding(user)
		return TRUE
	return ..()

/obj/item/clothing/mask/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()
	if(!face_hide_capable)
		return
	if(!((item_flags & IN_INVENTORY) || loc == user))
		return
	LAZYSET(context[SCREENTIP_CONTEXT_ALT_LMB], INTENT_ANY, face_hidden ? "Показать лицо" : "Скрыть лицо")
	return CONTEXTUAL_SCREENTIP_SET

// BLUEMOON ADD - hailer in any mask via SecTech device/hailer
/obj/item/clothing/mask/Destroy()
	if(has_hailer)
		GLOB.sechailers -= src
		QDEL_NULL(hailer_radio)
	return ..()

/obj/item/clothing/mask/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/device/hailer) && !has_hailer && !istype(src, /obj/item/clothing/mask/gas/sechailer))
		var/obj/item/device/hailer/H = I
		if(!user.transferItemToLoc(H, src) && !user.dropItemToGround(H))
			return ..()
		// переносим состояние эмага: если hailer взломан (insults не null), то safety = FALSE
		has_hailer = TRUE
		hailer_aggressiveness = 2
		hailer_safety = isnull(H.insults) ? TRUE : FALSE
		qdel(H)
		hailer_radio = new(src)
		hailer_radio.keyslot = new hailer_radio_key
		hailer_radio.listening = FALSE
		hailer_radio.recalculateChannels()
		GLOB.sechailers += src
		var/datum/action/item_action/halt/HA = new(src)
		var/datum/action/item_action/dispatch/DA = new(src)
		if(ismob(loc))
			var/mob/M = loc
			HA.Grant(M)
			DA.Grant(M)
		else if(ismob(user))
			HA.Grant(user)
			DA.Grant(user)
		to_chat(user, span_notice("Вы устанавливаете hailer-модуль в [src]. Отвёртка — снять модуль."))
		if(ismob(loc))
			var/mob/living/L = loc
			L.update_inv_wear_mask()
		return TRUE
	return ..()

/obj/item/clothing/mask/screwdriver_act(mob/living/user, obj/item/I)
	if(has_hailer)
		var/obj/item/device/hailer/H = new(get_turf(src))
		// переносим состояние взлома
		if(!hailer_safety)
			H.insults = rand(1,3)
		user.put_in_hands(H)
		has_hailer = FALSE
		hailer_broken = FALSE
		GLOB.sechailers -= src
		QDEL_NULL(hailer_radio)
		for(var/datum/action/A in actions)
			if(istype(A, /datum/action/item_action/halt) || istype(A, /datum/action/item_action/dispatch))
				qdel(A)
		to_chat(user, span_notice("Вы снимаете hailer-модуль с [src]."))
		if(ismob(loc))
			var/mob/living/L = loc
			L.update_inv_wear_mask()
		return TRUE
	return ..()

/obj/item/clothing/mask/emag_act(mob/user)
	if(has_hailer && hailer_safety)
		hailer_safety = FALSE
		to_chat(user, span_warning("Вы взламываете vocal circuit [src] эмагом!"))
		log_admin("[key_name(user)] emagged hailer mask [src] at [AREACOORD(src)]")
		return TRUE
	. = ..()

/obj/item/clothing/mask/ui_action_click(mob/user, action)
	if(has_hailer)
		if(istype(action, /datum/action/item_action/halt))
			hailer_halt(user)
			return
		if(istype(action, /datum/action/item_action/dispatch))
			hailer_dispatch(user)
			return
	return ..()

/obj/item/clothing/mask/proc/hailer_halt(mob/user)
	if(!has_hailer || !can_use(user))
		return
	if(hailer_broken)
		to_chat(user, span_warning("Hailing system is broken."))
		return
	var/phrase = 0
	var/phrase_text = null
	var/phrase_sound = null
	if(hailer_cooldown < world.time - 30)
		hailer_recent_uses++
		if(hailer_cooldown_special < world.time - 180)
			hailer_recent_uses = initial(hailer_recent_uses)
		switch(hailer_recent_uses)
			if(3)
				to_chat(user, span_warning("\The [src] is starting to heat up."))
			if(4)
				to_chat(user, span_userdanger("\The [src] is heating up dangerously from overuse!"))
			if(5)
				hailer_broken = TRUE
				to_chat(user, span_userdanger("\The [src]'s power modulator overloads and breaks."))
				return
		switch(hailer_aggressiveness)
			if(-1)
				phrase = rand(28,34)
			if(0)
				phrase = rand(19,27)
			if(1)
				phrase = rand(1,5)
			if(2)
				phrase = rand(1,11)
			if(3)
				phrase = rand(1,18)
			if(4)
				phrase = rand(12,18)
			if(999)
				phrase = rand(35,41)
		if(!hailer_safety)
			phrase_text = "ТЫ, СУКА, ОХУЕЛ? ДУМАЕШЬ САМЫЙ КРУТОЙ? Я ТЕБЕ СЕЙЧАС ЕБАЛО НАБЬЮ!!"
			phrase_sound = "emag"
		else
			switch(phrase)
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
				if(19)
					phrase_text = "Твоя задница - моя!"
					phrase_sound = "ass"
				if(20)
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
				if(25)
					phrase_text = "Лицом на землю, задницей вверх!"
					phrase_sound = "facedown"
				if(26)
					phrase_text = "Пожалуйста, займи на мне свою любимую позицию."
					phrase_sound = "fisto"
				if(27)
					phrase_text = "Ты пойдешь со мной, и тебе это понравится!"
					phrase_sound = "love"
				if(28)
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
				if(32)
					phrase_text = "Мастер..."
					phrase_sound = "master"
				if(33)
					phrase_text = "Я сделаю всё ради тебя..."
					phrase_sound = "anything"
				if(34)
					phrase_text = "Я живу, чтобы служить."
					phrase_sound = "serve"
				if(35)
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
					phrase_sound = "bluemoon_death_to_alien"
		if(hailer_aggressiveness <= 0)
			user.audible_message("[user]'s Slut-o-Nator: <font color=#D45592 size='2'><b>[phrase_text]</b></font>")
		else
			user.audible_message("[user]'s Compli-o-Nator: <font color='red' size='4'><b>[phrase_text]</b></font>")
		playsound(loc, "sound/voice/complionator/[phrase_sound].ogg", 100, 0, 4)
		hailer_cooldown = world.time
		hailer_cooldown_special = world.time

/obj/item/clothing/mask/proc/hailer_dispatch(mob/user)
	if(!has_hailer)
		return FALSE
	var/area/A = get_area(src)
	if(world.time < hailer_last_dispatch + hailer_dispatch_cooldown)
		to_chat(user, span_notice("Система Уведомления на перезарядке."))
		return FALSE
	var/list/options = list()
	for(var/option in list("69", "187", "404", "505", "996", "211"))
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
	if(hailer_radio)
		hailer_radio.talk_into(src, "Центр, Код [new_message], 10-20: [A], [A.x], [A.y], [A.z]. Офицеру [user] требуется поддержка.", hailer_radio_channel)
	hailer_last_dispatch = world.time
	for(var/atom/movable/hailer in GLOB.sechailers)
		if(hailer.loc && ismob(hailer.loc))
			playsound(hailer.loc, "sound/voice/dispatch_hailer.ogg", 100, FALSE)
	return TRUE
