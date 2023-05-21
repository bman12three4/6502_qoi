#ifndef _STREAM_QOI_H
#define _STREAM_QOI_H

#include "qoi.h"

void *s_qoi_encode(const void *data, const qoi_desc *desc, int *out_len);

void *s_qoi_decode(const void* data, int size, qoi_desc *desc, int channels);

#endif
