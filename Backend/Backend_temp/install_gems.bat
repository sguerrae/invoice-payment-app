@echo off
echo Instalando sqlite3 y otras dependencias...
cd %~dp0
C:\Ruby34-x64\bin\gem install sqlite3
C:\Ruby34-x64\bin\gem install rails -v 8.0.2
C:\Ruby34-x64\bin\gem install nokogiri
C:\Ruby34-x64\bin\gem install httparty
C:\Ruby34-x64\bin\gem install sidekiq
C:\Ruby34-x64\bin\gem install dotenv-rails
C:\Ruby34-x64\bin\gem install puma
