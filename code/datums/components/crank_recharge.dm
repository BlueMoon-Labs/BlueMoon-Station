// Ручная зарядка для разнокалиберного самодельного оружия вроде лазерного мушкета и термальных пистолетов.
/datum/component/crank_recharge
	/// Наша ячейка, которую мы заряжаем
	var/obj/item/stock_parts/cell/charging_cell
	/// Крутим ли мы оружие для перезарядки (и требуется ли соответствующий трейт)
	var/spin_to_win = FALSE
	/// Сколько заряда даём ячейке за один поворот рукоятки
	var/charge_amount
	/// Как долго длится перезарядка
	var/cooldown_time
	/// Звук, используемый при зарядке
	var/charge_sound
	/// Как долго длится задержка между звуками зарядки
	var/charge_sound_cooldown_time
	/// Заряжаемся ли мы прямо сейчас
	var/is_charging = FALSE
	/// Можно ли двигаться во время зарядки; используйте IGNORE_USER_LOC_CHANGE чтобы двигаться и крутить рукоятку
	var/charge_move = NONE
	COOLDOWN_DECLARE(charge_sound_cooldown)

/datum/component/crank_recharge/Initialize(charging_cell, spin_to_win = FALSE, charge_amount = 500, cooldown_time = 2 SECONDS, charge_sound = 'sound/items/weapons/laser_crank.ogg', charge_sound_cooldown_time = 1.8 SECONDS, charge_move = NONE)
	. = ..()
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE
	if(!istype(charging_cell, /obj/item/stock_parts/cell))
		return COMPONENT_INCOMPATIBLE
	src.charging_cell = charging_cell
	src.spin_to_win = spin_to_win
	src.charge_amount = charge_amount
	src.cooldown_time = cooldown_time
	src.charge_sound = charge_sound
	src.charge_sound_cooldown_time = charge_sound_cooldown_time
	src.charge_move = charge_move

/datum/component/crank_recharge/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_ITEM_ATTACK_SELF, PROC_REF(on_attack_self))

/datum/component/crank_recharge/UnregisterFromParent()
	. = ..()
	UnregisterSignal(parent, COMSIG_ITEM_ATTACK_SELF)

/datum/component/crank_recharge/proc/on_attack_self(obj/source, mob/living/user)
	SIGNAL_HANDLER

	INVOKE_ASYNC(src, PROC_REF(crank), source, user) //игре не нравится совмещение сигнал-хендлера и do_after
	return COMPONENT_CANCEL_ATTACK_CHAIN

/datum/component/crank_recharge/proc/crank(obj/source, mob/user)
	if(charging_cell.charge >= charging_cell.maxcharge)
		source.balloon_alert(user, "уже заряжен!")
		return
	if(is_charging)
		return
	if(spin_to_win)
		source.balloon_alert(user, "нужен повертее, чтобы крутить!")
		return

	is_charging = TRUE
	if(COOLDOWN_FINISHED(src, charge_sound_cooldown))
		COOLDOWN_START(src, charge_sound_cooldown, charge_sound_cooldown_time)
		playsound(source, charge_sound, 40)
	source.balloon_alert(user, "зарядка...")
	if(!do_after(user, cooldown_time, source, timed_action_flags = charge_move))
		is_charging = FALSE
		return
	charging_cell.give(charge_amount)
	source.update_appearance()
	is_charging = FALSE
	if(spin_to_win)
		source.SpinAnimation(4, 2) //Какой же крутой
	source.balloon_alert(user, "заряжено")
