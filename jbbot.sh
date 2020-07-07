#!/bin/bash

cd $HOME/ZulipBots/ZulipJuliaBloggers/
$HOME/.local/bin/julia --project=. jbbot.jl >> $HOME/logs/jbbot.log 2>&1
