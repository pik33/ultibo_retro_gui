// kjmp2 example player application for Linux/OSS
// this file is public domain -- do with it whatever you want!

#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <linux/soundcard.h>

#include "kjmp2.h"


size_t strlen(const char *s);
#define out(text) dummy = write(1, (const void *) text, strlen(text))


int main(int argc, char *argv[]) {
    kjmp2_context_t mp2;
    int fd, pcm;
    const void *file_data;
    const unsigned char *stream_pos;
    signed short sample_buf[KJMP2_SAMPLES_PER_FRAME * 2];
    int bytes_left;
    int sample_rate;
    int value;
    int dummy;

    out("mp2play -- a small MPEG-1 Audio Layer II player based on kjmp2\n\n");
    if (argc < 2) {
        out("Error: no input file specified!\n");
        return 1;
    }

    fd = open(argv[1], O_RDONLY);
    if (fd < 0) {
        out("Error: cannot open `");
        out(argv[1]);
        out("'!\n");
        return 1;
    }
    
    bytes_left = lseek(fd, 0, SEEK_END);    
    file_data = mmap(0, bytes_left, PROT_READ, MAP_PRIVATE, fd, 0);
    stream_pos = (unsigned char *) file_data;
    bytes_left -= 100;
    out("Now Playing: ");
    out(argv[1]);

    kjmp2_init(&mp2);
    sample_rate = kjmp2_get_sample_rate(stream_pos);
    if (!sample_rate) {
        out("\nError: not a valid MP2 audio file!\n");
        return 1;
    }

    #define FAIL(msg) { \
        out("\nError: " msg "\n"); \
        return 1; \
    }   

    pcm = open("/dev/dsp", O_WRONLY);
    if (pcm < 0) FAIL("cannot set audio format");

    value = AFMT_S16_LE;
    if (ioctl(pcm, SNDCTL_DSP_SETFMT, &value) < 0)
        FAIL("cannot set audio format");

    value = 2;
    if (ioctl(pcm, SNDCTL_DSP_CHANNELS, &value) < 0)
        FAIL("cannot set audio channels");

    if (ioctl(pcm, SNDCTL_DSP_SPEED, &sample_rate) < 0)
        FAIL("cannot set audio sample rate");

    out("\n\nPress Ctrl+C to stop playback.\n");

    while (bytes_left >= 0) {
        value = kjmp2_decode_frame(&mp2, stream_pos, sample_buf);
        if (!value) break;
        stream_pos += value;
        bytes_left -= value;
        dummy = write(pcm, (const void *) sample_buf, KJMP2_SAMPLES_PER_FRAME * 4);
    }

    close(pcm);
    return 0;
}
