xquery version "1.0-ml";

module namespace disp = "http://graph.x.ql/dispatcher";

import module namespace gxqlr = "http://graph.x.ql/resolvers" 
    at "/graphXql/resolvers/export.xqy";
import module namespace intro = "http://graph.x.ql/resolver/introspection" 
    at "/graphXql/resolvers/introspection-resolver.xqy";
import schema namespace gxqli = "http://graph.x.qli" 
    at "/graphxql/introspection.xsd";

declare namespace xs="http://www.w3.org/2001/XMLSchema";

declare function disp:get-entity-resolver($entity-name as xs:string) as xdmp:function
{
    (
        xdmp:log('[disp:get-entity-resolver] $entity-name: '||$entity-name, 'debug')
    ),
    (: INTROSPECTION :)
    if      ($entity-name eq '__schema')    then xdmp:function(xs:QName('intro:schema-resolver'))
    else if ($entity-name eq '__type')      then xdmp:function(xs:QName('intro:type-resolver'))
    (: EXECUTION :)
    else gxqlr:get-entity-resolver($entity-name)
};

declare function disp:get-field-resolver($entity as element(), $field-name as xs:string) as xdmp:function
{
    (
        xdmp:log('[disp:get-field-resolver] $entity: '||xdmp:describe($entity, (), ()), 'debug')
        ,xdmp:log('[disp:get-field-resolver] $field-name: '||$field-name, 'debug')
    ),

    typeswitch ($entity)
        (: INTROSPECTION :)
        case $o as element(*, gxqli:__Schema) return intro:schema-field-resolver($field-name)
        case $o as element(*, gxqli:__Type) return intro:type-field-resolver($field-name)
        case $o as element(*, gxqli:__Field) return intro:field-field-resolver($field-name)
        case $o as element(*, gxqli:__InputValue  ) return intro:input-value-field-resolver($field-name)
        case $o as element(*, gxqli:__EnumValue  ) return intro:enum-value-field-resolver($field-name)
        (: EXECUTION :)
        default return gxqlr:get-field-resolver($entity, $field-name)
};

declare function disp:get-entity-type($entity as element()) as xs:string
{
    (
        xdmp:log('[disp:get-entity-type] $entity: '||xdmp:describe($entity, (), ()), 'debug')
    ),

    gxqlr:typename-resolver($entity)
};

declare function disp:mutate($node as node(), $variables as map:map)
{
    (
        xdmp:log('[disp:mutate] $node: '||xdmp:describe($node,(),()), 'debug'),
        xdmp:log('[disp:mutate] $variables: '||xdmp:describe($variables,(),()), 'debug')
    ),

    let $mutation := gxqlr:mutation-resolver($node/name/@value/string())
    return
        xdmp:apply($mutation, $variables)
};

