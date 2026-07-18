#define RULESET_STOP_PROCESSING 1

#define FAKE_REPORT_CHANCE 20
#define REPORT_NEG_DIVERGENCE -15
#define REPORT_POS_DIVERGENCE 15
#define EXTENDED_CURVE_CENTER -7

// Are HIGH_IMPACT_RULESETs allowed to stack?
GLOBAL_VAR_INIT(dynamic_no_stacking, TRUE)
// If enabled does not accept or execute any rulesets.
GLOBAL_VAR_INIT(dynamic_forced_extended, FALSE)
// Antags still allowed, but no roundstart antags + midrounds are low impact
GLOBAL_VAR_INIT(dynamic_extended, FALSE)
// How high threat is required for HIGH_IMPACT_RULESETs stacking.
// This is independent of dynamic_no_stacking.
GLOBAL_VAR_INIT(dynamic_stacking_limit, 90)
// List of forced roundstart rulesets.
GLOBAL_LIST_EMPTY(dynamic_forced_roundstart_ruleset)
// Forced threat level, setting this to zero or higher forces the roundstart threat to the value.
GLOBAL_VAR_INIT(dynamic_forced_threat_level, -1)
// BLUEMOON ADD
// Очки для уровней угрозы от различных вариаций динамика
// Значения изменяются при выборе вариаций динамика
GLOBAL_VAR_INIT(dynamic_type_threat_min, 40)
GLOBAL_VAR_INIT(dynamic_type_threat_max, 60)
// Некоторые пресеты антагонистов не могут выпасть не в свой тип.
GLOBAL_VAR_INIT(round_type, ROUNDTYPE_DYNAMIC_MEDIUM)
// BLUEMOON ADD END

/datum/game_mode/dynamic
	name = "dynamic mode"
	config_tag = "dynamic"
	announce_span = "danger"
	announce_text = "Dynamic mode!" // This needs to be changed maybe
	// Threat logging vars
	/// The "threat cap", threat shouldn't normally go above this and is used in ruleset calculations
	var/threat_level = 0

	/// Set at the beginning of the round. Spent by the mode to "purchase" rules. Everything else goes in the postround budget.
	var/round_start_budget = 0

	/// Set at the beginning of the round. Spent by midrounds and latejoins.
	var/mid_round_budget = 0

	/// The initial round start budget for logging purposes, set once at the beginning of the round.
	var/initial_round_start_budget = 0

	/// Running information about the threat. Can store text or datum entries.
	var/list/threat_log = list()
	/// List of latejoin rules used for selecting the rules.
	var/list/latejoin_rules
	/// List of midround rules used for selecting the rules.
	var/list/midround_rules
	/** # Pop range per requirement.
	  * If the value is five the range is:
	  * 0-4, 5-9, 10-14, 15-19, 20-24, 25-29, 30-34, 35-39, 40-54, 45+
	  * If it is six the range is:
	  * 0-5, 6-11, 12-17, 18-23, 24-29, 30-35, 36-41, 42-47, 48-53, 54+
	  * If it is seven the range is:
	  * 0-6, 7-13, 14-20, 21-27, 28-34, 35-41, 42-48, 49-55, 56-62, 63+
	  */
	var/pop_per_requirement = 6
	/// Number of players who were ready on roundstart.
	var/roundstart_pop_ready = 0
	/// List of candidates used on roundstart rulesets.
	var/list/candidates = list()
	/// Rules that are processed, rule_process is called on the rules in this list.
	var/list/current_rules = list()
	/// List of executed rulesets.
	var/list/executed_rules = list()
	/// Forced ruleset to be executed for the next latejoin.
	var/datum/dynamic_ruleset/latejoin/forced_latejoin_rule = null
	/// If a high impact ruleset was executed. Only one will run at a time in most circumstances.
	var/high_impact_ruleset_executed = FALSE
	/// If a only ruleset has been executed.
	var/only_ruleset_executed = FALSE

	/// A list of recorded "snapshots" of the round, stored in the dynamic.json log
	var/list/datum/dynamic_snapshot/snapshots

	/// The amount of threat shown on the piece of paper.
	/// Can differ from the actual threat amount.
	var/shown_threat

/datum/game_mode/dynamic/admin_panel()
	var/list/dat = list("<html><head><meta http-equiv='Content-Type' content='text/html; charset=utf-8'><title>Game Mode Panel</title></head><body><h1><B>Game Mode Panel</B></h1>")
	dat += "Dynamic Mode <a href='?_src_=vars;[HrefToken()];Vars=[REF(src)]'>\[VV\]</a> <a href='?src=\ref[src];[HrefToken()]'>\[Refresh\]</a><BR>"
	dat += "Threat Level: <b>[threat_level]</b><br/>"
	dat += "Budgets (Roundstart/Midrounds): <b>[initial_round_start_budget]/[threat_level - initial_round_start_budget]</b><br/>"

	dat += "Director budget to spend: <b>[round(SSdirector.total_budget(), 0.1)]</b> <a href='?src=\ref[src];[HrefToken()];adjustthreat=1'>\[Adjust\]</A> <a href='?src=\ref[src];[HrefToken()];threatlog=1'>\[View Log\]</a><br/>"
	dat += "<a href='?_src_=holder;[HrefToken()];director_panel=1'>Открыть Director Panel</a><br/>"
	dat += "<br/>"
	/* BLUEMOON CHANGES START - мы используем GLOB.round_type
	dat += "Forced extended: <a href='?src=\ref[src];[HrefToken()];forced_extended=1'><b>[GLOB.dynamic_forced_extended ? "On" : "Off"]</b></a><br/>"
	dat += "Dynamic extended: <a href='?src=\ref[src];[HrefToken()];extended=1'><b>[GLOB.dynamic_extended ? "On" : "Off"]</b></a><br/>"
	/ BLUEMOON CHANGES END */
	// BLUEMOON ADD START - мы используем GLOB.round_type
	dat += "Dynamic Round Type: <a href='?src=\ref[src];[HrefToken()];round_type_choose=1'><b>[GLOB.round_type]</b></a><br/>"
	// BLUEMOON ADD END
	dat += "No stacking (only one round-ender): <a href='?src=\ref[src];[HrefToken()];no_stacking=1'><b>[GLOB.dynamic_no_stacking ? "On" : "Off"]</b></a><br/>"
	dat += "Stacking limit: [GLOB.dynamic_stacking_limit] <a href='?src=\ref[src];[HrefToken()];stacking_limit=1'>\[Adjust\]</A>"
	dat += "<br/>"
	dat += "<A href='?src=\ref[src];[HrefToken()];force_latejoin_rule=1'>\[Force Next Latejoin Ruleset\]</A><br>"
	if (forced_latejoin_rule)
		dat += {"<A href='?src=\ref[src];[HrefToken()];clear_forced_latejoin=1'>-> [forced_latejoin_rule.name] <-</A><br>"}
	dat += "<A href='?src=\ref[src];[HrefToken()];force_midround_rule=1'>\[Execute Midround Ruleset\]</A><br>"
	dat += "<br />"
	dat += "Executed rulesets: "
	if (executed_rules.len > 0)
		dat += "<br/>"
		for (var/datum/dynamic_ruleset/DR in executed_rules)
			dat += "[DR.ruletype] - <b>[DR.name]</b><br>"
	else
		dat += "none.<br>"
	var/datum/browser/popup = new(usr, "gamemode_panel", "Dynamic Mode", 500, 500)
	popup.set_content(dat.Join())
	popup.open()

/datum/game_mode/dynamic/Topic(href, href_list)
	if (..()) // Sanity, maybe ?
		return
	if(!check_rights(R_ADMIN))
		message_admins("[usr.key] has attempted to override the game mode panel!")
		log_admin("[key_name(usr)] tried to use the game mode panel without authorization.")
		return
	/* BLUEMOON ADD START - мы используем GLOB.round_type
	if (href_list["forced_extended"])
		GLOB.dynamic_forced_extended = !GLOB.dynamic_forced_extended
	else if (href_list["Extended"])
		GLOB.dynamic_extended = !GLOB.dynamic_extended
	/ BLUEMOON ADD END */
	// BLUEMOON ADD START
	if (href_list["round_type_choose"])
		var/chosen_type = input("Выберите вариацию динамика","Round Type Choose") as null|anything in list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_LIGHT)
		message_admins("[key_name(usr)] изменяет режим игры [GLOB.round_type] на [chosen_type]. Это повлияет только на доступность появления новых антагонистов.")
		GLOB.round_type = chosen_type
		GLOB.master_mode = "[chosen_type] (Changed Midgame)"
	// BLUEMOON ADD END
	else if (href_list["no_stacking"])
		GLOB.dynamic_no_stacking = !GLOB.dynamic_no_stacking
	else if (href_list["adjustthreat"])
		var/threatadd = input("Укажите, сколько бюджета добавить директору (отрицательное - убавить).", "Adjust Director Budget", 0) as null|num
		if(!threatadd)
			return
		SSdirector.distribute_to_budgets(threatadd)
		threat_log += "[worldtime2text()]: [key_name(usr)] изменил бюджет директора на [threatadd]."
	else if (href_list["threatlog"])
		show_threatlog(usr)
	else if (href_list["stacking_limit"])
		GLOB.dynamic_stacking_limit = input(usr,"Change the threat limit at which round-endings rulesets will start to stack.", "Change stacking limit", null) as num
	else if(href_list["force_latejoin_rule"])
		var/added_rule = input(usr,"What ruleset do you want to force upon the next latejoiner? This will bypass threat level and population restrictions.", "Rigging Latejoin", null) as null|anything in sortNames(init_rulesets(/datum/dynamic_ruleset/latejoin))
		if (!added_rule)
			return
		forced_latejoin_rule = added_rule
		log_admin("[key_name(usr)] set [added_rule] to proc on the next latejoin.")
		message_admins("[key_name(usr)] set [added_rule] to proc on the next latejoin.")
	else if(href_list["clear_forced_latejoin"])
		forced_latejoin_rule = null
		log_admin("[key_name(usr)] cleared the forced latejoin ruleset.")
		message_admins("[key_name(usr)] cleared the forced latejoin ruleset.")
	else if(href_list["force_midround_rule"])
		var/added_rule = input(usr,"What ruleset do you want to force right now? This will bypass threat level and population restrictions.", "Execute Ruleset", null) as null|anything in sortNames(init_rulesets(/datum/dynamic_ruleset/midround))
		if (!added_rule)
			return
		// То же предупреждение о насыщении, что и у форса событий: рулсет поверх
		// заполненной антаг-цели - осознанное решение, а не случайный стак.
		if(!SSdirector.confirm_antag_force(usr, added_rule))
			return
		log_admin("[key_name(usr)] executed the [added_rule] ruleset.")
		message_admins("[key_name(usr)] executed the [added_rule] ruleset.")
		picking_specific_rule(added_rule, TRUE)

	admin_panel() // Refreshes the window

// Checks if there are HIGH_IMPACT_RULESETs and calls the rule's round_result() proc
/datum/game_mode/dynamic/set_round_result()
	// If it got to this part, just pick one high impact ruleset if it exists
	for(var/datum/dynamic_ruleset/rule in executed_rules)
		if(rule.flags & HIGH_IMPACT_RULESET)
			return rule.round_result()
	return ..()

/datum/game_mode/dynamic/send_intercept()
	. = "<b><i>Отчёт от Центрального Командования</i></b><hr>"
	switch(round(shown_threat))
		if(0 to 19)
			if(!current_players[CURRENT_LIVING_ANTAGS].len)
				. += "<b>Мирный Сектор</b></center><BR>"
				. += "Ваша станция вращается глубоко внутри контролируемых систем центрального сектора и служит путевой точкой для обычных перевозок через торговые пути Нанотрейзен. Из-за сочетания высокой безопасности, межзвездного трафика и низкой стратегической ценности он делает любую прямую угрозу вторжения маловероятной. Вашими главными врагами будут некомпетентность и скучающие члены экипажа: постарайтесь организовать тимбилдинговые мероприятия, чтобы сотрудники были заинтересованы и продуктивны."
			else
				. += "<b>Центральная Территория</b></center><BR>"
				. += "Ваша станция вращается в надёжно обыденном, безопасном пространстве. Несмотря на то, что Нанотрейзен крепко контролирует безопасность в вашем регионе, ценные ресурсы и стратегическое положение на борту вашей станции делают ее потенциальной мишенью для вторжения. Следите за нелояльным поведением экипажа, но ожидайте относительно спокойной смены без крупномасштабных разрушений. Мы ожидаем больших успехов от вашей станции."
		if(20 to 39)
			. += "<b>Аномальная Экзогеология</b></center><BR>"
			. += "Хотя ваша станция находится в секторе, обычно считающемся контролируемым Нанотрейзеном, курс ее орбиты привел к тому, что она прошла необычно близко к экзогеологическим объектам с аномальными показаниями. Хотя эти особенности открывают возможности для нашего исследовательского отдела, известно, что эти малопонятные показания часто коррелируют с повышенной активностью со стороны конкурирующих межзвездных организаций и отдельных лиц, среди которых Федерация Волшебников и Культ Геометра Крови — все известные конкуренты объектов Аномального Типа Б. Соблюдайте повышенную осторожность."
		if(40 to 65)
			. += "<b>Оспариваемый Сектор</b></center><BR>"
			. += "Орбита вашей станции проходит по краю сферы влияния Нанотрейзена. В то время как подрывные элементы остаются наиболее вероятной угрозой для вашей станции, враждебные организации действуют смелее здесь, где наша хватка слабее. Соблюдайте повышенную осторожность в отношении элитных ударных сил ИнтеКью, или запретите какие-либо непродуманные попытки объединения в профсоюзы."
		if(66 to 79)
			. += "<b>Неизведанный Космос</b></center><BR>"
			. += "Поздравляем и благодарим вас за участие в космической программе NT Frontier! Ваша станция активно вращается вокруг важной системы вдали от ближайших станций поддержки. Мало что известно о вашем секторе космоса, а возможность столкнуться с неизведанным принесет большую славу. Вам рекомендуется повысить уровень безопасности, если это необходимо для защиты активов Нанотрейзен."
		if(80 to 99)
			. += "<b>Черная Орбита</b></center><BR>"
			. += "В рамках обязательного протокола безопасности мы должны сообщить вам, что в результате того, что ваша орбитальная схема находится непосредственно за астрологическим телом (ориентируемым из ближайшей к нам обсерватории), ваша станция будет находиться под ограниченным контролем и поддержкой. Ожидается, что ваше экстремальное местоположение и ослабленное наблюдение могут представлять угрозу безопасности. Избегайте неоправданных рисков и старайтесь сохранить свою станцию в целости и сохранности."
		if(100)
			. += "<b>Надвигающаяся Гибель</b></center><BR>"
			. += "Ваша станция каким-то образом появилась посреди враждебной территории и совсем рядом с Аномалией 'Око Синих Лун', на виду у любого врага корпорации. Ваши шансы выжить малы, а разрушение станции ожидаемо и почти неизбежно. Защитите любой конфиденциальный материал и нейтрализуйте любого врага, с которым вы столкнетесь. Важно, чтобы вы хотя бы попытались сохранить станцию.<BR>"
			. += "Удачи =)"

	if(station_goals.len)
		. += "<hr><b>Специальные указы для [station_name()]:</b><br>"
		for(var/datum/station_goal/G in station_goals)
			G.on_report()
			. += "[G.get_report()]<hr>"

	print_command_report(., "Отдел ССО ПАКТа Синих Лун", announce=FALSE)
	priority_announce("Благодаря неустанным усилиям наших специальных оперативных подразделений мы обнаружили несколько возможных угроз для [station_name()]. Будьте осторожней!", "Отдел ССО ПАКТа Синих Лун", "intercept")

/datum/game_mode/dynamic/proc/show_threatlog(mob/admin)
	if(!SSticker.HasRoundStarted())
		tgui_alert(usr, "The round hasn't started yet!")
		return

	if(!check_rights(R_ADMIN))
		return

	var/list/out = list("<TITLE>Threat Log</TITLE><B><font size='3'>Threat Log</font></B><br><B>Starting Threat:</B> [threat_level]<BR>")

	for(var/entry in threat_log)
		if(istext(entry))
			out += "[entry]<BR>"

	out += "<B>Director budget/threat_level:</B> [round(SSdirector.total_budget(), 0.1)]/[threat_level]"

	var/datum/browser/popup = new(usr, "threatlog", "Threat Log", 700, 500)
	popup.set_content(out.Join())
	popup.open()

/// Выставляет отображаемую угрозу и roundstart-бюджет; каплю и мидраунды ведёт SSdirector.
/datum/game_mode/dynamic/proc/generate_threat()
	// BLUEMOON: пределы уровня угрозы по типу раунда (читаются пресетами антагов и cellular_emporium)
	switch(GLOB.round_type)
		if(ROUNDTYPE_DYNAMIC_TEAMBASED)
			GLOB.dynamic_type_threat_min = 90 //от 1 до 2 командных антагов
			GLOB.dynamic_type_threat_max = 100
			GLOB.dynamic_no_stacking = FALSE //Welcome To Space Iraq
		if(ROUNDTYPE_DYNAMIC_HARD)
			GLOB.dynamic_type_threat_min = 95
			GLOB.dynamic_type_threat_max = 100
		if(ROUNDTYPE_DYNAMIC_MEDIUM)
			GLOB.dynamic_type_threat_min = 50
			GLOB.dynamic_type_threat_max = 100
		if(ROUNDTYPE_DYNAMIC_LIGHT)
			GLOB.dynamic_type_threat_min = 30
			GLOB.dynamic_type_threat_max = 70
		if(ROUNDTYPE_EXTENDED)
			GLOB.dynamic_type_threat_min = 0
			GLOB.dynamic_type_threat_max = 0
		if("dynamic")
			GLOB.master_mode = ROUNDTYPE_DYNAMIC_MEDIUM

	SSdirector.setup_profile()
	var/datum/director_profile/profile = SSdirector.profile
	round_start_budget = rand(profile.roundstart_budget_min, profile.roundstart_budget_max)
	if(GLOB.round_type == ROUNDTYPE_EXTENDED)
		threat_level = 0 // экста репортит нулевую угрозу, без оценки flavor-капли
	else
		threat_level = estimate_display_threat(round_start_budget, profile.base_drip)
	SSblackbox.record_feedback("tally", "director_threat", threat_level)

/// Отображаемая угроза: roundstart-бюджет + оценка капли за типовые 90 минут. Все потребители
/// threat_level (band required_enemies, сентинель 101 в requirements, стакинг-лимит) считают
/// шкалу 0-100, поэтому оценка обязана капаться: хард-профиль без капа давал до 112.5.
/datum/game_mode/dynamic/proc/estimate_display_threat(budget, drip)
	return clamp(round(budget + drip * 90 * 0.5, 0.1), 0, 100)

/// Roundstart-бюджет уже выбран в generate_threat; мидраунд-пул теперь у SSdirector.
/datum/game_mode/dynamic/proc/generate_budgets()
	initial_round_start_budget = round_start_budget
	mid_round_budget = 0 // капает у SSdirector

/datum/game_mode/dynamic/proc/setup_parameters()
	log_game("DYNAMIC: Dynamic mode parameters for the round:")
	log_game("DYNAMIC: No stacking is [GLOB.dynamic_no_stacking ? "Enabled" : "Disabled"].")
	log_game("DYNAMIC: Stacking limit is [GLOB.dynamic_stacking_limit].")
	if(GLOB.dynamic_forced_threat_level >= 0)
		// Кошельки ниже получают форс без капа; витринная шкала для гейтов - 0-100.
		threat_level = clamp(round(GLOB.dynamic_forced_threat_level, 0.1), 0, 100)
		round_start_budget = min(GLOB.dynamic_forced_threat_level / 2, 30)
		SSdirector.setup_profile() // профиль нужен даже при форсе, иначе директор не запустится
		SSdirector.distribute_to_budgets(GLOB.dynamic_forced_threat_level / 2) // совместимость админ-привычки
	else
		generate_threat()
	generate_budgets()
	log_game("DYNAMIC: Dynamic Mode initialized with a Threat Level of... [threat_level]! ([round_start_budget] round start budget)")
	return TRUE

/datum/game_mode/dynamic/proc/setup_shown_threat()
	if (prob(FAKE_REPORT_CHANCE))
		shown_threat = rand(1, 100)
	else
		shown_threat = clamp(threat_level + rand(REPORT_NEG_DIVERGENCE, REPORT_POS_DIVERGENCE), 0, 100)

/datum/game_mode/dynamic/pre_setup()
	setup_parameters()
	setup_shown_threat()
	setup_rulesets()

	// Мидраунды и латеджойны теперь ведёт SSdirector: отдаём ему рулсеты (защита ролей уже применена в init_rulesets).
	SSdirector.register_ruleset_actions(midround_rules)
	SSdirector.register_ruleset_actions(latejoin_rules)

	//We do this here instead of with the midround rulesets and such because these rules can hang refs
	//To new_player and such, and we want the datums to just free when the roundstart work is done
	var/list/roundstart_rules = init_rulesets(/datum/dynamic_ruleset/roundstart)

	for(var/i in GLOB.new_player_list)
		var/mob/dead/new_player/player = i
		if(player.ready == PLAYER_READY_TO_PLAY && player.mind && player.check_preferences())
			roundstart_pop_ready++
			candidates.Add(player)
	log_game("DYNAMIC: Listing [roundstart_rules.len] round start rulesets, and [candidates.len] players ready.")
	if (candidates.len <= 0)
		log_game("DYNAMIC: [candidates.len] candidates.")
		return TRUE
	SSblackbox.record_feedback("tally","dynamic",roundstart_rules.len,"Roundstart rules considered")
	SSblackbox.record_feedback("tally","dynamic",roundstart_pop_ready,"Players readied up")

	if(GLOB.dynamic_forced_roundstart_ruleset.len > 0)
		rigged_roundstart()
	else
		roundstart(roundstart_rules)

	log_game("DYNAMIC: [round_start_budget] round start budget was left, donating it to the director drip.")
	threat_log += "[worldtime2text()]: [round_start_budget] round start budget was left, donating it to the director drip."
	SSdirector.distribute_to_budgets(round_start_budget) // неистраченный roundstart раскладывается по кошелькам директора

	var/starting_rulesets = ""
	for (var/datum/dynamic_ruleset/roundstart/DR in executed_rules)
		starting_rulesets += "[DR.name], "
	log_game("DYNAMIC: Picked the following roundstart rules: [starting_rulesets]")
	candidates.Cut()
	return TRUE

/datum/game_mode/dynamic/post_setup(report)
	for(var/datum/dynamic_ruleset/roundstart/rule in executed_rules)
		rule.candidates.Cut() // The rule should not use candidates at this point as they all are null.
		addtimer(CALLBACK(src, TYPE_PROC_REF(/datum/game_mode/dynamic, execute_roundstart_rule), rule), rule.delay)

	..()

/// Initializes the internal ruleset variables
/datum/game_mode/dynamic/proc/setup_rulesets()
	midround_rules = init_rulesets(/datum/dynamic_ruleset/midround)
	latejoin_rules = init_rulesets(/datum/dynamic_ruleset/latejoin)

/// Returns a list of the provided rulesets.
/// Configures their variables to match config.
/datum/game_mode/dynamic/proc/init_rulesets(ruleset_subtype)
	var/list/rulesets = list()

	for (var/datum/dynamic_ruleset/ruleset_type as anything in subtypesof(ruleset_subtype))
		if (initial(ruleset_type.name) == "")
			continue

		if (initial(ruleset_type.weight) == 0)
			continue

		var/ruleset = new ruleset_type
		SSdirector.apply_role_protection(ruleset)
		rulesets += ruleset

	return rulesets

/// A simple roundstart proc used when dynamic_forced_roundstart_ruleset has rules in it.
/datum/game_mode/dynamic/proc/rigged_roundstart()
	message_admins("[GLOB.dynamic_forced_roundstart_ruleset.len] rulesets being forced. Will now attempt to draft players for them.")
	log_game("DYNAMIC: [GLOB.dynamic_forced_roundstart_ruleset.len] rulesets being forced. Will now attempt to draft players for them.")
	for (var/datum/dynamic_ruleset/roundstart/rule in GLOB.dynamic_forced_roundstart_ruleset)
		SSdirector.apply_role_protection(rule)
		message_admins("Drafting players for forced ruleset [rule.name].")
		log_game("DYNAMIC: Drafting players for forced ruleset [rule.name].")
		rule.mode = src
		rule.acceptable(roundstart_pop_ready, threat_level) // Assigns some vars in the modes, running it here for consistency
		rule.candidates = candidates.Copy()
		rule.trim_candidates()
		if (rule.ready(roundstart_pop_ready, TRUE))
			var/cost = rule.cost
			var/scaled_times = 0
			if (rule.scaling_cost)
				scaled_times = round(max(round_start_budget - cost, 0) / rule.scaling_cost)
				cost += rule.scaling_cost * scaled_times

			spend_roundstart_budget(picking_roundstart_rule(rule, scaled_times, forced = TRUE))

/datum/game_mode/dynamic/proc/roundstart(list/roundstart_rules)
	/* BLUEMOON ADD START - мы используем GLOB.round_type
	if (GLOB.dynamic_forced_extended)
		log_game("DYNAMIC: Starting a round of forced extended.")
		return TRUE
	if (GLOB.dynamic_extended)
		log_game("DYNAMIC: Starting a round of dynamic extended.")
		return TRUE
	/ BLUEMOON ADD END */
	var/list/drafted_rules = list()
	for (var/datum/dynamic_ruleset/roundstart/rule in roundstart_rules)
		if (!rule.weight)
			continue
		// Естественная жеребьёвка обязана уважать те же выключатели, что и биты директора.
		// Ручной форс идёт мимо этого цикла через GLOB.dynamic_forced_roundstart_ruleset.
		if (!rule.enabled || rule.admin_only)
			continue
		if (rule.acceptable(roundstart_pop_ready, threat_level) && round_start_budget >= rule.cost) // If we got the population and threat required
			rule.candidates = candidates.Copy()
			rule.trim_candidates()
			if (rule.ready(roundstart_pop_ready) && rule.candidates.len > 0)
				drafted_rules[rule] = rule.weight

	var/list/rulesets_picked = list()

	// Kept in case a ruleset can't be initialized for whatever reason, we want to be able to only spend what we can use.
	var/round_start_budget_left = round_start_budget

	while (round_start_budget_left > 0)
		var/datum/dynamic_ruleset/roundstart/ruleset = pickweight(drafted_rules)
		if (isnull(ruleset))
			log_game("DYNAMIC: No more rules can be applied, stopping with [round_start_budget_left] left.")
			break

		var/cost = (ruleset in rulesets_picked) ? ruleset.scaling_cost : ruleset.cost
		if (cost == 0)
			stack_trace("[ruleset] cost 0, this is going to result in an infinite loop.")
			drafted_rules[ruleset] = 0
			continue

		if (cost > round_start_budget_left)
			drafted_rules[ruleset] = 0
			continue

		if (check_blocking(ruleset.blocking_rules, rulesets_picked))
			drafted_rules[ruleset] = 0
			continue
		// BLUEMOON ADD START - проверки для вариаций динамика
		if(!(GLOB.round_type in ruleset.required_round_type))
			drafted_rules[ruleset] = 0
			continue
		// BLUEMOON ADD END
		round_start_budget_left -= cost

		rulesets_picked[ruleset] += 1

		if (ruleset.flags & HIGH_IMPACT_RULESET)
			for (var/_other_ruleset in drafted_rules)
				var/datum/dynamic_ruleset/other_ruleset = _other_ruleset
				if (other_ruleset.flags & HIGH_IMPACT_RULESET)
					drafted_rules[other_ruleset] = 0

		if (ruleset.flags & LONE_RULESET)
			drafted_rules[ruleset] = 0

	for (var/ruleset in rulesets_picked)
		spend_roundstart_budget(picking_roundstart_rule(ruleset, rulesets_picked[ruleset] - 1))

	update_log()

/// Initializes the round start ruleset provided to it. Returns how much threat to spend.
/datum/game_mode/dynamic/proc/picking_roundstart_rule(datum/dynamic_ruleset/roundstart/ruleset, scaled_times = 0, forced = FALSE)
	log_game("DYNAMIC: Picked a ruleset: [ruleset.name], scaled [scaled_times] times")

	ruleset.trim_candidates()
	var/added_threat = ruleset.scale_up(roundstart_pop_ready, scaled_times)

	if(ruleset.pre_execute(roundstart_pop_ready))
		ruleset.director_pending_cost += ruleset.cost + added_threat
		threat_log += "[worldtime2text()]: Roundstart [ruleset.name] spent [ruleset.cost + added_threat]. [ruleset.scaling_cost ? "Scaled up [ruleset.scaled_times]/[scaled_times] times." : ""]"
		if(ruleset.flags & ONLY_RULESET)
			only_ruleset_executed = TRUE
		if(ruleset.flags & HIGH_IMPACT_RULESET)
			high_impact_ruleset_executed = TRUE
		executed_rules += ruleset
		return ruleset.cost + added_threat
	else
		stack_trace("The starting rule \"[ruleset.name]\" failed to pre_execute.")
	return FALSE

/// Mainly here to facilitate delayed rulesets. All roundstart rulesets are executed with a timered callback to this proc.
/datum/game_mode/dynamic/proc/execute_roundstart_rule(sent_rule)
	var/datum/dynamic_ruleset/rule = sent_rule
	if(rule.execute())
		if(rule.persistent)
			current_rules += rule
		SSdirector.confirm_action_success(rule)
		new_snapshot(rule)
		return TRUE
	rule.clean_up() // Refund threat, delete teams and so on.
	rule.director_pending_cost = 0
	executed_rules -= rule
	stack_trace("The starting rule \"[rule.name]\" failed to execute.")
	return FALSE

/// Форс-исполнение midround-рулсета админом в обход бюджета и потолков директора.
/// Единственный вызывающий - панель динамика (Execute Midround Ruleset).
/datum/game_mode/dynamic/proc/picking_specific_rule(ruletype, forced = TRUE)
	var/datum/dynamic_ruleset/midround/new_rule
	if(ispath(ruletype))
		new_rule = new ruletype() // Использовать только для midround-рулсетов.
		SSdirector.apply_role_protection(new_rule)
	else if(istype(ruletype, /datum/dynamic_ruleset))
		new_rule = ruletype
	else
		return FALSE

	if(!new_rule)
		return FALSE

	new_rule.trim_candidates()
	if(!new_rule.ready(forced))
		log_game("DYNAMIC: The ruleset [new_rule.name] couldn't be executed due to lack of elligible players.")
		return FALSE

	threat_log += "[worldtime2text()]: Forced rule [new_rule.name]"
	new_rule.pre_execute(current_players[CURRENT_LIVING_PLAYERS].len)
	if (new_rule.execute()) // Не должно падать, раз ready() вернул TRUE.
		if(new_rule.flags & HIGH_IMPACT_RULESET)
			high_impact_ruleset_executed = TRUE
		else if(new_rule.flags & ONLY_RULESET)
			only_ruleset_executed = TRUE
		log_game("DYNAMIC: Making a call to a specific ruleset...[new_rule.name]!")
		executed_rules += new_rule
		if (new_rule.persistent)
			current_rules += new_rule
		SSdirector.note_forced_run(new_rule) // регистрируем запуск в директоре, не трогая бюджет
		return TRUE
	// clean_up() тут не зовём: форс-путь бюджета не списывал, а рефанд clean_up
	// теперь уходит в кошельки SSdirector - была бы бесплатная накачка бюджета.
	// Это совпадает со старой семантикой picking_specific_rule (без clean_up на провале).
	return FALSE

/// Отложенное исполнение midround/latejoin рулсета, выбранного директором.
/// Бюджет уже списан в SSdirector.spend_and_execute; здесь - собственно запуск и бухгалтерия.
/datum/game_mode/dynamic/proc/execute_scheduled_ruleset(datum/dynamic_ruleset/rule)
	threat_log += "[worldtime2text()]: [rule.ruletype] [rule.name] spent [rule.cost]"
	rule.execution_failure_reason = null
	var/assigned_before = length(rule.assigned)
	var/prepared = rule.pre_execute(current_players[CURRENT_LIVING_PLAYERS].len)
	if(!prepared && !rule.execution_failure_reason)
		rule.execution_failure_reason = "pre_execute() не нашёл достаточно кандидатов"
	if (prepared && rule.execute())
		log_game("DYNAMIC: Injected a [rule.ruletype] ruleset [rule.name].")
		if(rule.flags & HIGH_IMPACT_RULESET)
			high_impact_ruleset_executed = TRUE
		else if(rule.flags & ONLY_RULESET)
			only_ruleset_executed = TRUE
		if(rule.ruletype == "Latejoin")
			var/mob/M = pick(rule.candidates)
			message_admins("[key_name(M)] joined the station, and was selected by the [rule.name] ruleset.")
			log_game("DYNAMIC: [key_name(M)] joined the station, and was selected by the [rule.name] ruleset.")
		executed_rules += rule
		rule.candidates.Cut()
		if (rule.persistent)
			current_rules += rule
		new_snapshot(rule)
		SSdirector.confirm_action_success(rule)
		var/assigned_this_attempt = max(0, length(rule.assigned) - assigned_before)
		SSdirector.director_log_beat(SSdirector.collect_signals(), rule, DIRECTOR_BEAT_EXECUTED,
			detail = rule.director_execution_detail(assigned_this_attempt))
		return TRUE
	rule.clean_up()
	SSdirector.note_failed_action(rule, retry_replacement = istype(rule, /datum/dynamic_ruleset/midround))
	var/failure_detail = rule.execution_failure_reason || "execute() вернул FALSE; бюджет возвращён"
	SSdirector.director_log_beat(SSdirector.collect_signals(), rule, DIRECTOR_BEAT_FAILED, detail = failure_detail)
	if(rule.execution_failure_reason)
		log_game("DYNAMIC: [rule.ruletype] ruleset [rule.name] failed: [failure_detail]")
	else
		stack_trace("The [rule.ruletype] rule \"[rule.name]\" failed to execute.")
	return FALSE

/datum/game_mode/dynamic/process()
	// BLUEMOON ADD START - напоминание антагонистам, что они антагонисты
	for(var/datum/antagonist/A in GLOB.antagonists_to_remind)
		A.remind_them_they_are_antagonists()
	// BLUEMOON ADD END
	for (var/datum/dynamic_ruleset/rule in current_rules)
		if(rule.rule_process() == RULESET_STOP_PROCESSING) // If rule_process() returns 1 (RULESET_STOP_PROCESSING), stop processing.
			current_rules -= rule
			SSblackbox.record_feedback("tally","dynamic",1,"Rulesets finished")
	// Драфт мидраундов теперь ведёт SSdirector на своих битах.

/// Removes type from the list
/datum/game_mode/dynamic/proc/remove_from_list(list/type_list, type)
	for(var/I in type_list)
		if(istype(I, type))
			type_list -= I
	return type_list

/// Checks if a type in blocking_list is in rule_list.
/datum/game_mode/dynamic/proc/check_blocking(list/blocking_list, list/rule_list)
	if(blocking_list.len > 0)
		for(var/blocking in blocking_list)
			for(var/_executed in rule_list)
				var/datum/executed = _executed
				if(blocking == executed.type)
					return TRUE
	return FALSE

/datum/game_mode/dynamic/proc/check_age(client/C, age)
	enemy_minimum_age = age
	if(get_remaining_days(C) == 0)
		enemy_minimum_age = initial(enemy_minimum_age)
		return TRUE // Available in 0 days = available right now = player is old enough to play.
	enemy_minimum_age = initial(enemy_minimum_age)
	return FALSE

/datum/game_mode/dynamic/make_antag_chance(mob/living/carbon/human/newPlayer)
	if(GLOB.round_type == ROUNDTYPE_EXTENDED) // BLUEMOON CHANGES
		return
	if(EMERGENCY_ESCAPED_OR_ENDGAMED) // No more rules after the shuttle has left
		return

	if (forced_latejoin_rule)
		forced_latejoin_rule.candidates = list(newPlayer)
		forced_latejoin_rule.trim_candidates()
		log_game("DYNAMIC: Forcing ruleset [forced_latejoin_rule]")
		if (forced_latejoin_rule.ready(TRUE))
			if (!forced_latejoin_rule.repeatable)
				latejoin_rules = remove_from_list(latejoin_rules, forced_latejoin_rule.type)
			addtimer(CALLBACK(src, TYPE_PROC_REF(/datum/game_mode/dynamic, execute_scheduled_ruleset), forced_latejoin_rule), forced_latejoin_rule.delay)
			SSdirector.note_forced_run(forced_latejoin_rule) // учёт форса в темпе директора, бюджет не трогаем
		forced_latejoin_rule = null
		return

	// Естественный латеджойн-драфт теперь ведёт SSdirector: он сам собирает latejoin-рулсеты,
	// ставит кандидата и решает по темпу/бюджету.
	SSdirector.on_latejoin(newPlayer)

/// Возврат бюджета при провале рулсета. mid_round_budget мёртв (всегда 0),
/// поэтому рефанд уходит в кошелёк ступени рулсета (ANTAG) - иначе провал execute сжигал бы бюджет насовсем.
/datum/game_mode/dynamic/proc/refund_threat(datum/dynamic_ruleset/rule, regain)
	SSdirector.refund_to_budget(rule.severity, regain)

/// Внешний приток угрозы (например, победа революции). mid_round_budget мёртв, поэтому приток
/// раскладываем по кошелькам директора как донат; threat_level поднимаем для отчёта ЦК.
/datum/game_mode/dynamic/proc/create_threat(gain)
	SSdirector.distribute_to_budgets(gain)
	threat_level = min(100, threat_level + gain)
	threat_log += "[worldtime2text()]: +[gain] угрозы направлено в бюджет директора."

/// Expend round start threat, can't fall under 0.
/datum/game_mode/dynamic/proc/spend_roundstart_budget(cost)
	round_start_budget = max(round_start_budget - cost,0)

/// Expend midround threat, can't fall under 0.
/datum/game_mode/dynamic/proc/spend_midround_budget(cost)
	mid_round_budget = max(mid_round_budget - cost,0)

/// Log to messages and to the game
/datum/game_mode/dynamic/proc/dynamic_log(text)
	message_admins("DYNAMIC: [text]")
	log_game("DYNAMIC: [text]")

#undef FAKE_REPORT_CHANCE
#undef REPORT_NEG_DIVERGENCE
#undef REPORT_POS_DIVERGENCE
