/obj/structure/destructible/clockwork/trap/power_nullifier
	name = "power nullifier"
	desc = "Хорошо спрятанный набор проводов и соединений."
	clockwork_desc = "При срабатывании он генерирует импульс ЭМИ 3х3, при этом центр испытывает более сильный импульс."
	icon_state = "electric_trap"
	break_message = "<span class='warning'>Нейтрализатор энергии искрит, а затем медленно рассыпается на куски!</span>"
	max_integrity = 40
	density = FALSE
	var/activated = FALSE

/obj/structure/destructible/clockwork/trap/power_nullifier/activate()
	if(!activated)
		activated = TRUE
		empulse_using_range(get_turf(src),1,TRUE)

/obj/structure/destructible/clockwork/trap/power_nullifier/emp_act(var/strength=1)
	activate()
