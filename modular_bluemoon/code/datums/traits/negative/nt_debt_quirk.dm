/datum/quirk/nt_debt
	name = "В долгах"
	desc = "Персонаж должен NT. Подъёмные при найме уходят в счёт долга, а часть каждой зарплаты на руки списывается, пока долг не погашен. Счёт при этом работает как обычно."
	value = -1
	gain_text = span_warning("Коллекторы NT помнят о вас.")
	lose_text = span_notice("Долг NT больше не висит над вами.")

/datum/quirk/nt_debt/on_spawn()
	var/datum/bank_account/account = econ_account_of(quirk_holder)
	if(!account || account.offstation)
		return
	account.take_nt_debt(SSeconomy.settings.quirk_debt_amount)

/datum/quirk/nt_debt/post_add()
	var/datum/bank_account/account = econ_account_of(quirk_holder)
	if(account?.nt_debt > 0)
		to_chat(quirk_holder, span_warning("Ваш долг NT: [account.nt_debt] кр. Подъёмные ушли коллекторам, [SSeconomy.settings.quirk_debt_wage_share]% каждой зарплаты на руки будет списываться, пока долг не погашен."))
