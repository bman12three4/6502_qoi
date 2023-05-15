#include <stdlib.h>
#include <stdio.h>

#include "qoi.h"

static const unsigned char qoi_padding[8] = {0,0,0,0,0,0,0,1};

static qoi_rgba_t index[64];

static void qoi_write_32(unsigned char *bytes, uint32_t *p, uint32_t v)
{
	printf("v: %x\n", v);
	bytes[(*p)++] = (0xff000000 & v) >> 24;
	bytes[(*p)++] = (0x00ff0000 & v) >> 16;
	bytes[(*p)++] = (0x0000ff00 & v) >> 8;
	bytes[(*p)++] = (0x000000ff & v);
}

void *qoi_encode(const void *data, const qoi_desc *desc, int *out_len)
{
	uint32_t i, max_size, p, run;
	int px_len, px_end, px_pos, channels;
	unsigned char* bytes;
	const unsigned char *pixels;
	qoi_rgba_t px, px_prev;

	if (
		data == 0 || out_len == 0 || desc == 0 ||
		desc->width == 0 || desc->height == 0 ||
		desc->channels < 3 || desc-> channels > 4 ||
		desc->colorspace > 1 ||
		desc->height >= QOI_PIXELS_MAX / desc->width
	) {
		return 0;
	}

	max_size =
		desc->width * desc->height * (desc->channels + 1) +
		QOI_HEADER_SIZE + sizeof(qoi_padding);
	
	p = 0;
	bytes = (unsigned char*) malloc(max_size);
	if (!bytes) {
		return 0;
	}

	qoi_write_32(bytes, &p, QOI_MAGIC);
	qoi_write_32(bytes, &p, desc->width);
	qoi_write_32(bytes, &p, desc->height);

	*out_len = p;
	return bytes;
}
