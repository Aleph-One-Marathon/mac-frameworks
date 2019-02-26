#!/bin/bash

export PROJ="ffmpeg"
export VERSION="4.1.1"
export URL="http://ffmpeg.org/releases/ffmpeg-4.1.1.tar.bz2"
export OGGBASE=$(cd "../ogg/installs/x86_64" && pwd)
export VORBISBASE=$(cd "../vorbis/installs/x86_64" && pwd)
export VPXBASE=$(cd "../vpx/installs/x86_64" && pwd)
export PKGCONFIG_OVERRIDE="$OGGBASE/lib/pkgconfig:$VORBISBASE/lib/pkgconfig:$VPXBASE/lib/pkgconfig"
export CONFIGOPTS="--disable-static --enable-shared --enable-gpl --enable-libvorbis --enable-libvpx --disable-doc --disable-ffmpeg --disable-ffplay --disable-ffprobe --disable-avdevice --disable-swresample --disable-postproc --disable-avfilter --disable-everything"
CONFIGOPTS+=" --enable-muxer=webm --enable-encoder=libvorbis --enable-encoder=libvpx_vp8"
CONFIGOPTS+=" --enable-demuxer=aiff --enable-demuxer=mp3 --enable-demuxer=mpegps --enable-demuxer=mpegts --enable-demuxer=mpegtsraw --enable-demuxer=mpegvideo --enable-demuxer=ogg --enable-demuxer=wav"
CONFIGOPTS+=" --enable-parser=mpegaudio --enable-parser=mpegvideo"
CONFIGOPTS+=" --enable-decoder=adpcm_ima_wav --enable-decoder=adpcm_ms --enable-decoder=gsm --enable-decoder=gsm_ms --enable-decoder=mp1 --enable-decoder=mp1float --enable-decoder=mp2 --enable-decoder=mp2float --enable-decoder=mp3 --enable-decoder=mp3float --enable-decoder=mpeg1video --enable-decoder=pcm_alaw --enable-decoder=pcm_f32be --enable-decoder=pcm_f32le --enable-decoder=pcm_f64be --enable-decoder=pcm_f64le --enable-decoder=pcm_mulaw --enable-decoder=pcm_s8 --enable-decoder=pcm_s8_planar --enable-decoder=pcm_s16be --enable-decoder=pcm_s16le --enable-decoder=pcm_s16le_planar --enable-decoder=pcm_s24be --enable-decoder=pcm_s24le --enable-decoder=pcm_s32be --enable-decoder=pcm_s32le --enable-decoder=pcm_u8 --enable-decoder=theora --enable-decoder=vorbis --enable-decoder=vp8"
CONFIGOPTS+=" --enable-protocol=file"
CONFIGOPTS+=" --pkg-config-flags=--static"
export PATH_OVERRIDE="/usr/local/bin" # install pkg-config, glib here
export FWKS="libavcodec libavformat libavutil libswscale"
export DYLIBNAME_libavcodec="libavcodec.58.dylib"
export DYLIBNAME_libavformat="libavformat.58.dylib"
export DYLIBNAME_libavutil="libavutil.56.dylib"
export DYLIBNAME_swscale="libswscale.5.dylib"
export LICENSE="LICENSE.md"

../build-std.sh

rm -r avcodec.framework/Versions/A/Headers/libavformat
rm -r avcodec.framework/Versions/A/Headers/libavutil
rm -r avcodec.framework/Versions/A/Headers/libswscale

rm -r avformat.framework/Versions/A/Headers/libavcodec
rm -r avformat.framework/Versions/A/Headers/libavutil
rm -r avformat.framework/Versions/A/Headers/libswscale

rm -r avutil.framework/Versions/A/Headers/libavcodec
rm -r avutil.framework/Versions/A/Headers/libavformat
rm -r avutil.framework/Versions/A/Headers/libswscale

rm -r swscale.framework/Versions/A/Headers/libavcodec
rm -r swscale.framework/Versions/A/Headers/libavformat
rm -r swscale.framework/Versions/A/Headers/libavutil
