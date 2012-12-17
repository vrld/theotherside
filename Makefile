.PHONY: all test

all: test

test:
	love .

love: *.lua */*.lua font/*.ttf img/* snd/*
	zip the-other-side.love "$^"
