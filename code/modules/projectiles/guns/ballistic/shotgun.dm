/obj/item/gun/ballistic/shotgun
	name = "Shotgun"
	desc = "Традиционный дробовик с деревянным прикладом и подствольным магазином на четыре патрона."
	sawn_desc = "Но люди сверху решили, что теперь мы друзья. Позволь спросить... Тебя глошит чувство стыда за то что ты делал? -Две крепости. Часть 3."
	icon_state = "shotgun"
	item_state = "shotgun-wielded"
	fire_sound = "sound/weapons/gunshotshotgunshot.ogg"
	w_class = WEIGHT_CLASS_BULKY
	recoil = 0.5
	force = 10
	flags_1 =  CONDUCT_1
	slot_flags = ITEM_SLOT_BACK
	mag_type = /obj/item/ammo_box/magazine/internal/shot
	casing_ejector = FALSE
	can_suppress = FALSE
	can_bayonet = FALSE
	var/recentpump = 0 // to prevent spammage
	var/pumpsound = "sound/weapons/shotgunpump.ogg" //Звуки досыла патрона
	var/loadshell_sound = 'sound/weapons/shotguninsert.ogg' //Звуки заряжания патрона внутрь

	var/jammed = FALSE //Имеет ли осечку
	var/jam_multiplier = 0  //множитель стресса
	var/jam_threshold = 160
	var/last_fire_time = 0 //Проверка когда был произведён последний выстрел
	var/uses_jam = FALSE //Будет ли дробовик иметь осечки
	var/jam_stress = 0 //Показатель стресса.
	var/last_stress_decay = 0 //Падение стресса со временем
	var/stress_pump_delay = 0
	var/stress_stam_cost = 0
	var/stress_spread_mult = 0

	var/suppressed_spread_mult = 0.75 //Глушитель = меньший разброс и отдача
	var/suppressed_recoil_mult = 0.7
	var/base_spread = null //Кэширование базового значения обоих параметров
	var/base_recoil = null

	weapon_weight = WEAPON_HEAVY
	sawn_icon_state = "sawnshotgun"

/obj/item/gun/ballistic/shotgun/Initialize(mapload)
    . = ..()

    if(isnull(base_spread))
        base_spread = spread

    if(isnull(base_recoil))
        base_recoil = recoil

/obj/item/gun/ballistic/shotgun/attackby(obj/item/A, mob/user, params)
	. = ..()
	if(.)
		return
	var/num_loaded = magazine.attackby(A, user, params, 1)
	if(num_loaded)
		to_chat(user, "<span class='notice'>Вы заряжаете [num_loaded] в [src]!</span>")
		playsound(user, loadshell_sound, 60, 1)
		shake_camera(user, 0.5, 0.5)
		A.update_icon()
		update_icon()

	refresh_stress_effects()

/obj/item/gun/ballistic/shotgun/process_chamber(mob/living/user, empty_chamber = 0)
	return ..() //changed argument value

/obj/item/gun/ballistic/shotgun/proc/update_jam_stress()

    if(!uses_jam)
        return

    if(jam_stress <= 0)
        last_stress_decay = world.time
        return

    var/time_passed = world.time - last_stress_decay

    if(time_passed < 20)
        return

    var/decay_ticks = round(time_passed / 20) //2 секунды

    jam_stress = max(0, jam_stress - decay_ticks)

    last_stress_decay = world.time

/obj/item/gun/ballistic/shotgun/proc/update_stress_effects()

    stress_spread_mult = 0
    stress_pump_delay = 0
    stress_stam_cost = 0

    if(jam_stress >= 40)
        stress_spread_mult = 4

    if(jam_stress >= 60)
        stress_spread_mult = 8
        stress_stam_cost = 2

    if(jam_stress >= 80)
        stress_spread_mult = 14
        stress_stam_cost = 4
        stress_pump_delay = 2

    if(jam_stress >= jam_threshold)
        jammed = TRUE

/obj/item/gun/ballistic/shotgun/proc/refresh_stress_effects()
    update_jam_stress()
    update_stress_effects()

/obj/item/gun/ballistic/shotgun/proc/get_stressed_shot_spread(bonus_spread = 0)
    var/randomized_gun_spread = 0
    if(spread)
        randomized_gun_spread = rand(0, spread)
    var/randomized_bonus_spread = rand(0, bonus_spread + stress_spread_mult)
    return round((rand() - 0.5) * 1.4 * (randomized_gun_spread + randomized_bonus_spread))

/obj/item/gun/ballistic/shotgun/proc/apply_stressed_shot_stamina(mob/living/user, stam_cost = 0)
    if(!user)
        return
    stam_cost += stress_stam_cost
    if(stam_cost <= 0)
        return
    var/safe_cost = clamp(stam_cost, 0, user.stamina_buffer)
    user.UseStaminaBuffer(safe_cost)

/obj/item/gun/ballistic/shotgun/proc/get_chambered_stress_added()
    if(chambered)
        return chambered.stress_added
    return 0

/obj/item/gun/ballistic/shotgun/proc/get_chambered_recoil_added()
    if(chambered)
        return chambered.recoil_added
    return 0

/obj/item/gun/ballistic/shotgun/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, stam_cost = 0)

    if(uses_jam)
        refresh_stress_effects()
        if(!can_fire_check(user))
            return

        if(try_jam(user))
            return

    bonus_spread += stress_spread_mult
    stam_cost += stress_stam_cost

    var/ammo_recoil_added = 0
    if(chambered)
        ammo_recoil_added = chambered.recoil_added
        recoil = base_recoil + ammo_recoil_added

    var/result = ..()

    if(result)
        last_fire_time = world.time
        var/ammo_stress_added = 0
        if(chambered)
            ammo_stress_added = chambered.stress_added
        jam_stress += round(15 * jam_multiplier) + ammo_stress_added
        update_stress_effects()
    else
        recoil = base_recoil

    return result

/obj/item/gun/ballistic/shotgun/chamber_round()
	return

/obj/item/gun/ballistic/shotgun/proc/can_fire_check(mob/living/user)

	if(jammed)
		to_chat(user, "<span class='warning'>Оружие заклинило!</span>")
		playsound(user, "sound/weapons/Shotguns_reheated/shared/jam_warning.ogg", 60, TRUE)
		balloon_alert(user, "Щёлк?!")
		update_jam_stress()
		return FALSE

	return TRUE

/obj/item/gun/ballistic/shotgun/proc/try_jam(mob/living/user)

    if(jam_stress >= jam_threshold)
        jammed = TRUE
        to_chat(user, "<span class='warning'>Оружие заклинило!</span>")
        return TRUE

    return FALSE

/obj/item/gun/ballistic/shotgun/proc/clear_jam(mob/living/user, visible = TRUE, play_sound = TRUE)
	if(!jammed)
		return FALSE
	if(visible)
		user.visible_message("<span class='warning'>[user] с заметным усилием взводит [src]!</span>", "<span class='notice'>Вы устраняете осечку. Оружие готово к использованию!</span>")
		balloon_alert(user, "С заметным усилием взводит оружие!")
	playsound(user, 'sound/weapons/Shotguns_reheated/shared/weapon_rattle.ogg', 75, TRUE)
	playsound(user, pumpsound, 60, TRUE)
	jam_stress = max(0, jam_stress - 40)
	shake_camera(user, 1.8, 1.6)
	// используем существующую механику
	pump_unload(user)
	pump_reload(user)

	jammed = FALSE
	update_stress_effects()
	update_icon()
	return TRUE


/obj/item/gun/ballistic/shotgun/can_shoot()
	if(!chambered)
		return FALSE
	return (chambered.BB ? 1 : 0)

/obj/item/gun/ballistic/shotgun/attack_self(mob/living/user)
    if(recentpump > world.time)
        return
    refresh_stress_effects()

    if(IS_STAMCRIT(user))
        to_chat(user, "<span class='warning'>Вы слишком устали чтобы это сделать.</span>")
        return

    if(jammed)
        if(clear_jam(user))
            return

    if(HAS_TRAIT(user, TRAIT_FAST_PUMP))
        recentpump = world.time + 2
    else if(!user.UseStaminaBuffer(2, warn = TRUE))
        return
    pump(user, TRUE)
    recentpump = world.time + 4 + stress_pump_delay
    update_stress_effects()


/obj/item/gun/ballistic/shotgun/proc/pump(mob/M, visible = TRUE, play_sound = TRUE)

	if(visible)
		M.visible_message("<span class='warning'>[M] взводит [src]!</span>", "<span class='warning'>Вы взводите [src]!</span>")

	if(play_sound)
		playsound(M, pumpsound, 60, TRUE)
		shake_camera(M, 1.2, 0.8)
	pump_unload(M)
	pump_reload(M)
	update_icon()
	jam_stress = max(0, jam_stress - 15)
	update_stress_effects()
	return TRUE

/obj/item/gun/ballistic/shotgun/proc/pump_unload(mob/M)
	if(chambered)//We have a shell in the chamber
		chambered.forceMove(drop_location())//Eject casing
		chambered.bounce_away()
		chambered = null

/obj/item/gun/ballistic/shotgun/proc/pump_reload(mob/M)
	if(!magazine.ammo_count())
		return FALSE
	var/obj/item/ammo_casing/AC = magazine.get_round() //load next casing.
	chambered = AC
/obj/item/gun/ballistic/shotgun/examine(mob/user)
    . = ..()

    if(uses_jam)
        . += "<span class='notice'>["DEBUG JAM STATE"]</span>"
        . += "Stress: [jam_stress]"
        . += "Jammed: [jammed ? "YES" : "NO"]"

        if(jam_stress >= jam_threshold)
            . += "<span class='warning'>CRITICAL: JAM THRESHOLD EXCEEDED</span>"
        else if(jam_stress >= 70)
            . += "<span class='warning'>HIGH RISK</span>"
        else if(jam_stress >= 40)
            . += "Moderate stress"
        else
            . += "Stable"

    . += "<span class='notice'>DEBUG ICON STATE</span>"
    . += "icon_state: [icon_state]"
    . += "item_state: [item_state]"
    . += "sawn_icon_state: [sawn_icon_state]"
    . += "sawn_item_state: [sawn_item_state]"

    if(icon)
        . += "icon file: [icon]"
    else
        . += "icon file: NONE"

    . += "w_class: [w_class]"

/obj/item/gun/ballistic/shotgun/on_suppressor_installed(obj/item/suppressor/S)
    . = ..()

    spread = round(base_spread * suppressed_spread_mult)
    recoil = base_recoil * suppressed_recoil_mult

/obj/item/gun/ballistic/shotgun/on_suppressor_removed(obj/item/suppressor/S)
    . = ..()

    spread = base_spread
    recoil = base_recoil

/obj/item/gun/ballistic/shotgun/lethal
	mag_type = /obj/item/ammo_box/magazine/internal/shot/lethal

// RIOT SHOTGUN //

/obj/item/gun/ballistic/shotgun/riot //for spawn in the armory
	name = "Riot Shotgun"
	desc = "Надежный дробовик с удлиненным магазином и тактическим прикладом, предназначенный для применения в целях нелетального подавления массовых беспорядков."
	icon = 'icons/obj/guns/ShotgunsReheated.dmi'
	icon_state = "Riot"
	item_state = "riot-wielded"
	pumpsound = "sound/weapons/Shotguns_reheated/Riot/Riotchamber.ogg"
	fire_sound = "sound/weapons/Shotguns_reheated/Riot/Riotfire.ogg"
	suppressed_fire_sound = 'sound/weapons/Shotguns_reheated/shared/shotgunsuppressed.ogg'
	loadshell_sound = 'sound/weapons/Shotguns_reheated/shared/Shellinsert1.ogg'
	fire_delay = 8
	uses_jam = TRUE
	can_suppress = TRUE
	can_bayonet = TRUE
	knife_x_offset = 30
	knife_y_offset = 12
	jam_multiplier = 0.8
	mag_type = /obj/item/ammo_box/magazine/internal/shot/riot
	sawn_icon_state = "riot-sawn-e"
	sawn_item_state = "riot-sawn"
	sawn_desc = "Следуй за мной если хочешь жить."
	spread = 0.4

/obj/item/gun/ballistic/shotgun/riot/update_icon()
    . = ..()
    if(current_skin)
        icon_state = unique_reskin[current_skin]["icon_state"] + (sawn_off ? "-sawn" : "") + (suppressed ? "-suppressed" : "") + (chambered ? "" : "-e")
    else
        icon_state = initial(icon_state) + (sawn_off ? "-sawn" : "") + (suppressed ? "-suppressed" : "") + (chambered ? "" : "-e")

/obj/item/gun/ballistic/shotgun/riot/attackby(obj/item/A, mob/user, params)
	..()
	if(A.tool_behaviour == TOOL_SAW || istype(A, /obj/item/gun/energy/plasmacutter))
		sawoff(user)
	if(istype(A, /obj/item/melee/transforming/energy))
		var/obj/item/melee/transforming/energy/W = A
		if(W.active)
			sawoff(user)

/obj/item/gun/ballistic/shotgun/riot/syndicate
	name = "\improper Peacebreaker shotgun"
	desc = "Дробовик компании Scarborough для борьбы с массовыми беспорядками, оснащенный алой отделкой и деревянным тактическим прикладом. Можно поклясться, что эту модель уже вы где-то видели..."
	sawn_desc = "Нет. И тебя не должно. Мы сами подписались резать друг другу глотки за интересы сверху. Так выпьем за наш шаткий союз! -Две крепости. Часть 4."
	icon = 'icons/obj/guns/projectile.dmi'
	icon = 'icons/obj/guns/ShotgunsReheated.dmi'
	icon_state = "Peacebreaker"
	item_state = "peacebreaker-wielded"
	sawn_icon_state = "Peacebreaker-sawn-e"
	sawn_item_state = "peacebreaker-sawn"
	fire_delay = 3
	uses_jam = TRUE
	can_bayonet = TRUE
	can_suppress = FALSE

/obj/item/gun/ballistic/shotgun/jackhammer
	name = "CS-11 'JackHammer'"
	desc = "Универсальный инструмент для быстрого проникновения в труднодоступные места. Малый магазин, легко крепится на пояс, рукоять позволяет стрелять одной рукой."
	icon = 'icons/obj/guns/ShotgunsReheated.dmi'
	icon_state = "jackhammer"
	item_state = "aspis-wielded"
	pumpsound = "sound/weapons/Shotguns_reheated/Slamfire/Slamfirepump.ogg"
	fire_sound = "sound/weapons/Shotguns_reheated/KS-23/Ks-23shot.ogg"
	loadshell_sound = 'sound/weapons/Shotguns_reheated/shared/Shellinsert2.ogg'
	mag_type = /obj/item/ammo_box/magazine/internal/shot/breacher
	fire_delay = 2
	uses_jam = TRUE
	jam_multiplier = 3
	ignore_twohand_requirement = TRUE
	w_class = WEIGHT_CLASS_SMALL

/obj/item/gun/ballistic/shotgun/jackhammer/update_icon()
    . = ..()
    if(current_skin)
        icon_state = unique_reskin[current_skin]["icon_state"] + (chambered ? "" : "-e")
    else
        icon_state = initial(icon_state) + (chambered ? "" : "-e")

//Dual Feed Shotgun

/obj/item/gun/ballistic/shotgun/dual_tube
	name = "CS-9 'Bastion'"
	desc = "Современный дробовик с двумя отдельными трубчатыми магазинами, позволяющий быстро переключаться между типами патронов."
	icon = 'icons/obj/guns/ShotgunsReheated.dmi'
	icon_state = "Bastion"
	item_state = "bastion-wielded"
	mag_type = /obj/item/ammo_box/magazine/internal/shot/tube
	w_class = WEIGHT_CLASS_BULKY
	can_suppress = TRUE //У него один ствол, duh. А вот штык-нож поставить будет тяжело
	can_bayonet = FALSE
	uses_jam = TRUE
	fire_delay = 7
	fire_sound = 'sound/weapons/Shotguns_reheated/Pumpaction/Pumpfire.ogg'
	pumpsound = 'sound/weapons/Shotguns_reheated/Pumpaction/Pumpchamber.ogg'
	suppressed_fire_sound = 'sound/weapons/Shotguns_reheated/shared/shotgunsuppressed.ogg'
	loadshell_sound = 'sound/weapons/Shotguns_reheated/Shared/Shellinstertplastic.wav'

	var/toggled = FALSE
	var/obj/item/ammo_box/magazine/internal/shot/alternate_magazine

/obj/item/gun/ballistic/shotgun/dual_tube/Initialize(mapload)
	. = ..()
	if(!alternate_magazine)
		alternate_magazine = new mag_type(src)

/obj/item/gun/ballistic/shotgun/dual_tube/attack_self(mob/living/user)
	return ..()

/obj/item/gun/ballistic/shotgun/dual_tube/proc/toggle_tube(mob/living/user, visible = TRUE, play_sound = TRUE)
	var/old = magazine
	magazine = alternate_magazine
	alternate_magazine = old

	toggled = !toggled
	if(visible)
		user.visible_message("[user] переворачивает оружие и переключает подачу [src]</span>", "Вы переключаете магазины. Метка на селекторе горит [toggled ? "<span style='color: #25b334'>зелёным</span>" : "<span style='color: #ff0000'>красным</span>"]!")
		balloon_alert(user, "Вскидывает пушку и переключает подачу!")
	playsound(user, 'sound/weapons/Shotguns_reheated/shared/Cyclerswap.ogg', 60, 1)
	update_icon()

/obj/item/gun/ballistic/shotgun/dual_tube/AltClick(mob/living/user)
	if(!istype(user) || !user.canUseTopic(src, BE_CLOSE, ismonkey(user)))
		return

	toggle_tube(user)
	return TRUE

/obj/item/gun/ballistic/shotgun/dual_tube/update_icon()
	. = ..()
	var/state = current_skin ? unique_reskin[current_skin]["icon_state"] : initial(icon_state)
	state += (suppressed ? "-suppressed" : "")
	state += (chambered ? "" : "-e")
	icon_state = state
	overlays.Cut()
	if(toggled)
		overlays += mutable_appearance(icon, "Bastion-selector")

/// Я в рот ебал кодить эту пушку, но она очень крутая. Обожаю ультранасилие(Над своей жопой) - RzW
/obj/item/gun/ballistic/shotgun/dp12
    name = "Aegis-12 'Teta'"
    desc = "Два дробовика в одной цельнометалической оболочке. Чертёж был импортирован извне, от этой адской машины несёт Марсианским духом за километр. Сборка оставляет желать лучшего, но оружие справляется с прямой функцией."
    icon = 'icons/obj/guns/ShotgunsReheated.dmi'
    icon_state = "Aegis"
    item_state = "aegis-wielded"

    mag_type = /obj/item/ammo_box/magazine/internal/shot/tube
    uses_jam = TRUE
    jam_multiplier = 1.2
    w_class = WEIGHT_CLASS_HUGE
    fire_delay = 8

    fire_sound = 'sound/weapons/Shotguns_reheated/Pumpaction/Pumpfire.ogg'
    pumpsound = 'sound/weapons/Shotguns_reheated/Pumpaction/Pumpchamber.ogg'
    loadshell_sound = 'sound/weapons/Shotguns_reheated/Shared/Shellinstertplastic.wav'

    var/obj/item/ammo_casing/secondary_chambered = null
    var/obj/item/ammo_box/magazine/internal/shot/alternate_magazine
    var/load_toggle = FALSE

/obj/item/gun/ballistic/shotgun/dp12/Initialize(mapload)
    . = ..()
    if(!alternate_magazine)
        alternate_magazine = new mag_type(src)

/obj/item/gun/ballistic/shotgun/dp12/can_shoot()
    return (chambered && chambered.BB) || (secondary_chambered && secondary_chambered.BB)

/obj/item/gun/ballistic/shotgun/dp12/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, stam_cost = 0)

    // Хук осечек
    if(uses_jam)
        refresh_stress_effects()
        if(!can_fire_check(user))
            return
        if(try_jam(user))
            return

    var/fired = FALSE
    var/shot_spread = get_stressed_shot_spread(bonus_spread)

    // Сначала первый, потом второй ствол.
    if(chambered && chambered.BB)
        chambered.fire_casing(target, user, params, , suppressed, zone_override, shot_spread, src)
        fired = TRUE
       	shake_camera(user, 2, 2) //Хотите чизить оружие, минусы которого построены на отдаче? Я запрещаю.
    else if(secondary_chambered && secondary_chambered.BB)
        secondary_chambered.fire_casing(target, user, params, , suppressed, zone_override, shot_spread, src)
        fired = TRUE
       	shake_camera(user, 2.5, 2.5)

    if(!fired)
        return ..() // защита от пустого клика

    apply_stressed_shot_stamina(user, stam_cost)
    playsound(user, fire_sound, 50, TRUE)
    user.do_attack_animation(src)

    last_fire_time = world.time
    jam_stress += round(15 * jam_multiplier)
    update_stress_effects()

    update_icon()
    return TRUE


/obj/item/gun/ballistic/shotgun/dp12/pump(mob/M, visible = TRUE, play_sound = TRUE)

    if(clear_jam_dp12(M))
        return TRUE

    if(visible)
        M.visible_message("[M] взводит [src].", "Вы взводите [src].")

    if(play_sound)
        playsound(M, pumpsound, 60, TRUE)
        shake_camera(M, 1.2, 1)

    pump_unload_dual(M)
    pump_reload_dual(M)

    jam_stress = max(0, jam_stress - 10)
    update_stress_effects()

    update_icon()
    return TRUE

/obj/item/gun/ballistic/shotgun/dp12/proc/pump_unload_dual(mob/M)

    if(chambered)
        chambered.forceMove(drop_location())
        chambered.bounce_away()
        chambered = null

    if(secondary_chambered)
        secondary_chambered.forceMove(drop_location())
        secondary_chambered.bounce_away()
        secondary_chambered = null

/obj/item/gun/ballistic/shotgun/dp12/proc/pump_reload_dual(mob/M)

    if(magazine && magazine.ammo_count())
        if(!chambered)
            chambered = magazine.get_round()

    if(alternate_magazine && alternate_magazine.ammo_count())
        if(!secondary_chambered)
            secondary_chambered = alternate_magazine.get_round()

/obj/item/gun/ballistic/shotgun/dp12/proc/clear_jam_dp12(mob/living/user, visible = TRUE, play_sound = TRUE)

    if(!jammed)
        return FALSE
    if(visible)
        user.visible_message("<span class='warning'>[user] с заметным усилием взводит [src]</span>", "<span class='notice'>Вы устраняете осечку. Оружие готово к использованию!</span>")
        balloon_alert(user, "С заметным усилием взводит оружие!")
    playsound(user, 'sound/weapons/Shotguns_reheated/shared/weapon_rattle.ogg', 75, TRUE)
    playsound(user, pumpsound, 60, TRUE)
    shake_camera(user, 2, 2)

    pump_unload_dual(user)
    pump_reload_dual(user)

    jam_stress = max(0, jam_stress - 25)
    jammed = FALSE
    update_stress_effects()

    update_icon()
    return TRUE

/obj/item/gun/ballistic/shotgun/dp12/attackby(obj/item/A, mob/user, params)
    . = FALSE

    var/obj/item/ammo_box/magazine/internal/shot/target_mag
    var/obj/item/ammo_box/magazine/internal/shot/other_mag
    var/loaded = FALSE

    if(load_toggle)
        target_mag = alternate_magazine
        other_mag = magazine
    else
        target_mag = magazine
        other_mag = alternate_magazine

    if(target_mag)
        loaded = target_mag.attackby(A, user, params, 1)

    if(!loaded && other_mag)
        loaded = other_mag.attackby(A, user, params, 1)

    if(loaded)
        load_toggle = !load_toggle

        to_chat(user, "<span class='notice'>Вы заряжаете патрон в [src].</span>")
        playsound(user, loadshell_sound, 60, TRUE)
        shake_camera(user, 0.5, 0.5)

        A.update_icon()
        update_icon()
        return TRUE

    return FALSE

/obj/item/gun/ballistic/shotgun/dp12/update_icon()
	. = ..()
	var/state = initial(icon_state)
	if(!chambered?.BB && !secondary_chambered?.BB)
		state += "-e"
	icon_state = state

/* ДЕБАГ, ЗАКОММЕНТИТЬ ПОСЛЕ ТЕСТОВ
/obj/item/gun/ballistic/shotgun/dp12/examine(mob/user)
    . = ..()
    if(chambered)
        . += "Primary barrel: [chambered.BB ? "live" : "spent"]"
    if(secondary_chambered)
        . += "Secondary barrel: [secondary_chambered.BB ? "live" : "spent"]"
*/
/obj/item/gun/ballistic/shotgun/dp12/traitor
    name = "HCA-00 'Invictus'"
    desc = "Особая версия двуствольного дробовика сделанная под заказ неким Хейлом. Все детали были подогнанны идеально, а конструкция внушает доверие. Гравировка на корпусе гласит: 'Шок и трепет - лучшее лекарство. Рви и кромсай пока не иссякнут!'"
    icon = 'icons/obj/guns/ShotgunsReheated.dmi'
    icon_state = "Invictus"
    item_state = "invictus-wielded"
    mag_type = /obj/item/ammo_box/magazine/internal/shot/tube
    uses_jam = FALSE
    w_class = WEIGHT_CLASS_HUGE
    fire_delay = 6
    fire_sound = 'sound/weapons/Shotguns_reheated/Pumpaction/Pumpfire.ogg'
    pumpsound = 'sound/weapons/Shotguns_reheated/Pumpaction/Pumpchamber.ogg'
    loadshell_sound = 'sound/weapons/Shotguns_reheated/Shared/Shellinstertplastic.wav'
    var/doubleshot_mode = FALSE
    var/sync_stamina_cost = 15


/obj/item/gun/ballistic/shotgun/dp12/traitor/AltClick(mob/user)

    if(!istype(user) || !user.canUseTopic(src, BE_CLOSE, ismonkey(user)))
        return
    doubleshot_mode = !doubleshot_mode
    to_chat(user, "Вы переключаете режим стрельбы. Теперь оружие в режиме [doubleshot_mode ? "<span style='color: #ff0000'>синхронного выстрела</span>" : "<span style='color: #25b334'>стандартной стрельбы</span>"]!")
    balloon_alert(user, "Переключает режим стрельбы!")
    playsound(user, 'sound/weapons/Shotguns_reheated/shared/Cyclerswap.ogg', 60, TRUE)
    return TRUE

/obj/item/gun/ballistic/shotgun/dp12/traitor/proc/fire_second_barrel(atom/target, mob/living/user, params, suppressed, zone_override, shot_spread)
    if(QDELETED(src) || QDELETED(user) || !secondary_chambered)
        return
    secondary_chambered.fire_casing(target, user, params, , suppressed, zone_override, shot_spread, src)
    playsound(user, fire_sound, 75, TRUE)
    user.do_attack_animation(src)
    shake_camera(user, 1.5, 1.5)
    user.adjustStaminaLoss(10)

/obj/item/gun/ballistic/shotgun/dp12/traitor/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 2, stam_cost = 0)

    if(!doubleshot_mode)
        return ..()
    if(!(chambered && chambered.BB) || !(secondary_chambered && secondary_chambered.BB))
        to_chat(user, "<span class='warning'>Оба ствола должны быть заряжены для синхронного выстрела!</span>")
        return
    if(!user.UseStaminaBuffer(sync_stamina_cost, warn = TRUE))
        return
    var/shot_spread = get_stressed_shot_spread(bonus_spread)
    chambered.fire_casing(target, user, params, , suppressed, zone_override, shot_spread, src)
    shake_camera(user, 2.5, 3)
    secondary_chambered.fire_casing(target, user, params, , suppressed, zone_override, shot_spread, src)
    apply_stressed_shot_stamina(user, stam_cost)
    playsound(user, fire_sound, 75, TRUE)
// addtimer отвечает за задержу между выстрелами в синхронном режиме
    playsound(user, fire_sound, 75, TRUE)
    addtimer(CALLBACK(src, PROC_REF(fire_second_barrel), target, user, params, suppressed, zone_override, shot_spread), 1.2)

    last_fire_time = world.time
    return TRUE

/obj/item/gun/ballistic/shotgun/dp12/traitor/examine(mob/user)
    . = ..()
    . += "Alt-click чтобы сменить режим стрельбы."
    . += "Селектор стоит на режиме: [doubleshot_mode ? "СИНХ." : "СТАНД."]"

/obj/item/gun/ballistic/shotgun/dp12/traitor/update_icon()
	var/total_ammo = 0
	if(magazine)
		total_ammo += magazine.ammo_count()
	if(alternate_magazine)
		total_ammo += alternate_magazine.ammo_count()
	if(chambered && chambered.BB)
		total_ammo += 1
	if(secondary_chambered && secondary_chambered.BB)
		total_ammo += 1
	var/state = initial(icon_state)
	if(total_ammo <= 1)
		state = "[state]-e"
	else if(total_ammo <= 2)
		state = "[state]-m"
	icon_state = state

//due to code weirdness, and the fact that a refactor is coming soon anyway, the barman's shotgun and maint shotgun are in revolver.dm

/// SLAMFIRE ДРОБОВИКИ

/obj/item/gun/ballistic/shotgun/slamfire
    name = "Model 156-C"
    desc = "Репродукция старого полицейского дробовика, где ещё не был обрезан УСМ. Позволяет стрелять без остановки в правильной стойке."
    sawn_desc = "Мы вели эти партизанские войны, и для чего? Чтобы вновь восстать из пепла и надеяться на светлое будущее без корпораций? -Две крепости. Часть 1."
    icon = 'icons/obj/guns/ShotgunsReheated.dmi'
    icon_state = "156-C"
    item_state = "156c-wielded"
    sawn_icon_state = "156-C-sawn"
    sawn_item_state = "156c-sawn"
    pumpsound = "sound/weapons/Shotguns_reheated/Slamfire/Slamfirepump.ogg"
    fire_sound = "sound/weapons/Shotguns_reheated/Riot/Riotfire.ogg"
    loadshell_sound = 'sound/weapons/Shotguns_reheated/shared/Shellinsert1.ogg'
    suppressed_fire_sound = 'sound/weapons/Shotguns_reheated/shared/shotgunsuppressed.ogg'
    mag_type = /obj/item/ammo_box/magazine/internal/shot
    uses_jam = TRUE
    jam_multiplier = 1.3
    fire_delay = 4
    can_suppress = TRUE //Самое частое оружие в лутпуле. Пусть игрок узнает о том что можно у него есть возможность кастомизации таким образом.
    can_bayonet = TRUE
    knife_x_offset = 28
    knife_y_offset = 10
    ignore_twohand_requirement = TRUE
    weapon_weight = WEAPON_HEAVY
    var/auto_pump_delay = 4

/datum/movespeed_modifier/slamfire
    multiplicative_slowdown = 1.5

/datum/movespeed_modifier/slamfire_mid
    multiplicative_slowdown = 1.3

/datum/movespeed_modifier/slamfire_frenzy
    multiplicative_slowdown = 1.1

/obj/item/gun/ballistic/shotgun/slamfire/Initialize(mapload)
    . = ..()
    RegisterSignal(src, COMSIG_TWOHANDED_WIELD, PROC_REF(on_wield))
    RegisterSignal(src, COMSIG_TWOHANDED_UNWIELD, PROC_REF(on_unwield))

/obj/item/gun/ballistic/shotgun/slamfire/Destroy()
    cleanup_holder_state()
    return ..()

/obj/item/gun/ballistic/shotgun/slamfire/ComponentInitialize()
    . = ..()

    AddComponent(/datum/component/two_handed, wieldsound = "sound/weapons/Shotguns_reheated/slamfire/HandlingIN.ogg", unwieldsound = "sound/weapons/Shotguns_reheated/slamfire/HandlingOUT.ogg")

/obj/item/gun/ballistic/shotgun/slamfire/proc/get_twohanded()
    return GetComponent(/datum/component/two_handed)

/obj/item/gun/ballistic/shotgun/slamfire/proc/is_in_stance()
    var/datum/component/two_handed/TH = get_twohanded()

    if(!TH)
        return FALSE
    return TH.wielded

/obj/item/gun/ballistic/shotgun/slamfire/proc/get_holder()

    if(isliving(loc))
        return loc
    return null

/obj/item/gun/ballistic/shotgun/slamfire/proc/cleanup_holder_state(mob/living/user)

    if(!user)
        user = get_holder()
    if(!user)
        return
    user.remove_movespeed_modifier(/datum/movespeed_modifier/slamfire)
    user.remove_movespeed_modifier(/datum/movespeed_modifier/slamfire_mid)
    user.remove_movespeed_modifier(/datum/movespeed_modifier/slamfire_frenzy)

/obj/item/gun/ballistic/shotgun/slamfire/proc/update_stance_state(mob/living/user)

    if(!user)
        return
    cleanup_holder_state(user)
    if(!is_in_stance())
        return
    user.add_movespeed_modifier(/datum/movespeed_modifier/slamfire)

/obj/item/gun/ballistic/shotgun/slamfire/equipped(mob/user, slot)
    . = ..()

/obj/item/gun/ballistic/shotgun/slamfire/dropped(mob/user)
    . = ..()
    cleanup_holder_state(user)

/obj/item/gun/ballistic/shotgun/slamfire/proc/on_wield(obj/item/source, mob/living/user)
    SIGNAL_HANDLER

    cleanup_holder_state(user)
    user.add_movespeed_modifier(/datum/movespeed_modifier/slamfire)

/obj/item/gun/ballistic/shotgun/slamfire/proc/on_unwield(obj/item/source, mob/living/user)
    SIGNAL_HANDLER

    cleanup_holder_state(user)

/obj/item/gun/ballistic/shotgun/slamfire/AltClick(mob/living/user)
    if(!istype(user))
        return FALSE
    if(!user.canUseTopic(src, BE_CLOSE, ismonkey(user)))
        return FALSE
    if(item_flags & IN_STORAGE)
        return FALSE
    if(loc != user)
        return FALSE

    var/datum/component/two_handed/TH = get_twohanded()
    if(!TH)
        return FALSE

    if(TH.wielded)
        TH.unwield(user)
    else
        TH.wield(user)

    return TRUE

/obj/item/gun/ballistic/shotgun/slamfire/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, stam_cost = 0)
    update_jam_stress()
    update_stress_effects()

    if(uses_jam)

        if(!can_fire_check(user))
            return FALSE
        if(try_jam(user))
            return FALSE

    var/local_spread = bonus_spread
    var/local_stamina = stam_cost

    local_spread += round(jam_stress * (is_in_stance() ? 0.14 : 0.32))
    local_stamina += round(jam_stress * 0.04)

    if(!is_in_stance())
        local_spread += 12

    var/result = ..(
        target,
        user,
        message,
        params,
        zone_override,
        local_spread,
        local_stamina
    )
    if(!result)
        return FALSE

    jam_stress += round(16 * jam_multiplier)
    if(!is_in_stance())
        jam_stress += 12
    update_stress_effects()

    if(is_in_stance())
        var/pump_speed = auto_pump_delay
        if(jam_stress >= 50)
            pump_speed = 3
        if(jam_stress >= 90)
            pump_speed = 2
        addtimer(CALLBACK(src, PROC_REF(safe_auto_pump), user), pump_speed)
    return TRUE

/obj/item/gun/ballistic/shotgun/slamfire/proc/safe_auto_pump(mob/living/user)

    if(QDELETED(src))
        return
    if(!user)
        return
    if(loc != user)
        return
    if(!is_in_stance())
        return
    pump(user, FALSE, TRUE)

/obj/item/gun/ballistic/shotgun/slamfire/attackby(obj/item/A, mob/user, params)
	..()
	if(A.tool_behaviour == TOOL_SAW || istype(A, /obj/item/gun/energy/plasmacutter))
		sawoff(user)
	if(istype(A, /obj/item/melee/transforming/energy))
		var/obj/item/melee/transforming/energy/W = A
		if(W.active)
			sawoff(user)

/obj/item/gun/ballistic/shotgun/slamfire/on_sawoff(mob/user)
	. = ..()

	recoil += 1
	spread += 2

/obj/item/gun/ballistic/shotgun/slamfire/update_icon()
    . = ..()
    if(current_skin)
        icon_state = unique_reskin[current_skin]["icon_state"] + (sawn_off ? "-sawn" : "") + (suppressed ? "-suppressed" : "") + (chambered ? "" : "-e")
    else
        icon_state = initial(icon_state) + (sawn_off ? "-sawn" : "") + (suppressed ? "-suppressed" : "") + (chambered ? "" : "-e")

/obj/item/gun/ballistic/shotgun/slamfire/lethal
    mag_type = /obj/item/ammo_box/magazine/internal/shot/lethal

/obj/item/gun/ballistic/shotgun/slamfire/traitor
    name = "M-156 'Hell-Stitch'"
    desc = "Тяжело модифицированный полицейский дробовик, обёрнутый стальной проволкой. Идёт в комплекте с лазерным штык-ножом."
    icon = 'icons/obj/guns/ShotgunsReheated.dmi'
    icon_state = "HellStitch"
    item_state = "hellstitch-wielded"
    fire_delay = 5
    can_suppress = FALSE //Зачем менять эксклюзивный модуль на глушитель?
    can_bayonet = TRUE
    w_class = WEIGHT_CLASS_HUGE //Нельзя положить на спину для большей сложности в обращении.
    var/mob/living/bound_user
    var/frenzy = 0
    var/max_frenzy = 300
    var/frenzy_stage = 0
    var/previous_frenzy_stage = 0
    var/overload_active = FALSE
    var/overload_end_time = 0
    var/frenzy_decay_delay = 30 // 3 секунды
    var/frenzy_reset_time = 1200 //2 минуты
    var/last_decay_tick = 0
    var/last_damage_time = 0
    var/last_jitter = 0

    var/list/stage_up_bank = list(
        'sound/weapons/Shotguns_reheated/slamfire/Hellstitch/inject1.ogg',
        'sound/weapons/Shotguns_reheated/slamfire/Hellstitch/inject2.ogg',
        'sound/weapons/Shotguns_reheated/slamfire/Hellstitch/inject3.ogg'
    )

    var/list/stage_down_bank = list(
        'sound/weapons/Shotguns_reheated/slamfire/Hellstitch/fade1.ogg',
        'sound/weapons/Shotguns_reheated/slamfire/Hellstitch/fade2.ogg',
        'sound/weapons/Shotguns_reheated/slamfire/Hellstitch/fade3.ogg'
    )

    var/list/DemonChatter_bank = list(
		'sound/weapons/Shotguns_reheated/slamfire/Hellstitch/DemonChatter1.ogg',
		'sound/weapons/Shotguns_reheated/slamfire/Hellstitch/DemonChatter2.ogg',
		'sound/weapons/Shotguns_reheated/slamfire/Hellstitch/DemonChatter3.ogg'
	)

    var/list/frenzy_emote_bank = list(
        "laugh",
        "psychoticshort",
        "psychotic",
		"giggle",
        "gasp"
    )

    var/list/stage_up_text_bank = list(
        "УБЕЙ ИХ.",
        "ЕЩЁ, ЕЩЁ!",
        "БЫСТРЕЕ!",
        "РВИ И КРОМСАЙ!",
        "ОНИ БОЛЬШЕ НЕ ЖИЛЬЦЫ.",
        "НЕ УХОДИ ВО ТЬМУ БЕЗ ОГНЯ!",
        "СДОХНИ, СДОХНИ, СДОХНИ!!",
        "СМОТРИ, КАК ОНИ ДРОЖАТ!",
        "ТЫ ИХ ВИДИШЬ?! ОНИ ПОВСЮДУ!",
        "НЕ ДАЙ ИМ ЗАГНАТЬ СЕБЯ В УГОЛ!!",
        "ПУСТЬ УМОЮТСЯ СОБСТВЕННОЙ КРОВЬЮ.",
        "ПУТИ НАЗАД НЕТ."
    )

    var/list/stage_down_text_bank = list(
        "Лихорадка окончилась...",
        "Ваш пульс замедляется.",
        "Вы чуствуете себя опустошённым.",
        "Реальность снова давит на плечи.",
        "Холод пробирает до костей.",
        "Тишина... слишком тихо.",
        "Руки не перестают дрожать.",
        "Дыхание восстанавливается, но руки всё ещё дрожат.",
        "Синхронизация убывает.",
        "Шум утихает..."
    )

    var/last_stage_sound = 0
    var/stage_sound_cooldown = 20
    var/processing_active = FALSE
    var/last_emote = 0
    var/emote_cooldown = 30
    var/frenzy_fullscreen_category = "slamfire_frenzy"
    var/overload_mood_category = "slamfire_overload"
    var/last_voice = 0
    var/voice_cooldown = 60

    var/list/voice_pickup_bank = list(
        "Вот ты где.",
        "Владелец. Отлично. Теперь за дело.",
        "Мы не закончили здесь.",
        "Нейроинтерфейс активен. Начало работы...",
        "Биометрическая связь установлена. Оператор идентифицирован.",
        "Датчики функционируют. Подача реагента возобновлена."
    )

    var/list/voice_drop_bank = list(
        "Не оставляй меня без дела.",
        "Подбери меня обратно.",
        "Внимание: Потеря биометрического контакта.",
        "Автономный режим активирован. Не заставляй меня удаленно выжечь твою нервную систему.",
        "Разрыв связи. Мои данные бесценны, а твоя жизнь — нет. Вернись.",
        "Внимание: Потеря оператора.",
        "Твоя сила всё ещё в моих руках.",
        "Мы только теряем время."
    )

    var/list/voice_stage_up_bank = list(
        "Синхронизация повышена.",
        "Эта власть опьяняет, не так ли?",
        "Я приведу тебя к победе.",
        "Усиленная доза стимуятора введена.",
        "Внимание: Выделение адреналина превышает норму. Что очень хорошо.",
        "Не останавливайся."
    )

    var/list/voice_overload_bank = list(
        "Синхронизация завершена.",
        "Теперь мы единое целое.",
        "Задай им жару.",
        "ЗАВОДСКИЕ ЛИМИТЫ СНЯТЫ. ПРИСТУПИТЬ К УНИЧТОЖЕНИЮ БИОЦЕЛЕЙ.",
        "Ограничители мощности отключены. Продолжить тестирование.",
        "Образцы собраны. Инициализировать систему поощрения..."
    )

    var/list/voice_overload_stop = list(
        "Цикл повторяется.",
        "Критический перегрев систем. Б---Ь, твой мозг почти спекся...",
        "Пульс превышает физические возможности, ввод бета-адреноблокатора...",
        "Синхронизация разорвана. Недостаточно образцов.",
        "Процесс завершён. Запуск повторного цикла...",
        "Энергоядро разряжено. Охлаждение плазменных плат. Постарайся удержать сознание."
    )

/obj/item/gun/ballistic/shotgun/slamfire/traitor/Initialize(mapload)
    . = ..()
    var/obj/item/kitchen/knife/combat/laser_bayonet/B
    B = new(src)
    bayonet = B
    update_icon()

/obj/item/gun/ballistic/shotgun/slamfire/traitor/attackby(obj/item/A, mob/user, params) //зачем вообще делать обрез из выскокотехнологичного оружия? Ты все провода обрежешь.
    if(A.tool_behaviour == TOOL_SAW || istype(A, /obj/item/gun/energy/plasmacutter))
        to_chat(user, "<span class='notice'>Оружие выглядит слишком технологичным, я точно что-то сломаю.</span>")
        return TRUE
    if(istype(A, /obj/item/melee/transforming/energy))
        var/obj/item/melee/transforming/energy/W = A
        if(W.active)
            to_chat(user, "<span class='notice'>Оружие выглядит слишком технологичным, я точно что-то сломаю.</span>")
            return TRUE
    return ..()

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/speak(message, force = FALSE)
    if(!message)
        return
    if(last_voice && !force && world.time < last_voice + voice_cooldown)
        return
    last_voice = world.time
    say(message)
    playsound(get_turf(src), pick(DemonChatter_bank), 70, FALSE)

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/speak_voice(list/lines, force = FALSE)
    if(!lines || !lines.len)
        return
    speak(pick(lines), force)

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/apply_overload_mood(mob/living/user)
    if(!user)
        return
    SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, overload_mood_category, /datum/mood_event/slamfire_overload)

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/clear_overload_mood(mob/living/user)
    if(!user)
        return
    SEND_SIGNAL(user, COMSIG_CLEAR_MOOD_EVENT, overload_mood_category)

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/start_frenzy_processing()

    if(processing_active)
        return

    processing_active = TRUE
    START_PROCESSING(SSobj, src)

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/stop_frenzy_processing()

    if(!processing_active)
        return

    processing_active = FALSE

    STOP_PROCESSING(SSobj, src)

/obj/item/gun/ballistic/shotgun/slamfire/traitor/Destroy()
    stop_frenzy_processing()

    if(bound_user && !QDELETED(bound_user))
        cleanup_combat_state(bound_user)
        clear_frenzy_overlay(bound_user)
    if(bound_user)
        clear_bond()
    return ..()

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/try_bind_user(mob/living/user)
    if(!bound_user)
        bind_user(user)
        return TRUE
    if(bound_user == user)
        return TRUE
    reject_user(user)
    return FALSE

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/bind_user(mob/living/user)
    bound_user = user
    RegisterSignal(bound_user, COMSIG_MOB_DEATH, PROC_REF(on_bound_user_death))
    RegisterSignal(bound_user, COMSIG_PARENT_QDELETING, PROC_REF(on_bound_user_death))
    user.apply_damage(10, BRUTE, BODY_ZONE_L_ARM)
    user.apply_damage(10, BRUTE, BODY_ZONE_R_ARM)
    shake_camera(user, 2, 2)
    playsound(user, 'sound/weapons/Shotguns_reheated/slamfire/Hellstitch/initialization.ogg', 70, FALSE)
    to_chat(user, span_userdanger("Что-то впивается в ладони!"))

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/reject_user(mob/living/user)
    to_chat(user, span_userdanger("[src] отвергает твою хватку."))
    playsound(user, 'sound/weapons/Shotguns_reheated/shared/jam_warning.ogg', 70, TRUE)
    var/datum/component/two_handed/TH = get_twohanded()
    TH?.unwield(user)
    addtimer(CALLBACK(user, TYPE_PROC_REF(/mob, dropItemToGround), src, TRUE), 1)

/obj/item/gun/ballistic/shotgun/slamfire/traitor/on_wield(obj/item/source, mob/living/user)
    cleanup_holder_state(user)

    if(!try_bind_user(user))
        return
    sync_frenzy_state(user, FALSE)

/obj/item/gun/ballistic/shotgun/slamfire/traitor/on_unwield(obj/item/source, mob/living/user)
    ..()
    cleanup_holder_state(user)
    cleanup_combat_state(user)

/obj/item/gun/ballistic/shotgun/slamfire/traitor/pickup(mob/user)
    . = ..()

    if(!isliving(user))
        return

    if(!bound_user)
        try_bind_user(user)
    else if(bound_user != user)
        reject_user(user)

    speak_voice(voice_pickup_bank)

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/clear_bond()
    if(bound_user && !QDELETED(bound_user))
        clear_frenzy_overlay(bound_user)
        clear_overload_mood(bound_user)
        UnregisterSignal(bound_user, list(
            COMSIG_MOB_DEATH,
            COMSIG_PARENT_QDELETING
        ))
    bound_user = null
    overload_active = FALSE
    overload_end_time = 0
    frenzy = 0
    frenzy_stage = 0
    previous_frenzy_stage = 0
    jam_multiplier = get_frenzy_jam_multiplier()
    stop_frenzy_processing()

/obj/item/gun/ballistic/shotgun/slamfire/traitor/dropped(mob/user)
    . = ..()

    if(user)
        cleanup_combat_state(user)
    speak_voice(voice_drop_bank)

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/play_stage_feedback(mob/living/user, ascending = TRUE)

    if(world.time < last_stage_sound + stage_sound_cooldown)
        return
    last_stage_sound = world.time

    if(ascending)
        playsound(user, pick(stage_up_bank), 60, FALSE)
        var/msg = pick(stage_up_text_bank)
        user.visible_message(
            span_warning("Дыхание [user] становится более неровным."),
            span_userdanger(msg)
        )
    else
        playsound(user, pick(stage_down_bank), 60, FALSE)
        var/msg = pick(stage_down_text_bank)
        user.visible_message(
            span_notice("Похоже что [user] немного успокаивается."),
            span_warning(msg)
        )

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/trigger_frenzy_emote(mob/living/user)

    if(!user)
        return
    if(world.time < last_emote + emote_cooldown)
        return
    last_emote = world.time
    var/chosen_emote = pick(frenzy_emote_bank)
    user.emote(chosen_emote)

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/update_combat_state(mob/living/user)

    if(!user)
        return

    user.remove_movespeed_modifier(/datum/movespeed_modifier/slamfire)
    user.remove_movespeed_modifier(/datum/movespeed_modifier/slamfire_mid)
    user.remove_movespeed_modifier(/datum/movespeed_modifier/slamfire_frenzy)

    if(is_in_stance())
        switch(frenzy_stage)
            if(0 to 2)
                user.add_movespeed_modifier(/datum/movespeed_modifier/slamfire)
            if(3 to 4)
                user.add_movespeed_modifier(/datum/movespeed_modifier/slamfire_mid)
            if(5)
                user.add_movespeed_modifier(/datum/movespeed_modifier/slamfire_frenzy)

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/cleanup_combat_state(mob/living/user)

    if(!user)
        return
    user.remove_movespeed_modifier(/datum/movespeed_modifier/slamfire)
    user.remove_movespeed_modifier(/datum/movespeed_modifier/slamfire_mid)
    user.remove_movespeed_modifier(/datum/movespeed_modifier/slamfire_frenzy)
    REMOVE_TRAIT(user, TRAIT_IGNOREDAMAGESLOWDOWN, "slamfire_frenzy")
    REMOVE_TRAIT(user, TRAIT_NOSOFTCRIT, "slamfire_frenzy")

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/on_bound_user_death()
    SIGNAL_HANDLER

    var/mob/living/user = bound_user
    if(user && !QDELETED(user))
        reset_frenzy(user)
        cleanup_combat_state(user)
    clear_bond()

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/get_frenzy_jam_multiplier()

    switch(frenzy_stage)
        if(0)
            return 1.3
        if(1)
            return 1.2
        if(2)
            return 1.0
        if(3)
            return 0.8
        if(4)
            return 0.6
        if(5)
            return 0.3

    return 1.4

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/get_stage_from_frenzy()

    if(frenzy >= 300)
        return 5
    if(frenzy >= 225)
        return 4
    if(frenzy >= 120)
        return 3
    if(frenzy >= 75)
        return 2
    if(frenzy >= 40)
        return 1
    return 0

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/get_frenzy_fire_delay()

    switch(frenzy_stage)
        if(0)
            return 3
        if(1)
            return 2.5
        if(2)
            return 2
        if(3)
            return 1.7
        if(4)
            return 1.4
        if(5)
            return 1

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/get_frenzy_overlay_power()
    if(frenzy <= 0)
        return 0
    return clamp(frenzy_stage, 1, 5)

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/update_frenzy_overlay(mob/living/user)
    if(!user)
        return
    if(user != bound_user)
        clear_frenzy_overlay(user)
        return
    var/power = get_frenzy_overlay_power()
    if(power <= 0)
        clear_frenzy_overlay(user)
        return
    user.overlay_fullscreen(frenzy_fullscreen_category, /atom/movable/screen/fullscreen/tiled/slamfire_frenzy, power)
    user.overlay_fullscreen("brute", /atom/movable/screen/fullscreen/scaled/brute, power)

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/clear_frenzy_overlay(mob/living/user)
    if(!user)
        return
    user.clear_fullscreen(frenzy_fullscreen_category, 5)
    user.clear_fullscreen("brute")

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/sync_frenzy_state(mob/living/user, announce_stage_change = TRUE)
    previous_frenzy_stage = frenzy_stage
    frenzy_stage = get_stage_from_frenzy()
    jam_multiplier = get_frenzy_jam_multiplier()
    fire_delay = get_frenzy_fire_delay()
    update_combat_state(user)
    update_frenzy_overlay(user)

    if(previous_frenzy_stage == frenzy_stage)
        return
    var/entered_overload = FALSE
    if(frenzy_stage >= 5 && !overload_active)
        enter_overload(user)
        entered_overload = TRUE
    if(!announce_stage_change)
        return
    if(frenzy_stage > previous_frenzy_stage)
        if(!entered_overload)
            speak_voice(voice_stage_up_bank, TRUE)
        play_stage_feedback(user, TRUE)
        trigger_frenzy_emote(user)
    else
        play_stage_feedback(user, FALSE)

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/recalculate_frenzy(mob/living/user)
    sync_frenzy_state(user)

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/feed_frenzy(mob/living/user, amount)

    if(amount <= 0)
        return
    if(!processing_active)
        start_frenzy_processing()
    frenzy = clamp(frenzy + amount, 0, max_frenzy)
    last_damage_time = world.time
    recalculate_frenzy(user)

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/enter_overload(mob/living/user)

    if(!user)
        return
    overload_active = TRUE
    overload_end_time = world.time + frenzy_reset_time
    apply_overload_mood(user)
    speak_voice(voice_overload_bank, TRUE)
    to_chat(user, span_boldwarning("ДОСТИГНУТА ПОЛНАЯ СИНХРОНИЗАЦИЯ."))
    user.emote("overload")
    user.playsound_local(src, 'sound/health/fastbeat.ogg', 80, TRUE)
    user.heal_overall_damage(20, 20)
    ADD_TRAIT(user, TRAIT_IGNOREDAMAGESLOWDOWN, "slamfire_frenzy")
    ADD_TRAIT(user, TRAIT_NOSOFTCRIT, "slamfire_frenzy")

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/reset_frenzy(mob/living/user)

    overload_active = FALSE
    overload_end_time = 0
    frenzy = 0
    clear_overload_mood(user)
    jam_stress += 35
    update_stress_effects()
    previous_frenzy_stage = frenzy_stage
    frenzy_stage = 0
    cleanup_combat_state(user)
    sync_frenzy_state(user, FALSE)
    clear_frenzy_overlay(user)

    if(user)
        to_chat(user, span_warning("Ваше тело резко выходит из синхронизации."))
        user.playsound_local(src, 'sound/health/slowbeat.ogg', 70, TRUE)
        user.adjustStaminaLoss(40)
        speak_voice(voice_overload_stop)
    stop_frenzy_processing()

/obj/item/gun/ballistic/shotgun/slamfire/traitor/process()
    ..()
    process_frenzy()

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/process_frenzy()

    var/mob/living/user = bound_user
    if(!user)
        stop_frenzy_processing()
        return
    if(QDELETED(user))
        clear_bond()
        return

    if(user.stat == DEAD)
        reset_frenzy(user)
        cleanup_combat_state(user)
        clear_bond()
        return

    if(overload_active && world.time >= overload_end_time)
        reset_frenzy(user)
        return

    if(frenzy <= 0)
        clear_frenzy_overlay(user)
        stop_frenzy_processing()
        return

    if(world.time >= last_decay_tick + frenzy_decay_delay)
        frenzy = max(0, frenzy - 2)
        last_decay_tick = world.time
        recalculate_frenzy(user)

    update_frenzy_jitter(user)

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/update_frenzy_jitter(mob/living/user)

    if(!user)
        return
    if(world.time < last_jitter + 8)
        return
    last_jitter = world.time
    switch(frenzy_stage)
        if(0 to 2)
            user.Jitter(3)
        if(3)
            user.Jitter(4)
        if(4)
            shake_camera(user, 2, 1)
            user.Jitter(8)
        if(5)
            shake_camera(user, 4, 2)
            user.Jitter(12)

/obj/item/gun/ballistic/shotgun/slamfire/traitor/shoot_live_shot(mob/living/user, pointblank = FALSE, mob/pbtarget, message = TRUE, stam_cost = 0)
    . = ..()
    if(!.)
        return FALSE
    if(!pointblank)
        return .
    if(!isliving(pbtarget))
        return .

    var/mob/living/L = pbtarget
    if(L.stat == DEAD)
        return .
    if(L == user)
        return .
    if(L.health < HEALTH_THRESHOLD_CRIT)
        feed_frenzy(user, 25)
    else
        feed_frenzy(user, 15)

    return .

/obj/item/gun/ballistic/shotgun/slamfire/traitor/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
    . = ..()
    if(!proximity_flag)
        return
    if(!isliving(target))
        return

    var/mob/living/L = target
    if(L.stat == DEAD)
        return
    on_melee_hit(user, L)

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/on_melee_hit(mob/living/user, mob/living/target)

    if(!user)
        return
    if(!target)
        return
    if(target == user)
        return
    var/mob/living/L = target
    if(L.health < HEALTH_THRESHOLD_CRIT)
        feed_frenzy(user, 25)
    else
        feed_frenzy(user, 15)

    var/heal_amt = 2 + round(frenzy * 0.01)
    user.heal_overall_damage(heal_amt, heal_amt)
    user.adjustStaminaLoss(-8)
    jam_stress = max(0, jam_stress - 10)
    update_stress_effects()

/obj/item/gun/ballistic/shotgun/slamfire/traitor/update_icon_state()
	if(current_skin)
		icon_state = "[unique_reskin[current_skin]["icon_state"]][chambered ? "" : "-e"]"
	else
		icon_state = "[initial(icon_state)][chambered ? "" : "-e"]"

/obj/item/gun/ballistic/shotgun/slamfire/traitor/examine(mob/user)
    . = ..()
/*
    if(!user?.client)
        return
    . += "<hr>"
    . += span_boldnotice("=== SLAMFIRE DIAGNOSTICS ===")
    . += span_notice("Bound user: [bound_user]")
    . += span_notice("Frenzy: [frenzy]/[max_frenzy]")
    . += span_notice("Stage: [frenzy_stage]")
    . += span_notice("Overload: [overload_active]")
    . += span_notice("Jam stress: [jam_stress]")
    . += span_notice("Jam multiplier: [jam_multiplier]")
    . += span_notice("Stance: [is_in_stance()]")
    . += span_notice("Last decay tick: [last_decay_tick]")
    . += span_notice("Last damage time: [last_damage_time]")
    if(overload_active)
        . += span_warning("Overload ends in: [max(0, round((overload_end_time - world.time) / 10))]s")
    if(frenzy_stage >= 5)
        . += span_userdanger("TERMINAL SYNCHRONIZATION")
    else if(frenzy_stage >= 3)
        . += span_warning("HIGH SYNCHRONIZATION")
    else if(frenzy_stage >= 1)
        . += span_notice("LOW SYNCHRONIZATION")
    else
        . += span_notice("DORMANT")
*/
///////////////////////
// BOLT ACTION RIFLE //
///////////////////////

/obj/item/gun/ballistic/shotgun/boltaction
	name = "\improper Mosin Nagant"
	desc = "This piece of junk looks like something that could have been used 700 years ago. It feels slightly moist."
	icon_state = "moistnugget"
	item_state = "moistnugget"
	slot_flags = 0 //no ITEM_SLOT_BACK sprite, alas
	inaccuracy_modifier = 0.5
	mag_type = /obj/item/ammo_box/magazine/internal/boltaction
	var/bolt_open = FALSE
	can_bayonet = TRUE
	knife_x_offset = 27
	knife_y_offset = 13

/obj/item/gun/ballistic/shotgun/boltaction/improvised
	name = "Makeshift 7.62mm Rifle"
	icon_state = "ishotgun"
	icon_state = "irifle"
	item_state = "shotgun"
	desc = "A bolt-action breechloaded rifle that takes 7.62mm bullets."
	mag_type = /obj/item/ammo_box/magazine/internal/boltaction/improvised
	can_bayonet = FALSE
	var/slung = FALSE

/obj/item/gun/ballistic/shotgun/boltaction/pump(mob/M)
	playsound(M, 'sound/weapons/shotgunpump.ogg', 60, 1)
	if(bolt_open)
		pump_reload(M)
	else
		pump_unload(M)
	bolt_open = !bolt_open
	update_icon()	//I.E. fix the desc
	return TRUE

/obj/item/gun/ballistic/shotgun/boltaction/attackby(obj/item/A, mob/user, params)
	if(!bolt_open)
		to_chat(user, "<span class='notice'>The bolt is closed!</span>")
		return
	. = ..()

/obj/item/gun/ballistic/shotgun/boltaction/examine(mob/user)
	. = ..()
	. += "The bolt is [bolt_open ? "open" : "closed"]."

/obj/item/gun/ballistic/shotgun/boltaction/improvised/attackby(obj/item/A, mob/user, params)
	..()
	if(istype(A, /obj/item/stack/cable_coil) && !sawn_off)
		if(A.use_tool(src, user, 0, 10, skill_gain_mult = EASY_USE_TOOL_MULT))
			slot_flags = ITEM_SLOT_BACK
			to_chat(user, "<span class='notice'>You tie the lengths of cable to the rifle, making a sling.</span>")
			slung = TRUE
			update_icon()
		else
			to_chat(user, "<span class='warning'>You need at least ten lengths of cable if you want to make a sling!</span>")

/obj/item/gun/ballistic/shotgun/boltaction/improvised/update_overlays()
	. = ..()
	if(slung)
		. += "[icon_state]sling"

/obj/item/gun/ballistic/shotgun/boltaction/enchanted
	name = "Enchanted Bolt Action Rifle"
	desc = "Careful not to lose your head."
	var/guns_left = 30
	var/gun_type
	mag_type = /obj/item/ammo_box/magazine/internal/boltaction/enchanted

/obj/item/gun/ballistic/shotgun/boltaction/enchanted/arcane_barrage
	name = "Arcane Barrage"
	desc = "Pew! Pew-pew!!"
	fire_sound = 'sound/weapons/emitter.ogg'
	pin = /obj/item/firing_pin/magic
	icon_state = "arcane_barrage"
	item_state = "arcane_barrage"
	can_bayonet = FALSE
	item_flags = NEEDS_PERMIT | DROPDEL
	flags_1 = NONE
	mag_type = /obj/item/ammo_box/magazine/internal/boltaction/enchanted/arcane_barrage

/obj/item/gun/ballistic/shotgun/boltaction/enchanted/Initialize(mapload)
	. = ..()
	bolt_open = TRUE
	pump()
	gun_type = type

/obj/item/gun/ballistic/shotgun/boltaction/enchanted/proc/discard_gun(mob/user)
	throw_at(pick(oview(7,get_turf(user))),1,1)
	user.visible_message("<span class='warning'>[user] tosses aside the spent rifle!</span>")

/obj/item/gun/ballistic/shotgun/boltaction/enchanted/arcane_barrage/discard_gun(mob/user)
	return

/obj/item/gun/ballistic/shotgun/boltaction/enchanted/attack_self()
	return

/obj/item/gun/ballistic/shotgun/boltaction/enchanted/shoot_live_shot(mob/living/user, pointblank = FALSE, mob/pbtarget, message = 1, stam_cost = 0)
	..()
	if(guns_left)
		var/obj/item/gun/ballistic/shotgun/boltaction/enchanted/GUN = new gun_type
		GUN.guns_left = guns_left - 1
		user.dropItemToGround(src, TRUE)
		user.swap_hand()
		user.put_in_hands(GUN)
	else
		user.dropItemToGround(src, TRUE)
	discard_gun(user)

/// AUTOMATIC SHOTGUNS
/obj/item/gun/ballistic/shotgun/automatic
    var/automatic_cycle = TRUE

/obj/item/gun/ballistic/shotgun/automatic/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, stam_cost = 0)
    var/result = ..()
    if(!result)
        return FALSE
    // Логика полуавтоматов
    if(automatic_cycle)
        // выброс гильзы
        if(chambered)
            chambered.forceMove(drop_location())
            chambered.bounce_away()
            chambered = null

        // сразу же зарядить новый патрон
        if(magazine && magazine.ammo_count())
            chambered = magazine.get_round()
    update_icon()
    return TRUE


/obj/item/gun/ballistic/shotgun/automatic/combat
	name = "Combat Shotgun"
	desc = "Современная модификация полуавтоматиеского дробовика со складным прикладом и предохранителем, предотвращающим выстрел в сложенном состоянии. Для близких знакомств."
	sawn_desc = " 'Чем больше шкаф, чем громче падает.' Эта мысль всегда помогала мне, когда я шёл сжигать станции Трейзен под знаменем киберсана... -Две крепости. Часть 2."
	icon = 'icons/obj/guns/ShotgunsReheated.dmi'
	icon_state = "Combat"
	sawn_icon_state = "Combat-sawn"
	item_state = "combat-wielded"
	fire_delay = 5
	fire_sound = 'sound/weapons/Shotguns_reheated/Semi-auto/Semifire.ogg'
	pumpsound = 'sound/weapons/Shotguns_reheated/Semi-auto/Semichamber.ogg'
	loadshell_sound = 'sound/weapons/Shotguns_reheated/Shared/Shellinsert2.ogg'
	mag_type = /obj/item/ammo_box/magazine/internal/shot/com
	uses_jam = TRUE
	can_bayonet = TRUE
	can_suppress = FALSE //Высокий шанс что будут ошибки определения веса с механикой приклада.
	jam_multiplier = 0.8
	w_class = WEIGHT_CLASS_NORMAL
	var/stock = FALSE
	var/stock_removed = FALSE
	var/extend_sound = 'sound/weapons/Shotguns_reheated/Semi-auto/Stockunfold.ogg'

/obj/item/gun/ballistic/shotgun/automatic/combat/AltClick(mob/living/user)
	if(!istype(user) || !user.canUseTopic(src, BE_CLOSE, ismonkey(user)) || item_flags & IN_STORAGE)
		return
	toggle_stock(user)
	update_item_state()
	. = ..()

/obj/item/gun/ballistic/shotgun/automatic/combat/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Alt-click чтобы разложить приклад.</span>"

/obj/item/gun/ballistic/shotgun/automatic/combat/attackby(obj/item/A, mob/user, params)
	..()
	if(A.tool_behaviour == TOOL_SAW || istype(A, /obj/item/gun/energy/plasmacutter))
		sawoff(user)
		update_item_state()
	if(istype(A, /obj/item/melee/transforming/energy))
		var/obj/item/melee/transforming/energy/W = A
		if(W.active)
			sawoff(user)
			update_item_state()

/obj/item/gun/ballistic/shotgun/automatic/combat/proc/toggle_stock(mob/living/user)
	if(stock_removed)
		return
	stock = !stock
	if(stock)
		w_class = WEIGHT_CLASS_HUGE
		to_chat(user, "Вы раскладываете приклад.")
		recoil = 1
		spread = 0
		shake_camera (user, 0.5, 0.5)
	else
		w_class = WEIGHT_CLASS_NORMAL
		to_chat(user, "Вы складываете приклад.")
		recoil = 5
		spread = 2
	playsound(src.loc, extend_sound, 50, 1)
	update_icon()
	update_item_state()
	shake_camera (user, 0.5, 0.5)

/obj/item/gun/ballistic/shotgun/automatic/combat/proc/update_item_state()
	var/state = initial(item_state)
	if(!stock && !stock_removed)
		sawn_item_state += "-folded"
	item_state = state

/obj/item/gun/ballistic/shotgun/automatic/combat/afterattack(atom/target, mob/living/user, flag, params)
    if(!stock_removed && !stock)
        shoot_with_empty_chamber(user)
        to_chat(user, "<span class='warning'>[src] не выстрелит со сложенным прикладом!</span>")
        return

    . = ..()
    update_icon()
    update_item_state()

/obj/item/gun/ballistic/shotgun/automatic/combat/on_sawoff(mob/user)
    . = ..()

    stock_removed = TRUE
    stock = TRUE
    recoil += 2
    spread += 1
    update_icon()
    update_item_state()
/obj/item/gun/ballistic/shotgun/automatic/combat/update_icon()
	. = ..()

	var/state = initial(icon_state)
	if(sawn_off)
		state += "-sawn"
	if(!stock && !stock_removed)
		state += "-folded"
	if(!chambered)
		state += "-e"
	icon_state = state

/obj/item/gun/ballistic/shotgun/automatic/combat/pindicate
	pin = /obj/item/firing_pin/implant/pindicate

/obj/item/gun/ballistic/shotgun/automatic/combat/warden
	name = "Warden's Combat Shotgun"
	desc = "Модифицированная версия полуавтоматического боевого дробовика со складным прикладом и предохранителем, предотвращающим выстрел в сложенном состоянии. Предназначен для ближнего боя."
	fire_delay = 3
	spread = 2

/obj/item/gun/ballistic/shotgun/automatic/traitor
	name = "HC-X 'Aspis'"
	desc = "Дешёвый полуавтоматический дробовик, созданный для быстрых устранений целей. Лёгкий, компактный и брезгливый. Имеет резьбу для установки дульных устройств."
	icon = 'icons/obj/guns/ShotgunsReheated.dmi'
	icon_state = "Aspis"
	item_state = "aspis-wielded"
	fire_delay = 3
	fire_sound = 'sound/weapons/Shotguns_reheated/Semi-auto/Semifire.ogg'
	pumpsound = 'sound/weapons/Shotguns_reheated/Devastator/devastatorchamber.ogg'
	loadshell_sound = 'sound/weapons/Shotguns_reheated/Shared/Shellinsertlight.wav'
	suppressed_fire_sound = 'sound/weapons/Shotguns_reheated/Devastator/devastatorsuppressed.ogg'
	mag_type = /obj/item/ammo_box/magazine/internal/shot/lethal
	can_suppress = TRUE
	uses_jam = TRUE
	jam_multiplier = 1
	ignore_twohand_requirement = TRUE
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/gun/ballistic/shotgun/automatic/traitor/update_icon()
	. = ..()
	var/state = "Aspis"
	if(suppressed)
		state += "-suppressed"
	if(!chambered)
		state += "-e"
	icon_state = state

/obj/item/gun/ballistic/shotgun/doublebarrel/hook
	name = "Hook Modified Sawn-Off Shotgun"
	desc = "Range isn't an issue when you can bring your victim to you."
	icon_state = "hookshotgun"
	item_state = "shotgun"
	mag_type = /obj/item/ammo_box/magazine/internal/shot/bounty
	w_class = WEIGHT_CLASS_BULKY
	weapon_weight = WEAPON_MEDIUM
	force = 16 //it has a hook on it
	attack_verb = list("slashed", "hooked", "stabbed")
	hitsound = 'sound/weapons/bladeslice.ogg'
	//our hook gun!
	var/obj/item/gun/magic/hook/bounty/hook
	var/toggled = FALSE

// hey you kids like
// LEVER GUNS?

/obj/item/gun/ballistic/shotgun/leveraction
	name = "Lever-Action Rifle"
	desc = "While lever-actions have been horribly out of date for hundreds of years now, \
	the reported potential versatility of .38 Special is worth paying attention to."
	fire_sound = "sound/weapons/revolvershot2.ogg"
	mag_type = /obj/item/ammo_box/magazine/internal/shot/levergun
	icon_state = "levercarabine"
	item_state = "leveraction"
	sawn_icon_state = "maresleg"

/obj/item/gun/ballistic/shotgun/leveraction/on_sawoff(mob/user)
	magazine.max_ammo-- // sawing off drops from 7+1 to 6+1

/obj/item/gun/ballistic/shotgun/leveraction/update_icon_state()
	if(current_skin)
		icon_state = "[unique_reskin[current_skin]["icon_state"]][sawn_off ? "-sawn" : ""][chambered ? "" : "-e"]"
	else
		icon_state = "[initial(icon_state)][sawn_off ? "-sawn" : ""][chambered ? "" : "-e"]"

/obj/item/gun/ballistic/shotgun/brush
	name = "Brush Gun"
	desc = "While lever-actions have been horribly out of date for hundreds of years now, \
	putting a nicely sized hole in a man-sized target with a .45-70 round has stayed relatively timeless."
	icon_state = "brushgun"
	item_state = "leveraction"
	mag_type = /obj/item/ammo_box/magazine/internal/shot/levergun/brush
	fire_sound = "sound/weapons/revolvershot2.ogg"
