#!/bin/bash
cd /tools/vm/looking-glass/client/build
SDL_VIDEO_X11_VISUALID=0x022 xinit /usr/bin/bash -c "xrandr --output eDP-1 --mode 1920x1080 && /tools/vm/looking-glass/client/build/looking-glass-client -m 73 -a -s -T -S win:quickSplash=yes win:position=0x0 egl:vsync=yes egl:multisample=no opengl:vsync=yes" $* -- :1 vt3 -config xorg.conf.d/z_alt.altconfig
