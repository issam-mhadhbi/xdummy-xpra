# xdummy-xpra
Docker image with virtual display based on xdummy and remote display using xpra (port = 14500), and code-server (port = 8000)

## Build and run  : 
```bash
git clone https://github.com/MhadhbiXissam/xdummy-xpra.git
cd xdummy-xpra
make
```
* for xpra open browser on [http://localhost:14500](http://localhost:14500)
* for code-server open browser on [http://localhost:8000/](http://localhost:8000)

## pull image and run already build : 
```bash
docker run -it --rm -p 14500:14500 -p 8000:8000 --name ubuntu_xdummy_xpra mhadhbixissam/ubuntu:xdummy.xpra   
```

## Build on top on this image  : 
```dockerfile
from mhadhbixissam/ubuntu:xdummy.xpra 

run apt update 
#overide or modify xstartuyp here 
run <<EOF
echo -n '#!/bin/bash
set -euo pipefail
tilix --working-directory=/root/Desktop --maximize & 
code-server --bind-addr 0.0.0.0:8000  --auth none /root/Desktop 
#### put your app here 
' > /root/xstartup.sh && chmod +x /root/xstartup.sh
EOF

```
