
all: build

build:
	docker build -f Dockerfile -t dymos-test .

