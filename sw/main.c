#include "qoi.h"

char* qoi = (char*)0x9000;
char* img = (char*)0x8000;

qoi_desc desc;

int main(void)
{
	int size;
	desc.width = 32;
	desc.height = 32;
	desc.channels = 4;
	desc.colorspace = QOI_SRGB;
	qoi_encode(img, &desc, &size);
	return 0;
}
