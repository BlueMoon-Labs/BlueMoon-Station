#define _DONATE_ITEM_TOOLTIP(name, highrisk) span_tooltip_fast("This is [span_italics(name)][highrisk ? ". Highrisk item!" : ""]")

//#define _DONATE_ITEM_TOOLTIP_PATH(original_item_path, highrisk) _DONATE_ITEM_TOOLTIP(original_item_path::name, highrisk)
//#define DONATE_ITEM_TOOLTIP(original_item_path) _DONATE_ITEM_TOOLTIP_PATH(original_item_path, FALSE)
//#define DONATE_ITEM_TOOLTIP_HIGHRISK(original_item_path) _DONATE_ITEM_TOOLTIP_PATH(original_item_path, TRUE)

#define _DONATE_ITEM_TOOLTIP_PARENT(highrisk) \
	get_examine_name(mob/user) { \
		. = ..(); \
		var/obj/tooltip_path = parent_type; \
		. += _DONATE_ITEM_TOOLTIP(initial(tooltip_path.name), highrisk); \
	} ;

#define DONATE_ITEM_TOOLTIP_PARENT _DONATE_ITEM_TOOLTIP_PARENT(FALSE)
#define DONATE_ITEM_TOOLTIP_PARENT_HIGHRISK _DONATE_ITEM_TOOLTIP_PARENT(TRUE)
