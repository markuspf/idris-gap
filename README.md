Idris to GAP back end
=====================

Inspired by Edwin Brady's excellent [PHP backend](https://github.com/edwinb/idris-php) for
his even more excellent language [Idris](http://www.idris-lang.org).

This Idris code to [GAP](https://github.com/gap-system/gap) code at the moment. I might add
direct compilation to GAP kernel code.

Does it work?
=============

It does work in that it generates code runnable in GAP. It is certainly a very bad
idea to generate GAP code to be interpreted by the GAP runtime for several reasons. One
of those reasons is that at this point one of the most expensive operations in GAP is to call
functions.

To run the output of this code generator, you will need a reasonably recent version of
[GAP](https://github.com/gap-system/gap). I ran the produced code by using 
```
# idris --codegen gap pythag.idr -o pythag.g
# gap -r pythag.g
```

Why?
====

Because I can. Also, because I wanted to learn how to write an idris backend. I am considering
making a gap-runtime backend that generates GAP kernel code. Together with Idris' excellent
FFI work it'd be possible to interact between Idris and GAP, experiment with their very disparate
type systems, etc.

Contributions?
==============

Of course you are welcome to muck about with the code. Let me know if you find any of this 
interesting at all.

The following is a list of things I might like to implement:
 * Tail call optimisation
 * Compiling to GAP kernel code
 * Compiling to slightly more idiomatic GAP code
 * Proper indentation of the generated GAP code 
 * Foreign function calls
 * Complete support for Idris' primitives 
 
How slow is it?
===============

Probably very. Here are some non-numbers (measured on my i5 laptop):

```
 | Backend |            10 |            50 |           100 |               500 |
 | ------- | ------------- | ------------- | ------------- | ----------------- |
 | C       | 0.00u + 0.01s | 0.04u + 0.02s | 0.25u + 0.11s |  30.27u +  10.62s |
 | PHP     | 0.00u + 0.01s | 0.55u + 0.01s | 4.99u + 0.20s | 632.58u + 129.48s |
 | GAP     | 1.53u + 0.28s | 1.72u + 0.29s | 2.85u + 0.24s | 137.98u +   0.27s |
``` 

