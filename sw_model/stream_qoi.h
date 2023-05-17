#ifndef _STREAM_QOI_H
#define _STREAM_QOI_H

#include "qoi.h"

void *s_qoi_encode(const void *data, const qoi_desc *desc, int *out_len);

int s_qoi_write(const char *filename, const void *data, const qoi_desc *desc);

void *s_qoi_decode(const void* data, int size, qoi_desc *desc, int channels);

void *s_qoi_read(const char *filename, qoi_desc *desc, int channels);
#endif
