/// Полиномиальный хеш с малыми константами (без больших литералов — dreamchecker / float32).
/proc/ic_tgui_hash_string(t)
	var/hash = 0
	if(!istext(t) || !length(t))
		return 0
	for(var/i = 1, i <= length(t), i++)
		hash = ((hash * 131) + text2ascii(t, i)) & 0x7FFFFFFF
	return hash

/// Stable per-instance accent for IntegratedCircuit TGUI (IE chips + wiremod components).
/proc/ic_tgui_chip_accent_hex(datum/D)
	if(!D)
		return "#4269a3"
	var/mix = "[D.type][REF(D)]"
	if(ismovable(D))
		var/atom/movable/M = D
		mix += "[M.name]"
	var/hi = ic_tgui_hash_string(mix)
	/// Золотой угол — равномернее, чем hi % 360 при похожих ref.
	var/angle = hi % 360
	var/golden = round((hi * 0.618033988749895) % 360, 1)
	var/angle2 = round((angle + golden) % 360, 1)
	var/h = AngleToHue(angle2)
	return HSVtoRGB(hsv(h, 188, 232))

GLOBAL_LIST_INIT(ie_ic_tgui_accent_by_type, list(
	/obj/item/integrated_circuit/input/button = "#2daa4e",
	/obj/item/integrated_circuit/input/toggle_button = "#38c96a",
	/obj/item/integrated_circuit/input/textpad = "#ff5cab",
	/obj/item/integrated_circuit/input/ntnet_packet = "#4da3ff",
	/obj/item/integrated_circuit/input/ntnet_advanced = "#6eb8ff",
	/obj/item/integrated_circuit/input = "#e0a62e",
	/obj/item/integrated_circuit/output = "#5c7cfa",
	/obj/item/integrated_circuit/output/screen = "#7b9cff",
	/obj/item/integrated_circuit/output/light = "#ffd54a",
	/obj/item/integrated_circuit/output/sound = "#9b7ed9",
	/obj/item/integrated_circuit/output/text_to_speech = "#ff6eb4",
	/obj/item/integrated_circuit/logic = "#c06bff",
	/obj/item/integrated_circuit/logic/binary = "#d080ff",
	/obj/item/integrated_circuit/logic/unary = "#a85fd9",
	/obj/item/integrated_circuit/memory = "#ff8f42",
	/obj/item/integrated_circuit/arithmetic = "#3ec9c1",
	/obj/item/integrated_circuit/converter = "#6ecf7a",
	/obj/item/integrated_circuit/time = "#5fd4a0",
	/obj/item/integrated_circuit/passive = "#8899aa",
	/obj/item/integrated_circuit/manipulation = "#ff7b6b",
	/obj/item/integrated_circuit/reagent = "#66d4ff",
	/obj/item/integrated_circuit/smart = "#b8e034",
))

/// IE: сначала цвет по иерархии типа, иначе хеш по экземпляру.
/proc/ic_tgui_ie_chip_accent_hex(obj/item/integrated_circuit/chip)
	if(!istype(chip))
		return ic_tgui_chip_accent_hex(chip)
	var/t = chip.type
	while(t)
		if(GLOB.ie_ic_tgui_accent_by_type[t])
			return GLOB.ie_ic_tgui_accent_by_type[t]
		t = type2parent(t)
	return ic_tgui_chip_accent_hex(chip)
