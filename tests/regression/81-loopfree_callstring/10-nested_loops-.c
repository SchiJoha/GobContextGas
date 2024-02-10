// PARAM: --set "ana.activated[+]" loopfree_callstring --enable ana.int.interval_set
// Basic example
#include <stdio.h>

int g(int i);

int h(int i)
{
    return g(i - 1);
}

int f(int i)
{
    if (i == 0)
    {
        return h(4);
    }
    if (i > 0)
    {
        return f(i - 1);
    }
    return 1;
}

int g(int i)
{
    if (i <= 4)
    {
        return f(i - 1);
    }
    else
    {
        return 0;
    }
}

int main(void)
{
    // main -> g(4) -> f(3) -> f(2) -> f(1) -> f(0) -> h(4) ->
    //         g(3) -> f(2) -> f(1) -> f(0) -> h(4) -> g(3) -> ...
    // [main] {f, h, g}
    __goblint_check(g(4) == 0);
}
