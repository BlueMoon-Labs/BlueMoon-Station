/// Max |x|/|y| for IE chips on the TGUI canvas (must match wire-scale panning).
#define IE_TGUI_COMPONENT_COORD_LIMIT 25000

/// Максимум одновременно «живых» подсветок импульсов в окне TGUI (очередь по порядку активации).
#define IE_TGUI_MAX_LIVE_PULSES 64

/// Автораскладка без сохранённых координат: шаг между колонками (слоями) графа, px.
#define IE_TGUI_LAYOUT_COL_GAP 500
/// Автораскладка: вертикальный зазор между нодами в колонке, px.
#define IE_TGUI_LAYOUT_NODE_Y_PAD 500

#define IC_TOPIC_UNHANDLED 0
#define IC_TOPIC_HANDLED 1
#define IC_TOPIC_REFRESH 2
#define IC_FLAG_ANCHORABLE 1
#define IC_FLAG_CAN_FIRE 2

/// Max characters for printer "load program" JSON (layout fields etc. inflate size).
#define MAX_IC_PRINTER_JSON_LEN (512 * 1024)
