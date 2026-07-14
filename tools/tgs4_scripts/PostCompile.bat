@echo off
set "GAME_DIR=%~1"
if "%GAME_DIR%"=="" (
	echo TGS did not provide the game directory
	exit /b 2
)
set "TG_BOOTSTRAP_CACHE=%~dp0"
call "%GAME_DIR%\tools\bootstrap\python.bat" "%GAME_DIR%\tools\rsc_deploy\rsc_deploy.py" publish --game-dir "%GAME_DIR%" --config "%~dp0..\GameStaticFiles\config\rsc_deploy.env"
exit /b %errorlevel%
