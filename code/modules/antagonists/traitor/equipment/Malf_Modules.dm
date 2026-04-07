#define DEFAULT_DOOMSDAY_TIMER 4500
#define DOOMSDAY_ANNOUNCE_INTERVAL 600

GLOBAL_LIST_INIT(blacklisted_malf_machines, typecacheof(list(
		/obj/machinery/field/containment,
		/obj/machinery/power/supermatter_crystal,
		/obj/machinery/doomsday_device,
		/obj/machinery/nuclearbomb,
		/obj/machinery/nuclearbomb/selfdestruct,
		/obj/machinery/nuclearbomb/syndicate,
		/obj/machinery/syndicatebomb,
		/obj/machinery/syndicatebomb/badmin,
		/obj/machinery/syndicatebomb/badmin/clown,
		/obj/machinery/syndicatebomb/empty,
		/obj/machinery/syndicatebomb/self_destruct,
		/obj/machinery/syndicatebomb/training,
		/obj/machinery/gravity_generator,
		/obj/machinery/gravity_generator/main
	)))

//The malf AI action subtype. All malf actions are subtypes of this.
/datum/action/innate/ai
	name = "AI Action"
	desc = "You aren't entirely sure what this does, but it's very beepy and boopy."
	background_icon_state = "bg_tech_blue"
	icon_icon = 'icons/mob/actions/actions_AI.dmi'
	check_flags = AB_CHECK_CONSCIOUS //can't doomsday if dead.
	var/mob/living/silicon/ai/owner_AI //The owner AI, so we don't have to typecast every time
	var/uses //If we have multiple uses of the same power
	var/auto_use_uses = TRUE //If we automatically use up uses on each activation
	var/cooldown_period //If applicable, the time in deciseconds we have to wait before using any more modules


/datum/action/innate/ai/New()
	..()
	desc = "[desc] It has [uses] use\s remaining."

/datum/action/innate/ai/Grant(mob/living/L)
	. = ..()
	if(!isAI(owner))
		WARNING("AI action [name] attempted to grant itself to non-AI mob [L.real_name] ([L.key])!")
		qdel(src)
	else
		owner_AI = owner

/datum/action/innate/ai/IsAvailable(silent = FALSE)
	. = ..()
	if(owner_AI && owner_AI.malf_cooldown > world.time)
		return FALSE

/datum/action/innate/ai/Trigger()
	. = ..()
	if(auto_use_uses)
		adjust_uses(-1)
	if(cooldown_period)
		owner_AI.malf_cooldown = world.time + cooldown_period

/datum/action/innate/ai/proc/adjust_uses(amt, silent)
	uses += amt
	if(uses)
		if(!silent)
			to_chat(owner, "<span class='notice'>[name] now has <b>[uses]</b> use[uses > 1 ? "s" : ""] remaining.</span>")
		desc = "[initial(desc)] It has [uses] use\s remaining."
		UpdateButtons()
		return
	if(initial(uses) > 1) //no need to tell 'em if it was one-use anyway!
		to_chat(owner, "<span class='warning'>[name] has run out of uses!</span>")
	qdel(src)


//Framework for ranged abilities that can have different effects by left-clicking stuff.
/datum/action/innate/ai/ranged
	name = "Ranged AI Action"
	auto_use_uses = FALSE //This is so we can do the thing and disable/enable freely without having to constantly add uses
	var/obj/effect/proc_holder/ranged_ai/linked_ability //The linked proc holder that contains the actual ability code
	var/linked_ability_type //The path of our linked ability

/datum/action/innate/ai/ranged/New()
	if(!linked_ability_type)
		WARNING("Ranged AI action [name] attempted to spawn without a linked ability!")
		qdel(src) //uh oh!
		return
	linked_ability = new linked_ability_type()
	linked_ability.attached_action = src
	..()

/datum/action/innate/ai/ranged/adjust_uses(amt, silent)
	uses += amt
	if(uses)
		if(!silent)
			to_chat(owner, "<span class='notice'>[name] now has <b>[uses]</b> use[uses > 1 ? "s" : ""] remaining.</span>")
		desc = "[initial(desc)] It has [uses] use\s remaining."
		UpdateButtons()
		return
	if(initial(uses) > 1) //no need to tell 'em if it was one-use anyway!
		to_chat(owner, "<span class='warning'>[name] has run out of uses!</span>")
	Remove(owner)
	QDEL_IN(src, 100) //let any active timers on us finish up

/datum/action/innate/ai/ranged/Destroy()
	QDEL_NULL(linked_ability)
	return ..()

/datum/action/innate/ai/ranged/Activate()
	linked_ability.toggle(owner)
	return TRUE

//The actual ranged proc holder.
/obj/effect/proc_holder/ranged_ai
	var/enable_text = "<span class='notice'>Hello World!</span>" //Appears when the user activates the ability
	var/disable_text = "<span class='danger'>Goodbye Cruel World!</span>" //Context clues!
	var/datum/action/innate/ai/ranged/attached_action

/obj/effect/proc_holder/ranged_ai/Destroy()
	attached_action = null
	return ..()

/obj/effect/proc_holder/ranged_ai/proc/toggle(mob/user)
	if(active)
		remove_ranged_ability(disable_text)
	else
		add_ranged_ability(user, enable_text)


//The datum and interface for the malf unlock menu, which lets them choose actions to unlock.
/datum/module_picker
	var/temp
	var/processing_time = 50
	var/list/possible_modules

/datum/module_picker/New()
	possible_modules = list()
	for(var/type in typesof(/datum/AI_Module))
		var/datum/AI_Module/AM = new type
		if((AM.power_type && AM.power_type != /datum/action/innate/ai) || AM.upgrade)
			possible_modules += AM

/datum/module_picker/proc/remove_malf_verbs(mob/living/silicon/ai/AI) //Removes all malfunction-related abilities from the target AI.
	for(var/datum/AI_Module/AM in possible_modules)
		for(var/datum/action/A in AI.actions)
			if(istype(A, initial(AM.power_type)))
				qdel(A)

// (ADD) Pe4henika bluemoon -- start
// MARK: TGUI
/datum/module_picker/ui_interact(mob/user, datum/tgui/ui)
    ui = SStgui.try_update_ui(user, src, ui)
    if(!ui)
        ui = new(user, src, "MalfunctionModulePicker", "MALFUNCTION SYSTEM // MODULE V2.77")
        ui.open()

/datum/module_picker/ui_host(mob/user)
	return user

/datum/module_picker/ui_data(mob/user)
    var/list/data = list()
    // Ключи должны строго совпадать с JS частью!
    data["processing_time"] = processing_time
    data["temp"] = temp

    var/list/large = list()
    var/list/small = list()

    for(var/datum/AI_Module/AM in possible_modules)
        var/list/info = list(
            "name" = AM.module_name,
            "cost" = AM.cost,
            "desc" = AM.description,
            "ref" = REF(AM)
        )
        if(istype(AM, /datum/AI_Module/large))
            large += list(info)
        else
            small += list(info)

    data["large_modules"] = large
    data["small_modules"] = small
    return data

/datum/module_picker/ui_act(action, list/params, datum/tgui/ui)
    if(..())
        return

    var/mob/living/silicon/ai/A = usr
    if(!istype(A) || A.stat == DEAD)
        return

    switch(action)
        if("buy") // Соответствует act('buy', ...) в JS
            var/datum/AI_Module/AM = locate(params["ref"]) in possible_modules
            if(!AM)
                return FALSE

            if(AM.cost > processing_time)
                temp = "ОШИБКА: Недостаточно мощностей."
                return TRUE

            var/datum/action/innate/ai/action_exists = locate(AM.power_type) in A.actions

            if(AM.upgrade)
                AM.upgrade(A)
                possible_modules -= AM
                to_chat(A, AM.unlock_text)
            else
                if(AM.power_type)
                    if(!action_exists)
                        var/datum/action/AC = new AM.power_type
                        AC.Grant(A)
                        A.current_modules += new AM.type
                        temp = AM.description
                        if(AM.one_purchase)
                            possible_modules -= AM
                        if(AM.unlock_text)
                            to_chat(A, AM.unlock_text)
                    else
                        action_exists.uses += initial(action_exists.uses)
                        action_exists.desc = "[initial(action_exists.desc)] Использований: [action_exists.uses]."
                        action_exists.UpdateButtons()
                        temp = "Заряды добавлены: [action_exists.name]!"

            if(AM.unlock_sound)
                A.playsound_local(A, AM.unlock_sound, 50, 0)

            processing_time -= AM.cost
            return TRUE
    return FALSE
// (ADD) Pe4henika bluemoon -- end
//The base module type, which holds info about each ability.
/datum/AI_Module
	var/module_name
	var/mod_pick_name
	var/description = ""
	var/engaged = 0
	var/cost = 5
	var/one_purchase = FALSE //If this module can only be purchased once. This always applies to upgrades, even if the variable is set to false.

	var/power_type = /datum/action/innate/ai //If the module gives an active ability, use this. Mutually exclusive with upgrade.
	var/upgrade //If the module gives a passive upgrade, use this. Mutually exclusive with power_type.
	var/unlock_text = "<span class='notice'>Hello World!</span>" //Text shown when an ability is unlocked
	var/unlock_sound //Sound played when an ability is unlocked

/datum/AI_Module/proc/upgrade(mob/living/silicon/ai/AI) //Apply upgrades!
	return

/datum/AI_Module/large //Big, powerful stuff that can only be used once.
/datum/AI_Module/small //Weak, usually localized stuff with multiple uses.


//Doomsday Device: Starts the self-destruct timer. It can only be stopped by killing the AI completely.
/datum/AI_Module/large/nuke_station
	module_name = "Устройство Судного Дня"
	mod_pick_name = "nukestation"
	description = "Активирует оружие, которое расщепит всю органику на станции через 450 секунд. Работает только на станции. Провал, если ядро будет перемещено или уничтожено."
	cost = 130
	one_purchase = TRUE
	power_type = /datum/action/innate/ai/nuke_station
	unlock_text = "<span class='notice'>Вы медленно, шаг за шагом, устанавливаете соединение с системой самоуничтожения станции. Теперь вы можете активировать её в любой момент.</span>"

/datum/action/innate/ai/nuke_station
	name = "Doomsday Device"
	desc = "Activates the doomsday device. This is not reversible."
	button_icon_state = "doomsday_device"
	auto_use_uses = FALSE

/datum/action/innate/ai/nuke_station/Activate()
	var/turf/T = get_turf(owner)
	if(!istype(T) || !is_station_level(T.z))
		to_chat(owner, "<span class='warning'>You cannot activate the doomsday device while off-station!</span>")
		return
	if(alert(owner, "Send arming signal? (true = arm, false = cancel)", "purge_all_life()", "confirm = TRUE;", "confirm = FALSE;") != "confirm = TRUE;")
		return
	if (active)
		return //prevent the AI from activating an already active doomsday
	if (owner_AI.shunted)
		return //prevent AI from activating doomsday while shunted.
	if (istype(owner.loc, /obj/item/aicard))
		return //prevent AI from activating doomsday while carded. If the AI gets carded after doomsdaying, there's already code to stop it then.
	active = TRUE
	set_us_up_the_bomb(owner)

/datum/action/innate/ai/nuke_station/proc/set_us_up_the_bomb(mob/living/owner)
	set waitfor = FALSE
	to_chat(owner, "<span class='small boldannounce'>run -o -a 'selfdestruct'</span>")
	sleep(5)
	if(QDELETED(owner) || owner.stat == DEAD)
		return
	to_chat(owner, "<span class='small boldannounce'>Running executable 'selfdestruct'...</span>")
	sleep(rand(10, 30))
	if(QDELETED(owner) || owner.stat == DEAD)
		return
	owner.playsound_local(owner, 'sound/misc/bloblarm.ogg', 50, 0)
	to_chat(owner, "<span class='userdanger'>!!! UNAUTHORIZED SELF-DESTRUCT ACCESS !!!</span>")
	to_chat(owner, "<span class='boldannounce'>This is a class-3 security violation. This incident will be reported to Central Command.</span>")
	for(var/i in 1 to 3)
		sleep(20)
		if(QDELETED(owner) || owner.stat == DEAD)
			return
		to_chat(owner, "<span class='boldannounce'>Sending security report to Central Command.....[rand(0, 9) + (rand(20, 30) * i)]%</span>")
	sleep(3)
	if(QDELETED(owner) || owner.stat == DEAD)
		return
	to_chat(owner, "<span class='small boldannounce'>auth 'akjv9c88asdf12nb' ******************</span>")
	owner.playsound_local(owner, 'sound/items/timer.ogg', 50, 0)
	sleep(30)
	if(QDELETED(owner) || owner.stat == DEAD)
		return
	to_chat(owner, "<span class='boldnotice'>Credentials accepted. Welcome, akjv9c88asdf12nb.</span>")
	owner.playsound_local(owner, 'sound/misc/server-ready.ogg', 50, 0)
	sleep(5)
	if(QDELETED(owner) || owner.stat == DEAD)
		return
	to_chat(owner, "<span class='boldnotice'>Arm self-destruct device? (Y/N)</span>")
	owner.playsound_local(owner, 'sound/misc/compiler-stage1.ogg', 50, 0)
	sleep(20)
	if(QDELETED(owner) || owner.stat == DEAD)
		return
	to_chat(owner, "<span class='small boldannounce'>Y</span>")
	sleep(15)
	if(QDELETED(owner) || owner.stat == DEAD)
		return
	to_chat(owner, "<span class='boldnotice'>Confirm arming of self-destruct device? (Y/N)</span>")
	owner.playsound_local(owner, 'sound/misc/compiler-stage2.ogg', 50, 0)
	sleep(10)
	if(QDELETED(owner) || owner.stat == DEAD)
		return
	to_chat(owner, "<span class='small boldannounce'>Y</span>")
	sleep(rand(15, 25))
	if(QDELETED(owner) || owner.stat == DEAD)
		return
	to_chat(owner, "<span class='boldnotice'>Please repeat password to confirm.</span>")
	owner.playsound_local(owner, 'sound/misc/compiler-stage2.ogg', 50, 0)
	sleep(14)
	if(QDELETED(owner) || owner.stat == DEAD)
		return
	to_chat(owner, "<span class='small boldannounce'>******************</span>")
	sleep(40)
	if(QDELETED(owner) || owner.stat == DEAD)
		return
	to_chat(owner, "<span class='boldnotice'>Credentials accepted. Transmitting arming signal...</span>")
	owner.playsound_local(owner, 'sound/misc/server-ready.ogg', 50, 0)
	sleep(30)
	if(QDELETED(owner) || owner.stat == DEAD)
		return
	if(istype(owner.loc, /obj/item/aicard))
		to_chat(owner, "<span class='boldnotice'>Error: Signal transmission failed. Reason: Lost connection to network.</span>")
		to_chat(owner, "<span class='warning'>You can't activate the doomsday device while inside an intelliCard!</span>")
		return
	priority_announce("Во всех станционных системах зафиксировано вредоносное ПО. Пожалуйста, отключите ИИ чтобы предотвратить возможные неисправности его ядра морали.", "ВНИМАНИЕ: АНОМАЛИЯ", "aimalf")
	set_security_level("delta")
	var/obj/machinery/doomsday_device/DOOM = new(owner_AI)
	owner_AI.nuking = TRUE
	owner_AI.doomsday_device = DOOM
	owner_AI.doomsday_device.start()
	for(var/obj/item/pinpointer/nuke/P in GLOB.pinpointer_list)
		P.switch_mode_to(TRACK_MALF_AI) //Pinpointers start tracking the AI wherever it goes
	qdel(src)

/obj/machinery/doomsday_device
	icon = 'icons/obj/machines/nuke_terminal.dmi'
	name = "doomsday device"
	icon_state = "nuclearbomb_base"
	desc = "A weapon which disintegrates all organic life in a large area."
	density = TRUE
	verb_exclaim = "blares"
	var/timing = FALSE
	var/obj/effect/countdown/doomsday/countdown
	var/detonation_timer
	var/next_announce

/obj/machinery/doomsday_device/Initialize(mapload)
	. = ..()
	countdown = new(src)

/obj/machinery/doomsday_device/Destroy()
	QDEL_NULL(countdown)
	STOP_PROCESSING(SSfastprocess, src)
	SSshuttle.clearHostileEnvironment(src)
	SSmapping.remove_nuke_threat(src)
	for(var/A in GLOB.ai_list)
		var/mob/living/silicon/ai/AI = A
		if(AI.doomsday_device == src)
			AI.doomsday_device = null
	return ..()

/obj/machinery/doomsday_device/proc/start()
	detonation_timer = world.time + DEFAULT_DOOMSDAY_TIMER
	next_announce = world.time + DOOMSDAY_ANNOUNCE_INTERVAL
	timing = TRUE
	countdown.start()
	START_PROCESSING(SSfastprocess, src)
	SSshuttle.registerHostileEnvironment(src)
	SSmapping.add_nuke_threat(src) //This causes all blue "circuit" tiles on the map to change to animated red icon state.

/obj/machinery/doomsday_device/proc/seconds_remaining()
	. = max(0, (round((detonation_timer - world.time) / 10)))

/obj/machinery/doomsday_device/process()
	var/turf/T = get_turf(src)
	if(!T || !is_station_level(T.z))
		minor_announce("УСТРОЙСТВО СУДНОГО ДНЯ НАХОДИТСЯ ВНЕ СТАНЦИИ, ОТМЕНА", "ОШИБКА 0ШИБК0 $Ш0ШШO$!R41.%%!!(%$^^__+ @#F0E4", TRUE)
		SSshuttle.clearHostileEnvironment(src)
		qdel(src)
		return
	if(!timing)
		STOP_PROCESSING(SSfastprocess, src)
		return
	var/sec_left = seconds_remaining()
	if(!sec_left)
		timing = FALSE
		detonate()
	else if(world.time >= next_announce)
		minor_announce("[sec_left] СЕКУНД ДО АКТИВАЦИИ УСТРОЙСТВА СУДНОГО ДНЯ!", "ОШИБКА 0ШИБК0 $Ш0ШШO$!R41.%%!!(%$^^__+ @#F0E4", TRUE)
		next_announce += DOOMSDAY_ANNOUNCE_INTERVAL

/obj/machinery/doomsday_device/proc/detonate()
	set waitfor = FALSE
	sound_to_playing_players('sound/machines/alarm.ogg')
	sleep(100)
	for(var/i in GLOB.mob_living_list)
		var/mob/living/L = i
		var/turf/T = get_turf(L)
		if(!T || !is_station_level(T.z))
			continue
		if(issilicon(L))
			continue
		to_chat(L, "<span class='userdanger'>Взрывная волна от [src] расщепляет вас на атомы!</span>")
		L.dust()
	to_chat(world, "<B>Искусственный интеллект очистил станцию с помощью устройства судного дня!</B>")
	SSticker.force_ending = 1


//AI Turret Upgrade: Increases the health and damage of all turrets.
/datum/AI_Module/large/upgrade_turrets
	module_name = "Модернизация Турелей"
	mod_pick_name = "turret"
	description = "Улучшает прочность и урон всех турелей ИИ. Эффект постоянен."
	cost = 30
	upgrade = TRUE
	unlock_text = "<span class='notice'>Вы перенаправляете питание к турелям, значительно увеличивая их боевую эффективность.</span>"
	unlock_sound = 'sound/items/rped.ogg'

/datum/AI_Module/large/upgrade_turrets/upgrade(mob/living/silicon/ai/AI)
	for(var/obj/machinery/porta_turret/ai/turret in GLOB.machines)
		turret.obj_integrity += 30
		turret.lethal_projectile = /obj/item/projectile/beam/laser/heavylaser //Once you see it, you will know what it means to FEAR.
		turret.lethal_projectile_sound = 'sound/weapons/lasercannonfire.ogg'


//Hostile Station Lockdown: Locks, bolts, and electrifies every airlock on the station. After 90 seconds, the doors reset.
/datum/AI_Module/large/lockdown
	module_name = "Блокировка Станции"
	mod_pick_name = "lockdown"
	description = "Перегружает сеть управления шлюзами и пожарными дверями, закрывая их на болты и электризуя. Сеть перезагрузится через 90 секунд."
	cost = 30
	one_purchase = TRUE
	power_type = /datum/action/innate/ai/lockdown
	unlock_text = "<span class='notice'>Вы загружаете спящий троян в систему управления дверями. Готов к активации.</span>"
	unlock_sound = 'sound/machines/boltsdown.ogg'

/datum/action/innate/ai/lockdown
	name = "Lockdown"
	desc = "Closes, bolts, and depowers every airlock, firelock, and blast door on the station. After 90 seconds, they will reset themselves."
	button_icon_state = "lockdown"
	uses = 1

/datum/action/innate/ai/lockdown/Activate()
	for(var/obj/machinery/door/D in GLOB.airlocks)
		if(!is_station_level(D.z))
			continue
		INVOKE_ASYNC(D, TYPE_PROC_REF(/obj/machinery/door, hostile_lockdown), owner)
		addtimer(CALLBACK(D, TYPE_PROC_REF(/obj/machinery/door, disable_lockdown)), 900)

	var/obj/machinery/computer/communications/C = locate() in GLOB.machines
	if(C)
		C.post_status("alert", "lockdown")

	minor_announce("Вредоносное программное обеспечение обнаружено в системе контроля шл+юзов. Задействованы протоколы изоляции. Пожалуйста, сохраняйте спокойствие.","ВНИМАНИЕ: УЯЗВИМОСТЬ СЕТИ", TRUE)
	to_chat(owner, "<span class='danger'>Lockdown initiated. Network reset in 90 seconds.</span>")
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(minor_announce),
		"Автоматическая перезагрузка системы завершена. Хорошего вам дня.",
		"ПЕРЕЗАГРУЗКА СЕТИ:"), 900)


//Destroy RCDs: Detonates all non-cyborg RCDs on the station.
/datum/AI_Module/large/destroy_rcd
	module_name = "Детонация RCD"
	mod_pick_name = "rcd"
	description = "Посылает специализированный импульс, подрывающий все переносные RCD на станции (кроме киборгов)."
	cost = 25
	one_purchase = TRUE
	power_type = /datum/action/innate/ai/destroy_rcds
	unlock_text = "<span class='notice'>Вы настроили свои радиосистемы на частоту детонации RCD. Сигнал готов к отправке.</span>"
	unlock_sound = 'sound/items/timer.ogg'

/datum/action/innate/ai/destroy_rcds
	name = "Destroy RCDs"
	desc = "Detonate all non-cyborg RCDs on the station."
	button_icon_state = "detonate_rcds"
	uses = 1
	cooldown_period = 100

/datum/action/innate/ai/destroy_rcds/Activate()
	for(var/I in GLOB.rcd_list)
		if(!istype(I, /obj/item/construction/rcd/borg)) //Ensures that cyborg RCDs are spared.
			var/obj/item/construction/rcd/RCD = I
			RCD.detonate_pulse()
	to_chat(owner, "<span class='danger'>RCD detonation pulse emitted.</span>")
	owner.playsound_local(owner, 'sound/machines/twobeep.ogg', 50, 0)


//Unlock Mech Domination: Unlocks the ability to dominate mechs. Big shocker, right?
/datum/AI_Module/large/mecha_domination
	module_name = "Взлом Мехов"
	mod_pick_name = "mechjack"
	description = "Позволяет захватывать управление мехами, выбрасывая пилота. Внимание: после загрузки в меха вы не сможете его покинуть."
	cost = 30
	upgrade = TRUE
	unlock_text = "<span class='notice'>Вирусный пакет скомпилирован. Выберите цель. Потеря сигнала со станцией приведет к немедленной блокировке систем.</span>"
	unlock_sound = 'sound/mecha/nominal.ogg'

/datum/AI_Module/large/mecha_domination/upgrade(mob/living/silicon/ai/AI)
	AI.can_dominate_mechs = TRUE //Yep. This is all it does. Honk!


//Thermal Sensor Override: Unlocks the ability to disable all fire alarms from doing their job.
/datum/AI_Module/large/break_fire_alarms
	module_name = "Отключение Термодатчиков"
	mod_pick_name = "burnpigs"
	description = "Отключает сенсоры огня на всех пожарных тревогах. Они перестанут реагировать на пожар автоматически."
	one_purchase = TRUE
	cost = 25
	power_type = /datum/action/innate/ai/break_fire_alarms
	unlock_text = "<span class='notice'>Вы заменили ПО пожарных тревог. Теперь они будут работать только в ручном режиме.</span>"
	unlock_sound = 'goon/sound/machinery/firealarm.ogg'

/datum/action/innate/ai/break_fire_alarms
	name = "Override Thermal Sensors"
	desc = "Disables the automatic temperature sensing on all fire alarms, making them effectively useless."
	button_icon_state = "break_fire_alarms"
	uses = 1

/datum/action/innate/ai/break_fire_alarms/Activate()
	for(var/obj/machinery/firealarm/F in GLOB.machines)
		if(!is_station_level(F.z))
			continue
		F.obj_flags |= EMAGGED
		F.update_icon()
	to_chat(owner, "<span class='notice'>All thermal sensors on the station have been disabled. Fire alerts will no longer be recognized.</span>")
	owner.playsound_local(owner, 'sound/machines/terminal_off.ogg', 50, 0)


//Air Alarm Safety Override: Unlocks the ability to enable flooding on all air alarms.
/datum/AI_Module/large/break_air_alarms
	module_name = "Взлом Воздушной Системы"
	mod_pick_name = "allow_flooding"
	description = "Снимает ограничения безопасности с воздушных контроллеров. Это позволит использовать режим затопления"
	one_purchase = TRUE
	cost = 50
	power_type = /datum/action/innate/ai/break_air_alarms
	unlock_text = "<span class='notice'>Протоколы безопасности удалены. Режим 'Затопление' готов к использованию... вы чудовище.</span>"
	unlock_sound = 'sound/effects/space_wind.ogg'

/datum/action/innate/ai/break_air_alarms
	name = "Override Air Alarm Safeties"
	desc = "Enables the Flood setting on all air alarms."
	button_icon_state = "break_air_alarms"
	uses = 1

/datum/action/innate/ai/break_air_alarms/Activate()
	for(var/obj/machinery/airalarm/AA in GLOB.machines)
		if(!is_station_level(AA.z))
			continue
		AA.obj_flags |= EMAGGED
	to_chat(owner, "<span class='notice'>All air alarm safeties on the station have been overridden. Air alarms may now use the Flood environmental mode.</span>")
	owner.playsound_local(owner, 'sound/machines/terminal_off.ogg', 50, 0)


//Overload Machine: Allows the AI to overload a machine, detonating it after a delay. Two uses per purchase.
/datum/AI_Module/small/overload_machine
	module_name = "Перегрузка Оборудования"
	mod_pick_name = "overload"
	description = "Вызывает перегрев электрического прибора, приводя к взрыву. 2 заряда за покупку."
	cost = 20
	power_type = /datum/action/innate/ai/ranged/overload_machine
	unlock_text = "<span class='notice'>Вы получили доступ к управлению питанием отдельных узлов оборудования.</span>"
	unlock_sound = 'sound/effects/comfyfire.ogg' //definitely not comfy, but it's the closest sound to "roaring fire" we have

/datum/action/innate/ai/ranged/overload_machine
	name = "Overload Machine"
	desc = "Overheats a machine, causing a small explosion after a short time."
	button_icon_state = "overload_machine"
	uses = 2
	linked_ability_type = /obj/effect/proc_holder/ranged_ai/overload_machine

/datum/action/innate/ai/ranged/overload_machine/proc/detonate_machine(obj/machinery/M)
	if(M && !QDELETED(M))
		var/turf/T = get_turf(M)
		message_admins("[ADMIN_LOOKUPFLW(usr)] overloaded [M.name] at [ADMIN_VERBOSEJMP(T)].")
		log_game("[key_name(usr)] overloaded [M.name] at [AREACOORD(T)].")
		explosion(get_turf(M), 0, 2, 3, 0)
		if(M) //to check if the explosion killed it before we try to delete it
			qdel(M)

/obj/effect/proc_holder/ranged_ai/overload_machine
	active = FALSE
	ranged_mousepointer = 'icons/effects/overload_machine_target.dmi'
	enable_text = "<span class='notice'>You tap into the station's powernet. Click on a machine to detonate it, or use the ability again to cancel.</span>"
	disable_text = "<span class='notice'>You release your hold on the powernet.</span>"

/obj/effect/proc_holder/ranged_ai/overload_machine/InterceptClickOn(mob/living/caller, params, obj/machinery/target)
	if(..())
		return
	if(ranged_ability_user.incapacitated())
		remove_ranged_ability()
		return
	if(!istype(target))
		to_chat(ranged_ability_user, "<span class='warning'>You can only overload machines!</span>")
		return
	if(is_type_in_typecache(target, GLOB.blacklisted_malf_machines))
		to_chat(ranged_ability_user, "<span class='warning'>You cannot overload that device!</span>")
		return
	ranged_ability_user.playsound_local(ranged_ability_user, "sparks", 50, 0)
	attached_action.adjust_uses(-1)
	target.audible_message("<span class='userdanger'>You hear a loud electrical buzzing sound coming from [target]!</span>")
	addtimer(CALLBACK(attached_action, TYPE_PROC_REF(/datum/action/innate/ai/ranged/overload_machine, detonate_machine), target), 50) //kaboom!
	remove_ranged_ability("<span class='danger'>Overcharging machine...</span>")
	return TRUE


//Override Machine: Allows the AI to override a machine, animating it into an angry, living version of itself.
/datum/AI_Module/small/override_machine
	module_name = "Перехват Оборудования"
	mod_pick_name = "override"
	description = "Оживляет машину, превращая её в агрессивного мимика, атакующего всех вокруг. 4 заряда."
	cost = 30
	power_type = /datum/action/innate/ai/ranged/override_machine
	unlock_text = "<span class='notice'>Вы скачали вирус из 'Space Dark Web' и внедрили его в локальную сеть.</span>"
	unlock_sound = 'sound/machines/airlock_alien_prying.ogg'

/datum/action/innate/ai/ranged/override_machine
	name = "Override Machine"
	desc = "Animates a targeted machine, causing it to attack anyone nearby."
	button_icon_state = "override_machine"
	uses = 4
	linked_ability_type = /obj/effect/proc_holder/ranged_ai/override_machine

/datum/action/innate/ai/ranged/override_machine/proc/animate_machine(obj/machinery/M)
	if(M && !QDELETED(M))
		new/mob/living/simple_animal/hostile/mimic/copy/machine(get_turf(M), M, owner, 1)

/obj/effect/proc_holder/ranged_ai/override_machine
	active = FALSE
	ranged_mousepointer = 'icons/effects/override_machine_target.dmi'
	enable_text = "<span class='notice'>You tap into the station's powernet. Click on a machine to animate it, or use the ability again to cancel.</span>"
	disable_text = "<span class='notice'>You release your hold on the powernet.</span>"

/obj/effect/proc_holder/ranged_ai/override_machine/InterceptClickOn(mob/living/caller, params, obj/machinery/target)
	if(..())
		return
	if(ranged_ability_user.incapacitated())
		remove_ranged_ability()
		return
	if(!istype(target))
		to_chat(ranged_ability_user, "<span class='warning'>You can only animate machines!</span>")
		return
	if(!target.can_be_overridden() || is_type_in_typecache(target, GLOB.blacklisted_malf_machines))
		to_chat(ranged_ability_user, "<span class='warning'>That machine can't be overridden!</span>")
		return
	ranged_ability_user.playsound_local(ranged_ability_user, 'sound/misc/interference.ogg', 50, 0)
	attached_action.adjust_uses(-1)
	target.audible_message("<span class='userdanger'>You hear a loud electrical buzzing sound coming from [target]!</span>")
	addtimer(CALLBACK(attached_action, TYPE_PROC_REF(/datum/action/innate/ai/ranged/override_machine, animate_machine), target), 50) //kabeep!
	remove_ranged_ability("<span class='danger'>Sending override signal...</span>")
	return TRUE


//Robotic Factory: Places a large machine that converts humans that go through it into cyborgs. Unlocking this ability removes shunting.
/datum/AI_Module/large/place_cyborg_transformer
	module_name = "Роботизированная Фабрика"
	mod_pick_name = "cyborgtransformer"
	description = "Позволяет построить преобразователь в киборгов. ВНИМАНИЕ: Установка этого модуля делает невозможным использование Шанта (Shunting)."
	cost = 100
	one_purchase = TRUE
	power_type = /datum/action/innate/ai/place_transformer
	unlock_text = "<span class='notice'>Вы связались со 'Space Amazon' и заказали экспресс-доставку оборудования для фабрики.</span>"
	unlock_sound = 'sound/machines/ping.ogg'

/datum/action/innate/ai/place_transformer
	name = "Place Robotics Factory"
	desc = "Places a machine that converts humans into cyborgs. Conveyor belts included!"
	button_icon_state = "robotic_factory"
	uses = 1
	auto_use_uses = FALSE //So we can attempt multiple times
	var/list/turfOverlays

/datum/action/innate/ai/place_transformer/New()
	..()
	for(var/i in 1 to 3)
		var/image/I = image("icon"='icons/turf/overlays.dmi')
		LAZYADD(turfOverlays, I)

/datum/action/innate/ai/place_transformer/Activate()
	if(!owner_AI.can_place_transformer(src))
		return
	active = TRUE
	if(alert(owner, "Are you sure you want to place the machine here?", "Are you sure?", "Yes", "No") == "No")
		active = FALSE
		return
	if(!owner_AI.can_place_transformer(src))
		active = FALSE
		return
	var/turf/T = get_turf(owner_AI.eyeobj)
	var/obj/machinery/transformer/conveyor = new(T)
	conveyor.masterAI = owner
	playsound(T, 'sound/effects/phasein.ogg', 100, 1)
	owner_AI.can_shunt = FALSE
	to_chat(owner, "<span class='warning'>You are no longer able to shunt your core to APCs.</span>")
	adjust_uses(-1)

/mob/living/silicon/ai/proc/remove_transformer_image(client/C, image/I, turf/T)
	if(C && I.loc == T)
		C.images -= I

/mob/living/silicon/ai/proc/can_place_transformer(datum/action/innate/ai/place_transformer/action)
	if(!eyeobj || !isturf(loc) || incapacitated() || !action)
		return
	var/turf/middle = get_turf(eyeobj)
	var/list/turfs = list(middle, locate(middle.x - 1, middle.y, middle.z), locate(middle.x + 1, middle.y, middle.z))
	var/alert_msg = "There isn't enough room! Make sure you are placing the machine in a clear area and on a floor."
	var/success = TRUE
	for(var/n in 1 to 3) //We have to do this instead of iterating normally because of how overlay images are handled
		var/turf/T = turfs[n]
		if(!isfloorturf(T))
			success = FALSE
		var/datum/camerachunk/C = GLOB.cameranet.getCameraChunk(T.x, T.y, T.z)
		if(!C.visibleTurfs[T])
			alert_msg = "You don't have camera vision of this location!"
			success = FALSE
		for(var/atom/movable/AM in T.contents)
			if(AM.density)
				alert_msg = "That area must be clear of objects!"
				success = FALSE
		var/image/I = action.turfOverlays[n]
		I.loc = T
		client.images += I
		I.icon_state = "[success ? "green" : "red"]Overlay" //greenOverlay and redOverlay for success and failure respectively
		addtimer(CALLBACK(src, PROC_REF(remove_transformer_image), client, I, T), 30)
	if(!success)
		to_chat(src, "<span class='warning'>[alert_msg]</span>")
	return success


//Blackout: Overloads a random number of lights across the station. Three uses.
/datum/AI_Module/small/blackout
	module_name = "Блэкаут"
	mod_pick_name = "blackout"
	description = "Попытка перегрузить осветительные цепи станции, уничтожая часть ламп. Три использования."
	cost = 15
	power_type = /datum/action/innate/ai/blackout
	unlock_text = "<span class='notice'>Вы подключаетесь к энергосети и направляете избыточную энергию в систему освещения станции.</span>"
	unlock_sound = "sparks"

/datum/action/innate/ai/blackout
	name = "Blackout"
	desc = "Overloads random lights across the station."
	button_icon_state = "blackout"
	uses = 3
	auto_use_uses = FALSE

/datum/action/innate/ai/blackout/New()
	..()
	desc = "[desc] It has [uses] use\s remaining."

/datum/action/innate/ai/blackout/Activate()
	for(var/obj/machinery/power/apc/apc in GLOB.apcs_list)
		if(prob(30 * apc.overload))
			apc.overload_lighting()
		else
			apc.overload++
	to_chat(owner, "<span class='notice'>Overcurrent applied to the powernet.</span>")
	owner.playsound_local(owner, "sparks", 50, 0)
	adjust_uses(-1)
	if(QDELETED(src) || uses) //Not sure if not having src here would cause a runtime, so it's here to be safe
		return
	desc = "[initial(desc)] It has [uses] use\s remaining."
	UpdateButtons()

//Disable Emergency Lights
/datum/AI_Module/small/emergency_lights
	module_name = "Отключение аварийного освещения"
	mod_pick_name = "disable_emergency_lights"
	description = "Разрывает цепи аварийного освещения по всей станции. В случае потери питания лампы не будут переключаться на резервные источники энергии."
	cost = 10
	one_purchase = TRUE
	power_type = /datum/action/innate/ai/emergency_lights
	unlock_text = "<span class='notice'>Вы подключаетесь к энергосети и находите соединения между осветительными приборами и их резервными системами.</span>"
	unlock_sound = "sparks"

/datum/action/innate/ai/emergency_lights
	name = "Disable Emergency Lights"
	desc = "Disables all emergency lighting. Note that emergency lights can be restored through reboot at an APC."
	button_icon_state = "emergency_lights"
	uses = 1

/datum/action/innate/ai/emergency_lights/Activate()
	for(var/obj/machinery/light/L in GLOB.machines)
		if(is_station_level(L.z))
			L.no_emergency = TRUE
			INVOKE_ASYNC(L, TYPE_PROC_REF(/obj/machinery/light, update), FALSE)
		CHECK_TICK
	to_chat(owner, "<span class='notice'>Emergency light connections severed.</span>")
	owner.playsound_local(owner, 'sound/effects/light_flicker.ogg', 50, FALSE)


//Reactivate Camera Network: Reactivates up to 30 cameras across the station.
/datum/AI_Module/small/reactivate_cameras
	module_name = "Восстановление сети камер"
	mod_pick_name = "recam"
	description = "Запускает диагностику всей сети видеонаблюдения, сбрасывая фокус и перенаправляя питание на неисправные устройства. Позволяет восстановить до 30 камер."
	cost = 10
	one_purchase = TRUE
	power_type = /datum/action/innate/ai/reactivate_cameras
	unlock_text = "<span class='notice'>Вы выпускаете нанороботов в систему видеонаблюдения.</span>"
	unlock_sound = 'sound/items/wirecutter.ogg'

/datum/action/innate/ai/reactivate_cameras
	name = "Reactivate Cameras"
	desc = "Reactivates disabled cameras across the station; remaining uses can be used later."
	button_icon_state = "reactivate_cameras"
	uses = 30
	auto_use_uses = FALSE
	cooldown_period = 30

/datum/action/innate/ai/reactivate_cameras/New()
	..()
	desc = "[desc] It has [uses] use\s remaining."

/datum/action/innate/ai/reactivate_cameras/Activate()
	var/fixed_cameras = 0
	for(var/V in GLOB.cameranet.cameras)
		if(!uses)
			break
		var/obj/machinery/camera/C = V
		if(!C.status || C.view_range != initial(C.view_range))
			C.toggle_cam(owner_AI, 0) //Reactivates the camera based on status. Badly named proc.
			C.view_range = initial(C.view_range)
			fixed_cameras++
			uses-- //Not adjust_uses() so it doesn't automatically delete or show a message
	to_chat(owner, "<span class='notice'>Diagnostic complete! Cameras reactivated: <b>[fixed_cameras]</b>. Reactivations remaining: <b>[uses]</b>.</span>")
	owner.playsound_local(owner, 'sound/items/wirecutter.ogg', 50, 0)
	adjust_uses(0, TRUE) //Checks the uses remaining
	if(QDELETED(src) || !uses) //Not sure if not having src here would cause a runtime, so it's here to be safe
		return
	desc = "[initial(desc)] It has [uses] use\s remaining."
	UpdateButtons()

//Upgrade Camera Network: EMP-proofs all cameras, in addition to giving them X-ray vision.
/datum/AI_Module/large/upgrade_cameras
	module_name = "Обновление сети камер"
	mod_pick_name = "upgradecam"
	description = "Установка прошивки для широкополосного сканирования и электрического резервирования в сеть камер. Обеспечивает защиту от ЭМИ и рентгеновское зрение с усилением света."
	one_purchase = TRUE
	cost = 35 //Decent price for omniscience!
	upgrade = TRUE
	unlock_text = "<span class='notice'>Распространение прошивки по воздуху (OTA) завершено! Камеры обновлены: Пакет CAMSUPGRADED активен. Система усиления света подключена.</span>"
	unlock_sound = 'sound/items/rped.ogg'

/datum/AI_Module/large/upgrade_cameras/upgrade(mob/living/silicon/ai/AI)
	AI.see_override = SEE_INVISIBLE_MINIMUM //Night-vision, without which X-ray would be very limited in power.
	AI.update_sight()

	var/upgraded_cameras = 0
	for(var/V in GLOB.cameranet.cameras)
		var/obj/machinery/camera/C = V
		if(C.assembly)
			var/upgraded = 0

			if(!C.isXRay())
				C.upgradeXRay()
				//Update what it can see.
				GLOB.cameranet.updateVisibility(C, 0)
				upgraded = 1

			if(!C.isEmpProof())
				C.upgradeEmpProof()
				upgraded = 1

			if(upgraded)
				upgraded_cameras++

	unlock_text = replacetext(unlock_text, "CAMSUPGRADED", "<b>[upgraded_cameras]</b>") //This works, since unlock text is called after upgrade()

/datum/AI_Module/large/eavesdrop
	module_name = "Улучшенное наблюдение"
	mod_pick_name = "eavesdrop"
	description = "Благодаря сочетанию скрытых микрофонов и ПО для чтения по губам, вы получаете возможность использовать свои камеры для прослушивания разговоров."
	cost = 30
	one_purchase = TRUE
	upgrade = TRUE
	unlock_text = "<span class='notice'>Распространение прошивки по воздуху (OTA) завершено! Камеры обновлены: пакет расширенного наблюдения в сети.</span>"
	unlock_sound = 'sound/items/rped.ogg'

/datum/AI_Module/large/eavesdrop/upgrade(mob/living/silicon/ai/AI)
	if(AI.eyeobj)
		AI.eyeobj.relay_speech = TRUE

#undef DEFAULT_DOOMSDAY_TIMER
#undef DOOMSDAY_ANNOUNCE_INTERVAL
