#include <iostream>
#include <fstream>
#include <cstring>
#include <cstdlib>


// 内核代码位于镜像的第 SYS_SECTOR_BEG 个扇区
#define SYS_SECTOR_BEG 6
#define IMG_SECTOR_NUM 20160

using namespace std;

int header_len = 0;

int copyFile(ofstream &out, const char *filename){

	ifstream in(filename,  ios::binary);

	char buf[256] = {0};

	int count = 0;

	int num = 256;

	if ( strcmp("tools/system", filename) == 0)
	{
		// in.read(buf, 0x1000);  //get rid of the elf file header
		in.seekg(header_len, ios::beg);
		cout<<"get rid of the elf file header"<<endl;
	}

	while(num == 256) {
 		in.read(buf, 256);
 		num = in.gcount();
 		count += num;
 		out.write(buf, num);
 		// cout<<num<<endl;
 	}
	in.close();
	return count;
}

/*

	argv[1]: img elf header len

*/


int main(int argc, char const *argv[])
{
	ofstream out("a.img",  ios::binary);
	

	int count = 0;

	header_len = strtol(argv[1], NULL, 16);



	cout<<"header_len : "<< header_len <<endl;

	// cout<<"ddddddd"<<endl;

	count += copyFile(out, "boot/bootSect");
	count += copyFile(out, "boot/setup");

	int diff = 512 * (SYS_SECTOR_BEG - 1) - count;

	// cout<<"aaaaaaa"<<endl;

	char *zero = new char[512 * IMG_SECTOR_NUM];
	bzero(zero, sizeof(zero));

	out.write(zero, diff);

	count += diff;


	// count += copyFile(out, "tools/system");

	out.write(zero, 512 * IMG_SECTOR_NUM - count);

	// cout<<"djfdsfj"<<endl;	
	delete [] zero;

	out.close();
	return 0;
}
