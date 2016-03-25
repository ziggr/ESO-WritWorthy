.PHONY: send get csv

put:
	git commit -am auto
	cp -f ./GuildGoldDeposits.lua /Volumes/Elder\ Scrolls\ Online/live/AddOns/GuildGoldDeposits/

get:
	cp -f /Volumes/Elder\ Scrolls\ Online/live/SavedVariables/GuildGoldDeposits.lua ../../SavedVariables/

csv: ../../SavedVariables/GuildGoldDeposits.csv

../../SavedVariables/GuildGoldDeposits.csv: ../../SavedVariables/GuildGoldDeposits.lua
	lua GuildGoldDeposits_to_csv.lua
