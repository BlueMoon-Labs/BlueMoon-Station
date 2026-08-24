/datum/asset/spritesheet_batched/vending
	name = "vending"
	// GLOB.vending_products наполняют сами вендоматы при инициализации, и порядок
	// там зависит от порядка инициализации мира: набор товаров тот же, а шарды
	// каждый раунд разные. Без сортировки лист пересобирается всегда.
	sort_sprites = TRUE

/datum/asset/spritesheet_batched/vending/create_spritesheets()
	// Один и тот же DMI обслуживает сотни товаров - разобранные наборы стейтов
	// держим при себе, чтобы не гонять icon_states() по кругу.
	var/list/states_by_file = list()

	for(var/atom/item as anything in GLOB.vending_products)
		if(!ispath(item, /atom))
			continue

		//if (initial(item.greyscale_colors) && initial(item.greyscale_config))
		//	icon_file = SSgreyscale.GetColoredIconByType(initial(item.greyscale_config), initial(item.greyscale_colors))
		//else
		var/icon_file = initial(item.icon)
		var/icon_state = initial(item.icon_state)

		// Апстрим здесь выбрасывает всё, у чего нет GAGS или цвета, и добирает
		// остальное компонентом DMIcon в tgui. DMIcon у нас нет - витрина живёт
		// только на спрайтшите, поэтому в лист идёт каждый товар.

		// Стейта нет в файле - IconForge на таком спрайте роняет генерацию всего
		// листа, а DM-путь такой спрайт молча выбрасывал (Insert() возвращал FALSE
		// на пустой иконке). Повторяем прежний исход: спрайта нет, лист есть.
		// Проверка безусловная именно поэтому: под UNIT_TESTS её было бы мало,
		// сломанный стейт дожил бы до прода и убил там весь ассет.
		var/list/all_states = states_by_file["[icon_file]"]
		if(isnull(all_states))
			all_states = icon_file ? icon_states(icon_file) : list()
			states_by_file["[icon_file]"] = all_states
		if(!(icon_state in all_states))
			continue

		var/imgid = replacetext(replacetext("[item]", "/obj/item/", ""), "/", "-")

		var/datum/universal_icon/sprite = uni_icon(icon_file, icon_state, SOUTH)
		// Цветом атома может быть матрица, а не строка - на DM-пути такой предмет
		// просто вставлялся без окраски, здесь же нестроковый цвет уронил бы лист.
		var/item_color = initial(item.color)
		if(istext(item_color) && uppertext(item_color) != "#FFFFFF")
			sprite.blend_color(item_color, ICON_MULTIPLY)

		insert_icon(imgid, sprite)
