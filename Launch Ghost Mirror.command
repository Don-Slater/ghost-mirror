#!/usr/bin/env osascript
-- Launch Ghost Mirror
set mirrorApp to "/Applications/Ghost Mirror.app"
set fallback to POSIX path of (path to home folder) & "BenStudio/EaseMirror/Ghost Mirror.app"
try
	do shell script "test -d " & quoted form of mirrorApp
on error
	set mirrorApp to fallback
end try
do shell script "test -d " & quoted form of mirrorApp
tell application mirrorApp to activate
