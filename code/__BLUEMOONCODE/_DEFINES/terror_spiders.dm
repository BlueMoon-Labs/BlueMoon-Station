// Размытие зрения от пауков ужаса. eye_blurry сходит на единицу за тик Life, поэтому время переводится в тики.
#define TERROR_BLUR_TICKS(duration) round((duration) / SSmobs.wait)

/// Яд вдовы держит зрение размытым, пока он в крови, и размытие сходит за это время после выведения.
#define TERROR_VENOM_BLUR_LIGHT (20 SECONDS)
#define TERROR_VENOM_BLUR_HEAVY (40 SECONDS)
/// Укус лекаря добавляет размытие, но не выше потолка.
#define TERROR_HEALER_BITE_BLUR (20 SECONDS)
#define TERROR_HEALER_BLUR_CAP (2 MINUTES)
/// Слизистая паутина лекаря.
#define TERROR_WEB_BLUR (30 SECONDS)
#define TERROR_WEB_BLUR_CAP (1 MINUTES)
