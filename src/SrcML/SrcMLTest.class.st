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

{ #category : #tests }
SrcMLTest >> testTimeout [
	| old |
	old := SrcML binary.
	[ 
		SrcML binary: '/bin/sleep' asFileReference.
		self should: [ SrcML primRun: #('5') ] raise: OSSTimeout ] 
	ensure: [ SrcML binary: old ]
]
