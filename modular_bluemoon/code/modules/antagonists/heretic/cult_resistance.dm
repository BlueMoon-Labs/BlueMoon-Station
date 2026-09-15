#define HERETIC_CULT_STUN_STAMINA 35
#define HERETIC_CULT_STUN_DURATION (1 SECONDS)
#define HERETIC_CULT_STUN_KNOCKDOWN (2 SECONDS)

/mob/living/proc/apply_heretic_cult_stun()
	adjustStaminaLoss(HERETIC_CULT_STUN_STAMINA)
	Stun(HERETIC_CULT_STUN_DURATION)
	Knockdown(HERETIC_CULT_STUN_KNOCKDOWN)
	flash_act(1, TRUE)
	visible_message(span_warning("Красная вспышка сбивает [src] с ног, но за ней проступает знак Мансуса."), span_userdanger("Мансус сдерживает чужую волю. Вы сбиты с ног, но ещё можете сопротивляться!"))

#undef HERETIC_CULT_STUN_STAMINA
#undef HERETIC_CULT_STUN_DURATION
#undef HERETIC_CULT_STUN_KNOCKDOWN
