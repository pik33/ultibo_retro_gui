#!/usr/bin/env python
"""simple helper that compares two .wav files with 16-bit PCM data of the same
length and prints the PSNR; must be run on a little-endian CPU architecture!"""
import sys, array, itertools, math

if __name__ == "__main__":
    try:
        fa = open(sys.argv[1], "rb")
        fb = open(sys.argv[2], "rb")
    except IndexError:
        print "Usage:", sys.argv[0], "<file1.wav> <file2.wav>"
        sys.exit(2)
    except IOError, e:
        print e
        sys.exit(1)

    print "Computing PSNR between", sys.argv[1], "and", sys.argv[2], "..."
    fa.read(44)
    fb.read(44)

    eof = False
    n = 0
    s = 0L
    while not eof:
        da = array.array('h')
        try:
            da.fromfile(fa, 1024 * 1024)
        except EOFError:
            eof = True
        db = array.array('h')
        try:
            db.fromfile(fb, 1024 * 1024)
        except EOFError:
            eof = True
        s += sum([(a-b)*(a-b) for a, b in itertools.izip(da, db)])
        n += max(len(da), len(db))

    if not n:
        print "Files are empty."
    elif not s:
        print "Files are identical."
    else:
        psnr = 10.0 * math.log10(n * (65535.0 * 65535.0) / s)
        print "PSNR:", psnr, "dB"
