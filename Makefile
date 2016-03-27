.PHONY: send get csv

put:
	git commit -am auto
	cp -f ./GuildGoldDeposits.lua /Volumes/Elder\ Scrolls\ Online/live/AddOns/GuildGoldDeposits/

get:
	cp -f /Volumes/Elder\ Scrolls\ Online/live/SavedVariables/GuildGoldDeposits.lua ../../SavedVariables/
	cp -f ../../SavedVariables/GuildGoldDeposits.lua data/

csv: ../../SavedVariables/GuildGoldDeposits.lua
	lua GuildGoldDeposits_to_csv.lua
	cp -f ../../SavedVariables/GuildGoldDeposits.csv data/

zip:
	-rm -rf published/GuildGoldDeposits published/GuildGoldDeposits\ x.x.x.x.zip
	mkdir -p published/GuildGoldDeposits
	cp -R Libs published/GuildGoldDeposits/Libs
	cp ./GuildGoldDeposits* published/GuildGoldDeposits/
	cd published; zip -r GuildGoldDeposits\ x.x.x.x.zip GuildGoldDeposits

