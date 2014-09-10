#include "client/linux/handler/exception_handler.h"
#include <stdio.h>

void crash();

static bool dumpCallback(const google_breakpad::MinidumpDescriptor& descriptor,
                         void* context,
                         bool succeeded)
{
      printf("Dump path: %s\n", descriptor.path());
      return succeeded;
}

int main(int argc, char* argv[])
{
      google_breakpad::MinidumpDescriptor descriptor("/tmp");
      google_breakpad::ExceptionHandler eh(descriptor,
                                           NULL,
                                           dumpCallback,
                                           NULL,
                                           true,
                                           -1);
      crash();
      return 0;
}

