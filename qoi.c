#include <stdlib.h>

#include "qoi.h"

static const unsigned char qoi_padding[8] = {0,0,0,0,0,0,0,1};

static qoi_rgba_t index[64];

void *qoi_encode(const void *data, const qoi_desc *desc, int *out_len)
{
	int i, max_size, p, run;
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

	*out_len = p;
	return bytes;
}
