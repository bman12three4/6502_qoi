#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "qoi.h"
#include "stream_qoi.h"

#define STR_ENDS_WITH(S, E) (strcmp(S + strlen(S) - (sizeof(E)-1), E) == 0)

int main(int argc, char **argv) {
	void *pixels = NULL;
	int w, h;
	int size;
	uint8_t channels;

	uint8_t encoded;

	FILE *f;
	qoi_desc desc;

	//printf("argc: %d\n, argc");

	if (argc < 3) {
		puts("Usage: qoiconv <infile> <outfile>");
		puts("Examples:");
		puts("  qoiconv input.png output.qoi");
		puts("  qoiconv input.qoi output.png");
		exit(1);
	}

	if (STR_ENDS_WITH(argv[1], ".data")) {
		printf("Opening a data file\n");
		f = fopen(argv[1], "rb");
		w = 32;
		h = 32;
		channels = 4;
		size = w * h * channels;
		pixels = malloc(size);
		fread(pixels, 1, size, f);
		fclose(f);
	}
	else if (STR_ENDS_WITH(argv[1], ".qoi")) {
		printf("Opening a QOI file\n");
		pixels = qoi_read(argv[1], &desc, 0);
		channels = desc.channels;
		w = desc.width;
		h = desc.height;
	}

	if (pixels == NULL) {
		printf("Couldn't load/decode %s\n", argv[1]);
		exit(1);
	}

	if (STR_ENDS_WITH(argv[2], ".data")) {
		printf("Writing a data file\n");
		f = fopen(argv[2], "wb");
		size = w * h * channels;
		fwrite(pixels, 1, size, f);
		printf("size: %d\n", size);
		fclose(f);
	}
	else if (STR_ENDS_WITH(argv[2], ".qoi")) {
		printf("Writing a QOI file\n");
		desc.width = w;
		desc.height = h;
		desc.channels = channels;
		desc.colorspace = QOI_SRGB;
		encoded = s_qoi_write(argv[2], pixels, &desc);
	}

	if (!encoded) {
		printf("Couldn't write/encode %s\n", argv[2]);
		exit(1);
	}

	free(pixels);
	return 0;
}
