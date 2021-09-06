#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tweetnacl.h"
#include "blind.h"

// wrapper function for generating key pair and blinding secret key memory
int generate_keypair(unsigned char **pub, unsigned char **sec) {
    *pub = (unsigned char *)malloc(crypto_box_PUBLICKEYBYTES);
    if (*pub == NULL) {
        return 1;
    }

    *sec = (unsigned char *)malloc(crypto_box_SECRETKEYBYTES);
    if (*sec == NULL) {
        return 1;
    }

    crypto_box_keypair(*pub, *sec);

    blnd(*sec, crypto_box_SECRETKEYBYTES);

    return 0;
}


__attribute__((blinded)) unsigned char *blinded;
// unsigned char *blinded;

int demo(unsigned char *a_pub, __attribute__((blinded)) unsigned char *a_sec) {
// int demo(unsigned char *a_pub, unsigned char *a_sec) {
    // printf("branch: %d\n", branch(a_sec));

    unsigned char n[crypto_box_NONCEBYTES];
    unsigned long long mlen = 10 + crypto_box_ZEROBYTES;
    unsigned char *m = (unsigned char *)malloc(mlen);
    memset(m, 0, crypto_box_ZEROBYTES);
    unsigned char *c = (unsigned char *)malloc(mlen);

    unsigned char x = 0;
    unsigned char *unblinded = (unsigned char *)malloc(crypto_box_SECRETKEYBYTES);
    if (unblinded == NULL) {
        return 1;
    }
    blinded = (unsigned char *)malloc(crypto_box_SECRETKEYBYTES);
    // if (blinded == NULL) {
    //     return 1;
    // }
    blinded[1] = 5;
    blnd(blinded, crypto_box_SECRETKEYBYTES);

    int op = 7;
    printf("Test case: ");
    scanf("%d", &op);
    switch (op) {
        case 1: // try to read from blinded memory
            x = a_sec[0];
            break;
        case 2: // try to print from blinded memory
            printf("%lx\n", a_sec[0]);
            break;
        case 3: // branch based on blinded memory
            // if (a_sec[0] > 1) {
            //     printf("Branched based on blinded memory.\n");
            // }
            break;
        case 4: // try to use blinded memory as address for a load
            // x = unblinded[blinded[1]];
            break;
        case 5: // try to use blinded memory as address for a store
            // unblinded[blinded[1]] = 4;
            break;
        case 6: // writing into blinded memory works
            blinded[0] = a_sec[0] + 1;
            break;
				case 7: // encrypting unblinded msg using blinded key
						crypto_box(c, m, mlen, n, a_pub, a_sec);
						break;
				case 8: // encrypting blinded msg using blinded key
                        blnd(m, mlen);

						crypto_box(c, m, mlen, n, a_pub, a_sec);
						break;
    }

    printf("PASSED\n");

    return 0;
}

int main() {
    unsigned char *a_pub;
    unsigned char *a_sec;

    if (generate_keypair(&a_pub, &a_sec)) {
        return 1;
    }

    int result = demo(a_pub, a_sec);
    rblnd();
    return result;
}
