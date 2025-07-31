@echo off
echo Iniciando servidor Rails...
cd %~dp0
set BUNDLE_GEMFILE=%~dp0Gemfile
C:\Ruby34-x64\bin\ruby -r bundler/setup -e "system('C:\\Ruby34-x64\\bin\\bundle exec rails server')"
