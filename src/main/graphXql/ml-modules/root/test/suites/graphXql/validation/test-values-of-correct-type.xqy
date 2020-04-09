xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare variable $RULE := 'VALUES-OF-CORRECT-TYPE';

(: GOOD INT VALUE :)
let $query := 
'
{
    complicatedArgs {
        intArgField(intArg: 2)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: GOOD NEGATIVE INT VALUE :)
let $query := 
'
{
    complicatedArgs {
        intArgField(intArg: -2)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: GOOD BOOLEAN VALUE :)
let $query := 
'
{
    complicatedArgs {
        booleanArgField(booleanArg: true)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: GOOD STRING VALUE :)
let $query := 
'
{
    complicatedArgs {
        stringArgField(stringArg: "foo")
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: GOOD FLOAT VALUE :)
let $query := 
'
{
    complicatedArgs {
        floatArgField(floatArg: 1.1)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: GOOD NEGATIVE FLOAT VALUE :)
let $query := 
'
{
    complicatedArgs {
        floatArgField(floatArg: -1.1)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: INT INTO FLOAT 
let $query := 
'
{
    complicatedArgs {
        floatArgField(floatArg: 1)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: INT INTO ID :)
let $query := 
'
{
    complicatedArgs {
        idArgField(idArg: 1)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: STRING INTO ID :)
let $query := 
'
{
    complicatedArgs {
        idArgField(idArg: "someIdString")
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
:)
(: GOOD ENUM VALUE :)
let $query := 
'
{
    dog {
        hasFurColor(furColor: BROWN)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: ENUM WITH UNDEFINED VALUE :)
let $query := 
'
{
    complicatedArgs {
        enumArgField(enumArg: UNKNOWN)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: ENUM WITH NULL VALUE :)
let $query := 
'
{
    complicatedArgs {
        enumArgField(enumArg: NO_FUR)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: NULL INTO NULLABLE TYPE :)
let $query := 
'
{
    complicatedArgs {
        intArgField(intArg: null)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: NULL INTO NULLABLE TYPE 
let $query := 
'
{
    dog(a: null, b: null, c:{ requiredField: true, intField: null }) {
        name
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,:)
(: INT INTO STRING :)
let $query := 
'
{
    complicatedArgs {
        stringArgField(stringArg: 1)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"String cannot represent a non String value: 1", "locations":[{"line":4, "column":24}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '1')])
)
,
(: FLOAT INTO STRING :)
let $query := 
'
{
    complicatedArgs {
        stringArgField(stringArg: 1.0)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"String cannot represent a non String value: 1.0", "locations":[{"line":4, "column":24}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '1.0')])
)
,
(: BOOLEAN INTO STRING :)
let $query := 
'
{
    complicatedArgs {
        stringArgField(stringArg: true)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"String cannot represent a non String value: true", "locations":[{"line":4, "column":24}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'true')])
)
,
(: STRING INTO INT :)
let $query := 
'
{
    complicatedArgs {
        intArgField(intArg: "3")
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"Int cannot represent a non Int value: 3", "locations":[{"line":4, "column":21}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '3')])
)
,
(: BIG INT INTO INT 
let $query := 
'
{
    complicatedArgs {
        intArgField(intArg: 829384293849283498239482938)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"Int cannot represent a non Int value: 3", "locations":[{"line":4, "column":21}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '3')])
)
,:)
(: UNQUOTED STRING INTO INT :)
let $query := 
'
{
    complicatedArgs {
        intArgField(intArg: FOO)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"Int cannot represent a non Int value: FOO", "locations":[{"line":4, "column":21}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'FOO')])
)
,
(: SIMPLE FLOAT INTO INT :)
let $query := 
'
{
    complicatedArgs {
        intArgField(intArg: 3.0)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"Int cannot represent a non Int value: 3.0", "locations":[{"line":4, "column":21}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '3.0')])
)
,
(: FLOAT INTO INT :)
let $query := 
'
{
    complicatedArgs {
        intArgField(intArg: 3.333)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"Int cannot represent a non Int value: 3.333", "locations":[{"line":4, "column":21}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '3.333')])
)
,
(: STRING INTO FLOAT :)
let $query := 
'
{
    complicatedArgs {
        floatArgField(floatArg: "3.333")
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"Float cannot represent a non Float value: 3.333", "locations":[{"line":4, "column":23}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '3.333')])
)
,
(: BOOLEAN INTO FLOAT :)
let $query := 
'
{
    complicatedArgs {
        floatArgField(floatArg: true)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"Float cannot represent a non Float value: true", "locations":[{"line":4, "column":23}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'true')])
)
,
(: UNQUOTED STRING INTO FLOAT :)
let $query := 
'
{
    complicatedArgs {
        floatArgField(floatArg: FOO)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"Float cannot represent a non Float value: FOO", "locations":[{"line":4, "column":23}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'FOO')])
)
,
(: INT INTO BOOLEAN :)
let $query := 
'
{
    complicatedArgs {
        booleanArgField(booleanArg: 2)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"Boolean cannot represent a non Boolean value: 2", "locations":[{"line":4, "column":25}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '2')])
)
,
(: FLOAT INTO BOOLEAN :)
let $query := 
'
{
    complicatedArgs {
        booleanArgField(booleanArg: 1.0)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"Boolean cannot represent a non Boolean value: 1.0", "locations":[{"line":4, "column":25}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '1.0')])
)
,
(: STRING INTO BOOLEAN :)
let $query := 
'
{
    complicatedArgs {
        booleanArgField(booleanArg: "true")
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"Boolean cannot represent a non Boolean value: true", "locations":[{"line":4, "column":25}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'true')])
)
,
(: UNQUOTED STRING INTO BOOLEAN :)
let $query := 
'
{
    complicatedArgs {
        booleanArgField(booleanArg: TRUE)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"Boolean cannot represent a non Boolean value: TRUE", "locations":[{"line":4, "column":25}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'TRUE')])
)
,
(: FLOAT INTO ID :)
let $query := 
'
{
    complicatedArgs {
        idArgField(idArg: 1.0)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"ID cannot represent a non ID value: 1.0", "locations":[{"line":4, "column":20}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '1.0')])
)
,
(: BOOLEAN INTO ID :)
let $query := 
'
{
    complicatedArgs {
        idArgField(idArg: true)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"ID cannot represent a non ID value: true", "locations":[{"line":4, "column":20}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'true')])
)
,
(: UNQUOTED STRING INTO ID :)
let $query := 
'
{
    complicatedArgs {
        idArgField(idArg: SOMETHING)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"ID cannot represent a non ID value: SOMETHING", "locations":[{"line":4, "column":20}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'SOMETHING')])
)
,
(: INT INTO ENUM :)
let $query := 
'
{
    dog {
        hasFurColor(furColor: 2)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"Expected value of type [FurColor], found: 2", "locations":[{"line":4, "column":21}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '2')])
)
,
(: FLOAT INTO ENUM :)
let $query := 
'
{
    dog {
        hasFurColor(furColor: 2.0)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"Expected value of type [FurColor], found: 2.0", "locations":[{"line":4, "column":21}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '2.0')])
)
,
(: STRING INTO ENUM :)
let $query := 
'
{
    dog {
        hasFurColor(furColor: "BROWN")
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"Expected value of type [FurColor], found: BROWN", "locations":[{"line":4, "column":21}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'BROWN')])
)
,
(: BOOLEAN INTO ENUM :)
let $query := 
'
{
    dog {
        hasFurColor(furColor: true)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"Expected value of type [FurColor], found: true", "locations":[{"line":4, "column":21}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'true')])
)
,
(: UNKNOWN ENUM VALUE INTO ENUM :)
let $query := 
'
{
    dog {
        hasFurColor(furColor: DAZZLING)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"Expected value of type [FurColor], found: DAZZLING", "locations":[{"line":4, "column":21}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'DAZZLING')])
)
,
(: DIFFERENT CASE ENUM VALUE INTO ENUM :)
let $query := 
'
{
    dog {
        hasFurColor(furColor: brown)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"Expected value of type [FurColor], found: brown", "locations":[{"line":4, "column":21}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'brown')])
)
,
(: GOOD LIST VALUE :)
let $query := 
'
{
    complicatedArgs {
        stringListArgField(stringListArg: ["one", null, "two"])
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: EMPTY LIST VALUE :)
let $query := 
'
{
    complicatedArgs {
        stringListArgField(stringListArg: [])
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: NULL VALUE :)
let $query := 
'
{
    complicatedArgs {
        stringListArgField(stringListArg: null)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: SINGLE VALUE INTO LIST :)
let $query := 
'
{
    complicatedArgs {
        stringListArgField(stringListArg: "one")
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: INCORRECT ITEM TYPE :)
let $query := 
'
{
    complicatedArgs {
        stringListArgField(stringListArg: ["one", 2])
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"String cannot represent a non String value: 2", "locations":[{"line":4, "column":28}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '2')])
)
,
(: SINGLE VALUE OF INCORRECT TYPE :)
let $query := 
'
{
    complicatedArgs {
        stringListArgField(stringListArg: 1)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"String cannot represent a non String value: 1", "locations":[{"line":4, "column":28}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '1')])
)
,
(: ARG ON OPTIONAL ARG :)
let $query := 
'
{
    dog {
        canSpeak(inHisHead: true)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: NO ARG ON OPTIONAL ARG :)
let $query := 
'
{
    dog {
        canSpeak
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: MULTIPLE ARGS :)
let $query := 
'
{
    complicatedArgs {
        multipleReqs(req1: 1, req2: 2)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: MULTIPLE ARGS REVERSE ORDER:)
let $query := 
'
{
    complicatedArgs {
        multipleReqs(req2: 2, req1: 1)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: NO ARGS ON MULTIPLE OPTIONAL:)
let $query := 
'
{
    complicatedArgs {
        multipleOpts
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: ONE ARG ON MULTIPLE OPTIONAL:)
let $query := 
'
{
    complicatedArgs {
        multipleOpts(opt1: 1)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: SECOND ARG ON MULTIPLE OPTIONAL:)
let $query := 
'
{
    complicatedArgs {
        multipleOpts(opt2: 1)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: MULTIPLE REQS ON MIXED LIST :)
let $query := 
'
{
    complicatedArgs {
        multipleOptAndReq(req1: 3, req2: 4)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: MULTIPLE REQS AND ONE OPT ON MIXED LIST :)
let $query := 
'
{
    complicatedArgs {
        multipleOptAndReq(req1: 3, req2: 4, opt1: 5)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: ALL REQS AND OPTS ON MIXED LIST :)
let $query := 
'
{
    complicatedArgs {
        multipleOptAndReq(req1: 3, req2: 4, opt1: 5, opt2: 6)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: INCORRECT VALUE TYPE :)
let $query := 
'
{
    complicatedArgs {
        multipleReqs(req2: "two", req1: "one")
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"Int cannot represent a non Int value: two", "locations":[{"line":4, "column":22}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"Int cannot represent a non Int value: one", "locations":[{"line":4, "column":35}]}'))
)
return
(
    test:assert-equal(2, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'two')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'one')])
)
,
(: INCORRECT VALUE AND MISSING ARGUMENT :)
let $query := 
'
{
    complicatedArgs {
        multipleReqs(req1: "one")
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"Int cannot represent a non Int value: one", "locations":[{"line":4, "column":22}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'one')])
)
,
(: NULL VALUE :)
let $query := 
'
{
    complicatedArgs {
        multipleReqs(req1: null)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"Expected value of type [Int!], found: null", "locations":[{"line":4, "column":22}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'null')])
)
,
(: OPTIONAL ARG, DESPITE REQUIRED FIELD IN TYPE :)
let $query := 
'
{
    complicatedArgs {
        complexArgField
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: PARTIAL OBJECT, ONLY REQUIRED :)
let $query := 
'
{
    complicatedArgs {
        complexArgField(complexArg: { requiredField: true })
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: PARTIAL OBJECT, REQUIRED FIELD CAN BE FALSE :)
let $query := 
'
{
    complicatedArgs {
        complexArgField(complexArg: { requiredField: false })
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: PARTIAL OBJECT, INLCUDING REQUIRED :)
let $query := 
'
{
    complicatedArgs {
        complexArgField(complexArg: { requiredField: true, intField: 4 })
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: FULL OBJECT :)
let $query := 
'
{
    complicatedArgs {
        complexArgField(complexArg: {
            requiredField: true,
            intField: 4,
            stringField: "foo",
            booleanField: false,
            stringListField: ["one", "two"]
        })
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: FULL OBJECT, FIELDS IN DIFFERENT ORDER :)
let $query := 
'
{
    complicatedArgs {
        complexArgField(complexArg: {
            stringListField: ["one", "two"],
            booleanField: false,
            requiredField: true,
            stringField: "foo",
            intField: 4,
        })
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: PARTIAL OBJECT, MISSING REQUIRED :)
let $query := 
'
{
    complicatedArgs {
        complexArgField(complexArg: { intField: 4 })
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"Field complexArg.requiredField of required type Boolean! was not provided.", "locations":[{"line":4, "column":25}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'requiredField')])
)
,
(: PARTIAL OBJECT, INVALID FIELD TYPE :)
let $query := 
'
{
    complicatedArgs {
        complexArgField(complexArg: {
            stringListField: ["one", 2],
            requiredField: true,
        })
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"String cannot represent a non String value: 2", "locations":[{"line":5, "column":13}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '2')])
)
,
(: PARTIAL OBJECT, NULL TO NON-NULL FIELD :)
let $query := 
'
{
    complicatedArgs {
        complexArgField(complexArg: {
            requiredField: true,
            nonNullField: null,
        })
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"Expected value of type [Boolean!], found: null", "locations":[{"line":6, "column":13}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Boolean!')])
)
,
(: PARTIAL OBJECT, UNKNOWN FIELD ARG :)
let $query := 
'
{
    complicatedArgs {
        complexArgField(complexArg: {
            requiredField: true,
            unknownField: "value"
        })
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VALUES-OF-CORRECT-TYPE", "message":"Field unknownField is not defined by type ComplexInput. Valid field values are [requiredField, nonNullField, intField, stringField, booleanField, stringListField]", "locations":[{"line":6, "column":13}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'unknownField')])
)
(: TODO: FINALIZE IMPLEMENTATION OF MISSING TEST CASES... :)