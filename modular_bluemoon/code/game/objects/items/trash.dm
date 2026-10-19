/obj/item/trash/chips/macnachos
	name = "macnachos"
	icon_state = "macnachos"
	desc = "Когда-то это были вкусные чипсы"

// Использованная марлевая повязка, снятая с конечности. Отмывается до
// одной единицы /obj/item/stack/medical/gauze/improvised в раковине или
// стиральной машине.

// Иконки мусорной повязки подбираются по типу снятого бинта, последняя цифра
// в имени - общий вариант для чистой и кровавой версии (наклон тряпки).
#define GAUZE_TRASH_KIND_PLAIN "gauze_trash" // обычный медицинский бинт
#define GAUZE_TRASH_KIND_IMP "gauze_trash_imp" // импровизированный бинт
#define GAUZE_TRASH_KIND_ADV "gauze_trash_adv" // стерильный бинт

GLOBAL_LIST_INIT(gauze_trash_icon_kinds, list(
	GAUZE_TRASH_KIND_PLAIN,
	GAUZE_TRASH_KIND_IMP,
	GAUZE_TRASH_KIND_ADV,
))

/obj/item/trash/gauze
	name = "used gauze"
	desc = "Пропитавшаяся кровью марлевая повязка. Пахнет больницей. Если её отмыть, может выйти импровизированная марля."
	icon = 'icons/obj/medical/stack_medical.dmi'
	icon_state = "gauze_trash1"
	/// Префикс иконки по типу снятого бинта: gauze_trash / gauze_trash_imp / gauze_trash_adv
	var/icon_kind = GAUZE_TRASH_KIND_PLAIN
	/// Порядковый номер визуального варианта спрайта (1..3). Иконки: gauze_trash1 / _2 / _3
	var/variant = 1
	/// Цвет впитанной крови, берётся из преференсов владельца повязки.
	var/blood_color = BLOOD_COLOR_HUMAN
	/// Режим наложения крови при отрисовке оверлея.
	var/blood_blend = BLEND_MULTIPLY

/// Аргументы: gauze - снятый бинт (для выбора иконки), new_blood_color, new_blood_blend
/obj/item/trash/gauze/Initialize(mapload, gauze, new_blood_color, new_blood_blend)
	. = ..(mapload)
	if(istype(gauze, /obj/item/stack/medical/gauze/improvised))
		icon_kind = GAUZE_TRASH_KIND_IMP
	else if(istype(gauze, /obj/item/stack/medical/gauze/adv))
		icon_kind = GAUZE_TRASH_KIND_ADV
	else if(istype(gauze, /obj/item/stack/medical/gauze))
		icon_kind = GAUZE_TRASH_KIND_PLAIN
	else
		icon_kind = pick(GLOB.gauze_trash_icon_kinds) // подобрали в мусорке - вид не важен
	variant = rand(1, 3)
	icon_state = "[icon_kind][variant]"
	set_blood_info(new_blood_color, new_blood_blend)

/obj/item/trash/gauze/proc/set_blood_info(new_color, new_blend)
	if(new_color)
		blood_color = new_color
	if(!isnull(new_blend))
		blood_blend = new_blend
	update_appearance(UPDATE_OVERLAYS)

/obj/item/trash/gauze/update_overlays()
	. = ..()
	// Цифра варианта обязана совпадать с чистой иконкой: наклон у них общий,
	// различаются только оттенки тряпки.
	var/mutable_appearance/blood_overlay = mutable_appearance(icon, "[icon_kind]_blood[variant]", color = blood_color)
	blood_overlay.blend_mode = blood_blend
	. += blood_overlay

/// Отмывает повязку и превращает её в одну единицу импровизированной марли.
/obj/item/trash/gauze/proc/wash_into_improvised(mob/user)
	var/obj/item/stack/medical/gauze/improvised/clean_gauze = new(get_turf(src), 1, FALSE)
	qdel(src)
	if(user)
		user.put_in_hands(clean_gauze)
	return clean_gauze

/obj/item/trash/gauze/machine_wash(obj/machinery/washing_machine/WM)
	wash_into_improvised()
