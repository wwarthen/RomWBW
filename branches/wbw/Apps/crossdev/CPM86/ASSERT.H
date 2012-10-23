#ifndef NDEBUG
#ifndef stderr
#include <stdio.h>
#endif
#define assert(x) if (!(x)) {fprintf(stderr,"Assertion failed: x, file %s, line %d\n",__FILE__,__LINE__); exit(1);}
#else
#define assert(x)
#endif
