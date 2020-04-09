xquery version "1.0-ml";

import module namespace test="http://marklogic.com/test" at "/test/test-helper.xqy";

let $_ := xdmp:log("******** test:suite-setup ***********")
return
(
    test:load-test-file("person-1.xml", xdmp:database(), "http://one.oecd.org/person/1"),
    xdmp:document-set-collections('http://one.oecd.org/person/1', ('/test/data', 'http://one.oecd.org/persons')),

    test:load-test-file("person-2.xml", xdmp:database(), "http://one.oecd.org/person/2"),
    xdmp:document-set-collections('http://one.oecd.org/person/2', ('/test/data', 'http://one.oecd.org/persons')),

    test:load-test-file("person-3.xml", xdmp:database(), "http://one.oecd.org/person/3"),
    xdmp:document-set-collections('http://one.oecd.org/person/3', ('/test/data', 'http://one.oecd.org/persons')),

    test:load-test-file("person-4.xml", xdmp:database(), "http://one.oecd.org/person/4"),
    xdmp:document-set-collections('http://one.oecd.org/person/4', ('/test/data', 'http://one.oecd.org/persons')),

    test:load-test-file("person-5.xml", xdmp:database(), "http://one.oecd.org/person/5"),
    xdmp:document-set-collections('http://one.oecd.org/person/5', ('/test/data', 'http://one.oecd.org/persons')),

    test:load-test-file("person-6.xml", xdmp:database(), "http://one.oecd.org/person/6"),
    xdmp:document-set-collections('http://one.oecd.org/person/6', ('/test/data', 'http://one.oecd.org/persons')),

    test:load-test-file("person-7.xml", xdmp:database(), "http://one.oecd.org/person/7"),
    xdmp:document-set-collections('http://one.oecd.org/person/7', ('/test/data', 'http://one.oecd.org/persons')),

    test:load-test-file("schema.xml", xdmp:database(), "/graphXql/schema.xml"),
    xdmp:document-set-collections('/graphXql/schema.xml', ('/test/data', '/graphXql/schema'))

)