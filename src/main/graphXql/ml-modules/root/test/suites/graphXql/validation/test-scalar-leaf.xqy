xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare variable $RULE := 'SCALAR-LEAF';

(: VALID SCALAR SELECTION :)
let $query := 
'
fragment scalarSelection on Dog {
    name
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: OBJECT TYPE MISSING SELECTION :)
let $query := 
'
query directQueryOnObjectWithoutSubFields {
    human
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"SCALAR-LEAF", "message":"Field [human] of type [Human] must have a selection of subfields. Did you mean human { ... }?", "locations":[{"line":3, "column":5}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[Human]')])
)
,
(: INTERFACE TYPE MISSING SELECTION :)
let $query := 
'
{
    person { friends }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"SCALAR-LEAF", "message":"Field [friends] of type [Person] must have a selection of subfields. Did you mean friends { ... }?", "locations":[{"line":3, "column":14}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[friends]')])
)
,
(: VALID SCALAR SELECTION WITH ARGS :)
let $query := 
'
fragment scalarSelection on Dog {
    canSpeak (inHisHead: "true")
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: SCALAR SELECTION NOT ALLOWED ON BOOLEAN :)
let $query := 
'
fragment scalarSelection on Dog {
    canSpeak { sinceWhen }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"SCALAR-LEAF", "message":"Field [canSpeak] must not have a selection since type [Boolean] has no subfields.", "locations":[{"line":3, "column":5}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[canSpeak]')])
)
,
(: SCALAR SELECTION NOT ALLOWED ON ENUM :)
let $query := 
'
fragment scalarSelection on Pet {
    furColor { inHexdec }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"SCALAR-LEAF", "message":"Field [furColor] must not have a selection since type [FurColor] has no subfields.", "locations":[{"line":3, "column":5}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[furColor]')])
)
,
(: SCALAR SELECTION NOT ALLOWED WITH ARGS :)
let $query := 
'
fragment scalarSelection on Dog {
    canSpeak (inHisHead: "true") { sinceWhen }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"SCALAR-LEAF", "message":"Field [canSpeak] must not have a selection since type [Boolean] has no subfields.", "locations":[{"line":3, "column":5}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[canSpeak]')])
)
,
(: SCALAR SELECTION NOT ALLOWED WITH DIRECTIVE :)
let $query := 
'
fragment scalarSelection on Dog {
    name @include(if: "true") { isAlsoHumanName }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"SCALAR-LEAF", "message":"Field [name] must not have a selection since type [String] has no subfields.", "locations":[{"line":3, "column":5}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[name]')])
)
,
(: SCALAR SELECTION NOT ALLOWED WITH DIRECTIVE AND ARGS :)
let $query := 
'
fragment scalarSelection on Dog {
    canSpeak (inHisHead: "true") @include(if: "true") { sinceWhen }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"SCALAR-LEAF", "message":"Field [canSpeak] must not have a selection since type [Boolean] has no subfields.", "locations":[{"line":3, "column":5}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[canSpeak]')])
)
