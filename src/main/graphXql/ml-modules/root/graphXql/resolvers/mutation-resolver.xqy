xquery version "1.0-ml";

module namespace gxqlr = "http://graph.x.ql/resolvers";

import schema namespace gxql ="http://graph.x.ql" 
    at "/graphxql/entities/graphXql-types.xsd";

declare default element namespace "http://graph.x.ql";



declare function gxqlr:createParticipant($variables as map:map) {
    (
        xdmp:log('[gxqlr:createParticipant] $variables: '||xdmp:describe($variables, (), ()), 'debug')
    ),

    let $event-uri := fn:concat('/graphXql/event/', map:get($variables, 'id'))
    let $event := fn:doc($event-uri)/node()
    let $collections := xdmp:document-get-collections($event-uri)
    let $event := 
        document {
            element {xs:QName('gxql:event')}
            {
                $event/namespace::*,
                $event/@*,
                $event/(* except (./gxql:participants)),
                <gxql:participants>
                    {$event/gxql:participants/gxql:person}
                    <gxql:person>
                        <gxql:id>{map:get($variables, 'participant')}</gxql:id>
                    </gxql:person>
                </gxql:participants>        
            }
        }
    return 
    (
        xdmp:document-insert($event-uri, $event, (), $collections), 
        xdmp:commit()
    )
};