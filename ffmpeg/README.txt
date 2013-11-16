For support reasons, only specific codecs are enabled in FFmpeg. When updating the list, also update the "ffmpeg.mk" file in this directory -- that file defines the options to use in the MXE Windows cross-compile.

The following formats are enabled for Aleph One:

DECODERS:
# AIFF/WAV formats -- replacing sndfile
adpcm_ima_wav
adpcm_ms
gsm
gsm_ms
pcm_alaw
pcm_f32be
pcm_f32le
pcm_f64be
pcm_f64le
pcm_mulaw
pcm_s8
pcm_s8_planar
pcm_s16be
pcm_s16le
pcm_s16le_planar
pcm_s24be
pcm_s24le
pcm_s32be
pcm_s32le
pcm_u8

# MPEG audio formats -- replacing mad / smpeg
mp1
mp1float
mp2
mp2float
mp3
mp3float

# Ogg/Vorbis audio format -- replacing Vorbis
vorbis

# MPEG-1 video format -- replacing smpeg
mpeg1video

# Ogg/Theora and WebM video format -- new support
theora
vp8

PARSERS:
# these might be needed for MPEG support
mpegaudio
mpegvideo

DEMUXERS:
aiff
mp3
mpegps
mpegts
mpegtsraw
mpegvideo
ogg
wav

ENCODERS:
libvpx
libvorbis

MUXERS:
webm
