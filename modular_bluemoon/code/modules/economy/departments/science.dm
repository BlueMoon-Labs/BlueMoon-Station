/// Цвет экстракта слайма -> его ценность для науки
GLOBAL_LIST_INIT(econ_slime_extract_value, list(
	"grey" = 5,
	"orange" = 10,
	"metal" = 10,
	"blue" = 10,
	"purple" = 10,
	"dark purple" = 50,
	"dark blue" = 50,
	"green" = 50,
	"silver" = 50,
	"gold" = 50,
	"yellow" = 50,
	"red" = 50,
	"pink" = 50,
	"cerulean" = 75,
	"sepia" = 75,
	"bluespace" = 75,
	"pyrite" = 75,
	"light pink" = 75,
	"oil" = 75,
	"adamantine" = 75,
	"black" = 75,
	"rainbow" = 100,
))

/datum/economy_department/science
	id = ACCOUNT_SCI
	name = "Наука"
	budget_name = "бюджет науки"
	head_access = list(ACCESS_RD)
	/// Цвета экстрактов, уже оплаченных в этом раунде
	var/list/extracts_seen = list()
	/// world.time начала часового окна гранта на исследования
	var/grant_window_start = 0
	var/grant_points_in_window = 0

/datum/economy_department/science/proc/pays_extracts_at(atom/source)
	var/turf/source_turf = get_turf(source)
	return source_turf && is_station_level(source_turf.z)

/datum/economy_department/science/proc/note_extract(colour, atom/source, mob/performer)
	if(!colour || (colour in extracts_seen) || !pays_extracts_at(source))
		return
	extracts_seen += colour
	var/value = GLOB.econ_slime_extract_value[colour]
	if(value)
		SSeconomy.record_work(id, WORK_SCI_SLIME_DISCOVERY, value, performer, memo = "Новый экстракт: [colour]")

/proc/econ_node_points(datum/techweb_node/node, datum/techweb/web)
	. = 0
	var/list/price = node.get_price(web)
	for(var/point_type in price)
		. += price[point_type]

/datum/economy_department/science/proc/buy_research_grant(points, mob/living/user)
	if(!can_manage(user) || !isnum(points))
		return FALSE
	points = round(points)
	if(points < 1)
		return FALSE
	if(world.time - grant_window_start >= 1 HOURS)
		grant_window_start = world.time
		grant_points_in_window = 0
	if(grant_points_in_window + points > SSeconomy.settings.research_grant_cap_hour)
		return FALSE
	var/price = CEILING(points * SSeconomy.settings.research_grant_price_per_point, 1)
	if(!account.debit(price, ECON_PURCHASE, user, "Грант на исследования: [points] очков"))
		return FALSE
	grant_points_in_window += points
	SSresearch.science_tech.add_point_list(list(TECHWEB_POINT_TYPE_GENERIC = points), income = FALSE)
	log_econ("[key_name(user)] купил грант на исследования: [points] очков за [price] кр.")
	return TRUE
