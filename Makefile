.PHONY: all test

all: test

test:
	love .

love: *.lua */*.lua font/*.ttf img/*.png snd/*
	zip the-other-side.love $^
