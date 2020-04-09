xquery version "1.0-ml";

module namespace lex = "http://graph.x.ql/lexer";

declare namespace s = "http://www.w3.org/2005/xpath-functions";

declare variable $SOF           := '<SOF>';
declare variable $EOF           := '<EOF>';
declare variable $NAME          := 'Name';
declare variable $INT           := 'Int';
declare variable $FLOAT         := 'Float';
declare variable $STRING        := 'String';
declare variable $COMMENT       := 'Comment';

declare variable $BANG-LABEL              := 'BANG';
declare variable $DOLLAR-LABEL            := 'DOLLAR';
declare variable $PAREN_L-LABEL           := 'PAREN_L';
declare variable $PAREN_R-LABEL           := 'PAREN_R';
declare variable $SPREAD-LABEL            := 'SPREAD';
declare variable $COLON-LABEL             := 'COLON';
declare variable $EQUALS-LABEL            := 'EQUALS';
declare variable $AT-LABEL                := 'AT';
declare variable $BRACKET_L-LABEL         := 'BRACKET_L';
declare variable $BRACKET_R-LABEL         := 'BRACKET_R';
declare variable $BRACE_L-LABEL           := 'BRACE_L';
declare variable $PIPE-LABEL              := 'PIPE';
declare variable $BRACE_R-LABEL           := 'BRACE_R';
declare variable $BooleanLiteral-LABEL    := 'BooleanLiteral';
declare variable $NAME-LABEL              := 'NAME';
declare variable $String_-LABEL           := 'String_';
declare variable $STRING-LABEL            := 'STRING';
declare variable $BLOCK_STRING-LABEL      := 'BLOCK_STRING';
declare variable $LABEL-LABEL             := 'LABEL';
declare variable $ESC-LABEL               := 'ESC';
declare variable $UNICODE-LABEL           := 'UNICODE';
declare variable $HEX-LABEL               := 'HEX';
declare variable $NUMBER-LABEL            := 'NUMBER';
declare variable $INT-LABEL               := 'INT';
declare variable $EXP-LABEL               := 'EXP';
declare variable $WS-LABEL                := 'WS';
declare variable $LineComment-LABEL       := 'LineComment';
declare variable $COMMA-LABEL             := 'COMMA';
declare variable $AMP-LABEL               := 'AMP';

declare variable $BANG-ID              := '1';
declare variable $DOLLAR-ID            := '2';
declare variable $PAREN_L-ID           := '3';
declare variable $PAREN_R-ID           := '4';
declare variable $SPREAD-ID            := '5';
declare variable $COLON-ID             := '6';
declare variable $EQUALS-ID            := '7';
declare variable $AT-ID                := '8';
declare variable $BRACKET_L-ID         := '9';
declare variable $BRACKET_R-ID         := '10';
declare variable $BRACE_L-ID           := '11';
declare variable $PIPE-ID              := '12';
declare variable $BRACE_R-ID           := '13';
declare variable $BooleanLiteral-ID    := '14';
declare variable $NAME-ID              := '15';
declare variable $BLOCK_STRING-ID      := '16';
declare variable $String_-ID           := '17';
declare variable $STRING-ID            := '18';
declare variable $ID-ID                := '19';
declare variable $ESC-ID               := '20';
declare variable $UNICODE-ID           := '21';
declare variable $HEX-ID               := '22';
declare variable $NUMBER-ID            := '23';
declare variable $INT-ID               := '24';
declare variable $EXP-ID               := '25';
declare variable $WS-ID                := '26';
declare variable $LineComment-ID       := '27';
declare variable $COMMA-ID             := '28';
declare variable $AMP-ID               := '29';

declare variable $BANG-REGEXP              := '!';
declare variable $DOLLAR-REGEXP            := '\$';
declare variable $PAREN_L-REGEXP           := '\(';
declare variable $PAREN_R-REGEXP           := '\)';
declare variable $SPREAD-REGEXP            := '\.\.\.';
declare variable $COLON-REGEXP             := ':';
declare variable $EQUALS-REGEXP            := '=';
declare variable $AT-REGEXP                := '@';
declare variable $BRACKET_L-REGEXP         := '\[';
declare variable $BRACKET_R-REGEXP         := '\]';
declare variable $BRACE_L-REGEXP           := '\{';
declare variable $PIPE-REGEXP              := '\|';
declare variable $BRACE_R-REGEXP           := '\}';
declare variable $BooleanLiteral-REGEXP    := "true|false";
declare variable $NAME-REGEXP              := "[_A-Za-z][_0-9A-Za-z]*";
declare variable $HEX-REGEXP               := "[0-9a-fA-F]";
declare variable $UNICODE-REGEXP           := 'u'||$HEX-REGEXP||$HEX-REGEXP||$HEX-REGEXP||$HEX-REGEXP;
declare variable $ESC-REGEXP               := '\\(["\\/bfnrt]|'||$UNICODE-REGEXP||')';
declare variable $BLOCK_STRING-REGEXP      := '"""[\W]*?.*?[\W]*?"""';
declare variable $STRING-REGEXP            := '('||$ESC-REGEXP||'|"[^"\\]*")';
declare variable $String_-REGEXP           := '('||$BLOCK_STRING-REGEXP||'|'||$STRING-REGEXP||')';
declare variable $ID-REGEXP                := $STRING-REGEXP;
declare variable $NUMBER-REGEXP            := "[+-]?(\d+([.]\d*)?(e[+-]?\d+)?|[.]\d+(e[+-]?\d+)?)";
(: declare variable $NUMBER-REGEXP            := fn:concat("-?",$INT-REGEXP, ".[0-9]+",$EXP-REGEXP,"?|-?",$INT-REGEXP, $EXP-REGEXP,"|-?", $INT-REGEXP);
declare variable $INT-REGEXP               := "0|[1-9][0-9]*";
declare variable $EXP-REGEXP               := fn:concat("[Ee][+\-]?",$INT-REGEXP); :)
declare variable $WS-REGEXP                := "[ \t\n\r]+";
declare variable $LineComment-REGEXP       := "#[^\r\n]*"; (:"# ~[\r\n]*";:)
declare variable $COMMA-REGEXP             := ",";
declare variable $AMP-REGEXP               := '&amp;';

declare variable $lexer-labels-map := map:map()
                => map:with($BANG-ID,$BANG-LABEL)
                => map:with($DOLLAR-ID,$DOLLAR-LABEL)
                => map:with($PAREN_L-ID,$PAREN_L-LABEL)
                => map:with($PAREN_R-ID,$PAREN_R-LABEL)
                => map:with($SPREAD-ID,$SPREAD-LABEL)
                => map:with($COLON-ID,$COLON-LABEL)
                => map:with($EQUALS-ID,$EQUALS-LABEL)
                => map:with($AT-ID,$AT-LABEL)
                => map:with($BRACKET_L-ID,$BRACKET_L-LABEL)
                => map:with($BRACKET_R-ID,$BRACKET_R-LABEL)
                => map:with($BRACE_L-ID,$BRACE_L-LABEL)
                => map:with($PIPE-ID,$PIPE-LABEL)
                => map:with($BRACE_R-ID,$BRACE_R-LABEL)
                => map:with($BooleanLiteral-ID,$BooleanLiteral-LABEL)
                => map:with($NAME-ID,$NAME-LABEL)
                => map:with($STRING-ID,$STRING-LABEL)
                => map:with($String_-ID,$String_-LABEL)
                => map:with($NUMBER-ID,$NUMBER-LABEL)
                => map:with($WS-ID,$WS-LABEL)
                => map:with($LineComment-ID,$LineComment-LABEL)
                => map:with($COMMA-ID,$COMMA-LABEL)
                => map:with($BLOCK_STRING-ID,$BLOCK_STRING-LABEL)
                => map:with($AMP-ID, $AMP-LABEL);

declare variable $lexer-regex-map := map:map()
                => map:with($BANG-ID,$BANG-REGEXP)
                => map:with($DOLLAR-ID,$DOLLAR-REGEXP)
                => map:with($PAREN_L-ID,$PAREN_L-REGEXP)
                => map:with($PAREN_R-ID,$PAREN_R-REGEXP)
                => map:with($SPREAD-ID,$SPREAD-REGEXP)
                => map:with($COLON-ID,$COLON-REGEXP)
                => map:with($EQUALS-ID,$EQUALS-REGEXP)
                => map:with($AT-ID,$AT-REGEXP)
                => map:with($BRACKET_L-ID,$BRACKET_L-REGEXP)
                => map:with($BRACKET_R-ID,$BRACKET_R-REGEXP)
                => map:with($BRACE_L-ID,$BRACE_L-REGEXP)
                => map:with($PIPE-ID,$PIPE-REGEXP)
                => map:with($BRACE_R-ID,$BRACE_R-REGEXP)
                => map:with($BooleanLiteral-ID,$BooleanLiteral-REGEXP)
                => map:with($NAME-ID,$NAME-REGEXP)
                => map:with($STRING-ID,$STRING-REGEXP)
                => map:with($NUMBER-ID,$NUMBER-REGEXP)
                => map:with($WS-ID,$WS-REGEXP)
                => map:with($LineComment-ID,$LineComment-REGEXP)
                => map:with($COMMA-ID,$COMMA-REGEXP)
                => map:with($BLOCK_STRING-ID,$BLOCK_STRING-REGEXP)
                => map:with($AMP-ID, $AMP-REGEXP);
                (: => map:with($String_-ID,$String_-REGEXP) :)
                (: => map:with($ID-ID,$ID-REGEXP) :)
                (: => map:with($ESC-ID,$ESC-REGEXP) :)
                (: => map:with($UNICODE-ID,$UNICODE-REGEXP) :)
                (: => map:with($HEX-ID,$HEX-REGEXP) :)
                (: => map:with($INT-ID,$INT-REGEXP) :)
                (: => map:with($EXP-ID,$EXP-REGEXP) :)

declare variable $SKIP := ($WS-LABEL, $LineComment-LABEL, $BLOCK_STRING-LABEL, $COMMA-LABEL);

declare variable $TOKEN-SOF := <token key="" type="{$SOF}" value=""/>;
declare variable $TOKEN-EOF := <token key="" type="{$EOF}" value=""/>;

declare variable $KEYS := 
  for $key in map:keys($lexer-regex-map)
    order by xs:int($key) ascending
    return xs:int($key);

declare function lex:next-map-key($current-key as xs:int) as xs:int{
  fn:head(($KEYS[. gt $current-key], 0))
};

declare function lex:match($string as xs:string){
  lex:match($string, 1)
};

declare function lex:match($string as xs:string, $key as xs:int) as node()?
{
  (: 
    recursive approach since matching rules are sorted according to grammar precedence 
    so that only first match needs to be considered. 
  :)
  let $regex := map:get($lexer-regex-map,xs:string($key))
  let $token := fn:analyze-string($string, '^('||$regex||')', '')/s:match
  return 
    if (fn:exists($token)) 
    then <token key="{$key}" type="{map:get($lexer-labels-map, xs:string($key))}" value="{$token}"/> 
    else 
      let $next-key := lex:next-map-key($key)
      return
        if ($next-key gt 0)  (: somewhat artificial exit condition to avoid endless recursion :)
        then lex:match($string, $next-key)
        else ()
};

declare function lex:tokenize($string as xs:string) 
{
  let $_ := xdmp:log('lex:tokenize: '||$string, 'debug')
  let $matches := ()
  let $lines := fn:tokenize($string, '\n')
  let $_ :=
    for $i in (1 to fn:count($lines))
    where $lines[$i] (: ignore empty lines :)
    return
      xdmp:set($matches, ($matches, lex:tokenize($lines[$i], $i, 1, ())))
  return $matches
};

declare function lex:tokenize($string as xs:string, $line-number as xs:int, $column-number as xs:int, $matches as node()*) as node()*
{
  let $match := lex:match($string)
  let $_ := 
    if (not($match)) 
    then fn:error((), 'TOKENIZER EXCEPTION', ("500", "Internal server error", "unable to tokenize input: "||$string)) 
    else ()
  
  let $match := <token key="{$match/@key}" type="{$match/@type}" value="{$match/@value}" line="{$line-number}" column="{$column-number}"/> (: TODO: refactor!:)
  let $matches := ($matches, $match)
  let $column-number := $column-number + fn:string-length($match/@value)
  let $string := fn:substring-after($string, $match/@value/string())
  return
    if (fn:string-length($string) > 0) 
    then lex:tokenize($string, $line-number, $column-number, $matches)
    else $matches
};  

declare function lex:get-tokens($result as node()*) as node()*
{
  (
    $TOKEN-SOF
    ,$result[not(./@type/string() = $SKIP)]
    ,$TOKEN-EOF
  )
};
