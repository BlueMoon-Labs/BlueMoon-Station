/obj/item/disk/nifsoft_uploader/summoner/book
	name = "Grimoire Akasha"
	loaded_nifsoft = /datum/nifsoft/summoner/book

/datum/nifsoft/summoner/book
	name = "Grimoire Akasha"
	program_desc = "Grimoire Akasha — ответвление NIFSoft Grimoire Caeruleam, созданное для доступа пользователя к разнообразным образовательным книгам из жёсткого света. \
	Благодаря образовательному характеру и крошечному размеру, Grimoire Akasha обычно распространяется бесплатно на большинстве NIFSoft-площадок."
	summonable_items = list()
	purchase_price = 0 // This is a tool intended to help out newer players.
	max_summoned_items = 2
	buying_category = NIFSOFT_CATEGORY_INFORMATION
	ui_icon = "book"

/datum/nifsoft/summoner/book/New()
	. = ..()
	summonable_items += subtypesof(/obj/item/book/manual/wiki) //That's right! all of the manual books!

/datum/nifsoft/summoner/book/apply_custom_properties(obj/item/book/generated_book)
	if(!istype(generated_book))
		return FALSE

	generated_book.cannot_carve = TRUE
	return TRUE

// Need this code here so that we don't have people carving out the summoned books
/obj/item/book
	/// Is the parent book unable to be carved? TRUE prevents carving. By default this is unset
	var/cannot_carve

// Wiki books are the ones accessible through the summoner, so block carving on them
/obj/item/book/manual/wiki/attackby(obj/item/I, mob/user, params)
	if(cannot_carve && (istype(I, /obj/item/kitchen/knife) || I.tool_behaviour == TOOL_WIRECUTTER))
		balloon_alert(user, "unable to be carved!")
		return TRUE

	return ..()
