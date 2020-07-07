# Initial setup

## Installation

Since this is not registered package, you should install it manually

```sh
mkdir ~/ZulipBots
cd ~/ZulipBots
git clone https://github.com/Arkoniak/ZulipJuliaBloggers.jl.git ZulipJuliaBloggers
cd ZulipJuliaBloggers
julia
```

```julia
julia> ]
pkg> activate .
pkg> instantiate
```

## Configuration

For proper functioning, bot requires `configuration.jl` file in root directory. Since this file contains secrets it is not under version control, and should be created manually. Template of this file can be found in `config_tmpl.jl`, which should be copied to `configuration.jl` and edited approppriately.

## Database setup
Before first run, you should setup sqlite database. Recommended location is in `db` folder, but you can choose any other location, which is set in `configuration.jl` file, paramater `SODB`.

For db creation run
```sh
julia --project=. create_db.jl
```

# Bot
Bot itself can be found in root directory, file `jbbot.jl`, so it can be run manually 
```sh
julia --project=. jbbot.jl
```

To run as a cron job (as a local user) you can create executable shell script (fix julia path if needed)

```sh
#!/bin/bash

cd $HOME/ZulipBots/ZulipJuliaBloggers/
$HOME/.local/bin/julia --project=. jbbot.jl >> $HOME/logs/jbbot.log 2>&1
```

and in `crontab -e` install

```sh
0 * * * * $HOME/ZulipBots/ZulipJuliaBloggers/jbbot.sh >> $HOME/logs/cron_jbbot.log 2>&1
```
