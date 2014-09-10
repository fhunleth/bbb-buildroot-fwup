#include <stdio.h>

void crash()
{
      volatile int* a = (int*)(NULL);
      *a = 1;
}
