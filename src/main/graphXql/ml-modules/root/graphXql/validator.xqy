
xquery version "1.0-ml";

module namespace validator = "http://graph.x.ql/validator";
import module namespace builder = "http://graph.x.ql/schema-builder" 
    at "/graphXql/schema-builder.xqy";

declare namespace gxqls = "http://graph.x.qls";

declare variable $validator:SCHEMA as element(*, gxqls:Schema) := builder:build-graphXql-schema();
declare variable $validator:GRAPHQL-ERRORS := ();
declare variable $validator:KNOWN-OPERATION-NAMES as map:map := map:map();
declare variable $validator:KNOWN-VARIABLE-NAMES as map:map := map:map();
declare variable $validator:KNOWN-ARGUMENT-NAMES as map:map := map:map();
declare variable $validator:KNOWN-FRAGMENT-NAMES as map:map := map:map();
declare variable $validator:KNOWN-INPUT-FIELD-NAMES as map:map := map:map();

declare function validator:validate($node as node())
{
    validator:validate($node, map:map())
};

declare function validator:validate($node as node(), $variables as map:map)
{
    xdmp:set($validator:GRAPHQL-ERRORS, ())

    ,map:clear($validator:KNOWN-OPERATION-NAMES)
    ,map:clear($validator:KNOWN-VARIABLE-NAMES)
    ,map:clear($validator:KNOWN-ARGUMENT-NAMES)
    ,map:clear($validator:KNOWN-FRAGMENT-NAMES)
    ,map:clear($validator:KNOWN-INPUT-FIELD-NAMES)

    ,validator:match($node, (map:map() => map:with('node', $node)))
    
    ,validator:report($validator:GRAPHQL-ERRORS)
};

declare function validator:match($node as node(), $context as map:map?) 
{
    xdmp:log('[validator:match]: '||$node/name()),

    switch($node/name())

    (: TODO: lone-schema-definition :)
    (: TODO: unique-directives-per-location :)
    (: TODO: unique-operation-types :)
    (: TODO: unique-type-names :)
    (: TODO: overlapping-fields-can-be-merged :)
    (: TODO: possible-type-extensions :)
    (: TODO: single-field-subscription :)
    (: TODO: unique-directive-names :)
    (: TODO: unique-enum-value-names :)
    (: TODO: unique-field-definition-names :)
    case 'document'
    return
        (
            validator:no-unused-fragments($node, $context)
            ,validator:match($node/child::*, $context)        
        )
    case 'definitions'
    return 
        (
            validator:executable-definitions($node, $context)
            ,validator:match($node/child::*, $context)        
        )

    case 'operation-definition'
    return 
        (
            map:clear($validator:KNOWN-VARIABLE-NAMES)
            ,map:put($context, 'location', (map:get($context, 'location'),fn:upper-case($node/@operation/string())))
            ,map:put($context, 'operation-definition', $node/name/@value/string())

            ,validator:unique-operation-name($node, $context)
            ,validator:lone-anonymous-operation($node, $context)
            ,validator:single-field-subscription($node, $context)
            ,validator:no-undefined-variables($node, $context)
            ,validator:no-unused-variables($node, $context)
            ,validator:match($node/child::*, $context)        

            ,map:put($context, 'location', map:get($context, 'location')[position() lt last()])
            ,map:delete($context, 'operation-definition')
        )

    case 'variable-definition'
    return
        (
            map:put($context, 'location', (map:get($context, 'location'),fn:upper-case($node/name())))

            ,validator:unique-variable-name($node/variable, $context)
            ,validator:variables-are-input-types($node, $context)
            ,validator:variables-in-allowed-position($node, $context)
            ,validator:match($node/child::*, $context)        

            ,map:put($context, 'location', map:get($context, 'location')[position() lt last()])
        )

    case 'fragment-definition'
    case 'fragment-spread'
    case 'inline-fragment'
    return 
        (
            map:put($context, 'location', (map:get($context, 'location'),fn:upper-case($node/name())))
            ,map:put($context, 'fragment', $node/name/@value/string())

            ,validator:fragment-on-composite-type($node, $context)
            ,(if ($node/name() = ('fragment-spread', 'inline-fragment')) then validator:possible-fragment-spread($node, $context) else ())
            ,(if ($node/name()='fragment-spread') then validator:known-fragment-names($node, $context) else ())
            ,(if ($node/name()='fragment-definition') 
                then 
                (
                    validator:no-fragment-cycles($node, $context) 
                    ,validator:unique-fragment-name($node, $context)
                )
                else ())
            ,validator:match($node/child::*, $context)

            ,map:delete($context, 'fragment')
            ,map:put($context, 'location', map:get($context, 'location')[position() lt last()])
        )

    case 'selection-set'
    return
        (
            (
                for $field in $node/field
                    let $_ := map:clear($validator:KNOWN-ARGUMENT-NAMES)
                    let $entity-name := $field/name/@value/string()
                    let $entity-type := 
                        if ($validator:SCHEMA/gxqls:Query/gxqls:fields/gxqls:field[@name/string() = $entity-name]) 
                        then $validator:SCHEMA/gxqls:Query/gxqls:fields/gxqls:field[@name/string() = $entity-name]/gxqls:Type/@name/string()
                        else if ($validator:SCHEMA/gxqls:types/child::*[fn:upper-case(@name/string()) = fn:upper-case($entity-name)])
                        then $validator:SCHEMA/gxqls:types/child::*[fn:upper-case(@name/string()) = fn:upper-case($entity-name)]/@name/string()
                        else 
                            if (map:get($context, 'type-hierarchy')[last()] 
                                and $validator:SCHEMA/gxqls:types/child::*[fn:lower-case(@name/string()) = fn:lower-case(map:get($context, 'type-hierarchy')[last()])]/gxqls:fields/gxqls:field[@name/string() = $entity-name])
                            then $validator:SCHEMA/gxqls:types/child::*[fn:lower-case(@name/string()) = fn:lower-case(map:get($context, 'type-hierarchy')[last()])]/gxqls:fields/gxqls:field[@name/string() = $entity-name]/gxqls:Type/@name/string()
                            else ()
                    return 
                        validator:match($field, $context)
            )
            ,validator:match($node/(child::* except field), $context)
        )

    case 'field'
    return 
        (
            map:put($context, 'field', $node/name/@value/string())
            ,map:put($context, 'location', (map:get($context, 'location'),fn:upper-case($node/name())))
            ,map:clear($validator:KNOWN-ARGUMENT-NAMES)

            ,validator:field-on-correct-type($node, $context)
            ,validator:provided-required-arguments($node, $context)
            ,validator:scalar-leaf($node, $context)
            ,validator:match($node/child::*, $context)        

            ,map:delete($context, 'field')
            ,map:put($context, 'location', map:get($context, 'location')[position() lt last()])
        )

    case 'directive'
    return 
        (
            map:put($context, 'directive', $node/name/@value/string())
            ,map:clear($validator:KNOWN-ARGUMENT-NAMES)

            ,validator:known-directive($node, $context)
            ,validator:provided-required-arguments-on-directive($node, $context)
            ,validator:match($node/child::*, $context)        

            ,map:delete($context, 'directive')
        )

    case 'argument'
    return 
        (
            map:put($context, 'argument', $node/name/@value/string())

            ,validator:unique-argument-name($node, $context)
            ,validator:known-argument-name($node, $context)
            ,validator:values-of-correct-type($node, $context)
            ,validator:match($node/child::*, $context)        

            ,map:delete($context, 'argument')
        )

    case 'value'
    return
        (
            validator:match($node/child::*, $context)        
        )

    case 'named-type'
    return
        (
            validator:known-type-name($node, $context)
        )

    case 'object'
    return
    (    
        if (map:contains($context, 'object')) 
        then map:put($context, 'object', (map:get($context, 'object'), (1 + map:get($context, 'object')[last()]))) 
        else map:put($context, 'object', (1))        
        ,if (map:contains($validator:KNOWN-INPUT-FIELD-NAMES, xs:string(map:get($context, 'object')[last()]))) 
        then () 
        else map:put($validator:KNOWN-INPUT-FIELD-NAMES, xs:string(map:get($context, 'object')[last()]), map:map())

        ,validator:match($node/child::*, $context)        
        
        ,map:delete($validator:KNOWN-INPUT-FIELD-NAMES, xs:string(map:get($context, 'object')[last()]))
        ,map:put($context, 'object', map:get($context, 'object')[1 to last()-1])
    )

    case 'object-field'
    return
    (
        validator:unique-input-field-names($node, $context)
        ,validator:match($node/child::*, $context)        
    )

    default
    return 
        (
            if ($node/child::*)
            then validator:match($node/child::*, $context)  
            else ()
        )
};

(: 
    Fragments on composite type

    Fragments use a type condition to determine if they apply, since fragments
    can only be spread into a composite type (object, interface, or union), the
    type condition must also be a composite type.
:)
declare function validator:fragment-on-composite-type($field as node(), $context as map:map)
{
    (
        xdmp:log('[validator:fragment-on-composite-type] $field', 'fine')
        ,xdmp:log($field, 'fine')
        ,for $key in map:keys($context)[not(. = 'node')] return map:get($context, $key)!xdmp:log('[validator:fragment-on-composite-type] '||$key||': '||.)
    ),
    
    if (not($field/type-condition/named-type)) 
    then ()
    else
        let $type-name := $field/type-condition/named-type/name/@value/string()
        return
            if (fn:exists($validator:SCHEMA/gxqls:types/child::*[@name/string() = $type-name]) 
                and validator:type-kind-resolver($type-name) = ('OBJECT', 'INTERFACE', 'UNION')) 
            then ()
            else 
            (
                if ($field/name() = 'fragment-definition') 
                then
                    let $error-message := 'Fragment '||$field/name/@value/string()||' cannot condition on non composite type '||$type-name||'.'
                    let $line := ($field/name/location/token)[1]/@line/string()
                    let $column := ($field/name/location/token)[1]/@column/string()
                    let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)} }
                    return
                        xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('FRAGMENT-ON-COMPOSITE-TYPE',$error-message, $error-location)))
                else if ($field/name() = 'inline-fragment') 
                then 
                    let $error-message := 'Fragment cannot condition on non composite type '||$type-name||'.'
                    let $line := ($field/type-condition/named-type/name/location/token)[1]/@line/string()
                    let $column := ($field/type-condition/named-type/name/location/token)[1]/@column/string()
                    let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)} }
                    return
                        xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('FRAGMENT-ON-COMPOSITE-TYPE', $error-message, $error-location)))
                else () (: TODO: throw exception :)
            )
};

declare function validator:type-kind-resolver($type-name as xs:string) as xs:string
{
    (: TODO: refactor to combine with introspection module :)
    if ($type-name = ('Int', 'Float', 'String', 'Boolean', 'ID')) 
    then 'SCALAR'
    else 
    (
        let $kind := ''
        let $kind := if ($validator:SCHEMA/gxqls:types/child::*[@name/string() = $type-name]) then 'OBJECT' else $kind
        let $kind := if ($validator:SCHEMA/gxqls:types/child::*/gxqls:interface[./gxqls:Type/@name/string() = $type-name]) then 'INTERFACE' else $kind
        (: TODO: implement UNION :)
        return $kind
    )
};

(: 
    Fields on correct type

    A GraphQL document is only valid if all fields selected are defined by the
    parent type, or are an allowed meta field such as __typename.
:)
declare function validator:field-on-correct-type($field as node(), $context as map:map)
{
    (
        xdmp:log('[validator:field-on-correct-type] $field: ', 'fine')
        ,xdmp:log($field, 'fine')
        ,for $key in map:keys($context)[not(. = 'node')] return map:get($context, $key)!xdmp:log('[validator:field-on-correct-type] '||$key||': '||.)
    ),

    let $field-name := $field/name/@value/string()
    let $type-name := 
        if ($field/ancestor::selection-set[1]/parent::field) 
        then $field/ancestor::selection-set[1]/parent::field/name/@value/string()
        else if ($field/ancestor::selection-set[1]/parent::*[local-name()=('fragment-definition', 'inline-fragment')])
        then $field/ancestor::selection-set[1]/parent::*[local-name()=('fragment-definition', 'inline-fragment')]/type-condition/named-type/name/@value/string()
        else ()
    let $type := 
        if ($validator:SCHEMA/gxqls:Query/gxqls:fields/gxqls:field[@name/string() = $type-name]) 
        then $validator:SCHEMA/gxqls:Query/gxqls:fields/gxqls:field[@name/string() = $type-name]/gxqls:Type/@name/string()
        else if ($validator:SCHEMA/gxqls:types/child::*[fn:upper-case(@name/string()) = fn:upper-case($type-name)])
        then $validator:SCHEMA/gxqls:types/child::*[fn:upper-case(@name/string()) = fn:upper-case($type-name)]/@name/string()
        else ()
    return
        if (fn:exists($validator:SCHEMA/gxqls:types/child::*[@name/string() = $type])) 
        then
            if (not(fn:lower-case($field-name)= fn:lower-case($type-name)) and not(validator:lookup-type-field($type, $field-name)))
            then 
            (
                let $error-message := "Cannot query field "||$field-name||" on type "||$type-name||"."
                let $suggestion := validator:suggest-field-names($type, $field-name)
                let $error-message := 
                    if ($suggestion) 
                    then $error-message||fn:concat(' Available fields are ', fn:string-join($suggestion, ', '), '.')
                    else $error-message
                let $line := ($field/name/location/token)[1]/@line/string()
                let $column := ($field/name/location/token)[1]/@column/string()
                let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)} }
                return
                    xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('FIELD-ON-CORRECT-TYPE', $error-message, $error-location)))
            )
            else ()
        else ()
};

declare function validator:suggest-field-names($type, $field-name) as xs:string*
{ 
    $validator:SCHEMA/gxqls:types/child::*[@name/string() = $type]/gxqls:fields/gxqls:field/@name/string()
};

declare function validator:lookup-type-field($type as xs:string, $field-name as xs:string) as xs:boolean
{
    if ($field-name = '__typename') (: allowed meta fields :)
    then 
        xs:boolean('true')
    else
        fn:exists($validator:SCHEMA/gxqls:types/child::*[@name/string() = $type]/gxqls:fields/gxqls:field[@name/string() = $field-name])
};

(: 
    Subscriptions must only include one field.

    A GraphQL subscription is valid only if it contains a single root field.
:)
declare function validator:single-field-subscription($operation as node(), $context as map:map)
{
    (
        xdmp:log('[validator:single-field-subscription] $operation: ', 'fine')
        ,xdmp:log($operation, 'fine')
        ,for $key in map:keys($context)[not(. = 'node')] return map:get($context, $key)!xdmp:log('[validator:single-field-subscription] '||$key||': '||.)
    ),

    if 
    (
        $operation/@operation 
        and $operation/@operation/string() eq 'subscription'
        and fn:count($operation/selection-set/field) gt 1
    )
    then 
    (
        let $error-message := if ($operation/name) 
                                then "Subscription "||$operation/name/@value/string()||" must select only one top level field."
                                else "Anonymous subscription must select only one top level field."

        let $line := ($operation/location/token)[1]/@line/string()
        let $column := ($operation/location/token)[1]/@column/string()
        let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
        return
        xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('SINGLE-FIELD-SUBSCRIPTION', $error-message, $error-location)))
    )
    else ()
};

(: 
    Lone anonymous operation

    A GraphQL document is only valid if when it contains an anonymous operation
    (the query short-hand) that it contains only that one operation definition.
:)
declare function validator:lone-anonymous-operation($operation as node(), $context as map:map)
{
    (
        xdmp:log('[validator:lone-anonymous-operation] $operation', 'fine')
        ,xdmp:log($operation, 'fine')
        ,for $key in map:keys($context)[not(. = 'node')] return map:get($context, $key)!xdmp:log('[validator:lone-anonymous-operation] '||$key||': '||.)
    ),

    if 
    (
        $operation/@name 
        and $operation/@name/string() eq 'undefined'
        and fn:count($operation/ancestor::document//operation-definition) gt 1
    )
    then 
    (
        let $error-message := "This anonymous operation must be the only defined operation."
        let $line := ($operation/location/token)[1]/@line/string()
        let $column := ($operation/location/token)[1]/@column/string()
        let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
        return
        xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('LONE-ANONYMOUS-OPERATION', $error-message, $error-location)))
    )
    else ()
};

(: 
    Unique operation names

    A GraphQL document is only valid if all defined operations have unique names.
:)
declare function validator:unique-operation-name($operation as node(), $context as map:map)
{
    (
        xdmp:log('[validator:unique-operation-name] $operation', 'fine')
        ,xdmp:log($operation, 'fine')
        ,for $key in map:keys($context)[not(. = 'node')] return map:get($context, $key)!xdmp:log('[validator:unique-operation-name] '||$key||': '||.)
    ),

    if 
    (
        $operation/name/@value 
        and map:contains($validator:KNOWN-OPERATION-NAMES, $operation/name/@value/string())
    )
    then
    (
        let $name := $operation/name/@value/string()
        let $error-message := "There can be only one operation named "||$name||"."
        let $error-locations := 
            array-node 
            { 
                for $operation-name in (map:get($validator:KNOWN-OPERATION-NAMES, $operation/name/@value/string()), $operation/name)
                (: TODO: investigate strange bug causing multiple location tokens. Spooky! :)
                let $line := ($operation-name/location/token)[1]/@line/string()
                let $column := ($operation-name/location/token)[1]/@column/string()
                where $operation-name/@value/string() = $operation/name/@value/string()
                return
                    object-node {"line": xs:int($line), "column": xs:int($column)}
            }
        return
            xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('UNIQUE-OPERATION-NAME', $error-message, $error-locations)))
    ) 
    else 
        map:put($validator:KNOWN-OPERATION-NAMES, $operation/name/@value/string(), $operation/name)
};

(: 
    Unique variable names

    A GraphQL operation is only valid if all its variables are uniquely named.
:)
declare function validator:unique-variable-name($variable as node(), $context as map:map)
{
    (
        xdmp:log('[validator:unique-variable-name] $variable', 'fine')
        ,xdmp:log($variable, 'fine')
        ,for $key in map:keys($context)[not(. = 'node')] return map:get($context, $key)!xdmp:log('[validator:unique-variable-name] '||$key||': '||.)
    ),

    if 
    (
        $variable/name/@value 
        and map:contains($validator:KNOWN-VARIABLE-NAMES, $variable/name/@value/string())
    )
    then
    (
        let $name := $variable/name/@value/string()
        let $error-message := "There can be only one variable named "||$name||"."
        let $error-locations := 
            array-node 
            { 
                for $variable-name in (map:get($validator:KNOWN-VARIABLE-NAMES, $variable/name/@value/string()), $variable/name)
                (: TODO: investigate strange bug causing multiple location tokens. Spooky! :)
                let $line := ($variable-name/location/token)[1]/@line/string()
                let $column := ($variable-name/location/token)[1]/@column/string()
                where $variable-name/@value/string() = $variable/name/@value/string()
                return
                    object-node {"line": xs:int($line), "column": xs:int($column)}
            }
        return
            xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('UNIQUE-VARIABLE-NAME', $error-message, $error-locations)))
    ) 
    else 
        map:put($validator:KNOWN-VARIABLE-NAMES, $variable/name/@value/string(), $variable/name)
};

(: 
    Unique argument names

    A GraphQL field or directive is only valid if all supplied arguments are
    uniquely named.
:)
declare function validator:unique-argument-name($argument as node(), $context as map:map)
{
    (
        xdmp:log('[validator:unique-argument-name] $argument', 'fine')
        ,xdmp:log($argument, 'fine')
        ,for $key in map:keys($context)[not(. = 'node')] return map:get($context, $key)!xdmp:log('[validator:unique-argument-name] '||$key||': '||.)
    ),

    if 
    (
        $argument/name/@value 
        and map:contains($validator:KNOWN-ARGUMENT-NAMES, $argument/name/@value/string())
    )
    then
    (
        let $name := $argument/name/@value/string()
        let $error-message := "There can be only one argument named "||$name||"."
        let $error-locations := 
            array-node 
            { 
                for $argument-name in (map:get($validator:KNOWN-ARGUMENT-NAMES, $argument/name/@value/string()), $argument/name)
                (: TODO: investigate strange bug causing multiple location tokens. Spooky! :)
                let $line := ($argument-name/location/token)[1]/@line/string()
                let $column := ($argument-name/location/token)[1]/@column/string()
                where $argument-name/@value/string() = $argument/name/@value/string()
                return
                    object-node {"line": xs:int($line), "column": xs:int($column)}
            }
        return
            xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('UNIQUE-ARGUMENT-NAME', $error-message, $error-locations)))
    ) 
    else 
        map:put($validator:KNOWN-ARGUMENT-NAMES, $argument/name/@value/string(), $argument/name)
};

(:
    Known argument names

    A GraphQL field is only valid if all supplied arguments are defined by
    that field.
:)
declare function validator:known-argument-name($argument as node(), $context as map:map)
{
    (
        xdmp:log('[validator:known-argument-name] $argument', 'fine')
        ,xdmp:log($argument, 'fine')
        ,for $key in map:keys($context)[not(. = 'node')] return map:get($context, $key)!xdmp:log('[validator:known-argument-name] '||$key||': '||.)
    ),

    if (map:contains($context, 'directive')) 
    then validator:known-directive-argument-name($argument, $context)
    else if (map:contains($context, 'field'))
    then validator:known-field-argument-name($argument, $context)
    else fn:error((), 'validator:known-argument-name EXCEPTION', ("500", "Internal server error", "Invalid context"))
};

declare function validator:known-field-argument-name($argument as node(), $context as map:map)
{
    let $argument-name := $argument/name/@value/string()
    let $field-name := map:get($context, 'field')
    let $field := $argument/ancestor::field[./name/@value/string() = $field-name]
    let $type-name := 
        if ($field/ancestor::selection-set[1]/parent::field) 
        then $field/ancestor::selection-set[1]/parent::field/name/@value/string()
        else if ($field/ancestor::selection-set[1]/parent::*[local-name()=('fragment-definition', 'inline-fragment')])
        then $field/ancestor::selection-set[1]/parent::*[local-name()=('fragment-definition', 'inline-fragment')]/type-condition/named-type/name/@value/string()
        else ()

    let $schema-type := $validator:SCHEMA/gxqls:types/child::*[@name/string() = $type-name]
    let $schema-field := if ($schema-type) then $schema-type/gxqls:fields/gxqls:field[@name/string() = $field-name] else ()
    let $schema-arg := if ($schema-field) then $schema-field/gxqls:args/gxqls:Arg[@name/string() = $argument-name] else ()

    return
    if (not($schema-arg) and $schema-type and $schema-field) 
    then 
    (
        let $available-args := $schema-field/gxqls:args/gxqls:Arg/@name/string()
        let $error-message := "Unknown argument ["||$argument-name||"] on field ["||$type-name||"."||$field-name||"]."
        let $error-message := if ($available-args) then $error-message||" Available arguments: ["||fn:string-join($available-args, ', ')||"]" else $error-message
        let $line := ($argument/name/location/token)[1]/@line/string()
        let $column := ($argument/name/location/token)[1]/@column/string()
        let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
        return
        xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('KNOWN-ARGUMENT-NAME', $error-message, $error-location)))
    )
    else ()
};

declare function validator:known-directive-argument-name($argument as node(), $context as map:map)
{
    let $argument-name := $argument/name/@value/string()
    let $directive-name := map:get($context, 'directive')

    let $schema-directive := $validator:SCHEMA/gxqls:directives/gxqls:Directive[@name/string() = $directive-name]
    let $schema-arg := if ($schema-directive) then $schema-directive/gxqls:args/gxqls:Arg[@name/string() = $argument-name] else ()

    return
    if (not($schema-arg) and $schema-directive) 
    then 
    (
        let $available-args := $schema-directive/gxqls:args/gxqls:Arg/@name/string()
        let $error-message := "Unknown argument ["||$argument-name||"] on directive ["||$directive-name||"]."
        let $error-message := if ($available-args) then $error-message||" Available arguments: ["||fn:string-join($available-args, ', ')||"]" else $error-message
        let $line := ($argument/name/location/token)[1]/@line/string()
        let $column := ($argument/name/location/token)[1]/@column/string()
        let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
        return
        xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('KNOWN-ARGUMENT-NAME', $error-message, $error-location)))
    )
    else ()
};

(: 
    Executable definitions

    A GraphQL document is only valid for execution if all definitions are either
    operation or fragment definitions.
:)
declare function validator:executable-definitions($definitions as node(), $context as map:map)
{
    (
        xdmp:log('[validator:executable-definitions] $definitions', 'fine')
        ,xdmp:log($definitions, 'fine')
        ,for $key in map:keys($context)[not(. = 'node')] return map:get($context, $key)!xdmp:log('[validator:executable-definitions] '||$key||': '||.)
    ),

    for $definition in $definitions/child::*
    return
        if (not($definition/name() = ('operation-definition', 'fragment-definition')))
        then
            (
                let $executable := fn:tokenize($definition/name(), '-')[1]
                let $name := $definition/name/@value/string()
                let $error-message := "The "||fn:string-join(($executable, $name), ' ')||" definition is not executable"
                let $line := ($definition/location/token)[1]/@line/string()
                let $column := ($definition/location/token)[1]/@column/string()
                let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
                return
                xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('EXECUTABLE-DEFINITION', $error-message, $error-location)))
            ) 
        else ()
};

(: 
    Known directives

    A GraphQL document is only valid if all `@directives` are known by the
    schema and legally positioned.
:)
declare function validator:known-directive($directive as node(), $context as map:map)
{
    (
        xdmp:log('[validator:known-directive] $directive: ', 'fine')
        ,xdmp:log($directive, 'fine')
        ,for $key in map:keys($context)[not(. = 'node')] return map:get($context, $key)!xdmp:log('[validator:known-directive] '||$key||': '||.)
    ),

    let $directive-name := $directive/name/@value/string()
    let $schema-directive := $validator:SCHEMA/gxqls:directives/gxqls:Directive[@name/string() = $directive-name]

    return
    if (not($schema-directive)) 
    then 
    (
        let $error-message := "Unknown directive [@"||$directive-name||"]."
        let $line := ($directive/name/location/token)[1]/@line/string()
        let $column := ($directive/name/location/token)[1]/@column/string()
        let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
        return
        xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('KNOWN-DIRECTIVE', $error-message, $error-location)))
    )
    else 
    (
        let $directive-location := $schema-directive/gxqls:locations/gxqls:location/string()
        return
        if (not(map:contains($context, 'location')) or not(map:get($context, 'location')[last()] = $directive-location)) 
        then
        (
            let $error-message := "Directive ["||$directive-name||"] may not be used on ["||map:get($context, 'location')[last()]||"]."
            let $line := ($directive/name/location/token)[1]/@line/string()
            let $column := ($directive/name/location/token)[1]/@column/string()
            let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
            return
            xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('KNOWN-DIRECTIVE', $error-message, $error-location)))
        )
        else () 
    )
};

(: 
    Known fragment names

    A GraphQL document is only valid if all `...Fragment` fragment spreads refer
    to fragments defined in the same document.
:)
declare function validator:known-fragment-names($fragment-spread as node(), $context as map:map)
{
    (
        xdmp:log('[validator:known-fragment-names] $fragment-spread: ', 'fine')
        ,xdmp:log($fragment-spread, 'fine')
        ,for $key in map:keys($context)[not(. = 'node')] return map:get($context, $key)!xdmp:log('[validator:known-fragment-names] '||$key||': '||.)
    ),

    let $fragment-spread-name := $fragment-spread/name/@value/string()
    let $node := map:get($context, 'node')
    let $available-fragments := $node//fragment-definition/name/@value/string()
    return 
    (
        if (not($fragment-spread-name = $available-fragments))
        then 
        (
            let $error-message := "Unknown fragment ["||$fragment-spread-name||"]."
            let $line := ($fragment-spread/name/location/token)[1]/@line/string()
            let $column := ($fragment-spread/name/location/token)[1]/@column/string()
            let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
            return
            xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('KNOWN-FRAGMENT-NAME', $error-message, $error-location)))
        )
        else ()
    )
};

(: 
    Known type names

    A GraphQL document is only valid if referenced types (specifically
    variable definitions and fragment conditions) are defined by the type schema.
:)
declare function validator:known-type-name($named-type as node(), $context as map:map)
{
    (
        xdmp:log('[validator:known-type-name] $named-type: ', 'fine')
        ,xdmp:log($named-type, 'fine')
        ,for $key in map:keys($context)[not(. = 'node')] return map:get($context, $key)!xdmp:log('[validator:known-type-name] '||$key||': '||.)
    ),

    let $type-name := $named-type/name/@value/string()
    return
    if (not($type-name = fn:distinct-values($validator:SCHEMA//gxqls:Type/@name/string()))
        and not($type-name = fn:distinct-values($validator:SCHEMA//gxqls:InputType/@name/string()))
        and not($type-name = fn:distinct-values($validator:SCHEMA//gxqls:UnionType/@name/string()))) (: TODO: refactor to harmonze rule :)
    then
    (
        let $error-message := "Unknown type ["||$type-name||"]."
        let $line := ($named-type/name/location/token)[1]/@line/string()
        let $column := ($named-type/name/location/token)[1]/@column/string()
        let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
        return
        xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('KNOWN-TYPE-NAME', $error-message, $error-location)))
    )
    else ()
};

declare function validator:no-fragment-cycles($fragment-definition as node(), $context as map:map)
{
    (
        xdmp:log('[validator:no-fragment-cycles] $fragment-definition: ', 'fine')
        ,xdmp:log($fragment-definition, 'fine')
        ,for $key in map:keys($context)[not(. = 'node')] return map:get($context, $key)!xdmp:log('[validator:no-fragment-cycles] '||$key||': '||.)
    ),

    let $node := map:get($context, 'node')
    let $target-names := $fragment-definition/name/@value/string()
    return
    for $target-name in $target-names
        let $current-name := $target-name
        let $cycle-path := map:map()
        let $visited := map:map()
        let $path := ()
        let $_ := validator:detect-cycles($target-name, $current-name, $node, $path, $cycle-path, $visited)
        return 
        (
            if (map:count($cycle-path) gt 0)
            then
            (
                for $path in map:keys($cycle-path)
                    let $path-steps := fn:tokenize($path, '\|')
                    let $error-message := "Cannot spread fragment ["||$target-name||"] within itself"
                    let $error-message := 
                        if (fn:count($path-steps) gt 0) 
                        then $error-message||" via ["||fn:string-join($path-steps, " ,")||"]."
                        else $error-message||"."
                    let $error-location := 
                        array-node 
                        {
                            for $step in $path-steps
                            let $fragment := $node//fragment-definition[./name/@value/string() = $step]
                            let $line := ($fragment/name/location/token)[1]/@line/string()
                            let $column := ($fragment/name/location/token)[1]/@column/string()
                            return object-node {"line": xs:int($line), "column": xs:int($column)}
                        }
                    return
                    xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('NO-FRAGMENT-CYCLES', $error-message, $error-location)))
            )
            else ()

        )
};

declare function validator:detect-cycles($fragment-name as xs:string, $current-name as xs:string, $node as node(), $path as xs:string*, $cycle-path as map:map, $visited as map:map) 
{
    let $child-fragment-names := $node//fragment-definition[./name/@value/string() = $current-name]//fragment-spread/name/@value/string()[not(. = map:keys($visited))]
    return
    (
        map:put($visited, $current-name, xs:boolean('true')),
        for $child-fragment-name in $child-fragment-names
            let $child-fragment-definition := $node//fragment-definition[./name/@value/string() = $child-fragment-name]
            let $path := fn:string-join(($path, $child-fragment-name), '|')
            return
                if ($child-fragment-definition//fragment-spread[./name/@value/string() = $fragment-name]) 
                then map:put($cycle-path, $path, $fragment-name)
                else validator:detect-cycles($fragment-name, $child-fragment-name, $node, $path, $cycle-path, $visited)
    )
};

(: 
    No undefined variables

    A GraphQL operation is only valid if all variables encountered, both directly
    and via fragment spreads, are defined by that operation.
:)
declare function validator:no-undefined-variables($operation as node(), $context as map:map)
{
    (
        xdmp:log('[validator:no-undefined-variables] $operation: ', 'fine')
        ,xdmp:log($operation, 'fine')
        ,for $key in map:keys($context)[not(. = 'node')] return map:get($context, $key)!xdmp:log('[validator:no-undefined-variables] '||$key||': '||.)
    ),

    let $node := map:get($context, 'node')
    let $operation-name := $operation/name/@value/string()
    
    let $defined-variable-names := $node/definitions/operation-definition[./name/@value/string() = $operation-name]/variable-definition/variable/name/@value/string()
    
    let $used-variables := $operation//argument//variable
    let $undefined-variables := $used-variables[not(./name/@value/string() = $defined-variable-names)]
    let $_ := validator:report-undefined-variables($operation, $undefined-variables)

    let $fragment-spreads := $operation//fragment-spread
    let $visited-fragments := map:map()
    for $fragment-spread in $fragment-spreads
    return 
    (
        map:put($visited-fragments, $fragment-spread/name/@value/string(), 'true'),
        validator:no-undefined-variables-in-fragment($fragment-spreads, $defined-variable-names, $operation, $node, $visited-fragments)      
    )
};

declare function validator:no-undefined-variables-in-fragment($fragment, $defined-variable-names, $operation, $node, $visited-fragments)
{
    let $fragment-name := $fragment/name/@value/string()
    let $fragment-definition := $node/definitions/fragment-definition[./name/@value/string() = $fragment-name]
    let $used-variables := $fragment-definition//argument//variable
    let $undefined-variables := $used-variables[not(./name/@value/string() = $defined-variable-names)]    
    let $_ := validator:report-undefined-variables($operation, $undefined-variables)

    let $fragment-spreads := $fragment-definition//fragment-spread
    for $fragment-spread in $fragment-spreads[not(./name/@value/string() = map:keys($visited-fragments))]
    return 
    (
        map:put($visited-fragments, $fragment-spread/name/@value/string(), 'true'),
        validator:no-undefined-variables-in-fragment($fragment-spreads, $defined-variable-names, $operation, $node, $visited-fragments)      
    )
};

declare function validator:report-undefined-variables($operation as node(), $undefined-variables as node()*)
{
    let $operation-name := $operation/name/@value/string()
    return
    if ($undefined-variables)
    then
    (
        for $undefined-variable in $undefined-variables
        let $error-message := "Variable [$"||$undefined-variable/name/@value/string()||"] is not defined"
        let $error-message := if ($operation-name) then $error-message||" by operation ["||$operation-name||"]." else $error-message||"."
        let $error-location := 
            array-node 
            {
                (   
                    if ($operation-name) then
                    (
                        let $line := ($operation/name/location/token)[1]/@line/string()
                        let $column := ($operation/name/location/token)[1]/@column/string()
                        return object-node {"line": xs:int($line), "column": xs:int($column)}
                    )
                    else ()
                ),
                (
                    let $line := ($undefined-variable/name/location/token)[1]/@line/string()
                    let $column := ($undefined-variable/name/location/token)[1]/@column/string()
                    return object-node {"line": xs:int($line), "column": xs:int($column)}
                )
            }
        return
            xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('NO-UNDEFINED-VARIABLES', $error-message, $error-location)))
    )
    else ()
};

declare function validator:no-unused-variables($operation as node(), $context as map:map)
{
    (
        xdmp:log('[validator:no-unused-variables] $operation: ', 'fine')
        ,xdmp:log($operation, 'fine')
        ,for $key in map:keys($context)[not(. = 'node')] return map:get($context, $key)!xdmp:log('[validator:no-unused-variables] '||$key||': '||.)
    ),

    let $node := map:get($context, 'node')
    let $operation-name := $operation/name/@value/string()
    let $visited-fragments := map:map()
    let $defined-variables := $operation//variable/name/@value/string()
    let $operation-fragments := $operation//fragment-spread/name/@value/string()
    let $referenced-fragments :=
        for $operation-fragment in $operation-fragments
        return validator:get-indirect-fragments($node, $operation-fragment, $visited-fragments)
    
    let $used-variables := $operation//selection-set//variable/name/@value/string()
    let $used-variables := ($used-variables, $node//fragment-definition[./name/@value/string() = ($operation-fragments, $referenced-fragments)]//variable/name/@value/string())

    for $unused-variable-name in $defined-variables[not(. = $used-variables)]
        let $unused-variable := $operation//variable[./name/@value/string() = $unused-variable-name]
        let $error-message := "Variable ["||$unused-variable-name||"] is never used"
        let $error-message := if ($operation-name) then $error-message||" by operation ["||$operation-name||"]." else $error-message||"."
        let $line := ($unused-variable/name/location/token)[1]/@line/string()
        let $column := ($unused-variable/name/location/token)[1]/@column/string()
        let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
        return
            xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('NO-UNUSED-VARIABLES', $error-message, $error-location)))
};

(: 
    No unused fragments

    A GraphQL document is only valid if all fragment definitions are spread
    within operations, or spread within other fragments spread within operations.
:)
declare function validator:no-unused-fragments($document as node(), $context as map:map)
{
    (
        xdmp:log('[validator:no-unused-fragments] $document: ', 'fine')
        ,xdmp:log($document, 'fine')
        ,for $key in map:keys($context)[not(. = 'node')] return map:get($context, $key)!xdmp:log('[validator:no-unused-fragments] '||$key||': '||.)
    ),

    let $visited-fragments := map:map()
    let $operation-fragment-names := $document//operation-definition//fragment-spread/name/@value/string()
    let $used-fragment-names :=
        for $operation-fragment-name in $operation-fragment-names
        return validator:get-indirect-fragments($document, $operation-fragment-name, $visited-fragments)
    let $used-fragment-names := ($operation-fragment-names, $used-fragment-names)
    let $defined-fragment-names := $document//fragment-definition/name/@value/string()

    for $unused-fragment-name in $defined-fragment-names[not(. = $used-fragment-names)]
        let $unused-fragment := $document//fragment-definition[./name/@value/string() = $unused-fragment-name]
        let $error-message := "Fragment ["||$unused-fragment-name||"] is never used."
        let $line := ($unused-fragment/name/location/token)[1]/@line/string()
        let $column := ($unused-fragment/name/location/token)[1]/@column/string()
        let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
        return
        xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('NO-UNUSED-FRAGMENTS', $error-message, $error-location)))
};

declare function validator:get-indirect-fragments($node, $fragment-name, $visited-fragments)
{
    let $_ := map:put($visited-fragments, $fragment-name, 'true')
    let $used-fragments := $node//fragment-definition[./name/@value/string() = $fragment-name]//fragment-spread/name/@value/string()
    return ($used-fragments, $used-fragments[not(. = map:keys($visited-fragments))]!validator:get-indirect-fragments($node, ., $visited-fragments))
};

(: 
    Possible fragment spread

    A fragment spread is only valid if the type condition could ever possibly
    be true: if there is a non-empty intersection of the possible parent types,
    and possible types which pass the type condition.
:)
declare function validator:possible-fragment-spread($fragment as node(), $context as map:map)
{
    (
        xdmp:log('[validator:possible-fragment-spread] $fragment: ', 'fine')
        ,xdmp:log($fragment, 'fine')
        ,for $key in map:keys($context)[not(. = 'node')] return map:get($context, $key)!xdmp:log('[validator:possible-fragment-spread] '||$key||': '||.)
    ),
    
    let $node := map:get($context, 'node')
    let $fragment-kind := $fragment/name()
    let $fragment-name := $fragment/name/@value/string()

    let $parent-type := 
        (: TODO: simplify logic + rationalize link between field name and field type :)
        if ($fragment/ancestor::selection-set[1]/parent::field/ancestor::selection-set[1]/parent::field) 
        then 
        (
            let $parent-field-name := $fragment/ancestor::selection-set[1]/parent::field/name/@value/string()
            return fn:distinct-values($validator:SCHEMA//gxqls:field[@name/string()=$parent-field-name]/gxqls:Type/@name/string())
        )
        else if ($fragment/ancestor::selection-set[1]/parent::field) 
        then 
        (
            let $parent-field-name := $fragment/ancestor::selection-set[1]/parent::field/name/@value/string()
            return fn:distinct-values($validator:SCHEMA//gxqls:field[@name/string()=$parent-field-name]/gxqls:Type/@name/string())
        )
        else if ($fragment/ancestor::selection-set[1]/parent::*[local-name()=('fragment-definition', 'inline-fragment')])
        then $fragment/ancestor::selection-set[1]/parent::*[local-name()=('fragment-definition', 'inline-fragment')]/type-condition/named-type/name/@value/string()
        else if ($fragment/ancestor::selection-set[1]/parent::*[local-name()=('operation-definition')])
        then ()
        else fn:error((), 'validator:possible-fragment-spread EXCEPTION', ("500", "Internal server error", "Invalid fragment kind"))
    
    let $fragment-type :=
        switch ($fragment-kind)
        case 'fragment-spread'
        return
        (
            let $fragment-definition := $node//fragment-definition[./name/@value/string() = $fragment-name][1]
            return $fragment-definition/type-condition/named-type/name/@value/string()
        ) 
        case 'inline-fragment'
        return
            $fragment/type-condition/named-type/name/@value/string()
        default
        return
            fn:error((), 'validator:possible-fragment-spread EXCEPTION', ("500", "Internal server error", "Invalid fragment kind"))
    let $_ := xdmp:log('$parent-type:   '||xdmp:describe($parent-type, (),()))
    let $_ := xdmp:log('$fragment-type: '||xdmp:describe($fragment-type, (),()))
    return
    if (not(validator:do-types-ovelap($fragment-type, $parent-type)))
    then
    (
        let $error-fragment-name := if ($fragment-name) then " ["||$fragment-name||"]" else ()
        let $error-message := "Fragment"||$error-fragment-name||" cannot be spread here as objects of type ["||$parent-type||"] can never be of type ["||$fragment-type||"]."
        let $line := ($fragment/name/location/token)[1]/@line/string()
        let $column := ($fragment/name/location/token)[1]/@column/string()
        let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
        return
        xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('POSSIBLE-FRAGMENT-SPREAD', $error-message, $error-location)))
    )
    else ()
};

declare function validator:type-hierarchy($type)
{
    fn:distinct-values(validator:recursive-type-hierarchy($type))
};

declare function validator:recursive-type-hierarchy($type)
{
    let $types :=
        if ($validator:SCHEMA/gxqls:types/gxqls:UnionType[@name/string() = $type])
        then $validator:SCHEMA/gxqls:types/gxqls:UnionType[@name/string() = $type]/gxqls:types/gxqls:Type/@name/string()
        else $type
    for $type in $types
        let $type-def := $validator:SCHEMA/gxqls:types/child::*[@name/string() = $type]
        return 
        (
            $type,
            if ($type-def/gxqls:interfaces)
            then 
            (
                let $interfaces := $type-def/gxqls:interfaces
                for $interface in $interfaces
                return
                    validator:type-hierarchy($interface/gxqls:Type/@name/string())
            )
            else ()
        )
};

declare function validator:do-types-ovelap($type as xs:string, $parent-type as xs:string) as xs:boolean
{
    fn:count(validator:type-hierarchy($type)[. = validator:type-hierarchy($parent-type)]) gt 0
};

(: 
    Provided required arguments

    A field or directive is only valid if all required (non-null without a
    default value) field arguments have been provided.
:)
declare function validator:provided-required-arguments($field as node(), $context as map:map)
{
    (
        xdmp:log('[validator:provided-required-arguments] $field: ', 'debug')
        ,xdmp:log($field, 'debug')
        ,for $key in map:keys($context)[not(. = 'node')] return map:get($context, $key)!xdmp:log('[validator:provided-required-arguments] '||$key||': '||.)
    ),

    let $field-name := $field/name/@value/string()
    let $parent-type-name := 
        if ($field/ancestor::selection-set[1]/parent::field) 
        then $field/ancestor::selection-set[1]/parent::field/name/@value/string()
        else if ($field/ancestor::selection-set[1]/parent::*[local-name()=('fragment-definition', 'inline-fragment')])
        then $field/ancestor::selection-set[1]/parent::*[local-name()=('fragment-definition', 'inline-fragment')]/type-condition/named-type/name/@value/string()
        else ()
    let $parent-field-type := 
        if ($validator:SCHEMA/gxqls:Query/gxqls:fields/gxqls:field[@name/string() = $parent-type-name]) 
        then $validator:SCHEMA/gxqls:Query/gxqls:fields/gxqls:field[@name/string() = $parent-type-name]/gxqls:Type/@name/string()
        else if ($validator:SCHEMA/gxqls:types/child::*[fn:upper-case(@name/string()) = fn:upper-case($parent-type-name)])
        then $validator:SCHEMA/gxqls:types/child::*[fn:upper-case(@name/string()) = fn:upper-case($parent-type-name)]/@name/string()
        else ()

    let $schema-field := 
        if (map:get($context, 'location')[last()-1] = 'QUERY')
        then $validator:SCHEMA/gxqls:Query/gxqls:fields/gxqls:field[@name/string()=$field-name]
        else $validator:SCHEMA/gxqls:types/child::*[@name/string() = $parent-field-type]/gxqls:fields/gxqls:field[@name/string()=$field-name]
    let $schema-field-required-args := $schema-field/gxqls:args/gxqls:Arg[@nullable/string()="false" and not(@default)]

    return
        for $required-arg in $schema-field-required-args
        let $required-arg-name := $required-arg/@name/string()
        let $required-arg-type := $required-arg/gxqls:Type/@name/string()
        return
        if (not(fn:exists($field/arguments/argument[./name/@value/string() = $required-arg-name])))
        then
        (
            let $error-message := "Field ["||$field-name||"] argument ["||$required-arg-name||"] of type ["||$required-arg-type||"!] is required, but it was not provided."
            let $line := ($field/name/location/token)[1]/@line/string()
            let $column := ($field/name/location/token)[1]/@column/string()
            let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
            return
            xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('PROVIDED-REQUIRED-ARGUMENTS', $error-message, $error-location)))
        )
        else ()
};

declare function validator:provided-required-arguments-on-directive($directive as node(), $context as map:map)
{
    (
        xdmp:log('[validator:provided-required-arguments-on-directive] $directive: ', 'debug')
        ,xdmp:log($directive, 'debug')
        ,for $key in map:keys($context)[not(. = 'node')] return map:get($context, $key)!xdmp:log('[validator:provided-required-arguments-on-directive] '||$key||': '||.)
    ),

    let $directive-name := $directive/name/@value/string()

    let $schema-directive := $validator:SCHEMA/gxqls:directives/gxqls:Directive[@name/string() = $directive-name]
    let $schema-directive-required-args := $schema-directive/gxqls:args/gxqls:Arg[@nullable/string()="false" and not(@default)]
    return
        for $required-arg in $schema-directive-required-args
        let $required-arg-name := $required-arg/@name/string()
        let $required-arg-type := $required-arg/gxqls:Type/@name/string()
        return
        if (not(fn:exists($directive/arguments/argument[./name/@value/string() = $required-arg-name])))
        then
        (
            let $error-message := "Directive [@"||$directive-name||"] argument ["||$required-arg-name||"] of type ["||$required-arg-type||"!] is required, but it was not provided."
            let $line := ($directive/name/location/token)[1]/@line/string()
            let $column := ($directive/name/location/token)[1]/@column/string()
            let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
            return
            xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('PROVIDED-REQUIRED-ARGUMENTS', $error-message, $error-location)))
        )
        else ()
};

declare function validator:scalar-leaf($field as node(), $context as map:map)
{
    (
        xdmp:log('[validator:scalar-leaf] $field: ', 'debug')
        ,xdmp:log($field, 'debug')
        ,for $key in map:keys($context)[not(. = 'node')] return map:get($context, $key)!xdmp:log('[validator:scalar-leaf] '||$key||': '||.)
    ),

    let $field-name := $field/name/@value/string()
    let $parent-type-name := 
        if ($field/ancestor::selection-set[1]/parent::field) 
        then $field/ancestor::selection-set[1]/parent::field/name/@value/string()
        else if ($field/ancestor::selection-set[1]/parent::*[local-name()=('fragment-definition', 'inline-fragment')])
        then $field/ancestor::selection-set[1]/parent::*[local-name()=('fragment-definition', 'inline-fragment')]/type-condition/named-type/name/@value/string()
        else ()
    let $parent-field-type := 
        if ($validator:SCHEMA/gxqls:Query/gxqls:fields/gxqls:field[@name/string() = $parent-type-name]) 
        then $validator:SCHEMA/gxqls:Query/gxqls:fields/gxqls:field[@name/string() = $parent-type-name]/gxqls:Type/@name/string()
        else if ($validator:SCHEMA/gxqls:types/child::*[fn:upper-case(@name/string()) = fn:upper-case($parent-type-name)])
        then $validator:SCHEMA/gxqls:types/child::*[fn:upper-case(@name/string()) = fn:upper-case($parent-type-name)]/@name/string()
        else ()
    let $field-type := 
        (: QUERY FIELD:)
        if ($validator:SCHEMA/gxqls:Query/gxqls:fields/gxqls:field[@name/string() = $field-name]) 
        then $validator:SCHEMA/gxqls:Query/gxqls:fields/gxqls:field[@name/string() = $field-name]/gxqls:Type/@name/string()
        (: TYPE FIELD:)
        else if ($validator:SCHEMA/gxqls:types/child::*[fn:upper-case(@name/string()) = fn:upper-case($field-name)])
        then $validator:SCHEMA/gxqls:types/child::*[fn:upper-case(@name/string()) = fn:upper-case($field-name)]/@name/string()
        (: SUBTYPE FIELD:)
        else if ($validator:SCHEMA/gxqls:types/child::*[@name/string() = $parent-field-type]/gxqls:fields/gxqls:field[@name/string() = $field-name])
        then $validator:SCHEMA/gxqls:types/child::*[@name/string() = $parent-field-type]/gxqls:fields/gxqls:field[@name/string() = $field-name]/gxqls:Type/@name/string()
        else () (: ignore unknown field types:)

    let $_ := xdmp:log('$field-type: '||$field-type)
    return
    if ($field-type 
        and $validator:SCHEMA/gxqls:types/child::*[@name/string() = $field-type]/gxqls:fields
        and not($field/selection-set))
    then
    (
        let $error-message := "Field ["||$field-name||"] of type ["||$field-type||"] must have a selection of subfields. Did you mean "||$field-name||" { ... }?"
        let $line := ($field/name/location/token)[1]/@line/string()
        let $column := ($field/name/location/token)[1]/@column/string()
        let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
        return
        xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('SCALAR-LEAF', $error-message, $error-location)))
    )
    else if ($field-type 
        and $field/selection-set
        and not($validator:SCHEMA/gxqls:types/child::*[@name/string() = $field-type]/gxqls:fields)
        and not($SCHEMA/gxqls:types/child::*[@name/string() = $SCHEMA/gxqls:types/child::*[@name/string() = 'SearchResult']/gxqls:types/gxqls:Type/@name/string()]/gxqls:fields))
    then
    (
        let $error-message := "Field ["||$field-name||"] must not have a selection since type ["||$field-type||"] has no subfields."
        let $line := ($field/name/location/token)[1]/@line/string()
        let $column := ($field/name/location/token)[1]/@column/string()
        let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
        return
        xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('SCALAR-LEAF', $error-message, $error-location)))
    )
    else () (: ignore unknown field types:)
};

declare function validator:unique-fragment-name($fragment as node(), $context as map:map)
{
    (
        xdmp:log('[validator:unique-fragment-name] $fragment: ', 'debug')
        ,xdmp:log($fragment, 'debug')
        ,for $key in map:keys($context)[not(. = 'node')] return map:get($context, $key)!xdmp:log('[validator:unique-fragment-name] '||$key||': '||.)
    ),

    if 
    (
        $fragment/name/@value 
        and map:contains($validator:KNOWN-FRAGMENT-NAMES, $fragment/name/@value/string())
    )
    then
    (
        let $name := $fragment/name/@value/string()
        let $error-message := "There can be only one fragment named "||$name||"."
        let $error-locations := 
            array-node 
            { 
                for $fragment-name in (map:get($validator:KNOWN-FRAGMENT-NAMES, $fragment/name/@value/string()), $fragment/name)
                let $line := ($fragment-name/location/token)[1]/@line/string()
                let $column := ($fragment-name/location/token)[1]/@column/string()
                where $fragment-name/@value/string() = $fragment/name/@value/string()
                return
                    object-node {"line": xs:int($line), "column": xs:int($column)}
            }
        return
            xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('UNIQUE-FRAGMENT-NAME', $error-message, $error-locations)))
    ) 
    else 
        map:put($validator:KNOWN-FRAGMENT-NAMES, $fragment/name/@value/string(), $fragment/name)
};

declare function validator:unique-input-field-names($object-field as node(), $context as map:map)
{
    (
        xdmp:log('[validator:unique-input-field-names] $object-field: ', 'debug')
        ,xdmp:log($object-field, 'debug')
        ,for $key in map:keys($context)[not(. = 'node')] return map:get($context, $key)!xdmp:log('[validator:unique-input-field-names] '||$key||': '||.)
    ),

    let $object := xs:string(map:get($context, 'object')[last()])
    let $name := $object-field/name/@value/string()
    return
    if 
    (
        $object-field/name/@value 
        and map:contains($validator:KNOWN-INPUT-FIELD-NAMES, $object)
        and map:contains(map:get($validator:KNOWN-INPUT-FIELD-NAMES, $object), $name)
    )
    then
    (
        let $error-message := "There can be only one field named "||$name||"."
        let $error-locations := 
            array-node 
            { 
                for $object-field-name in (map:get(map:get($validator:KNOWN-INPUT-FIELD-NAMES, $object), $name), $object-field/name)
                let $line := ($object-field-name/location/token)[1]/@line/string()
                let $column := ($object-field-name/location/token)[1]/@column/string()
                where $object-field-name/@value/string() = $name
                return
                    object-node {"line": xs:int($line), "column": xs:int($column)}
            }
        return
            xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('UNIQUE-INPUT-FIELD-NAME', $error-message, $error-locations)))
    ) 
    else 
        map:put(map:get($validator:KNOWN-INPUT-FIELD-NAMES, $object), $name, $object-field/name)

};

(: 
    Variables are input types

    A GraphQL operation is only valid if all the variables it defines are of
    input types (scalar, enum, or input object).
:)
declare function validator:variables-are-input-types($variable-definition as node(), $context as map:map)
{
    (
        xdmp:log('[validator:variables-are-input-types] $variable-definition: ', 'debug')
        ,xdmp:log($variable-definition, 'debug')
        ,for $key in map:keys($context)[not(. = 'node')] return map:get($context, $key)!xdmp:log('[validator:variables-are-input-types] '||$key||': '||.)
    ),

    let $variable-name := $variable-definition/variable/name/@value/string()
    let $variable-type := $variable-definition/type//named-type//name/@value/string()
    return
    if (not($validator:SCHEMA/gxqls:types/gxqls:InputType[fn:upper-case(@name/string()) = fn:upper-case($variable-type)])
        and 
        not($validator:SCHEMA/gxqls:scalars/child::*[fn:upper-case(local-name()) = fn:upper-case($variable-type)]))
    then 
    (
        let $error-message := "Variable ["||$variable-name||"] cannot be non-input type ["||$variable-type||"]"
        let $line := ($variable-definition/variable/name/location/token)[1]/@line/string()
        let $column := ($variable-definition/variable/name/location/token)[1]/@column/string()
        let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
        return
        xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('VARIABLES-ARE-INPUT-TYPES', $error-message, $error-location)))
    )
    else ()
};

declare function validator:values-of-correct-type($arg as node(), $context as map:map)
{
    (
        xdmp:log('[validator:values-of-correct-type] $arg: ', 'debug')
        ,xdmp:log($arg, 'debug')
        ,for $key in map:keys($context)[not(. = 'node')] return map:get($context, $key)!xdmp:log('[validator:values-of-correct-type] '||$key||': '||.)
    ),

    let $arg-name := $arg/name/@value/string()
    let $arg-type := $arg/value/child::*/local-name()
    let $arg-value := $arg/value/child::*/@value/string()
    let $field-name := map:get($context, 'field')
    let $field := $arg/ancestor::field[1]
    let $parent-type-name := 
        if ($field/ancestor::selection-set[1]/parent::field) 
        then $field/ancestor::selection-set[1]/parent::field/name/@value/string()
        else if ($field/ancestor::selection-set[1]/parent::*[local-name()=('fragment-definition', 'inline-fragment')])
        then $field/ancestor::selection-set[1]/parent::*[local-name()=('fragment-definition', 'inline-fragment')]/type-condition/named-type/name/@value/string()
        else if ($field/ancestor::selection-set[1]/parent::*[local-name()=('operation-definition')])
        then $field-name
        else ()
    let $type-name := 
        if ($validator:SCHEMA/child::*[local-name()=('Query', 'Mutation')]/gxqls:fields/gxqls:field[@name/string() = $parent-type-name]) 
        then $validator:SCHEMA/child::*[local-name()=('Query', 'Mutation')]/gxqls:fields/gxqls:field[@name/string() = $parent-type-name]/gxqls:Type/@name/string()
        else if ($validator:SCHEMA/gxqls:types/child::*[fn:upper-case(@name/string()) = fn:upper-case($parent-type-name)])
        then $validator:SCHEMA/gxqls:types/child::*[fn:upper-case(@name/string()) = fn:upper-case($parent-type-name)]/@name/string()
        else ()
    let $schema-type := 
        (
            $validator:SCHEMA/gxqls:types/child::*[@name/string() = $type-name]/gxqls:fields/gxqls:field[@name/string()=$field-name],
            $validator:SCHEMA/child::*[local-name()=('Query', 'Mutation')]/gxqls:fields/gxqls:field[@name/string()=$field-name and ./gxqls:Type/@name/string() = $type-name]
        )
    let $schema-arg := $schema-type/gxqls:args/gxqls:Arg[@name/string()=$arg-name]
    let $schema-arg-type := $schema-arg/gxqls:Type/@name/string()
    let $schema-arg-named-type := $validator:SCHEMA/gxqls:types/child::*[@name/string() = $schema-arg-type]

    let $_ := 
    (
        xdmp:log('[validator:values-of-correct-type] $arg-name: '||$arg-name, 'debug')
        ,xdmp:log('[validator:values-of-correct-type] $arg-type: '||$arg-type, 'debug')
        ,xdmp:log('[validator:values-of-correct-type] $arg-value: '||$arg-value, 'debug')
        ,xdmp:log('[validator:values-of-correct-type] $field-name: '||$field-name, 'debug')
        ,xdmp:log('[validator:values-of-correct-type] $type-name: '||$type-name, 'debug')
        ,xdmp:log('[validator:values-of-correct-type] $schema-arg: '||xdmp:describe($schema-arg, (), ()), 'debug')
    )
    return
    (
        switch ($schema-arg-named-type/local-name())
        case 'EnumType'
        return
        (
            xdmp:log('### EnumType ###'),
            if ($arg-value = $schema-arg-named-type/gxqls:values/gxqls:value/@label/string() and $arg-type = 'enum')
            then ()
            else
            (
                let $error-message := "Expected value of type ["||$schema-arg-type||"], found: "||$arg-value
                let $line := ($arg/name/location/token)[1]/@line/string()
                let $column := ($arg/name/location/token)[1]/@column/string()
                let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
                return
                xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('VALUES-OF-CORRECT-TYPE', $error-message, $error-location)))
            )
        )
        case 'Type'
        return
        (
            xdmp:log('### Type ###'),
            if (fn:upper-case($arg-type) ne fn:upper-case($schema-arg-type))
            then
            (
                let $error-message := $schema-arg-type||" cannot represent a non "||$schema-arg-type||" value: "||$arg-value
                let $line := ($arg/name/location/token)[1]/@line/string()
                let $column := ($arg/name/location/token)[1]/@column/string()
                let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
                return
                xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('VALUES-OF-CORRECT-TYPE', $error-message, $error-location)))
            )
            else ()
        )
        case 'InputType'
        return
        (
            xdmp:log('### InputType ###'),
            (: Check all required fields exist :)
            for $required-field in $schema-arg-named-type/gxqls:fields/gxqls:field[@nullable/string()='false' and not(@default)]
            let $required-field-name := $required-field/@name/string()
            let $required-field-type := $required-field//gxqls:Type/@name/string()
            return
                if (not($required-field-name = $arg/value/object/object-field/name/@value/string()))
                then
                (
                    let $_ := xdmp:log('### Check all required fields exist ###')
                    let $error-message := "Field "||$arg-name||"."||$required-field-name||" of required type "||$required-field-type||"! was not provided."
                    let $line := ($arg/name/location/token)[1]/@line/string()
                    let $column := ($arg/name/location/token)[1]/@column/string()
                    let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
                    return
                    xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('VALUES-OF-CORRECT-TYPE', $error-message, $error-location)))
                )
                else ()
            ,
            (: Check field value types :)
            for $field in $arg/value/object/object-field
            let $field-name := $field/name/@value/string()
            let $field-value := $field/value
            let $_ := xdmp:log('### $field-name ###'||xdmp:describe($field-name, (), ()))
            let $_ := xdmp:log('### $field-value ###'||xdmp:describe($field-value, (), ()))
            return
                if ($field-value/child::*/local-name() = 'null')
                then
                (
                    xdmp:log('### null ###'),
                    if ($schema-arg-named-type/gxqls:fields/gxqls:field[@name/string()=$field-name]/@nullable/string()='false')
                    then
                    (
                        let $error-message := "Expected value of type ["||$schema-arg-named-type/gxqls:fields/gxqls:field[@name/string()=$field-name]/gxqls:Type/@name/string()||"!], found: null"
                        let $line := ($field/name/location/token)[1]/@line/string()
                        let $column := ($field/name/location/token)[1]/@column/string()
                        let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
                        return
                        xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('VALUES-OF-CORRECT-TYPE', $error-message, $error-location)))
                    )
                    else ()
                )
                else if ($field-value/child::*/local-name() = 'list') 
                then
                (
                    if ($schema-arg-named-type/gxqls:fields/gxqls:field[@name/string()=$field-name]/gxqls:Type/@kind/string() = 'List')
                    then 
                    (
                        let $_ := xdmp:log('### list ###')
                        let $expected-type := $schema-arg-named-type/gxqls:fields/gxqls:field[@name/string()=$field/name/@value/string()]/gxqls:Type/@name/string()
                        for $list-arg in $field-value/list/child::*[local-name(.) ne 'null']
                        return
                            if (fn:upper-case($list-arg/local-name()) ne fn:upper-case($expected-type))
                            then
                            (
                                (: TODO: improve error message when arg-value is of type String. Surround with quotes :)
                                let $_ := xdmp:log('#4')
                                let $error-message := $expected-type||" cannot represent a non "||$expected-type||" value: "||$list-arg/@value/string()
                                let $line := ($field/name/location/token)[1]/@line/string()
                                let $column := ($field/name/location/token)[1]/@column/string()
                                let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
                                return
                                xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('VALUES-OF-CORRECT-TYPE', $error-message, $error-location)))
                            )
                            else ()
                    )
                    else 
                    (
                    let $_ := xdmp:log('### else-list ###')
                    let $error-message := "Expected value of type ["||$schema-arg-type||"], found: "||$arg-type
                    let $line := ($field/name/location/token)[1]/@line/string()
                    let $column := ($field/name/location/token)[1]/@column/string()
                    let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
                    return
                    xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('VALUES-OF-CORRECT-TYPE', $error-message, $error-location)))
                    )
                )
                else if (not($field-name = $schema-arg-named-type/gxqls:fields/gxqls:field/@name/string()))
                then
                (
                    let $_ := xdmp:log('### invalid field ###')
                    let $error-message := "Field "||$field-name||" is not defined by type "||$schema-arg-named-type/@name/string()||"."
                    let $error-message := $error-message||fn:concat(" Valid field values are [", fn:string-join($schema-arg-named-type/gxqls:fields/gxqls:field/@name/string(), ", "), "]")
                    let $line := ($field/name/location/token)[1]/@line/string()
                    let $column := ($field/name/location/token)[1]/@column/string()
                    let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
                    return
                    xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('VALUES-OF-CORRECT-TYPE', $error-message, $error-location)))
                )
                else if (fn:upper-case($field/value/child::*/local-name()) ne fn:upper-case($schema-arg-named-type/gxqls:fields/gxqls:field[@name/string()=$field-name]/gxqls:Type/@name/string()))
                then
                (
                    let $_ := xdmp:log('### else ###')
                    let $_ := xdmp:log('$field/value/child::*/local-name(): '||$field/value/child::*/local-name())
                    let $error-message := $schema-arg-type||" cannot represent a non "||$schema-arg-type||" value: "||$arg-value
                    let $line := ($field/name/location/token)[1]/@line/string()
                    let $column := ($field/name/location/token)[1]/@column/string()
                    let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
                    return
                    xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('VALUES-OF-CORRECT-TYPE', $error-message, $error-location)))
                )
                else ()            
        )
        default (: SCALAR :)
        return
        (
            xdmp:log('### default ###'),
            if ($arg-type = 'variable')
            then ( (:IGNORE:) ) 
            else if ($arg-type = 'null')
            then
            (
                xdmp:log('### null ###'),
                if ($schema-arg/@nullable/string()='false')
                then
                (
                    let $error-message := "Expected value of type ["||$schema-arg-type||"!], found: "||$arg-type
                    let $line := ($arg/name/location/token)[1]/@line/string()
                    let $column := ($arg/name/location/token)[1]/@column/string()
                    let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
                    return
                    xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('VALUES-OF-CORRECT-TYPE', $error-message, $error-location)))
                )
                else ()
            )
            else if ($arg-type = 'list') 
            then
            (
                xdmp:log('### list ###'),
                if ($schema-arg/gxqls:Type/@kind/string() = 'List')
                then 
                (
                    for $list-arg in $arg/value/list/child::*[local-name(.) ne 'null']
                    return
                        if (fn:upper-case($list-arg/local-name()) ne fn:upper-case($schema-arg-type))
                        then
                        (
                            (: TODO: improve error message when arg-value is of type String. Surround with quotes :)
                            let $error-message := $schema-arg-type||" cannot represent a non "||$schema-arg-type||" value: "||$list-arg/@value/string()
                            let $line := ($arg/name/location/token)[1]/@line/string()
                            let $column := ($arg/name/location/token)[1]/@column/string()
                            let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
                            return
                            xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('VALUES-OF-CORRECT-TYPE', $error-message, $error-location)))
                        )
                        else ()
                )
                else 
                (
                let $error-message := "Expected value of type ["||$schema-arg-type||"], found: "||$arg-type
                let $line := ($arg/name/location/token)[1]/@line/string()
                let $column := ($arg/name/location/token)[1]/@column/string()
                let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
                return
                xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('VALUES-OF-CORRECT-TYPE', $error-message, $error-location)))
                )
            )
            else 
            if (fn:upper-case($arg-type) ne fn:upper-case($schema-arg-type))
            then
            (
                (: TODO: improve error message when arg-value is of type String. Surround with quotes :)
                let $error-message := $schema-arg-type||" cannot represent a non "||$schema-arg-type||" value: "||$arg-value
                let $line := ($arg/name/location/token)[1]/@line/string()
                let $column := ($arg/name/location/token)[1]/@column/string()
                let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
                return
                xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('VALUES-OF-CORRECT-TYPE', $error-message, $error-location)))
            )
            else ()
        )
    )
};

(: 
    Variables passed to field arguments conform to type
:)
declare function validator:variables-in-allowed-position($variable-definition as node(), $context as map:map)
{
    (
        xdmp:log('[validator:variables-in-allowed-position] $variable-definition: ', 'debug')
        ,xdmp:log($variable-definition, 'debug')
        ,for $key in map:keys($context)[not(. = 'node')] return map:get($context, $key)!xdmp:log('[validator:variables-in-allowed-position] '||$key||': '||.)
    ),
    
    let $variable-name := $variable-definition/variable/name/@value/string()
    let $variable-type := $variable-definition/type//named-type/name/@value/string()
    let $variable-nullable := if ($variable-definition/type/non-null-type) then xs:boolean('false') else xs:boolean('true')
    let $variable-non-null-default  := ($variable-definition/default-value and $variable-definition/default-value/child::*/local-name() != 'null')
    let $variable-cardinality := if ($variable-definition/type//list-type) then 'list' else 'scalar'
    let $list-variable-item-nullable := if ($variable-cardinality = 'list') then not(fn:exists($variable-definition/type//list-type/non-null-type)) else ()
    let $variable-details := map:map()
        => map:with('name',$variable-name)
        => map:with('type',$variable-type)
        => map:with('nullable',$variable-nullable)
        => map:with('non-null-default',$variable-non-null-default)
        => map:with('cardinality',$variable-cardinality)
        => map:with('list-variable-item-nullable',$list-variable-item-nullable)
    let $_ := xdmp:log('[validator:variables-in-allowed-position] $variable-type: '||map:get($variable-details, 'type'))
    let $_ := xdmp:log('[validator:variables-in-allowed-position] $variable-nullable: '||map:get($variable-details, 'nullable'))
    let $_ := xdmp:log('[validator:variables-in-allowed-position] $variable-non-null-default: '||map:get($variable-details, 'non-null-default'))
    let $_ := xdmp:log('[validator:variables-in-allowed-position] $variable-cardinality: '||map:get($variable-details, 'cardinality'))
    let $_ := xdmp:log('[validator:variables-in-allowed-position] $list-variable-item-nullable: '||map:get($variable-details, 'list-variable-item-nullable'))

    let $doc := $variable-definition/ancestor::*[local-name() = 'document']
    let $fields := 
        (
            $doc//field[./arguments/argument/value/variable/name/@value/string() = $variable-name], 
            $doc//directive[./arguments/argument/value/variable/name/@value/string() = $variable-name]
        )
    for $field in $fields
        let $field-details := validator:get-field-details($field, $variable-name)
        return 
        (
            xdmp:log('[validator:variables-in-allowed-position] $field: '||xdmp:describe($field, (), ()))
            ,xdmp:log('[validator:variables-in-allowed-position] $parent-field-name: '||xdmp:describe(map:get($field-details, 'parent-field-name'), (), ()))
            ,xdmp:log('[validator:variables-in-allowed-position] $field-name: '||xdmp:describe(map:get($field-details, 'field-name'), (), ()))
            ,xdmp:log('[validator:variables-in-allowed-position] $argument-name: '||xdmp:describe(map:get($field-details, 'argument-name'), (), ()))
            ,xdmp:log('[validator:variables-in-allowed-position] $schema-arg-type: '||xdmp:describe(map:get($field-details, 'type'), (), ()))
            ,xdmp:log('[validator:variables-in-allowed-position] $schema-arg-cardinality: '||xdmp:describe(map:get($field-details, 'cardinality'), (), ()))
            ,xdmp:log('[validator:variables-in-allowed-position] $schema-arg-nullable: '||xdmp:describe(map:get($field-details, 'nullable'), (), ()))
            ,if (not(validator:allowed-variable-usage($variable-details, $field-details)))
            then 
            (
                let $error-message := "Variable "||$variable-name||" of type "||validator:report-type($variable-details)
                let $error-message := $error-message||" used in position expecting type "||validator:report-type($field-details)||""
                let $line := ($variable-definition/variable/name/location/token)[1]/@line/string()
                let $column := ($variable-definition/variable/name/location/token)[1]/@column/string()
                let $error-location := array-node { object-node {"line": xs:int($line), "column": xs:int($column)}}
                return
                xdmp:set($validator:GRAPHQL-ERRORS, ($validator:GRAPHQL-ERRORS, validator:error('VARIABLES-IN-ALLOWED-POSITION', $error-message, $error-location)))
            )
            else ()
        )
};

declare function validator:get-field-details($field as node(), $variable-name as xs:string) as map:map
{
    let $field-name := $field/name/@value/string()
    let $parent-field := 
        if ($field/local-name()='directive') 
        then $field
        else $field/ancestor::*[local-name()='field' or local-name()='fragment-definition'][position()=1]
    let $parent-field := if ($parent-field) then $parent-field else $field/ancestor::*[local-name()='selection-set'][position()=1]
    let $parent-field-name := 
        switch ($parent-field/local-name())
        case 'field'
            return $parent-field/name/@value/string()
        case 'fragment-definition'
            return $parent-field/type-condition/named-type/name/@value/string()
        case 'selection-set'
            return $field-name
        case 'directive'
            return $parent-field/name/@value/string()
        default 
            return ()
    let $argument-name := $field/arguments/argument[./value/variable/name/@value/string() = $variable-name]/name/@value/string()
    let $schema-arg := 
        switch ($parent-field/local-name())
        case 'field'
        case 'fragment-definition'
            return $validator:SCHEMA//gxqls:Type[fn:upper-case(@name)=fn:upper-case($parent-field-name)]//gxqls:Arg[@name=$argument-name and ./ancestor::*[local-name()='field']/@name/string()=$field-name]
        case 'selection-set'
            return 
                (
                    $validator:SCHEMA/gxqls:Query/gxqls:fields/gxqls:field[@name/string()=$field-name]/gxqls:args/gxqls:Arg[@name=$argument-name],
                    $validator:SCHEMA/gxqls:Mutation/gxqls:fields/gxqls:field[@name/string()=$field-name]/gxqls:args/gxqls:Arg[@name=$argument-name]
                )
        case 'directive'
            return $validator:SCHEMA//gxqls:directives/gxqls:Directive[@name/string() = $parent-field-name]//gxqls:Arg[@name=$argument-name]
        default 
            return ()
        
    let $schema-arg-type := $schema-arg/gxqls:Type/@name/string()
    let $schema-arg-cardinality := fn:lower-case($schema-arg/gxqls:Type/@kind/string())
    let $schema-arg-nullable := if ($schema-arg/@nullable and $schema-arg/@nullable/string() = 'false') then xs:boolean('false') else xs:boolean('true')
    let $schema-arg-non-null-default := if ($schema-arg/@default) then xs:boolean('true') else xs:boolean('false')
    return map:map()
        => map:with('field-name',$field-name)
        => map:with('parent-field-name',$parent-field-name)
        => map:with('argument-name',$argument-name)
        => map:with('type',$schema-arg-type)
        => map:with('cardinality',$schema-arg-cardinality)
        => map:with('nullable',$schema-arg-nullable)
        => map:with('non-null-default',$schema-arg-non-null-default)
};

declare function validator:report-type($type-details as map:map) as xs:string
{
  let $report := map:get($type-details, 'type')
  let $report := if (fn:lower-case(map:get($type-details, 'cardinality')) eq 'scalar') then $report else fn:concat('[', $report, ']')
  let $report := if (map:get($type-details, 'nullable')) then $report else fn:concat($report, '!') 
  
  return $report
};

(: 
    Returns true if the variable is allowed in the location it was found,
    which includes considering if default values exist for either the variable
    or the location at which it is located.
:)
declare function validator:allowed-variable-usage($variable-details as map:map, $field-details as map:map) as xs:boolean
{
    (: TODO: REFACTOR TO REPORT BACK ERROR LOCATION :)
    let $variable-type := map:get($variable-details, 'type')
    let $variable-cardinality := map:get($variable-details, 'cardinality')
    let $variable-nullable := map:get($variable-details, 'nullable')
    let $variable-non-null-default := if (map:get($variable-details, 'non-null-default')) then xs:boolean('true') else xs:boolean('false')
    let $schema-arg-type := map:get($field-details, 'type')
    let $schema-arg-cardinality := fn:lower-case(map:get($field-details, 'cardinality'))
    let $schema-arg-nullable := map:get($field-details, 'nullable')
    let $schema-arg-non-null-default := map:get($field-details, 'non-null-default')
    return
    (
        xdmp:log('[validator:allowed-variable-usage] $variable-type: '||$variable-type),
        xdmp:log('[validator:allowed-variable-usage] $variable-cardinality: '||$variable-cardinality),
        xdmp:log('[validator:allowed-variable-usage]$variable-nullable: '||$variable-nullable),
        xdmp:log('[validator:allowed-variable-usage]$variable-non-null-default: '||$variable-non-null-default),
        xdmp:log('[validator:allowed-variable-usage]$schema-arg-type: '||$schema-arg-type),
        xdmp:log('[validator:allowed-variable-usage]$schema-arg-cardinality: '||$schema-arg-cardinality),
        xdmp:log('[validator:allowed-variable-usage]$schema-arg-nullable: '||$schema-arg-nullable),
        xdmp:log('[validator:allowed-variable-usage]$schema-arg-non-null-default: '||$schema-arg-non-null-default),
        if (not($schema-arg-nullable) and $variable-nullable)
        then
        (
            if (not($variable-non-null-default) and not($schema-arg-non-null-default))
            then xs:boolean('false')
            else validator:subtype-of($variable-details, $field-details)
        )
        else
            validator:subtype-of($variable-details, $field-details)
    )
};

declare function validator:subtype-of($variable-details as map:map, $field-details as map:map) as xs:boolean
{
    let $variable-type := map:get($variable-details, 'type')
    let $variable-cardinality := map:get($variable-details, 'cardinality')
    let $variable-nullable := map:get($variable-details, 'nullable')
    let $variable-non-null-default := if (map:get($variable-details, 'non-null-default')) then xs:boolean('true') else xs:boolean('false')
    let $schema-arg-type := map:get($field-details, 'type')
    let $schema-arg-cardinality := fn:lower-case(map:get($field-details, 'cardinality'))
    let $schema-arg-nullable := map:get($field-details, 'nullable')
    let $schema-arg-non-null-default := map:get($field-details, 'non-null-default')
    return
    (
        if ($variable-cardinality eq 'list' and not($schema-arg-cardinality eq 'list'))
        then 
            xs:boolean('false')
        else if ($variable-cardinality eq 'scalar' and not($schema-arg-cardinality eq 'scalar'))
        then 
            if ($variable-non-null-default) 
            then xs:boolean('true') 
            else xs:boolean('false')
        else if ($schema-arg-cardinality eq 'scalar' and not($variable-cardinality eq 'scalar'))
        then 
            xs:boolean('false')
        else if ($schema-arg-type eq $variable-type)
        then 
            xs:boolean('true')
        else 
            xs:boolean('false')
    )
};


declare function validator:error($error-message as xs:string, $error-location as node())
{
    validator:error('', $error-message, $error-location)
};

declare function validator:error($validation-rule as xs:string?, $error-message as xs:string, $error-location as node())
{
    object-node 
    {
        "rule": $validation-rule,
        "message": $error-message,
        "locations": $error-location
    }
};

declare function validator:report($errors)
{
    document {
        object-node {
            "errors": array-node {
                $validator:GRAPHQL-ERRORS!.
            }
        }
    }
};