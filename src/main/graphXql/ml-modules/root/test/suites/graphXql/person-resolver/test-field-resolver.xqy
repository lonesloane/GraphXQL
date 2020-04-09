xquery version "1.0-ml";

import module namespace gxqlr = "http://graph.x.ql/resolvers" at "/graphXql/resolvers/person-resolver.xqy";
import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";

let $field-name := 'name'
let $expected := xs:QName('gxqlr:person-name-resolver')
let $actual := gxqlr:person-field-resolver($field-name)

return 
(
    test:assert-equal($expected, xdmp:function-name($actual))
)
,
let $field-name := 'unknown'
return
try {
    gxqlr:person-field-resolver($field-name)
} catch($ex){
    xdmp:log(xdmp:describe($ex, (),())),
    test:assert-equal('FIELD RESOLVER EXCEPTION', $ex/error:code/string())
}

