#ifndef QOI_H
#define QOI_H

#include <stdint.h>

#define QOI_SRGB	0
#define QOI_LINEAR	1

typedef struct {
	uint32_t width;
	uint32_t height;
	uint8_t channels;
	uint8_t colorspace;
} qoi_desc;

#define QOI_OP_RGB	0xfe
#define QOI_OP_RGBA	0xff
#define QOI_OP_INDEX	0x00
#define QOI_OP_DIFF	0x40
#define QOI_OP_LUMA	0x80
#define QOI_OP_RUN	0xc0

#define QOI_MASK_2	0xc0

#define QOI_COLOR_HASH(C) (C.rgba.r*3 + C.rgba.g*5 + C.rgba.b*7 + C.rgba.a*11)
#define QOI_MAGIC \
	(((uint32_t)'q') << 24 | ((uint32_t)'o') << 16 | \
	 ((uint32_t)'i') <<  8 | ((uint32_t)'f'))
#define QOI_HEADER_SIZE 14

typedef union {
	struct { uint8_t r, g, b, a; } rgba;
	uint32_t v;
} qoi_rgba_t;

#define QOI_PIXELS_MAX ((uint32_t)32768UL)

#ifndef QOI_ZEROARR
	#define QOI_ZEROARR(a) memset((a),0,sizeof(a))
#endif

void *qoi_encode(const void *data, const qoi_desc *desc, int *out_len);

void *qoi_decode(const void *data, int size, qoi_desc *desc, int channels);

int qoi_write(const char *filename, const void *data, const qoi_desc *desc);

void *qoi_read(const char *filename, qoi_desc *desc, int channels);
#endif
