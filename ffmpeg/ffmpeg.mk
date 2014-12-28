# This file is Aleph One's custom config for ffmpeg under MXE.

PKG             := ffmpeg
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 1.2.7
$(PKG)_CHECKSUM := ff49a6b28e174f9f8072638d8251e1e447666ef6
$(PKG)_SUBDIR   := $(PKG)-$($(PKG)_VERSION)
$(PKG)_FILE     := $(PKG)-$($(PKG)_VERSION).tar.bz2
$(PKG)_URL      := http://www.ffmpeg.org/releases/$($(PKG)_FILE)
$(PKG)_URL_2    := http://launchpad.net/ffmpeg/main/$($(PKG)_VERSION)/+download/$($(PKG)_FILE)
$(PKG)_DEPS     := gcc bzip2 libvpx ogg sdl speex vorbis zlib

define $(PKG)_UPDATE
    $(WGET) -q -O- 'http://www.ffmpeg.org/download.html' | \
    $(SED) -n 's,.*ffmpeg-\([0-9][^>]*\)\.tar.*,\1,p' | \
    head -1
endef

define $(PKG)_BUILD
    '$(SED)' -i "s^[-]lvpx^`'$(TARGET)'-pkg-config --libs-only-l vpx`^g;" $(1)/configure
    cd '$(1)' && ./configure \
        --cross-prefix='$(TARGET)'- \
        --enable-cross-compile \
        --arch=$(patsubst -%,,$(TARGET)) \
        --target-os=mingw32 \
        --prefix='$(PREFIX)/$(TARGET)' \
        --disable-shared \
        --disable-debug \
        --disable-doc \
        --enable-memalign-hack \
        --enable-gpl \
        --enable-version3 \
        --disable-nonfree \
        --enable-postproc \
        --disable-pthreads \
        --enable-w32threads \
        --enable-libvorbis \
        --enable-libvpx \
        --disable-everything \
        --enable-muxer=webm \
        --enable-encoder=libvorbis \
        --enable-encoder=libvpx_vp8 \
        --enable-demuxer=aiff \
        --enable-demuxer=mp3 \
        --enable-demuxer=mpegps \
        --enable-demuxer=mpegts \
        --enable-demuxer=mpegtsraw \
        --enable-demuxer=mpegvideo \
        --enable-demuxer=ogg \
        --enable-demuxer=wav \
        --enable-parser=mpegaudio \
        --enable-parser=mpegvideo \
        --enable-decoder=adpcm_ima_wav \
        --enable-decoder=adpcm_ms \
        --enable-decoder=gsm \
        --enable-decoder=gsm_ms \
        --enable-decoder=mp1 \
        --enable-decoder=mp1float \
        --enable-decoder=mp2 \
        --enable-decoder=mp2float \
        --enable-decoder=mp3 \
        --enable-decoder=mp3float \
        --enable-decoder=mpeg1video \
        --enable-decoder=pcm_alaw \
        --enable-decoder=pcm_f32be \
        --enable-decoder=pcm_f32le \
        --enable-decoder=pcm_f64be \
        --enable-decoder=pcm_f64le \
        --enable-decoder=pcm_mulaw \
        --enable-decoder=pcm_s8 \
        --enable-decoder=pcm_s8_planar \
        --enable-decoder=pcm_s16be \
        --enable-decoder=pcm_s16le \
        --enable-decoder=pcm_s16le_planar \
        --enable-decoder=pcm_s24be \
        --enable-decoder=pcm_s24le \
        --enable-decoder=pcm_s32be \
        --enable-decoder=pcm_s32le \
        --enable-decoder=pcm_u8 \
        --enable-decoder=theora \
        --enable-decoder=vorbis \
        --enable-decoder=vp8 \
        --enable-protocol=file
    $(MAKE) -C '$(1)' -j '$(JOBS)'
    $(MAKE) -C '$(1)' -j 1 install
endef
