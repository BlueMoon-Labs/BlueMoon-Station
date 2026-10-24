/// Все существующие части HK-51: по ним каркас пеленгует недостающие.
GLOBAL_LIST_EMPTY(hk51_parts)

/obj/item/hk51_part
	name = "HK-51 part"
	desc = "Деталь дроида-ассасина HK-51."
	icon = 'modular_bluemoon/icons/obj/hk_droids/hk51_parts.dmi'
	icon_state = "chassis"
	lefthand_file = 'modular_bluemoon/icons/obj/hk_droids/hk_droids_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/hk_droids/hk_droids_righthand.dmi'
	w_class = WEIGHT_CLASS_NORMAL
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	/// Ключ части: по нему каркас отличает установленные детали.
	var/part_id
	/// Лот, под которым часть продаётся на чёрном рынке.
	var/datum/blackmarket_item/misc/hk51_part/market_listing = /datum/blackmarket_item/misc/hk51_part
	/// Где искать следующую часть: бирка курьера от раскладчика.
	var/next_node
	/// Часть ушла в собранного дроида, её удаление - не потеря.
	var/consumed = FALSE

/obj/item/hk51_part/Initialize(mapload)
	. = ..()
	GLOB.hk51_parts += src

/obj/item/hk51_part/Destroy()
	GLOB.hk51_parts -= src
	return ..()

/obj/item/hk51_part/examine(mob/user)
	. = ..()
	. += span_notice("Все пять частей вставляются в каркас HK-51 - его печатают в фабрикаторе робототехники. Каркас пеленгует недостающие части. Огонь, лава и кислота деталь не берут, а пропавшую часть рано или поздно снова выставят на чёрный рынок.")
	if(next_node)
		. += span_notice("К части привязана бирка курьера: «Следующий узел отправлен: [next_node]».")

/obj/item/hk51_part/chassis
	name = "HK-51 chassis"
	desc = "Грудная бронеплита дроида-ассасина HK-51 в песочной краске с выцветшими красными полосами. Под ключицей выбит серийный номер - те же цифры стоят на остальных четырёх частях. Их растащили по заброшенным руинам вокруг станции, а одну, по слухам, перепродают на чёрном рынке."
	icon_state = "chassis"
	item_state = "hk51_chassis"
	w_class = WEIGHT_CLASS_BULKY
	part_id = "chassis"
	market_listing = /datum/blackmarket_item/misc/hk51_part/chassis

/obj/item/hk51_part/head
	name = "HK-51 head"
	desc = "Голова HK-51: шлем-капюшон с центральным ребром и косыми щелями фотоприёмников. Без корпуса, приводов, вокабулятора и мотиватора глаза не загорятся. Детали с тем же серийным номером ищите в ящиках заброшенных руин и у торговцев чёрного рынка."
	icon_state = "head"
	item_state = "hk51_head"
	part_id = "head"
	market_listing = /datum/blackmarket_item/misc/hk51_part/head

/obj/item/hk51_part/actuators
	name = "HK-51 actuators"
	desc = "Связка поршневых приводов конечностей HK-51, стянутая хомутами. Серийный номер на кожухе совпадает с номерами остальных частей дроида - их разбросало по руинам, а что-то всплыло на чёрном рынке."
	icon_state = "actuators"
	item_state = "hk51_actuators"
	part_id = "actuators"
	market_listing = /datum/blackmarket_item/misc/hk51_part/actuators

/obj/item/hk51_part/vocabulator
	name = "HK-51 vocabulator"
	desc = "Вокабулятор HK-51 - коробка речевого синтезатора с решёткой динамика. Пока молчит. Остальные части с тем же серийным номером лежат где-то в заброшенных руинах или продаются на чёрном рынке."
	icon_state = "vocabulator"
	item_state = "hk51_vocabulator"
	part_id = "vocabulator"
	market_listing = /datum/blackmarket_item/misc/hk51_part/vocabulator

/obj/item/hk51_part/motivator
	name = "HK-51 motivator"
	desc = "Мотиватор HK-51 - силовое сердце дроида, цилиндр с янтарной лампой. Такие держат на фабриках серии HK. Остальные части с этим серийным номером разошлись по заброшенным руинам и чёрному рынку."
	icon_state = "motivator"
	item_state = "hk51_motivator"
	part_id = "motivator"
	market_listing = /datum/blackmarket_item/misc/hk51_part/motivator

/// Лот части HK-51. Сам рынок его не выставляет: лот добавляет раскладчик частей.
/datum/blackmarket_item/misc/hk51_part
	name = "HK-51 part"
	desc = "Подлинная деталь дроида-ассасина HK-51, серийный номер сходится. Одна штука, без возврата и без вопросов."
	price_min = HK51_PART_PRICE_MIN
	price_max = HK51_PART_PRICE_MAX
	stock = 1
	availability_prob = 0
	/// Раскладчик, выставивший лот: купленная часть встаёт к нему на учёт.
	var/datum/weakref/scatter_ref
	/// Где, по словам продавца, лежит ещё одна часть.
	var/next_node

/datum/blackmarket_item/misc/hk51_part/proc/set_next_node(hint)
	next_node = hint
	desc = initial(desc)
	if(hint)
		desc += " Продавец божится, что знает, где лежит ещё одна деталь с тем же номером: [hint]."

/datum/blackmarket_item/misc/hk51_part/spawn_item(loc)
	var/obj/item/hk51_part/part = ..()
	var/datum/hk51_part_scatter/scatter = scatter_ref?.resolve()
	scatter?.track(part)
	if(istype(part) && next_node)
		part.next_node = next_node
	return part

/datum/blackmarket_item/misc/hk51_part/chassis
	name = "HK-51 chassis"
	item = /obj/item/hk51_part/chassis

/datum/blackmarket_item/misc/hk51_part/head
	name = "HK-51 head"
	item = /obj/item/hk51_part/head

/datum/blackmarket_item/misc/hk51_part/actuators
	name = "HK-51 actuators"
	item = /obj/item/hk51_part/actuators

/datum/blackmarket_item/misc/hk51_part/vocabulator
	name = "HK-51 vocabulator"
	item = /obj/item/hk51_part/vocabulator

/datum/blackmarket_item/misc/hk51_part/motivator
	name = "HK-51 motivator"
	item = /obj/item/hk51_part/motivator
