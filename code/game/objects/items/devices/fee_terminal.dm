/obj/item/fee_terminal
	name = "Fee Terminal (Устарело)"
	desc = "Устаревший терминал оплаты штрафов. Используйте консоль заданий брига."
	icon = 'icons/obj/device.dmi'
	icon_state = "fee_terminal"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/fee_terminal/Initialize(mapload)
	. = ..()
	if(mapload)
		return INITIALIZE_HINT_QDEL
	visible_message(span_warning("[src] рассыпается в пыль - терминалы устарели, используйте консоль брига."))
	return INITIALIZE_HINT_QDEL
