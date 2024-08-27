#!/bin/bash

if [[ ! -d "bin" ]]; then 
	echo "creating bin directory"
	mkdir bin
fi

TARGET=bin/snake
if [[ $1 = "release" ]] ; then
	command="odin build src -out:$TARGET -collection:src=src -vet -strict-style -o:speed -no-bounds-check -show-timings"
else
	command="odin build src -out:$TARGET -collection:src=src -vet -strict-style -o:none -show-timings -debug"
fi

echo $command
$command

