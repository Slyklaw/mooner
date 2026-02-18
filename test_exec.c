#include <unistd.h>
int main() {
    char *args[] = { "./a.out", NULL };
    char *env[] = { NULL };
    execve("./a.out", args, env);
    return 1;
}
