//
//  RegexKitPrivateAtomic.h
//  RegexKit
//  http://regexkit.sourceforge.net/
//
//  PRIVATE HEADER -- NOT in RegexKit.framework/Headers
//

/*!
 * @file BMAtomic.h
 * Abstraction layer to <libkern/OSAtomic.h>.
 * ￼￼Provides an interface to atomic functions originally provided by the OS. Atomic functions can be used to provide alternatives to locks in a concurrent application.
 * @sa <a href="http://developer.apple.com/mac/library/documentation/DriversKernelHardware/Reference/libkern_ref/OSAtomic_h" class="external">OSAtomic.h (ADC)</a>
 * @sa <a href="x-man-page://atomic" class="external">atomic(3)</a> (in Xcode: right-click and choose <span class="code"Open Link in Browser").
 */

/*
 Copyright © 2007-2008, John Engelhart
 
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 
 * Neither the name of the Zang Industries nor the names of its
 contributors may be used to endorse or promote products derived from
 this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BMDefines.h"

/// @cond HIDDEN
#ifdef __cplusplus
extern "C" {
#endif

#ifndef _BM_ATOMIC_H_
#define _BM_ATOMIC_H_ 1
/// @endcond 
    
#ifdef __MACOSX_RUNTIME__

#include <libkern/OSAtomic.h>
    
#define HAVE_BM_ATOMIC_OPS
    
#define BMAtomicMemoryBarrier(...)                             OSMemoryBarrier()
    
#define BMAtomicCompareAndSwapInt(oldValue, newValue, ptr)     OSAtomicCompareAndSwap32Barrier(oldValue, newValue, ptr)
    
#define BMAtomicIncrementInt(ptr)                              OSAtomicIncrement32(ptr)
#define BMAtomicDecrementInt(ptr)                              OSAtomicDecrement32(ptr)
#define BMAtomicIncrementIntBarrier(ptr)                       OSAtomicIncrement32Barrier(ptr)
#define BMAtomicDecrementIntBarrier(ptr)                       OSAtomicDecrement32Barrier(ptr)
    
#define BMAtomicOrIntBarrier(mask, ptr)                        OSAtomicOr32Barrier((mask), (ptr))
#define BMAtomicAndIntBarrier(mask, ptr)                       OSAtomicAnd32Barrier((mask), (ptr))
#define BMAtomicTestAndSetBarrier(bit, ptr)                    OSAtomicTestAndSetBarrier((bit), (ptr))
#define BMAtomicTestAndClearBarrier(bit, ptr)                  OSAtomicTestAndClearBarrier((bit), (ptr))
    
#ifdef __LP64__
    #define BMAtomicCompareAndSwapPtr(oldp, newp, ptr)             OSAtomicCompareAndSwap64Barrier((int64_t)oldp,     (int64_t)newp,     (int64_t *)ptr)
    #define BMAtomicCompareAndSwapInteger(oldValue, newValue, ptr) OSAtomicCompareAndSwap64Barrier((int64_t)oldValue, (int64_t)newValue, (int64_t *)ptr)
        
    #define BMAtomicIncrementInteger(ptr)                          OSAtomicIncrement64(       (int64_t *)ptr)
    #define BMAtomicDecrementInteger(ptr)                          OSAtomicDecrement64(       (int64_t *)ptr)
    #define BMAtomicIncrementIntegerBarrier(ptr)                   OSAtomicIncrement64Barrier((int64_t *)ptr)
    #define BMAtomicDecrementIntegerBarrier(ptr)                   OSAtomicDecrement64Barrier((int64_t *)ptr)
#else // __LP64__ not defined
    #define BMAtomicCompareAndSwapPtr(oldp, newp, ptr)             OSAtomicCompareAndSwap32Barrier((int32_t)oldp,     (int32_t)newp,     (int32_t *)ptr)
    #define BMAtomicCompareAndSwapInteger(oldValue, newValue, ptr) OSAtomicCompareAndSwap32Barrier((int32_t)oldValue, (int32_t)newValue, (int32_t *)ptr)
        
    #define BMAtomicIncrementInteger(ptr)                          OSAtomicIncrement32(       (int32_t *)ptr)
    #define BMAtomicDecrementInteger(ptr)                          OSAtomicDecrement32(       (int32_t *)ptr)
    #define BMAtomicIncrementIntegerBarrier(ptr)                   OSAtomicIncrement32Barrier((int32_t *)ptr)
    #define BMAtomicDecrementIntegerBarrier(ptr)                   OSAtomicDecrement32Barrier((int32_t *)ptr)
#endif // __LP64__
    
#endif //__MACOSX_RUNTIME__
    
    // FreeBSD 5+
#if (__FreeBSD__ >= 5)
#include <sys/types.h>
#include <machine/atomic.h>
#include <unistd.h>
    
#define HAVE_BM_ATOMIC_OPS
    BM_STATIC_INLINE void    BMAtomicMemoryBarrier(void)        { volatile int x = 0; atomic_load_acq_int(&x); atomic_store_rel_int(&x, 1); }
    
    BM_STATIC_INLINE BOOL    BMAtomicCompareAndSwapInt(int32_t oldValue, int32_t newValue, volatile int32_t * ptr)  { return(atomic_cmpset_rel_int(ptr, oldValue, newValue)); }
    BM_STATIC_INLINE BOOL    BMAtomicCompareAndSwapPtr(void * oldp, void * newp, volatile void * ptr)               { return(atomic_cmpset_rel_ptr(ptr, oldp,      newp)); }
    
    BM_STATIC_INLINE int32_t BMAtomicIncrementInt(int32_t * ptr)            { atomic_add_int(ptr, 1);           return(atomic_load_acq_32(ptr)); }
    BM_STATIC_INLINE int32_t BMAtomicDecrementInt(int32_t * ptr)            { atomic_subtract_int(ptr, 1);      return(atomic_load_acq_32(ptr)); }
    BM_STATIC_INLINE int32_t BMAtomicIncrementIntBarrier(int32_t * ptr)     { atomic_add_rel_int(ptr, 1);       return(atomic_load_acq_32(ptr)); }
    BM_STATIC_INLINE int32_t BMAtomicDecrementIntBarrier(int32_t * ptr)     { atomic_subtract_rel_int(ptr, 1);  return(atomic_load_acq_32(ptr)); }
    
#ifdef __LP64__
    BM_STATIC_INLINE int64_t BMAtomicIncrementInteger(int64_t * ptr)        { atomic_add_long(ptr, 1);          return(atomic_load_acq_64(ptr)); }
    BM_STATIC_INLINE int64_t BMAtomicDecrementInteger(int64_t * ptr)        { atomic_subtract_long(ptr, 1);     return(atomic_load_acq_64(ptr)); }
    BM_STATIC_INLINE int64_t BMAtomicIncrementIntegerBarrier(int64_t * ptr) { atomic_add_rel_long(ptr, 1);      return(atomic_load_acq_64(ptr)); }
    BM_STATIC_INLINE int64_t BMAtomicDecrementIntegerBarrier(int64_t * ptr) { atomic_subtract_rel_long(ptr, 1); return(atomic_load_acq_64(ptr)); }
    BM_STATIC_INLINE BOOL    BMAtomicCompareAndSwapInteger(int64_t oldValue, int64_t newValue, volatile int64_t * ptr) { return(atomic_cmpset_rel_long(ptr, oldValue, newValue)); }
#else // __LP64__ not defined
    BM_STATIC_INLINE int32_t BMAtomicIncrementInteger(int32_t * ptr)        { atomic_add_int(ptr, 1);           return(atomic_load_acq_32(ptr)); }
    BM_STATIC_INLINE int32_t BMAtomicDecrementInteger(int32_t * ptr)        { atomic_subtract_int(ptr, 1);      return(atomic_load_acq_32(ptr)); }
    BM_STATIC_INLINE int32_t BMAtomicIncrementIntegerBarrier(int32_t * ptr) { atomic_add_rel_int(ptr, 1);       return(atomic_load_acq_32(ptr)); }
    BM_STATIC_INLINE int32_t BMAtomicDecrementIntegerBarrier(int32_t * ptr) { atomic_subtract_rel_int(ptr, 1);  return(atomic_load_acq_32(ptr)); }
    
    BM_STATIC_INLINE BOOL    BMAtomicCompareAndSwapInteger(int32_t oldValue, int32_t newValue, volatile int32_t * ptr) { return(atomic_cmpset_rel_int(ptr, oldValue, newValue)); }
#endif // __LP64__
    
#endif //__FreeBSD__
    
    // Solaris
#if defined(__sun__) && defined(__svr4__)
#include <atomic.h>
    
#define HAVE_BM_ATOMIC_OPS
    BM_STATIC_INLINE void    BMAtomicMemoryBarrier(void)    { membar_enter(); membar_exit(); }

    BM_STATIC_INLINE BOOL    BMAtomicCompareAndSwapInt(int32_t oldValue, int32_t newValue, volatile int32_t * ptr) { return(atomic_cas_uint(ptr, (uint_t)oldValue, (uint_t)newValue) == oldValue ? YES : NO); }
    BM_STATIC_INLINE BOOL    BMAtomicCompareAndSwapPtr(void * oldp,    void * newp,    volatile void * ptr) { return(atomic_cas_ptr(ptr, oldp, newp) == oldp ? YES : NO); }
    
    BM_STATIC_INLINE int32_t BMAtomicIncrementInt(int32_t * ptr)            { return(atomic_inc_uint_nv((uint_t *)ptr)); }
    BM_STATIC_INLINE int32_t BMAtomicDecrementInt(int32_t * ptr)            { return(atomic_dec_uint_nv((uint_t *)ptr)); }
    BM_STATIC_INLINE int32_t BMAtomicIncrementIntBarrier(int32_t * ptr)     { return(atomic_inc_uint_nv((uint_t *)ptr)); }
    BM_STATIC_INLINE int32_t BMAtomicDecrementIntBarrier(int32_t * ptr)     { return(atomic_dec_uint_nv((uint_t *)ptr)); }
    
#ifdef __LP64__
    BM_STATIC_INLINE int64_t BMAtomicIncrementInteger(int64_t * ptr)        { return(atomic_inc_ulong_nv((uint64_t *)ptr)); }
    BM_STATIC_INLINE int64_t BMAtomicDecrementInteger(int64_t * ptr)        { return(atomic_dec_ulong_nv((uint64_t *)ptr)); }
    BM_STATIC_INLINE int64_t BMAtomicIncrementIntegerBarrier(int64_t * ptr) { return(atomic_inc_ulong_nv((uint64_t *)ptr)); }
    BM_STATIC_INLINE int64_t BMAtomicDecrementIntegerBarrier(int64_t * ptr) { return(atomic_dec_ulong_nv((uint64_t *)ptr)); }
    
    BM_STATIC_INLINE BOOL    BMAtomicCompareAndSwapInteger(int64_t oldValue, int64_t newValue, volatile int64_t * ptr) { return(atomic_cas_ulong(ptr, (uint64_t)oldValue, (uint64_t)newValue) == oldValue ? YES : NO); }
#else // __LP64__ not defined
    BM_STATIC_INLINE int32_t BMAtomicIncrementInteger(int32_t * ptr)        { return(atomic_inc_uint_nv((uint_t *)ptr)); }
    BM_STATIC_INLINE int32_t BMAtomicDecrementInteger(int32_t * ptr)        { return(atomic_dec_uint_nv((uint_t *)ptr)); }
    BM_STATIC_INLINE int32_t BMAtomicIncrementIntegerBarrier(int32_t * ptr) { return(atomic_inc_uint_nv((uint_t *)ptr)); }
    BM_STATIC_INLINE int32_t BMAtomicDecrementIntegerBarrier(int32_t * ptr) { return(atomic_dec_uint_nv((uint_t *)ptr)); }
    BM_STATIC_INLINE BOOL    BMAtomicCompareAndSwapInteger(  int32_t oldValue, int32_t newValue, volatile int32_t * ptr) { return(atomic_cas_uint(ptr, (uint_t)oldValue, (uint_t)newValue) == oldValue ? YES : NO); }
#endif // __LP64__
    
#endif // Solaris __sun__ __svr4__
    
    // Try for GCC 4.1+ built in atomic ops and pthreads?
#if !defined(HAVE_BM_ATOMIC_OPS) && ((__GNUC__ == 4) && (__GNUC_MINOR__ >= 1))
    
#warning Unable to determine platform specific atomic operations. Trying gcc 4.1+ built in atomic ops
    
#define HAVE_BM_ATOMIC_OPS
    
#define BMAtomicMemoryBarrier(...)                             __sync_synchronize()
#define BMAtomicIncrementInt(ptr)                              __sync_add_and_fetch(ptr, 1)
#define BMAtomicDecrementInt(ptr)                              __sync_sub_and_fetch(ptr, 1)
#define BMAtomicIncrementIntBarrier(ptr)                       __sync_add_and_fetch(ptr, 1)
#define BMAtomicDecrementIntBarrier(ptr)                       __sync_sub_and_fetch(ptr, 1)
#define BMAtomicCompareAndSwapInt(oldValue, newValue, ptr)     __sync_bool_compare_and_swap(ptr, oldValue, newValue)
#define BMAtomicCompareAndSwapPtr(oldp, newp, ptr)             __sync_bool_compare_and_swap(ptr, oldValue, newValue)
    
#define BMAtomicIncrementInteger(ptr)                          __sync_add_and_fetch(ptr, 1)
#define BMAtomicDecrementInteger(ptr)                          __sync_sub_and_fetch(ptr, 1)
#define BMAtomicIncrementIntegerBarrier(ptr)                   __sync_add_and_fetch(ptr, 1)
#define BMAtomicDecrementIntegerBarrier(ptr)                   __sync_sub_and_fetch(ptr, 1)
#define BMAtomicCompareAndSwapInteger(oldValue, newValue, ptr) __sync_bool_compare_and_swap(ptr, oldValue, newValue)
    
#endif // HAVE_BM_ATOMIC_OPS && gcc >= 4.1 
    
#ifndef   HAVE_BM_ATOMIC_OPS
    #error Unable to determine atomic operations for this platform.
#endif // HAVE_BM_ATOMIC_OPS
    
    
/// @cond HIDDEN
#endif // _BM_ATOMIC_H_ 
    
#ifdef __cplusplus
}  /* extern "C" */
#endif
/// @endcond 