#include <stdio.h>
#include <stdlib.h>

#include "qoi.h"

int main(void)
{
	int retval;
	int len;

	int width, height;

	FILE* f;
	FILE* f1;

	void* data;
	int size;


	qoi_desc desc;

	width = 32;
	height = 32;

	f = fopen("pixels.data", "rb");

	size = width * height * 4;

	data = malloc(size);
	if (!data) {
		fclose(f);
		return -1;
	}

	fread(data, 1, size, f);
	fclose(f);
	
	printf("Testing qoi_encode...\n");

	desc.width = 32;
	desc.height = 32;
	desc.channels = 4;
	desc.colorspace = QOI_SRGB;

	retval = qoi_encode(data, &desc, &len);

	if (!retval) {
		printf("Error! %d\n", retval);
		return -1;
	} else {
		printf("Return size: %d\n", len);
	}

	f1 = fopen("pixels.qoi", "wb");
	fwrite(retval, 1, len, f1);
	fclose(f1);
	free(data);

	return 0;
};

