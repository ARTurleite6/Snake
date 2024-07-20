all: build

TARGET = bin/snake

release:
	odin build src -out:$(TARGET) -collection:src=src -vet -strict-style -o:speed -no-bounds-check -show-timings

build:
	odin build src -out:$(TARGET) -collection:src=src -vet -strict-style -show-timings

run: 
	bin/snake
