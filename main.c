#include <stdio.h>
#include <string.h>
#include <stdlib.h>

char shellName[] = "shell.exe";
int length = 0;

unsigned char* LoadFile(char* filename) {
	FILE *fp;
	long size;
	unsigned char* buf;
	size_t result;

	if ((fp = fopen(filename, "rb")) == NULL)
		return NULL;
	fseek(fp, 0, SEEK_END);
	size = ftell(fp);
	rewind(fp);

	buf = (unsigned char*)calloc(size, sizeof(char));

	result = fread(buf, 1, size, fp);
	if (result != size)
		return NULL;

	length = result;
	fclose(fp);

	return buf;
}

int outputFile(unsigned char* file, int length, char* fileName) {
	FILE* fp;
	int size;
	if ((fp = fopen(fileName, "wb")) == NULL)
		return 0;

	size = fwrite(file, sizeof(char), length, fp);
	if (size != length)
		return 0;

	fclose(fp);
	return 1;
}

unsigned char* myMemcat(unsigned char* buf1, int length1, unsigned char* buf2, int length2) {
	unsigned char* buf;

	buf = (unsigned char*)calloc(length1 + length2, sizeof(char));

	memcpy(buf, buf1, length1);
	memcpy(buf + length1, buf2, length2);

	return buf;
}

void modifyFile(unsigned char* file, int fileLength, int headLength, int shellLength) {
	int i = headLength;
	int l, s, ip;
	for (; i < fileLength; i++)
		file[i] ^= 0x44;
	//除了文件头外的全部内容进行加密(使用逐字节xor 44h)

	file[6] = file[7] = 0;
	//修改重定位项=0

	l = (unsigned int)file[2] + (((unsigned int)file[3]) << 8);
	s = (unsigned int)file[4] + (((unsigned int)file[5]) << 8);
	l += shellLength;
	while (l > 0x200) {
		l -= 0x200;
		s++;
	}
	if (l == 0x200) {
		l = 0;
	}
	file[2] = l & 0xff;
	file[3] = (l >> 8) & 0xff;
	file[4] = s & 0xff;
	file[5] = (s >> 8) & 0xff;
	//修改载入内存长度

	ip = fileLength - headLength;
	file[0x14] = ip & 0xff;
	file[0x15] = (ip >> 8) & 0xff;
	file[0x16] = 0;
	file[0x17] = ((ip >> 16) & 0xff) << 4;
	//修改Δcs:ip
}

int main(int argc, char** argv) {
	unsigned char *file, *shell, *newshell;
	int fileLength, shellLength, headLength;

	shell = LoadFile(shellName);
	if (shell == NULL) {
		printf("error in loading shell.exe\n");
	}	
	shellLength = length;
	//载入shell

	headLength = ((unsigned int)shell[8] + (((unsigned int)shell[9]) << 8)) * 0x10;
	memcpy(shell, shell + headLength, shellLength - headLength);
	shellLength = shellLength - headLength;
	//获取shell.exe文件头后面的内容并将shellLength置为文件头后面内容的长度

	file = LoadFile(argv[1]);
	if (file == NULL) {
		printf("error in loading %s\n", argv[1]);
	}
	fileLength = length;

	headLength = ((unsigned int)file[8] + (((unsigned int)file[9]) << 8)) * 0x10;

	newshell = myMemcat(shell, shellLength, file, headLength);
	shellLength = shellLength + headLength;
	//新的shell的长度
	file = myMemcat(file, fileLength, newshell, shellLength);

	modifyFile(file, fileLength, headLength, shellLength);

	if (outputFile(file, fileLength + shellLength, argv[2]) == 0)
		printf("Error in output %s\n", argv[2]);

	return 0;
}