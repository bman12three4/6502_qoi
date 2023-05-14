#include <stdio.h>

#include "qoi.h"

int main(void)
{
	int retval;
	int len;

	printf("Testing qoi_encode...\n");


	retval = qoi_encode(NULL, NULL, &len);

	if (!retval) {
		printf("Error!\n");
	}
};

