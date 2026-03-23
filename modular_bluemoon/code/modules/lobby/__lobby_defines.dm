// Пути
#define BM_LOBBY_HTML_FILE "config/bluemoon/lobby_html.txt"

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
</style>
</head><body>
"}


