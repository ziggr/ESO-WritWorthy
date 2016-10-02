.PHONY: send get csv

put:
	git commit -am auto
	cp -f ./NetWorth.lua /Volumes/Elder\ Scrolls\ Online/live/AddOns/NetWorth/

get:
	cp -f /Volumes/Elder\ Scrolls\ Online/live/SavedVariables/NetWorth.lua ../../SavedVariables/
	cp -f ../../SavedVariables/NetWorth.lua data/

csv: ../../SavedVariables/NetWorth.lua
	lua NetWorth_to_csv.lua
	cp -f ../../SavedVariables/NetWorth.csv data/

zip:
	-rm -rf published/NetWorth published/NetWorth\ x.x.x.zip
	mkdir -p published/NetWorth
	cp -R Libs published/NetWorth/Libs
	cp ./NetWorth* published/NetWorth/
	cd published; zip -r NetWorth\ x.x.x.zip NetWorth

