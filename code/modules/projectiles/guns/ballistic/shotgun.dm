/obj/item/gun/ballistic/shotgun
	name = "Shotgun"
	desc = "Традиционный дробовик с деревянным прикладом и подствольным магазином на четыре патрона."
	icon_state = "shotgun"
	item_state = "shotgun-wielded"
	fire_sound = "sound/weapons/gunshotshotgunshot.ogg"
	w_class = WEIGHT_CLASS_BULKY
	recoil = 1
	force = 10
	flags_1 =  CONDUCT_1
	slot_flags = ITEM_SLOT_BACK
	mag_type = /obj/item/ammo_box/magazine/internal/shot
	casing_ejector = FALSE
	var/recentpump = 0 // to prevent spammage
	var/pumpsound = "sound/weapons/shotgunpump.ogg" //Звуки досыла патрона
	var/loadshell_sound = 'sound/weapons/shotguninsert.ogg' //Звуки заряжания патрона внутрь
	var/jammed = FALSE //Имеет ли осечку
	var/jam_multiplier = 0  //множитель стресса
	var/last_fire_time = 0 //Проверка когда был произведён последний выстрел
	var/uses_jam = FALSE //Будет ли дробовик иметь осечки
	var/jam_stress = 0 //Показатель стресса.
	var/last_stress_decay = 0 //Падение стресса со временем
	var/stress_pump_delay = 0
	var/stress_stam_cost = 0
	var/stress_spread_mult = 0

	weapon_weight = WEAPON_HEAVY
	sawn_item_state = "sawnshotgun"

/obj/item/gun/ballistic/shotgun/attackby(obj/item/A, mob/user, params)
	. = ..()
	if(.)
		return
	var/num_loaded = magazine.attackby(A, user, params, 1)
	if(num_loaded)
		to_chat(user, "<span class='notice'>You load [num_loaded] shell\s into \the [src]!</span>")
		playsound(user, loadshell_sound, 60, 1)
		A.update_icon()
		update_icon()

	update_jam_stress()

/obj/item/gun/ballistic/shotgun/process_chamber(mob/living/user, empty_chamber = 0)
	return ..() //changed argument value

/obj/item/gun/ballistic/shotgun/proc/update_jam_stress()

    if(!uses_jam)
        return

    if(jam_stress <= 0)
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

    if(jam_stress >= 100)
        jammed = TRUE

/obj/item/gun/ballistic/shotgun/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, stam_cost = 0)

    if(uses_jam)
        if(!can_fire_check(user))
            return

        if(try_jam(user))
            return
    bonus_spread += stress_spread_mult
    stam_cost += stress_stam_cost
    var/result = ..()

    if(result)
        last_fire_time = world.time
        jam_stress += round(20 * jam_multiplier)
        update_jam_stress()
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

    if(jam_stress >= 100)
        jammed = TRUE
        to_chat(user, "<span class='warning'>Оружие заклинило!</span>")
        return TRUE

    var/chance = 0
// Чем больше стресса, тем больший шанс на осечку. Корректирует темп стрельбы игрока
    if(jam_stress >= 90)
        chance = 30
    else if(jam_stress >= 80)
        chance = 15
    else if(jam_stress >= 70)
        chance = 5

    if(prob(chance))
        jammed = TRUE
        to_chat(user, "<span class='warning'>Осечка!</span>")
        return TRUE

    return FALSE

/obj/item/gun/ballistic/shotgun/proc/clear_jam(mob/living/user)
	if(!jammed)
		return FALSE

	to_chat(user, "<span class='notice'>Ты устраняешь осечку. Оружие готово к использованию!</span>")
	balloon_alert(user, "С заметным усилием взводит оружие!")
	playsound(user, pumpsound, 60, TRUE)
	jam_stress = max(0, jam_stress - 40)
	// используем существующую механику
	pump_unload(user)
	pump_reload(user)

	jammed = FALSE
	update_icon()
	return TRUE


/obj/item/gun/ballistic/shotgun/can_shoot()
	if(!chambered)
		return FALSE
	return (chambered.BB ? 1 : 0)

/obj/item/gun/ballistic/shotgun/attack_self(mob/living/user)
    if(recentpump > world.time)
        return
    if(IS_STAMCRIT(user))
        to_chat(user, "<span class='warning'>Ты слишком устал чтобы это сделать.</span>")
        return
    if(jammed)
        if(clear_jam(user))
            return
    pump(user, TRUE)
    if(HAS_TRAIT(user, TRAIT_FAST_PUMP))
        recentpump = world.time + 2
    else if(!user.UseStaminaBuffer(2, warn = TRUE))
        return
    recentpump = world.time + 4 + stress_pump_delay
    update_jam_stress()
/obj/item/gun/ballistic/shotgun/proc/pump(mob/M, visible = TRUE, play_sound = TRUE)
	if(visible)
		M.visible_message("<span class='warning'>[M] racks [src].</span>", "<span class='warning'>You rack [src].</span>")

	if(play_sound)
		playsound(M, pumpsound, 60, 1)

	pump_unload(M)
	pump_reload(M)
	update_icon()
	jam_stress = max(0, jam_stress - 10)
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

    if(uses_jam) //Детальная инфррмция о механике. Для отладки
        . += "<span class='notice'>["DEBUG JAM STATE"]</span>"
        . += "Stress: [jam_stress]"
        . += "Jammed: [jammed ? "YES" : "NO"]"

        if(jam_stress >= 100)
            . += "<span class='warning'>CRITICAL: JAM THRESHOLD EXCEEDED</span>"
        else if(jam_stress >= 70)
            . += "<span class='warning'>HIGH RISK</span>"
        else if(jam_stress >= 40)
            . += "Moderate stress"
        else
            . += "Stable"

/obj/item/gun/ballistic/shotgun/lethal
	mag_type = /obj/item/ammo_box/magazine/internal/shot/lethal

// RIOT SHOTGUN //

/obj/item/gun/ballistic/shotgun/riot //for spawn in the armory
	name = "Riot Shotgun"
	desc = "A sturdy shotgun with a longer magazine and a fixed tactical stock designed for non-lethal riot control."
	icon_state = "riotshotgun"
	item_state = "gun_wielded"
	pumpsound = "sound/weapons/Shotguns_reheated/Riot/Riotchamber.ogg"
	fire_sound = "sound/weapons/Shotguns_reheated/Riot/Riotfire.ogg"
	loadshell_sound = 'sound/weapons/Shotguns_reheated/shared/Shellinsert1.ogg'
	fire_delay = 8
	uses_jam = TRUE
	jam_multiplier = 0.6
	mag_type = /obj/item/ammo_box/magazine/internal/shot/riot
	sawn_desc = "Come with me if you want to live."
	spread = 0.4
	unique_reskin = list(
		"Tactical" = list("icon_state" = "riotshotgun"),
		"Wood Stock" = list("icon_state" = "wood_riotshotgun")
	)

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
	desc = "A Scarborough riot control shotgun fitted with a crimson furnishing and a wooden tactical stock. You swear you've seen this model elsewhere before..."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "riotshotgun_syndie"
	item_state = "riot_shotgun_syndie"
	fire_delay = 6
	uses_jam = TRUE
	can_suppress = FALSE

//Dual Feed Shotgun

/obj/item/gun/ballistic/shotgun/dual_tube
	name = "Cycler Shotgun"
	desc = "An advanced shotgun with two separate magazine tubes, allowing you to quickly toggle between ammo types."
	icon_state = "cycler"
	mag_type = /obj/item/ammo_box/magazine/internal/shot/tube
	w_class = WEIGHT_CLASS_HUGE
	uses_jam = TRUE
	fire_delay = 8
	fire_sound = 'sound/weapons/Shotguns_reheated/Pumpaction/Pumpfire.ogg'
	pumpsound = 'sound/weapons/Shotguns_reheated/Pumpaction/Pumpchamber.ogg'
	loadshell_sound = 'sound/weapons/Shotguns_reheated/Shared/Shellinstertplastic.wav'

	var/toggled = FALSE
	var/obj/item/ammo_box/magazine/internal/shot/alternate_magazine

/obj/item/gun/ballistic/shotgun/dual_tube/Initialize(mapload)
	. = ..()
	if(!alternate_magazine)
		alternate_magazine = new mag_type(src)

/obj/item/gun/ballistic/shotgun/dual_tube/attack_self(mob/living/user)
	return ..()

/obj/item/gun/ballistic/shotgun/dual_tube/proc/toggle_tube(mob/living/user)
	var/old = magazine
	magazine = alternate_magazine
	alternate_magazine = old

	toggled = !toggled

	to_chat(user, "Вы переключаете магазины. Метка на селекторе горит [toggled ? "<span style='color: #25b334'>зелёным</span>" : "<span style='color: #ff0000'>красным</span>"]!")
	balloon_alert(user, "Вскидывает пушку и переключает подачу!")
	playsound(user, 'sound/weapons/Shotguns_reheated/shared/Cyclerswap.ogg', 60, 1)

/obj/item/gun/ballistic/shotgun/dual_tube/AltClick(mob/living/user)
	if(!istype(user) || !user.canUseTopic(src, BE_CLOSE, ismonkey(user)))
		return

	toggle_tube(user)
	return TRUE
/// Я в рот ебал кодить эту пушку, но она очень крутая. Обожаю ультранасилие(Над своей жопой) - RzW
/obj/item/gun/ballistic/shotgun/dp12
    name = "Recycler-12"
    desc = "Два дробовика в одной цельнометалической оболочке. Чертёж был импортирован извне, от этой адской машины несёт Марсианским духом за километр. Сборка оставляет желать лучшего, от того это и опытный образец."
    icon_state = "cycler"

    mag_type = /obj/item/ammo_box/magazine/internal/shot/tube
    uses_jam = TRUE
    jam_multiplier = 0.8
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
        if(!can_fire_check(user))
            return
        if(try_jam(user))
            return

    var/fired = FALSE

    // Сначала первый, потом второй ствол.
    if(chambered && chambered.BB)
        chambered.fire_casing(target, user)
        fired = TRUE
       	shake_camera(user, 2, 2)
    else if(secondary_chambered && secondary_chambered.BB)
        secondary_chambered.fire_casing(target, user)
        fired = TRUE
       	shake_camera(user, 3, 3)

    if(!fired)
        return ..() // защита от пустого клика

    playsound(user, fire_sound, 50, TRUE)
    user.do_attack_animation(src)

    last_fire_time = world.time
    jam_stress += round(15 * jam_multiplier)

    update_icon()
    return TRUE


/obj/item/gun/ballistic/shotgun/dp12/pump(mob/M, visible = TRUE, play_sound = TRUE)

    if(clear_jam_dp12(M))
        return TRUE

    if(visible)
        M.visible_message("[M] racks [src].", "You rack [src].")

    if(play_sound)
        playsound(M, pumpsound, 60, TRUE)

    pump_unload_dual(M)
    pump_reload_dual(M)

    jam_stress = max(0, jam_stress - 10)

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

/obj/item/gun/ballistic/shotgun/dp12/proc/clear_jam_dp12(mob/living/user)

    if(!jammed)
        return FALSE

    to_chat(user, "<span class='notice'>Ты устраняешь осечку. Оружие готово к использованию!</span>")
    playsound(user, pumpsound, 60, TRUE)

    pump_unload_dual(user)
    pump_reload_dual(user)

    jam_stress = max(0, jam_stress - 25)
    jammed = FALSE

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

        to_chat(user, "<span class='notice'>You load a shell into [src].</span>")
        playsound(user, loadshell_sound, 60, TRUE)

        A.update_icon()
        update_icon()
        return TRUE

    return FALSE


/// ДЕБАГ, ЗАКОММЕНТИТЬ ПОСЛЕ ТЕСТОВ
/obj/item/gun/ballistic/shotgun/dp12/examine(mob/user)
    . = ..()
    if(chambered)
        . += "Primary barrel: [chambered.BB ? "live" : "spent"]"
    if(secondary_chambered)
        . += "Secondary barrel: [secondary_chambered.BB ? "live" : "spent"]"

/obj/item/gun/ballistic/shotgun/dp12/traitor
    name = "Human Recycler"
    desc = "Особая версия двуствольного дробовика сделанная под заказ неким Хейлом. Все детали были подогнанны идеально, а конструкция внушает доверие. Гравировка на корпусе гласит: 'Шок и трепет - лучшее лекарство. Рви и кромсай пока не иссякнут!'"
    icon_state = "cycler"
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

/obj/item/gun/ballistic/shotgun/dp12/traitor/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 2, stam_cost = 0)

    if(!doubleshot_mode)
        return ..()
    if(!(chambered && chambered.BB) || !(secondary_chambered && secondary_chambered.BB))
        to_chat(user, "<span class='warning'>Оба ствола должны быть заряжены для синхронного выстрела!</span>")
        return
    if(!user.UseStaminaBuffer(sync_stamina_cost, warn = TRUE))
        return
    chambered.fire_casing(target, user)
    shake_camera(user, 6, 4)
    secondary_chambered.fire_casing(target, user)
    playsound(user, fire_sound, 75, TRUE)
// Sleep отвечает за задержу между выстрелами в синхронном режиме
    sleep(1.2)
    playsound(user, fire_sound, 75, TRUE)

// перчинка для выстрела
    user.do_attack_animation(src)
    shake_camera(user, 6, 6)
    user.adjustStaminaLoss(5)
    recoil = 7
    last_fire_time = world.time
    update_icon()
    return TRUE

/obj/item/gun/ballistic/shotgun/dp12/traitor/examine(mob/user)
    . = ..()
    . += "Alt-click чтобы сменить режим стрельбы."
    . += "Селектор стоит на: [doubleshot_mode ? "СИНХ." : "СТАНД."]"
//due to code weirdness, and the fact that a refactor is coming soon anyway, the barman's shotgun and maint shotgun are in revolver.dm

/// SLAMFIRE ДРОБОВИКИ

/obj/item/gun/ballistic/shotgun/slamfire
    name = "Slamfire shotgun"
    desc = "A reproduction of an old police shotgun with an unrestricted slamfire mechanism."
    icon_state = "riotshotgun"
    item_state = "gun_wielded"
    pumpsound = "sound/weapons/Shotguns_reheated/Riot/Riotchamber.ogg"
    fire_sound = "sound/weapons/Shotguns_reheated/Riot/Riotfire.ogg"
    loadshell_sound = 'sound/weapons/Shotguns_reheated/shared/Shellinsert1.ogg'
    mag_type = /obj/item/ammo_box/magazine/internal/shot
    uses_jam = TRUE
    jam_multiplier = 1.4
    fire_delay = 4
    can_bayonet = TRUE
    knife_x_offset = 30
    knife_y_offset = 12
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
    AddComponent(/datum/component/two_handed, force, force)

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
    var/datum/component/two_handed/TH = get_twohanded()
    if(TH?.wielded)
        TH.unwield(user)

/obj/item/gun/ballistic/shotgun/slamfire/dropped(mob/user)
    . = ..()
    cleanup_holder_state(user)

/obj/item/gun/ballistic/shotgun/slamfire/proc/on_wield(obj/item/source, mob/living/user)
    update_stance_state(user)
    to_chat(user, span_notice("You brace [src] against your shoulder."))

/obj/item/gun/ballistic/shotgun/slamfire/proc/on_unwield(obj/item/source, mob/living/user)
    update_stance_state(user)
    to_chat(user, span_warning("You relax your stance."))

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

/obj/item/gun/ballistic/shotgun/slamfire/traitor
    name = "Spray'n'Pray"
    desc = "A heavily modified slamfire shotgun wrapped in sharpened steel wire."
    fire_delay = 2
    var/mob/living/bound_user
    var/frenzy = 0
    var/max_frenzy = 200
    var/frenzy_stage = 0
    var/previous_frenzy_stage = 0
    var/overload_active = FALSE
    var/overload_end_time = 0
    var/frenzy_decay_delay = 30
    var/frenzy_reset_time = 1200
    var/last_decay_tick = 0
    var/last_damage_time = 0

    var/list/stage_up_bank = list(
        'sound/weapons/Shotguns_reheated/slamfire/VO/whisper1.ogg',
        'sound/weapons/Shotguns_reheated/slamfire/VO/whisper1.ogg',
        'sound/weapons/Shotguns_reheated/slamfire/VO/whisper1.ogg'
    )

    var/list/stage_down_bank = list(
        'sound/weapons/Shotguns_reheated/slamfire/VO/fade1.ogg',
        'sound/weapons/Shotguns_reheated/slamfire/VO/fade2.ogg',
        'sound/weapons/Shotguns_reheated/slamfire/VO/fade3.ogg'
    )

    var/list/frenzy_emote_bank = list(
        "laugh",
        "heavybreath",
        "twitch",
        "gasp"
    )

    var/list/stage_up_text_bank = list(
        "KILL.",
        "MORE.",
        "FASTER.",
        "THEY ARE WEAK.",
        "DON'T STOP."
    )

    var/list/stage_down_text_bank = list(
        "It's fading...",
        "Your pulse slows.",
        "You feel hollow.",
        "Synchronization weakening.",
        "The noise disappears."
    )

    var/last_stage_sound = 0
    var/stage_sound_cooldown = 50
    var/processing_active = FALSE
    var/last_emote = 0
    var/emote_cooldown = 80

/obj/item/gun/ballistic/shotgun/slamfire/traitor/Initialize(mapload)
    . = ..()
    var/obj/item/kitchen/knife/combat/laser_bayonet/B
    B = new(src)
    bayonet = B
    update_icon()

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

    if(bound_user)
        cleanup_combat_state(bound_user)
    return ..()

/obj/item/gun/ballistic/shotgun/slamfire/traitor/on_wield(obj/item/source, mob/living/user)
    ..()
    update_combat_state(user)

    if(!bound_user)
        bound_user = user
        user.apply_damage(10, BRUTE, BODY_ZONE_L_ARM)
        user.apply_damage(10, BRUTE, BODY_ZONE_R_ARM)
        playsound(user, 'sound/weapons/Shotguns_reheated/slamfire/VO/initialization.ogg', 70, TRUE)
        to_chat(user, span_userdanger("The wire bites into your flesh."))
        return

    if(bound_user != user)
        to_chat(user, span_userdanger("[src] rejects your grip."))
        playsound(user, 'sound/weapons/Shotguns_reheated/shared/jam_warning.ogg', 70, TRUE)
        var/datum/component/two_handed/TH = get_twohanded()
        TH?.unwield(user)
        addtimer(CALLBACK(user, TYPE_PROC_REF(/mob, dropItemToGround), src, TRUE), 1)
        return

/obj/item/gun/ballistic/shotgun/slamfire/traitor/on_unwield(obj/item/source, mob/living/user)
    ..()
    cleanup_combat_state(user)

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/clear_bond()
    bound_user = null
    overload_active = FALSE
    frenzy = 0
    frenzy_stage = 0
    previous_frenzy_stage = 0

/obj/item/gun/ballistic/shotgun/slamfire/traitor/dropped(mob/user)
    . = ..()

    if(user)
        cleanup_combat_state(user)

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/play_stage_feedback(mob/living/user, ascending = TRUE)

    if(world.time < last_stage_sound + stage_sound_cooldown)
        return
    last_stage_sound = world.time

    if(ascending)
        playsound(user, pick(stage_up_bank), 60, TRUE)
        var/msg = pick(stage_up_text_bank)
        user.visible_message(
            span_warning("[user]'s breathing becomes more erratic."),
            span_userdanger(msg)
)
    else
        playsound(user, pick(stage_down_bank), 60, TRUE)
        var/msg = pick(stage_down_text_bank)
        user.visible_message(
            span_notice("[user] seems to calm down slightly."),
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
    cleanup_combat_state(user)

    if(is_in_stance())
        switch(frenzy_stage)
            if(0 to 2)
                user.add_movespeed_modifier(/datum/movespeed_modifier/slamfire)
            if(3 to 4)
                user.add_movespeed_modifier(/datum/movespeed_modifier/slamfire_mid)
            if(5)
                user.add_movespeed_modifier(/datum/movespeed_modifier/slamfire_frenzy)
    if(frenzy_stage >= 3)
        ADD_TRAIT(user, TRAIT_IGNOREDAMAGESLOWDOWN, "slamfire_frenzy")
    if(frenzy_stage >= 5)
        ADD_TRAIT(user, TRAIT_NOSOFTCRIT, "slamfire_frenzy")

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/cleanup_combat_state(mob/living/user)

    if(!user)
        return
    user.remove_movespeed_modifier(/datum/movespeed_modifier/slamfire)
    user.remove_movespeed_modifier(/datum/movespeed_modifier/slamfire_mid)
    user.remove_movespeed_modifier(/datum/movespeed_modifier/slamfire_frenzy)
    REMOVE_TRAIT(user, TRAIT_IGNOREDAMAGESLOWDOWN, "slamfire_frenzy")
    REMOVE_TRAIT(user, TRAIT_NOSOFTCRIT, "slamfire_frenzy")

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/get_frenzy_jam_multiplier()

    switch(frenzy_stage)
        if(0)
            return 1.4
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

    if(frenzy >= 190)
        return 5
    if(frenzy >= 130)
        return 4
    if(frenzy >= 80)
        return 3
    if(frenzy >= 45)
        return 2
    if(frenzy >= 20)
        return 1
    return 0

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/recalculate_frenzy(mob/living/user)

    previous_frenzy_stage = frenzy_stage
    frenzy_stage = get_stage_from_frenzy()
    jam_multiplier = get_frenzy_jam_multiplier()
    update_combat_state(user)

    if(previous_frenzy_stage == frenzy_stage)
        return
    if(frenzy_stage > previous_frenzy_stage)
        play_stage_feedback(user, TRUE)
        trigger_frenzy_emote(user)
    else
        play_stage_feedback(user, FALSE)
    if(frenzy_stage >= 5 && !overload_active)
        enter_overload(user)


/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/feed_frenzy(mob/living/user, amount)

    if(!processing_active)
        start_frenzy_processing()
    if(amount <= 0)
        return
    frenzy = clamp(frenzy + amount, 0, max_frenzy)
    last_damage_time = world.time
    recalculate_frenzy(user)

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/enter_overload(mob/living/user)

    overload_active = TRUE
    overload_end_time = world.time + frenzy_reset_time
    to_chat(user, span_boldwarning("FULL SYNCHRONIZATION ACHIEVED."))
    playsound(user, 'sound/weapons/Shotguns_reheated/slamfire/VO/overload.ogg', 80, TRUE)
    playsound(user, 'sound/health/fastbeat.ogg', 80, TRUE)
    user.heal_overall_damage(20, 20)

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/reset_frenzy(mob/living/user)

    overload_active = FALSE
    overload_end_time = 0
    frenzy = 0
    frenzy_stage = 0
    jam_stress += 35
    previous_frenzy_stage = 0
    frenzy_stage = 0
    cleanup_combat_state(user)
    update_combat_state(user)

    if(user)
        user.adjustStaminaLoss(40)
        to_chat(user, span_warning("Your body violently crashes out of synchronization."))
    playsound(src, 'sound/health/slowbeat.ogg', 70, TRUE)
    stop_frenzy_processing()

/obj/item/gun/ballistic/shotgun/slamfire/traitor/process()
    ..()
    process_frenzy()

/obj/item/gun/ballistic/shotgun/slamfire/traitor/proc/process_frenzy()

    var/mob/living/user = bound_user
    if(!user)
        return
    if(bound_user.stat == DEAD)

        reset_frenzy(bound_user)
        cleanup_combat_state(bound_user)
        clear_bond()
        stop_frenzy_processing()
        return

    if(overload_active)

        if(world.time >= overload_end_time)
            if(bound_user && isliving(bound_user))
                reset_frenzy(bound_user)
            else
                reset_frenzy(null)
            return

    if(frenzy <= 0)
        stop_frenzy_processing()
        return

    if(world.time >= last_decay_tick + frenzy_decay_delay)
        frenzy = max(0, frenzy - 2)
        last_decay_tick = world.time
        recalculate_frenzy(user)

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
    feed_frenzy(user, 12)
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

    var/heal_amt = 2 + round(frenzy * 0.01)
    user.heal_overall_damage(heal_amt, heal_amt)
    user.adjustStaminaLoss(-8)
    jam_stress = max(0, jam_stress - 10)
    feed_frenzy(user, 18)
    to_chat(user, span_danger("The weapon feeds on violence."))

/obj/item/gun/ballistic/shotgun/slamfire/traitor/examine(mob/user)
    . = ..()

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

// Automatic Shotguns//
/obj/item/gun/ballistic/shotgun/automatic/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, stam_cost = 0)

    if(uses_jam)
        if(!can_fire_check(user))
            return
        if(try_jam(user))
            return

    var/result = ..()

    if(result)

        if(chambered)
            chambered.forceMove(drop_location())
            chambered.bounce_away()
            chambered = null

        // chamber next round
        if(magazine && magazine.ammo_count())
            chambered = magazine.get_round()

        last_fire_time = world.time
        jam_stress += round(15 * jam_multiplier)

        update_icon()

    return result

    // выброс текущего патрона
    if(chambered)
        chambered.forceMove(drop_location())
        chambered.bounce_away()
        chambered = null

    // досыл нового
    if(magazine && magazine.ammo_count())
        chambered = magazine.get_round()

    jammed = FALSE
    update_icon()
    return TRUE

	// выброс гильзы
    if(chambered)
        chambered.forceMove(drop_location())
        chambered.bounce_away()
        chambered = null

	// досыл нового патрона
    if(magazine && magazine.ammo_count())
        var/obj/item/ammo_casing/AC = magazine.get_round()
        chambered = AC

    update_icon()
    update_jam_stress()

/obj/item/gun/ballistic/shotgun/automatic/combat
	name = "Combat Shotgun"
	desc = "A modified version of the semi-automatic combat shotgun with a collapsible stock and a safety that prevents firing while folded. For close encounters."
	icon_state = "cshotgun"
	item_state = "cshotgun-wielded"
	fire_delay = 5
	fire_sound = 'sound/weapons/Shotguns_reheated/Semi-auto/Semifire.ogg'
	pumpsound = 'sound/weapons/Shotguns_reheated/Semi-auto/Semichamber.ogg'
	loadshell_sound = 'sound/weapons/Shotguns_reheated/Shared/Shellinsert2.ogg'
	mag_type = /obj/item/ammo_box/magazine/internal/shot/com
	uses_jam = TRUE
	jam_multiplier = 0.8
	w_class = WEIGHT_CLASS_NORMAL
	unique_reskin = list(
		"Tactical" = list("icon_state" = "cshotgun"),
		"Slick" = list("icon_state" = "cshotgun_slick")
	)
	var/stock = FALSE
	var/extend_sound = 'sound/weapons/Shotguns_reheated/Semi-auto/Stockunfold.ogg'


/obj/item/gun/ballistic/shotgun/automatic/combat/pindicate
	pin = /obj/item/firing_pin/implant/pindicate

/obj/item/gun/ballistic/shotgun/automatic/combat/warden
	name = "Warden's Combat Shotgun"
	desc = "A modified version of the semi-automatic combat shotgun with a collapsible stock and a safety that prevents firing while folded. For close encounters."
	fire_delay = 3
	recoil = 6
	spread = 2

/obj/item/gun/ballistic/shotgun/automatic/combat/AltClick(mob/living/user)
	if(!istype(user) || !user.canUseTopic(src, BE_CLOSE, ismonkey(user)) || item_flags & IN_STORAGE)
		return
	toggle_stock(user)
	. = ..()

/obj/item/gun/ballistic/shotgun/automatic/combat/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Alt-click to toggle the stock.</span>"

/obj/item/gun/ballistic/shotgun/automatic/combat/proc/toggle_stock(mob/living/user)
	stock = !stock
	if(stock)
		w_class = WEIGHT_CLASS_HUGE
		to_chat(user, "You unfold the stock.")
		recoil = 1
		spread = 0
	else
		w_class = WEIGHT_CLASS_NORMAL
		to_chat(user, "You fold the stock.")
		recoil = 5
		spread = 2
	playsound(src.loc, extend_sound, 50, 1)
	update_icon()

/obj/item/gun/ballistic/shotgun/automatic/combat/update_icon_state()
	icon_state = "[current_skin ? unique_reskin[current_skin]["icon_state"] : "cshotgun"][stock ? "" : "c"]"

/obj/item/gun/ballistic/shotgun/automatic/combat/afterattack(atom/target, mob/living/user, flag, params)
	if(!stock)
		shoot_with_empty_chamber(user)
		to_chat(user, "<span class='warning'>[src] won't fire with a folded stock!</span>")
	else
		. = ..()
		update_icon()

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
	sawn_item_state = "maresleg"

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
