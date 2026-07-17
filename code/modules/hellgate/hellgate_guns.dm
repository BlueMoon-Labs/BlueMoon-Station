// HellGate / PactDivest — оружие на спрайтах sprites_HellGate
// Пистолеты: pistol-ammo.dmi, 17 патр. Винтовки: rifle-ammo.dmi, 30 патр. Пулемёты: machinegun-ammo.dmi, 100 патр. Иконка _e — пустой.

// Магазин для VP78 (10мм, 17 патр.) — спрайт pistol-ammo.dmi
/obj/item/ammo_box/magazine/hellgate_vp78
	name = "магазин VP78 (10мм, 17 патр.)"
	desc = "Магазин под пистолет VP78. 10мм."
	icon = 'icons/obj/hellgate/pistol-ammo.dmi'
	icon_state = "vp78"
	ammo_type = /obj/item/ammo_casing/c10mm
	caliber = "10mm"
	max_ammo = 17

/obj/item/ammo_box/magazine/hellgate_vp78/update_icon_state()
	icon_state = ammo_count() ? "vp78" : "vp78_e"

// Магазин для C77 (7.62x39, 30 патр.) — спрайт rifle-ammo.dmi (винтовочный)
/obj/item/ammo_box/magazine/hellgate_c77
	name = "магазин C77 (7.62x39, 30 патр.)"
	desc = "Магазин под винтовку C77. 7.62x39."
	icon = 'icons/obj/hellgate/rifle-ammo.dmi'
	icon_state = "c77"
	ammo_type = /obj/item/ammo_casing/a762x39
	caliber = "a762x39"
	max_ammo = 30

/obj/item/ammo_box/magazine/hellgate_c77/update_icon_state()
	icon_state = ammo_count() ? "c77" : "c77_e"

// Магазин для M41A (5.56, 100 патр.)
/obj/item/ammo_box/magazine/hellgate_m41a
	name = "магазин M41A (5.56, 100 патр.)"
	desc = "Магазин под автомат M41A. 5.56мм."
	icon = 'icons/obj/hellgate/machinegun-ammo.dmi'
	icon_state = "m41a"
	ammo_type = /obj/item/ammo_casing/a556
	caliber = "a556"
	max_ammo = 100

/obj/item/ammo_box/magazine/hellgate_m41a/update_icon_state()
	icon_state = ammo_count() ? "m41a" : "m41a_e"

// Магазин для V41 (7.62x39, 100 патр.)
/obj/item/ammo_box/magazine/hellgate_v41
	name = "магазин V41 (7.62x39, 100 патр.)"
	desc = "Магазин под пулемёт V41. 7.62x39."
	icon = 'icons/obj/hellgate/machinegun-ammo.dmi'
	icon_state = "v41"
	ammo_type = /obj/item/ammo_casing/a762x39
	caliber = "a762x39"
	max_ammo = 100

/obj/item/ammo_box/magazine/hellgate_v41/update_icon_state()
	icon_state = ammo_count() ? "v41" : "v41_e"

// Магазин для C74 (7.62x39, 100 патр.)
/obj/item/ammo_box/magazine/hellgate_c74
	name = "магазин C74 (7.62x39, 100 патр.)"
	desc = "Магазин под автомат C74. 7.62x39."
	icon = 'icons/obj/hellgate/machinegun-ammo.dmi'
	icon_state = "c74"
	ammo_type = /obj/item/ammo_casing/a762x39
	caliber = "a762x39"
	max_ammo = 100

/obj/item/ammo_box/magazine/hellgate_c74/update_icon_state()
	icon_state = ammo_count() ? "c74" : "c74_e"

// Магазин для SG60 (.45, 100 патр.)
/obj/item/ammo_box/magazine/hellgate_sg60
	name = "магазин SG60 (.45, 100 патр.)"
	desc = "Магазин под пулемёт SG60. Калибр .45."
	icon = 'icons/obj/hellgate/machinegun-ammo.dmi'
	icon_state = "sg60"
	ammo_type = /obj/item/ammo_casing/c45
	caliber = ".45"
	max_ammo = 100

/obj/item/ammo_box/magazine/hellgate_sg60/update_icon_state()
	icon_state = ammo_count() ? "sg60" : "sg60_e"

/obj/item/gun/ballistic/automatic/pistol/hellgate_vp78
	name = "VP78"
	desc = "Пистолет калибра 10мм. В билде."
	icon = 'icons/obj/hellgate/pistols.dmi'
	icon_state = "vp78"
	item_state = "vp78"
	lefthand_file = 'icons/mob/inhands/hellgate/pistols_left_1.dmi'
	righthand_file = 'icons/mob/inhands/hellgate/pistols_right_1.dmi'
	mag_type = /obj/item/ammo_box/magazine/hellgate_vp78
	fire_sound = 'sound/weapons/gun/pistol/shot.ogg'
	can_suppress = FALSE
	burst_size = 1
	fire_delay = 0
	fire_select_modes = list(SELECT_SEMI_AUTOMATIC)
	automatic_burst_overlay = FALSE

/obj/item/gun/ballistic/automatic/pistol/hellgate_vp78/update_icon_state()
	icon_state = magazine ? "vp78" : "vp78_e"

/obj/item/gun/ballistic/automatic/hellgate_c77
	name = "C77"
	desc = "Винтовка калибра 7,62x39 (магазин как у АК)."
	icon = 'icons/obj/hellgate/rifles64.dmi'
	icon_state = "c77"
	item_state = "c77"
	lefthand_file = 'icons/mob/inhands/hellgate/rifles_left_1.dmi'
	righthand_file = 'icons/mob/inhands/hellgate/rifles_right_1.dmi'
	mag_type = /obj/item/ammo_box/magazine/hellgate_c77
	fire_sound = 'sound/weapons/rifleshot.ogg'
	can_suppress = FALSE
	burst_size = 1
	fire_delay = 2
	fire_select_modes = list(SELECT_SEMI_AUTOMATIC, SELECT_BURST_SHOT)
	automatic_burst_overlay = FALSE
	weapon_weight = WEAPON_MEDIUM

/obj/item/gun/ballistic/automatic/hellgate_c77/update_icon_state()
	icon_state = magazine ? "c77" : "c77_e"

/obj/item/gun/ballistic/automatic/hellgate_m41a
	name = "M41A"
	desc = "Автомат калибра 5,56."
	icon = 'icons/obj/hellgate/machineguns64.dmi'
	icon_state = "m41a"
	item_state = "m41a"
	lefthand_file = 'icons/mob/inhands/hellgate/machineguns_left_1.dmi'
	righthand_file = 'icons/mob/inhands/hellgate/machineguns_right_1.dmi'
	mag_type = /obj/item/ammo_box/magazine/hellgate_m41a
	fire_sound = 'sound/weapons/rifleshot.ogg'
	can_suppress = FALSE
	burst_size = 3
	burst_shot_delay = 2
	fire_delay = 2
	fire_select_modes = list(SELECT_SEMI_AUTOMATIC, SELECT_BURST_SHOT, SELECT_FULLY_AUTOMATIC)
	automatic_burst_overlay = TRUE
	weapon_weight = WEAPON_MEDIUM

/obj/item/gun/ballistic/automatic/hellgate_m41a/update_icon_state()
	icon_state = magazine ? "m41a" : "m41a_e"

// V41 — 7.62x39. В inhand .dmi нет состояния v41 — используем m41a для отображения в руках
/obj/item/gun/ballistic/automatic/hellgate_v41
	name = "V41"
	desc = "Пулемёт калибра 7,62x39."
	icon = 'icons/obj/hellgate/machineguns64.dmi'
	icon_state = "v41"
	item_state = "m41a"
	lefthand_file = 'icons/mob/inhands/hellgate/machineguns_left_1.dmi'
	righthand_file = 'icons/mob/inhands/hellgate/machineguns_right_1.dmi'
	mag_type = /obj/item/ammo_box/magazine/hellgate_v41
	fire_sound = 'sound/weapons/rifleshot.ogg'
	can_suppress = FALSE
	burst_size = 3
	burst_shot_delay = 2
	fire_delay = 2
	fire_select_modes = list(SELECT_SEMI_AUTOMATIC, SELECT_BURST_SHOT, SELECT_FULLY_AUTOMATIC)
	automatic_burst_overlay = TRUE
	weapon_weight = WEAPON_HEAVY

/obj/item/gun/ballistic/automatic/hellgate_v41/update_icon_state()
	icon_state = magazine ? "v41" : "v41_e"

// C74 — 7.62x39
/obj/item/gun/ballistic/automatic/hellgate_c74
	name = "C74"
	desc = "Автомат калибра 7,62x39."
	icon = 'icons/obj/hellgate/machineguns64.dmi'
	icon_state = "c74"
	item_state = "c74"
	lefthand_file = 'icons/mob/inhands/hellgate/machineguns_left_1.dmi'
	righthand_file = 'icons/mob/inhands/hellgate/machineguns_right_1.dmi'
	mag_type = /obj/item/ammo_box/magazine/hellgate_c74
	fire_sound = 'sound/weapons/rifleshot.ogg'
	can_suppress = FALSE
	burst_size = 3
	burst_shot_delay = 2
	fire_delay = 2
	fire_select_modes = list(SELECT_SEMI_AUTOMATIC, SELECT_BURST_SHOT, SELECT_FULLY_AUTOMATIC)
	automatic_burst_overlay = TRUE
	weapon_weight = WEAPON_MEDIUM

/obj/item/gun/ballistic/automatic/hellgate_c74/update_icon_state()
	icon_state = magazine ? "c74" : "c74_e"

// SG60 — .45
/obj/item/gun/ballistic/automatic/hellgate_sg60
	name = "SG60"
	desc = "Пулемёт калибра .45."
	icon = 'icons/obj/hellgate/machineguns64.dmi'
	icon_state = "sg60"
	item_state = "sg60"
	lefthand_file = 'icons/mob/inhands/hellgate/machineguns_left_1.dmi'
	righthand_file = 'icons/mob/inhands/hellgate/machineguns_right_1.dmi'
	mag_type = /obj/item/ammo_box/magazine/hellgate_sg60
	fire_sound = 'sound/weapons/gunshot_smg.ogg'
	can_suppress = FALSE
	burst_size = 3
	burst_shot_delay = 2
	fire_delay = 2
	fire_select_modes = list(SELECT_SEMI_AUTOMATIC, SELECT_BURST_SHOT, SELECT_FULLY_AUTOMATIC)
	automatic_burst_overlay = TRUE
	weapon_weight = WEAPON_MEDIUM

/obj/item/gun/ballistic/automatic/hellgate_sg60/update_icon_state()
	icon_state = magazine ? "sg60" : "sg60_e"
