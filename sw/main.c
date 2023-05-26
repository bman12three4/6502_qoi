#include "qoi.h"
#include "stream_qoi.h"

#define QOI_START  ((char)(1 << 7))
#define QOI_ENCODE ((char)(0 << 7))

#define QOI_READ_FLAG ((char)(1 << 0))
#define QOI_WRITE_FLAG ((char)(1 << 1))

char* qoi = (char*)0x9000;
char* img = (char*)0x8000;
char* accel = (char*)0xa000;

qoi_desc desc;

uint8_t status;

int main(void)
{
	uint32_t size;
	int p;
	char i;

	size = 4096L;
	p = 0;

	desc.width = 32;
	desc.height = 32;
	desc.channels = 4;
	desc.colorspace = QOI_SRGB;

	for (i = 0; i < 4; i++) {
		accel[i+4] = size >> i*8;
	}

	accel[3] = QOI_START | QOI_ENCODE;

	while(!(accel[3] | ~QOI_READ_FLAG));
	
	for (i = 0; i < 4; i++) {
		accel[0] = img[i]; //img order is a b g r
	}

	for (;;) {
		status = accel[3];
		if (status & QOI_READ_FLAG) {
			break;
		} else if (status & QOI_WRITE_FLAG) {
			qoi[p++] = accel[0];
		}
	}

	return 0;
}
