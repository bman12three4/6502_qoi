char* qoi = (char*)0x9000;
char* img = (char*)0x8000;

int main(void)
{
	int a;
	for (a = 0; a < 4096; a++) {
		qoi[a] = img[a];
	}

	return 0;
}
