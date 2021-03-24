#!/bin/bash
cd /tools/vm/looking-glass/client/build
SDL_VIDEO_X11_VISUALID=0x022 xinit /tools/vm/looking-glass/client/build/looking-glass-client -k -m 73 -a -s -S $* -- :1 vt3
