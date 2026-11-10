/// Серия поставок: этапы идут по одному, каждый оплачивается сразу, за последний - премия от суммы всех этапов.
/datum/econ_contract/delivery/chain
	/// Типы баунти следующих этапов, текущий этап - в bounty
	var/list/next_stages
	var/stage = 1
	var/stages_total = 1
	/// Сумма наград уже оплаченных этапов
	var/stages_paid = 0

/datum/econ_contract/delivery/chain/New(department_id, datum/bounty/bounty, list/next_stages)
	..()
	src.next_stages = next_stages || list()
	stages_total = length(src.next_stages) + 1

/datum/econ_contract/delivery/chain/kind()
	return "chain"

/datum/econ_contract/delivery/chain/proc/final_stage()
	return stage >= stages_total

/datum/econ_contract/delivery/chain/payout()
	. = ..()
	if(final_stage())
		. += round((stages_paid + .) * SSeconomy.settings.contract_chain_bonus / 100)

/datum/econ_contract/delivery/chain/has_progress()
	return stage > 1 || ..()

/datum/econ_contract/delivery/chain/rep_value()
	return ..() + 1

/datum/econ_contract/delivery/chain/ship(atom/movable/thing, mob/performer)
	if(final_stage())
		return ..()
	note_contribution(performer)
	bounty.ship(thing)
	if(bounty.can_claim())
		finish_stage(performer)

/// Этап закрыт: награда этапа выплачена, серия переходит к следующему заказу, взятой серии срок отсчитывается заново.
/datum/econ_contract/delivery/chain/proc/finish_stage(mob/performer)
	var/total = payout()
	var/to_people = pay_reward(total, performer)
	stages_paid += total
	log_econ("Контракт #[uid] \"[title]\" отдела [department_id]: этап [stage] из [stages_total] выполнен[performer ? " ([key_name(performer)])" : ""]: [total] кр., исполнителю [to_people]")
	SSeconomy.note_contract_demand(bounty.type)
	var/next_type = next_stages[1]
	next_stages.Cut(1, 2)
	qdel(bounty)
	set_bounty(new next_type)
	stage++
	contributions = null
	if(taker)
		taker.bank_card_talk("Серия поставок: этап [stage - 1] из [stages_total] закрыт, следующий заказ - \"[title]\".")
		if(!urgent)
			set_deadline(world.time + ECON_CONTRACT_TAKEN_TIME)

/datum/econ_contract/delivery/chain/taken_text()
	return "Серия поставок закреплена за вами: [stages_total] этапа, ваша доля - [performer_share()]% награды каждого, за последний - премия [SSeconomy.settings.contract_chain_bonus]% от суммы этапов."

/datum/econ_contract/delivery/chain/ui_entry()
	. = ..()
	.["stage"] = stage
	.["stages"] = stages_total
	.["chain_bonus"] = SSeconomy.settings.contract_chain_bonus

/// Серия из первого заказа first и ещё ECON_CONTRACT_CHAIN_STAGES - 1 заказов из bounty_types; если заказов не хватает - обычная поставка.
/datum/controller/subsystem/economy/proc/generate_chain(department_id, datum/bounty/first, list/bounty_types)
	var/list/next_stages = list()
	while(length(next_stages) < ECON_CONTRACT_CHAIN_STAGES - 1)
		var/datum/bounty/next = pick_bounty(bounty_types)
		if(!next)
			break
		next_stages += next.type
		qdel(next)
	if(length(next_stages) < ECON_CONTRACT_CHAIN_STAGES - 1)
		return new /datum/econ_contract/delivery(department_id, first)
	return new /datum/econ_contract/delivery/chain(department_id, first, next_stages)
