/// Окно, которое лопнуло, вскрывает отсек мгновенно, и до сих пор единственным
/// ответом было успеть добежать. Аирбаг - закладной модуль в оконной раме: пока
/// стекло цело, он висит на нём с горящей лампой, а в момент, когда стекло
/// вылетает, разворачивает мембрану на тот же тайл. Мембрана держит давление,
/// но недолго и недокрепко: это время на то, чтобы прийти с листом стекла, а не
/// замена стене.
///
/// Точки входа из code/game/objects/structures/window.dm - пять вызовов
/// airbag_*, вся остальная механика живёт здесь.

/// Сколько мембрана держится, прежде чем сдуться сама. Полторы минуты уходили
/// на то, чтобы просто добежать до ближайшего листа стекла: окно бьют не рядом
/// со складом. Три минуты - это уже "успеть, если пошёл сразу".
#define AIRBAG_INFLATED_LIFETIME (3 MINUTES)
/// За сколько до конца мембрана начинает шипеть. Сдувшаяся без предупреждения
/// мембрана вскрывает отсек ровно в тот момент, когда на неё перестали смотреть.
#define AIRBAG_DEFLATE_WARNING (30 SECONDS)
/// Сколько листов пластика уходит на перепаковку отработавшего модуля. Модуль
/// не расходник на одну смену: порванную мембрану складывают заново.
#define AIRBAG_REPACK_PLASTIC_COST 2

/obj/structure/window
	/// Заряженный модуль, вставленный в раму. Срабатывает только на разбитие.
	var/obj/item/airbag_module/airbag = null

/obj/structure/window/proc/airbag_examine()
	if(airbag)
		return list("<span class='notice'>В раму вставлен <b>аварийный аирбаг</b>. Кусачками можно вынуть.</span>")
	if(can_take_airbag())
		return list("<span class='notice'>В раму можно вставить аварийный аирбаг.</span>")
	return list()

/// Модуль распирает между стеклом и рамой, так что окну нужно быть закреплённым.
/obj/structure/window/proc/can_take_airbag()
	return anchored

/obj/structure/window/proc/airbag_overlay()
	if(!airbag)
		return null
	// Спокойная зелёная лампа, а не красный строб на два кадра: модуль в раме -
	// это штатное состояние окна, а мигающая тревога на каждом стекле отсека
	// читается как поломка и просто рябит в глазах.
	return mutable_appearance('modular_bluemoon/icons/obj/structures/inflatable.dmi', "airbag_safe")

/// TRUE, если предмет ушёл на работу с аирбагом и обычную обработку окна звать не надо.
/obj/structure/window/proc/airbag_attackby(obj/item/I, mob/living/user)
	if(istype(I, /obj/item/airbag_module))
		var/obj/item/airbag_module/module = I
		return module.install_into(src, user)
	// Отвёртка, лом и ключ у окна уже заняты разборкой рамы, кусачки - нет.
	if(airbag && I.tool_behaviour == TOOL_WIRECUTTER)
		return remove_airbag(user, I)
	return FALSE

/obj/structure/window/proc/remove_airbag(mob/living/user, obj/item/tool)
	if(!airbag)
		return FALSE
	tool?.play_tool_sound(src, 50)
	var/obj/item/airbag_module/module = airbag
	airbag = null
	module.forceMove(drop_location())
	if(user)
		user.put_in_hands(module)
		to_chat(user, "<span class='notice'>Вы вынимаете аирбаг из рамы [src].</span>")
	update_icon()
	return TRUE

/// Разобранное окно отдаёт модуль в руки, разбитое - тратит его на мембрану.
/obj/structure/window/proc/airbag_on_deconstruct(disassembled)
	if(!airbag)
		return
	var/obj/item/airbag_module/module = airbag
	airbag = null
	if(disassembled)
		module.forceMove(drop_location())
		return
	module.deploy(get_turf(src))

/// Окно, удалённое мимо deconstruct (админ, взрыв, смена турфа), не должно
/// уносить модуль с собой в никуда.
/obj/structure/window/proc/airbag_drop()
	if(!airbag)
		return
	var/obj/item/airbag_module/module = airbag
	airbag = null
	module.forceMove(drop_location())

/obj/item/airbag_module
	name = "аварийный аирбаг"
	desc = "Закладной модуль в оконную раму. Когда стекло вылетает, разворачивает мембрану на тот же тайл и держит давление, пока кто-нибудь не придёт с листом стекла."
	icon = 'modular_bluemoon/icons/obj/structures/inflatable.dmi'
	icon_state = "airbag_folded"
	w_class = WEIGHT_CLASS_SMALL
	custom_materials = list(/datum/material/iron = 500, /datum/material/plastic = 1000)
	/// Отработавший модуль сдувается в тряпку и в раму больше не встаёт.
	var/spent = FALSE

/obj/item/airbag_module/examine(mob/user)
	. = ..()
	if(spent)
		. += "<span class='warning'>Мембрана порвана. Складывается заново из <b>[AIRBAG_REPACK_PLASTIC_COST] листов пластика</b>.</span>"
	else
		. += "<span class='notice'>Вставляется в оконную раму. Срабатывает на разбитие стекла, но не на разборку.</span>"

/// Порванный модуль это корпус с целой пиропатронной частью: новая мембрана
/// складывается из пластика прямо в руках. Иначе восемь штук из вендора - это
/// восемь окон на всю смену, и функцию просто не начинают использовать.
/obj/item/airbag_module/attackby(obj/item/used_item, mob/user, params)
	if(!istype(used_item, /obj/item/stack/sheet/plastic))
		return ..()
	if(!spent)
		to_chat(user, "<span class='warning'>Мембрана [src] цела, складывать заново нечего.</span>")
		return TRUE
	var/obj/item/stack/sheet/plastic/patch = used_item
	if(patch.get_amount() < AIRBAG_REPACK_PLASTIC_COST)
		to_chat(user, "<span class='warning'>Нужно [AIRBAG_REPACK_PLASTIC_COST] листа пластика, чтобы сложить новую мембрану.</span>")
		return TRUE
	to_chat(user, "<span class='notice'>Вы начинаете складывать новую мембрану в корпус [src]...</span>")
	if(!do_after(user, 5 SECONDS, target = src))
		return TRUE
	repack(user, patch)
	return TRUE

/// Сама перепаковка вынесена из attackby, чтобы тест гонял ровно тот код,
/// который выполняется в игре, а не пятисекундное ожидание вокруг него.
/// Условия перепроверяются здесь же: за время do_after модуль могли сложить
/// чужими руками, а пластик - потратить.
/obj/item/airbag_module/proc/repack(mob/user, obj/item/stack/sheet/plastic/patch)
	if(!spent || !patch?.use(AIRBAG_REPACK_PLASTIC_COST))
		return FALSE
	spent = FALSE
	icon_state = initial(icon_state)
	playsound(src, 'sound/machines/click.ogg', 40, TRUE)
	if(user)
		user.visible_message("<span class='notice'>[user] складывает новую мембрану в [src].</span>",
			"<span class='notice'>Вы складываете новую мембрану в [src]. Модуль снова заряжен.</span>")
	return TRUE

/obj/item/airbag_module/proc/install_into(obj/structure/window/target, mob/living/user)
	if(spent)
		to_chat(user, "<span class='warning'>Мембрана [src] порвана.</span>")
		return TRUE
	if(!target.can_take_airbag())
		to_chat(user, "<span class='warning'>[target] не закреплено в раме, модуль держать нечем.</span>")
		return TRUE
	if(target.airbag)
		to_chat(user, "<span class='warning'>В раме [target] уже стоит аирбаг.</span>")
		return TRUE
	if(!user.transferItemToLoc(src, target))
		return TRUE
	target.airbag = src
	target.update_icon()
	user.visible_message("<span class='notice'>[user] вставляет аирбаг в раму [target].</span>",
		"<span class='notice'>Вы вставляете аирбаг в раму [target]. Лампа модуля загорается.</span>")
	playsound(target, 'sound/machines/click.ogg', 50, TRUE)
	return TRUE

/// Модуль тратится целиком: на тайл встаёт мембрана, а сам он уезжает внутрь неё
/// и вернётся порванным, когда та сдуется.
/obj/item/airbag_module/proc/deploy(turf/where)
	if(spent || !isturf(where))
		return null
	spent = TRUE
	icon_state = "airbag_folded_torn"
	var/obj/structure/inflatable/airbag/membrane = new(where)
	forceMove(membrane)
	membrane.module = src
	return membrane

/obj/item/airbag_module/spent
	spent = TRUE
	icon_state = "airbag_folded_torn"

/obj/structure/inflatable/airbag
	name = "аварийная мембрана"
	desc = "Раздутая аварийная мембрана. Держит давление ровно столько, сколько нужно, чтобы успеть застеклить проём."
	icon_state = "airbag_wall"
	max_integrity = 30
	// Смысл мембраны в том, что она держит воздух; плотность тут вторична.
	CanAtmosPass = ATMOS_PASS_NO
	/// Отработавший модуль, который выпадет, когда мембрана сдуется.
	var/obj/item/airbag_module/module
	/// Таймер саморазряда; снимается в Destroy, чтобы лопнутая мембрана не висела в SStimer.
	var/deflate_timer
	/// Таймер предупреждения о скором сдувании; снимается там же и по той же причине.
	var/warning_timer

/obj/structure/inflatable/airbag/Initialize(mapload)
	. = ..()
	// Тайл только что перестал быть дырой наружу - атмосу надо сказать об этом
	// сразу, иначе отсек продолжит стравливать до ближайшего пересчёта.
	air_update_turf(TRUE)
	playsound(src, 'sound/effects/spray.ogg', 60, TRUE)
	visible_message("<span class='warning'>Аирбаг с шипением разворачивается, затыкая проём!</span>")
	deflate_timer = addtimer(CALLBACK(src, PROC_REF(deflate)), AIRBAG_INFLATED_LIFETIME, TIMER_STOPPABLE)
	warning_timer = addtimer(CALLBACK(src, PROC_REF(warn_deflating)), AIRBAG_INFLATED_LIFETIME - AIRBAG_DEFLATE_WARNING, TIMER_STOPPABLE)

/obj/structure/inflatable/airbag/Destroy()
	if(deflate_timer)
		deltimer(deflate_timer)
		deflate_timer = null
	if(warning_timer)
		deltimer(warning_timer)
		warning_timer = null
	var/turf/where = get_turf(src)
	if(module)
		module.forceMove(where || drop_location())
		module = null
	. = ..()
	// Порядок важен: пересчитывать проходимость имеет смысл только после того,
	// как мембраны на тайле уже нет.
	if(where)
		where.air_update_turf(TRUE)

/obj/structure/inflatable/airbag/proc/warn_deflating()
	warning_timer = null
	if(QDELETED(src))
		return
	visible_message("<span class='warning'>Аварийная мембрана начинает шипеть и оседать.</span>")
	playsound(src, 'sound/effects/spray.ogg', 25, TRUE)

/obj/structure/inflatable/airbag/proc/deflate()
	if(QDELETED(src))
		return
	visible_message("<span class='warning'>Аварийная мембрана сдувается.</span>")
	playsound(src, 'sound/effects/spray.ogg', 40, TRUE)
	qdel(src)

/obj/structure/inflatable/airbag/examine(mob/user)
	. = ..()
	. += "<span class='warning'>Долго не продержится. Проём надо застеклить.</span>"

#undef AIRBAG_INFLATED_LIFETIME
#undef AIRBAG_DEFLATE_WARNING
#undef AIRBAG_REPACK_PLASTIC_COST
