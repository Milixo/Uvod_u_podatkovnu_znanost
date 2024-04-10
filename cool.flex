%{
#include &lt;cool-parse.h&gt;
#include &lt;stringtab.h&gt;
#include &lt;utilities.h&gt;
/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex cool_yylex
/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT /* keep g++ happy */
extern FILE *fin; /* we read from this file */
/* define YY_INPUT so we read from the FILE fin:
* This change makes it possible to use this scanner in
* the Cool compiler.
*/
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) &lt; 0) \
YY_FATAL_ERROR( &quot;read() in flex scanner failed&quot;);
char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_pt;
extern int curr_lineno;
extern int verbose_flag;
extern YYSTYPE cool_yylval;
/*
* Add Your own definitions here
*/
int nCom = 0;
%}
WHITESPACE [ \n \f \v \t \r ]
INTEGER [0-9]+
TYPE [A-Z][a-zA-Z0-9_]*
OBJECT [a-z][a-zA-Z0-9_]*

INVALID &quot;!&quot;|&quot;#&quot;|&quot;$&quot;|&quot;%&quot;|&quot;&amp;&quot;|&quot;[&quot;|&quot;]&quot;|&quot;|&quot;|[\\]|&quot;_&quot;|&quot;?&quot;|&quot;`&quot;|&quot;^&quot;

%x string
%x comment
%x string_error

%%

{WHITESPACE}+ ;
\n {curr_lineno++;}
&quot;--&quot;.* {}
&quot;--&quot;.*\n {curr_lineno++;}
&quot;*)&quot; {

cool_yylval.error_msg = &quot;Unmached *)&quot;;
return (ERROR);
}
&quot;(*&quot; {

nCom++;
BEGIN(comment);
}
&lt;comment&gt;&quot;*)&quot; {
nCom--;
if(nCom == 0)
BEGIN(INITIAL);
}
&lt;comment&gt;&quot;(*&quot; nCom++;
&lt;comment&gt;\n ++curr_lineno;
&lt;comment&gt;.
&lt;comment&gt;{WHITESPACE}+
&lt;comment&gt;&lt;&lt;EOF&gt;&gt; {
BEGIN(INITIAL);
if(nCom &gt; 0)
{
nCom = 0;
cool_yylval.error_msg = &quot;EOF in comment.&quot;;
return (ERROR);
}
}
&quot;\&quot;&quot; {

BEGIN(string);
string_buf_pt = string_buf;
}
&lt;string&gt;&quot;\&quot;&quot; {
if((string_buf_pt - string_buf) &gt;= MAX_STR_CONST)
{
*string_buf = &#39;\0&#39;;
cool_yylval.error_msg = &quot;String constant too long.&quot;;

BEGIN(INITIAL);
return (ERROR);
}
*string_buf_pt = &#39;\0&#39;;
&lt;string&gt;\0 {
cool_yylval.error_msg = &quot;String contains null character.&quot;;
BEGIN(string_error);
return (ERROR);
}
&lt;string&gt;\\\0 {
cool_yylval.error_msg = &quot;String contains escaped null character.&quot;;
string_buf[0] = &#39;\0&#39;;
BEGIN(string_error);
return (ERROR);
}
&lt;string&gt;\n {
curr_lineno++;
BEGIN(INITIAL);
cool_yylval.error_msg = &quot;Undetermined string constant.&quot;;
return (ERROR);
}
&lt;string&gt;&lt;&lt;EOF&gt;&gt; {
cool_yylval.error_msg = &quot;EOF in string costant.&quot;;
BEGIN(INITIAL);
return (ERROR);
}
&lt;string&gt;&quot;\\n&quot; {
*string_buf_pt++ = &#39;\n&#39;;
}
&lt;string&gt;&quot;\\t&quot; {
*string_buf_pt++ = &#39;\t&#39;;
}
&lt;string&gt;&quot;\\f&quot; {
*string_buf_pt++ = &#39;\f&#39;;
}
&lt;string&gt;&quot;\\v&quot; {
*string_buf_pt++ = &#39;\v&#39;;
}
&lt;string&gt;&quot;\\r&quot; {
*string_buf_pt++ = &#39;\r&#39;;
}
&lt;string&gt;. {

*string_buf_pt++ = *yytext;
}
&lt;string&gt;&quot;\\&quot;[^ntbf] {

*string_buf_pt++ = yytext[1];
}

(?i:class) return CLASS;
(?i:else) return ELSE;
(?i:fi) return FI;
(?i:if) return IF;
(?i:in) return IN;
(?i:inherits) return INHERITS;
(?i:isvoid) return ISVOID;
(?i:let) return LET;
(?i:loop) return LOOP;
(?i:pool) return POOL;
(?i:while) return WHILE;
(?i:then) return THEN;
(?i:esac) return ESAC;
(?i:case) return CASE;
(?i:new) return NEW;
(?i:of) return OF;
(?i:not) return NOT;
&quot;;&quot; {return int(&#39;;&#39;);}
&quot;:&quot; {return int(&#39;:&#39;);}
&quot;(&quot; {return int(&#39;(&#39;);}
&quot;)&quot; {return int(&#39;)&#39;);}
&quot;{&quot; {return int(&#39;{&#39;);}
&quot;}&quot; {return int(&#39;}&#39;);}
&quot;/&quot; {return int(&#39;/&#39;);}
&quot;*&quot; {return int(&#39;*&#39;);}
&quot;-&quot; {return int(&#39;-&#39;);}
&quot;+&quot; {return int(&#39;+&#39;);}
&quot;.&quot; {return int(&#39;.&#39;);}
&quot;,&quot; {return int(&#39;,&#39;);}
&quot;=&quot; {return int(&#39;=&#39;);}
&quot;~&quot; {return int(&#39;~&#39;);}
&quot;&lt;&quot; {return int(&#39;&lt;&#39;);}
&quot;@&quot; {return int(&#39;@&#39;);}

t[rR][uU][eE] {
cool_yylval.boolean = true;
return BOOL_CONST;
}
f[aA][lL][sS][eE] {
cool_yylval.boolean = false;

return BOOL_CONST;
}
{TYPE} {
cool_yylval.symbol = idtable.add_string(yytext);
return TYPEID;
}
{OBJECT} {
cool_yylval.symbol = idtable.add_string(yytext);
return OBJECTID;
}
{INTEGER} {
cool_yylval.symbol = inttable.add_string(yytext);
return (INT_CONST);
}
{INVALID} {
cool_yylval.error_msg = yytext;
return (ERROR);
}
&lt;string_error&gt;\&quot; {
BEGIN(INITIAL);
}
&lt;string_error&gt;\n {
curr_lineno++;
BEGIN(INITIAL);
}
&lt;string_error&gt;. {}

. {

cool_yylval.error_msg = yytext;
return (ERROR);
}

%%
