xquery version "1.0-ml";

module namespace intro = "http://graph.x.ql/resolver/introspection";

declare namespace gxql ="http://graph.x.ql";
declare namespace gxqls ="http://graph.x.qls";
declare namespace gxqli ="http://graph.x.qli";
declare namespace xs="http://www.w3.org/2001/XMLSchema";

declare default element namespace "http://graph.x.ql";

declare variable $intro:SCHEMA as element(*, gxqls:Schema) := fn:doc('/graphXql/schema.xml')/gxqls:Schema;
declare variable $intro:INTROSPECTION-SCHEMA as element(*, gxqls:Schema) := fn:doc('/graphXql/introspection/introspection-schema.xml')/gxqls:Schema;
declare variable $intro:SCALARS as xs:string* := ('INT', 'FLOAT', 'STRING', 'BOOLEAN', 'ID');

declare function intro:schema-resolver($var-map as map:map) as element(*, gxqli:__Schema)
{
    (
        for $key in map:keys($var-map) return map:get($var-map, $key)!xdmp:log('[intro:schema-resolver] '||$key||': '||., 'debug')
    ),

    element gxqli:__Schema 
    {
        element gxqli:description {$intro:SCHEMA/gxqls:description},
        intro:build-schema-types(),
        intro:build-schema-directives() 
    }
};

declare function intro:build-schema-types()
{
    (: TODO: implement caching mechanism :)
    element gxqli:types 
    {
        intro:build-schema-queryType(),
        intro:build-schema-mutationType(),
        intro:build-schema-subscriptionType(),
        (
            let $map-types := map:map()
            let $_ :=
            (
                for $type in $intro:SCHEMA/gxqls:types/child::*
                return 
                    map:put($map-types, $type/@name/string(), $type)
                ,
                for $type in ($intro:SCHEMA//gxqls:field/gxqls:Type, $intro:SCHEMA//gxqls:Arg/gxqls:Type)
                return
                    if (not(map:contains($map-types, $type/@name/string()))) 
                    then map:put($map-types, $type/@name/string(), <Type name="{$type/@name/string()}"/>)
                    else ()
            )
            for $key in map:keys($map-types) 
                return intro:build-type(map:get($map-types,$key))
        ),

        (: Introspection type names all begin with __ :)
        for $type in $intro:INTROSPECTION-SCHEMA/gxqls:types/gxqls:Type[fn:contains(@name/string(), '__')]
        return intro:build-type(<Type name="{$type/@name/string()}"/>)

    }
};

declare function intro:build-schema-queryType() as element(*, gxqli:__Type)
{
    element gxqli:queryType 
    {
        element gxqli:kind {'OBJECT'},
        element gxqli:name {$intro:SCHEMA/gxqls:Query/@name/string()},
        if ($intro:SCHEMA/gxqls:Query/gxqls:description) 
        then element gxqli:description {$intro:SCHEMA/gxqls:Query/gxqls:description/string()}
        else (),
        element gxqli:fields {
            for $field in $intro:SCHEMA/gxqls:Query/gxqls:fields/gxqls:field
            return intro:build-type-field($field)
        }
    }
};

declare function intro:build-schema-mutationType() as element(*, gxqli:__Type)?
{
    if ($intro:SCHEMA/gxqls:Mutation) 
    then 
        element gxqli:mutationType 
        {
            element gxqli:kind {'OBJECT'},
            element gxqli:name {$intro:SCHEMA/gxqls:Mutation/@name/string()},
            if ($intro:SCHEMA/gxqls:Mutation/gxqls:description) 
            then element gxqli:description {$intro:SCHEMA/gxqls:Mutation/gxqls:description/string()}
            else (),
            element gxqli:fields {
                for $field in $intro:SCHEMA/gxqls:Mutation/gxqls:fields/gxqls:field
                return intro:build-type-field($field)
            }
        }
    else ()
};

declare function intro:build-schema-subscriptionType() as element(*, gxqli:__Type)?
{
    if ($intro:SCHEMA/gxqls:Subscription) 
    then 
        element gxqli:subscriptionType 
        {
            element gxqli:kind {},
            element gxqli:name {},
            element gxqli:description {}
        }
    else ()
};

declare function intro:build-schema-directives()
{
    element gxqli:directives 
    {
        for $directive in $intro:SCHEMA//gxqls:directives/gxqls:Directive
        return intro:build-directive($directive)
    }
};

declare function intro:build-directive($directive as element(*, gxqls:Directive)) as element(*, gxqli:__Directive)
{
    element gxqli:__Directive
    {
        element gxqli:name {$directive/@name/string()},
        element gxqli:description {$directive/gxqls:description/string()},
        element gxqli:locations 
        {
            $directive/gxqls:locations/gxqls:location/string()!(element gxqli:__DirectiveLocation {.})
        },
        element gxqli:args 
        {
            for $arg in $directive/gxqls:args/gxqls:Arg
            return intro:build-input-value($arg)
        },
        element gxqli:isRepeatable 
        {
            if ($directive/@isRepeatable/string()='true') then xs:boolean('true') else xs:boolean('false')
        }
    }
};

declare function intro:build-type($type) as element(*, gxqli:__Type)
{
    intro:build-type($type, '__Type')
};

declare function intro:build-type($type, $name as xs:string) as element(*, gxqli:__Type)
{
    let $local-name := $type/local-name()

    let $root-kind :=                  
                 if (fn:upper-case($type/@name/string()) = $intro:SCALARS) then 'SCALAR'
            else if ($local-name = 'InterfaceType') then 'INTERFACE'
            else if ($local-name = 'Type') then 'OBJECT'
            else if ($local-name = 'UnionType') then 'UNION'
            else if ($local-name = 'EnumType') then 'ENUM'
            else if ($local-name = 'InputType') then 'INPUT_OBJECT'
            else fn:error((), 'SCHEMA TYPE RESOLVER EXCEPTION', ("500", "Internal server error", "unsupported type kind: "||$local-name))

    let $kind := 
             if ($type/@kind/string() = 'List') then 'LIST' 
        else if ($type/parent::*/@nullable/string() = 'false') then 'NON_NULL' 
        else $root-kind

    return
    element {xs:QName('gxqli:'||$name)} 
    {
        (: KIND :)
        element gxqli:kind {$kind},

        (: NAME :)
        if (not($kind = ('LIST', 'NON_NULL'))) then 
        element gxqli:name 
        {
            $type/@name/string() 
        } else (),

        (: DESCRIPTION :)
        if ($type/gxqls:description)
        then element gxqli:description 
        {
            $type/gxqls:description/string()
        } else ( ),

        (: FIELDS :)
        if ($root-kind = ('OBJECT', 'INTERFACE') and $type/gxqls:fields) 
        then element gxqli:fields 
        {
            for $field in $type/gxqls:fields/gxqls:field
                return intro:build-type-field($field)
        } else (),

         (: INTERFACES :)
        (: OBJECT only :)
        if ($root-kind = ('OBJECT', 'INTERFACE'))
        then element gxqli:interfaces 
        {
            for $interface-type in $intro:SCHEMA/gxqls:types/gxqls:Type[./@name/string() = $type/@name/string()]/gxqls:interfaces/gxqls:Type
                let $base-type := $intro:SCHEMA/gxqls:types/gxqls:InterfaceType[./@name/string() = $interface-type/@name/string()]
                return intro:build-type($base-type)
        }
        else (), 

        (: POSSIBLE TYPES :)
        (: INTERFACE and UNION only :)
        if ($root-kind = ('INTERFACE', 'UNION')) 
        then element gxqli:possibleTypes 
        { 
            let $possible-types :=
                if ($root-kind = 'INTERFACE') 
                then $intro:SCHEMA/gxqls:types/gxqls:Type[./gxqls:interfaces/gxqls:Type/@name/string() = $type/@name/string()]
                else $intro:SCHEMA/gxqls:types/gxqls:UnionType[@name/string() = $type/@name/string()]/gxqls:types/gxqls:Type
            for $possible-type in $possible-types
                return intro:build-possible-type($possible-type)
        } 
        else (), 

        (: ENUM VALUES :)
        (: ENUM only :)
        if ($root-kind = 'ENUM') 
        then element gxqli:enumValues 
        {
            for $enum-value in $intro:SCHEMA/gxqls:types/gxqls:EnumType[@name/string() = $type/@name/string()]/gxqls:values/gxqls:value
                return intro:build-enum-value($enum-value)
        }
        else (), 

        (: INPUT FIELDS :)
        (: INPUT OBJECT only :)
        if ($root-kind = 'INPUT_OBJECT') 
        then element gxqli:inputFields 
        {
            for $input-field in $intro:SCHEMA/gxqls:types/gxqls:InputType[@name/string() = $type/@name/string()]/gxqls:fields/gxqls:field
                return intro:build-input-value($input-field)
        }
        else (), 

        (: OF-TYPE :)
        (: NON_NULL and LIST only :)
        if ($kind = ('LIST', 'NON_NULL')) 
        then element gxqli:ofType 
        {
            element gxqli:name {$type/@name/string()},
            element gxqli:kind {$root-kind}
        }
        else ()
    }
};

declare function intro:build-input-value($input-field) as element(*, gxqli:__InputValue)
{
    element gxqli:__InputValue
    {
        element gxqli:name {$input-field/@name/string()},
        if ($input-field/gxqls:description)
        then element gxqli:description 
        {
            $input-field/gxqls:description/string()
        } 
        else (),
        intro:build-type($input-field/gxqls:Type, 'type'),
        if ($input-field/@default)
        then element gxqli:defaultValue 
        {
            $input-field/@default/string()
        }
        else ()
    }
};

declare function intro:build-enum-value($enum-value as element(*,gxqls:EnumValue)) as element(*, gxqli:__EnumValue)
{
    element gxqli:__EnumValue
    {
        element gxqli:name {$enum-value/@label/string()},
        if ($enum-value/gxqls:description)
        then element gxqli:description 
        {
            $enum-value/gxqls:description/string()
        } else (),
        element gxqli:isDeprecated 
        {
            if ($enum-value/@deprecated/string() = 'true') then xs:boolean('true') else xs:boolean('false')
        },
        if ($enum-value/gxqls:deprecationReason)
        then element gxqli:deprecationReason {$enum-value/gxqls:deprecationReason/string()}
        else ()
    }    
};

declare function intro:build-possible-type($possible-type as element(*, gxqls:Type)) as element(*, gxqli:__Type)
{
    element gxqli:__Type
    {
        element gxqli:kind {'OBJECT'},
        element gxqli:name {$possible-type/@name/string()}
    }

};

declare function intro:build-type-field($field as element(*, gxqls:Field)) as element(*, gxqli:__Field)
{
    element gxqli:__Field 
    {
        element gxqli:name 
        {
            $field/@name/string()
        },
        if ($field/gxqls:description)
        then element gxqli:description 
        {
            $field/gxqls:description/string()
        } else (),
        element gxqli:args 
        {
            for $arg in $field/gxqls:args/gxqls:Arg
            return intro:build-field-arg($arg)
        },
        (
            let $field-type-name := $field/gxqls:Type/@name/string()
            let $root-type := $intro:SCHEMA/gxqls:types/child::*[./@name/string() = $field-type-name]
            let $type := 
                if ($root-type) 
                then 
                    element {xs:QName('gxqls:'||$root-type/local-name())}
                    {
                        attribute kind {$field/gxqls:Type/@kind/string()},
                        attribute name {$root-type/@name/string()}
                    } 
                else $field/gxqls:Type
            return
                intro:build-type($type, 'type')
        ),
        element gxqli:isDeprecated 
        {
            if ($field/@deprecated) then xs:boolean('true') else xs:boolean('false')
        },
        if ($field/gxqls:deprecationReason)
        then element gxqli:deprecationReason {$field/gxqls:deprecationReason/string()}
        else ()
    }
};

declare function intro:build-field-arg($arg as element(*, gxqls:Arg)) as element(*, gxqli:__InputValue)
{
    element gxqli:__InputValue
    {
        element gxqli:name 
        {
            $arg/@name/string()
        },
        if ($arg/gxqls:description)
        then element gxqli:description 
        {
            $arg/gxqls:description/string()
        } else (),
        (
            let $arg-type-name := $arg/gxqls:Type/@name/string()
            let $root-type := $intro:SCHEMA/gxqls:types/child::*[@name/string() = $arg-type-name]
            let $type := 
                if ($root-type) 
                then 
                (
                    element {xs:QName('gxqls:'||$root-type/local-name())}
                    {
                        attribute kind {$arg/gxqls:Type/@kind/string()},
                        attribute name {$root-type/@name/string()}
                    } 
                )
                else $arg/gxqls:Type
            return
                intro:build-type($type, 'type')
        ),
        if ($arg/@default)
        then element gxqli:defaultValue {$arg/@default/string()}
        else ()
    }
};

declare function intro:schema-field-resolver($field-name as xs:string) as xdmp:function
{
    switch ($field-name)
    case 'description'
    return xdmp:function(xs:QName('intro:schema-description-resolver'))
    case 'types'
    return xdmp:function(xs:QName('intro:schema-types-resolver'))
    case 'queryType'
    return xdmp:function(xs:QName('intro:schema-queryType-resolver'))
    case 'mutationType'
    return xdmp:function(xs:QName('intro:schema-mutationType-resolver'))
    case 'subscriptionType'
    return xdmp:function(xs:QName('intro:schema-subscriptionType-resolver'))
    case 'directives'
    return xdmp:function(xs:QName('intro:schema-directives-resolver'))
    default 
    return fn:error((), 'SCHEMA FIELD RESOLVER EXCEPTION', ("500", "Internal server error", "unsupported field: "||$field-name))
};

declare function intro:schema-description-resolver($schema as element(*, gxqli:__Schema), $var-map as map:map) as xs:string?
{
    fn:head(($schema/gxqli:description/string(), ""))
};

declare function intro:schema-types-resolver($schema as element(*, gxqli:__Schema), $var-map as map:map) (:as element(*, gxqli:__Type)*:)
{
    if ($schema/gxqli:types/*)
    then 
    (
        let $array := json:array()
        let $_ :=
            for $value in ($schema/gxqli:types/gxqli:queryType, 
                            $schema/gxqli:types/gxqli:mutationType, 
                            $schema/gxqli:types/gxqli:subscriptionType, 
                            $schema/gxqli:types/gxqli:__Type)
                return json:array-push($array, $value)
        return $array        
    )
    else json:array()
};

declare function intro:schema-queryType-resolver($schema as element(*, gxqli:__Schema), $var-map as map:map) as element(*, gxqli:__Type)
{
    $schema/gxqli:types/gxqli:queryType
};

declare function intro:schema-mutationType-resolver($schema as element(*, gxqli:__Schema), $var-map as map:map) as element(*, gxqli:__Type)?
{
    $schema/gxqli:types/gxqli:mutationType
};

declare function intro:schema-subscriptionType-resolver($schema as element(*, gxqli:__Schema), $var-map as map:map) as element(*, gxqli:__Type)?
{
    $schema/gxqli:types/gxqli:subscriptionType
};

declare function intro:schema-directives-resolver($schema as element(*, gxqli:__Schema), $var-map as map:map)
{
    if ($schema/gxqli:directives/*)
    then 
    (
        let $array := json:array()
        let $_ :=
            for $value in ($schema/gxqli:directives/gxqli:__Directive)
            return json:array-push($array, $value)
        return $array        
    )
    else json:array()
};

declare function intro:type-field-resolver($field-name as xs:string) as xdmp:function
{
    switch ($field-name)
    case 'kind'
        return xdmp:function(xs:QName('intro:type-kind-resolver'))
    case 'name'
        return xdmp:function(xs:QName('intro:type-name-resolver'))
    case 'description'
        return xdmp:function(xs:QName('intro:type-description-resolver'))
    case 'fields'
        return xdmp:function(xs:QName('intro:type-fields-resolver'))
    case 'interfaces'
        return xdmp:function(xs:QName('intro:type-interfaces-resolver'))
    case 'possibleTypes'
        return xdmp:function(xs:QName('intro:type-possibleTypes-resolver'))
    case 'enumValues'
        return xdmp:function(xs:QName('intro:type-enumValues-resolver'))
    case 'inputFields'
        return xdmp:function(xs:QName('intro:type-inputFields-resolver'))
    case 'ofType'
        return xdmp:function(xs:QName('intro:type-ofType-resolver'))
    default 
        return fn:error((), 'TYPE FIELD RESOLVER EXCEPTION', ("500", "Internal server error", "unsupported field: "||$field-name))
};

declare function intro:type-kind-resolver($type as element(*, gxqli:__Type), $var-map as map:map) as xs:string
{
    $type/gxqli:kind/string()
};

declare function intro:type-name-resolver($type as element(*, gxqli:__Type), $var-map as map:map) as xs:string?
{
    $type/gxqli:name/string()
};

declare function intro:type-description-resolver($type as element(*, gxqli:__Type), $var-map as map:map) as xs:string?
{
    fn:head(($type/gxqli:description/string(), ""))
};

declare function intro:type-fields-resolver($type as element(*, gxqli:__Type), $var-map as map:map) (:as element(*, gxqli:__Field)*:)
{
    if ($type/gxqli:kind/string() = ('OBJECT', 'INTERFACE'))
    then
    (
        if ($type/gxqli:fields/*)
        then 
        (
            let $array := json:array()
            let $_ :=
                for $value in $type/gxqli:fields/child::*
                    return json:array-push($array, $value)
            return $array        
        )
        else json:array()
    )
    else ()
};

declare function intro:type-interfaces-resolver($type as element(*, gxqli:__Type), $var-map as map:map) (:as element(*, gxqli:__Type)*:)
{
    if ($type/gxqli:kind/string() = ('OBJECT', 'INTERFACE'))
    then
    (
        if ($type/gxqli:interfaces/*) 
        then 
        (
            let $array := json:array()
            let $_ :=
                for $value in $type/gxqli:interfaces/child::*
                    return json:array-push($array, $value)
            return $array        
        )
        else json:array() 
    )
    else ()
};

declare function intro:type-possibleTypes-resolver($type as element(*, gxqli:__Type), $var-map as map:map) (:as element(*, gxqli:__Type)*:)
{
    if ($type/gxqli:kind/string() = ('UNION', 'INTERFACE'))
    then
    (
        if ($type/gxqli:possibleTypes/*) 
        then 
        (
            let $array := json:array()
            let $_ :=
                for $value in $type/gxqli:possibleTypes/child::*
                    return json:array-push($array, $value)
            return $array        
        )
        else json:array() 
    )
    else ()
};

declare function intro:type-enumValues-resolver($type as element(*, gxqli:__Type), $var-map as map:map) (:as element(*, gxqli:__EnumValue)*:)
{ 
    if ($type/gxqli:kind/string() = 'ENUM')
    then
    (
        if ($type/gxqli:enumValues/*)
        then 
        (
            let $array := json:array()
            let $_ :=
                for $value in $type/gxqli:enumValues/child::*
                    return json:array-push($array, $value)
            return $array        
        )
        else json:array()
    )
    else ()
};

declare function intro:type-inputFields-resolver($type as element(*, gxqli:__Type), $var-map as map:map) (:as element(*, gxqli:__InputValue)*:)
{
    if ($type/gxqli:kind/string() = 'INPUT_OBJECT')
    then
    (
        if ($type/gxqli:inputFields/*)
        then 
        (
            let $array := json:array()
            let $_ :=
                for $value in $type/gxqli:inputFields/child::*
                    return json:array-push($array, $value)
            return $array        
        )
        else json:array()
    )
    else ()
};

declare function intro:type-ofType-resolver($type as element(*, gxqli:__Type), $var-map as map:map) as element(*, gxqli:__Type)?
{
    if ($type/gxqli:kind/string() = ('NON_NULL', 'LIST'))
    then
    (
        if ($type/gxqli:ofType) then 
        element gxqli:__Type 
        {
            element gxqli:kind { $type/gxqli:ofType/gxqli:kind/string() },
            element gxqli:name { $type/gxqli:ofType/gxqli:name/string() }
        }
        else ()
    )
    else ()
};

declare function intro:type-resolver($var-map as map:map) as element(*, gxqli:__Type)
{
    (: TODO: Implement caching mechanism :)
    intro:build-type($intro:SCHEMA/gxqls:types/gxqls:*[@name/string() = map:get($var-map, 'name')])
};

declare function intro:field-field-resolver($field-name as xs:string) as xdmp:function
{
    switch ($field-name)
    case 'name'
       return xdmp:function(xs:QName('intro:field-name-resolver'))
    case 'description'
        return xdmp:function(xs:QName('intro:field-description-resolver'))
    case 'args'
        return xdmp:function(xs:QName('intro:field-args-resolver'))
    case 'type'
        return xdmp:function(xs:QName('intro:field-type-resolver'))
    case 'isDeprecated'
        return xdmp:function(xs:QName('intro:field-isDeprecated-resolver'))
    case 'deprecationReason'
        return xdmp:function(xs:QName('intro:field-deprecationReason-resolver'))
    default 
        return fn:error((), 'FIELD FIELD RESOLVER EXCEPTION', ("500", "Internal server error", "unsupported field: "||$field-name))
};

declare function intro:field-name-resolver($field as element(*, gxqli:__Field), $var-map as map:map) as xs:string
{
    $field/gxqli:name/string()
};

declare function intro:field-description-resolver($field as element(*, gxqli:__Field), $var-map as map:map) as xs:string?
{
    fn:head(($field/gxqli:description/string(), ""))
};

declare function intro:field-args-resolver($field as element(*, gxqli:__Field), $var-map as map:map) (:as element(*, gxqli:__InputValue)*:)
{
    if ($field/gxqli:args/*)
    then
    (
        let $array := json:array()
        let $_ :=
            for $item in $field/gxqli:args/gxqli:__InputValue
                return json:array-push($array, $item)
        return $array
    )
    else json:array()        
};

declare function intro:field-type-resolver($field as element(*, gxqli:__Field), $var-map as map:map) as element(*, gxqli:__Type)
{
    $field/gxqli:type
};

declare function intro:field-isDeprecated-resolver($field as element(*, gxqli:__Field), $var-map as map:map) as xs:boolean
{
    $field/gxqli:isDeprecated
};

declare function intro:field-deprecationReason-resolver($field as element(*, gxqli:__Field), $var-map as map:map) as xs:string?
{
    $field/gxqli:deprecationReason/string()
};

declare function intro:input-value-field-resolver($field-name) as xdmp:function 
{
    switch ($field-name)
    case 'name'
       return xdmp:function(xs:QName('intro:input-value-name-resolver'))
    case 'description'
        return xdmp:function(xs:QName('intro:input-value-description-resolver'))
    case 'type'
        return xdmp:function(xs:QName('intro:input-value-type-resolver'))
    case 'defaultValue'
        return xdmp:function(xs:QName('intro:input-value-defaultValue-resolver'))
    default 
        return fn:error((), 'INPUT-VALUE FIELD RESOLVER EXCEPTION', ("500", "Internal server error", "unsupported field: "||$field-name))
};

declare function intro:input-value-name-resolver($input-value as element(*, gxqli:__InputValue), $var-map as map:map) as xs:string
{
    $input-value/gxqli:name/string()
};

declare function intro:input-value-description-resolver($input-value as element(*, gxqli:__InputValue), $var-map as map:map) as xs:string?
{
    fn:head(($input-value/gxqli:description/string(), ""))
};

declare function intro:input-value-type-resolver($input-value as element(*, gxqli:__InputValue), $var-map as map:map) as element(*, gxqli:__Type)
{
    $input-value/gxqli:type
};

declare function intro:input-value-defaultValue-resolver($input-value as element(*, gxqli:__InputValue), $var-map as map:map) as xs:string?
{
    $input-value/gxqli:defaultValue/string()
};

declare function intro:enum-value-field-resolver($field-name) as xdmp:function 
{
    switch ($field-name)
    case 'name'
       return xdmp:function(xs:QName('intro:enum-value-name-resolver'))
    case 'description'
        return xdmp:function(xs:QName('intro:enum-value-description-resolver'))
    case 'isDeprecated'
        return xdmp:function(xs:QName('intro:enum-value-is-deprecated-resolver'))
    case 'deprecationReason'
        return xdmp:function(xs:QName('intro:enum-value-deprecation-reason-resolver'))
    default 
        return fn:error((), 'ENUM-VALUE FIELD RESOLVER EXCEPTION', ("500", "Internal server error", "unsupported field: "||$field-name))
};

declare function intro:enum-value-name-resolver($enum-value as element(*, gxqli:__EnumValue), $var-map as map:map) as xs:string
{
    $enum-value/gxqli:name/string()
};

declare function intro:enum-value-description-resolver($enum-value as element(*, gxqli:__EnumValue), $var-map as map:map) as xs:string?
{
    fn:head(($enum-value/gxqli:description/string(), ""))
};

declare function intro:enum-value-is-deprecated-resolver($enum-value as element(*, gxqli:__EnumValue), $var-map as map:map) as xs:boolean
{
    $enum-value/gxqli:isDeprecated
};

declare function intro:enum-value-deprecation-reason-resolver($enum-value as element(*, gxqli:__EnumValue), $var-map as map:map) as xs:string?
{
    $enum-value/gxqli:deprecationReason/string()
};

declare function intro:directive-field-resolver($field-name as xs:string) as xdmp:function
{
    switch ($field-name)
    case 'name'
       return xdmp:function(xs:QName('intro:directive-name-resolver'))
    case 'description'
        return xdmp:function(xs:QName('intro:directive-description-resolver'))
    case 'locations'
        return xdmp:function(xs:QName('intro:directive-locations-resolver'))
    case 'args'
        return xdmp:function(xs:QName('intro:directive-args-resolver'))
    case 'isRepeatable'
        return xdmp:function(xs:QName('intro:directive-isRepeatable-resolver'))
    default 
        return fn:error((), 'DIRECTIVE FIELD RESOLVER EXCEPTION', ("500", "Internal server error", "unsupported field: "||$field-name))
};

declare function intro:directive-name-resolver($directive as element(*, gxqli:__Directive), $var-map as map:map) as xs:string
{
    $directive/gxqli:name/string()
};

declare function intro:directive-description-resolver($directive as element(*, gxqli:__Directive), $var-map as map:map) as xs:string?
{
    fn:head(($directive/gxqli:description/string(), ""))
};

declare function intro:directive-locations-resolver($directive as element(*, gxqli:__Directive), $var-map as map:map) 
{
    if ($directive/gxqli:locations/gxqli:__DirectiveLocation)
    then
    (
        let $array := json:array()
        let $_ :=
            for $item in $directive/gxqli:locations/gxqli:__DirectiveLocation/string()
                return json:array-push($array, $item)
        return $array
    )
    else json:array()    
};

declare function intro:directive-args-resolver($directive as element(*, gxqli:__Directive), $var-map as map:map) 
{
    if ($directive/gxqli:args/*)
    then
    (
        let $array := json:array()
        let $_ :=
            for $item in $directive/gxqli:args/gxqli:__InputValue
                return json:array-push($array, $item)
        return $array
    )
    else json:array()    
};

declare function intro:directive-isRepeatable-resolver($directive as element(*, gxqli:__Directive), $var-map as map:map) as xs:boolean
{
    $directive/gxqli:isRepeatable    
};