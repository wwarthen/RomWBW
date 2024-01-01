/*
 * Generic and very simple preprocessor
 * Copyright (c) 2012 Total Spectrum Software Inc.
 * MIT Licensed, see terms of use at end of file
 *
 * Reads UTF-16LE or UTF-8 encoded files, and returns a
 * string containing UTF-8 characters.
 * The following directives are supported:
 *  #define FOO  - simple macros with no arguments
 *  #undef
 *  #ifdef FOO / #ifndef FOO
 *  #else / #elseifdef FOO / #elseifndef FOO
 *  #endif
 *  #error message
 *  #warn message
 *  #include "file"
 *
 * Here's an example of reading a file foo.txt in and preprocessing
 * it in an environment where "VALUE1" is defined to "VALUE" and
 * "VALUE2" is defined to "0":
 *
 *   struct preprocess pp;
 *   char *parser_str;
 *
 *   pp_init(&pp, false);
 *   pp_define(&pp, "VALUE1", "VALUE");
 *   pp_define(&pp, "VALUE2", "0");
 *   pp_push_file(&pp, "foo.txt");
 *   pp_run(&pp);
 *   // any additional files to read can be pushed and run here
 *   parser_str = pp_finish(&pp);
 */

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdarg.h>
#include "flexbuf.h"
#include "preprocess.h"

#ifdef _MSC_VER
#define strdup _strdup
#endif

static PreprocessLoadFileFunc s_pLoadFileFunc = 0;
static PreprocessFreeFileBufferFunc s_pFreeFileBufferFunc = 0;

void pp_setFileFunctions(PreprocessLoadFileFunc pLoadFileFunc, PreprocessFreeFileBufferFunc pFreeFileBufferFunc)
{
    s_pLoadFileFunc = pLoadFileFunc;
    s_pFreeFileBufferFunc = pFreeFileBufferFunc;
}

memoryfile* mopen(const char* filename)
{
    memoryfile* f;
    f = (struct memoryfile *)calloc(1, sizeof(*f));
    if (!f)
    {
        return 0;
    }
    f->readoffset = 0;
    f->buffer = s_pLoadFileFunc(filename, &f->length, &f->filepath);

    return f;
}

int mgetc(memoryfile* f)
{
    if (f->readoffset < f->length)
    {
        return (unsigned char)(f->buffer[f->readoffset++]);
    }
    return EOF;
}

int mungetc(int c, memoryfile* f)
{
    f->readoffset--;
    return c;
}

void mclose(memoryfile* f)
{
    s_pFreeFileBufferFunc(f->buffer);
    free(f);
}

/*
 * function to read a single LATIN-1 character
 * from a file
 * returns number of bytes placed in buffer, or -1 on EOF
 */
static int read_latin1(memoryfile *f, char buf[4])
{
  int c = mgetc(f);
  if (c == EOF)
  {
    return -1;
  }
  if (c <= 127)
  {
    buf[0] = (char)c;
    return 1;
  }
  buf[0] = 0xC0 + ((c>>6) & 0x1f);
  buf[1] = 0x80 + ( c & 0x3f );
  return 2;
}

/*
 * function to read a single UTF-8 character
 * from a file
 * returns number of bytes placed in buffer, or -1 on EOF
 */
static int read_single(memoryfile *f, char buf[4])
{
    int c = mgetc(f);
    if (c == EOF)
    {
        return -1;
    }
    buf[0] = (char)c;
    return 1;
}

/*
 * function to read a single UTF-16 character
 * from a file
 * returns number of bytes placed in buffer, or -1 on EOF
 */
static int read_utf16(memoryfile *f, char buf[4])
{
    int c, d;
    int r;
    c = mgetc(f);
    if (c < 0)
    {
        return -1;
    }
    d = mgetc(f);
    if (d < 0)
    {
        return -1;
    }

    c = c + (d<<8);
    /* here we need to translate UTF-16 to UTF-8 */
    /* FIXME: this code is not done properly; it does
       not handle surrogate pairs (0xD800 - 0xDFFF)
     */
    if (c < 128)
    {
        buf[0] = (char)c;
        r = 1;
    }
    else if (c < 0x800)
    {
        buf[0] = 0xC0 + ((c>>6) &  0x1F);
        buf[1] = 0x80 + ( c & 0x3F );
        r = 2;
    }
    else if (c < 0x10000)
    {
        buf[0] = 0xE0 + ((c>>12) & 0x0F);
        buf[1] = 0x80 + ((c>>6) & 0x3F);
        buf[2] = 0x80 + (c & 0x3F);
        r = 3;
    }
    else
    {
        buf[0] = 0xF0 + ((c>>18) & 0x07);
        buf[1] = 0x80 + ((c>>12) & 0x3F);
        buf[2] = 0x80 + ((c>>6) & 0x3F);
        buf[3] = 0x80 + (c & 0x3F);
        r = 4;
    }
    return r;
}

/*
 * read a line
 * returns number of bytes read, or 0 on EOF
 */
int pp_nextline(struct preprocess *pp)
{
    int r;
    int count = 0;
    memoryfile *f;
    char buf[4];
    struct filestate *A;

    A = pp->fil;
    if (!A)
    {
        return 0;
    }
    f = A->f;
    A->lineno++;

    flexbuf_clear(&pp->line);
    if (A->readfunc == NULL)
    {
        int c0, c1, c2;
        c0 = mgetc(f);
        if (c0 < 0)
        {
            return 0;
        }
        c1 = mgetc(f);
        c2 = mgetc(f);
        if ((c0 == 0xff && c1 == 0xfe) || c1 == 0)
        {
            A->readfunc = read_utf16;
            mungetc(c2, f);
        }
        else if (c0 == 239 && c1 == 187 && c2 == 191)
        {
            A->readfunc = read_single;
        }
        else
        {
            A->readfunc = read_latin1;
            mungetc(c2, f);
            mungetc(c1, f);
        }
        /* add UTF-8 encoded BOM */
        flexbuf_addchar(&pp->line, 239);
        flexbuf_addchar(&pp->line, 187);
        flexbuf_addchar(&pp->line, 191);
        if (A->readfunc == read_latin1)
        {
            flexbuf_addchar(&pp->line, c0);
        }
        if (c0 == '\n')
        {
            flexbuf_addchar(&pp->line, 0);
            return 1;
        }
    }
    for(;;)
    {
        r = (*A->readfunc)(f, buf);
        if (r <= 0) break;
        count += r;
        flexbuf_addmem(&pp->line, buf, r);
        if (r == 1 && buf[0] == '\n') break;
    }
    flexbuf_addchar(&pp->line, '\0');
    return count;
}

/*
 * default error handling functions
 */
static void default_messagefunc(const char *level, const char *filename, int line, const char *msg)
{
    fprintf(stderr, "%s:%d: %s: ", filename, line, level);
    fprintf(stderr, "%s", msg);
    fprintf(stderr, "\n");
}

static void domessage(struct preprocess *pp, const char *level, const char *msg, ...)
{
    va_list args;
    char tmpmsg[BUFSIZ];
    struct filestate *fil;

    va_start(args, msg);
    vsnprintf(tmpmsg, sizeof(tmpmsg), msg, args);
    va_end(args);

    fil = pp->fil;
    if (fil)
    {
        (*pp->messagefunc)(level, pp->fil->name, pp->fil->lineno, tmpmsg);
    }
    else
    {
        (*pp->messagefunc)(level, "", 0, tmpmsg);
    }
}

/*
 * initialize preprocessor
 */
void pp_init(struct preprocess *pp, bool alternate)
{
    memset(pp, 0, sizeof(*pp));
    flexbuf_init(&pp->line, 128);
    flexbuf_init(&pp->whole, 102400);

    pp->messagefunc = default_messagefunc;
    pp->alternate = alternate;
}

/*
 * push a file into the preprocessor
 * files will be processed in LIFO order,
 * so the one on top of the stack is the
 * "current" one; this makes #include implementation
 * easier
 */
void pp_push_file_struct(struct preprocess *pp, memoryfile *f, const char *filename)
{
    struct filestate *A;

    A = (struct filestate *)calloc(1, sizeof(*A));
    if (!A)
    {
        domessage(pp, "error", "Out of memory!\n");
        return;
    }
    A->lineno = 0;
    A->f = f;
    A->next = pp->fil;
    A->name = filename;
    pp->fil = A;
}

void pp_push_file(struct preprocess *pp, const char *name)
{
    memoryfile *f;

    f = mopen(name);
    if (!f)
    {
        domessage(pp, "error", "Unable to open file %s", name);
        return;
    }
    pp_push_file_struct(pp, f, name);
    pp->fil->flags |= FILE_FLAGS_CLOSEFILE;
}

/*
 * pop the current file state off the stack
 * closes the file as a side effect
 */
void pp_pop_file(struct preprocess *pp)
{
    struct filestate *A;
    struct ifstate *I, *PI;

    PI = NULL;
    I = pp->ifs;
    while (I)
    {
        if (strcmp(pp->fil->name, I->name) == 0)
        {
           domessage(pp, "error", "Unterminated #if starting at line %d", I->linenum);
           if (PI == NULL)
           {
              pp->ifs = I->next;
              free(I);
              I = pp->ifs;
           }
           else
           {
              PI->next = I->next;
              free(I);
              I = PI->next;
           }
        }
        else
        {
           PI = I;
           I = I->next;
        }
    }
    A = pp->fil;
    if (A)
    {
        pp->fil = A->next;
        if (A->flags & FILE_FLAGS_CLOSEFILE)
        {
            mclose(A->f);
        }
        free(A);
    }
}

/*
 * add a definition
 * "flags" indicates things like whether we must free the memory
 * associated with name and def
 */
static void pp_define_internal(struct preprocess *pp, const char *name, const char *def, int flags)
{
    struct predef *the;

    the = (struct predef *)calloc(sizeof(*the), 1);
    the->name = name;
    the->def = def;
    the->flags = flags;
    the->next = pp->defs;
    pp->defs = the;
}

/*
 * the user visible "pp_define"; used mainly for constant strings and
 * such, so we do not free those
 */
void pp_define(struct preprocess *pp, const char *name, const char *str)
{
    pp_define_internal(pp, name, str, 0);
}

/*
 * retrieive a definition
 * returns NULL if no definition exists (or if there was an
 * explicit #undef)
 */
const char* pp_getdef(struct preprocess *pp, const char *name)
{
    struct predef *X;
    const char *def = NULL;
    X = pp->defs;
    while (X)
    {
        if (!strcmp(X->name, name))
        {
            def = X->def;
            break;
        }
        X = X->next;
    }
    return def;
}

/* structure describing current parse state of a string */
typedef struct parse_state
{
    char *str;  /* pointer to start of string */
    char *save; /* pointer to where last parse ended */
    int   c;    /* saved character */
} ParseState;

static void parse_init(ParseState *P, char *s)
{
    P->str = s;
    P->save = NULL;
    P->c = 0;
}

#define PARSE_ISSPACE 1
#define PARSE_IDCHAR  2
#define PARSE_OTHER   3

static int
classify_char(int c)
{
    if (isspace(c))
    {
        return PARSE_ISSPACE;
    }
    if (isalnum(c) || (c == '_'))
    {
        return PARSE_IDCHAR;
    }
    return PARSE_OTHER;
}

/*
 * fetch the next word
 * a word is a sequence of identifier characters, spaces, or
 * other characters
 */
static char *parse_getword(ParseState *P)
{
    char *word, *ptr;
    int state;

    if (P->save)
    {
        *P->save = (char)(P->c);
        ptr = P->save;
    }
    else
    {
        ptr = P->str;
    }
    word = ptr;
    if (!*ptr) return ptr;
    if (*ptr == '\"')
    {
       ptr++;
       while (*ptr && (*ptr != '\"'))
       {
          ptr++;
       }
       if (*ptr == '\"')
       {
          ptr++;
       }
       P->save = ptr;
       P->c = *ptr;
       *ptr = 0;
       return word;
    }
    state = classify_char((unsigned char)*ptr);
    ptr++;
    if (state != PARSE_OTHER)
    {
       while (*ptr && classify_char((unsigned char)*ptr) == state)
       {
           ptr++;
       }
    }

    P->save = ptr;
    P->c = *ptr;
    *ptr = 0;
    return word;
}

static char *parse_restofline(ParseState *P)
{
    char *ptr;
    char *ret;

    if (P->save)
    {
        *P->save = (char)(P->c);
        ptr = P->save;
    }
    else
    {
        ptr = P->str;
    }
    ret = ptr;
    while (*ptr && *ptr != '\n')
    {
        ptr++;
    }
    if (*ptr)
    {
        P->c = *ptr;
        *ptr = 0;
        P->save = ptr;
    }
    else
    {
        P->save = NULL;
    }
    P->str = ret;
    return P->str;
}

static void parse_skipspaces(ParseState *P)
{
    char *ptr;
    if (P->save)
    {
        *P->save = (char)(P->c);
        ptr = P->save;
    }
    else
    {
        ptr = P->str;
    }
    while (*ptr && isspace(*ptr))
    {
        ptr++;
    }
    P->str = ptr;
    P->save = NULL;
}

static char *parse_getwordafterspaces(ParseState *P)
{
    parse_skipspaces(P);
    return parse_getword(P);
}

static char *parse_getquotedstring(ParseState *P)
{
    char *ptr, *start;
    parse_skipspaces(P);
    ptr = P->str;
    if (*ptr != '\"')
    {
        return NULL;
    }
    ptr++;
    start = ptr;
    while (*ptr && *ptr != '\"')
    {
        ptr++;
    }
    if (!*ptr)
    {
        return NULL;
    }
    P->save = ptr;
    P->c = *ptr;
    *ptr = 0;
    return start;
}


/*
 * expand macros in a buffer
 * "src" is the source data
 * "dst" is a destination flexbuf
 */
static int expand_macros(struct preprocess *pp, struct flexbuf *dst, char *src)
{
    ParseState P;
    char *word;
    const char *def;
    int len;

    if (!pp_active(pp))
    {
        return 0;
    }

    parse_init(&P, src);
    for(;;)
    {
        word = parse_getword(&P);
        if (!*word)
        {
            break;
        }
        if (pp->incomment)
        {
            if (strstr(word, pp->endcomment))
            {
                --pp->incomment;
            }
            else
            {
                if (strstr(word, pp->startcomment))
                {
                    pp->incomment++;
                }
            }
            def = word;
        }
        else if (isalpha((unsigned char)*word))
        {
            def = pp_getdef(pp, word);
            if (!def)
            {
                def = word;
            }
            else if (pp->alternate && (strlen(def) == 0))
            {
                def = word;
            }
        }
        else
        {
            if (pp->startcomment && strstr(word, pp->startcomment))
            {
                pp->incomment++;
            }
            def = word;
        }
        flexbuf_addstr(dst, def);
    }
    len = (int)flexbuf_curlen(dst);
    flexbuf_addchar(dst, 0);
    return len;
}

static void handle_ifdef(struct preprocess *pp, ParseState *P, int invert)
{
    char *word;
    const char *def;
    struct ifstate *I;

    I = (struct ifstate *)calloc(1, sizeof(*I));
    if (!I)
    {
        domessage(pp, "error", "Out of memory\n");
        return;
    }
    I->next = pp->ifs;
    if (pp->fil)
    {
        I->name = strdup(pp->fil->name);
        I->linenum = pp->fil->lineno;
    }

    if (!pp_active(pp))
    {
        I->skip = 1;
        I->skiprest = 1;  /* skip all branches, even else */
        pp->ifs = I;
        return;
    }
    else
    {
        I->skip = 0;
        I->skiprest = 0;
        pp->ifs = I;
    }
    
    word = parse_getwordafterspaces(P);
    def = pp_getdef(pp, word);
    if (invert ^ (def != NULL))
    {
        I->skip = 0;
        I->skiprest = 1;
    }
    else
    {
        I->skip = 1;
    }
}

static void handle_else(struct preprocess *pp, ParseState *P)
{
#ifdef _MSC_VER
    (P); // stop warning
#endif

    struct ifstate *I = pp->ifs;

    if (!I)
    {
        domessage(pp, "error", "#else without matching #if");
        return;
    }
    if (I->sawelse)
    {
        domessage(pp, "error", "multiple #else statements in #if");
        return;
    }
    I->sawelse = 1;
    if (I->skiprest)
    {
        /* some branch was already handled */
        I->skip = 1;
    }
    else
    {
        I->skip = 0;
    }
}

static void handle_elseifdef(struct preprocess *pp, ParseState *P, int invert)
{
    struct ifstate *I = pp->ifs;
    char *word;
    const char *def;

    if (!I)
    {
        domessage(pp, "error", "#else without matching #if");
        return;
    }

    if (I->skiprest)
    {
        /* some branch was already handled */
        I->skip = 1;
        return;
    }
    word = parse_getwordafterspaces(P);
    def = pp_getdef(pp, word);
    if (invert ^ (def != NULL))
    {
        I->skip = 0;
        I->skiprest = 1;
    }
    else
    {
        I->skip = 1;
    }
}

static void handle_endif(struct preprocess *pp, ParseState *P)
{
#ifdef _MSC_VER
    (P); // stop warning
#endif

    struct ifstate *I = pp->ifs;

    if (!I)
    {
        domessage(pp, "error", "#endif without matching #if");
        return;
    }
    pp->ifs = I->next;
    free(I);
}

static void handle_message(struct preprocess *pp, ParseState *P, char *type)
{
    char *msg;
    if (!pp_active(pp))
    {
        return;
    }
    msg = parse_restofline(P);
    domessage(pp, type, "#%s: %s", type, msg);
}

static void handle_define(struct preprocess *pp, ParseState *P, int isDef)
{
    char *def;
    char *name;
    const char *oldvalue;
    struct flexbuf newdef;

    if (!pp_active(pp))
    {
        return;
    }
    name = parse_getwordafterspaces(P);
    if (classify_char(name[0]) != PARSE_IDCHAR)
    {
        domessage(pp, "error", "%s is not a valid identifier for define", name);
        return;
    }
    oldvalue = pp_getdef(pp, name);
    if (oldvalue && isDef)
    {
        domessage(pp, "warning", "redefining `%s'", name);
    }
    name = strdup(name);

    if (isDef)
    {
        parse_skipspaces(P);
        def = parse_restofline(P);
        flexbuf_init(&newdef, 80);
        expand_macros(pp, &newdef, def);
        def = flexbuf_get(&newdef);
    }
    else
    {
        def = NULL;
    }
    pp_define_internal(pp, name, def, PREDEF_FLAG_FREEDEFS);
}

static void handle_include(struct preprocess *pp, ParseState *P)
{
    char *name;
    if (!pp_active(pp))
    {
        return;
    }
    name = parse_getquotedstring(P);
    if (!name)
    {
        domessage(pp, "error", "no string found for include");
        return;
    }
    pp_push_file(pp, strdup(name));
}

/*
 * expand a line and process any directives
 */
static int do_line(struct preprocess *pp)
{
    char *data = flexbuf_get(&pp->line);
    char *func;
    int r;

    // skip over utf-8 BOM character
    int dataOffset = 0;
    if (data[0] == -17 && data[1] == -69 && data[2] == -65)
    {
        dataOffset = 3;
    }

    if (data[dataOffset] != '#' || pp->incomment)
    {
        r = expand_macros(pp, &pp->line, data);
    }
    else
    {
        ParseState P;
        parse_init(&P, data+1+dataOffset);
        parse_skipspaces(&P);
        func = parse_getword(&P);
        r = 0;
        if (!strcmp(func, "ifdef"))
        {
            handle_ifdef(pp, &P, 0);
        }
        else if (!strcmp(func, "ifndef"))
        {
            handle_ifdef(pp, &P, 1);
        }
        else if (!strcmp(func, "else"))
        {
            handle_else(pp, &P);
        }
        else if (!strcmp(func, "elseifdef"))
        {
            handle_elseifdef(pp, &P, 0);
        }
        else if (!strcmp(func, "elseifndef"))
        {
            handle_elseifdef(pp, &P, 1);
        }
        else if (!strcmp(func, "endif"))
        {
            handle_endif(pp, &P);
        }
        else if (!strcmp(func, "error"))
        {
            handle_message(pp, &P, "error");
            if (pp->alternate)
            {
                exit(1);
            }
        }
        else if (!strcmp(func, "warning") || !strcmp(func, "warn"))
        {
            handle_message(pp, &P, "warning");
        }
        else if (!strcmp(func, "info"))
        {
            handle_message(pp, &P, "info");
        }
        else if (!strcmp(func, "define"))
        {
            handle_define(pp, &P, 1);
        }
        else if (!strcmp(func, "undef"))
        {
            handle_define(pp, &P, 0);
        }
        else if (!strcmp(func, "include"))
        {
            handle_include(pp, &P);
        }
        else
        {
            //doerror(pp, "Unknown preprocessor directive `%s'", func);
            // because spin has the # as a valid part of it's syntax and that can be at the start of a line,
            // this isn't an error, but instead needs to be parsed like a normal line
            // first restore the line
            if (P.save)
            {
                *(P.save) = (char)(P.c);
            }
            r = expand_macros(pp, &pp->line, data);
        }
    }
    free(data);
    return r;
}

/*
 * main function
 */
void pp_run(struct preprocess *pp)
{
    int linelen;

    while (pp->fil)
    {
        for(;;)
        {
            linelen = pp_nextline(pp);
            if (linelen <= 0) break;  /* end of file */
            /* now expand directives and/or macros */
            linelen = do_line(pp);
            /* if the whole line should be skipped check_directives will return 0 */
            if (linelen == 0)
            {
                /* add a newline so line number errors will be correct */
                flexbuf_addchar(&pp->whole, '\n');
            }
            else
            {
                char *line = flexbuf_get(&pp->line);
                flexbuf_addstr(&pp->whole, line);
                free(line);
            }
        }
        pp_pop_file(pp);
    }
}

char* pp_finish(struct preprocess *pp)
{
    flexbuf_addchar(&pp->whole, 0);
    flexbuf_delete(&pp->line);
    return flexbuf_get(&pp->whole);
}

/*
 * set comment characters
 */
void pp_setcomments(struct preprocess *pp, const char *line, const char *start, const char *end)
{
    pp->linecomment = line;
    pp->startcomment = start;
    pp->endcomment = end;
}

/*
 * get/restore define state
 * this may be used to ensure that #defines in sub files are not
 * seen in the main file
 */
void* pp_get_define_state(struct preprocess *pp)
{
    return (void *)pp->defs;
}

void pp_restore_define_state(struct preprocess *pp, void *vp)
{
    struct predef *where = (struct predef *)vp;
    struct predef *x, *old;

    x = pp->defs;
    while (x && x != where)
    {
        old = x;
        x = old->next;
        if (old->flags & PREDEF_FLAG_FREEDEFS)
        {
            free((void *)old->name);
            if (old->def)
            {
                free((void *)old->def);
            }
        }
        free(old);
    }
    pp->defs = x;
}

void pp_clear_define_state(struct preprocess *pp)
{
    struct predef *x, *old;

    x = pp->defs;
    while (x)
    {
        old = x;
        x = old->next;
        if (old->flags & PREDEF_FLAG_FREEDEFS)
        {
            free((void *)old->name);
            if (old->def)
            {
                free((void *)old->def);
            }
        }
        free(old);
    }
    pp->defs = 0;
}

/*
 * +--------------------------------------------------------------------
 * ¦  TERMS OF USE: MIT License
 * +--------------------------------------------------------------------
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files
 * (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 * +--------------------------------------------------------------------
 */
