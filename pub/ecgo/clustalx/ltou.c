#include "stdio.h"
#include "stdarg.h"

main()
{
	char c;

for(;c!=EOF;) {
	c=getchar();
	if(c!='\r')
	putchar(c);
}
}
