# Tasty Basic Files

## Introduction
The CP/M version of Tasty Basic allows programs to be saved to and loaded from disk. This
document describes the Tasty Basic `.TBA` file format.

## .TBA File format
Tasty Basic `.TBA` files are direct reflections of Tasty Basic programs as held in memory. Thus,
each line of code starts with a 16 bit, LSB first, line number and ends with a carriage return
character (0xD). An EOF marker (0x1A) indicates the end of the file. Any trailing NUL characters
(0x0) are ignored.

### Example
Following is an example Tasty Basic program:
```
10 PRINT "HELLO WORLD"
20 GOTO 10
```
And its `.TBA` file representation:
```
0A 00 50 52 49 4E 54 20 22 48 45 4C 4C 4F 20 57 
4F 52 4C 44 22 0D 14 00 47 4F 54 4F 20 31 30 0D
1A 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
```

