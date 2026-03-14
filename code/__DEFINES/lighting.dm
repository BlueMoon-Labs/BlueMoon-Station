//Bay lighting engine shit, not in /code/modules/lighting because BYOND is being shit about it
#define LIGHTING_INTERVAL       5 // frequency, in 1/10ths of a second, of the lighting process

#define MINIMUM_USEFUL_LIGHT_RANGE 1.4
#define LIGHTING_MAX_RANGE 8 // Performance cap: range 9+ costs 4.2x more per source (quadratic view). Objects with higher range will be clamped here.

#define LIGHTING_HEIGHT_SPACE  -0.5 // light UNDER the floor, primarily used for starlight
#define LIGHTING_HEIGHT_FLOOR   0   // light ON the floor
#define LIGHTING_HEIGHT         1   // height off the ground of light sources on the pseudo-z-axis, you should probably leave this alone
#define LIGHTING_SHEET_RANGE_STEP 0.1 // range quantization step for falloff cache keys
#define LIGHTING_SHEET_HEIGHT_STEP 0.1 // height quantization step for falloff cache keys
#define LIGHTING_SHEETS_MAX_ENTRIES 256 // soft cap for cached falloff lookup tables
// Falloff mode: how light intensity decreases with distance
#define LIGHTING_FALLOFF_LINEAR 0         // Classic: 1 - dist/range (SS13 standard)
#define LIGHTING_FALLOFF_INVERSE_SQUARE 1 // Realistic: 1 / (1 + k * dist²) — brighter center, softer edges
#define LIGHTING_FALLOFF_MODE LIGHTING_FALLOFF_INVERSE_SQUARE // Compile-time default (runtime override via GLOB.lighting_falloff_mode)
#define LIGHTING_INVERSE_SQUARE_K 2.5     // Steepness for inverse-square (higher = faster falloff)
GLOBAL_VAR_INIT(lighting_falloff_mode, LIGHTING_FALLOFF_MODE) // Runtime falloff mode — togglable by admins
#define LIGHTING_SOFT_EDGE 0.8            // Normalized distance where soft falloff begins (linear mode) — smooths visible "ring" at light boundary
#define LIGHTING_FALLOFF_CULL_THRESHOLD 0.005 // Skip storing corners with falloff below this (invisible, saves memory on large-range lights)
#define LIGHTING_ROUND_VALUE    (1 / 32) //Value used to round lumcounts, values smaller than 1/129 don't matter (if they do, thanks sinking points), greater values will make lighting less precise, but in turn increase performance, VERY SLIGHTLY.

#define LIGHTING_ANIMATE_TIME 3       // Default animate() duration in deciseconds (0.3s) for smooth lighting transitions
#define LIGHTING_ANIMATE_TIME_FAST 1  // Instant events (EMP, explosion, power cut) — 0.1s
#define LIGHTING_ANIMATE_TIME_SMOOTH 5 // Gradual events (sunrise, slow power-up) — 0.5s

#define LIGHTING_BLUR_MIN 0
#define LIGHTING_BLUR_MAX 4
#define LIGHTING_BLUR_DEFAULT 3
#define LIGHTING_BLUR_BASE 0 // Minimum blur (px) always applied to smooth tile boundaries — GPU-cheap on composited plane master
#define LIGHTING_BLUR_MULTIPLIER 2 // Edge softening: level * this = blur px (2/4/6/8)

#define LIGHTING_CONE_PENUMBRA 30 // Penumbra width (degrees) on each side of the cone edge — softens cone light edges
#define LIGHTING_CONE_INNER_RADIUS 1.5 // Within this distance (tiles), light is omnidirectional — prevents dark source tile
#define LIGHTING_FLASHLIGHT_CONE_ANGLE 90 // Standard flashlight: 90° full cone width
#define LIGHTING_SECLITE_CONE_ANGLE 100 // Seclite: slightly wider
#define LIGHTING_PENLIGHT_CONE_ANGLE 60 // Penlight: narrow beam
#define LIGHTING_WALL_TUBE_CONE_ANGLE 200 // Wall tube: wide spread, tube shape scatters light broadly to the sides
#define LIGHTING_WALL_BULB_CONE_ANGLE 170 // Wall bulb: slightly narrower than tube, still wide

// Adaptive source processing cap
#define LIGHTING_SOURCES_BASE_CAP 100      // Default max sources per fire
#define LIGHTING_SOURCES_UNCAPPED_THRESHOLD 50 // Process all if queue is this small
#define LIGHTING_SOURCES_MIN_CAP 20        // Minimum cap during extreme server lag
#define LIGHTING_SOURCES_MEDIUM_REDUCTION 25 // Cap reduction under medium time dilation
#define LIGHTING_SOURCES_HARD_CEILING 200  // Absolute max sources per fire, even during backlog drain
#define LIGHTING_BACKLOG_THRESHOLD_MULT 2  // Queue must be cap*this to trigger drain boost
#define LIGHTING_BACKLOG_DRAIN_DIVISOR 3   // Drain rate: (queue - cap) / this
#define LIGHTING_IDLE_WAIT_THRESHOLD 20    // Below this pending count, subsystem relaxes to wait=2
#define LIGHTING_BG_INIT_PENDING_THRESHOLD 100 // Background z-level init only runs when normal queue < this
#define LIGHTING_DILATION_HIGH 40          // Time dilation threshold for minimum cap
#define LIGHTING_DILATION_MEDIUM 20        // Time dilation threshold for reduced cap

// Cascade caps for corners (Phase 2) and objects (Phase 3)
// These prevent cascading queue amplification: 1 source → N corners → 4N objects
#define LIGHTING_CORNERS_MIN_CAP 100       // Minimum corners per fire
#define LIGHTING_CORNERS_CAP_MULT 8        // Max corners = sources_processed * this
#define LIGHTING_CORNERS_HARD_CEILING 800   // Absolute max corners per fire
#define LIGHTING_OBJECTS_MIN_CAP 200       // Minimum objects per fire
#define LIGHTING_OBJECTS_CAP_MULT 6        // Max objects = corners_processed * this
#define LIGHTING_OBJECTS_HARD_CEILING 2000  // Absolute max objects per fire

// Area lighting profile presets — pick from these instead of raw floats
// Temperature: positive = warm (↑R ↓B), negative = cool (↓R ↑B)
#define LIGHT_TEMP_WARM         0.06  // Cozy, inviting (bar, lounge)
#define LIGHT_TEMP_DRAMATIC     0.05  // Warm with intent (chapel, candlelit)
#define LIGHT_TEMP_INDUSTRIAL   0.08  // Hot machinery glow (engineering)
#define LIGHT_TEMP_FURNACE      0.1   // Extreme heat (atmospherics, smelter)
#define LIGHT_TEMP_SUBTLE_WARM  0.02  // Barely warm — lived-in feel (dorms, cargo)
#define LIGHT_TEMP_SUBTLE_COOL -0.02  // Barely cool — neutral-professional
#define LIGHT_TEMP_COOL        -0.03  // Slightly cold (science, bridge, prison)
#define LIGHT_TEMP_CLINICAL    -0.04  // Sterile blue-white (medical, surgery)
// Contrast: >1 = deeper shadows, 1 = normal
#define LIGHT_CONTRAST_NORMAL   1     // Standard shadow depth
#define LIGHT_CONTRAST_ENHANCED 1.1   // Noticeable shadow (chapel, prison)
#define LIGHT_CONTRAST_DEEP     1.15  // Heavy shadow (maintenance, tunnels)

// Contact shadows
#define CONTACT_SHADOW_STRENGTH 0.07       // Base dimming per adjacent opaque turf — actual effect uses diminishing returns
#define CONTACT_SHADOW_MAX_NEIGHBORS 3     // Cap opaque neighbors considered — 4th neighbor (fully enclosed) is ignored
// Area-level contact shadow multiplier presets
#define CONTACT_SHADOW_FLAT     0.3  // Nearly flat shadows (operating rooms, clean environments)
#define CONTACT_SHADOW_REDUCED  0.5  // Softer than default (medical, AI satellite)
#define CONTACT_SHADOW_ENHANCED 1.2  // Slightly heavier (armory, secure areas)
#define CONTACT_SHADOW_HEAVY    1.5  // Deep wall shadows (maintenance, morgue)

// Complementary shadow tinting: shadows shift to the opposite hue of the area temperature
// In warm areas (positive temp), shadows gain a subtle blue tint; in cool areas, a subtle red tint
#define SHADOW_TINT_FACTOR      0.35  // Strength of complementary tint (0-1). Keep subtle.
#define SHADOW_TINT_THRESHOLD   0.3   // Only apply tint when corner brightness is below this

// Ambient light floor: minimum brightness instead of pure black in dark areas
#define AMBIENT_LIGHT_DEFAULT   0.02  // Default: textures barely visible in darkness
#define AMBIENT_LIGHT_NONE      0     // True black (space, void)
#define AMBIENT_LIGHT_DIM       0.01  // Barely perceptible (deep maintenance)
#define AMBIENT_LIGHT_SUBTLE    0.03  // Slightly more visible (indoor areas with residual light)

// Damage-based light flickering
#define LIGHT_DAMAGE_FLICKER_THRESHOLD      0.75  // Integrity ratio below which flickering starts
#define LIGHT_DAMAGE_FLICKER_SEVERE         0.4   // Integrity ratio for severe flickering
#define LIGHT_FLICKER_INTERVAL_NORMAL       30    // Deciseconds between flicker ticks at mild damage (3s)
#define LIGHT_FLICKER_INTERVAL_SEVERE       15    // Deciseconds between flicker ticks at severe damage (1.5s)
#define LIGHT_FLICKER_POWER_VARIANCE        0.15  // +/- 15% power variation (mild damage)
#define LIGHT_FLICKER_POWER_VARIANCE_SEVERE 0.25  // +/- 25% power variation (severe damage)
#define LIGHT_FLICKER_DROPOUT_PROB_NORMAL   5     // % chance per tick of brief dropout (mild)
#define LIGHT_FLICKER_DROPOUT_PROB_SEVERE   15    // % chance per tick of brief dropout (severe)
#define LIGHT_FLICKER_DROPOUT_POWER         0.2   // Power multiplier during dropout (20%)
#define LIGHT_FLICKER_DROPOUT_DURATION      2     // Deciseconds of dropout (0.2s)
#define LIGHT_FLICKER_POWER_CLAMP_MIN       0.3   // Min power multiplier in normal flicker clamp
#define LIGHT_FLICKER_POWER_CLAMP_MAX       1.1   // Max power multiplier in normal flicker clamp

// Timer interval jitter: multiply base interval by (MIN + rand() * RANGE) for ±20% randomness
#define LIGHT_INTERVAL_JITTER_MIN           0.8
#define LIGHT_INTERVAL_JITTER_RANGE         0.4

// Power loss animation
#define LIGHT_DEATH_FLICKER_STEPS           4     // Number of rapid on/off toggles before going dark
#define LIGHT_DEATH_FLICKER_BRIGHTNESS_MUL  0.4   // Brightness multiplier during dim phase
#define LIGHT_DEATH_FLICKER_POWER_MUL       0.3   // Power multiplier during dim phase
#define LIGHT_DEATH_FLICKER_DURATION        5     // Deciseconds total for death flicker sequence (0.5s)
#define LIGHT_EMERGENCY_DELAY_MIN           10    // Min deciseconds of darkness before emergency (1.0s)
#define LIGHT_EMERGENCY_DELAY_MAX           20    // Max deciseconds of darkness before emergency (2.0s)
#define LIGHT_EMERGENCY_FLICKER_INTERVAL    25    // Deciseconds between emergency light flickers (2.5s)
#define LIGHT_EMERGENCY_POWER_JITTER_MIN   0.9   // Emergency power variance: min multiplier (±10%)
#define LIGHT_EMERGENCY_POWER_JITTER_RANGE 0.2   // Emergency power variance: random range
#define LIGHT_EMERGENCY_DRAIN_RATE          5     // Power drained from cell per process() tick during emergency (~30s total)


#define LIGHTING_ICON 'icons/effects/lighting_object.dmi' // icon used for lighting shading effects

// If the max of the lighting lumcounts of each spectrum drops below this, disable luminosity on the lighting objects.
// Set to zero to disable soft lighting. Luminosity changes then work if it's lit at all.
#define LIGHTING_SOFT_THRESHOLD 0.04

// If I were you I'd leave this alone.
#define LIGHTING_BASE_MATRIX \
	list                     \
	(                        \
		1, 1, 1, 0, \
		1, 1, 1, 0, \
		1, 1, 1, 0, \
		1, 1, 1, 0, \
		0, 0, 0, 1           \
	)                        \

#define LIGHTING_DARK_MATRIX \
	list                     \
	(                        \
		0, 0, 0, 0, \
		0, 0, 0, 0, \
		0, 0, 0, 0, \
		0, 0, 0, 0, \
		0, 0, 0, 1           \
	)                        \

/// Small cache of ambient-dark color matrices keyed by quantized ambient value
GLOBAL_LIST_INIT(lighting_ambient_matrices, list())

//Some defines to generalise colours used in lighting.
//Important note on colors. Colors can end up significantly different from the basic html picture, especially when saturated
#define LIGHT_COLOR_WHITE		"#FFFFFF"
#define LIGHT_COLOR_RED        "#FA8282" //Warm but extremely diluted red. rgb(250, 130, 130)

#define COLOR_STARLIGHT "#8589fa" //Periwinkle/lavender blue, used for space starlight

// Solar cycle starlight anchor colors (dawn->day->dusk->night)
#define STARLIGHT_COLOR_DAWN    "#FFB366"  // Warm amber-orange
#define STARLIGHT_COLOR_DAY     "#FFF5E6"  // Bright neutral-warm white
#define STARLIGHT_COLOR_DUSK    "#FF9944"  // Deep amber-orange
#define STARLIGHT_COLOR_EVENING "#9999CC"  // Cool lavender transition
// Night uses COLOR_STARLIGHT (#8589fa)

// Solar cycle starlight power levels
#define STARLIGHT_POWER_DAY     0.72
#define STARLIGHT_POWER_DAY_LOW 0.68
#define STARLIGHT_POWER_DAWN    0.58
#define STARLIGHT_POWER_DUSK    0.53
#define STARLIGHT_POWER_EVENING 0.50
#define STARLIGHT_POWER_NIGHT   0.48

GLOBAL_VAR_INIT(current_starlight_color, COLOR_STARLIGHT) // Current solar-cycle starlight color (updated by SSnight_shift)
GLOBAL_VAR_INIT(current_starlight_power, STARLIGHT_POWER_NIGHT) // Current solar-cycle starlight power (updated by SSnight_shift)

#define LIGHT_RANGE_FIRE		3 //How many tiles standard fires glow.

#define LIGHTING_PLANE_ALPHA_VISIBLE 255
#define LIGHTING_PLANE_ALPHA_NV_TRAIT 223
#define LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE 192
#define LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE 128 //For lighting alpha, small amounts lead to big changes. even at 128 its hard to figure out what is dark and what is light, at 64 you almost can't even tell.
#define LIGHTING_PLANE_ALPHA_INVISIBLE 0

#define NIGHT_VISION_DARKSIGHT_RANGE 3

//lighting area defines
#define DYNAMIC_LIGHTING_DISABLED 0 //dynamic lighting disabled (area stays at full brightness)
#define DYNAMIC_LIGHTING_ENABLED 1 //dynamic lighting enabled
#define DYNAMIC_LIGHTING_FORCED 2 //dynamic lighting enabled even if the area doesn't require power
#define DYNAMIC_LIGHTING_IFSTARLIGHT 3 //dynamic lighting enabled only if starlight is.
#define IS_DYNAMIC_LIGHTING(A) A.dynamic_lighting


//code assumes higher numbers override lower numbers.
#define LIGHTING_NO_UPDATE 0
#define LIGHTING_VIS_UPDATE 1
#define LIGHTING_CHECK_UPDATE 2
#define LIGHTING_FORCE_UPDATE 3

#define FLASH_LIGHT_DURATION 2
#define FLASH_LIGHT_POWER 3
#define FLASH_LIGHT_RANGE 3.8

// Emissive blocking.
/// Uses vis_overlays to leverage caching so that very few new items need to be made for the overlay. For anything that doesn't change outline or opaque area much or at all.
#define EMISSIVE_BLOCK_GENERIC 1
/// Uses a dedicated render_target object to copy the entire appearance in real time to the blocking layer. For things that can change in appearance a lot from the base state, like humans.
#define EMISSIVE_BLOCK_UNIQUE 2

/// The color matrix applied to all emissive overlays. Should be solely dependent on alpha and not have RGB overlap with [EM_BLOCK_COLOR].
#define EMISSIVE_COLOR list(0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,1, 1,1,1,0)
/// A globaly cached version of [EMISSIVE_COLOR] for quick access.
GLOBAL_LIST_INIT(emissive_color, EMISSIVE_COLOR)
/// The color matrix applied to all emissive blockers. Should be solely dependent on alpha and not have RGB overlap with [EMISSIVE_COLOR].
#define EM_BLOCK_COLOR list(0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,1, 0,0,0,0)
/// A globaly cached version of [EM_BLOCK_COLOR] for quick access.
GLOBAL_LIST_INIT(em_block_color, EM_BLOCK_COLOR)
/// The color matrix used to mask out emissive blockers on the emissive plane. Alpha should default to zero, be solely dependent on the RGB value of [EMISSIVE_COLOR], and be independant of the RGB value of [EM_BLOCK_COLOR].
#define EM_MASK_MATRIX list(0,0,0,1/3, 0,0,0,1/3, 0,0,0,1/3, 0,0,0,0, 1,1,1,0)
/// A globaly cached version of [EM_MASK_MATRIX] for quick access.
GLOBAL_LIST_INIT(em_mask_matrix, EM_MASK_MATRIX)

/// Precomputed direction unit vectors. Indexed by BYOND dir (1=NORTH .. 10=SW).
GLOBAL_LIST_INIT(light_dir_vectors, list( \
	list(0, 1),                /* 1=NORTH */ \
	list(0, -1),               /* 2=SOUTH */ \
	null,                      /* 3=unused */ \
	list(1, 0),                /* 4=EAST  */ \
	list(0.7071, 0.7071),      /* 5=NE    */ \
	list(0.7071, -0.7071),     /* 6=SE    */ \
	null,                      /* 7=unused */ \
	list(-1, 0),               /* 8=WEST  */ \
	list(-0.7071, 0.7071),     /* 9=NW    */ \
	list(-0.7071, -0.7071)     /* 10=SW   */ \
))

/// Returns the red part of a #RRGGBB hex sequence as number
#define GETREDPART(hexa) hex2num(copytext(hexa, 2, 4))

/// Returns the green part of a #RRGGBB hex sequence as number
#define GETGREENPART(hexa) hex2num(copytext(hexa, 4, 6))

/// Returns the blue part of a #RRGGBB hex sequence as number
#define GETBLUEPART(hexa) hex2num(copytext(hexa, 6, 8))

/// Parse the hexadecimal color into lumcounts of each perspective.
#define PARSE_LIGHT_COLOR(source) \
do { \
	if (source.light_color) { \
		var/__light_color = source.light_color; \
		source.lum_r = GETREDPART(__light_color) / 255; \
		source.lum_g = GETGREENPART(__light_color) / 255; \
		source.lum_b = GETBLUEPART(__light_color) / 255; \
	} else { \
		source.lum_r = 1; \
		source.lum_g = 1; \
		source.lum_b = 1; \
	}; \
} while (FALSE)

//Defines for atom layers and planes
//KEEP THESE IN A NICE ACSCENDING ORDER, PLEASE

//NEVER HAVE ANYTHING BELOW THIS PLANE ADJUST IF YOU NEED MORE SPACE
#define LOWEST_EVER_PLANE -100

#define RENDER_PLANE_TRANSPARENT -9 //Transparent plane that shows openspace underneath the floor

#define GAME_PLANE_FOV_HIDDEN -7
#define GAME_PLANE_UPPER -6
#define WALL_PLANE_UPPER -5
#define GAME_PLANE_UPPER_FOV_HIDDEN -4

#define SEETHROUGH_PLANE -3
#define ABOVE_GAME_PLANE -2

#define AREA_PLANE 2
#define MASSIVE_OBJ_PLANE 3
#define GHOST_PLANE 4
#define POINT_PLANE 5

///---------------- MISC -----------------------

///Pipecrawling images
#define PIPECRAWL_IMAGES_PLANE 20

///Anything that wants to be part of the game plane, but also wants to draw above literally everything else
#define HIGH_GAME_PLANE 22

///--------------- FULLSCREEN RUNECHAT BUBBLES ------------

///Popup Chat Messages
#define RUNECHAT_PLANE 30

//-------------------- HUD ---------------------
//HUD layer defines
#define HUD_BACKGROUND_LAYER 1
#define HUD_BUTTON_BG_LAYER 2
#define HUD_BUTTON_HIGH_BG_LAYER 3
#define HUD_ABOVE_BG_LAYER 4

//#define TURF_LAYER 2 //For easy recordkeeping; this is a byond define. Most floors (FLOOR_PLANE) and walls (GAME_PLANE) use this.

// GAME_PLANE layers
#define CULT_OVERLAY_LAYER 2.01
#define WIRE_BRIDGE_LAYER 2.44
#define PLUMBING_PIPE_VISIBILE_LAYER 2.495//layer = initial(layer) + ducting_layer / 3333 in atmospherics/handle_layer() to determine order of duct overlap
#define HIGH_PIPE_LAYER 2.54
// Anything aboe this layer is not "on" a turf for the purposes of washing
// I hate this life of ours
#define FLOOR_CLEAN_LAYER 2.55

#define CORGI_ASS_PIN_LAYER 3.41

// GAME_PLANE_FOV_HIDDEN layers
#define LOW_MOB_LAYER 3.75
#define VEHICLE_LAYER 3.9
#define MOB_BELOW_PIGGYBACK_LAYER 3.94
//#define MOB_LAYER 4 //For easy recordkeeping; this is a byond define
#define MOB_SHIELD_LAYER 4.01
#define MOB_ABOVE_PIGGYBACK_LAYER 4.06
#define HITSCAN_PROJECTILE_LAYER 4.09 //above all mob but still hidden by FoV

#define RAD_TEXT_PLANE 90

//---------- LIGHTING -------------

#define LIGHTING_PRIMARY_LAYER 15	//The layer for the main lights of the station
#define LIGHTING_PRIMARY_DIMMER_LAYER 15.1	//The layer that dims the main lights of the station
#define LIGHTING_SECONDARY_LAYER 16	//The colourful, usually small lights that go on top

///--------------- SOUND EFFECT VISUALS ------------

/// Bubble for typing indicators
#define TYPING_LAYER 1
#define RADIAL_BACKGROUND_LAYER 0
///1000 is an unimportant number, it's just to normalize copied layers
#define RADIAL_CONTENT_LAYER 1000

///Layer for tooltips
#define TOOLTIP_LAYER 4

///cinematics are "below" the splash screen
#define CINEMATIC_LAYER -1

///Plane master controller keys
#define PLANE_MASTERS_COLORBLIND "plane_masters_colorblind"

#define PLANE_CRITICAL_FUCKO_PARALLAX (PLANE_CRITICAL_DISPLAY|PLANE_CRITICAL_NO_EMPTY_RELAY)

/// We expect at most 11 layers of multiz
/// Increment this define if you make a huge map. We unit test for it too just to make it easy for you
/// If you modify this, you'll need to modify the tsx file too
#define MAX_EXPECTED_Z_DEPTH 11
