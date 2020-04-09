xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare variable $RULE := 'VARIABLES-ARE-INPUT-TYPES';

(: VALID INPUT TYPES :)
let $query := 
'
query Foo($a: String, $b: [Boolean!]!, $c: ComplexInput) {
    field(a: $a, b: $b, c: $c)
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)

return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: INVALID OUTPUT TYPES :)
let $query := 
'
query Foo($a: Dog, $b: [[DogOrHuman!]]!, $c: Pet) {
    field(a: $a, b: $b, c: $c)
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)

let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VARIABLES-ARE-INPUT-TYPES", "message":"Variable [a] cannot be non-input type [Dog]", "locations":[{"line":2, "column":12}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"VARIABLES-ARE-INPUT-TYPES", "message":"Variable [b] cannot be non-input type [DogOrHuman]", "locations":[{"line":2, "column":21}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"VARIABLES-ARE-INPUT-TYPES", "message":"Variable [c] cannot be non-input type [Pet]", "locations":[{"line":2, "column":43}]}'))
)
return
(
    test:assert-equal(3, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[Dog]')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[DogOrHuman]')])
    ,test:assert-equal($expected[3]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[Pet]')])
)


