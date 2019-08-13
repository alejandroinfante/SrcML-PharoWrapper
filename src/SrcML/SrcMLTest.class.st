Class {
	#name : #SrcMLTest,
	#superclass : #TestCase,
	#category : #SrcML
}

{ #category : #tests }
SrcMLTest >> testEmptyJavaClass [
	| srcml |
	srcml := SrcML extractJavaFromCode: 'class Foo {}'.
	self assert: 
		(srcml raw indexOfSubCollection: '<class>class <name>Foo</name> <block>{}</block></class>') ~= 0.
]
