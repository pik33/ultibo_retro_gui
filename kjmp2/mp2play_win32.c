// kjmp2 example player application for Win32
// this file is public domain -- do with it whatever you want!

#include <windows.h>
#include "kjmp2.h"

#define BUFFER_COUNT 8

#ifdef NDEBUG
int _fltused=0;  // required by the math library to work properly
#endif


// define a working entry point function
#ifdef _DEBUG
    int EntryPoint(void);
    int main(void) {
        return EntryPoint();
    }
#else
    #define EntryPoint mainCRTStartup
#endif


static WAVEFORMATEX wf = {
    1,  // wFormatTag
    2,  // nChannels
    0,  // nSamplesPerSec
    0,  // nAvgBytesPerSec
    4,  // nBlockAlign
    16, // wBitsPerSample
    sizeof(WAVEFORMATEX) // cbSize
};

static const WAVEHDR wh_template = {
    NULL, // lpData
    KJMP2_SAMPLES_PER_FRAME * 4, // dwBufferLength
    0, // dwBytesRecorded
    0, // dwUser
    0, // dwFlags
    1, // dwLoops
    NULL, // lpNext
    0 // reserved
};


static kjmp2_context_t mp2;
static unsigned char *stream_pos;
static int bytes_left;
static WAVEHDR wh[BUFFER_COUNT];
static unsigned long sample_buffer[KJMP2_SAMPLES_PER_FRAME * BUFFER_COUNT];

static HANDLE stdout;
#define out(text) WriteFile(stdout, (LPCVOID) text, strlen(text), NULL, NULL)


void CALLBACK AudioCallback(
  HWAVEOUT hwo,      
  UINT uMsg,         
  DWORD_PTR dwInstance,  
  DWORD dwParam1,    
  DWORD dwParam2     
) {
    LPWAVEHDR wh = (LPWAVEHDR) dwParam1;
    int byte_count;
    if (!wh || (bytes_left < 0)) return;
    byte_count = kjmp2_decode_frame(&mp2, stream_pos, (signed short *) wh->lpData);
    if (!byte_count) return;
    stream_pos += byte_count;
    bytes_left -= byte_count;
    waveOutUnprepareHeader(hwo, wh, sizeof(WAVEHDR));
    waveOutPrepareHeader(hwo, wh, sizeof(WAVEHDR));
    waveOutWrite(hwo, wh, sizeof(WAVEHDR));
}

int EntryPoint(void) {
    char input_file_name[256];
    char *inptr, *outptr = input_file_name;
    HANDLE hFile, hMap;
    HWAVEOUT hwo;
    int i;
    
    // init stdout and write banner
    stdout = GetStdHandle(STD_OUTPUT_HANDLE);
    out("mp2play -- a <4k MPEG-1 Audio Layer II player based on kjmp2\n\n");
    
    // read arguments, but skip the program name
    for (inptr = GetCommandLine();  *inptr != ' ';  ++inptr) {
        if (*inptr == '"')  // skip "quoted arguments"
            do { ++inptr; } while (*inptr != '"');
    }
    // skip whitespace
    while (*inptr == ' ')  ++inptr;
    // check for a parameter
    if (!*inptr) {
        // no parameter -> quit
        out("Error: no input file specified!\n");
        return 1;
    } else if (*inptr == '"') {
        // "quoted parameter"
        ++inptr;
        while (*inptr != '"')
            *outptr++ = *inptr++;
    } else {
        // unquoted parameter
        do {
            *outptr++ = *inptr++;
        } while(*inptr);
    }
    *outptr = '\0';
    
    // open and mmap() the file
    hFile = CreateFile(input_file_name, GENERIC_READ, 0, NULL, OPEN_EXISTING, 0, NULL);
    bytes_left = GetFileSize(hFile, NULL) - 100;
    hMap = CreateFileMapping(hFile, NULL, PAGE_READONLY, 0, 0, NULL);
    stream_pos = (unsigned char*) MapViewOfFile(hMap, FILE_MAP_READ, 0, 0, 0);
    
    // check if the result is valid
    if (!stream_pos) {
        out("Error: cannot open `");
        out(input_file_name);
        out("'!\n");
        return 1;
    } else {
        out("Now Playing: ");
        out(input_file_name);
    }
    
    // set up kjmp2 and determine the sample rate
    kjmp2_init(&mp2);
    if (!(wf.nAvgBytesPerSec = (wf.nSamplesPerSec = kjmp2_get_sample_rate(stream_pos)) << 2)) {
        out("\nError: not a valid MP2 audio file!\n");
        return 1;
    }
    
    // set up wave output
    if(waveOutOpen(&hwo, WAVE_MAPPER, &wf, (INT_PTR) AudioCallback, (INT_PTR) NULL, CALLBACK_FUNCTION)
       != MMSYSERR_NOERROR) {
        out("\nError: cannot open wave output!\n");
        return 1;
    }

    // allocate buffers
    out("\n\nPress Ctrl+C or close the console window to stop playback.\n");
    inptr = (char*) sample_buffer;
    for (i = 0;  i < BUFFER_COUNT;  ++i) {
        wh[i] = wh_template;
        wh[i].lpData = inptr;
        AudioCallback(hwo, 0, 0, (DWORD) &wh[i], 0);
        inptr += KJMP2_SAMPLES_PER_FRAME * 4;
    }

    // endless loop
    while (1) Sleep(10);

    return 0;    
}
