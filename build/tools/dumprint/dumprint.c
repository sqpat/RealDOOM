#include <stdio.h>




#ifndef __FIXEDTYPES__
#define __FIXEDTYPES__
typedef signed char				int8_t;
typedef unsigned char			uint8_t;
typedef short					int16_t;
typedef unsigned short			uint16_t;
typedef long					int32_t;
typedef unsigned long			uint32_t;
typedef long long				int64_t;
typedef unsigned long long		uint64_t;
#endif

typedef uint16_t filelength_t;
typedef int32_t ticcount_t;
typedef uint16_t texsize_t;

typedef uint16_t segment_t;


#ifndef __BYTEBOOL__
#define __BYTEBOOL__
// Fixed to use builtin bool type with C++.
#ifdef __cplusplus
typedef bool boolean;
#else
typedef enum { false, true } boolean;
#endif
typedef uint8_t byte;
#endif


#define MAXCHAR		((int8_t)0x7f)
#define MAXSHORT	((int16_t)0x7fff)

// Max pos 32-bit int.
#define MAXLONG		((int32_t)0x7fffffffL)
#define MINCHAR		((int8_t)0x80)

// Max negative 32-bit integer.
#define MINLONG		((int32_t)0x80000000L)
#define MINSHORT	((int16_t)0x8000)


// let's avoid 'int' due to it being unclear between 16 and 32 bit
//#define MAXINT		((int32_t)0x7fffffff)	
//#define MININT		((int32_t)0x80000000)	





//#define UNION_FIXED_POINT

typedef int32_t fixed_t32;

/* Basically, there are a number of things (sector floor and ceiling heights mainly) that
 in practice never end up with greater than 1/8th FRACUNIT precision. That happens with
  certain kinds of moving floors and ceilings. aside from that, they never really end up greater
 than ~ 900 height in practice. realistically, 10 bits integer + 3 of precision is already more
 than we need, we are keeping it at 13 and 3 for minimal shifting. Even though its a bit ugly,
 it's way less shifting (remember bigger shifts means more cpu cycles on 16 bit x86 processors )
 and way denser memory storage on many structs. short_height_t exists as a reminder as to when
 these fields are shifted and not just a standard int_16_t


 */
typedef int16_t short_height_t;



#define SHORTFLOORBITS 3
#define SHORTFLOORBITMASK 0x0007
//#define SHORTFLOORBITS 4
//#define SHORTFLOORBITMASK 0x0F

//#define SET_FIXED_UNION_FROM_SHORT_HEIGHT(x, y) x.h.intbits = y >> SHORTFLOORBITS; x.h.fracbits = (y & SHORTFLOORBITMASK) << (8 - SHORTFLOORBITS)
#define SET_FIXED_UNION_FROM_SHORT_HEIGHT(x, y) x.h.intbits = y >> SHORTFLOORBITS; x.h.fracbits = (y & SHORTFLOORBITMASK) << (16 - SHORTFLOORBITS)

//#define SET_FIXED_UNION_FROM_SHORT_HEIGHT(x, y) x.h.intbits = y; x.h.fracbits = 0; x.w >>= SHORTFLOORBITS;

// old version bugged   6144
// old version bugfixed 6146

//new version 6187
 

typedef int32_t fixed_t;
typedef int16_t fixed_16_t;
#define FIXED_16_T_FRAC_BITS 4
#define	FRAC_16_UNIT		1 << (16 - FIXED_16_T_FRAC_BITS)

typedef union _longlong_union {
	int16_t h[4];

	struct productresult_t {
		int16_t throwawayhigh;
		int32_t usemid;
		int16_t throwawaylow;
	} productresult;


	struct productresult_small_t {
		int16_t throwawayhigh;
		int16_t usemid_high;
		int32_t usemid_low;
		int8_t throwawaylow;
	} productresult_small;

	int64_t l;
} longlong_union;

typedef union _fixed_t_union {
	uint32_t wu;
	int32_t w;

	struct dual_int16_t {
		int16_t fracbits;
		int16_t intbits;
	} h;

	struct dual_uuint16_t {
		uint16_t fracbits;
		uint16_t intbits;
	} hu;

	struct quad_int8_t {
		int8_t fracbytelow;
		int8_t fracbytehigh;
		int8_t intbytelow;
		int8_t intbytehigh;
	} b;

	struct quad_uint8_t {
		uint8_t fracbytelow;
		uint8_t fracbytehigh;
		uint8_t intbytelow;
		uint8_t intbytehigh;
	} bu;

	struct productresult_mid_t {
		int8_t throwawayhigh;		// errr these are reversed.
		int16_t usemid;
		int8_t throwawaylow;
	} productresult_mid;

} fixed_t_union;

 
 


typedef union _int16_t_union {
	uint16_t hu;
	int16_t h;

	struct dual_int8_t {
		int8_t bytelow;
		int8_t bytehigh;
	} b;

	struct dual_uint8_t {
		uint8_t bytelow;
		uint8_t bytehigh;
	} bu;

} int16_t_union;








#define DUMP_SIZE (256 / sizeof(int16_t))
#define NUM_REGISTERS 12

typedef struct {
	char* desc;
	int16_t stack_dump_index;
	int16_t word_size;
	int8_t type;		// 0 = word   1 = skip   2 = dword   3 = flags   4 = stack    5 = bp (add to value?)
} reg_info;

#define REGINFO_LENGTH 12

reg_info registers[18] = {
	{"CS:IP", 15, 2, 2},
	{"FLAGS", 17, 1, 3},
	{"AX", 11, 1, 0},
	{"BX", 10, 1, 0},
	{"CX", 9, 1, 0},
	{"DX", 8, 1, 0},
	{"SI", 6, 1, 0},
	{"DI", 7, 1, 0},
	{"DS", 4, 1, 0},
	{"ES", 5, 1, 0},
	{"SS", 3, 1, 0},
	{"BP", 0, 1, 0},	// todo offset??
	{"SP", 1, 1, 0},	
	{"current CS", 2, 1, 1},

	{"PREV IP", 12, 1, 1},
	{"PREV AX", 13, 1, 1},
	{"PREV BX", 14, 1, 1},
	
	{"STACK", 18, NUM_REGISTERS - 13, 4}  // (sum of above)

	// prev ip
	// prev bx
	// prev ax
};



#define BYTE_TO_BINARY_PATTERN "%c%c%c%c%c%c%c%c\n"
#define BYTE_TO_BINARY(byte)  \
  (byte & 0x80 ? '1' : '0'), \
  (byte & 0x40 ? '1' : '0'), \
  (byte & 0x20 ? '1' : '0'), \
  (byte & 0x10 ? '1' : '0'), \
  (byte & 0x08 ? '1' : '0'), \
  (byte & 0x04 ? '1' : '0'), \
  (byte & 0x02 ? '1' : '0'), \
  (byte & 0x01 ? '1' : '0')

  #define WORD_TO_BINARY_PATTERN "%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c\n"
#define WORD_TO_BINARY(word)  \
  (word & 0x8000 ? '1' : '0'), \
  (word & 0x4000 ? '1' : '0'), \
  (word & 0x2000 ? '1' : '0'), \
  (word & 0x1000 ? '1' : '0'), \
  (word & 0x0800 ? '1' : '0'), \
  (word & 0x0400 ? '1' : '0'), \
  (word & 0x0200 ? '1' : '0'), \
  (word & 0x0100 ? '1' : '0'), \
  (word & 0x80 ? '1' : '0'), \
  (word & 0x40 ? '1' : '0'), \
  (word & 0x20 ? '1' : '0'), \
  (word & 0x10 ? '1' : '0'), \
  (word & 0x08 ? '1' : '0'), \
  (word & 0x04 ? '1' : '0'), \
  (word & 0x02 ? '1' : '0'), \
  (word & 0x01 ? '1' : '0')

int16_t main ( int16_t argc,int8_t** argv )  { 
    
    // Export .inc file with segment values, etc from the c coe
    FILE* fp = fopen("dumpdump.bin", "r");
	int16_t registerindex = 0; 

	if (!fp){
		printf("no dumpdump.bin found, aborting");
		return 0;
	}

	for (registerindex = 0; registerindex < DUMP_SIZE; registerindex++){
		reg_info* reg = &registers[registerindex];
		fseek(fp, 2*reg->stack_dump_index ,SEEK_SET);
		switch (reg->type){
			case 0:	// reg
			{
				int16_t datum;
				fread(&datum, 2, 1, fp);
				printf("%s:\t %x\t%i\n", reg->desc, datum, datum);
				break;
			} 
			case 1:	// ignore
				break;
			case 2:	// cs:ip
			{
				int32_t datum;
				fread(&datum, 4, 1, fp);
				printf("%s:\t %Fp\t%li\n", reg->desc, datum, datum);
				break;
			} 			
			case 3:	//flags
			{
				int16_t datum;
				fread(&datum, 2, 1, fp);
				printf("%s:\t %x\t%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c\n" , reg->desc, datum, WORD_TO_BINARY(datum));
				break;
			} 
			case 4: // stack contents
			{
				int16_t index = reg->stack_dump_index;
				int8_t count = 0;
				printf("%s:\n" , reg->desc);
				while (index < DUMP_SIZE){

					int16_t datum;
					fread(&datum, 2, 1, fp);
					printf("%04x " , datum);
					index ++;
					count ++;
					// if (count == 16){
					// 	printf("\n");
					// 	count = 0;
					// }


				}


				fclose(fp);
				return 0;
			}
		}

	}

    
    return 0;
} 
