xquery version "1.0-ml";

import module namespace test="http://marklogic.com/test" at "/test/test-helper.xqy";

let $_ := xdmp:log("******** test:suite-setup ***********")
return
(
    test:load-test-file("person-1.xml", xdmp:database(), "/graphXql/person/1"),
    xdmp:document-set-collections('/graphXql/person/1', ('/test/data', '/graphXql/persons')),

    test:load-test-file("person-2.xml", xdmp:database(), "/graphXql/person/2"),
    xdmp:document-set-collections('/graphXql/person/2', ('/test/data', '/graphXql/persons')),

    test:load-test-file("person-3.xml", xdmp:database(), "/graphXql/person/3"),
    xdmp:document-set-collections('/graphXql/person/3', ('/test/data', '/graphXql/persons')),

    test:load-test-file("person-4.xml", xdmp:database(), "/graphXql/person/4"),
    xdmp:document-set-collections('/graphXql/person/4', ('/test/data', '/graphXql/persons')),

    test:load-test-file("person-5.xml", xdmp:database(), "/graphXql/person/5"),
    xdmp:document-set-collections('/graphXql/person/5', ('/test/data', '/graphXql/persons')),

    test:load-test-file("person-6.xml", xdmp:database(), "/graphXql/person/6"),
    xdmp:document-set-collections('/graphXql/person/6', ('/test/data', '/graphXql/persons')),

    test:load-test-file("person-7.xml", xdmp:database(), "/graphXql/person/7"),
    xdmp:document-set-collections('/graphXql/person/7', ('/test/data', '/graphXql/persons')),

    test:load-test-file("schema.xml", xdmp:database(), "/graphXql/schema.xml"),
    xdmp:document-set-collections('/graphXql/schema.xml', ('/test/data', '/graphXql/schema'))

)