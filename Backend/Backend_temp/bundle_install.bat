@echo off
echo Instalando dependencias...
cd %~dp0
C:\Ruby34-x64\bin\gem install bundler
set BUNDLE_GEMFILE=%~dp0Gemfile
C:\Ruby34-x64\bin\bundle config set --local path vendor/bundle
C:\Ruby34-x64\bin\bundle install
