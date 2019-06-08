.PHONY: put parse zip doc

put:
	rsync -vrt --delete --exclude=.git \
		--exclude=.gitignore \
		--exclude=.gitmodules \
		--exclude=data \
		--exclude=doc \
		--exclude=published \
		--exclude=save \
		--exclude=tool \
		. /Volumes/Elder\ Scrolls\ Online/live/AddOns/WritWorthy

get:
	cp  -f /Volumes/Elder\ Scrolls\ Online/live/SavedVariables/WritWorthy.lua     data/
	-cp -f /Volumes/Elder\ Scrolls\ Online/live/SavedVariables/LibDebugLogger.lua data/


getpts:
	cp  -f /Volumes/Elder\ Scrolls\ Online/pts/SavedVariables/WritWorthy.lua     data/
	-cp -f /Volumes/Elder\ Scrolls\ Online/pts/SavedVariables/LibDebugLogger.lua data/

parse:
	lua wwparse.lua

zip:
	-rm -rf published/WritWorthy published/WritWorthy\ x.x.x.zip
	mkdir -p published/WritWorthy
	cp -R lang published/WritWorthy/lang
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

log:
	lua tool/log_to_text.lua > data/log.txt

doc:
	tool/2bbcode_phpbb  <README.md >/tmp/md2bbdoc
	sed sSdoc/hsm_stations_marked.jpgShttps://cdn-eso.mmoui.com/preview/pvw8154.jpgS /tmp/md2bbdoc >doc/README.bbcode
