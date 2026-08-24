//Vars that will not be copied when using /DuplicateObject
//signal_procs/active_timers: шальная копия рождает "регистрации", которых никто
//не делал (подвисшие ключи-датумы), а Destroy клона гасит таймеры оригинала.
//important_recursive_contents/spatial_grid_key/client_mobs_in_contents: клон
//объявил бы себя держателем чужого содержимого и травил ячейки спатиал-грида
//component_parts/debris/actions: списки чужих датумов. Копия списка мелкая, поэтому клон
//получал ссылки на детали, обломки и экшены оригинала, а его QDEL_LIST в Destroy убивал их
//вместе с собой - оригинал оставался единственным держателем трупа и уходил в харддел.
//Свои экшены клон и так создаёт в Initialize по actions_types, копия их только затирала.
//Общий случай шире этих трёх: цикл ниже проверяет islist() РАНЬШЕ istype(/datum), поэтому
//отдельная ссылка на датум отсеивается, а список таких же ссылок - нет
GLOBAL_LIST_INIT(duplicate_forbidden_vars,list(
	"tag", "datum_components", "area", "type", "loc", "locs", "vars", "parent", "parent_type", "verbs", "ckey", "key",
	"power_supply", "contents", "reagents", "stat", "x", "y", "z", "group", "atmos_adjacent_turfs", "comp_lookup",
	"pixloc", "signal_procs", "signal_enabled", "active_timers", "important_recursive_contents", "spatial_grid_key",
	"client_mobs_in_contents", "component_parts", "debris", "actions"
	))

GLOBAL_LIST_INIT(duplicate_forbidden_vars_by_type, typecacheof_assoc_list(list(
	/obj/item/gun/energy = "ammo_type"
	)))

//Дополнительный запрет для копирования ВАРОВ ТУРФА: в отличие от DuplicateObject
//турф не создаётся заново, а перекрашивается через ChangeTurf, и слепое присваивание
//утаскивало на приёмник ещё и состояние освещения шаблона:
//lc_* - углы шаблона с его координатами. Источник света рядом с копией брал их из
//соседнего турфа и лез в таблицу затухания по смещению в десятки тайлов
//("list index out of bounds" в LUM_FALLOFF, 166 рантаймов за один ресет тандердома).
//lighting_object/lighting_corners_initialised - настоящий оверлей приёмника терялся
//без qdel и уходил в харддел, а флаг инициализации врал про наличие четырёх углов.
//light/light_sources - источники, принадлежащие атомам шаблона.
//has_opaque_atom/shadow_weight_sum/cached_lumcount/dynamic_lumcount/luminosity -
//производные величины, их пересчитывает сам ChangeTurf.
GLOBAL_LIST_INIT(turf_copy_forbidden_vars, list(
	"light", "light_sources", "lighting_object", "lighting_corners_initialised",
	"lc_topleft", "lc_topright", "lc_bottomleft", "lc_bottomright",
	"has_opaque_atom", "shadow_weight_sum", "cached_lumcount", "dynamic_lumcount",
	"luminosity"
	))

/proc/DuplicateObject(atom/original, perfectcopy = TRUE, sameloc = FALSE, atom/newloc = null, nerf = FALSE, holoitem=FALSE)
	RETURN_TYPE(original.type)
	if(!original)
		return
	var/atom/O

	if(sameloc)
		O = new original.type(original.loc)
	else
		O = new original.type(newloc)

	if(perfectcopy && O && original)
		for(var/V in original.vars - GLOB.duplicate_forbidden_vars - GLOB.duplicate_forbidden_vars_by_type[O.type])
			if(islist(original.vars[V]))
				var/list/L = original.vars[V]
				O.vars[V] = L.Copy()
			else if(istype(original.vars[V], /datum))
				continue	// this would reference the original's object, that will break when it is used or deleted.
			else
				O.vars[V] = original.vars[V]

	if(isobj(O))
		var/obj/N = O
		if(holoitem)
			N.resistance_flags = LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF // holoitems do not burn

		if(nerf && isitem(O))
			var/obj/item/I = O
			I.damtype = STAMINA // thou shalt not

		N.update_icon()
		if(ismachinery(O))
			var/obj/machinery/M = O
			M.power_change()

	if(holoitem)
		O.flags_1 |= HOLOGRAM_1
	return O


/area/proc/copy_contents_to(var/area/A , var/platingRequired = 0, var/nerf_weapons = 0 )
	//Takes: Area. Optional: If it should copy to areas that don't have plating
	//Returns: Nothing.
	//Notes: Attempts to move the contents of one area to another area.
	//       Movement based on lower left corner. Tiles that do not fit
	//		 into the new area will not be moved.

	if(!A || !src)
		return FALSE

	var/list/turfs_src = get_area_turfs(src.type)
	var/list/turfs_trg = get_area_turfs(A.type)

	var/src_min_x = 99999
	var/src_min_y = 99999
	var/src_max_x = 0
	var/src_max_y = 0
	var/list/refined_src = new/list()

	for (var/turf/T in turfs_src)
		src_min_x = min(src_min_x,T.x)
		src_min_y = min(src_min_y,T.y)
		src_max_x = max(src_max_x,T.x)
		src_max_y = max(src_max_y,T.y)
	for (var/turf/T in turfs_src)
		refined_src[T] = "[T.x - src_min_x].[T.y - src_min_y]"

	var/trg_min_x = 99999
	var/trg_min_y = 99999
	var/trg_max_x = 0
	var/trg_max_y = 0
	var/list/refined_trg = new/list()

	for (var/turf/T in turfs_trg)
		trg_min_x = min(trg_min_x,T.x)
		trg_min_y = min(trg_min_y,T.y)
		trg_max_x = max(trg_max_x,T.x)
		trg_max_y = max(trg_max_y,T.y)

	var/diff_x = round(((src_max_x - src_min_x) - (trg_max_x - trg_min_x))/2)
	var/diff_y = round(((src_max_y - src_min_y) - (trg_max_y - trg_min_y))/2)
	for (var/turf/T in turfs_trg)
		refined_trg["[T.x - trg_min_x + diff_x].[T.y - trg_min_y + diff_y]"] = T

	var/list/toupdate = new/list()

	var/copiedobjs = list()

	for (var/turf/T in refined_src)
		var/coordstring = refined_src[T]
		var/turf/B = refined_trg[coordstring]
		if(!istype(B))
			continue

		if(platingRequired)
			if(isspaceturf(B))
				continue

		var/old_dir1 = T.dir
		var/old_icon_state1 = T.icon_state
		var/old_icon1 = T.icon

		B = B.ChangeTurf(T.type)
		B.setDir(old_dir1)
		B.icon = old_icon1
		B.icon_state = old_icon_state1

		for(var/obj/O in T)
			// Proximity checkers are spawned by proximity_monitor datums; copying them orphans them (no monitor ref).
			if(istype(O, /obj/effect/abstract/proximity_checker))
				continue
			var/obj/O2 = DuplicateObject(O , perfectcopy=TRUE, newloc = B, nerf=nerf_weapons, holoitem=TRUE)
			if(!O2)
				continue
			copiedobjs += O2
			copiedobjs += O2.GetAllContents()

		for(var/mob/M in T)
			if(iscameramob(M))
				continue // If we need to check for more mobs, I'll add a variable
			var/mob/SM = DuplicateObject(M , perfectcopy=TRUE, newloc = B, holoitem=TRUE)
			copiedobjs += SM
			copiedobjs += SM.GetAllContents()

		B.copy_template_vars(T)
		toupdate += B

	if(toupdate.len)
		for(var/turf/T1 in toupdate)
			CALCULATE_ADJACENT_TURFS(T1)

	rebuild_duplicated_proximity_monitors(copiedobjs)

	return copiedobjs

//Ссылка, которую копия не имеет права унаследовать: атом или обычный датум
//остаётся хозяйством шаблона. Картинка - значение внешнего вида, её копия получить
//обязана, иначе с турфа слетят оверлеи. Сырые аппирансы и фильтры - не датумы вовсе,
//istype(x, /datum) на них ложь, поэтому отдельная проверка isappearance тут не нужна:
//она наоборот пробивала фильтр для голых /datum - isappearance сверяется через
//istype(картинка, thing), а /image - наследник /datum, так что для typeof == /datum
//"аппирансом" объявлялся любой посторонний датум и оставался в копии шаблона.
#define IS_BORROWED_TEMPLATE_REF(value) (isdatum(value) && !isimage(value))

/**
 * Копия списка шаблона без чужих ссылок: датум выкидывается и из ключа, и из
 * значения, вложенные списки чистятся тем же правилом.
 *
 * Итерация for(in) даёт ключи списка - позиционный доступ source[i] тут не годится:
 * он возвращает ЗНАЧЕНИЕ слота. Прошлый вариант принимал значения за ключи, поэтому
 * элемент-список (atom_colours хранит пары цвет+приоритет вложенными списками)
 * уезжал в source[ключ] как индекс - голодек падал "bad index" на загрузке Beach.
 * Ассоциативные пары при этом разваливались: настоящий ключ через source[i] вообще
 * не достать, typecacheof-словари превращались в кучу элементов TRUE.
 */
/proc/copy_template_list(list/source)
	var/list/scrubbed = list()
	for(var/key in source)
		if(islist(key)) //вложенный список - обычный элемент без ассоциации; списком как индексом значение не спросить
			scrubbed += list(copy_template_list(key))
			continue
		if(IS_BORROWED_TEMPLATE_REF(key))
			continue //чужой датум-ключ уносит с собой всю пару
		//число и null ключами ассоциации не бывают, а source[число] - это доступ по индексу
		var/value = (isnum(key) || isnull(key)) ? null : source[key]
		if(IS_BORROWED_TEMPLATE_REF(value))
			continue //датум в значении выкидывает пару целиком, огрызок-ключ не нужен
		if(islist(value))
			value = copy_template_list(value)
		if(isnull(value))
			//простой элемент; += съел бы его молча, если это null
			scrubbed.len++
			scrubbed[scrubbed.len] = key
		else //ассоциированная пара встаёт одним слотом и в нужном месте порядка
			scrubbed[key] = value
	return scrubbed

/**
 * Переносит вары турфа-шаблона на этот турф (голодек, ресет тандердома).
 *
 * Правила те же, что у DuplicateObject: список копируется, а не шарится (иначе
 * геймплей в копии мутировал бы списки шаблона), ссылка на датум не переносится
 * вовсе - она сломается, как только оригинал удалят, и неважно, лежит она в варе
 * или внутри списка. Сверх этого отсекается лайтинг-состояние,
 * см. GLOB.turf_copy_forbidden_vars.
 */
/turf/proc/copy_template_vars(turf/template)
	if(!template)
		return
	for(var/varname in template.vars - GLOB.duplicate_forbidden_vars - GLOB.turf_copy_forbidden_vars)
		if(varname == "air")
			var/turf/open/open_copy = src
			var/turf/open/open_template = template
			if(istype(open_copy) && istype(open_template))
				open_copy.air.copy_from(open_template.return_air())
			continue
		var/template_value = template.vars[varname]
		if(islist(template_value))
			vars[varname] = copy_template_list(template_value)
			continue
		if(IS_BORROWED_TEMPLATE_REF(template_value))
			continue
		vars[varname] = template_value
	//светящиеся вары шаблона доехали, а источник света остался у шаблона:
	//заводим/гасим собственный по свежим light_range/light_power/light_on.
	//Обычный тёмный пол сюда не заходит - это горячий цикл на сотни турфов
	if(light || light_range)
		update_light()

#undef IS_BORROWED_TEMPLATE_REF
