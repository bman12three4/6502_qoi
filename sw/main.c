#include "qoi.h"
#include "stream_qoi.h"

char* qoi = (char*)0x9000;
char* img = (char*)0x8000;
char* accel = (char*)0xa000;

qoi_desc desc;

int main(void)
{
	int size;
	desc.width = 32;
	desc.height = 32;
	desc.channels = 4;
	desc.colorspace = QOI_SRGB;
	//s_qoi_encode(img, &desc, &size);
	accel[1] = 1;
	return 0;
}
