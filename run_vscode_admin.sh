docker run -u 0 -ti --privileged \
-e DISPLAY \
-v /tmp/.X11-unix:/tmp/.X11-unix:rw \
-v $HOME/.Xauthority:/home/developer/.Xauthority:ro \
--device /dev/snd:/dev/snd:rw \
--device /dev/dri:/dev/dri:rw \
--device /dev/nvidia0:/dev/nvidia0:rw \
--device /dev/nvidiactl:/dev/nvidiactl:rw \
-v /run/user/$UID/pulse/native:/home/developer/pulse/socket:rw \
-v $HOME/Workspace:/home/developer/Workspace \
--net=host \
--pid=host \
--ipc=host \
vscode 
