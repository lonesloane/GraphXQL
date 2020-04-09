xquery version "1.0-ml";

module namespace gxqlr = "http://graph.x.ql/resolvers";

import module namespace gxqlr = "http://graph.x.ql/resolvers" 
    at 
    "/graphXql/resolvers/person-resolver.xqy", 
    "/graphXql/resolvers/event-resolver.xqy",
    "/graphXql/resolvers/document-resolver.xqy",
    "/graphXql/resolvers/delegation-resolver.xqy",
    "/graphXql/resolvers/mutation-resolver.xqy";

import schema namespace gxql = "http://graph.x.ql" at "/graphxql/entity-types.xsd";

declare function gxqlr:get-entity-resolver($entity-name as xs:string) as xdmp:function
{
         if ($entity-name eq ('person', 'hero', 'foe')) then xdmp:function(xs:QName('gxqlr:person-entity-resolver'))
    else if ($entity-name eq 'event')       then xdmp:function(xs:QName('gxqlr:event-entity-resolver'))
    else if ($entity-name eq 'document')    then xdmp:function(xs:QName('gxqlr:document-entity-resolver'))
    else if ($entity-name eq 'delegation')  then xdmp:function(xs:QName('gxqlr:delegation-entity-resolver'))
    else  fn:error((), 'DISPATCHER EXCEPTION', ("500", "Internal server error", "unexpected entity name: ", $entity-name))
};

declare function gxqlr:get-field-resolver($entity as element(), $field-name as xs:string) as xdmp:function
{
    (
        xdmp:log('[gxqlr:get-field-resolver] $entity: '||xdmp:describe($entity, (), ()), 'debug')
        ,xdmp:log('[gxqlr:get-field-resolver] $field-name: '||$field-name, 'debug')
    ),

    typeswitch ($entity)
        case $o as element(*, gxql:Person) return gxqlr:person-field-resolver($field-name)
        case $o as element(*, gxql:Event) return gxqlr:event-field-resolver($field-name)
        case $o as element(*, gxql:Document) return gxqlr:document-field-resolver($field-name)
        case $o as element(*, gxql:Delegation) return gxqlr:delegation-field-resolver($field-name)
        default return fn:error((), 'DISPATCHER EXCEPTION', ("500", "Internal server error", "unexpected entity type: ", xdmp:describe($entity, (), ())))
};

declare function gxqlr:get-entity-type($entity as element()) as xs:string
{
    (
        xdmp:log('[gxqlr:get-entity-type] $entity: '||xdmp:describe($entity, (), ()), 'debug')
    ),

    typeswitch ($entity)
        case $p as element(*, gxql:Hero) return 'Hero'
        case $p as element(*, gxql:Foe) return 'Foe'
        case $p as element(*, gxql:Person) return 'Person'
        default return fn:error((), 'DISPATCHER EXCEPTION', ("500", "Internal server error", "unknown entity type", $entity))
};

declare function gxqlr:mutation-resolver($mutation-name as xs:string) as xdmp:function
{
    switch ($mutation-name)
        case 'createParticipant' return xdmp:function(xs:QName('gxqlr:createParticipant'))
        default return fn:error((), 'DISPATCHER EXCEPTION', ("500", "Internal server error", "unknown mutation name", $mutation-name))
};

