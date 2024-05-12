#include <iostream>
#include <sys/utsname.h>
#include <cerrno>

int main() {
    struct utsname buf;
    if (uname(&buf) != EXIT_SUCCESS) {
        std::cerr << "Error calling uname\n";
        return 1;
    }

    std::cout << "CPU architecture: " << buf.machine << '\n';
    return 0;
}
