/obj/item/integrated_electronics/detailer
	name = "assembly detailer"
	desc = "Комбинированная установка для автоматической окраски и анодирования, предназначенная для придания электронным схемам яркого и износостойкого покрытия."
	icon = 'icons/obj/assemblies/electronic_tools.dmi'
	icon_state = "detailer"
	flags_1 = CONDUCT_1
	item_flags = NOBLUDGEON
	w_class = WEIGHT_CLASS_SMALL
	var/data_to_write = null
	var/accepting_refs = FALSE
	var/detail_color = COLOR_ASSEMBLY_WHITE
	var/list/color_list = list(
		"Чёрный" = COLOR_ASSEMBLY_BLACK,
		"Серый" = COLOR_FLOORTILE_GRAY,
		"Машинный серый" = COLOR_ASSEMBLY_BGRAY,
		"Белый" = COLOR_ASSEMBLY_WHITE,
		"Красный" = COLOR_ASSEMBLY_RED,
		"Оранжевый" = COLOR_ASSEMBLY_ORANGE,
		"Бежевый" = COLOR_ASSEMBLY_BEIGE,
		"Коричневый" = COLOR_ASSEMBLY_BROWN,
		"Золотой" = COLOR_ASSEMBLY_GOLD,
		"Жёлтый" = COLOR_ASSEMBLY_YELLOW,
		"Гуркха" = COLOR_ASSEMBLY_GURKHA,
		"Светло-зеленый" = COLOR_ASSEMBLY_LGREEN,
		"Зеленый" = COLOR_ASSEMBLY_GREEN,
		"Голубой" = COLOR_ASSEMBLY_LBLUE,
		"Синий" = COLOR_ASSEMBLY_BLUE,
		"Фиолетовый" = COLOR_ASSEMBLY_PURPLE,
		"Розовый" = LIGHT_COLOR_PINK,
		"Свой цвет" = COLOR_ASSEMBLY_WHITE
		)

/obj/item/integrated_electronics/detailer/Initialize(mapload)
	.=..()
	update_icon()

/obj/item/integrated_electronics/detailer/update_icon()
	cut_overlays()
	var/mutable_appearance/detail_overlay = mutable_appearance('icons/obj/assemblies/electronic_tools.dmi', "detailer-color")
	detail_overlay.color = detail_color
	add_overlay(detail_overlay)

/obj/item/integrated_electronics/detailer/attack_self(mob/user)
	var/color_choice = input(user, "Выберите цвет.", "Assembly Detailer") as null|anything in color_list
	if(!color_list[color_choice])
		return
	if(!in_range(src, user))
		return
	if(color_choice == "Свой цвет")
		detail_color = input(user,"","Выберите цвет",detail_color) as color|null
	else
		detail_color = color_list[color_choice]
	update_icon()
