/obj/item/book/granter/spell/summon_tentacle
	spell = /obj/effect/proc_holder/spell/targeted/conjure_item/summon_pie/summon_tentacle
	spellname = "Summon Tentacle"
	icon_state ="booksummons"
	desc = "Эта книга ощущается тёплой..."
	remarks = list("Тентакли...", "Большие тентакли...", "Тебе нравятся тентакли... не так ли?", "Кажется, книга запачкана в чём-то белом...", "Что за дела? Почему страницы слиплись...", "О... МОЙ... БОГ... ЧТО?", "В чём разница между кремом, молоком и тентаклями...")

/obj/item/book/granter/spell/summon_tentacle/on_reading_finished()
	. = ..()
	qdel(src)

/obj/effect/proc_holder/spell/targeted/conjure_item/summon_pie/summon_tentacle
	name = "Summon Tentacle"
	desc = "Summon Tentacle."
	item_type = /obj/item/gun/magic/tentacle
	action_icon = 'icons/obj/items_and_weapons.dmi'
	action_icon_state = "tentacle"
