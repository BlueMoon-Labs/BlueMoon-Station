/datum/controller/subsystem/economy
	/// Тип баунти -> сколько раз его недавно сдали: от этого падает награда повторов
	var/list/contract_demand = list()

/// Множитель награды заказа по спросу: каждая недавняя сдача снимает contract_repeat_step процентов, но не ниже contract_repeat_floor.
/datum/controller/subsystem/economy/proc/contract_demand_mult(bounty_type)
	var/repeats = contract_demand[bounty_type]
	if(!repeats)
		return 1
	return max(1 - repeats * settings.contract_repeat_step / 100, settings.contract_repeat_floor / 100)

/datum/controller/subsystem/economy/proc/note_contract_demand(bounty_type)
	contract_demand[bounty_type] += 1

/// Раз в тик экономики: за возраст ротации доски спрос возвращается на один шаг.
/datum/controller/subsystem/economy/proc/recover_contract_demand()
	var/step = 1 / max(settings.contract_rotation_ticks, 1)
	for(var/bounty_type in contract_demand)
		contract_demand[bounty_type] -= step
		if(contract_demand[bounty_type] <= 0.001)
			contract_demand -= bounty_type
