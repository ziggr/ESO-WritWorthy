.PHONY: send get csv

put:
	git commit -am auto
	cp -f ./GuildBankLedger.lua /Volumes/Elder\ Scrolls\ Online/live/AddOns/GuildBankLedger/

get:
	cp -f /Volumes/Elder\ Scrolls\ Online/live/SavedVariables/GuildBankLedger.lua ../../SavedVariables/
	cp -f ../../SavedVariables/GuildBankLedger.lua data/

csv: ../../SavedVariables/GuildBankLedger.lua
	lua GuildBankLedger_to_csv.lua
	cp -f ../../SavedVariables/GuildBankLedger.csv data/

zip:
	-rm -rf published/GuildBankLedger published/GuildBankLedger\ x.x.x.x.zip
	mkdir -p published/GuildBankLedger
	cp -R Libs published/GuildBankLedger/Libs
	cp ./GuildBankLedger* published/GuildBankLedger/
	cd published; zip -r GuildBankLedger\ x.x.x.x.zip GuildBankLedger

