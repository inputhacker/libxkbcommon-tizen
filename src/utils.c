/*
 * Copyright © 2013 Ran Benita <ran234@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice (including the next
 * paragraph) shall be included in all copies or substantial portions of the
 * Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

#include "utils.h"

#ifdef HAVE_MMAP

#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>

bool
map_file(FILE *file, char **string_out, size_t *size_out)
{
    struct stat stat_buf;
    int fd;
    char *string;

    /* Make sure to keep the errno on failure! */
    fd = fileno(file);
    if (fd < 0)
        return false;

    if (fstat(fd, &stat_buf) != 0)
        return false;

    string = mmap(NULL, stat_buf.st_size, PROT_READ, MAP_SHARED, fd, 0);
    if (string == MAP_FAILED)
        return false;

    *string_out = string;
    *size_out = stat_buf.st_size;
    return true;
}

void
unmap_file(char *str, size_t size)
{
    munmap(str, size);
}

#else

bool
map_file(FILE *file, char **string_out, size_t *size_out)
{
    long ret;
    size_t ret_s;
    char *string;
    size_t size;

    /* Make sure to keep the errno on failure! */

    ret = fseek(file, 0, SEEK_END);
    if (ret != 0)
        return false;

    ret = ftell(file);
    if (ret < 0)
        return false;
    size = (size_t) ret;

    ret = fseek(file, 0, SEEK_SET);
    if (ret < 0)
        return false;

    string = malloc(size);
    if (!string)
        return false;

    ret_s = fread(string, 1, size, file);
    if (ret_s < size) {
        free(string);
        return false;
    }

    *string_out = string;
    *size_out = size;
    return true;
}

void
unmap_file(char *str, size_t size)
{
    free(str);
}

#endif
