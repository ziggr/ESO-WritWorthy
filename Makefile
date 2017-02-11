.PHONY: put parse zip

put:
	#git commit -am auto
	cp -f ./WritWorthy*.lua /Volumes/Elder\ Scrolls\ Online/live/AddOns/WritWorthy/
	cp -f ./WritWorthy.txt /Volumes/Elder\ Scrolls\ Online/live/AddOns/WritWorthy/

parse:
	lua wwparse.lua

lua:
	-lua WritWorthy.lua
	-lua WritWorthy_Link.lua
	-lua WritWorthy_MatRow.lua
	-lua WritWorthy_Util.lua
	-lua WritWorthy_Smithing.lua

zip:
	-rm -rf published/WritWorthy published/WritWorthy\ x.x.x.zip
	mkdir -p published/WritWorthy
	# cp -R Libs published/WritWorthy/Libs
	cp ./WritWorthy* published/WritWorthy/
	cd published; zip -r WritWorthy\ x.x.x.zip WritWorthy

