xquery version "1.0-ml";

module namespace builder = "http://graph.x.ql/schema-builder";

declare namespace gxqls = "http://graph.x.qls";

declare variable $builder:SCHEMA as element(*, gxqls:Schema) := fn:doc('/graphXql/schema.xml')/gxqls:Schema;
declare variable $builder:INTROSPECTION-SCHEMA as element(*, gxqls:Schema) := fn:doc('/graphXql/introspection/introspection-schema.xml')/gxqls:Schema;

declare function builder:build-graphXql-schema() as element(*, gxqls:Schema)
{
    element gxqls:Schema
    {
        $builder:SCHEMA/(* except gxqls:types),

        element gxqls:types 
        {
            $builder:SCHEMA/gxqls:types/*,
            $builder:INTROSPECTION-SCHEMA/gxqls:types/*
        }
    }
};