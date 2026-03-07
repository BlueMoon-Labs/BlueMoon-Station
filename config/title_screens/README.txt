После перехода на лобби bluemoon нужно всего-лишь закинуть любую картинку формата .png .jpg / .jpeg .gif .dmi 
в соответствующую папку для SFW это config\title_screens, для NSFW это config\title_screens\NSFW
Для видео-фона — отдельный путь через SStitle_bm.set_video(payload) (admin controls), там формат зависит от того что передаст адмнн через payload — это iframe/embed, не файл с диска.
Примечание:
.webp не поддерживается
для того чтобы картинки работали на линуксе, нужно писать название файла в строку, типа lobbybigass1.png.