Idris to GAP back end
---------------------

Inspired by Edwin Brady's excellent [PHP backend](https://github.com/edwinb/idris/php) for
his even more excellent language [Idris](http://www.idris-lang.org).

This Idris code to [GAP](https://github.com/gap-system/gap) code at the moment. I might add
direct compilation to GAP kernel code.

Does it work?
-------------

It does work in that it generates code runnable in GAP. It is certainly a very bad
idea to generate GAP code to be interpreted by the GAP runtime for several reasons. One
of those reasons is that at this point one of the most expensive operations in GAP is to call
functions.

Why?
----

Because I can. Also, because I wanted to learn how to write an idris backend. I am considering
making a gap-runtime backend that generates GAP kernel code. Together with Idris' excellent
FFI work it'd be possible to interact between Idris and GAP, experiment with their very disparate
type systems, etc.

Contributions?
--------------

Of course you are welcome to muck about with the code. Let me know if you find any of this 
interesting at all.
 
