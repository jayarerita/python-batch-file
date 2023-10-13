@ECHO OFF
:: This script checks if a virtual environment is available, creates one if not.
:: Checks that all the correct packges are installed and installs them if not.
:: Checks that the correct base version of python is being used and raises a warning if not.
:: Runs the script from the available or installed venv.

:: ********************************************
:: set to name of script in local dir to run
SET script_name=tracker.py
:: Ex: 3.7 or 3.7.3, do not include "Python"
SET python_req=3.7
:: ********************************************

:: Set up a variable to this folder
SET script_dir=%~dp0%
cd %script_dir%

ECHO This program will run %script_name%

:: Check for virtual environment folder
IF EXIST %script_dir%venv\Scripts\activate (
    ECHO Found virtual environment at %script_dir%venv
    :: Check that the correct version of python is being used
    CALL :venv_version_check %script_dir%venv\Scripts\python.exe
    :: Check for the required packages
    GOTO :req_check 
) ELSE (
    ECHO No existing virtual environment found when searching for %script_dir%venv\Scripts\activate
    :: If not found we need to set one up
    GOTO :set_up
)

:venv_version_check
ECHO Checking that the correct version of python is available...

::for /f "delims=" %%a IN ('%test_command% 2^>^&1 1^>temp.txt') do (
::    set err_msg="%%~a" && set /p var=<temp.txt
::)

:: This passes the output of the version check to the output_str variable, Ex: output_str=Python 3.7.3
:: In python2 the response from the version check is set to stderr but in python3 it is set to stdout
:: We need to make sure we set the stdout to the variable and then append the stderr

:: We run an initial version check on the provided python.exe path
FOR /F "delims=" %%V in ('%~1 --version 2^>^&1') do SET output_str=%%V

::%~1 --version > %script_dir%version_check.txt 2>&1
::set /p output_str=<%script_dir%version_check.txt
:: Clean up temp files
::DEL %script_dir%version_check.txt

:: Get charaters 7-10 for the version Ex: Python 3.7.3 -> 3
SET maj_version_str=%output_str:~7,1%
SET maj_req=%python_req:~0,1%
::ECHO output_str=%output_str%
::ECHO maj_req=%maj_req%
::ECHO maj_version_str=%maj_version_str%

ECHO Program requires Python %python_req%
ECHO %output_str% found at %~1

IF %maj_version_str% EQU %maj_req% (
    :: Exit back to code
    ECHO Version check: Passed
    EXIT /B 0
) ELSE (
    IF EXIST %script_dir%venv\Scripts\python.exe (
        ECHO Version check: Failed!
        ECHO Deleting virtual environment...
        RMDIR /S %script_dir%venv
        GOTO :set_up
    ) ELSE (
        ECHO Version check: Failed!
        GOTO :set_up
    )
)

:: Check for requirements.txt
:requirements_file
IF NOT EXIST %script_dir%requirements.txt (
    ECHO Requirements file check - Failed
    ECHO Cannot find %script_dir%requirements.txt
    ECHO Exiting...
    pause
    EXIT
) ELSE (
    :: If passes exit out of subprocess
    ECHO Found %script_dir%requirements.txt
    ECHO Requirements file check - Passed
    EXIT /B 0
)

:: Check that the requried packages are installed, if not install them
:req_check
:: Check for requirements.txt
CALL :requirements_file

ECHO Checking if all packages are installed...
:: Get a list of current pkg installed
%script_dir%venv\Scripts\pip.exe freeze >> %script_dir%current_requirements.txt
:: Compare to the requirements.txt in the project folder
SET installed=0
FC %script_dir%current_requirements.txt %script_dir%requirements.txt > NUL && SET installed=1 || SET installed=0
:: Clean up the temp files
DEL %script_dir%current_requirements.txt

IF %installed%==1 (
    ECHO Dependencies check - Passed
    GOTO :run_script
) ELSE (
    ECHO Dependencies check - Failed
    GOTO :any_pkgs
)

:: Check if there are any installed packages
:any_pkgs
TYPE NUL > %script_dir%blank.txt
:: Get a list of current pkg installed
%script_dir%venv\Scripts\pip.exe freeze >> %script_dir%current_requirements.txt
SET no_pkg=0
FC %script_dir%current_requirements.txt %script_dir%blank.txt > NUL && SET no_pkg=1 || SET no_pkg=0
:: Clean up temp files
DEL %script_dir%blank.txt
DEL DEL %script_dir%current_requirements.txt

:: If the environment is blank we can then install the req pkgs
IF %no_pkg% EQU 1 (
    ECHO Virtual environment needs to have packages installed
    GOTO :install_pkgs
) ELSE (
    ECHO Virtual environment has the wrong packages deleting...
    :: Delete the present venv and recreate
    RMDIR /S %script_dir%venv
    GOTO :set_up
)

:: Create the virtual environment base
:set_up
ECHO Creating virtual environment...

:: Double check for existing venv due to failed deletion
IF EXIST %script_dir%venv (
    ECHO Found existing virtual environment. Must be deleted to continue...
    RMDIR /S %script_dir%venv
    GOTO :set_up
)

:: Check for requirements file
CALL :requirements_file

:: Set up the path to local python executable
:loop_path
ECHO Enter the absolute path to the local Python %python_req% executable or default
:: Search for all python executables in PATH and display
ECHO The following executables were found in your PATH...
for /F "delims=" %%W in ('where python') do (
    for /F "tokens=2" %%V in ('"%%W" --version 2^>^&1') do (
        ECHO %%W is version %%V
    )
)
ECHO Example Input: C:\Python38\pythone.exe
SET /P exe_path="Input: "

:: Check if the path is valid and repeat input if not
SET exe_check=0

IF EXIST %exe_path% SET exe_check=1
IF %exe_path% EQU default SET exe_check=2

if %exe_check% EQU 0 (
    ECHO Could not locate %exe_path%
    ECHO Please enter a valid path or default
    GOTO :loop_path
)
IF %exe_check% EQU 1 ECHO python.exe found at %exe_path%
IF %exe_check% EQU 2 ECHO Using default python.exe provided

ECHO Creating virtual environment base...
:: Create venv
IF %exe_path% EQU default (
    virtualenv venv
) ELSE (
    virtualenv --python=%exe_path% venv
)

ECHO Created virtual environment at %script_dir%venv

:: Check that the correct version of python is being used
CALL :venv_version_check %script_dir%venv\Scripts\python.exe

GOTO :install_pkgs

:: Install dependencies
:install_pkgs
ECHO Installing dependencies to venv...
::%script_dir%venv\Scripts\activate && %script_dir%venv\Scripts\python.exe -m pip install -r %script_dir%requirements.txt
%script_dir%venv\Scripts\pip.exe install -r %script_dir%requirements.txt
ECHO Finished installing the needed packages

:run_script
:: Run script using executable in venv
ECHO Running %script_name%...
%script_dir%venv\Scripts\python.exe %script_dir%%script_name%
pause
