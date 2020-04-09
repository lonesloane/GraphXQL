xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare variable $RULE := 'VARIABLES-IN-ALLOWED-POSITION';

(: BOOLEAN => BOOLEAN :)
let $query := 
'
query Query($booleanArg: Boolean)
{
    complicatedArgs {
        booleanArgField(booleanArg: $booleanArg)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: BOOLEAN => BOOLEAN WITH FRAGMENT :)
let $query := 
'
fragment booleanArgFrag on ComplicatedArgs {
    booleanArgField(booleanArg: $booleanArg)
}
query Query($booleanArg: Boolean)
{
    complicatedArgs {
        ...booleanArgFrag
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: BOOLEAN => BOOLEAN WITH FRAGMENT :)
let $query := 
'
query Query($booleanArg: Boolean)
{
    complicatedArgs {
        ...booleanArgFrag
    }
}
fragment booleanArgFrag on ComplicatedArgs {
    booleanArgField(booleanArg: $booleanArg)
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: BOOLEAN! => BOOLEAN :)
let $query := 
'
query Query($nonNullBooleanArg: Boolean!)
{
    complicatedArgs {
        booleanArgField(booleanArg: $nonNullBooleanArg)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: BOOLEAN! => BOOLEAN WITHIN FRAGMENT :)
let $query := 
'
fragment booleanArgFrag on ComplicatedArgs {
    booleanArgField(booleanArg: $nonNullBooleanArg)
}

query Query($nonNullBooleanArg: Boolean!)
{
    complicatedArgs {
        ...booleanArgFrag
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: [STRING] => [STRING] :)
let $query := 
'
query Query($stringListVar: [String])
{
    complicatedArgs {
        stringListArgField(stringListArg: $stringListVar)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: [STRING!] => [STRING] :)
let $query := 
'
query Query($stringListVar: [String!])
{
    complicatedArgs {
        stringListArgField(stringListArg: $stringListVar)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: STRING => [STRING] :)
let $query := 
'
query Query($stringListVar: String)
{
    complicatedArgs {
        stringListArgField(stringListArg: [$stringListVar])
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: STRING! => [STRING] :)
let $query := 
'
query Query($stringListVar: String!)
{
    complicatedArgs {
        stringListArgField(stringListArg: [$stringListVar])
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: COMPLEXINPUT => COMPLEXINPUT :)
let $query := 
'
query Query($complexVar: ComplexInput)
{
    complicatedArgs {
        complexArgField(complexArg: $complexVar)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: COMPLEXINPUT => COMPLEXINPUT IN FIELD POSITION :)
let $query := 
'
query Query($boolVar: Boolean = false)
{
    complicatedArgs {
        complexArgField(complexArg: {requiredArg: $boolVar})
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: BOOLEAN! => BOOLEAN! IN DIRECTIVE :)
let $query := 
'
query Query($boolVar: Boolean!)
{
    dog @include(if: $boolVar)
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: INT => INT! :)
let $query := 
'
query Query($intArg: Int) {
    complicatedArgs {
        nonNullIntArgField(nonNullIntArg: $intArg)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VARIABLES-IN-ALLOWED-POSITION", "message":"Variable intArg of type Int used in position expecting type Int!", "locations":[{"line":2, "column":14}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Int!')])
)
,
(: INT => INT! WITHIN FRAGMENT :)
let $query := 
'
fragment nonNullIntArgFieldFrag on ComplicatedArgs {
    nonNullIntArgField(nonNullIntArg: $intArg)
}

query Query($intArg: Int) {
    complicatedArgs {
        ...nonNullIntArgFieldFrag
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VARIABLES-IN-ALLOWED-POSITION", "message":"Variable intArg of type Int used in position expecting type Int!", "locations":[{"line":6, "column":14}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Int!')])
)
,
(: INT => INT! WITHIN NESTED FRAGMENT :)
let $query := 
'
fragment outerFrag on ComplicatedArgs {
    ...nonNullIntArgFieldFrag
}

fragment nonNullIntArgFieldFrag on ComplicatedArgs {
    nonNullIntArgField(nonNullIntArg: $intArg)
}

query Query($intArg: Int) {
    complicatedArgs {
        ...outerFrag
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VARIABLES-IN-ALLOWED-POSITION", "message":"Variable intArg of type Int used in position expecting type Int!", "locations":[{"line":10, "column":14}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Int!')])
)
,
(: STRING => BOOLEAN :)
let $query := 
'
query Query($stringVar: String) {
    complicatedArgs {
        booleanArgField(booleanArg: $stringVar)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VARIABLES-IN-ALLOWED-POSITION", "message":"Variable stringVar of type String used in position expecting type Boolean", "locations":[{"line":2, "column":14}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Boolean')])
)
,
(: STRING => [STRING] :)
let $query := 
'
query Query($stringVar: String) {
    complicatedArgs {
        stringListArgField(stringListArg: $stringVar)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VARIABLES-IN-ALLOWED-POSITION", "message":"Variable stringVar of type String used in position expecting type [String]", "locations":[{"line":2, "column":14}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[String]')])
)
,
(: BOOLEAN => BOOLEAN! IN DIRECTIVE :)
let $query := 
'
query Query($boolVar: Boolean) {
    dog @include(if: $boolVar)
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VARIABLES-IN-ALLOWED-POSITION", "message":"Variable boolVar of type Boolean used in position expecting type Boolean!", "locations":[{"line":2, "column":14}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Boolean')])
)
,
(: STRING => BOOLEAN! IN DIRECTIVE :)
let $query := 
'
query Query($stringVar: String) {
    dog @include(if: $stringVar)
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VARIABLES-IN-ALLOWED-POSITION", "message":"Variable stringVar of type String used in position expecting type Boolean!", "locations":[{"line":2, "column":14}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Boolean')])
)
,
(: [STRING] => [STRING!] :)
let $query := 
'
query Query($stringListVar: [String])
{
    complicatedArgs {
        stringListNonNullArgField(stringListNonNullArg: $stringListVar)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VARIABLES-IN-ALLOWED-POSITION", "message":"Variable stringListVar of type [String] used in position expecting type [String]!", "locations":[{"line":2, "column":14}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[String]!')])
)
,
(: INT => INT! FAILS WITH NULL DEFAULT VALUE :)
let $query := 
'
query Query($intVar: Int = null) {
    complicatedArgs {
        nonNullIntArgField(nonNullIntArg: $intVar)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"VARIABLES-IN-ALLOWED-POSITION", "message":"Variable intVar of type Int used in position expecting type Int!", "locations":[{"line":2, "column":14}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Int!')])
)
,
(: INT => INT! WITH NON-NULL DEFAULT VALUE :)
let $query := 
'
query Query($intVar: Int = 1) {
    complicatedArgs {
        nonNullIntArgField(nonNullIntArg: $intVar)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: INT => INT! WITH NON-NULL DEFAULT VALUE :)
let $query := 
'
query Query($intVar: Int) {
    complicatedArgs {
        nonNullFieldWithDefault(arg: $intVar)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: BOOLEAN => BOOLEAN! WITH NON-NULL DEFAULT VALUE :)
let $query := 
'
query Query($boolVar: Boolean = false) {
    dog @include(if: $boolVar)
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
