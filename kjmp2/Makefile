# note: this Makefile builds the Linux version only

CFLAGS = -Wall -Wextra -Os -march=native
CFLAGS += -ffast-math
CFLAGS += -finline-functions-called-once
CFLAGS += -fno-loop-optimize
CFLAGS += -fexpensive-optimizations
CFLAGS += -fpeephole2

STRIPFLAGS  = -R .comment
STRIPFLAGS += -R .note
STRIPFLAGS += -R .note.ABI-tag
STRIPFLAGS += -R .gnu.version

all: mp2play mp2dec

release: mp2play
	strip $(STRIPFLAGS) mp2play
	upx --ultra-brute mp2play

test: mp2play
	./mp2play example.mp2

mp2play: mp2play_oss.o kjmp2.o
	gcc $^ -o $@

mp2dec: mp2dec.o kjmp2.o
	gcc $^ -o $@

%.o: %.c
	gcc $(CFLAGS) -c $< -o $@

example_24k.wav: example.wav
	sox $< -r 24k $@
example_24k.mp2: example_24k.wav
	twolame -b 96 $< $@
example.mp2: example.wav
	twolame -b 160 $< $@

example_dec.wav: example.mp2 mp2dec
	./mp2dec $< $@
example_ref.wav: example.mp2
	ffmpeg -y -i $< $@

example_24k_dec.wav: example_24k.mp2 mp2dec
	./mp2dec $< $@
example_24k_ref.wav: example_24k.mp2
	ffmpeg -y -i $< $@

streams: example_ref.wav example_dec.wav example_24k_ref.wav example_24k_dec.wav compare.py
	python compare.py example_ref.wav example_dec.wav
	python compare.py example_24k_ref.wav example_24k_dec.wav

clean:
	rm -f mp2dec mp2play mp2play*.o kjmp2.o mp2dec.o *_dec.wav *_ref.wav
distclean: clean
	rm -f *.mp2 example_24k.wav

.PHONY:
	all release test streams clean distclean
