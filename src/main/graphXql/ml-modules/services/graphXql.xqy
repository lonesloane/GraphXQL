xquery version "1.0-ml";

module namespace graphxql = "http://marklogic.com/rest-api/resource/graphXql";

import module namespace parser = "http://graph.x.ql/parser" 
  at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" 
  at "/graphXql/validator.xqy";
import module namespace visitor = "http://graph.x.ql/visitor" 
  at "/graphXql/visitor.xqy";
import module namespace errh = "http://one.oecd.org/one/lib/errors.xqy" 
  at "/graphXql/errors.xqy"; 

declare namespace rapi = "http://marklogic.com/rest-api";

declare variable $graphxql:MODULE-NAME as xs:string := "graphxql-api";

declare function graphxql:execute($input as document-node()*, $params as map:map, $context as map:map){
    let $query := $input/query
    let $variables := fn:head(($input/variables, map:map()))
    (: TODO: implement validation caching strategy for (query/variables) set :)
    let $report := validator:validate(parser:parse($query, xs:boolean('true')))
    return 
      if (fn:count($report/errors) gt 0) 
      then 
      (
        map:put($context, "output-status", (400, "VALIDATION-ERROR")),
        $report
      )
      else visitor:visit(parser:parse($query), $variables)
};

declare %rapi:transaction-mode("update") function graphxql:post(
    $context as map:map,
    $params as map:map,
    $input as document-node()*
) as document-node()? 
{
  (: TODO: add log + execution time tracer :)
    try {
      (
        map:put($context, "output-types", "application/json"),
        map:put($context, "output-status", (200, "OK")),
        graphxql:execute($input, $params, $context)
      )
    }
    catch($ex){
      errh:throw-exception($ex, $graphxql:MODULE-NAME)
    }
};