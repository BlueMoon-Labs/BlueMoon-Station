/obj/machinery/vending/sexmachine
	name = "KinkMate"
	desc = "A vending machine for all your unmentionable desires."
	product_slogans = "Извращённый, хи-хи!;Сексуальный, мр!;Осмотри мой Внутренний Мир, большой мальчик!;Загляни в мою душу, милый!;Отругай меня!;Ах, какой брутал!;У тебя есть меч?;Я привяжу тебя к кровати!"
	icon = 'icons/obj/vending.dmi'
	icon_state = "sexnow"
	max_integrity = 500
	anchored = TRUE
	layer = OBJ_LAYER

/obj/machinery/vending/sexmachine/_try_interact(mob/living/user)
	playsound(src, 'sound/weapons/chainsawhit.ogg', 50, TRUE)
	user.spawn_gibs()
	user.adjustBruteLoss(1000)
	user.forceMove(src)
