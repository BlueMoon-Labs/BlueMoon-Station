/// Проверки видимости и обработчики ссылок из осмотра человека.
//Helper procedure. Called by /mob/living/carbon/human/examine() and /mob/living/carbon/human/Topic() to determine HUD access to security and medical records.
/proc/hasHUD(mob/M, hudtype)
	if(istype(M, /mob/living/carbon/human))
		var/have_hudtypes = list()
		var/mob/living/carbon/human/H = M

		if(istype(H.glasses, /obj/item/clothing/glasses/hud))
			var/obj/item/clothing/glasses/hud/hudglasses = H.glasses
			if(hudglasses?.hud_type)
				have_hudtypes += hudglasses.hud_type

		var/obj/item/organ/cyberimp/eyes/hud/CIH = H.getorgan(/obj/item/organ/cyberimp/eyes/hud)
		if(CIH?.HUD_type)
			have_hudtypes += CIH.HUD_type
		var/obj/item/organ/cyberimp/brain/nif/implant = H.getorganslot(ORGAN_SLOT_BRAIN_NIF)
		for(var/datum/nifsoft/hud/program in implant?.loaded_nifsofts)
			if(program.active && program.hud_type)
				have_hudtypes += program.hud_type

		if((DATA_HUD_MEDICAL_ADVANCED in have_hudtypes) && !(DATA_HUD_MEDICAL_BASIC in have_hudtypes))
			have_hudtypes += DATA_HUD_MEDICAL_BASIC

		return (hudtype in have_hudtypes)

	else if(iscyborg(M) || isAI(M)) //Stand-in/Stopgap to prevent pAIs from freely altering records, pending a more advanced Records system
		return (hudtype in list(DATA_HUD_SECURITY_BASIC, DATA_HUD_SECURITY_ADVANCED, DATA_HUD_MEDICAL_ADVANCED))

	else if(isobserver(M))
		var/mob/dead/observer/O = M
		if(DATA_HUD_SECURITY_ADVANCED in O.datahuds)
			return (hudtype in list(DATA_HUD_SECURITY_BASIC, DATA_HUD_SECURITY_ADVANCED))

	return FALSE

/mob/living/carbon/human/proc/examine_naked_headshots(mob/user, unknown)
	if(!length(dna?.headshot_naked_links))
		return list()
	if((check_rights_for(user.client, R_ADMIN) && isobserver(user)) || (!unknown && can_show_naked_flavor()))
		return dna.headshot_naked_links.Copy()
	return list()
/// Можно ли показывать цель обнажённой, как в профиле персонажа.
/mob/living/carbon/human/proc/can_show_naked_flavor()
	if(force_naked_flavor)
		return TRUE
	var/list/clothings = list(wear_suit, w_uniform, belt, w_underwear, w_socks, w_shirt, wrists, wear_neck)
	for(var/obj/item/clothing/clothpiece in clothings)
		if(clothpiece.body_parts_covered & (GROIN | CHEST))
			return FALSE
	return TRUE

/// Есть ли у смотрящего медхуд. Условие вынесено из examine(), чтобы ссылка и Topic проверяли одно и то же.
/proc/has_medical_examine_hud(mob/user)
	if(!ishuman(user))
		return FALSE
	var/mob/living/carbon/human/H = user
	if(istype(H.glasses, /obj/item/clothing/glasses/hud/health))
		return TRUE
	return !isnull(H.getorgan(/obj/item/organ/cyberimp/eyes/hud/medical))

/mob/living/carbon/human/proc/examine_traits_denied(mob/user, mode)
	if(QDELETED(src) || !user?.client)
		return "Не удалось получить данные."
	switch(mode)
		if(EXAMINE_TRAITS_MODE_OBSERVER)
			if(!isobserver(user))
				return "Это доступно только наблюдателям."
			return null
		if(EXAMINE_TRAITS_MODE_MEDHUD)
			if(!has_medical_examine_hud(user))
				return "Для этого нужен медицинский визор."
			return examine_sight_denied(user)
	return "Неизвестный режим."

/// Ссылка на особенности для осмотра. Пустая строка: просмотреть невозможно или показывать нечего.
/proc/examine_traits_link(mob/living/carbon/human/target, mob/user, mode, label = "Показать")
	if(!istype(target) || target.examine_traits_denied(user, mode))
		return ""
	if(!length(target.get_trait_string(FALSE, mode == EXAMINE_TRAITS_MODE_MEDHUD, null)))
		return ""
	return "<a href='?src=[REF(target)];examine_traits=[mode]'>\[[label]\]</a>"

/mob/living/carbon/human/proc/examine_traits_topic(mob/user, mode)
	var/denied = examine_traits_denied(user, mode)
	if(denied)
		to_chat(user, span_warning(denied))
		return
	var/traitstring = get_trait_string(FALSE, mode == EXAMINE_TRAITS_MODE_MEDHUD, null)
	if(!length(traitstring))
		to_chat(user, span_notice("Особенностей не обнаружено."))
		return
	to_chat(user, examine_box("Особенности: [html_encode(examine_shown_name(user))]", "<div>[examine_chips(traitstring)]</div>"))

/// Может ли user сейчас разглядеть цель: в сознании, не слеп, цель в зоне видимости. Null: можно.
/// Наблюдатели проверку не проходят: они видят всё.
/mob/living/carbon/human/proc/examine_sight_denied(mob/user)
	if(user.stat != CONSCIOUS)
		return "Вы не в состоянии этого сделать."
	if(user.eye_blind || HAS_TRAIT(user, TRAIT_BLIND))
		return "Вы ничего не видите."
	if(!(src in view(user.client.view, user)))
		return "Цель вне зоны видимости."
	return null

/// Видимые аксессуары униформы
/proc/visible_uniform_accessories(obj/item/clothing/under/U)
	var/list/result = list()
	if(!istype(U) || !length(U.accessories_attached) || (U.flags_inv & HIDEACCESSORY))
		return result
	for(var/obj/item/clothing/accessory/acc in U.accessories_attached)
		if(acc.flags_inv & HIDEACCESSORY)
			continue
		result += acc
	return result

/// Текст отказа, если user не может работать с аксессуарами цели. Null: можно.
/mob/living/carbon/human/proc/examine_accessories_denied(mob/user)
	if(QDELETED(src) || !user?.client)
		return "Не удалось получить данные."
	if(!isobserver(user))
		var/sight_denied = examine_sight_denied(user)
		if(sight_denied)
			return sight_denied
	if(!istype(w_uniform, /obj/item/clothing/under) || (ITEM_SLOT_ICLOTHING in check_obscured_slots()))
		return "Форма сейчас не видна."
	return null

/// Строка аксессуара из get_examine_string().
/// Если строка почему-то не начинается с иконки, рендерим название.
/proc/examine_accessory_string(mob/living/carbon/human/owner, obj/item/clothing/accessory/acc, mob/user)
	var/icon_html = icon2html(acc, user)
	var/full_string = acc.get_examine_string(user)
	if(!length(icon_html) || findtext(full_string, icon_html) != 1)
		return full_string
	return "<a href='?src=[REF(owner)];examine_accessory=[REF(acc)]'>[icon_html]</a>[copytext(full_string, length(icon_html) + 1)]"

/// Список видимых аксессуаров отдельным блоком в чат, как examine more
/mob/living/carbon/human/proc/examine_accessories_topic(mob/user, accessory_ref)
	var/denied = examine_accessories_denied(user)
	if(denied)
		to_chat(user, span_warning(denied))
		return
	var/list/accessories = visible_uniform_accessories(w_uniform)
	if(accessory_ref)
		var/obj/item/clothing/accessory/acc = locate(accessory_ref)
		if(!istype(acc) || !(acc in accessories))
			to_chat(user, span_warning("Этот аксессуар больше не виден."))
			return
		user.examinate(acc)
		return
	if(!length(accessories))
		to_chat(user, span_notice("Аксессуаров не видно."))
		return
	var/list/rows = list()
	for(var/obj/item/clothing/accessory/acc as anything in accessories)
		rows += "[examine_accessory_string(src, acc, user)] <a href='?src=[REF(src)];examine_accessory=[REF(acc)]'>\[Осмотреть\]</a>"
	to_chat(user, examine_box("Аксессуары: [html_encode(examine_shown_name(user))]", "<div>[rows.Join("\n")]</div>"))
