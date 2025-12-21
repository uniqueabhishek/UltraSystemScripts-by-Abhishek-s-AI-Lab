@echo off
title User Password Management Tool
color 0A
setlocal EnableDelayedExpansion

:main_menu
cls
echo ================================================
echo       User Password Management Tool
echo ================================================
echo.

:: Initialize counters
set gen_count=0
set sys_count=0

:: Fetch all user accounts
for /f "skip=4 tokens=*" %%A in ('net user') do (
    if "%%A"=="" goto :list_done
    for %%B in (%%A) do (
        rem Filter out the footer line
        if NOT "%%B"=="The" if NOT "%%B"=="command" if NOT "%%B"=="completed" if NOT "%%B"=="successfully." (
            rem Define a simple system accounts list
            if /I "%%B"=="DefaultAccount" (
                set /a sys_count+=1
                set sys_user[!sys_count!]=%%B
            ) else if /I "%%B"=="WDAGUtilityAccount" (
                set /a sys_count+=1
                set sys_user[!sys_count!]=%%B
            ) else if /I "%%B"=="WsiAccount" (
                set /a sys_count+=1
                set sys_user[!sys_count!]=%%B
            ) else (
                set /a gen_count+=1
                set gen_user[!gen_count!]=%%B
                echo !gen_count!. %%B
            )
        )
    )
)

:list_done

:: Store totals
set total_gen=%gen_count%
set total_sys=%sys_count%

echo.
echo System accounts (hidden from selection):
for /L %%i in (1,1,%total_sys%) do (
    echo     - !sys_user[%%i]!
)

echo.
set /p user_choice=Select user by number (or type 0 to exit):

if "%user_choice%"=="0" goto :eof

:: Validate input
set /a user_choice_num=%user_choice% 2>nul
if !user_choice_num! lss 1 goto invalid_selection
if !user_choice_num! gtr %total_gen% goto invalid_selection
goto valid_selection

:invalid_selection
echo Invalid selection. Press any key to try again.
pause >nul
goto main_menu

:valid_selection

:: Get selected username
set selected_user=!gen_user[%user_choice_num%]!

:operation_menu
cls
echo ================================================
echo Managing user: %selected_user%
echo ================================================
echo 1. Remove Password
echo 2. Set New Password
echo 3. Exit
echo.
set /p operation_choice=Select operation [1-3]:

if "%operation_choice%"=="1" goto remove_password
if "%operation_choice%"=="2" goto set_new_password
if "%operation_choice%"=="3" goto main_menu

echo Invalid choice. Press any key to try again.
pause >nul
goto operation_menu

:remove_password
echo.
set /p confirm=Are you sure you want to REMOVE the password for user '%selected_user%'? (Y/N):
if /I "%confirm%"=="Y" (
    net user "%selected_user%" "" >nul 2>&1
    if !errorlevel!==0 (
        echo Password removed successfully!
    ) else (
        echo Failed to remove password. Make sure you have Administrator privileges.
    )
) else (
    echo Action canceled by user.
)
pause
goto main_menu

:set_new_password
echo.
set /p new_pass=Enter new password:
set /p new_pass_confirm=Confirm new password:

if NOT "%new_pass%"=="%new_pass_confirm%" (
    echo Passwords do not match! Press any key to try again.
    pause >nul
    goto set_new_password
)

set /p confirm=Are you sure you want to SET the new password for user '%selected_user%'? (Y/N):
if /I "%confirm%"=="Y" (
    net user "%selected_user%" "%new_pass%" >nul 2>&1
    if !errorlevel!==0 (
        echo Password changed successfully!
    ) else (
        echo Failed to change password. Make sure you have Administrator privileges.
    )
) else (
    echo Action canceled by user.
)
pause
goto main_menu
