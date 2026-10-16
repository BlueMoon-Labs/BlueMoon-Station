/obj/structure/dresser
	var/static/list/possible_underwear = list()
	var/static/list/possible_shirt = list()
	var/static/list/possible_socks = list()

	var/static/list/possible_underwear_blacklist = list()
	var/static/list/possible_shirt_blacklist = list(/obj/item/clothing/underwear/shirt/adjustable, /obj/item/clothing/underwear/shirt/adjustable/toggle)
	var/static/list/possible_socks_blacklist = list()

#define UNDIE_AMOUNT 5
#define DRESSER_MAX_STORAGE ((UNDIE_AMOUNT*3)+UNDIE_AMOUNT) // UNDIE_AMOUNT of each type, plus UNDIE_AMOUNT for whatever else
/obj/structure/dresser/Initialize(mapload)
	. = ..()
	if(mapload)
		generate_underwear()

/obj/structure/dresser/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = AddComponent(/datum/component/storage/concrete/dresser)
	STR.max_items = DRESSER_MAX_STORAGE

/obj/structure/dresser/proc/generate_underwear()
	if(!possible_underwear.len)
		possible_underwear = (typesof(/obj/item/clothing/underwear/briefs) - possible_underwear_blacklist)
	if(!possible_shirt.len)
		possible_shirt = (typesof(/obj/item/clothing/underwear/shirt) - possible_shirt_blacklist)
	if(!possible_socks.len)
		possible_socks = (typesof(/obj/item/clothing/underwear/socks) - possible_socks_blacklist)

	for(var/i in 1 to UNDIE_AMOUNT)
		var/underwear = pick(possible_underwear)
		new underwear(src)

	for(var/i in 1 to UNDIE_AMOUNT)
		var/shirt = pick(possible_shirt)
		new shirt(src)

	for(var/i in 1 to UNDIE_AMOUNT)
		var/socks = pick(possible_socks)
		new socks(src)

#undef UNDIE_AMOUNT
#undef DRESSER_MAX_STORAGE
