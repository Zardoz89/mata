/*****************************************************************************/
/**                 Poor's man stdint para C pre C99                        **/
/*****************************************************************************/

#ifndef __MYINT_H_
#define __MYINT_H_

#ifdef __386__
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
#else
/* 16 bit */
typedef signed   char      int_8_t;
typedef signed   short     int_16_t;
typedef signed   long      int_32_t;
typedef unsigned char      uint_8_t;
typedef unsigned short     uint_16_t;
typedef unsigned long      uint_32_t;
#endif


#endif
/* vim: set ts=2 sw=2 tw=0 et fileencoding=cp858 :*/

