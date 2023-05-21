#include "qoi.h"
#include "stream_qoi.h"

#define QOI_START  ((char)(1 << 7))
#define QOI_ENCODE ((char)(0 << 7))

#define QOI_READ_FLAG ((char)(1 << 7))
#define QOI_WRITE_FLAG ((char)(1 << 6))

char* qoi = (char*)0x9000;
char* img = (char*)0x8000;
char* accel = (char*)0xa000;

qoi_desc desc;

int main(void)
{
	uint32_t size;
	char i;

	size = 4096L;

	desc.width = 32;
	desc.height = 32;
	desc.channels = 4;
	desc.colorspace = QOI_SRGB;

	for (i = 0; i < 3; i++) {
		accel[i+4] = size >> i*8;
	}

	accel[7] = size >> 24 | QOI_START;

	while(!(accel[7] | ~QOI_READ_FLAG));
	
	for (i = 0; i < 4; i++) {
		accel[i] = img[3-i]; //img order is a b g r
	}

	return 0;
}
