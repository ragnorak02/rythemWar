@echo off
REM RhythmWar test runner — launcher contract
REM Outputs JSON to stdout with gameId, status, testsTotal, testsPassed, details[]

set GODOT="C:\Users\nick\Downloads\Godot_v4.6-stable_win64.exe\Godot_v4.6-stable_win64.exe"
set PROJECT_DIR=%~dp0..

%GODOT% --path "%PROJECT_DIR%" --headless --script res://tests/run_tests.gd 2>nul
