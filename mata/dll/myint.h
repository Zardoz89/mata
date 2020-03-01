/*****************************************************************************/
/**                 Poor's man stdint para C pre C99                        **/
/*****************************************************************************/

#ifndef __MYINT_H_
#define __MYINT_H_

#include <limits.h>

// Check word size
#if INT_MAX == 2147483647
#define __WORD_SIZE__ 32
#else
#define __WORD_SIZE__ 16
#endif

#if __WORD_SIZE__ == 32
/* 32 bit */
typedef signed   char      int_8_t;
typedef signed   short     int_16_t;
typedef signed   int       int_32_t;
typedef unsigned char      uint_8_t;
typedef unsigned short     uint_16_t;
typedef unsigned int       uint_32_t;

#define INT8_MAX SCHAR_MAX
#define INT8_MIN SCHAR_MIN
#define UINT8_MAX UCHAR_MAX

#define INT16_MAX SHRT_MAX
#define INT16_MIN SHRT_MIN
#define UINT16_MAX USHRT_MAX

#define INT32_MAX INT_MAX
#define INT32_MIN INT_MIN
#define UINT32_MAX UINT_MAX

#else
/* 16 bit */
typedef signed   char      int_8_t;
typedef signed   short     int_16_t;
typedef signed   long      int_32_t;
typedef unsigned char      uint_8_t;
typedef unsigned short     uint_16_t;
typedef unsigned long      uint_32_t;

#define INT8_MAX SCHAR_MAX
#define INT8_MIN SCHAR_MIN
#define UINT8_MAX UCHAR_MAX

#define INT16_MAX INT_MAX
#define INT16_MIN INT_MIN
#define UINT16_MAX UINT_MAX

#define INT32_MAX LONG_MAX
#define INT32_MIN LONG_MIN
#define UINT32_MAX ULONG_MAX
#endif

#endif
/* vim: set ts=2 sw=2 tw=0 et fileencoding=cp858 :*/

