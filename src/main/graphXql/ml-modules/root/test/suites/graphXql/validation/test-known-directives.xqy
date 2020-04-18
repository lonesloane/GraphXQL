xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare variable $RULE := 'KNOWN-DIRECTIVE';

(: WITH NO DIRECTIVE :)
let $query := 
'
query Foo {
    name
    ...Frag
}

fragment Frag on Person {
    name
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: WITH KNOWN DIRECTIVES :)
let $query := 
'
{
    hero @include(if: true) {
        name
    }
    human @skip(if: false) {
        name
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: WITH UNKNOWN DIRECTIVES :)
let $query := 
'
{
    hero @unknown(directive: "value") {
        name
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-DIRECTIVE", "message":"Unknown directive [@unknown].", "locations":[{"line":3, "column":11}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'unknown')])
)
,
(: WITH MANY UNKNOWN DIRECTIVES :)
let $query := 
'
{
    hero @unknown1(directive: "value") {
        name
    }
    event @unknown2(directive: "value") {
        title
        participants @unknown3(directive: "value") {
            name
        }
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-DIRECTIVE", "message":"Unknown directive [@unknown1].", "locations":[{"line":3, "column":11}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-DIRECTIVE", "message":"Unknown directive [@unknown2].", "locations":[{"line":6, "column":12}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-DIRECTIVE", "message":"Unknown directive [@unknown3].", "locations":[{"line":8, "column":23}]}'))
)
return
(
    test:assert-equal(3, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'unknown1')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'unknown2')])
    ,test:assert-equal($expected[3]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'unknown3')])
)
,
(: WITH WELL PLACED DIRECTIVES :)
let $query := 
'
query Foo($var: Boolean) @onQuery {
    name @include(if: $var)
    ...Frag @include(if: true)
    skippedField @skip(if: true)
    ...SkippedFrag @skip(if: true)
}

mutation Bar @onMutation {
    someField
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: WITH WELL PLACED VARIABLE DEFINITION DIRECTIVES :)
let $query := 
'
query person($id: Int @onVariableDefinition){
    name
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: WITH MISPLACED DIRECTIVES :)
let $query := 
'
query Foo($var: Boolean) @include(if: true) {
    name @onQuery @include(if: $var)
    ...Frag @onQuery
}

mutation Bar @onQuery {
    someField
}'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-DIRECTIVE", "message":"Directive [include] may not be used on [QUERY].", "locations":[{"line":2, "column":27}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-DIRECTIVE", "message":"Directive [onQuery] may not be used on [FIELD].", "locations":[{"line":3, "column":11}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-DIRECTIVE", "message":"Directive [onQuery] may not be used on [FRAGMENT_SPREAD].", "locations":[{"line":4, "column":14}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-DIRECTIVE", "message":"Directive [onQuery] may not be used on [MUTATION].", "locations":[{"line":7, "column":15}]}'))
)
return
(
    test:assert-equal(4, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'QUERY')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'FIELD')])
    ,test:assert-equal($expected[3]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'FRAGMENT_SPREAD')])
    ,test:assert-equal($expected[4]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'MUTATION')])
)
,
(: WITH MISPLACED VARIABLE DEFINITION DIRECTIVES :)
let $query := 
'
query person($id: Int @onField){
    name
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-DIRECTIVE", "message":"Directive [onField] may not be used on [VARIABLE-DEFINITION].", "locations":[{"line":2, "column":24}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'VARIABLE-DEFINITION')])
)
