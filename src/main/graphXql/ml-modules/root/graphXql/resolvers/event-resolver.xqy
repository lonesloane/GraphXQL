xquery version "1.0-ml";

module namespace gxqlr = "http://graph.x.ql/resolvers";

import schema namespace gxql ="http://graph.x.ql" 
    at "/graphxql/entities/graphXql-types.xsd";

declare default element namespace "http://graph.x.ql";

declare function gxqlr:event-field-resolver($field-name as xs:string) as xdmp:function
{
         if ($field-name eq 'title') then xdmp:function(xs:QName('gxqlr:event-title-resolver'))
    else if ($field-name eq 'location') then xdmp:function(xs:QName('gxqlr:event-location-resolver'))
    else if ($field-name eq 'startDate') then xdmp:function(xs:QName('gxqlr:event-start-date-resolver'))
    else if ($field-name eq 'endDate') then xdmp:function(xs:QName('gxqlr:event-end-date-resolver'))
    else if ($field-name eq 'participants') then xdmp:function(xs:QName('gxqlr:event-participants-resolver'))
    else fn:error((), 'EVENT FIELD RESOLVER EXCEPTION', ("500", "Internal server error", "unexpected token kind: "||$field-name))
};

declare function gxqlr:event-entity-resolver($var-map as map:map) as element(*, gxql:Event)
{
    if (map:contains($var-map, 'id'))
    then 
    (
        let $event-uri := fn:concat('/graphXql/event/', map:get($var-map, 'id'))
        return fn:doc($event-uri)/node()
    )
    else fn:error((), 'entity-resolver EXCEPTION', ("500", "Internal server error", "No identifier received in variables: ", $var-map))
};

declare function gxqlr:event-title-resolver($event as element(), $var-map as map:map)
{
    $event/title/string()
};

declare function gxqlr:event-location-resolver($event as element(), $var-map as map:map)
{
    $event/location/string()
};

declare function gxqlr:event-start-date-resolver($event as element(), $var-map as map:map)
{
    $event/start-date/string()
};

declare function gxqlr:event-end-date-resolver($event as element(), $var-map as map:map)
{
    $event/end-date/string()
};

declare function gxqlr:event-participants-resolver($event as element(), $var-map as map:map) as element(*, gxql:Person)*
{
    let $participant-ids := $event/participants/person/id/string()
    let $person-uris := $participant-ids!fn:concat('/graphXql/person/', .)
    return $person-uris!fn:doc(.)/node()
};