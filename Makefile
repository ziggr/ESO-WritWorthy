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

# Use sed to replace all my private, local, relative image paths with
# public, global, absolute paths to the same images hosted on esoui.com.
#
# I don't know why 2bbcode is inserting occasional [img=] tags instead
# of [img], but we'll just brute-force sed them away.
#
doc:
	tool/2bbcode_phpbb  <README.md >/tmp/md2bbdoc
	sed 'sSRequired, install separately:S[color="red"]Required, install separately:[/color]S' /tmp/md2bbdoc >/tmp/md2bbdoc_a ; mv /tmp/md2bbdoc_a /tmp/md2bbdoc
		sed 'sSNew and experimental as of 2019-06-04.S[color="gold"]New and experimental as of 2019-06-04.[/color]S' /tmp/md2bbdoc >/tmp/md2bbdoc_a ; mv /tmp/md2bbdoc_a /tmp/md2bbdoc
	sed 'sS=]doc/img/ww_big.jpgS]https://cdn-eso.mmoui.com/preview/pvw5262.jpgS' /tmp/md2bbdoc >/tmp/md2bbdoc_a ; mv /tmp/md2bbdoc_a /tmp/md2bbdoc
	sed sSdoc/img/ww_warn.jpgShttps://cdn-eso.mmoui.com/preview/pvw5322.jpgS /tmp/md2bbdoc >/tmp/md2bbdoc_a ; mv /tmp/md2bbdoc_a /tmp/md2bbdoc
	sed sSdoc/img/window-partially-complete.jpgShttps://cdn-eso.mmoui.com/preview/pvw5718.jpgS /tmp/md2bbdoc >/tmp/md2bbdoc_a ; mv /tmp/md2bbdoc_a /tmp/md2bbdoc
	sed sSdoc/img/warning-temper-expertise.jpgShttps://cdn-eso.mmoui.com/preview/pvw5719.jpgS /tmp/md2bbdoc >/tmp/md2bbdoc_a ; mv /tmp/md2bbdoc_a /tmp/md2bbdoc
	sed sSdoc/img/ww_ags.jpgShttps://cdn-eso.mmoui.com/preview/pvw7851.jpgS /tmp/md2bbdoc >/tmp/md2bbdoc_a ; mv /tmp/md2bbdoc_a /tmp/md2bbdoc
	sed sSdoc/img/hsm_stations_marked.jpgShttps://cdn-eso.mmoui.com/preview/pvw8154.jpgS /tmp/md2bbdoc >/tmp/md2bbdoc_a ; mv /tmp/md2bbdoc_a /tmp/md2bbdoc
	cp /tmp/md2bbdoc doc/README.bbcode
