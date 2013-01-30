/***********************************************************************

   sysgen utility

   Copyright (C) 2009, Max Scane

   This program allows you to build and manage the N8VEM's system ROM.

   There are three possible functions which are selected by command line parameters:

   sysgen -C xxx image.file           : This command allows you to create a blank file of xxx KB in size

   sysgen -e extract.file image.file  : This command extracts the 10 KB system "track" to a file

   sysgen -i insert.file image.file   : This command inserts (writes) the contents of a file to the system "track"


*************************************************************************/

#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>


void  usage(void)
{
    printf("N8VEM sysgen v1.0\n");
    printf("usage:\n");
    printf("sysgen -C xx filename          - Create filename xx KB in size\n");
    printf("sysgen -i importfile imagefile - Import the contents of importfile to Imagefile\n");
    printf("sysgen -e exportfile imagefile - Export system track to exportfile\n");
    exit(1);
}

int main(int argc, char *argv[])

{

  int  i, size, fd1, fd2, nwritten, nread;
  int ntotal = 0;
  char buffer [10240];

  if (argc != 4)
    {
       printf("\nIncorrect number of parameters\n\n");
       usage();
    }


  if (strcmp(argv[1], "-C") == 0)  /* Create command */
    {
        for (i=0; i<1024; i++) buffer[i] = 229; 

        fd1 = creat(argv[3],O_WRONLY|S_IRWXU);

        if ( fd1 == -1)
          {
            printf("error creating file %s\n",argv[3]);
            exit(1);
          }
        for (i=0; i< (atoi(argv[2])) ; i++)
          {
           nwritten = write (fd1, &buffer, 1024);
           if (nwritten == -1)
            {
            printf ("error writing file %s\n",argv[3]);
            exit(1);
            }
          ntotal+=nwritten;
          }
        printf("wrote %d bytes to file %s\n",ntotal,argv[3]);
        close(fd1);
        exit(0);
    }

  if (strcmp(argv[1], "-i") == 0)  /* Import command */
    {

        fd1 = open (argv[2],O_RDONLY);
        if (fd1 == -1)
        {
          printf("error opening input file %s\n",argv[2]);
          exit(1);
        }
        fd2 = open (argv[3], O_WRONLY); 
        if ( fd2 == -1)
        {
          printf("error opening output file %s\n",argv[3]);
          exit(1);
        }

        nread = read( fd1, &buffer, 10240);

        if (nread == -1)
        {
          printf ("error reading from input file %s\n", argv[2]);
          exit(1);
        }
        nwritten = write ( fd2, &buffer, nread);
        if (nwritten == -1)
        {
          printf ("error writing to output file %s\n", argv[3]);
          exit(1);
        }
        printf("wrote %d bytes to file %s\n",nwritten,argv[3]);

        close(fd1);
        close(fd2);

        exit(0);
    }

  if (strcmp(argv[1], "-e") == 0)  /* Export command */
    {

        fd1 = creat(argv[2],O_WRONLY|S_IRWXU);        /* export file */

        if (fd1 == -1)
        {
          printf("error creating export file %s\n",argv[2]);
          exit(1);
        } 

        fd2 = open(argv[3],O_RDONLY);        /* romimage file */
        if (fd2 == -1)
        {
          printf("error opening romimage file %s\n",argv[3]);
          exit(1);
        } 
        nread = read( fd2, &buffer, 10240);
        if (nread == -1)
        {
          printf ("error reading from romimage file %s\n",argv[3]);
          exit(1);
       }
        nwritten = write( fd1, &buffer, nread);
        if (nwritten == -1)
        {
          printf ("error writing to outputfile %s\n",argv[2]);
          exit(1);
        }
        printf("wrote %d bytes to file %s\n",nwritten,argv[2]);

        close(fd1);
        close(fd2);

        exit(0);
    }

  usage();

  return EXIT_SUCCESS;
}


