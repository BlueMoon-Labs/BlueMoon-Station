/obj/item/genital_equipment/sounding //TODO probably fix this shit as well
	name 				= "уретральный стержень"
	desc 				= "Не глупи, засовывай в свой ствол!"
	icon 				= 'modular_splurt/icons/obj/sounding.dmi'
	throwforce			= 0
	icon_state 			= "sounding_wrapped"
	var/unwrapped		= 0
	w_class 			= WEIGHT_CLASS_TINY
	genital_slot 		= ORGAN_SLOT_PENIS

/obj/item/genital_equipment/sounding/attack_self(mob/user)
	if(!istype(user))
		return
	if(isliving(user))
		if(unwrapped == 0)
			icon_state 	= "sounding_rod"
			unwrapped = 1
			to_chat(user, "<span class='notice'>Ты распаковываешь стержень.</span>")
			playsound(user, 'sound/items/poster_ripped.ogg', 50, 1, -1)
			return

/obj/item/genital_equipment/sounding/item_inserting(datum/source, obj/item/organ/genital/G, mob/user)
	. = TRUE

	if(!(G.owner.client?.prefs?.erppref == "Yes"))
		to_chat(user, span_warning("[G.owner] не хочет этого!"))
		return FALSE

	if(!unwrapped)
		to_chat(user, span_notice("Сначала нужно достать из упаковки!"))
		return FALSE

	if(!G.owner.has_penis() == HAS_EXPOSED_GENITAL)
		to_chat(user, span_notice("Не можешь найти, куда вставить стержень!"))
		return

	if(locate(src.type) in G.contents)
		if(user == G.owner)
			to_chat(user, span_notice("В твоём [G] уже есть стержень!"))
		else
			to_chat(user, span_notice("У <b>[G.owner]</b> в [G] уже есть стержень!"))
		return FALSE

	if(user == G.owner)
		G.owner.visible_message(span_warning("<b>[user]</b> пытается вставить стержень внутрь себя!"),\
						span_warning("Ты пытаешься вставить стержень внутрь себя!"))
	else
		G.owner.visible_message(span_warning("<b>[user]</b> пытается вставить стержень внутрь <b>[G.owner]</b>!"),\
						span_warning("<b>[user]</b> пытается вставить стержень внутрь тебя!"))

	if(!do_mob(user, G.owner, 4 SECONDS))
		return FALSE

/obj/item/genital_equipment/sounding/item_inserted(datum/source, obj/item/organ/genital/G, mob/user)
	. = TRUE
	playsound(G.owner, 'modular_sand/sound/lewd/champ_fingering.ogg', 50, 1, -1)
	to_chat(G.owner, span_userlove("Ваш половой член кажется заполненным и растянутым!"))



// Just Ctrl+C -> Ctrl+V
/obj/item/genital_equipment/urethral_plug
	name 				= "уретральная пробка"
	desc 				= "Заткни свой фонтанчик!"
	icon 				= 'modular_splurt/icons/obj/sounding.dmi'
	throwforce			= 0
	icon_state 			= "urethral_plug_wrapped"
	var/unwrapped		= 0
	w_class 			= WEIGHT_CLASS_TINY
	genital_slot 		= ORGAN_SLOT_VAGINA

/obj/item/genital_equipment/urethral_plug/attack_self(mob/user)
	if(!istype(user))
		return
	if(isliving(user))
		if(unwrapped == 0)
			icon_state 	= "urethral_plug"
			unwrapped = 1
			to_chat(user, "<span class='notice'>Ты распаковываешь пробку.</span>")
			playsound(user, 'sound/items/poster_ripped.ogg', 50, 1, -1)
			return

/obj/item/genital_equipment/urethral_plug/item_inserting(datum/source, obj/item/organ/genital/G, mob/user)
	. = TRUE

	if(!(G.owner.client?.prefs?.erppref == "Yes"))
		to_chat(user, span_warning("[G.owner] не хочет этого!"))
		return FALSE

	if(!unwrapped)
		to_chat(user, span_notice("Сначала нужно достать из упаковки!"))
		return FALSE

	if(!G.owner.has_vagina() == HAS_EXPOSED_GENITAL)
		to_chat(user, span_notice("Не можешь найти, куда вставить пробку!"))
		return FALSE

	if(locate(src.type) in G.contents)
		if(user == G.owner)
			to_chat(user, span_notice("В твоей [G] уже есть пробка!"))
		else
			to_chat(user, span_notice("У <b>[G.owner]</b> в [G] уже есть пробка!"))
		return FALSE

	if(user == G.owner)
		G.owner.visible_message(span_warning("\<b>[user]</b> пытается вставить пробку внутрь себя!"),\
						span_warning("Ты пытаешься вставить пробку внутрь себя!"))
	else
		G.owner.visible_message(span_warning("<b>[user]</b> пытается вставить пробку внутрь <b>[G.owner]</b>!"),\
						span_warning("<b>[user]</b> пытается вставить пробку внутрь тебя!"))

	if(!do_mob(user, G.owner, 4 SECONDS))
		return FALSE

/obj/item/genital_equipment/urethral_plug/item_inserted(datum/source, obj/item/organ/genital/G, mob/user)
	. = TRUE
	playsound(G.owner, 'modular_sand/sound/lewd/champ_fingering.ogg', 50, 1, -1)
	to_chat(G.owner, span_userlove("Ваша уретра кажется заполненной и растянутой!"))
