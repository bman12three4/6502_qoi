#include "qoi.h"
#include "stream_qoi.h"

#include <string.h>

#define QOI_START  ((char)(1 << 7))
#define QOI_ENCODE ((char)(0 << 6))
#define QOI_DECODE ((char)(1 << 6))

#define QOI_READ_FLAG ((char)(1 << 0))
#define QOI_WRITE_FLAG ((char)(1 << 1))
#define QOI_FINAL_FLAG ((char)(1 << 6))

unsigned char* qoi = (unsigned char*)0x9000;
unsigned char* img = (unsigned char*)0x8000;
unsigned char* accel = (unsigned char*)0xa000;

unsigned char* accel_ctrl = (unsigned char*)0xa400;

static const unsigned char qoi_padding[8] = {0,0,0,0,0,0,0,1};

qoi_desc desc;

uint8_t status;

static void qoi_write_32(unsigned char *bytes, uint32_t *p, uint32_t v)
{
	bytes[(*p)++] = (0xff000000 & v) >> 24;
	bytes[(*p)++] = (0x00ff0000 & v) >> 16;
	bytes[(*p)++] = (0x0000ff00 & v) >> 8;
	bytes[(*p)++] = (0x000000ff & v);
}

static uint32_t qoi_read_32(const unsigned char *bytes, uint32_t *p) {
	uint32_t a = bytes[(*p)++];
	uint32_t b = bytes[(*p)++];
	uint32_t c = bytes[(*p)++];
	uint32_t d = bytes[(*p)++];
	return a << 24 | b << 16 | c << 8 | d;
}

int main(void)
{
	uint32_t size;
	uint32_t s, d;
	uint16_t remain;
	uint32_t header_magic;
	char i;

	d = 0;
	s = 0;

	desc.width = 32;
	desc.height = 32;
	desc.channels = 4;
	desc.colorspace = QOI_SRGB;

	size = desc.width * desc.height;

	header_magic = qoi_read_32(qoi, &d);
	desc.width = qoi_read_32(qoi, &d);
	desc.height = qoi_read_32(qoi, &d);
	desc.channels = qoi[d++];
	desc.colorspace = qoi[d++];

	for (i = 0; i < 4; i++) {
		accel_ctrl[i+4] = size >> i*8;
	}

	accel_ctrl[3] = QOI_START | QOI_DECODE;

	// Need some checking for final read/write (i.e. not n*1024)

	while(!((status = accel_ctrl[3]) & QOI_FINAL_FLAG)) {
		if (status & QOI_READ_FLAG) {
			memcpy(accel, qoi+s, 1024);
			s += 1024;
		} else if (status & QOI_WRITE_FLAG) {
			memcpy(img+d, accel, 1024);
			d += 1024;
		}
	}

	while(!(accel_ctrl[3] & QOI_FINAL_FLAG));
	remain = accel_ctrl[1];
	remain += accel_ctrl[2] << 8;
	memcpy(img+d, accel, remain+1);

	return 0;
}
