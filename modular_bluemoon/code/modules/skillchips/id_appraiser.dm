/obj/item/card/id/examine(mob/user)
	. = ..()
	if(mining_points)
		. += "У этой карты [mining_points] рудокопных очков карго; всего было заработано [mining_points_total] очков."
	if(contraband_points)
		. += "<span class='info'>У этой карты [contraband_points] очков Авангарда.</span>"
	if(!bank_support || (bank_support == ID_LOCKED_BANK_ACCOUNT && !registered_account))
		. += "<span class='info'>Эта ID-карта не имеет банковского счёта. Должно быть, устаревшая модель...</span>"
	else if(registered_account)
		. += "Привязанный к ID-карте аккаунт записан на имя \"[registered_account.account_holder]\" и сообщает о балансе [registered_account.account_balance] кр."
		if(registered_account.account_job)
			var/datum/bank_account/D = SSeconomy.get_dep_account(registered_account.account_job.paycheck_department)
			if(D)
				. += "На балансе [vocabulary_to_ru(GLOB.budget_ru_genitive, D.account_holder)] находится [D.account_balance] кр."
		. += "<span class='info'>Alt-Click по ID-карте, чтобы снять деньги с аккаунта в форме голочипов.</span>"
		. += "<span class='info'>Вы можете внести кредиты на аккаунт, приложив голочипы, наличные или монеты к ID-карте.</span>"
		if(registered_account.civilian_bounty)
			. += "<span class='info'><b>Есть активное гражданское баунти:</b>"
			. += "<span class='info'><i>[registered_account.bounty_text()]</i></span>"
			. += "<span class='info'>Количество: [registered_account.bounty_num()]</span>"
			. += "<span class='info'>Награда: [registered_account.bounty_value()]</span>"
		if(registered_account.account_holder == user.real_name)
			. += "<span class='boldnotice'>Если вы потеряете эту ID-карту, вы можете восстановить свой аккаунт, нажав Alt-Click по пустой ID-карту, держа её в руках, и введя номер своего банковского счёта.</span>"
	else
		. += "<span class='info'>Нет зарегистрированного аккаунта. Alt-Click, чтобы добавить.</span>"

	if(!HAS_TRAIT(user, TRAIT_ID_APPRAISER))
		return
	var/centcomp_card = istype(src, /obj/item/card/id/centcom) || (ACCESS_CENT_GENERAL in access)
	. += centcomp_card \
		? span_nicegreen("Гм... да, эта ID-карта выдана Центральным Командованием с самого начала!") \
		: span_notice("Эта ID-карта была создана в этом секторе, а не Центральным Командованием.")
