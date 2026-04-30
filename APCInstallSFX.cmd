:: ============================================================================
::   Название: APCInstallSFX
:: Назначение: Скрипт в тихом режиме устанавливает программу Anyplace Control,
::             задавая необходимые для работы настройки. Имя хоста и пароль
::             могут быть переданы в качестве параметов командной строки.
::     Версия: 1.0
:: ============================================================================
echo on
set login=%~1
set pass=%~2
chcp 1251
SetLocal EnableExtensions EnableDelayedExpansion

:: ====== ОСНОВНАЯ ПРОЦЕДУРА ==================================================
:MAIN
:: Определяем имя хоста и пароль
call :PARAMSET
:: Деинсталлируем Anyplace Control
call :UNINSTALL
:: Устанавливаем Anyplace Control
call :INSTALL
:: Меняем параметры, заданные по умолчанию, на наши
call :PARAMEDIT

exit /b


:: ====== ОПРЕДЕЛЯЕМ ПАРАМЕТРЫ ================================================
:PARAMSET

:: Разбираем параметры, переданные в командной строке SFX: имя хоста и пароль
:: (если не передали в качестве аргумента, то определяем значение по умолчанию)
::if not .%~1.==.. (set argHost=%~1) else (set argHost=UNKNOWN_%computername%)
if not .%login%.==.. (set argHost=%login%) else (set argHost=UNKNOWN_%computername%)
::if not .%~2.==.. (set argPass=%~2) else (set argPass=Oxi57trAn)
if not .%pass%.==.. (set argPass=%pass%) else (set argPass=Oxi57trAn)
exit /b


:: ====== ДЕИНСТАЛЛЯЦИЯ =======================================================
:: Сначала удаляем Anyplace Control, иначе возможна ситуация, когда  вместо
:: установки произойдет деинсталляция.
:UNINSTALL


attrib -r "c:\ProgramData\Anyplace Control 4\hostaccount.ini"

:: убиваем процессы, связанные с Anyplace Control
taskkill.exe /F /IM apc_* >nul
  
:: если находим, то запускаем деинсталлятор для версии 5* (5.4.0.0)
set InstallDir=c:\Program Files\Anyplace Control 4\
if exist "%InstallDir%Uninstall.exe" "%InstallDir%Uninstall.exe" "%InstallDir%INSTALL.LOG" -u -s
set InstallDir=c:\Program Files (x86)\Anyplace Control 4\
if exist "%InstallDir%Uninstall.exe" "%InstallDir%Uninstall.exe" "%InstallDir%INSTALL.LOG" -u -s

  
:: если находим, то запускаем деинсталлятор для версии 7* (7.0.4.0, 7.1.0.0)
set InstallDir=c:\Program Files\Anyplace Control\
if exist "%InstallDir%Uninstall.exe" "%InstallDir%Uninstall.exe" "%InstallDir%INSTALL.LOG" -u -s
set InstallDir=c:\Program Files (x86)\Anyplace Control\
if exist "%InstallDir%Uninstall.exe" "%InstallDir%Uninstall.exe" "%InstallDir%INSTALL.LOG" -u -s

  
:: удаляем службу APC-Host, так как собственный деинсталлятор этого не делает
sc.exe delete APC-Host >nul
exit /b


:: ====== УСТАНОВКА ===========================================================
:: Запускаем установку Anyplace Control в тихм (скрытом) режиме
:INSTALL

:: После запуска инсталлятора в папке c:\ProgramData\Anyplace Control Corporate\
:: появляется файл QuickSupportIntall_tmp-IWFwYy5hcHRla2FtLnJ1IQ==.exe, который
:: и выполняет саму установку APC, тогда как инсталлятор завершает свою работу
:: не дожидаясь окончания установки.
start /w "" c:\temp\anyplacecontrolinstall-IWFwYy5hcHRla2FtLnJ1IQ==.exe /password=%argPass%

:: Потому мы сами контролируем окончание процесса установки Anyplace Control,
:: периодически проверяя завершение работы процесса "QuickSupportIntall_tmp*"
:loop
ping -n 3 127.0.0.1 >nul
tasklist|find /i "QuickSupportIntall_tmp">nul&& goto loop
exit /b


:: ====== ИЗМЕНЯЕМ ПАРАМЕТРЫ, ЗАДАННЫЕ ПО УМОЛЧАНИЮ ===========================
:PARAMEDIT

:: Имя файла настроек Anyplace Control, обязательно в кавычках!
Set CfgFile="c:\ProgramData\Anyplace Control 4\apc-settings.ini"

:: Включаем настройку "Скрытый режим"
call :REPLACEVAL %CfgFile% HideTrayIcon 1

:: Включаем настройку "Защиить паролем доступ к настройкам Host-модуля"
call :REPLACEVAL %CfgFile% Password_Use 1

:: Прописываем в настройках пароль, имя хоста и перезапускаем сервис
"c:\Program Files\Anyplace Control\apc_hostconfig.exe" /setup /password=%argPass% /hostname=%argHost%
"c:\Program Files (x86)\Anyplace Control\apc_hostconfig.exe" /setup /password=%argPass% /hostname=%argHost%
"c:\Program Files\Anyplace Control 4\apc_hostconfig.exe" /setup /password=%argPass% /hostname=%argHost%
"c:\Program Files (x86)\Anyplace Control 4\apc_hostconfig.exe" /setup /password=%argPass% /hostname=%argHost%

:: Имя файла настроек Anyplace Control, обязательно в кавычках!
Set CfgFilePort="c:\ProgramData\Anyplace Control 4\hostaccount.ini"

:: Определяем и меняем порт
set argHostLetter=%argHost:~0,1%
set port=811
if %argHostLetter% GEQ k set port=812
if %argHostLetter% GEQ n set port=813
if %argHostLetter% GEQ s set port=814

call :REPLACEVAL %CfgFilePort% port %port%

attrib +r "c:\ProgramData\Anyplace Control 4\hostaccount.ini"

net stop APC-Host
net start APC-Host

exit /b


:: ====== РЕДАКТИРОВАНИЕ НАСТРОЕК APC =========================================
:: %~1 - имя файла с настройками (обязательно указываем в кавычках)
:: %~2 - имя изменяемого параметра
:: %~3 - новое значение, которое нужно присвоить параметру
:REPLACEVAL
SetLocal
for /f "UseBackQ delims=" %%s in ("%~1") do (
  for /f "tokens=*"  %%a in ("%%s") do (
    for /f "tokens=1 delims==" %%b in ("%%a") do (if %%b==%~2 (set "c=%%b=%~3") else (set "c=%%a"))
    echo !c!>>$
  )
)
move $ "%~1"
EndLocal
exit /b

