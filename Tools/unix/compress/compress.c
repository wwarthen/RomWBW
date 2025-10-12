/* =====================================================================
 * compress v1.1 - 251012 Paul de Bak, with help from Le Chat AI
 *
 * =====================================================================
 * This RomWBW utility program will attempt to compress any file using
 * a straightforward RLE approach.
 *
 * The output file will have the name of the input file with ".cmp"
 * appended.
 *
 * =====================================================================
 * To compile in Linux (or Windows using MinGW):
 *
 *    gcc -o compress_upd(.exe)  compress_upd.c
 *
 * =====================================================================
 * Usage:  compress(.exe)  <input file>
 *
 * If compression is successful, an ouput file is created with the name
 * of the input file + ".cmp".
 *
 * =====================================================================
 * Program exit codes
 * 0: Success. An output file is created.
 * 1: Incorrect usage or input file not found.
 * 2: Unable to create output file.
 *
 * =====================================================================
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
//#include <string.h>
//#include <libgen.h>  // For basename function

#define VERSION "compress v1.1 - 251012 Paul de Bak & Le Chat AI"
#define MAX_COUNT 0x100  // Maximum count is 256
#define BUFFER_SIZE 65536

size_t calculate_original_size(FILE *input) {
    fseek(input, 0, SEEK_END);
    return ftell(input);
}

size_t calculate_compressed_size(FILE *input) {
    uint8_t buffer[BUFFER_SIZE];
    size_t size, compressed_size = 0;
    while ((size = fread(buffer, 1, BUFFER_SIZE, input)) > 0) {
        size_t i = 0;
        while (i < size) {
            uint8_t byte = buffer[i];
            size_t count = 1;
            // Count the number of repetitions of the current byte
            while (i + count < size && buffer[i + count] == byte && count < MAX_COUNT) {
                count++;
            }
            if (count >= 2) {
                compressed_size += 3;  // Two bytes + count
            } else {
                compressed_size += 1;  // Single byte
            }
            i += count;
        }
    }
    return compressed_size;
}

int compress_file(FILE *input, FILE *output) {
    uint8_t buffer[BUFFER_SIZE];
    size_t size;
    uint8_t repeat_count;
    while ((size = fread(buffer, 1, BUFFER_SIZE, input)) > 0) {
        size_t i = 0;
        while (i < size) {
            uint8_t byte = buffer[i];
            size_t count = 1;
            // Count the number of repetitions of the current byte
            while (i + count < size && buffer[i + count] == byte && count < MAX_COUNT) {
                count++;
            }
            if (count >= 2) {
                fwrite(&byte, 1, 1, output);
                fwrite(&byte, 1, 1, output);
                repeat_count = count - 1;
                fwrite(&repeat_count, 1, 1, output);
            } else {
                fwrite(&byte, 1, 1, output);
            }
            i += count;
        }
    }
    return 1;
}

int main(int argc, char *argv[]) {
    char *input_filename;
    long free_bytes;
    FILE *input;
	size_t original_size;
	size_t compressed_size;
    char output_filename[256];
    char *base_name;
    char *dot;
    FILE *output;

    printf("\n%s\n\n", VERSION);

    if (argc != 2) {
        printf("Usage: %s  <input file>\n", argv[0]);
        printf("Example: %s  RCZ80_ez512_std.upd\n", argv[0]);
        return 1; // Error: Incorrect usage
    }

    input_filename = argv[1];
	input = fopen(input_filename, "rb");
    if (!input) {
        fprintf(stderr, "Error: Input file '%s' not found\n", input_filename);
        return 1; // Error: Input file not found
    }
	
	// Calculate the original file size
    original_size = calculate_original_size(input);
    rewind(input);

    // Calculate the compressed size first
    compressed_size = calculate_compressed_size(input);
    rewind(input);

    // Construct the output filename
	snprintf(output_filename, sizeof(output_filename), "%s.cmp", input_filename);
	
	printf("Compressing %s to %s...\n", input_filename, output_filename);

    output = fopen(output_filename, "wb");
    if (!output) {
        fprintf(stderr, "Error: Unable to create output file '%s'\n", output_filename);
        fclose(input);
        return 2; // Error: Unable to create output file
    }

    compress_file(input, output);

    fclose(input);
    fclose(output);

	printf("Compressed from %lu bytes to %lu bytes (%lu%% reduction)\n", original_size, compressed_size,  (((original_size - compressed_size) * 100) / original_size));
	
    return 0; // Success
}
