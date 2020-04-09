xquery version "1.0-ml";

import module namespace test="http://marklogic.com/test" at "/test/test-helper.xqy";

let $_ := xdmp:log("******** test:suite-setup ***********")
return
(
    test:load-test-file("schema.xml", xdmp:database(), "/graphXql/schema.xml"),
    xdmp:document-set-collections('/graphXql/schema.xml', ('/test/data', '/graphXql/schema'))
)