/client/verb/show_station_minimap()
	set category = "OOC"
	set name = "Show Station Minimap"
	set desc = "Показывает интерактивную миникарту текущей станции."

	if(!CONFIG_GET(flag/minimaps_enabled))
		to_chat(usr, span_boldwarning("Генерация миникарт отключена в настройках сервера."))
		return
	if(!SSminimaps.station_minimap)
		to_chat(usr, span_boldwarning("Миникарта ещё создаётся, подождите!"))
		return
	SSminimaps.station_minimap.show(mob)
