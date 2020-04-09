xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace visit = "http://graph.x.ql/visitor" at "/graphXql/visitor.xqy";

(: Test setup:)
let $map-vars := map:map() => map:with('foo', 'bar')
return xdmp:set($visit:VARIABLES, $map-vars)
,
let $argument := 
    <argument>
        <variable>
            <name value="foo"/>
        </variable>
    </argument>
let $actual := visit:get-argument-value($argument)
let $expected := 'bar'
return 
(
    test:assert-equal($expected, $actual)
)
,
let $field := 
    <field>
        <arguments>
            <argument>
                <name value="foo"/>
                <value>
                    <string value="bar" block="false"/>
                </value>
            </argument>
            <argument>
                <name value="id"/>
                <value>
                    <string value="1" block="false"/>
                </value>
            </argument>
        </arguments>
    </field>
let $actual := visit:get-variables($field)
let $expected := map:map() => map:with('foo', 'bar') => map:with('id', '1')
return 
(
    test:assert-equal-json($expected, $actual)
)
,
(: Test setup:)
let $map-vars := map:map() => map:with('withFriends', xs:boolean('true'))
return xdmp:set($visit:VARIABLES, $map-vars)
,
let $node := 
    <inline-fragment>
        <directives>
            <directive>
                <name value="include"/>
                <arguments>
                    <argument>
                        <name value="if"/>
                        <value>
                            <variable>
                                <name value="withFriends"/>
                            </variable>
                        </value>
                    </argument>
                </arguments>
            </directive>
        </directives>
    </inline-fragment>
return
(
    test:assert-true(visit:include-fragment($node))
)
,
(: Test setup:)
let $map-vars := map:map() => map:with('withFriends', xs:boolean('false'))
return xdmp:set($visit:VARIABLES, $map-vars)
,
let $node := 
    <inline-fragment>
        <directives>
            <directive>
                <name value="include"/>
                <arguments>
                    <argument>
                        <name value="if"/>
                        <value>
                            <variable>
                                <name value="withFriends"/>
                            </variable>
                        </value>
                    </argument>
                </arguments>
            </directive>
        </directives>
    </inline-fragment>
return
(
    test:assert-false(visit:include-fragment($node))
)
,
(: Test setup:)
let $map-vars := map:map() => map:with('withFriends', xs:boolean('true'))
return xdmp:set($visit:VARIABLES, $map-vars)
,
let $node := 
    <selection-set>
        <field>
            <name value="name"/>
        </field>
        <field>
            <name value="friends"/>
            <directives>
                <directive>
                    <name value="include"/>
                    <arguments>
                        <argument>
                            <name value="if"/>
                            <value>
                                <variable>
                                    <name value="withFriends"/>
                                </variable>
                            </value>
                        </argument>
                    </arguments>
                </directive>
            </directives>
            <selection-set>
                <field>
                    <name value="name"/>
                </field>
            </selection-set>
        </field>
    </selection-set>
let $actual := visit:include-skip-fields($node)
let $expected := 
(
    <field>
        <name value="name"/>
    </field>,
    <field>
        <name value="friends"/>
        <directives>
            <directive>
                <name value="include"/>
                <arguments>
                    <argument>
                        <name value="if"/>
                        <value>
                            <variable>
                                <name value="withFriends"/>
                            </variable>
                        </value>
                    </argument>
                </arguments>
            </directive>
        </directives>
        <selection-set>
            <field>
                <name value="name"/>
            </field>
        </selection-set>
    </field>
)
return 
(
    test:assert-equal($expected, $actual)
)
,
(: Test setup:)
let $map-vars := map:map() => map:with('withFriends', xs:boolean('false'))
return xdmp:set($visit:VARIABLES, $map-vars)
,
let $node := 
    <selection-set>
        <field>
            <name value="name"/>
        </field>
        <field>
            <name value="friends"/>
            <directives>
                <directive>
                    <name value="include"/>
                    <arguments>
                        <argument>
                            <name value="if"/>
                            <value>
                                <variable>
                                    <name value="withFriends"/>
                                </variable>
                            </value>
                        </argument>
                    </arguments>
                </directive>
            </directives>
            <selection-set>
                <field>
                    <name value="name"/>
                </field>
            </selection-set>
        </field>
    </selection-set>
let $actual := visit:include-skip-fields($node)
let $expected := 
    <field>
        <name value="name"/>
    </field>
return 
(
    test:assert-equal($expected, $actual)
)
,
(: Test setup:)
let $map-vars := map:map() 
        => map:with('withFriends', xs:boolean('false'))
        => map:with('withFoes', xs:boolean('false'))
        => map:with('withCompare', xs:boolean('false'))
return xdmp:set($visit:VARIABLES, $map-vars)
,
let $person-1 := 
    <person xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://graph.x.ql" xsi:type="gxql:Hero">
        <name>Luke</name>
        <height>180</height>
        <appearsIn>Return of the Jedi</appearsIn>
        <friends>
            <person><id>6</id></person>
        </friends>
        <foes>
            <person><id>2</id></person>
            <person><id>3</id></person>
            <person><id>4</id></person>
            <person><id>5</id></person>
        </foes>
    </person>
let $node := 
    <document>
        <definitions>
            <operation-definition operation="query">
                <name value="Person"/>
                <variable-definition>
                    <variable>
                        <name value="id"/>
                    </variable>
                    <type>
                        <non-null-type>
                            <named-type>
                                <name value="String"/>
                            </named-type>
                        </non-null-type>
                    </type>
                </variable-definition>
                <variable-definition>
                    <variable>
                        <name value="withFriends"/>
                    </variable>
                    <type>
                        <non-null-type>
                            <named-type>
                                <name value="Boolean"/>
                            </named-type>
                        </non-null-type>
                    </type>
                </variable-definition>
                <variable-definition>
                    <variable>
                        <name value="withFoes"/>
                    </variable>
                    <type>
                        <non-null-type>
                            <named-type>
                                <name value="Boolean"/>
                            </named-type>
                        </non-null-type>
                    </type>
                </variable-definition>
                <variable-definition>
                    <variable>
                        <name value="withCompare"/>
                    </variable>
                    <type>
                        <non-null-type>
                            <named-type>
                                <name value="Boolean"/>
                            </named-type>
                        </non-null-type>
                    </type>
                </variable-definition>
                <selection-set>
                    <field>
                        <name value="person"/>
                        <arguments>
                            <argument>
                                <name value="id"/>
                                <value>
                                    <variable>
                                        <name value="id"/>
                                    </variable>
                                </value>
                            </argument>
                        </arguments>
                        <selection-set>
                            <field>
                                <name value="name"/>
                            </field>
                            <inline-fragment>
                                <type-condition>
                                    <named-type>
                                        <name value="Hero"/>
                                    </named-type>
                                </type-condition>
                                <directives>
                                    <directive>
                                        <name value="include"/>
                                        <arguments>
                                            <argument>
                                                <name value="if"/>
                                                <value>
                                                    <variable>
                                                        <name value="withFoes"/>
                                                    </variable>
                                                </value>
                                            </argument>
                                        </arguments>
                                    </directive>
                                </directives>
                                <selection-set>
                                    <field>
                                        <name value="foes"/>
                                        <selection-set>
                                            <field>
                                                <name value="name"/>
                                            </field>
                                        </selection-set>
                                    </field>
                                </selection-set>
                            </inline-fragment>
                            <field>
                                <name value="friends"/>
                                <directives>
                                    <directive>
                                        <name value="include"/>
                                        <arguments>
                                            <argument>
                                                <name value="if"/>
                                                <value>
                                                    <variable>
                                                        <name value="withFriends"/>
                                                    </variable>
                                                </value>
                                            </argument>
                                        </arguments>
                                    </directive>
                                </directives>
                                <selection-set>
                                    <field>
                                        <name value="name"/>
                                    </field>
                                </selection-set>
                            </field>
                            <fragment-spread>
                                <name value="comparisonFields"/>
                                <directives>
                                    <directive>
                                        <name value="include"/>
                                        <arguments>
                                            <argument>
                                                <name value="if"/>
                                                <value>
                                                    <variable>
                                                        <name value="withCompare"/>
                                                    </variable>
                                                </value>
                                            </argument>
                                        </arguments>
                                    </directive>
                                </directives>
                            </fragment-spread>
                        </selection-set>
                    </field>
                </selection-set>
            </operation-definition>
            <fragment-definition>
                <name value="comparisonFields"/>
                <type-condition>
                    <named-type>
                        <name value="Person"/>
                    </named-type>
                </type-condition>
                <selection-set>
                    <field>
                        <name value="appearsIn"/>
                    </field>
                    <field>
                        <name value="friends"/>
                        <selection-set>
                            <field>
                                <name value="name"/>
                            </field>
                        </selection-set>
                    </field>
                </selection-set>
            </fragment-definition>
        </definitions>
    </document>
let $actual := visit:list-fields($node/definitions/operation-definition/selection-set/field/selection-set, $person-1)
let $expected := 
    <field>
        <name value="name"/>
    </field>
return 
(
    test:assert-equal($expected, $actual)
)
,
(: Test setup:)
let $map-vars := map:map() 
        => map:with('withFriends', xs:boolean('true'))
        => map:with('withFoes', xs:boolean('true'))
        => map:with('withCompare', xs:boolean('true'))
return xdmp:set($visit:VARIABLES, $map-vars)
,
let $person-1 := 
    <person xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://graph.x.ql" xsi:type="gxql:Hero">
        <name>Luke</name>
        <height>180</height>
        <appearsIn>Return of the Jedi</appearsIn>
        <friends>
            <person><id>6</id></person>
        </friends>
        <foes>
            <person><id>2</id></person>
            <person><id>3</id></person>
            <person><id>4</id></person>
            <person><id>5</id></person>
        </foes>
    </person>
let $node := 
    <document>
        <definitions>
            <operation-definition operation="query">
                <name value="Person"/>
                <variable-definition>
                    <variable>
                        <name value="id"/>
                    </variable>
                    <type>
                        <non-null-type>
                            <named-type>
                                <name value="String"/>
                            </named-type>
                        </non-null-type>
                    </type>
                </variable-definition>
                <variable-definition>
                    <variable>
                        <name value="withFriends"/>
                    </variable>
                    <type>
                        <non-null-type>
                            <named-type>
                                <name value="Boolean"/>
                            </named-type>
                        </non-null-type>
                    </type>
                </variable-definition>
                <variable-definition>
                    <variable>
                        <name value="withFoes"/>
                    </variable>
                    <type>
                        <non-null-type>
                            <named-type>
                                <name value="Boolean"/>
                            </named-type>
                        </non-null-type>
                    </type>
                </variable-definition>
                <variable-definition>
                    <variable>
                        <name value="withCompare"/>
                    </variable>
                    <type>
                        <non-null-type>
                            <named-type>
                                <name value="Boolean"/>
                            </named-type>
                        </non-null-type>
                    </type>
                </variable-definition>
                <selection-set>
                    <field>
                        <name value="person"/>
                        <arguments>
                            <argument>
                                <name value="id"/>
                                <value>
                                    <variable>
                                        <name value="id"/>
                                    </variable>
                                </value>
                            </argument>
                        </arguments>
                        <selection-set>
                            <field>
                                <name value="name"/>
                            </field>
                            <inline-fragment>
                                <type-condition>
                                    <named-type>
                                        <name value="Hero"/>
                                    </named-type>
                                </type-condition>
                                <directives>
                                    <directive>
                                        <name value="include"/>
                                        <arguments>
                                            <argument>
                                                <name value="if"/>
                                                <value>
                                                    <variable>
                                                        <name value="withFoes"/>
                                                    </variable>
                                                </value>
                                            </argument>
                                        </arguments>
                                    </directive>
                                </directives>
                                <selection-set>
                                    <field>
                                        <name value="foes"/>
                                        <selection-set>
                                            <field>
                                                <name value="name"/>
                                            </field>
                                        </selection-set>
                                    </field>
                                </selection-set>
                            </inline-fragment>
                            <field>
                                <name value="friends"/>
                                <directives>
                                    <directive>
                                        <name value="include"/>
                                        <arguments>
                                            <argument>
                                                <name value="if"/>
                                                <value>
                                                    <variable>
                                                        <name value="withFriends"/>
                                                    </variable>
                                                </value>
                                            </argument>
                                        </arguments>
                                    </directive>
                                </directives>
                                <selection-set>
                                    <field>
                                        <name value="name"/>
                                    </field>
                                </selection-set>
                            </field>
                            <fragment-spread>
                                <name value="comparisonFields"/>
                                <directives>
                                    <directive>
                                        <name value="include"/>
                                        <arguments>
                                            <argument>
                                                <name value="if"/>
                                                <value>
                                                    <variable>
                                                        <name value="withCompare"/>
                                                    </variable>
                                                </value>
                                            </argument>
                                        </arguments>
                                    </directive>
                                </directives>
                            </fragment-spread>
                        </selection-set>
                    </field>
                </selection-set>
            </operation-definition>
            <fragment-definition>
                <name value="comparisonFields"/>
                <type-condition>
                    <named-type>
                        <name value="Person"/>
                    </named-type>
                </type-condition>
                <selection-set>
                    <field>
                        <name value="appearsIn"/>
                    </field>
                    <field>
                        <name value="friends"/>
                        <selection-set>
                            <field>
                                <name value="name"/>
                            </field>
                        </selection-set>
                    </field>
                </selection-set>
            </fragment-definition>
        </definitions>
    </document>
let $actual := visit:list-fields($node/definitions/operation-definition/selection-set/field/selection-set, $person-1)
let $expected := 
(
	<field>
		<name value="name"/>
	</field>,
	<field>
		<name value="friends"/>
		<directives>
			<directive>
				<name value="include"/>
				<arguments>
					<argument>
						<name value="if"/>
						<value>
							<variable>
								<name value="withFriends"/>
							</variable>
						</value>
					</argument>
				</arguments>
			</directive>
		</directives>
		<selection-set>
			<field>
				<name value="name"/>
			</field>
		</selection-set>
	</field>,
	<field>
		<name value="appearsIn"/>
	</field>,
	<field>
		<name value="friends"/>
		<selection-set>
			<field>
				<name value="name"/>
			</field>
		</selection-set>
	</field>,
	<field>
		<name value="foes"/>
		<selection-set>
			<field>
				<name value="name"/>
			</field>
		</selection-set>
	</field>
)
return
(
    test:assert-equal($expected, $actual)
)