#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "qoi.h"

#define IMG_ADDR 0x8000
#define QOI_ADDR 0x9000

static const unsigned char qoi_padding[8] = {0,0,0,0,0,0,0,1};

static qoi_rgba_t index[64];

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

static int run;
static qoi_rgba_t px, px_prev;
static int px_end;


void s_qoi_encode_px(qoi_rgba_t px, int px_pos, uint8_t* px_enc, uint8_t* px_enc_len)
{
	uint8_t p = 0;

	if (px.v == px_prev.v) {
		run++;
		if (run == 62 || px_pos == px_end) {
			px_enc[p++] = QOI_OP_RUN | (run - 1);
			run = 0;
		}
	}
	else {
		int index_pos;

		if (run > 0) {
			px_enc[p++] = QOI_OP_RUN | (run - 1);
			run = 0;
		}

		index_pos = QOI_COLOR_HASH(px) % 64;

		if (index[index_pos].v == px.v) {
			px_enc[p++] = QOI_OP_INDEX | index_pos;
		}
		else {
			index[index_pos] = px;

			if (px.rgba.a == px_prev.rgba.a) {
				signed char vr = px.rgba.r - px_prev.rgba.r;
				signed char vg = px.rgba.g - px_prev.rgba.g;
				signed char vb = px.rgba.b - px_prev.rgba.b;

				signed char vg_r = vr - vg;
				signed char vg_b = vb - vg;

				if (
					vr > -3 && vr < 2 &&
					vg > -3 && vg < 2 &&
					vb > -3 && vb < 2
				) {
					px_enc[p++] = QOI_OP_DIFF | (vr + 2) << 4 | (vg + 2) << 2 | (vb + 2);
				}
				else if (
					vg_r >  -9 && vg_r <  8 &&
					vg   > -33 && vg   < 32 &&
					vg_b >  -9 && vg_b <  8
				) {
					px_enc[p++] = QOI_OP_LUMA     | (vg   + 32);
					px_enc[p++] = (vg_r + 8) << 4 | (vg_b +  8);
				}
				else {
					px_enc[p++] = QOI_OP_RGB;
					px_enc[p++] = px.rgba.r;
					px_enc[p++] = px.rgba.g;
					px_enc[p++] = px.rgba.b;
				}
			}
			else {
				px_enc[p++] = QOI_OP_RGBA;
				px_enc[p++] = px.rgba.r;
				px_enc[p++] = px.rgba.g;
				px_enc[p++] = px.rgba.b;
				px_enc[p++] = px.rgba.a;
			}
		}
	}
	px_prev = px;
	*px_enc_len = p;
}

void *s_qoi_encode(const void *data, const qoi_desc *desc, int *out_len)
{

	uint32_t i, max_size, p;
	int px_len, px_pos, channels;
	unsigned char* bytes;
	const unsigned char *pixels;

	uint8_t px_enc[6];
	uint8_t px_enc_len;

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
	// bytes = (unsigned char*) malloc(max_size);
	// if (!bytes) {
	// 	printf("Failed malloc\n");
	// 	return 0;
	// }
	bytes = (unsigned char*) QOI_ADDR;

	qoi_write_32(bytes, &p, QOI_MAGIC);
	qoi_write_32(bytes, &p, desc->width);
	qoi_write_32(bytes, &p, desc->height);
	bytes[p++] = desc->channels;
	bytes[p++] = desc->colorspace;

	pixels = (const uint8_t *)data;

	QOI_ZEROARR(index);

	run = 0;
	px_prev.rgba.r = 0;
	px_prev.rgba.g = 0;
	px_prev.rgba.b = 0;
	px_prev.rgba.a = 255;
	px = px_prev;

	px_len = desc->width * desc->height * desc->channels;
	px_end = px_len - desc->channels;
	channels = desc->channels;

	for (px_pos = 0; px_pos < px_len; px_pos += channels) {
		px.rgba.r = pixels[px_pos + 0];
		px.rgba.g = pixels[px_pos + 1];
		px.rgba.b = pixels[px_pos + 2];

		if (channels == 4) {
			px.rgba.a = pixels[px_pos + 3];
		}

		s_qoi_encode_px(px, px_pos, px_enc, &px_enc_len);

		for (i = 0; i < px_enc_len; i++) {
			bytes[p++] = px_enc[i];
		}
	}

	for (i = 0; i < (int)sizeof(qoi_padding); i++) {
		bytes[p++] = qoi_padding[i];
	}

	*out_len = p;
	return bytes;

}

uint8_t state;
uint8_t op_read, op_write, count;

uint8_t b[4];
uint8_t bufw[4];
uint8_t buf_idx;

uint8_t vg;

enum state {DS_FETCH_OP, DS_DECODE_OP, DS_RGB, DS_RGBA, DS_IDX, DS_DIFF, DS_LUMA, DS_RUN, DS_WRITE_PX};

void s_qoi_decode_op()
{
	switch (state) {
	case DS_FETCH_OP:
		if (run > 0) {
			run--;
			state = DS_WRITE_PX;
		}
		else {
			state = DS_DECODE_OP;
			count = 1;
			op_read = 1;
		}
		break;
	case DS_DECODE_OP:
		if (b[0] == QOI_OP_RGB) {
			state = DS_RGB;
			count = 3;
			op_read = 1;
		}
		else if (b[0] == QOI_OP_RGBA) {
			state = DS_RGBA;
			count = 4;
			op_read = 1;
		}
		else if ((b[0] & QOI_MASK_2) == QOI_OP_INDEX) {
			state = DS_IDX;
		}
		else if ((b[0] & QOI_MASK_2) == QOI_OP_DIFF) {
			state = DS_DIFF;

		}
		else if ((b[0] & QOI_MASK_2) == QOI_OP_LUMA) {
			vg = (b[0] & 0x3f) - 32;
			state = DS_LUMA;
			count = 1;
			op_read = 1;
		}
		else if ((b[0] & QOI_MASK_2) == QOI_OP_RUN) {
			state = DS_RUN;
		}
		break;
	case DS_RGB:
		state = DS_WRITE_PX;
		px.rgba.r = b[0];
		px.rgba.g = b[1];
		px.rgba.b = b[2];
		px.rgba.a = px_prev.rgba.a;
		break;
	case DS_RGBA:
		state = DS_WRITE_PX;
		px.rgba.r = b[0];
		px.rgba.g = b[1];
		px.rgba.b = b[2];
		px.rgba.a = b[3];
		break;
	case DS_IDX:
		state = DS_WRITE_PX;
		px = index[b[0]];
		break;
	case DS_DIFF:
		state = DS_WRITE_PX;
		px.rgba.r += ((b[0] >> 4) & 0x03) - 2;
		px.rgba.g += ((b[0] >> 2) & 0x03) - 2;
		px.rgba.b += ( b[0]       & 0x03) - 2;
		break;
	case DS_LUMA:
		state = DS_WRITE_PX;
		px.rgba.r += vg - 8 + ((b[0] >> 4) & 0x0f);
		px.rgba.g += vg;
		px.rgba.b += vg - 8 +  (b[0]       & 0x0f);
		break;
	case DS_RUN:
		state = DS_WRITE_PX;
		run = (b[0] & 0x3f);
		break;
	case DS_WRITE_PX:
		state = DS_FETCH_OP;
		bufw[0] = px.rgba.r;
		bufw[1] = px.rgba.g;
		bufw[2] = px.rgba.b;
		bufw[3] = px.rgba.a;
		px_prev = px;
		index[QOI_COLOR_HASH(px) % 64] = px;
		op_write = 1;
		count = 4;
		break;
	}
}

void s_qoi_send_byte(uint8_t b_in)
{
	b[buf_idx++] = b_in;
	if (buf_idx == count) {
		op_read = 0;
		buf_idx = 0;
		count = 0;
	}
}

uint8_t s_qoi_read_byte()
{
	uint8_t b1;

	b1 = bufw[buf_idx++];
	if (buf_idx == count) {
		op_write = 0;
		buf_idx = 0;
		count = 0;
	}
	return b1;
}

// Write works a little differently to read. It works more like verilog would
void *s_qoi_decode(const void* data, int size, qoi_desc *desc, int channels) {
	const unsigned char *bytes;
	uint32_t header_magic;
	unsigned char *pixels;
	qoi_rgba_t px;
	int px_len, px_pos;
	uint32_t p = 0, run = 0;

	if (
		data == NULL || desc == NULL ||
		(channels != 0 && channels != 3 && channels != 4) ||
		size < QOI_HEADER_SIZE + (int)sizeof(qoi_padding)
	) {
		return NULL;
	}

	bytes = (const unsigned char *)data;

	header_magic = qoi_read_32(bytes, &p);
	desc->width = qoi_read_32(bytes, &p);
	desc->height = qoi_read_32(bytes, &p);
	desc->channels = bytes[p++];
	desc->colorspace = bytes[p++];

	if (
		desc->width == 0 || desc->height == 0 ||
		desc->channels < 3 || desc->channels > 4 ||
		desc->colorspace > 1 ||
		header_magic != QOI_MAGIC ||
		desc->height >= QOI_PIXELS_MAX / desc->width
	) {
		return NULL;
	}

	if (channels == 0) {
		channels = desc->channels;
	}

	px_len = desc->width * desc->height * channels;
	//pixels = (unsigned char *) malloc(px_len);
	// if (!pixels) {
	// 	return NULL;
	// }
	pixels = (unsigned char *) IMG_ADDR;

	QOI_ZEROARR(index);
	px.rgba.r = 0;
	px.rgba.g = 0;
	px.rgba.b = 0;
	px.rgba.a = 255;

	//chunks_len = size - (int)sizeof(qoi_padding);
	px_pos = 0;

	while (px_pos < px_len) {
		s_qoi_decode_op();

		while (op_read) {
			s_qoi_send_byte(bytes[p++]);
		}

		while (op_write) {
			pixels[px_pos++] = s_qoi_read_byte();
		}
	}

	return pixels;
}
