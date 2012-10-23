main()
{
   char buffer[100];

   /* set to 25 row x 80 column monochrome mode 6 (HIRES) */
   mode('H');
   printf("Please enter your name: ");
   gets(buffer);
    /* set to 25 row x 40 column 4-color mode 4 (MEDRES) */
   mode('M');
   printf("Hello %s!\nWelcome to the growing family of\nAZTEC C users...\n",
      buffer);
   getchar();
   /* set to 25 row x 80 column color text mode 3 (LOWRES) */
   mode('L');
}
