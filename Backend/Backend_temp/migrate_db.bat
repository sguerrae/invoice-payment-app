@echo off
echo Creando directorios de base de datos...
cd %~dp0
if not exist db mkdir db
echo. > db\development.sqlite3
echo Creada la base de datos SQLite3 en db/development.sqlite3
