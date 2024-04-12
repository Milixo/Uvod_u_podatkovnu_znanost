/*

* Definicija skenera za COOL.

*/




/*

* Sadržaj između %{ %} u prvom dijelu se kopira doslovno u izlaz, pa su ovdje

* smještene zaglavlja i globalne definicije kako bi bile vidljive kodu u datoteci.

* Ne uklanjajte ništa što je ovdje bilo inicijalno.

*/

%option
noyywrap

%{

#include
<cool-parse.h>

#include
<stringtab.h>

#include
<utilities.h>




/* Kompajler pretpostavlja ove identifikatore. */

#define yylval cool_yylval

#define yylex  cool_yylex




/* Maksimalna veličina string konstanti */

#define MAX_STR_CONST
1025

#define YY_NO_UNPUT   /* čuva g++ zadovoljnim */




extern FILE
*fin; /* čitamo iz ove datoteke */




/* Definiraj YY_INPUT kako bismo čitali iz datoteke fin:

* Ova promjena omogućava upotrebu ovog skenera u COOL kompajleru.

*/

#undef YY_INPUT

#define YY_INPUT(buf,result,max_size)
\

   if ( (result
=
fread( (char*)buf, sizeof(char), max_size, fin))
<
0)
\

       YY_FATAL_ERROR(
"read() u flex skeneru nije uspio");




char
string_buf[MAX_STR_CONST]; /* za sastavljanje string konstanti */

char
*string_buf_ptr;




extern
int curr_lineno;

extern
int verbose_flag;

int commentLvl
=
0;




extern YYSTYPE cool_yylval;




/*

* Dodajte vlastite definicije ovdje

*/




int
checkValidStringLenght() {

   int lenght
= string_buf_ptr
- string_buf;

   if(lenght
>= MAX_STR_CONST)

       return
0;

   else

       return
1;

}

%}

%x STRING

%x COMMENT

%x RESET

/*

* Ovdje definirajte imena za regularne izraze.

*/




DARROW          =>

ASSIGN      <-

LE      <=

INT     [0-9]+

SPECIAL "+"|"-"|"*"|"/"|"~"|"<"|"="|"("|")"|"{"|"}"|"."|","|":"|";"|"@"

INVALID "!"|"#"|"$"|"%"|"^"|"&"|"_"|">"|"?"|"`"|"["|"]"|"\\"|"|"

CLASS       (C|c)(L|l)(A|a)(S|s)(S|s)

ELSE        (e|E)(l|L)(s|S)(e|E)

FI      (f|F)(i|I)

IF      (i|I)(f|F)

IN      (I|i)(N|n)

INHERITS    (i|I)(n|N)(h|H)(e|E)(r|R)(i|I)(t|T)(s|S)

ISVOID      (i|I)(s|S)(v|V)(o|O)(i|I)(d|D)

LET     (l|L)(E|e)(t|T)

LOOP        (l|L)(o|O)(o|O)(p|P)

POOL        (p|P)(o|O)(o|O)(l|L)

THEN        (t|T)(h|H)(e|E)(N|n)

WHILE       (w|W)(h|H)(i|I)(l|L)(e|E)

CASE        (c|C)(a|A)(s|S)(e|E)

ESAC        (e|E)(S|s)(A|a)(C|c)

NEW     (n|N)(e|E)(w|W)

OF      (o|O)(f|F)

NOT     (n|N)(o|O)(t|T)

TRUE        t(r|R)(u|U)(e|E)

FALSE       f(A|a)(l|L)(s|S)(e|E)

TYPE        [A-Z][A-Z|a-z|0-9|_]*

OBJECT      [a-z][A-Z|a-z|0-9|_]*

NEWLINE     "\n"

WHITESPACE  " "|"\f"|"\r"|"\t"|"\v"




BEGIN_COMMENT   "(*"

END_COMMENT     "*)"

DASH_COMMENT    --(.)*




STR     \"

NO_MATCH    .

%%




{END_COMMENT}      
{

               cool_yylval.error_msg
=
"Nepoklapanje *)";

               return (ERROR);

           }

{BEGIN_COMMENT}    
{ 

               commentLvl++;

               BEGIN(COMMENT);

           }

<COMMENT><<EOF>>    {

               BEGIN(INITIAL);

               cool_yylval.error_msg
=
"Kraj datoteke unutar komentara";

               return (ERROR);

           }

<COMMENT>{BEGIN_COMMENT}
{ commentLvl++; }

<COMMENT>\n    
{ curr_lineno++; }

<COMMENT>.      { }

<COMMENT>{END_COMMENT}  {

               commentLvl--;

               if(commentLvl
==
0) {

                   BEGIN(INITIAL);

               }

           }

{DASH_COMMENT}  { }

{CLASS}        
{ return (CLASS); }

{ELSE}      {
return (ELSE); }

{FI}            {
return (FI); }

{IF}            {
return (IF); }

{IN}            {
return (IN); }

{INHERITS}      {
return (INHERITS); }

{ISVOID}        {
return (ISVOID); }

{LET}          
{ return (LET); }

{LOOP}          {
return (LOOP); }

{POOL}          {
return (POOL); }

{THEN}          {
return (THEN); }

{WHILE}    
{ return (WHILE); }

{CASE}          {
return (CASE); }

{ESAC}          {
return (ESAC); }

{OF}            {
return (OF); }

{NEW}          
{ return (NEW); }

{NOT}          
{ return (NOT); }

{TRUE}      {

               cool_yylval.boolean
=
1;

               return (BOOL_CONST);

           }

{FALSE}        
{

               cool_yylval.boolean
=
0;

               return (BOOL_CONST);

           }

{NEWLINE}      
{ curr_lineno++; }

{WHITESPACE}        { }


{INT}          
{

               cool_yylval.symbol
=
inttable.add_string(yytext);

               return (INT_CONST);

           }      

{TYPE}          {

               cool_yylval.symbol
=
idtable.add_string(yytext);

               return (TYPEID);

           }

{OBJECT}        {

               cool_yylval.symbol
=
idtable.add_string(yytext);

               return (OBJECTID);

           }

{SPECIAL}      
{ return (yytext[0]);
 }

{INVALID}      
{ 

               cool_yylval.error_msg
= yytext;

               return (ERROR);

           }

{DARROW}        {
return (DARROW); }

{ASSIGN}        {
return (ASSIGN); }

{LE}            {
return (LE); }

{STR}          
{ 

           

               BEGIN(STRING);

               string_buf_ptr = string_buf;

           }

<STRING><<EOF>>    
{

               BEGIN(INITIAL);

               cool_yylval.error_msg
=
"Kraj datoteke unutar string konstante";

               return (ERROR);

           }

<STRING>{STR}      
{

               if(checkValidStringLenght()==0){

                       BEGIN(INITIAL);

                       *string_buf_ptr
=
'\0';

                       cool_yylval.error_msg
=
"String konstanta preduga";

                       return (ERROR);

                   }

               else {

                   BEGIN(INITIAL);

                   *string_buf_ptr
=
'\0';

                   cool_yylval.symbol
=                
stringtable.add_string(string_buf);            

                   return (STR_CONST);

               }

           }

<STRING>\0      {

               *string_buf
=
'\0';

               BEGIN(RESET);

               cool_yylval.error_msg
=
"String sadrži null znak";

               return (ERROR);

           }

<STRING>{NEWLINE}  
{

               *string_buf
=
'\0';

               BEGIN(INITIAL);

               cool_yylval.error_msg
=
"Nedovršena string konstanta";

               return (ERROR);

           }

<STRING>\\n        
{ *string_buf_ptr++
=
'\n'; }

<STRING>\\t        
{ *string_buf_ptr++
=
'\t'; }

<STRING>\\b        
{ *string_buf_ptr++
=
'\b'; }

<STRING>\\f        
{ *string_buf_ptr++
=
'\f'; }

<STRING>\\[^\0\r]  
{ *string_buf_ptr++
=
yytext[1]; }

<STRING>.      
{ *string_buf_ptr++
=
*yytext; }

<RESET>[\n"]        {
BEGIN(INITIAL); }

<RESET>[^\n"]      
{ }

{NO_MATCH}      {

               cool_yylval.error_msg
= yytext;

               return (ERROR);    

           }






%%  





