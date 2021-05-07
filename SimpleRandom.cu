//
// Created by DJtheRedstoner on 5/4/2021.
//

class SimpleRandom {
private:
    const static long long multiplier = 0x5DEECE66D;
    const static long long mask = (1LL << 48) - 1;
    long long seed = 0LL;
public:
    __device__
    void setSeed(long long newSeed) {
        seed = (newSeed ^ multiplier) & mask;
    }
    __device__
    int nextInt(int bound) {
        int r = next();
        int m = bound - 1;
        if ((bound & m) == 0)
            r = (int)((bound * (long long)r) >> 31);
        else {
            int u = r;
            while (u - (r = u % bound) + m < 0) u = next();
        }
        return r;
    }
private:
    __device__
    int next() {
        seed = (seed * multiplier + 0xBLL) & mask;
        return (int)(seed >> 17);
    }
};
