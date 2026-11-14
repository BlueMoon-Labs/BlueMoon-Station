/// HTML-хелперы чата принимают готовый HTML.

/// Секция с заголовком, при framed — самостоятельная карточка в рамке.
/proc/examine_box(title, content, framed = TRUE)
	if(!length(content))
		return ""
	var/html = "<div class='examine_title'>[title]</div>[content]"
	if(framed)
		return examine_block("<div class='examine_box'>[html]</div>")
	return html

/// Ассоциативная таблица: явный порядок необязателен, остальные строки идут после него.
/// records включает фиксированную ширину подписей и перенос длинных значений.
/proc/examine_table(list/rows, list/order = null, records = TRUE)
	if(!length(rows))
		return ""
	var/list/labels = order ? order.Copy() : list()
	for(var/label in rows)
		if(!(label in labels))
			labels += label
	var/list/html = list()
	for(var/label in labels)
		if(!(label in rows) || (!records && !rows[label]))
			continue
		html += "<tr><td>[label]</td><td>[rows[label]]</td></tr>"
	if(!length(html))
		return ""
	return "<table class='examine_table [records ? "examine_records" : "examine_equipment"]'>[html.Join("")]</table>"

/// Записи с разделителями. При пустом списке выводится empty_text.
/proc/examine_entries(list/entries, empty_text)
	if(!length(entries))
		return "<div class='examine_empty'>[empty_text]</div>"
	var/list/html = list()
	for(var/entry in entries)
		html += "<div>[entry]</div>"
	return "<div class='examine_entries'>[html.Join("")]</div>"

/// Особенности плашками; готовая HTML-разметка сохраняется.
/proc/examine_chips(traitstring)
	if(!length(traitstring))
		return ""
	if(findtext(traitstring, "<"))
		return traitstring
	var/list/chips = list()
	for(var/trait in splittext(traitstring, ", "))
		chips += "<span class='examine_chip'>[trait]</span>"
	return chips.Join(" ")

/// Короткий текст выводится без спойлера.
/proc/examine_spoiler(title, content, min_length = 0)
	if(!length(content))
		return ""
	if(length(content) <= min_length)
		return content
	return "<details class='examine_spoiler'><summary>[title]</summary><div>[content]</div></details>"
