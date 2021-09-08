@echo off
for /f "delims=" %%F in ('dir spsauce\SPSauce-*-all.jar /b /o-n') do set spsfile=%%F
if "%spsfile%"=="" goto :EOF
call java -jar spsauce\%spsfile% %*
