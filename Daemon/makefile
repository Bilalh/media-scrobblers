CC             = clang
CFLAGS         = -g -Wall -O2 -DSHOW_INFO
SCRIPTS        = *.rb
OBJS           = last_fm_scrobble_on_mplayer_played_50 last_fm_scrobble_on_mplayer_played_50_with_info

last_fm_scrobble_on_mplayer_played_50_with_info: last_fm_scrobble_on_mplayer_played_50.o
	${CC} ${CFlAGS} $^ -o $@

install: last_fm_scrobble_on_mplayer_played_50_with_info
	[ ! -d /usr/local/bin/ ] && mkdir /usr/local/bin/; \
	chmod +x ${SCRIPTS}; \
	cp last_fm_scrobble_on_mplayer_played_50_with_info ${SCRIPTS} /usr/local/bin/

clean:
	rm *.o ${OBJS}
