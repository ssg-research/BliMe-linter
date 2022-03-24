
#ifndef __noinilne
#define __noinline __attribute__((noinline))
#endif // ifndef __noinline

#define __blinded __attribute__((blinded))
#ifdef NO_BLINDED
#undef __blinded
#define __blinded
#endif // ifdef NO_BLINDED
