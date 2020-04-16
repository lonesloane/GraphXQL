xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare variable $RULE := 'KNOWN-TYPE-NAME';

(: KNOWN TYPE NAMES ARE VALID :)
let $query := 
'
query Event($var: String, $required: [String!]!) {
    participants(offset: "4") {
    friends { ... on Human { name }, ...HeroFields, ... { name } }
    }
}
fragment HeroFields on Hero {
    name
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: UNKNOWN TYPE NAMES ARE INVALID :)
let $query := 
'
query Event($var: JumbledUpLetters) {
    participants(offset: "4") {
    friends { ... on Scum { name }, ...HeroFields, ... { name } }
    }
}
fragment HeroFields on Herooooo {
    name
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-TYPE-NAME", "message":"Unknown type [JumbledUpLetters].", "locations":[{"line":2, "column":19}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-TYPE-NAME", "message":"Unknown type [Scum].", "locations":[{"line":4, "column":22}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-TYPE-NAME", "message":"Unknown type [Herooooo].", "locations":[{"line":7, "column":24}]}'))
)
return
(
    test:assert-equal(3, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'JumbledUpLetters')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Scum')])
    ,test:assert-equal($expected[3]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Herooooo')])
)
;
(: SCALARS MISSING IN THE SCHEMA ARE INVALID :)
import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
(
    test:load-test-file("schema_lite.xml", xdmp:database(), "/graphXql/schema.xml"),
    xdmp:document-set-collections('/graphXql/schema.xml', ('/test/data', '/graphXql/schema.xml'))
)
;
import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare variable $RULE := 'KNOWN-TYPE-NAME';

let $query := 
'
query ($id: ID, $float: Float, $int: Int) {
    __typename
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-TYPE-NAME", "message":"Unknown type [ID].", "locations":[{"line":2, "column":13}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-TYPE-NAME", "message":"Unknown type [Float].", "locations":[{"line":2, "column":25}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-TYPE-NAME", "message":"Unknown type [Int].", "locations":[{"line":2, "column":38}]}'))
)
return
(
    test:assert-equal(3, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'ID')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Float')])
    ,test:assert-equal($expected[3]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Int')])
)
;
import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
(
    test:load-test-file("schema.xml", xdmp:database(), "/graphXql/schema.xml"),
    xdmp:document-set-collections('/graphXql/schema.xml', ('/test/data', '/graphXql/schema.xml'))
)
;