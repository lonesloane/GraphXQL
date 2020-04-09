xquery version "1.0-ml";

import module namespace gxqlr = "http://graph.x.ql/resolvers" at "/graphXql/resolvers/person-resolver.xqy";
import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import schema namespace gxql = "http://graph.x.ql" at "/graphxql/entities/person.xsd";

declare namespace error="http://marklogic.com/xdmp/error";

let $var-map := map:map() => map:with('id', 1)
let $actual := gxqlr:person-entity-resolver($var-map)

return 
(
    test:assert-equal((), xdmp:validate($actual, 'type', xs:QName('gxql:Hero'))/error:error),
    test:assert-equal('1', $actual/gxql:id/string()),
    test:assert-equal('Luke', $actual/gxql:name/string())
)
,
let $var-map := map:map() => map:with('id', 0)
return
try {
    gxqlr:person-entity-resolver($var-map)
} catch($ex){
    xdmp:log(xdmp:describe($ex, (),())),
    test:assert-equal('ENTITY RESOLVER EXCEPTION', $ex/error:code/string())
}
,
let $var-map := map:map()
return
try {
    gxqlr:person-entity-resolver($var-map)
} catch($ex){
    xdmp:log(xdmp:describe($ex, (),())),
    test:assert-equal('ENTITY RESOLVER EXCEPTION', $ex/error:code/string())
}
