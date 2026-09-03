#!/bin/bash

#Run this in the repo root after compiling
#First arg is path to where you want to deploy
#creates a work tree free of everything except what's necessary to run the game

#second arg is working directory if necessary
if [[ $# -eq 2 ]] ; then
  cd $2
fi

mkdir -p \
    $1/_maps \
    $1/icons/runtime \
    $1/sound/runtime \
    $1/strings

if [ -d ".git" ]; then
  mkdir -p $1/.git/logs
  cp -r .git/logs/* $1/.git/logs/
fi

cp -r _maps/* $1/_maps/
cp -r icons/runtime/* $1/icons/runtime/
cp -r strings/* $1/strings/

#Спрайтшиты интерфейсов собирает rust-g (IconForge), а он читает .dmi с диска и ищет
#их относительно рабочего каталога сервера - в .rsc он не заглядывает. Без файлов
#иконок лист приезжает пустым, поэтому в деплой едут все .dmi всех деревьев кода.
#config сюда не попадает намеренно: конфиг серверу подкладывают снаружи, а созданный
#заранее каталог сломал бы тому же CI его собственный mkdir.
#find вырезает каталог деплоя по относительному пути вида ./x, поэтому $1 заранее
#приводится к нему: абсолютный путь, ./-префикс или хвостовой слеш иначе тихо ломают
#-prune, и повторный деплой утащит уже разложенные DMI внутрь $1/$1.
deploy_prune=$(realpath -m --relative-base=. -- "$1")
find . \
    -path ./.git -prune -o \
    -path ./.claude -prune -o \
    -path ./config -prune -o \
    -path ./data -prune -o \
    -path ./tools -prune -o \
    -path "./$deploy_prune" -prune -o \
    -name "*.dmi" -print0 \
    | xargs -0 -r cp --parents -t "$1/"

#remove .dm files from _maps

#this regrettably doesn't work with windows find
#find $1/_maps -name "*.dm" -type f -delete

#dlls on windows
if [ "$(uname -o)" = "Msys"  ]; then
	cp ./*.dll $1/
fi

#Мир нередко запускают по появлению dmb. Если dmb лечь первым, сторож стартует сервер,
#пока сюда ещё копируются тысячи DMI - rust-g не найдёт часть файлов, спрайтшиты уедут
#игрокам дырявыми, а их кэш запишется с неполными хэшами (раунд 9954). Поэтому dmb и
#rsc кладутся последними, когда всё остальное уже на месте.
cp tgstation.dmb tgstation.rsc $1/
