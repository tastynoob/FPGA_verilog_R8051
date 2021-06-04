__sfr __at(127) p;

void delay(int i) {
    while (i--);
}

void main() {
    char a = 0;
    while (1) {
        p = a;
        a++;
        delay(10000);
    }
}

