/obj/item/screwdriver/
	icon = 'modular_bluemoon/phenyamomota/icon/obj/tools.dmi'

/obj/item/screwdriver/power
	icon = 'modular_bluemoon/phenyamomota/icon/obj/tools.dmi'
	icon_state = "drill_screw_map"

/obj/item/wrench
	icon = 'modular_bluemoon/phenyamomota/icon/obj/tools.dmi'

/obj/item/wrench/power
	icon = 'modular_bluemoon/phenyamomota/icon/obj/tools.dmi'
	icon_state = "drill_bolt_map"

/obj/item/crowbar
	icon = 'modular_bluemoon/phenyamomota/icon/obj/tools.dmi'

/obj/item/crowbar/red
	icon = 'modular_bluemoon/phenyamomota/icon/obj/tools.dmi'

/obj/item/crowbar/large
	icon = 'modular_bluemoon/phenyamomota/icon/obj/tools.dmi'

/obj/item/crowbar/power
	icon = 'modular_bluemoon/phenyamomota/icon/obj/tools.dmi'
	lefthand_file = 'modular_bluemoon/phenyamomota/icon/mob/inhand/inhand_left.dmi'
	righthand_file = 'modular_bluemoon/phenyamomota/icon/mob/inhand/inhand_right.dmi'

/obj/item/wirecutters/power
	icon = 'modular_bluemoon/phenyamomota/icon/obj/tools.dmi'
	lefthand_file = 'modular_bluemoon/phenyamomota/icon/mob/inhand/inhand_left.dmi'
	righthand_file = 'modular_bluemoon/phenyamomota/icon/mob/inhand/inhand_right.dmi'

/obj/item/weldingtool
	icon = 'modular_bluemoon/phenyamomota/icon/obj/tools.dmi'

/obj/item/mini
	icon = 'icons/obj/tools.dmi'

/obj/item/weldingtool/largetank
	icon = 'modular_bluemoon/phenyamomota/icon/obj/tools.dmi'

/obj/item/weldingtool/hugetank
	icon = 'modular_bluemoon/phenyamomota/icon/obj/tools.dmi'

/obj/item/weldingtool/experimental
	icon = 'modular_bluemoon/phenyamomota/icon/obj/tools.dmi'

/obj/item/multitool
	icon = 'modular_bluemoon/phenyamomota/icon/obj/tools.dmi'

/////// Хирургические инструменты Т2 ////////
/obj/item/scalpel/upgraded_t2
	name = "vibration scalpel"
	desc = "Скальпель. Снабжён титановым лезвием и генератором вибраций высоких частот для плавного разреза без усилия со стороны хирурга."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "scalpel_t2"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/equipment/tools_righthand.dmi'
	item_state = "scalpel_t2"
	force = 13
	toolspeed = 0.8

/obj/item/circular_saw/upgraded_t2
	name = "oscillating saw"
	desc = "Безопасная пила c шарниром для изменения угла и плоскости. С ней можно без труда распиливать твёрдые вещи, кости пациента или гипсовые формы."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "saw_t2"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/equipment/tools_righthand.dmi'
	item_state = "saw_t2"
	hitsound = null
	force = 8 // Осциллирующими пилами НЕВОЗМОЖНО разрезать мягкие ткани. Зато можно больно приложить
	w_class = WEIGHT_CLASS_SMALL
	wound_bonus = 1
	bare_wound_bonus = 2
	toolspeed = 0.7
	sharpness = SHARP_NONE
	butchery_tool = FALSE

/obj/item/retractor/upgraded_t2
	name = "titanium retractor"
	desc = "Зажим, он же хирургический ранорасширитель. Материал позволяет получить доступ к полости пациента без отторжения металла организмом."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "retractor_t2"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/equipment/tools_righthand.dmi'
	item_state = "retractor_t2"
	toolspeed = 0.8

/obj/item/hemostat/upgraded_t2
	name = "silvered hemostat"
	desc = "Инструмент-зажим для гемостаза, контроля над кровотечениями при операции. Серебряное напыление благотворно влияет стерильность раны пациента."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "hemostat_t2"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/equipment/tools_righthand.dmi'
	item_state = "hemostat_t2"
	toolspeed = 0.8

/obj/item/cautery/upgraded_t2
	name = "high heat cautery"
	desc = "Усиленный плазмой и контролирующей электроникой прижигатель, позволяющий тратить минимум времени на устранение кровотечений и закрытие операционного вскрытия."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "cautery_t2"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/equipment/tools_righthand.dmi'
	item_state = "cautery_t2"
	toolspeed = 0.8
	force = 12
	damtype = BURN
	heat = 7000
