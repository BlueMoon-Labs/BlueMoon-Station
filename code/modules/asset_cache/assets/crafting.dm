/**
 * Спрайты предметов для меню крафта.
 *
 * Раньше иконки ехали прямо в payload интерфейса base64-строками: 2.71 МБ из 3.03 МБ
 * статики меню, и одна и та же иконка стального листа переписывалась в JSON столько
 * раз, во скольких рецептах он встречается. Каждое открытие меню просило у 32-битного
 * DreamDaemon непрерывный многомегабайтный кусок - на нём процесс и умирал
 * (раунды 9941 и 9948, обвал ровно в tgui_window.dm:317).
 */
/datum/asset/spritesheet_batched/crafting
	name = "crafting"

/datum/asset/spritesheet_batched/crafting/create_spritesheets()
	// Один DMI обслуживает десятки предметов - разобранные наборы стейтов держим при
	// себе, чтобы не гонять icon_states() по кругу.
	var/list/states_by_file = list()
	var/list/seen = list()

	for(var/datum/crafting_recipe/recipe as anything in GLOB.crafting_recipes)
		insert_crafting_sprite(recipe.result, seen, states_by_file)
		for(var/requirement in recipe.reqs)
			insert_crafting_sprite(requirement, seen, states_by_file)
		for(var/catalyst in recipe.chem_catalysts)
			insert_crafting_sprite(catalyst, seen, states_by_file)
		for(var/tool in recipe.tools)
			insert_crafting_sprite(tool, seen, states_by_file)

/datum/asset/spritesheet_batched/crafting/proc/insert_crafting_sprite(path, list/seen, list/states_by_file)
	// В reqs и chem_catalysts лежат в том числе пути реагентов, а в tools - строки
	// поведения инструмента (TOOL_WELDER и прочие). Иконка есть только у атомов.
	if(!ispath(path, /atom))
		return

	var/sprite_id = crafting_sprite_id(path)
	if(seen[sprite_id])
		return
	seen[sprite_id] = TRUE

	var/atom/atom_path = path
	var/icon_file = initial(atom_path.icon)
	var/icon_state = initial(atom_path.icon_state)
	// IconForge читает только DMI, а у части атомов в icon лежит голый png.
	if(!icon_file || copytext("[icon_file]", -4) != ".dmi")
		return
	// Пустой или нестроковый стейт роняет разбор ЦЕЛОГО шарда, причём ошибка укажет
	// на позицию в JSON, а не на спрайт. Отсекаем здесь.
	if(!istext(icon_state) || !length(icon_state))
		return

	var/list/all_states = states_by_file["[icon_file]"]
	if(isnull(all_states))
		all_states = icon_states(icon_file)
		states_by_file["[icon_file]"] = all_states
	// Стейта нет в файле - на DM-пути icon2base64 отдавал пустую картинку, здесь такой
	// спрайт убил бы весь шард. Повторяем прежний исход: спрайта нет, лист есть.
	if(!(icon_state in all_states))
		return

	insert_icon(sprite_id, uni_icon(icon_file, icon_state, SOUTH))

/// Имя спрайта в листе крафта. Одно на путь, и DM с интерфейсом обязаны звать
/// именно его - иначе класс в разметке не сойдётся с классом в css.
/proc/crafting_sprite_id(path)
	// Ведущий слэш убираем: css-идентификатор с него начинаться не должен.
	return replacetext(copytext("[path]", 2), "/", "-")
