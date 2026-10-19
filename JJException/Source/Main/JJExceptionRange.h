//
//  JJExceptionRange.h
//  JJException
//
//  Range validation shared by the container / string guards.
//
//  Why this exists:
//  The original guards used `range.location + range.length <= length`.
//  That addition is unsigned and wraps around: NSMakeRange(NSUIntegerMax - 1, 5)
//  produces a "valid" range and the guard is skipped, so the very input that
//  needs protecting goes straight into Foundation and still crashes.
//  Always compare with "location first, then subtract" instead of adding.
//

#ifndef JJExceptionRange_h
#define JJExceptionRange_h

#import <Foundation/Foundation.h>

/// YES when `range` is fully inside a collection/string of `length`.
/// {length, 0} is valid (an insertion / empty range at the end).
static inline BOOL JJExceptionIsValidRange(NSRange range, NSUInteger length) {
    if (range.location == NSNotFound) {
        return NO;
    }
    if (range.location > length) {
        return NO;
    }
    // Subtraction can never underflow here because location <= length.
    return range.length <= (length - range.location);
}

/// Clamp a location/length pair to the receiver length, never overflowing.
static inline NSRange JJExceptionClampRange(NSRange range, NSUInteger length) {
    if (range.location == NSNotFound || range.location > length) {
        return NSMakeRange(length, 0);
    }
    NSUInteger maxLength = length - range.location;
    NSUInteger newLength = range.length;
    if (newLength > maxLength) {
        newLength = maxLength;
    }
    return NSMakeRange(range.location, newLength);
}

#endif /* JJExceptionRange_h */
