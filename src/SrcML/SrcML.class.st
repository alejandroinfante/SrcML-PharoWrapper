Class {
	#name : #SrcML,
	#superclass : #Object,
	#instVars : [
		'raw'
	],
	#classInstVars : [
		'Binary'
	],
	#category : #SrcML
}

{ #category : #modes }
SrcML class >> binary [
	^ Binary ifNil: [ './srcml' asFileReference ]
]

{ #category : #modes }
SrcML class >> binary: aFileReference [
	Binary := aFileReference asFileReference
]

{ #category : #'as yet unclassified' }
SrcML class >> ensureTempFile: aBlock [
	| file |
	file := (99999999 atRandom asString , '.tmp') asFileReference.
	self assert: file exists not.
	^ [ aBlock value: file ] ensure: [ 
		file deleteIfAbsent: [  ] ]
]

{ #category : #'as yet unclassified' }
SrcML class >> extractFromCode: aString language: lang [
	^ self ensureTempFile: [ :inputFile | | stream |
		stream := inputFile writeStream.
		stream << aString.
		stream close.
		self run: {'-l'. lang. inputFile pathString } ]
]

{ #category : #'as yet unclassified' }
SrcML class >> extractFromDir: folder [
	^ self run: { folder asFileReference pathString }
]

{ #category : #'as yet unclassified' }
SrcML class >> extractJavaFromCode: aString [
	^ self extractFromCode: aString language: 'Java'
]

{ #category : #modes }
SrcML class >> primRun: argsStringOrCollection [
	| args |
	"srcML should be installed from https://www.srcml.org
	On OSX, you can download a .tar.gz from https://www.srcml.org/#download , copy the two libraries file and the executable in the same folder than the Pharo image.
	"
	self assert: [self binary exists] description: 'srcML is not installed'.
	args := argsStringOrCollection.
	args isString 
		ifFalse: [ 
			args := String streamContents: [ :str | 
						args do: [ :arg | 
								str << ' '.
								str << arg asString. ] ] ].
	^ LibC resultOfCommand: self binary pathString , args
]

{ #category : #modes }
SrcML class >> run: argsStringOrCollection [
	^ self new
		raw: (self primRun: argsStringOrCollection);
		yourself
]

{ #category : #accessing }
SrcML >> cleanAndReturn [
	| val |
	val := raw.
	raw := nil.
	^ val
]

{ #category : #accessing }
SrcML >> raw [
	^ self cleanAndReturn
]

{ #category : #accessing }
SrcML >> raw: anObject [
	raw := anObject
]

{ #category : #accessing }
SrcML >> xml [
	^ (XMLDOMParser on: self cleanAndReturn)
		documentReadLimit: 500000000;
		parseDocument
]
