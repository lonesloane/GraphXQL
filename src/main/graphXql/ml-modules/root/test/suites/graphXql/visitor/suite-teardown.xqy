xquery version "1.0-ml";
import module namespace cg = "http://marklogic.com/roxy/config" at "/app/config/config.xqy";

let $_ := xdmp:log("******** test:suite-teardown ***********")
return 
(
    cts:uris('', (), cts:collection-query('/test/data')) ! xdmp:document-delete(.)
)