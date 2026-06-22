#!/usr/bin/env osascript
-- Open Ease Mirror status + commands (right pane reference)
set home to POSIX path of (path to home folder)
set statusFile to home & "BenStudio/EaseMirror/STATUS.md"
set cmdFile to home & "BenStudio/EaseMirror/COMMANDS.md"
do shell script "open " & quoted form of statusFile
do shell script "open " & quoted form of cmdFile
return "Opened STATUS.md + COMMANDS.md"
