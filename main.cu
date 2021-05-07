//
// Created by DJtheRedstoner on 5/5/2021.
//

#include <iostream>
#include "SimpleRandom.cu"

__device__
inline int getGenericEnchantability(SimpleRandom& random, int bookshelves) {
    int first = random.nextInt(8);
    int second = random.nextInt(bookshelves + 1);
    return first + 1 + (bookshelves >> 1) + second;
}

__device__
inline int getLevelsSlot1(SimpleRandom& random, int bookshelves) {
    int enchantability = getGenericEnchantability(random, bookshelves) / 3;
    return enchantability < 1 ? 1 : enchantability;
}

__device__
inline int getLevelsSlot2(SimpleRandom& random, int bookshelves) {
    return getGenericEnchantability(random, bookshelves) * 2 / 3 + 1;
}

__device__
inline int getLevelsSlot3(SimpleRandom& random, int bookshelves) {
    int enchantability = getGenericEnchantability(random, bookshelves);
    int twiceBookshelves = bookshelves * 2;
    return enchantability < twiceBookshelves ? twiceBookshelves : enchantability;
}

__device__
inline bool checkSlots(int bookshelves, SimpleRandom r, const int* data) {
    int slot1 = data[bookshelves * 3];
    int slot2 = data[bookshelves * 3 + 1];
    int slot3 = data[bookshelves * 3 + 2];

    if (slot1 == 0) return true;

    if (getLevelsSlot1(r, bookshelves) == slot1) {
        if (getLevelsSlot2(r, bookshelves) == slot2) {
            if (getLevelsSlot3(r, bookshelves) == slot3) {
                return true;
            }
        }
    }
    return false;
}

__global__
void fullCrack(const int* data, long long* p_seed, int* counts) {

    SimpleRandom r;

    unsigned int first = blockIdx.x * blockDim.x + threadIdx.x;
    unsigned int stride = blockDim.x * gridDim.x;

    int count;
    for (long long seed = first; seed < (1LL << 32) - 1; seed += stride) {
        for (int i = 15; i >= 0; i--) {
            r.setSeed((int) seed);
            if (!checkSlots(i, r, data)) goto fail;
        }
        //printf("%lli\n", seed);
        count++;
        *p_seed = seed;
        fail:
        ;
    }

    counts[first] = count;
}

bool initialized = false;
int* data;

void resetCracker() {
    if (initialized) {
        cudaFree(data);
    }
    cudaMallocManaged(&data, 16*3*sizeof(int));

    for (int i = 0; i < 16 * 3; i++) {
        data[i] = 0;
    }

    initialized = true;
}

void addInfo(int bookshelves, int slot1, int slot2, int slot3) {
    data[bookshelves * 3] = slot1;
    data[bookshelves * 3 + 1] = slot2;
    data[bookshelves * 3 + 2] = slot3;
}

int main() {

    int blockSize = 1024;
    int blockCount = 32;
    int threadCount = blockCount * blockSize;


    /***
     * 15 07 13 30 100662581
     * 14 07 14 28 1275608
     * 13 05 15 26 31570
     * 12 04 09 24 734
     * 11 04 11 22 55
     * 10 06 06 20 F767F75E
     */
    resetCracker();
    addInfo(15,  7, 13, 30);
    addInfo(14,  7, 14, 28);
    addInfo(13,  5, 15, 26);
    addInfo(12,  4,  9, 24);
    addInfo(11,  4, 11, 22);
    addInfo(10,  6,  6, 20);

    long long* seed;
    cudaMallocManaged(&seed, sizeof(long long));

    int* count;
    cudaMallocManaged(&count, threadCount*sizeof(int));

    fullCrack<<<blockCount, blockSize>>>(data, seed, count);
    cudaDeviceSynchronize();

    int total = 0;
    for (int i = 0; i < threadCount; i++) {
        total += count[i];
    }

    std::cout << total << std::endl;
    printf("%llX", *seed);

    cudaFree(data);
    cudaFree(seed);
    cudaFree(count);
}