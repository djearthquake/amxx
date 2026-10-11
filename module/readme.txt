//For memoryhack compilation on Linux
g++ -m32 -O2 -shared -fPIC -fpermissive -w -s -o memhack_amxx_i386.so *.cpp -ldl
