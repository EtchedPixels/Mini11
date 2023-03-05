#include <stdio.h>

/*
 *	Adjust the mini11 rom to swap D2 and D0
 */

int main(int argc, char *argv[])
{
    int c;
    while((c = getchar()) != EOF) {
        int x = c & 0xFA;
        if (c & 1)
            x |= 4;
        if (c & 4)
            x |= 1;
        putchar(x);
    }
    return 0;
}
