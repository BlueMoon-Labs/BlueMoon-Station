/// eye_blurry сходит на единицу за тик Life, поэтому длительность размытия переводится в тики.
#define BLUR_TICKS(duration) round((duration) / SSmobs.wait)
