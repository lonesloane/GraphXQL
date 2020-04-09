xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace visit = "http://graph.x.ql/visitor" at "/graphXql/visitor.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";

let $query := 
'
{
  __schema {
    queryType {
      name
    }
  }
}
'
let $variables := map:map()
let $expected := xdmp:to-json(xdmp:from-json-string('
{
    "data": {
        "__schema": {
            "queryType": {
                "name": "Query"
            }
        }
    }
}'
))
let $actual := parser:parse($query)
                => visit:visit($variables)
return 
(
    test:assert-equal($expected, $actual)
)
