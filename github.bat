@echo off
chcp 65001
d:
cd \WorkSpace\Code\VS\command-tools

git remote add origin https://github.com/Tridays/command-tools
git pull origin main
git add .
git status
git commit -m "git up"
git push --set-upstream origin main
pause