#define CHANGELOG_ARCHIVE_DIR "html/changelogs/archive/"

/datum/changelog
	var/static/list/changelog_items = list()
	/// Месяцы архива ("YYYY-MM"), свежие первыми. Это же белый список для get_month.
	var/list/dates
	/// ckey -> дата последней записи, которую игрок видел ДО текущего открытия окна.
	var/list/last_seen_by_ckey = list()

/datum/changelog/New(archive_dir = CHANGELOG_ARCHIVE_DIR)
	. = ..()
	dates = changelog_archive_months(archive_dir)

/datum/changelog/ui_state()
	return GLOB.always_state

/datum/changelog/ui_interact(mob/user, datum/tgui/ui)
	if(!user?.client)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if (!ui)
		ui = new(user, src, "Changelog")
		ui.open()

/datum/changelog/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(action == "get_month")
		var/datum/asset/changelog_item/changelog_item = get_month_asset(params["date"])
		if(changelog_item)
			return ui.send_asset(changelog_item)

/// Ассет месяца архива; null для всего, чего нет в списке месяцев.
/datum/changelog/proc/get_month_asset(date)
	if(!istext(date) || !(date in dates))
		return null
	var/datum/asset/changelog_item/changelog_item = changelog_items[date]
	if (!changelog_item)
		changelog_item = new /datum/asset/changelog_item(date)
		changelog_items[date] = changelog_item
	return changelog_item

/datum/changelog/ui_static_data(mob/user)
	return list(
		"dates" = dates,
		"last_seen" = last_seen_by_ckey[user?.ckey] || "",
	)

/// Открывает окно и отмечает ченджлог прочитанным. Метки «новое» в окне считаются
/// от того, что игрок видел до этого открытия.
/datum/changelog/proc/open_for(client/viewer)
	if(!viewer?.mob)
		return
	var/datum/preferences/prefs = viewer.prefs
	if(prefs)
		last_seen_by_ckey[viewer.ckey] = prefs.lastchangelog_date
		if(GLOB.changelog_latest_date && prefs.lastchangelog_date != GLOB.changelog_latest_date)
			prefs.lastchangelog_date = GLOB.changelog_latest_date
			prefs.save_pref_var("lastchangelog_date")
		if(prefs.lastchangelog != GLOB.changelog_hash)
			prefs.lastchangelog = GLOB.changelog_hash
			prefs.save_pref_var("lastchangelog")
			winset(viewer, "infowindow.changelog", "font-style=;")
	ui_interact(viewer.mob)

/// Месяцы архива ченджлога ("YYYY-MM"), свежие первыми.
/proc/changelog_archive_months(archive_dir = CHANGELOG_ARCHIVE_DIR)
	var/list/months = list()
	var/regex/month_file = regex(@"^(\d{4}-\d{2})\.yml$")
	for(var/archive_file in sort_list(flist(archive_dir)))
		if(month_file.Find(archive_file))
			months.Insert(1, month_file.group[1])
	return months

/// Самая свежая дата записи ("YYYY-MM-DD") в последнем месяце архива, или "" если архив пуст.
/proc/changelog_latest_entry_date(archive_dir = CHANGELOG_ARCHIVE_DIR)
	var/list/months = changelog_archive_months(archive_dir)
	if(!length(months))
		return ""
	var/text = file2text("[archive_dir][months[1]].yml")
	var/regex/day_key = regex(@"^(\d{4}-\d{2}-\d{2}):", "gm")
	var/latest = ""
	while(day_key.Find(text))
		var/day = day_key.group[1]
		if(sorttext(day, latest) < 0)
			latest = day
	return latest

/// Дата в формате "YYYY-MM-DD" или "" для всего остального.
/proc/sanitize_changelog_date(value)
	var/static/regex/date_format = regex(@"^\d{4}-\d{2}-\d{2}$")
	if(istext(value) && date_format.Find(value))
		return value
	return ""

#undef CHANGELOG_ARCHIVE_DIR
