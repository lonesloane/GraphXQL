xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare variable $RULE := 'NO-UNUSED-FRAGMENTS';

(: ALL FRAGMENT NAMES ARE USED :)
let $query := 
'
{
human(id: "4") {
    ...HumanFields1
    ... on Human {
        ...HumanFields2
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
(: ALL FRAGMENT NAMES ARE USED BY MULTIPLE OPERATIONS :)
let $query := 
'
query Foo {
    human(id: "4") {
        ...HumanFields1
    }
}
query Bar {
    human(id: "4") {
        ...HumanFields2
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
(: CONTAINS UNKNOWN FRAGMENTS :)
let $query := 
'
query Foo {
    human(id: "4") {
        ...HumanFields1
    }
}
query Bar {
    human(id: "4") {
        ...HumanFields2
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
fragment Unused1 on Human {
    name
}
fragment Unused2 on Human {
    name
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNUSED-FRAGMENTS", "message":"Fragment [Unused1] is never used.", "locations":[{"line":22, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNUSED-FRAGMENTS", "message":"Fragment [Unused2] is never used.", "locations":[{"line":25, "column":10}]}'))
)
return
(
    test:assert-equal(2, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Unused1')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Unused2')])
)
,
(: CONTAINS UNKNOWN FRAGMENTS WITG REF CYCLES :)
let $query := 
'
query Foo {
    human(id: "4") {
        ...HumanFields1
    }
}
query Bar {
    human(id: "4") {
        ...HumanFields2
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
fragment Unused1 on Human {
    name
    ...Unused2
}
fragment Unused2 on Human {
    name
    ...Unused1
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNUSED-FRAGMENTS", "message":"Fragment [Unused1] is never used.", "locations":[{"line":22, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNUSED-FRAGMENTS", "message":"Fragment [Unused2] is never used.", "locations":[{"line":26, "column":10}]}'))
)
return
(
    test:assert-equal(2, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Unused1')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Unused2')])
)
,
(: CONTAINS UNKNOWN AND UNDEF FRAGMENTS :)
let $query := 
'
query Foo {
    human(id: "4") {
        ...bar
    }
}
fragment foo on Human {
    name
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNUSED-FRAGMENTS", "message":"Fragment [foo] is never used.", "locations":[{"line":7, "column":10}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'foo')])
)
