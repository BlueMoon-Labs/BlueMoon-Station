/// The builder consumes data from owned media. Only ordinary private agent
/// profiles are templates: police authority and station identities are not craftable.
/proc/netrun_agent_template(datum/netrun_file/file)
	RETURN_TYPE(/datum/netrun_bot_program)
	if(QDELETED(file) || file.kind != NETRUN_FILE_BOT)
		return null
	var/datum/netrun_bot_program/program = SSnetrun.get_bot_program(file.content)
	return program?.file_size && program.faction == NETRUN_FACTION_OWNER && !program.sanctioned ? program : null

/// A blank private process is an authored package, not a forged station profile.
/datum/netrun_bot_program/custom
	id = "custom"
	name = "Собственный агент"
	desc = "Пустой частный процесс: поведение задаётся паттерном, программы и модули выбираются из собственной памяти."
	faction = NETRUN_FACTION_OWNER
	storage = 8 * NETRUN_STORAGE_SCALE
	file_size = 4
	name_prefix = "AGENT"
	avatar = "cipher"
	accent = "cyan"

/datum/netrun_bot_program/custom/plan(datum/netrun_bot_brain/brain)
	if(brain.order == "patrol")
		return ..()
	brain.push_goal(new /datum/netrun_bot_goal/guard(brain, brain.post_node()))

/// Building from a recalled/authored package retains its owned policy snapshot.
/proc/netrun_agent_builder_behavior(datum/netrun_file/template, datum/netrun_bot_program/program)
	var/list/behavior = list("strategy" = "profile", "aggression" = 100, "caution" = round(program.flee_ratio * 100), "cooperation" = TRUE)
	var/datum/netrun_file/bot/package = template
	if(istype(package) && !isnull(package.stored_behavior))
		var/list/stored = netrun_agent_behavior_settings(package.stored_behavior, TRUE)
		if(!stored)
			return null
		for(var/key in stored)
			behavior[key] = stored[key]
	return behavior

/datum/netrun_console/proc/agent_builder_payload(datum/netrun_file/template)
	var/datum/netrun_bot_program/program = template ? netrun_agent_template(template) : SSnetrun.get_bot_program("custom")
	if(!program || (template && !inventory.store_for(template)))
		return null
	var/list/behavior = netrun_agent_builder_behavior(template, program)
	if(!behavior)
		return null
	var/list/defaults = list()
	for(var/id in program.programs)
		var/datum/netrun_program/executable = SSnetrun.get_program(id)
		if(executable)
			defaults += list(list("id" = id, "name" = executable.name, "size" = executable.size))
	for(var/id in program.daemons)
		var/datum/netrun_program/daemon/executable = SSnetrun.get_daemon(id)
		if(executable)
			defaults += list(list("id" = id, "name" = executable.name, "size" = executable.size))
	var/list/program_files = list()
	var/list/module_files = list()
	for(var/datum/netrun_file/file as anything in inventory.all_files())
		if(file.kind == NETRUN_FILE_PROGRAM && SSnetrun.get_program(file.content))
			program_files += list(list("uid" = file.uid, "name" = file.name, "program_id" = file.content, "size" = file.size))
		var/datum/netrun_agent_extension/extension = netrun_agent_extension_for(file)
		if(extension)
			var/datum/netrun_program/daemon/definition = SSnetrun.get_daemon(file.content)
			module_files += list(list("uid" = file.uid, "id" = extension.id, "name" = extension.name, "desc" = extension.desc, "size" = file.size, "effects" = definition.effect_values(), "requirements" = list(), "allowed" = TRUE, "reason" = null))
	return list(
		"template_uid" = template?.uid,
		"profile" = program.id,
		"name" = program.name,
		"description" = program.desc,
		"capacity" = program.storage,
		"base_size" = program.file_size,
		"defaults" = defaults,
		"programs" = program_files,
		"modules" = module_files,
		"orders" = list(list("id" = "guard", "name" = "Работа на месте запуска"), list("id" = "patrol", "name" = "Патруль доступной сети")),
		"avatars" = netrun_avatar_options(),
		"accents" = netrun_accent_options(),
		"themes" = netrun_theme_ids(),
		"max_programs" = 8,
		"max_modules" = 4,
		"behavior" = behavior,
	)

/// Create an independent executable package. All validation precedes writes;
/// source programs, templates and their recalled cargo remain on their disks.
/datum/netrun_console/proc/create_agent_file(list/options, mob/user)
	RETURN_TYPE(/datum/netrun_file/bot)
	if(!islist(options) || !cosmetic_user(user))
		return null
	var/from_scratch = isnull(options["uid"])
	var/datum/netrun_file/template = from_scratch ? null : find_local_file(options["uid"])
	var/datum/netrun_bot_program/program = from_scratch ? SSnetrun.get_bot_program("custom") : netrun_agent_template(template)
	if(!program || (!from_scratch && !inventory.store_for(template)))
		log_line("Нужен собственный файл-шаблон частного агента.", "bad")
		return null
	var/agent_name = ("name" in options) ? options["name"] : program.name_prefix
	if(!istext(agent_name) || length_char(agent_name) > 42)
		return null
	agent_name = reject_bad_name(agent_name, allow_numbers = TRUE)
	if(!agent_name)
		log_line("Недопустимое имя агента.", "bad")
		return null
	var/avatar = ("avatar" in options) ? options["avatar"] : program.avatar
	var/accent = ("accent" in options) ? options["accent"] : program.accent
	var/theme = ("theme" in options) ? options["theme"] : "ion"
	var/tagline = ("tagline" in options) ? options["tagline"] : program.tagline
	var/order = ("order" in options) ? options["order"] : "guard"
	if(!netrun_option_valid(avatar, netrun_avatar_options()) || !netrun_option_valid(accent, netrun_accent_options()) || !(theme in netrun_theme_ids()) || !istext(tagline) || length_char(tagline) > 80 || !(order in list("guard", "patrol")))
		log_line("Настройки внешности или начальной задачи агента недопустимы.", "bad")
		return null
	var/list/behavior = netrun_agent_builder_behavior(template, program)
	if(!behavior)
		return null
	if("behavior" in options)
		var/list/changes = netrun_agent_behavior_settings(options["behavior"], TRUE)
		if(!changes)
			log_line("Паттерн поведения агента недопустим.", "bad")
			return null
		for(var/key in changes)
			behavior[key] = changes[key]
	var/list/uids = options["program_uids"]
	if(isnull(uids))
		uids = list()
	if(!islist(uids) || length(uids) > 8)
		return null
	var/list/selected = list()
	var/list/seen = list()
	var/required = 0
	var/include_defaults = !("include_defaults" in options) || !!options["include_defaults"]
	if(include_defaults)
		for(var/id in program.programs)
			var/datum/netrun_program/executable = SSnetrun.get_program(id)
			if(!executable)
				return null
			required += executable.size
		for(var/id in program.daemons)
			var/datum/netrun_program/daemon/executable = SSnetrun.get_daemon(id)
			if(!executable)
				return null
			required += executable.size
	for(var/uid in uids)
		var/datum/netrun_file/file = find_local_file(uid)
		if(!istext(uid) || seen[uid] || QDELETED(file) || file.kind != NETRUN_FILE_PROGRAM || !inventory.store_for(file) || !SSnetrun.get_program(file.content) || !IS_FINITE(file.size) || file.size < 0)
			log_line("Выбранная программа больше не принадлежит этой консоли.", "bad")
			return null
		seen[uid] = TRUE
		selected += file
		required += file.size
	var/list/module_uids = options["module_uids"]
	if(isnull(module_uids))
		module_uids = list()
	if(!islist(module_uids) || length(module_uids) > 4)
		return null
	var/list/module_ids = list()
	for(var/uid in module_uids)
		var/datum/netrun_file/file = find_local_file(uid)
		var/datum/netrun_agent_extension/extension = netrun_agent_extension_for(file)
		if(!istext(uid) || seen[uid] || !extension || module_ids[extension.id] || !inventory.store_for(file) || !IS_FINITE(file.size) || file.size < 0)
			log_line("Модуль агента недоступен, повторяется или не входит в поддерживаемый набор.", "bad")
			return null
		seen[uid] = TRUE
		module_ids[extension.id] = TRUE
		selected += file
		required += file.size
	var/datum/netrun_file_store/destination = options["to_shard"] ? inventory.shard?.file_store : inventory.local_store
	if(QDELETED(destination) || required > program.storage || destination.used() + program.file_size + required > destination.capacity)
		log_line("Недостаточно памяти для агента и выбранного набора программ.", "bad")
		return null
	var/datum/netrun_file/bot/result = netrun_bot_file(program.id)
	result.name = netrun_file_name("[agent_name].bot")
	result.stored_name = agent_name
	result.stored_persona = list("avatar" = avatar, "accent" = accent, "tagline" = trim(strip_html_tags(tagline, TRUE)), "alias" = agent_name, "theme" = theme)
	result.stored_order = order
	result.stored_behavior = behavior
	result.stored_files = list()
	if(include_defaults)
		for(var/id in program.programs)
			result.stored_files += netrun_program_file(id)
		for(var/id in program.daemons)
			result.stored_files += netrun_daemon_file(id)
	for(var/datum/netrun_file/file as anything in selected)
		result.stored_files += file.copy()
	result.size = program.file_size + netrun_storage_used(result.stored_files)
	if(!destination.insert(result))
		qdel(result)
		return null
	inventory.selected_file_uid = result.uid
	log_line("Создан [result.name]: [program.name], [length(result.stored_files)] программ, задача [order == "patrol" ? "патруль" : "работа на месте запуска"].", "good")
	return result

/// Agent packages remain inspectable on media before they are launched.
/datum/netrun_file/bot/ui_entry(selected_uid)
	. = ..()
	var/datum/netrun_bot_program/program = SSnetrun.get_bot_program(content)
	.["preview"] = program ? "[program.name]: [program.desc]" : "Неизвестная программа агента"
	.["agent_profile"] = program?.id
	.["packed_files"] = length(stored_files)

/// The survey is an ordinary command goal: movement, delivery and node ACLs are
/// revalidated by the same pipeline as manually running scan from a terminal.
/datum/netrun_bot_goal/survey
	parent_type = /datum/netrun_bot_goal/command
	name = "разведка узла"

/datum/netrun_bot_goal/survey/New(datum/netrun_bot_brain/brain, datum/component/netrun_node/node)
	..(brain, node, "scan")

/datum/netrun_bot_goal/survey/advance()
	. = ..()
	if(. != NETRUN_BOT_GOAL_DONE)
		return
	var/datum/netrun_file_store/store = brain.owner.console.inventory.local_store
	var/datum/component/netrun_node/node = node_ref?.resolve()
	var/text = "[node_name] [node?.address]\n[copytext_char("[brain.command_result]", 1, 1001)]"
	var/datum/netrun_file/report = new("survey-[node?.address || "unknown"].txt", NETRUN_FILE_TEXT, text)
	// Four independent reports at most. A full cargo disk preserves its contents.
	if(!store.can_fit(report))
		qdel(report)
		return
	var/list/reports = list()
	for(var/datum/netrun_file/file as anything in store.files)
		if(file.kind == NETRUN_FILE_TEXT && findtext(file.name, "survey-") == 1)
			reports += file
	while(length(reports) >= 4)
		var/datum/netrun_file/oldest = reports[1]
		reports.Cut(1, 2)
		store.delete_file(oldest)
	if(!store.insert(report))
		qdel(report)
