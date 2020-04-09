xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace visit = "http://graph.x.ql/visitor" at "/graphXql/visitor.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";

import schema namespace gxqls="http://graph.x.qls" at "/graphxql/schema.xsd";
declare variable $SCHEMA as element(*, gxqls:Schema) := fn:doc('/graphXql/schema.xml')/gxqls:Schema;

(: XSD VALIDATION :)
test:assert-equal((), xdmp:validate($SCHEMA, 'type', xs:QName('gxqls:Schema'))/child::*)
,

let $query := 
'
{
    __schema {
        description
        types {
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
      "description": "Schema pretending to cover all possible test scenarios",
      "types": [
        {
          "name": "Query"
        },
        {
          "name": "Mutation"
        },
        {
          "name": "Dog"
        },
        {
          "name": "Document"
        },
        {
          "name": "Event"
        },
        {
          "name": "Pet"
        },
        {
          "name": "CreateParticipant"
        },
        {
          "name": "Person"
        },
        {
          "name": "ComplicatedArgs"
        },
        {
          "name": "HeroOrFoe"
        },
        {
          "name": "Horse"
        },
        {
          "name": "Delegation"
        },
        {
          "name": "Human"
        },
        {
          "name": "Hero"
        },
        {
          "name": "DogOrHuman"
        },
        {
          "name": "Boolean"
        },
        {
          "name": "HorseOrDog"
        },
        {
          "name": "FurColor"
        },
        {
          "name": "ComplexInput"
        },
        {
          "name": "Float"
        },
        {
          "name": "Foe"
        },
        {
          "name": "String"
        },
        {
          "name": "Int"
        },
        {
          "name": "ID"
        },
        {
          "name": "__Schema"
        },
        {
          "name": "__Type"
        },
        {
          "name": "__TypeKind"
        },
        {
          "name": "__EnumValue"
        },
        {
          "name": "__Field"
        },
        {
          "name": "__Directive"
        },
        {
          "name": "__DirectiveLocation"
        },
        {
          "name": "__InputValue"
        }
      ]
    }
  }
}
'))
let $actual := parser:parse($query)
                => visit:visit($variables)
return 
(
    test:assert-equal($expected, $actual)
)
