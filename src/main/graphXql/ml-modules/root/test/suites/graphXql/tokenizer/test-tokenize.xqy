xquery version "1.0-ml";

import module namespace lex = "http://graph.x.ql/lexer" at "/graphXql/lexer.xqy";
import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";

declare namespace s = "http://www.w3.org/2005/xpath-functions";

declare function local:get-tokens($result as map:map){
    
    for $key in map:keys($result)
    let $token := xdmp:unquote(map:get($result, $key))
    where (not($token/token/@type/string() = ("WS","LineComment", "BLOCK_STRING")))
    order by xs:int($key) ascending
    return $token/token

};

let $matches := map:map()
let $string := '{
  hero {
    name
    # Queries can have comments!
  }
}'
let $tokens := lex:tokenize($string) 
                 => lex:get-tokens() 

return (
    test:assert-equal(8,fn:count($tokens))

    ,test:assert-equal('<SOF>', $tokens[1]/@type/string())
    ,test:assert-equal('', $tokens[1]/@value/string())

    ,test:assert-equal('BRACE_L', $tokens[2]/@type/string())
    ,test:assert-equal('{', $tokens[2]/@value/string())

    ,test:assert-equal('NAME', $tokens[3]/@type/string())
    ,test:assert-equal('hero', $tokens[3]/@value/string())

    ,test:assert-equal('BRACE_L', $tokens[4]/@type/string())
    ,test:assert-equal('{', $tokens[4]/@value/string())

    ,test:assert-equal('NAME', $tokens[5]/@type/string())
    ,test:assert-equal('name', $tokens[5]/@value/string())

    ,test:assert-equal('BRACE_R', $tokens[6]/@type/string())
    ,test:assert-equal('}', $tokens[6]/@value/string())

    ,test:assert-equal('BRACE_R', $tokens[7]/@type/string())
    ,test:assert-equal('}', $tokens[7]/@value/string())

    ,test:assert-equal('<EOF>', $tokens[8]/@type/string())
    ,test:assert-equal('', $tokens[8]/@value/string())
)
,
let $matches := map:map()
let $string := '
{
  human(id: "1000") {
    name
    height(unit: FOOT)
  }
}
'
let $tokens := lex:tokenize($string) 
                 => lex:get-tokens() 

return (
   test:assert-equal(19,fn:count($tokens))

  ,test:assert-equal('<SOF>', $tokens[1]/@type/string())
  ,test:assert-equal('', $tokens[1]/@value/string())

  ,test:assert-equal('BRACE_L', $tokens[2]/@type/string())
  ,test:assert-equal('{', $tokens[2]/@value/string())

  ,test:assert-equal('NAME', $tokens[3]/@type/string())
  ,test:assert-equal('human', $tokens[3]/@value/string())

  ,test:assert-equal('PAREN_L', $tokens[4]/@type/string())
  ,test:assert-equal('(', $tokens[4]/@value/string())

  ,test:assert-equal('NAME', $tokens[5]/@type/string())
  ,test:assert-equal('id', $tokens[5]/@value/string())

  ,test:assert-equal('COLON', $tokens[6]/@type/string())
  ,test:assert-equal(':', $tokens[6]/@value/string())

  ,test:assert-equal('STRING', $tokens[7]/@type/string())
  ,test:assert-equal('"1000"', $tokens[7]/@value/string())

  ,test:assert-equal('PAREN_R', $tokens[8]/@type/string())
  ,test:assert-equal(')', $tokens[8]/@value/string())

  ,test:assert-equal('BRACE_L', $tokens[9]/@type/string())
  ,test:assert-equal('{', $tokens[9]/@value/string())

  ,test:assert-equal('NAME', $tokens[10]/@type/string())
  ,test:assert-equal('name', $tokens[10]/@value/string())

  ,test:assert-equal('NAME', $tokens[11]/@type/string())
  ,test:assert-equal('height', $tokens[11]/@value/string())

  ,test:assert-equal('PAREN_L', $tokens[12]/@type/string())
  ,test:assert-equal('(', $tokens[12]/@value/string())

  ,test:assert-equal('NAME', $tokens[13]/@type/string())
  ,test:assert-equal('unit', $tokens[13]/@value/string())

  ,test:assert-equal('COLON', $tokens[14]/@type/string())
  ,test:assert-equal(':', $tokens[14]/@value/string())

  ,test:assert-equal('NAME', $tokens[15]/@type/string())
  ,test:assert-equal('FOOT', $tokens[15]/@value/string())

  ,test:assert-equal('PAREN_R', $tokens[16]/@type/string())
  ,test:assert-equal(')', $tokens[16]/@value/string())

  ,test:assert-equal('BRACE_R', $tokens[17]/@type/string())
  ,test:assert-equal('}', $tokens[17]/@value/string())

  ,test:assert-equal('BRACE_R', $tokens[18]/@type/string())
  ,test:assert-equal('}', $tokens[18]/@value/string())

  ,test:assert-equal('<EOF>', $tokens[19]/@type/string())
  ,test:assert-equal('', $tokens[19]/@value/string())
)
,
let $matches := map:map()
let $string := '
{
  empireHero: hero(episode: EMPIRE) {
    name
  }
  jediHero: hero(episode: JEDI) {
    name
  }
}
'
let $tokens := lex:tokenize($string) 
                 => lex:get-tokens() 

return (
   test:assert-equal(26,fn:count($tokens))

  ,test:assert-equal('<SOF>', $tokens[1]/@type/string())
  ,test:assert-equal('', $tokens[1]/@value/string())

  ,test:assert-equal('BRACE_L', $tokens[2]/@type/string())
  ,test:assert-equal('{', $tokens[2]/@value/string())

  ,test:assert-equal('NAME', $tokens[3]/@type/string())
  ,test:assert-equal('empireHero', $tokens[3]/@value/string())

  ,test:assert-equal('COLON', $tokens[4]/@type/string())
  ,test:assert-equal(':', $tokens[4]/@value/string())

  ,test:assert-equal('NAME', $tokens[5]/@type/string())
  ,test:assert-equal('hero', $tokens[5]/@value/string())

  ,test:assert-equal('PAREN_L', $tokens[6]/@type/string())
  ,test:assert-equal('(', $tokens[6]/@value/string())

  ,test:assert-equal('NAME', $tokens[7]/@type/string())
  ,test:assert-equal('episode', $tokens[7]/@value/string())

  ,test:assert-equal('COLON', $tokens[8]/@type/string())
  ,test:assert-equal(':', $tokens[8]/@value/string())

  ,test:assert-equal('NAME', $tokens[9]/@type/string())
  ,test:assert-equal('EMPIRE', $tokens[9]/@value/string())

  ,test:assert-equal('PAREN_R', $tokens[10]/@type/string())
  ,test:assert-equal(')', $tokens[10]/@value/string())

  ,test:assert-equal('BRACE_L', $tokens[11]/@type/string())
  ,test:assert-equal('{', $tokens[11]/@value/string())

  ,test:assert-equal('NAME', $tokens[12]/@type/string())
  ,test:assert-equal('name', $tokens[12]/@value/string())

  ,test:assert-equal('BRACE_R', $tokens[13]/@type/string())
  ,test:assert-equal('}', $tokens[13]/@value/string())

  ,test:assert-equal('NAME', $tokens[14]/@type/string())
  ,test:assert-equal('jediHero', $tokens[14]/@value/string())

  ,test:assert-equal('COLON', $tokens[15]/@type/string())
  ,test:assert-equal(':', $tokens[15]/@value/string())

  ,test:assert-equal('NAME', $tokens[16]/@type/string())
  ,test:assert-equal('hero', $tokens[16]/@value/string())

  ,test:assert-equal('PAREN_L', $tokens[17]/@type/string())
  ,test:assert-equal('(', $tokens[17]/@value/string())

  ,test:assert-equal('NAME', $tokens[18]/@type/string())
  ,test:assert-equal('episode', $tokens[18]/@value/string())

  ,test:assert-equal('COLON', $tokens[19]/@type/string())
  ,test:assert-equal(':', $tokens[19]/@value/string())

  ,test:assert-equal('NAME', $tokens[20]/@type/string())
  ,test:assert-equal('JEDI', $tokens[20]/@value/string())

  ,test:assert-equal('PAREN_R', $tokens[21]/@type/string())
  ,test:assert-equal(')', $tokens[21]/@value/string())

  ,test:assert-equal('BRACE_L', $tokens[22]/@type/string())
  ,test:assert-equal('{', $tokens[22]/@value/string())

  ,test:assert-equal('NAME', $tokens[23]/@type/string())
  ,test:assert-equal('name', $tokens[23]/@value/string())

  ,test:assert-equal('BRACE_R', $tokens[24]/@type/string())
  ,test:assert-equal('}', $tokens[24]/@value/string())

  ,test:assert-equal('BRACE_R', $tokens[25]/@type/string())
  ,test:assert-equal('}', $tokens[25]/@value/string())

  ,test:assert-equal('<EOF>', $tokens[26]/@type/string())
  ,test:assert-equal('', $tokens[26]/@value/string())

)
,
let $matches := map:map()
let $string := '
mutation CreateParticipant($event: String!, $participant: String!) {
  event(id: $event) {
    title
    participants { name }
 }
}
'
let $tokens := lex:tokenize($string) 
                 => lex:get-tokens() 

return (
   test:assert-equal(32,fn:count($tokens))

  ,test:assert-equal('<SOF>', $tokens[1]/@type/string())
  ,test:assert-equal('', $tokens[1]/@value/string())

  ,test:assert-equal('NAME', $tokens[2]/@type/string())
  ,test:assert-equal('mutation', $tokens[2]/@value/string())

  ,test:assert-equal('NAME', $tokens[3]/@type/string())
  ,test:assert-equal('CreateParticipant', $tokens[3]/@value/string())

  ,test:assert-equal('PAREN_L', $tokens[4]/@type/string())
  ,test:assert-equal('(', $tokens[4]/@value/string())

  ,test:assert-equal('DOLLAR', $tokens[5]/@type/string())
  ,test:assert-equal('$', $tokens[5]/@value/string())

  ,test:assert-equal('NAME', $tokens[6]/@type/string())
  ,test:assert-equal('event', $tokens[6]/@value/string())

  ,test:assert-equal('COLON', $tokens[7]/@type/string())
  ,test:assert-equal(':', $tokens[7]/@value/string())

  ,test:assert-equal('NAME', $tokens[8]/@type/string())
  ,test:assert-equal('String', $tokens[8]/@value/string())

  ,test:assert-equal('BANG', $tokens[9]/@type/string())
  ,test:assert-equal('!', $tokens[9]/@value/string())

  ,test:assert-equal('DOLLAR', $tokens[10]/@type/string())
  ,test:assert-equal('$', $tokens[10]/@value/string())

  ,test:assert-equal('NAME', $tokens[11]/@type/string())
  ,test:assert-equal('participant', $tokens[11]/@value/string())

  ,test:assert-equal('COLON', $tokens[12]/@type/string())
  ,test:assert-equal(':', $tokens[12]/@value/string())

  ,test:assert-equal('NAME', $tokens[13]/@type/string())
  ,test:assert-equal('String', $tokens[13]/@value/string())

  ,test:assert-equal('BANG', $tokens[14]/@type/string())
  ,test:assert-equal('!', $tokens[14]/@value/string())

  ,test:assert-equal('PAREN_R', $tokens[15]/@type/string())
  ,test:assert-equal(')', $tokens[15]/@value/string())

  ,test:assert-equal('BRACE_L', $tokens[16]/@type/string())
  ,test:assert-equal('{', $tokens[16]/@value/string())

  ,test:assert-equal('NAME', $tokens[17]/@type/string())
  ,test:assert-equal('event', $tokens[17]/@value/string())

  ,test:assert-equal('PAREN_L', $tokens[18]/@type/string())
  ,test:assert-equal('(', $tokens[18]/@value/string())

  ,test:assert-equal('NAME', $tokens[19]/@type/string())
  ,test:assert-equal('id', $tokens[19]/@value/string())

  ,test:assert-equal('COLON', $tokens[20]/@type/string())
  ,test:assert-equal(':', $tokens[20]/@value/string())

  ,test:assert-equal('DOLLAR', $tokens[21]/@type/string())
  ,test:assert-equal('$', $tokens[21]/@value/string())

  ,test:assert-equal('NAME', $tokens[22]/@type/string())
  ,test:assert-equal('event', $tokens[22]/@value/string())

  ,test:assert-equal('PAREN_R', $tokens[23]/@type/string())
  ,test:assert-equal(')', $tokens[23]/@value/string())

  ,test:assert-equal('BRACE_L', $tokens[24]/@type/string())
  ,test:assert-equal('{', $tokens[24]/@value/string())

  ,test:assert-equal('NAME', $tokens[25]/@type/string())
  ,test:assert-equal('title', $tokens[25]/@value/string())

  ,test:assert-equal('NAME', $tokens[26]/@type/string())
  ,test:assert-equal('participants', $tokens[26]/@value/string())

  ,test:assert-equal('BRACE_L', $tokens[27]/@type/string())
  ,test:assert-equal('{', $tokens[27]/@value/string())

  ,test:assert-equal('NAME', $tokens[28]/@type/string())
  ,test:assert-equal('name', $tokens[28]/@value/string())

  ,test:assert-equal('BRACE_R', $tokens[29]/@type/string())
  ,test:assert-equal('}', $tokens[29]/@value/string())

  ,test:assert-equal('BRACE_R', $tokens[30]/@type/string())
  ,test:assert-equal('}', $tokens[30]/@value/string())

  ,test:assert-equal('BRACE_R', $tokens[31]/@type/string())
  ,test:assert-equal('}', $tokens[31]/@value/string())

  ,test:assert-equal('<EOF>', $tokens[32]/@type/string())
  ,test:assert-equal('', $tokens[32]/@value/string())
)
