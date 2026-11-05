/// Представление карточки человека. Данные и права доступа проверяются вызывающей стороной.
/proc/examine_card(name_html, race_html, height_cm, profile_link, list/headshots, list/naked_headshots, flavor_text, placeholder_html = "")
	var/portrait_cell = length(placeholder_html) ? "<td class='examine_portrait_cell'>[placeholder_html]</td>" : ""
	var/thumbs = ""
	var/normal_count = 0
	for(var/link in headshots)
		var/shot_html = examine_headshot(link, normal_count ? "examine_thumb" : "examine_portrait")
		if(!length(shot_html))
			continue
		if(!normal_count)
			portrait_cell = "<td class='examine_portrait_cell'>[shot_html]</td>"
		else
			thumbs += "[shot_html] "
		normal_count++
		if(normal_count >= 1 + EXAMINE_UI_THUMBS_MAX)
			break
	var/naked_count = 0
	for(var/link in naked_headshots)
		var/shot_html = examine_headshot(link, "examine_thumb")
		if(!length(shot_html))
			continue
		thumbs += "[shot_html] "
		naked_count++
		if(naked_count >= EXAMINE_UI_NAKED_THUMBS_MAX)
			break
	var/meta = "Рост: ≈[height_cm] см · [profile_link]"
	var/without_headshots = !length(portrait_cell) && !naked_count
	var/card_class = without_headshots ? "examine_card examine_card_no_headshots" : "examine_card"
	var/flavor_html = examine_flavor_preview(flavor_text, without_headshots ? 66 : 44)
	var/thumbs_html = length(thumbs) ? "<div class='examine_thumbs'>[thumbs]</div>" : ""
	var/flavor_block = length(flavor_html) ? "<div class='examine_flavor'>[flavor_html]</div>" : ""
	return "<table class='[card_class]'><tr>[portrait_cell]<td class='examine_card_content'><div class='examine_name'>[name_html]</div><div>[race_html]</div><div class='examine_meta'>[meta]</div>[thumbs_html][flavor_block]</td></tr></table>"

/// Порядок экипировки человека, общая разметка строится через examine_table().
/proc/examine_equipment(list/equip_slots)
	if(!length(equip_slots))
		return ""
	// Порядок отображения подобран специально
	var/static/list/slot_order = list(
		"На голове", "На лице", "Глаза",
		"На шее", "Левое ухо", "Правое ухо",
		"ID-карта", "На теле", "Бельё", "Рубашка",
		"Поверх тела", "&#8627; В слоте", // Кодовая крякозябра - стрелочка
		"На запястьях", "На руках",
		"На спине", "На поясе",
		"Обувь", "Носки")
	return examine_table(equip_slots, slot_order, FALSE)

/// Только ссылки на JPEG/PNG. Пропущенное медиа не занимает место в карточке.
/proc/examine_headshot(link, css_class)
	if(!link)
		return ""
	var/static/image_regex = regex("^https?://\[^?#]*\\.(jpg|jpeg|png)(\[?#]|$)", "i")
	if(!findtext(link, image_regex))
		return ""
	var/safe_link = html_encode(link)
	return "<img class='[css_class]' src='[safe_link]' referrerpolicy='no-referrer'>"

/// Краткий флавор карточки без разрыва HTML-сущностей при обрезке.
/proc/examine_flavor_preview(flavor, max_length = 44)
	if(!length(flavor))
		return ""
	// В хранилище текст уже закодирован (&#39; и т.п.): декодируем до обрезки, чтобы не порвать сущность, и кодируем обратно
	flavor = trim(replacetext(html_decode(flavor), "\n", " "))
	if(!length(flavor))
		return ""
	var/preview = copytext_char(flavor, 1, max_length + 1)
	if(length_char(flavor) > max_length)
		preview += "..."
	return span_notice(html_encode(preview))
