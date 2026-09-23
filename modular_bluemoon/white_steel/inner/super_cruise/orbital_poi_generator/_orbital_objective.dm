/datum/orbital_objective
	var/name = "Null Objective"
	var/datum/orbital_object/z_linked/beacon/ruin/linked_beacon
	var/payout = 0
	var/completed = FALSE
	var/min_payout = 0
	var/max_payout = 0
	var/id = 0
	var/station_name
	var/static/objective_num = 0

/datum/orbital_objective/New()
	. = ..()
	id = objective_num ++
	station_name = new_station_name()

/datum/orbital_objective/proc/on_assign(obj/machinery/computer/objective/objective_computer)
	return

/datum/orbital_objective/proc/generate_objective_stuff(turf/chosen_turf)
	return

/datum/orbital_objective/proc/check_failed()
	return TRUE

/datum/orbital_objective/proc/get_text()
	return ""

/datum/orbital_objective/proc/generate_payout()
	payout = rand(min_payout, max_payout)

/datum/orbital_objective/proc/generate_attached_beacon()
	linked_beacon = new
	linked_beacon.name = "(ЗАДАНИЕ) [linked_beacon.name]"
	linked_beacon.linked_objective = src

/datum/orbital_objective/proc/remove_objective()
	QDEL_NULL(SSorbits.current_objective)

/datum/orbital_objective/proc/complete_objective()
	if(completed)
		//Delete
		QDEL_NULL(SSorbits.current_objective)
		return
	completed = TRUE
	//Handle payout
	var/rangers_count = 0
	for(var/I in SSjob.occupations)
		var/datum/job/J = I
		if(istype(J, /datum/job/expeditor))
			rangers_count = J.current_positions

	var/israel = 0
	if(rangers_count)
		israel = round((payout / 2) / rangers_count)
	var/goyam  = round((payout / 2) / max(SSeconomy.generated_accounts.len, 1))
	for(var/B in SSeconomy.bank_accounts_by_id)
		var/datum/bank_account/A = SSeconomy.bank_accounts_by_id[B]
		if(istype(A.account_job, /datum/job/expeditor))
			A.bank_card_talk("Было получено [israel] кредитов за выполнение задания.")
			A.adjust_money(israel)
		else
			A.bank_card_talk("Было получено [goyam] кредитов за содействие выполнению поручений NanoTrasen.")
			A.adjust_money(goyam)
	//WHITE-STEEL PORT: очки задания. Половина пула начисляется на общий счёт карго,
	//каждый действующий авангард дополнительно получает В ДВА раза больше очков на свой ID.
	var/cargo_share = round(payout / 2)
	GLOB.cargo_objective_points += cargo_share
	for(var/mob/living/carbon/human/H as() in GLOB.human_list)
		if(!H.mind)
			continue
		var/datum/job/J = SSjob.GetJob(H.mind.assigned_role)
		if(!istype(J, /datum/job/expeditor))
			continue
		var/obj/item/card/id/id_card = H.get_idcard(TRUE)
		if(!id_card)
			continue
		id_card.contraband_points += cargo_share * 2
		to_chat(H, span_notice("Вы получили [cargo_share * 2] очков Авангарда за выполнение задания."))
	//Delete
	QDEL_NULL(SSorbits.current_objective)
