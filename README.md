# meltdown-poc
A PoC implementation of the meltdown attack described in  [https://meltdownattack.com/meltdown.pdf](https://meltdownattack.com/meltdown.pdf)

This implementation was tested on Windows 10 (`10.0.15063.0`) on Intel Atom x5-Z8350 hardware.

It is likely that it needs some tweaking to run properly on other platforms.

So far only some specific kernel memory could be leaked, it worked with the page containing PsLoadedModuleList very well, with the kernel base address not so well.

## UPDATE:

As pointed out in [http://blog.fefe.de/?ts=a4ad9f54](http://blog.fefe.de/?ts=a4ad9f54) the google blogpost documents a precondition which must be fullfilled for memory in order to be readable by meltdown.

This *seems* to be that the data must be present in the L1 cache of the executing core.

Reference: [https://googleprojectzero.blogspot.de/2018/01/reading-privileged-memory-with-side.html](https://googleprojectzero.blogspot.de/2018/01/reading-privileged-memory-with-side.html)

![screenshot](img/meltdown.JPG)