/mob/living/simple_animal/hostile/megafauna/sand
	name = "Corrupted Mayhem"
	desc = "The longer you look at this creature the more you feel your gut twist and you begin to feel sick..."
	//Богиня финальной комнаты гейта Killthemall - декорация, а не босс: бьёт
	//только того, кто ударил первым. Раньше неагрессивность держалась на
	//карточном хаке AIStatus = AI_Z_OFF (моб с карты в idle_mobs_by_zlevel не
	//попадал, разбудить его мог только adjustHealth). Контроллерный моб этот
	//легаси-статус не читает, поэтому гейт живёт на типе - через peaceful,
	//который уважает мегафаунная стратегия таргетирования.
	peaceful = TRUE
	icon = 'modular_splurt/icons/mob/lavaland/mayhem_mega.dmi'
	icon_state = "eva"
	icon_living = "eva"
	attack_sound = 'modular_splurt/sound/voice/ara-ara2.ogg'
