#include <stdio.h>

#include "qoi.h"

int main(void)
{
	int retval;
	printf("Testing qoi_encode...\n");
	
	retval = qoi_encode();
	return retval;
};
