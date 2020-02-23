#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libgen.h>

void die(const char msg[]) {
    perror(msg);
    exit(EXIT_FAILURE);
}

int main(int argc, char *argv[]) {
    for (int i = 1; i < argc; i++) {
        // determine file size
        FILE *input_file = fopen(argv[i], "rb");
        if (!input_file) {
            fprintf(stderr, "fail %s\n", argv[i]);
            die("Couldn't open input file");
        }
        if (fseek(input_file, 0, SEEK_END) == -1) {
            die("Error determining file size");
        }
        long file_size = ftell(input_file);
        if (file_size == -1) {
            die("Error determining file size (2)");
        }
        if (fseek(input_file, 0, SEEK_SET) == -1) {
            die("Error determining file size (3)");
        }
        // get file name
        char *name = basename(argv[i]);
        char *dot = strrchr(name, '.');
        if (dot) {
            *dot = '\0';
        }

        // print header
        printf("        .section .rodata\r\n");
        printf("        .global %s\r\n", name);
        printf("        .align  2\r\n\r\n");
        printf("%s:\r\n\r\n", name);

        // write lines
        while (file_size > 0) {
            size_t bytes_read = (file_size > 8) ? 8 : (size_t)file_size;
            unsigned char data_buf[8];
            size_t actual_read = fread(data_buf, 1, bytes_read, input_file);
            if (actual_read != bytes_read) {
                fprintf(stderr, "Error while reading file, only %d read instead of %d\n", (int)actual_read, (int)bytes_read);
                if (feof(input_file))
                    fprintf(stderr, "Reached end of file\n");
                if (ferror(input_file))
                    fprintf(stderr, "An unknown error occured while reading the file\n");
                perror("ERROR");
                exit(EXIT_FAILURE);
            }
            switch (bytes_read) {
                case 1:
                    printf("        .byte   0x%02X\r\n",
                            data_buf[0]);
                    break;
                case 2:
                    printf("        .byte   0x%02X, 0x%02X\r\n",
                            data_buf[0], data_buf[1]);
                    break;
                case 3:
                    printf("        .byte   0x%02X, 0x%02X, 0x%02X\r\n",
                            data_buf[0], data_buf[1], data_buf[2]);
                    break;
                case 4:
                    printf("        .byte   0x%02X, 0x%02X, 0x%02X, 0x%02X\r\n",
                            data_buf[0], data_buf[1], data_buf[2], data_buf[3]);
                    break;
                case 5:
                    printf("        .byte   0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X\r\n",
                            data_buf[0], data_buf[1], data_buf[2], data_buf[3], data_buf[4]);
                    break;
                case 6:
                    printf("        .byte   0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X\r\n",
                            data_buf[0], data_buf[1], data_buf[2], data_buf[3], data_buf[4], data_buf[5]);
                    break;
                case 7:
                    printf("        .byte   0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X\r\n",
                            data_buf[0], data_buf[1], data_buf[2], data_buf[3], data_buf[4], data_buf[5], data_buf[6]);
                    break;
                case 8:
                    printf("        .byte   0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X, 0x%02X\r\n",
                            data_buf[0], data_buf[1], data_buf[2], data_buf[3], data_buf[4], data_buf[5], data_buf[6], data_buf[7]);
                    break;
                default:
                    fprintf(stderr, "Invalid program state\n");
                    exit(EXIT_FAILURE);
            }
            file_size -= (long)bytes_read;
        }

        printf("\r\n");

        if (fclose(input_file)) {
            die("Error while closing file");
        }
    }
    return 0;
}
