/datum/controller/subsystem/economy/proc/treasury()
	var/datum/economy_department/command = departments[ACCOUNT_CMD]
	return command?.account

/// Выплата человеку с налогом; из бюджета аванпоста внестанционному счёту - без налога: деньги аванпоста не уходят в казну станции, а станционный со сканером аванпоста платит как обычно.
/datum/controller/subsystem/economy/proc/pay_personal(datum/bank_account/source, datum/bank_account/target, amount, reason, mob/actor, memo)
	if(!move(source, target, amount, reason, actor, memo))
		return 0
	if(econ_is_outpost_budget(source) && target.offstation)
		return round(amount)
	return collect_tax(target, round(amount), reason, actor)

/// Удерживает налог с уже зачисленного дохода, возвращает остаток после налога.
/datum/controller/subsystem/economy/proc/collect_tax(datum/bank_account/target, amount, reason, mob/actor)
	if(!tax_rate || reason == ECON_WAGE_FLOOR || istype(target, /datum/bank_account/department) || !(GLOB.econ_reason_category[reason] in GLOB.econ_taxable_categories))
		return amount
	var/tax = round(amount * tax_rate / 100)
	if(tax <= 0)
		return amount
	var/nt_part = round(tax * tax_nt_share_now() / 100)
	if(nt_part > 0 && !move(target, null, nt_part, ECON_TAX_NT, actor, "Налог [tax_rate]%: доля NT"))
		return amount
	if(tax - nt_part > 0 && !move(target, treasury(), tax - nt_part, ECON_TAX, actor, "Налог [tax_rate]%: в казну"))
		return amount - nt_part
	return amount - tax

/// Какую долю налога сейчас забирает NT, проценты: при недовольстве экипажа больше.
/datum/controller/subsystem/economy/proc/tax_nt_share_now()
	return tax_mood == TAX_MOOD_UNREST ? settings.tax_unrest_nt_share : settings.tax_nt_share

/datum/controller/subsystem/economy/proc/set_tax_rate(rate, mob/user)
	if(!isnum(rate))
		return FALSE
	tax_rate = clamp(round(rate), 0, settings.tax_max)
	log_econ("Налог установлен в [tax_rate]%[user ? " ([key_name(user)])" : ""]")
	update_tax_mood()
	return TRUE

/datum/controller/subsystem/economy
	/// TAX_MOOD_*, в чьей полосе налог был при последнем пересчёте
	var/tax_band = TAX_MOOD_NONE
	/// TAX_MOOD_* -> сколько налог набрал в этой полосе, децисекунды, не больше tax_mood_minutes; вне полосы набранное убывает с той же скоростью
	var/list/tax_band_held = list(TAX_MOOD_UNREST = 0, TAX_MOOD_GOODWILL = 0)
	/// world.time последнего пересчёта tax_band_held
	var/tax_band_checked = 0
	/// Действующее настроение экипажа, TAX_MOOD_*
	var/tax_mood = TAX_MOOD_NONE
	var/tax_mood_timer

/// Полоса налога; довольства без прибавки к премии нет вовсе.
/datum/controller/subsystem/economy/proc/tax_band_of(rate)
	if(rate > settings.tax_unrest_above)
		return TAX_MOOD_UNREST
	if(rate <= settings.tax_goodwill_upto && settings.tax_goodwill_premium_bonus > 0)
		return TAX_MOOD_GOODWILL
	return TAX_MOOD_NONE

/// Сколько налог набрал в полосе band к этой минуте, децисекунды.
/datum/controller/subsystem/economy/proc/tax_band_held_now(band)
	var/elapsed = max(world.time - tax_band_checked, 0)
	return clamp((tax_band_held[band] || 0) + (band == tax_band ? elapsed : -elapsed), 0, settings.tax_mood_minutes MINUTES)

/// Сверяет настроение экипажа с налогом: время в полосе копится и вне её убывает, так что сброс налога на минуту отсчёт не обнуляет. Настроение действует, пока налог в своей полосе и набрал tax_mood_minutes. Возвращает объявление, если настроение сменилось.
/datum/controller/subsystem/economy/proc/update_tax_mood()
	if(round_over())
		return null
	for(var/band in tax_band_held)
		tax_band_held[band] = tax_band_held_now(band)
	tax_band_checked = world.time
	tax_band = tax_band_of(tax_rate)
	var/limit = settings.tax_mood_minutes MINUTES
	var/mood = tax_band != TAX_MOOD_NONE && tax_band_held[tax_band] >= limit ? tax_band : TAX_MOOD_NONE
	deltimer(tax_mood_timer)
	tax_mood_timer = null
	if(tax_band != TAX_MOOD_NONE && mood == TAX_MOOD_NONE)
		tax_mood_timer = addtimer(CALLBACK(src, PROC_REF(update_tax_mood)), limit - tax_band_held[tax_band], TIMER_STOPPABLE)
	if(mood == tax_mood)
		return null
	var/old_mood = tax_mood
	tax_mood = mood
	. = tax_mood_text(old_mood)
	log_econ("Настроение экипажа: [mood || "обычное"] (налог [tax_rate]%)")
	minor_announce(., "Настроения экипажа")

/datum/controller/subsystem/economy/proc/tax_mood_text(old_mood)
	switch(tax_mood)
		if(TAX_MOOD_UNREST)
			return "Налог выше [settings.tax_unrest_above]% держится уже [settings.tax_mood_minutes] мин. (сейчас [tax_rate]%), экипаж недоволен и работает спустя рукава. Пока налог выше [settings.tax_unrest_above]%, отделы получают за работу на [settings.tax_unrest_work_cut]% меньше, премии за работу тоже ниже, а NT забирает [settings.tax_unrest_nt_share]% налога вместо [settings.tax_nt_share]%."
		if(TAX_MOOD_GOODWILL)
			return "Налог не выше [settings.tax_goodwill_upto]% держится уже [settings.tax_mood_minutes] мин. (сейчас [tax_rate]%), экипаж доволен. Пока налог не выше [settings.tax_goodwill_upto]%, премия за работу - [work_premium_share()]% вместо [settings.work_personal_share]%."
	if(old_mood == TAX_MOOD_UNREST)
		return "Налог снижен до [tax_rate]%, недовольство улеглось: отделы снова получают за работу полностью."
	return "Налог поднят до [tax_rate]%: премия за работу снова [settings.work_personal_share]%."

/// Множитель оплаты работы отделам: при недовольстве налогом она ниже.
/datum/controller/subsystem/economy/proc/work_pay_mult()
	return tax_mood == TAX_MOOD_UNREST ? (100 - settings.tax_unrest_work_cut) / 100 : 1

/// Сколько отдел сейчас получает за единицу работы: цена из прайса с поправкой на настроение экипажа.
/datum/controller/subsystem/economy/proc/work_price(work_type)
	return (settings.work_prices[work_type] || 0) * work_pay_mult()

/// Цена работы для осмотров и окон: с поправкой на настроение, до сотых.
/proc/econ_shown_work_price(work_type)
	return round(SSeconomy.work_price(work_type), 0.01)

/// Процент премии исполнителю от оплаты работы: при довольстве налогом выше.
/datum/controller/subsystem/economy/proc/work_premium_share()
	return settings.work_personal_share + (tax_mood == TAX_MOOD_GOODWILL ? settings.tax_goodwill_premium_bonus : 0)

/// Строка для окон о действующем настроении экипажа; пусто, если его нет.
/datum/controller/subsystem/economy/proc/tax_mood_note()
	switch(tax_mood)
		if(TAX_MOOD_UNREST)
			return "Экипаж недоволен налогом выше [settings.tax_unrest_above]%: отделы получают за работу на [settings.tax_unrest_work_cut]% меньше, премии за работу тоже ниже, NT забирает [settings.tax_unrest_nt_share]% налога."
		if(TAX_MOOD_GOODWILL)
			return "Экипаж доволен налогом до [settings.tax_goodwill_upto]%: премия за работу [work_premium_share()]% вместо [settings.work_personal_share]%."
	return ""

/// Через сколько минут налог в нынешней полосе сменит настроение экипажа; null - не сменит.
/datum/controller/subsystem/economy/proc/tax_mood_minutes_left()
	var/band = tax_band_of(tax_rate)
	if(band == TAX_MOOD_NONE || band == tax_mood || band != tax_band)
		return null
	return max(CEILING((settings.tax_mood_minutes MINUTES - tax_band_held_now(band)) / (1 MINUTES), 1), 1)

/// Сколько налог уже держится в полосе, которая ещё не сменила настроение: "держится N из M мин."; пусто вне полос и при действующем настроении.
/datum/controller/subsystem/economy/proc/tax_mood_progress()
	if(isnull(tax_mood_minutes_left()))
		return ""
	var/held = round(tax_band_held_now(tax_band) / (1 MINUTES))
	if(tax_band == TAX_MOOD_UNREST)
		return "Налог выше [settings.tax_unrest_above]% держится [held] из [settings.tax_mood_minutes] мин.: дальше экипаж станет недоволен."
	return "Налог не выше [settings.tax_goodwill_upto]% держится [held] из [settings.tax_mood_minutes] мин.: дальше экипаж будет доволен."

/// Предупреждение тому, кто ставит налог: что будет, если он продержится; пусто, если ничего не изменится.
/datum/controller/subsystem/economy/proc/tax_mood_hint()
	var/left = tax_mood_minutes_left()
	if(!left)
		return ""
	if(tax_band == TAX_MOOD_UNREST)
		return "Если налог продержится выше [settings.tax_unrest_above]% ещё [left] мин., экипаж станет недоволен: отделы будут получать за работу на [settings.tax_unrest_work_cut]% меньше."
	return "Если налог продержится не выше [settings.tax_goodwill_upto]% ещё [left] мин., экипаж будет доволен: премия за работу вырастет до [settings.work_personal_share + settings.tax_goodwill_premium_bonus]%."

/datum/controller/subsystem/economy/proc/treasury_transfer(datum/economy_department/target, amount, mob/user)
	if(!target || target.id == ACCOUNT_CMD)
		return FALSE
	return move(treasury(), target.account, amount, ECON_BUDGET_TRANSFER, user, "Из казны: [target.name]")

/datum/controller/subsystem/economy/proc/department_transfer(datum/economy_department/source, datum/economy_department/target, amount, mob/user)
	if(!source || !target || source == target)
		return FALSE
	return move(source.account, target.account, amount, ECON_BUDGET_TRANSFER, user, "[source.name] -> [target.name]")

/datum/bank_account
	/// Открыт из казны: пока у счёта нет owner_ref, он в лимите treasury_unowned_accounts_max; привязка к карте Alt-кликом owner_ref не ставит, так что лимит фактически на смену
	var/opened_by_treasury = FALSE

/datum/controller/subsystem/economy/proc/unowned_treasury_accounts()
	. = 0
	for(var/datum/bank_account/account as anything in bank_accounts)
		if(account.opened_by_treasury && !account.owner_ref)
			.++

/datum/controller/subsystem/economy/proc/open_account(holder, starting_funds, mob/user)
	if(!istext(holder) || !length(holder) || !isnum(starting_funds) || starting_funds < 0)
		return null
	if(unowned_treasury_accounts() >= settings.treasury_unowned_accounts_max)
		return null
	starting_funds = round(starting_funds)
	var/datum/bank_account/department/treasury = treasury()
	if(starting_funds && !treasury?.has_money(starting_funds))
		return null
	var/datum/bank_account/opened = new(holder)
	opened.opened_by_treasury = TRUE
	if(starting_funds && !move(treasury, opened, starting_funds, ECON_BUDGET_TRANSFER, user, "Открытие счёта"))
		qdel(opened)
		return null
	log_econ("Открыт счёт [holder] №[opened.account_id] с [starting_funds] кр.[user ? " ([key_name(user)])" : ""]")
	return opened
