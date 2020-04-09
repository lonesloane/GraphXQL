xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare variable $RULE := 'KNOWN-FRAGMENT-NAME';

(: KNOWN FRAGMENT NAMES ARE VALID :)
let $query := 
'
{
    human(id: "4") {
    ...HumanFields1
    ... on Human {
        ...HumanFields2
        }
    ... {
            name
        }
    }
}
fragment HumanFields1 on Human {
    name
    ...HumanFields3
}
fragment HumanFields2 on Human {
    name
}
fragment HumanFields3 on Human {
    name
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: UNKNOWN FRAGMENT NAMES ARE INVALID :)
let $query := 
'
{
    human(id: "4") {
        ...UnknownFragment1
        ... on Human {
            ...UnknownFragment2
        }
    }
}
fragment HumanFields on Human {
    name
    ...UnknownFragment3
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-FRAGMENT-NAME", "message":"Unknown fragment [UnknownFragment1].", "locations":[{"line":4, "column":12}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-FRAGMENT-NAME", "message":"Unknown fragment [UnknownFragment2].", "locations":[{"line":6, "column":16}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-FRAGMENT-NAME", "message":"Unknown fragment [UnknownFragment3].", "locations":[{"line":12, "column":8}]}'))
)
return
(
    test:assert-equal(3, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'UnknownFragment1')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'UnknownFragment2')])
    ,test:assert-equal($expected[3]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'UnknownFragment3')])
)
