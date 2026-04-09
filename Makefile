

all : build run

build : 
	@echo "Building docker image : ubuntu:xdummy.xpra..."
	docker build -t ubuntu:xdummy.xpra .

run  : 
	@echo "Running docker image : ubuntu:xdummy.xpra..."
	docker run -it --rm -p 14500:14500 -p 8000:8000 --name ubuntu_xdummy_xpra ubuntu:xdummy.xpra
	