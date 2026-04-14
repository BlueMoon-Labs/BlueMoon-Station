#define ZEALSTAR_SPEECH "saibasan/zealstar.json"

/obj/item/gun/energy/modular_laser_rifle/zealstar
	name = "\improper Zealstar Rifle"
	desc = "«Zealstar» - модульный блюспейс-комплекс с адаптивной баллистикой. \
	Режимы: парализатор-винтовка, ракетомёт, дробовик, огнемёт и автоматическая винтовка. Боезапас \
	регенерируется за счёт стабилизированной сингулярности."
	speech_json_file = ZEALSTAR_SPEECH
	icon = 'modular_bluemoon/code/modules/modular_laser_rifle/zealstar/icons/zealstar_obj.dmi'
	lefthand_file = 'modular_bluemoon/code/modules/modular_laser_rifle/zealstar/icons/zealstar_lefthand.dmi'
	righthand_file = 'modular_bluemoon/code/modules/modular_laser_rifle/zealstar/icons/zealstar_righthand.dmi'
	mob_overlay_icon = 'modular_bluemoon/code/modules/modular_laser_rifle/zealstar/icons/zealstar_mob.dmi'
	icon_state = "zealstar_spear"
	base_icon_state = "zealstar"
	charge_sections = 3
	charge_delay = 1
	cell_type = /obj/item/stock_parts/cell/hyeseong_internal_cell
	ammo_type = list(/obj/item/ammo_casing/energy/laser/pulse)
	weapon_mode_options = list(
		/datum/laser_weapon_mode/squall,
		/datum/laser_weapon_mode/spear,
		/datum/laser_weapon_mode/thunder,
		/datum/laser_weapon_mode/hammer,
		/datum/laser_weapon_mode/phoenix,
	)
	default_selected_mode = "Spear"
	expanded_examine_text = "«Zealstar» - ограниченная серия артефактного оружия на основе блюспейс-ядра класса «Омега». \
	Разработана для элитных оперативников, способных использовать её адаптивные режимы: \
	«Копьё»: парализатор-винтовка; ведёт огонь направленными на отключение мышц импульсами. «Гром»: ракетомёт. \
	«Молот»: дробовик; ведёт огонь кинетическим дробящим выбросом энергии. «Феникс»: огнемёт; поток блюспейс-плазмы, испаряющий органику. \
	«Шквал»: автомат; ведёт огонь потоком перегретых блюспейс-частиц. Ядро сингулярности регенерирует \
	боезапас, но требует калибровки каждые 72 часа. Встроенный ИИ «Хранитель» адаптирует режимы под \
	тактику пользователя, хотя операторы отмечают его «избыточную инициативу». При попадании в руки противника \
	система инициирует коллапс ядра (радиус поражения - 100 метров)."

/obj/item/gun/energy/modular_laser_rifle/zealstar/Initialize(mapload)
	. = ..()

/obj/item/gun/energy/modular_laser_rifle/zealstar/equipped(mob/user, slot, initial)
	. = ..()
	if(slot != ITEM_SLOT_HANDS || !isliving(user))
		return
	if(HAS_TRAIT(user, TRAIT_MINDSHIELD))
		return
	to_chat(user, span_userdanger("<b>«Хранитель»:</b> Несанкционированный носитель. Имплант защиты разума не обнаружен. <b>ИНИЦИАЦИЯ КОЛЛАПСА ЯДРА.</b>"))
	playsound(src, 'sound/machines/nuke/confirm_beep.ogg', 65, TRUE)
	addtimer(CALLBACK(src, PROC_REF(zealstar_unauthorized_detonate)), 3 SECONDS, TIMER_UNIQUE|TIMER_OVERRIDE)

/obj/item/gun/energy/modular_laser_rifle/zealstar/proc/zealstar_unauthorized_detonate()
	if(QDELETED(src))
		return
	var/turf/T = get_turf(src)
	message_admins("Zealstar core collapse at [ADMIN_VERBOSEJMP(T)] (wielder without mindshield).")
	log_game("Zealstar self-destruct at [loc_name(T)] ([AREACOORD(T)]).")
	do_sparks(8, 1, src)
	explosion(T, 4, 5, 6, 7, adminlog = TRUE, ignorecap = FALSE, flame_range = 6)
	qdel(src)

/// SPEAR - ПАРАЛИЗАТОР (100 выстрелов из 10k ячейки) ///

/obj/item/ammo_casing/energy/cybersun_small_disabler/zealstar
	e_cost = 100

/datum/laser_weapon_mode/spear
	standard_firing_mode = FALSE
	name = "Spear"
	casing = /obj/item/ammo_casing/energy/cybersun_small_disabler/zealstar
	weapon_icon_state = "spear"
	charge_sections = 3
	shot_delay = 0.25 SECONDS
	json_speech_string = "spear"
	gun_runetext_color = "#47a1b3"

/datum/laser_weapon_mode/spear/apply_to_weapon(obj/item/gun/energy/applied_gun)
	..()

/datum/laser_weapon_mode/spear/remove_from_weapon(obj/item/gun/energy/applied_gun)
	..()

/// SPEAR - ПАРАЛИЗАТОР ///

/// THUNDER - РАКЕТНИЦА (2 выстрела из 10k ячейки) ///

/obj/item/ammo_casing/energy/laser/thunder
	projectile_type = /obj/item/projectile/bullet/a84mm
	e_cost = 5000
	fire_sound = 'sound/weapons/rocketlaunch.ogg'

/datum/laser_weapon_mode/thunder
	standard_firing_mode = FALSE
	name = "Thunder"
	casing = /obj/item/ammo_casing/energy/laser/thunder
	weapon_icon_state = "thunder"
	charge_sections = 3
	shot_delay = 2 SECONDS
	json_speech_string = "thunder"
	gun_runetext_color = "#77bd5d"

/datum/laser_weapon_mode/thunder/apply_to_weapon(obj/item/gun/energy/applied_gun)
	..()
	applied_gun.recoil = 4

/datum/laser_weapon_mode/thunder/remove_from_weapon(obj/item/gun/energy/applied_gun)
	..()
	applied_gun.recoil = initial(applied_gun.recoil)

/// THUNDER - РАКЕТНИЦА ///

/// HAMMER - ДРОБОВИК (10 выстрелов из 10k ячейки) ///

/obj/item/ammo_casing/energy/laser/hammer
	projectile_type = /obj/item/projectile/bullet/pellet/buckshot23
	pellets = 8
	variance = 10
	e_cost = 1000
	fire_sound = 'modular_bluemoon/code/modules/modular_laser_rifle/sounds/shotgun_heavy.ogg'

/datum/laser_weapon_mode/hammer
	standard_firing_mode = FALSE
	name = "Hammer"
	casing = /obj/item/ammo_casing/energy/laser/hammer
	weapon_icon_state = "hammer"
	radial_menu_icon = 'icons/obj/ammo.dmi'
	radial_menu_icon_state = "gshell"
	charge_sections = 3
	shot_delay = 0.75 SECONDS
	json_speech_string = "hammer"
	gun_runetext_color = "#7a0bb7"

/datum/laser_weapon_mode/hammer/apply_to_weapon(obj/item/gun/energy/applied_gun)
	..()
	applied_gun.recoil = 2

/datum/laser_weapon_mode/hammer/remove_from_weapon(obj/item/gun/energy/applied_gun)
	..()
	applied_gun.recoil = initial(applied_gun.recoil)

/// HAMMER - ДРОБОВИК ///

/// PHOENIX - ОГНЕМЁТ (50 выстрелов из 10k ячейки) ///

/obj/item/ammo_casing/energy/laser/flamethrower
	projectile_type = /obj/item/projectile/bullet/incendiary/flamethrower
	pellets = 8
	variance = 35
	e_cost = 200
	select_name = "Fire"
	fire_sound = 'modular_bluemoon/code/modules/modular_laser_rifle/sounds/flamethrower.ogg'

/obj/item/projectile/bullet/incendiary/flamethrower
	name = "Fire"
	damage = 7
	fire_stacks = 10
	damage_type = BURN
	icon_state = ""
	hitsound_wall = ""
	projectile_piercing = PASSMOB
	range = 15

/datum/laser_weapon_mode/phoenix
	standard_firing_mode = FALSE
	name = "Phoenix"
	casing = /obj/item/ammo_casing/energy/laser/flamethrower
	weapon_icon_state = "phoenix"
	radial_menu_icon = 'icons/effects/turf_fire.dmi'
	radial_menu_icon_state = "red_big"
	charge_sections = 3
	shot_delay = 0.4 SECONDS
	json_speech_string = "phoenix"
	gun_runetext_color = "#cd4456"

/datum/laser_weapon_mode/phoenix/apply_to_weapon(obj/item/gun/energy/applied_gun)
	return ..()

/datum/laser_weapon_mode/phoenix/remove_from_weapon(obj/item/gun/energy/applied_gun)
	return ..()

/// PHOENIX - ОГНЕМЁТ ///

/// SQUALL - АВТОМАТИЧЕСКАЯ ВИНТОВКА (50 выстрелов из 10k ячейки) ///

/obj/item/ammo_casing/energy/laser/squall
	projectile_type = /obj/item/projectile/bullet/a556
	e_cost = 200
	fire_sound = 'modular_bluemoon/code/modules/modular_laser_rifle/sounds/ak17_fire.ogg'

/datum/laser_weapon_mode/squall
	name = "Squall"
	casing = /obj/item/ammo_casing/energy/laser/squall
	weapon_icon_state = "squall"
	radial_menu_icon = 'icons/obj/ammo.dmi'
	radial_menu_icon_state = "762-casing-live"
	charge_sections = 3
	shot_delay = 0.25 SECONDS
	json_speech_string = "squall"
	gun_runetext_color = "#47a1b3"

/datum/laser_weapon_mode/squall/apply_to_weapon(obj/item/gun/energy/applied_gun)
	applied_gun.burst_size = 3
	autofire_component = applied_gun.AddComponent(/datum/component/automatic_fire, shot_delay)

/datum/laser_weapon_mode/squall/remove_from_weapon(obj/item/gun/energy/applied_gun)
	QDEL_NULL(autofire_component)
	applied_gun.burst_size = 1

/// SQUALL - АВТОМАТИЧЕСКАЯ ВИНТОВКА ///

#undef ZEALSTAR_SPEECH
