#define _DONATE_ITEM_TOOLTIP(original_item_path, highrisk) span_tooltip_fast("This is [span_italics(original_item_path::name)][highrisk ? ". Highrisk item!" : ""]")
#define DONATE_ITEM_TOOLTIP(original_item_path) _DONATE_ITEM_TOOLTIP(original_item_path, FALSE)
#define DONATE_ITEM_TOOLTIP_HIGHRISK(original_item_path) _DONATE_ITEM_TOOLTIP(original_item_path, TRUE)
