.PHONY: send get csv

put:
	git commit -am auto
	cp -f ./MMChat.lua /Volumes/Elder\ Scrolls\ Online/live/AddOns/MMChat/

get:
	cp -f /Volumes/Elder\ Scrolls\ Online/live/SavedVariables/MMChat.lua ../../SavedVariables/
	cp -f ../../SavedVariables/MMChat.lua data/

zip:
	-rm -rf published/MMChat published/MMChat\ x.x.x.zip
	mkdir -p published/MMChat
	#cp -R Libs published/MMChat/Libs
	cp ./MMChat* published/MMChat/
	cd published; zip -r MMChat\ x.x.x.zip MMChat

