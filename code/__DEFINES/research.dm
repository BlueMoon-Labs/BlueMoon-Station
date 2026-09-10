
#define DEPARTMENTAL_FLAG_SECURITY		(1<<0)
#define DEPARTMENTAL_FLAG_MEDICAL		(1<<1)
#define DEPARTMENTAL_FLAG_CARGO			(1<<2)
#define DEPARTMENTAL_FLAG_SCIENCE		(1<<3)
#define DEPARTMENTAL_FLAG_ENGINEERING	(1<<4)
#define DEPARTMENTAL_FLAG_SERVICE		(1<<5)
#define DEPARTMENTAL_FLAG_ALL			(1<<6)			//NO THIS DOESN'T ALLOW YOU TO PRINT EVERYTHING, IT'S FOR ALL DEPARTMENTS!
//#define DEPARTMENTAL_FLAG_MINING		(1<<7)

#define DESIGN_ID_IGNORE "IGNORE_THIS_DESIGN"

#define RESEARCH_MATERIAL_RECLAMATION_ID		"__materials"
#define RESEARCH_DEEP_SCAN_ID					"__deepscan"

//When adding new types, update the list below!
#define TECHWEB_POINT_TYPE_GENERIC "General Research"

#define TECHWEB_POINT_TYPE_DEFAULT TECHWEB_POINT_TYPE_GENERIC

//defined here so people don't forget to change this!
#define TECHWEB_POINT_TYPE_LIST_ASSOCIATIVE_NAMES list(\
	TECHWEB_POINT_TYPE_GENERIC = "General Research"\
	)

#define LARGEST_BOMB				"bomb"

#define BOMB_TARGET_POINTS			50000 //Adjust as needed. Actual hard cap is double this, but will never be reached due to hyperbolic curve.
#define BOMB_TARGET_SIZE			300 // The shockwave radius required for a bomb to get TECHWEB_BOMB_MIDPOINT points.
// Linux still has old trit fires, so
#define BOMB_SUB_TARGET_EXPONENT	3 // The power of the points curve below the target size. Higher = less points for worse bombs, below target.
