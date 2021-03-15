objects := $(patsubst src/%.puml,%.png,$(wildcard src/*.puml))
includes := $(wildcard src/includes/*.puml)

all: $(objects)

%.png: src/%.puml $(includes)
	plantuml -failfast2 -output $(dir $(abspath $@)) -filename $@ $<

clean:
	rm *.png
