.PHONY: put parse zip

put:
	rsync -vrt --delete --exclude=.git \
		--exclude=.gitignore \
		--exclude=.gitmodules \
		--exclude=data \
		--exclude=doc \
		--exclude=published \
		--exclude=save \
		. /Volumes/Elder\ Scrolls\ Online/live/AddOns/WritWorthy

get:
	cp -f /Volumes/Elder\ Scrolls\ Online/live/SavedVariables/WritWorthy.lua ../../SavedVariables/
	cp -f ../../SavedVariables/WritWorthy.lua data/

getpts:
	cp -f /Volumes/Elder\ Scrolls\ Online/pts/SavedVariables/WritWorthy.lua ../../SavedVariables/
	cp -f ../../SavedVariables/WritWorthy.lua data/

parse:
	lua wwparse.lua

zip:
	-rm -rf published/WritWorthy published/WritWorthy\ x.x.x.zip
	mkdir -p published/WritWorthy
	cp -R Libs published/WritWorthy/Libs
	cp ./WritWorthy* Bindings.xml published/WritWorthy/
	rm -rf published/WritWorthy/Libs/LibCustomTitles/.git

	cd published; zip -r WritWorthy\ x.x.x.zip WritWorthy

	rm -rf published/WritWorthy

profile:
	lua ZZProfiler_Dump.lua > profile.txt


lang/en2.lua: data/WritWorthy.lua make_lang.lua
	lua make_lang.lua
	lua lang/en2.lua

