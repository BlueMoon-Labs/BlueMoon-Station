// Пути
/// Разметка/стили лобби (в репозитории рядом с модулями лобби, не в config/).
#define BM_LOBBY_HTML_FILE "modular_bluemoon/code/modules/lobby/lobby_html.txt"

/// Вероятность радуги для кнопки «Магазин» в процентах (0–100). 100 = всегда. Дублируется в bm_lobby.js: `BM_METASHOP_RAINBOW_P`.
#define BM_METASHOP_RAINBOW_P 100

#define BM_LOBBY_IMAGES_SFW "config/title_screens/"

#define BM_LOBBY_IMAGES_NSFW "config/title_screens/NSFW/"

#define BM_LOBBY_DEFAULT_IMAGE 'icons/runtime/default_title.dmi'

#define BM_LOBBY_LOADING_GIF "config/title_screens/cyberpunk_cityscape.gif"

#define BM_DEFAULT_LOBBY_HTML_PREAMBLE {"<!DOCTYPE html>
<html lang='ru'>
<head>
<meta charset='UTF-8'>
<meta name='viewport' content='width=device-width, initial-scale=1.0'>
<title>BlueMoon Station</title>
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
html,body{width:100%;height:100%;overflow:hidden;background:#000;font-family:'Courier New',monospace;user-select:none;cursor:default}
.bg{position:absolute;width:auto;height:100vmin;min-width:100vmin;min-height:100vmin;top:50%;left:50%;transform:translate(-50%,-50%);z-index:0}
#bm-overlay{position:fixed;top:0;left:0;width:100%;height:100%;background:linear-gradient(135deg,rgba(0,0,0,0.5) 0%,rgba(0,5,20,0.28) 50%,rgba(0,0,0,0.6) 100%);z-index:2;pointer-events:none}
#bm-sidebar{position:fixed;top:0;right:0;height:100%;width:clamp(200px,28vmin,340px);z-index:15;display:flex;flex-direction:column;justify-content:center;background:rgba(5,10,40,0.88);border-left:1px solid rgba(100,160,255,0.25)}
.bm-btn{display:block;width:100%;background:none;border:none;text-decoration:none;color:#cce;font-family:'Courier New',monospace;font-size:clamp(10px,1.8vmin,18px);padding:1vmin 1vmin 1vmin 2.5vmin;cursor:pointer;white-space:nowrap;text-overflow:ellipsis;overflow:hidden}
.bm-btn:hover{color:#ffe}.bm-btn .bm-checked{color:#4f4}.bm-btn .bm-unchecked{color:#f44}
@keyframes bm-ms-rainbow{0%{filter:hue-rotate(0deg);color:#8cf}100%{filter:hue-rotate(360deg);color:#fc8}}
.bm-metashop{font-weight:bold}
.bm-ms-rainbow{animation:bm-ms-rainbow 5s linear infinite}
.bm-metashop-slot{display:flex;flex-direction:column;width:100%;margin:0.55vmin 0;padding:0;border-top:1px solid rgba(60,90,160,0.2);border-bottom:1px solid rgba(60,90,160,0.2);background:rgba(0,6,22,0.48)}
.bm-metashop-nullspace{height:clamp(5px,1vmin,12px);min-height:5px;width:100%;pointer-events:none;flex-shrink:0;display:block;font-size:0;line-height:0;overflow:hidden}
</style>
</head><body>
"}


