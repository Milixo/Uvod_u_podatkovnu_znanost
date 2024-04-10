%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_pt;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

int nCom = 0;

%}

WHITESPACE	[ \n \f \v \t \r ]

INTEGER		[0-9]+
TYPE		[A-Z][a-zA-Z0-9_]*
OBJECT	 	[a-z][a-zA-Z0-9_]*
	
	
INVALID 	"!"|"#"|"$"|"%"|"&"|"["|"]"|"|"|[\\]|"_"|"?"|"`"|"^"
	

%x string
%x comment
%x string_error


%%



{WHITESPACE}+ 	;
\n		    {curr_lineno++;}

	
"--".*	    {}
"--".*\n    {curr_lineno++;}
	
"*)"	{
		cool_yylval.error_msg = "Unmached *)";
		return (ERROR);
		}

"(*"    {
		nCom++;
		BEGIN(comment);
		}

<comment>"*)"	{
                nCom--;
                if(nCom == 0)
                    BEGIN(INITIAL);
                }

<comment>"(*"	nCom++;
<comment>\n	++curr_lineno;
<comment>.
<comment>{WHITESPACE}+
<comment><<EOF>>    {
                    BEGIN(INITIAL);
                    if(nCom > 0)
                        {
                        nCom = 0;
                        cool_yylval.error_msg = "EOF in comment.";
                        return (ERROR);
                        }
                    }

"\""    {
		BEGIN(string);
		string_buf_pt = string_buf;	
		}

<string>"\""	{
                if((string_buf_pt - string_buf) >= MAX_STR_CONST)
                    {
                    *string_buf = '\0';
                    cool_yylval.error_msg = "String constant too long.";
                    BEGIN(INITIAL);
                    return (ERROR);
                    }
                *string_buf_pt = '\0';
                
                
<string>\0	    {
                cool_yylval.error_msg = "String contains null character.";
                BEGIN(string_error);
                return (ERROR);
		        }

<string>\\\0	{
                cool_yylval.error_msg = "String contains escaped null character.";
                string_buf[0] = '\0';
                BEGIN(string_error);
                return (ERROR);
		        }

<string>\n	    {
                curr_lineno++;
                BEGIN(INITIAL);
                cool_yylval.error_msg = "Undetermined string constant.";
                return (ERROR);
                }

<string><<EOF>> {
                cool_yylval.error_msg = "EOF in string costant.";
                BEGIN(INITIAL);
                return (ERROR);
		        }

<string>"\\n"	{
                *string_buf_pt++ = '\n';
                }

<string>"\\t"	{
                *string_buf_pt++ = '\t';
                }

<string>"\\f"	{
                *string_buf_pt++ = '\f';
                }

<string>"\\v"	{
                *string_buf_pt++ = '\v';
                }

<string>"\\r"	{
                *string_buf_pt++ = '\r';
                }

<string>.	    {
                *string_buf_pt++ = *yytext;
                }

<string>"\\"[^ntbf]	{
			        *string_buf_pt++ = yytext[1];
		            }



(?i:class)		    return CLASS;
(?i:else)		    return ELSE;
(?i:fi)			    return FI;
(?i:if)			    return IF;
(?i:in)			    return IN;
(?i:inherits)		return INHERITS;
(?i:isvoid)		    return ISVOID;
(?i:let)		    return LET;
(?i:loop)		    return LOOP;
(?i:pool)		    return POOL;
(?i:while)		    return WHILE;
(?i:then)		    return THEN;
(?i:esac)		    return ESAC;
(?i:case) 	    return CASE;
(?i:new)		    return NEW;
(?i:of)			    return OF;
(?i:not) 		    return NOT;

";"		{return int(';');}
":"		{return int(':');}
"("		{return int('(');}
")"		{return int(')');}
"{"		{return int('{');}
"}"		{return int('}');}
"/"		{return int('/');}
"*"		{return int('*');}
"-"		{return int('-');}
"+"		{return int('+');}
"."		{return int('.');}
","		{return int(',');}
"="		{return int('=');}
"~"		{return int('~');}
"<"		{return int('<');}
"@"		{return int('@');}



t[rR][uU][eE]	{
                cool_yylval.boolean = true;
                return BOOL_CONST;
                }

f[aA][lL][sS][eE]	{
                    cool_yylval.boolean = false;
                    return BOOL_CONST;
                    }

{TYPE}	{
            cool_yylval.symbol = idtable.add_string(yytext);
            return TYPEID;
            }

{OBJECT}		{
            cool_yylval.symbol = idtable.add_string(yytext);
            return OBJECTID;
            }

{INTEGER}	{
            cool_yylval.symbol = inttable.add_string(yytext);
            return (INT_CONST);
            }
	
{INVALID}	{
            cool_yylval.error_msg = yytext;
            return (ERROR);
            }


<string_error>\"  {
                BEGIN(INITIAL);
	            }

<string_error>\n  {
	            curr_lineno++;
                BEGIN(INITIAL);
	            }

<string_error>. {}


. 		{
		cool_yylval.error_msg = yytext;
		return (ERROR);
		}

%%

