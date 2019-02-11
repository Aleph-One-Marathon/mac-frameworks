For the most part, the `build.sh` scripts speak for themselves. When adding a framework, jpeg is a good standard script to start from.

If frameworks depend on one another, care is needed to get the links right. See the ffmpeg build file for examples. Use `otool -L` to check your work.

If multiple frameworks are produced by one package, it can also be tricky to get the headers correct. See ffmpeg and png for ways to handle unusual cases.

If frameworks have internal dependencies, the simplest route may be to statically link the dependencies. Currently, ogg, vorbis, and vpx are built statically and linked into ffmpeg.
