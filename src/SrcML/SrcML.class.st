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
SrcML class >> primRun: argsCollection [
	| command cummulativeTime millisDelay |
	self assert: self binary exists.
	cummulativeTime := 0.
	millisDelay := 50.
	command := OSSUnixSubprocess new.
	command
		command: self binary pathString;
		arguments: argsCollection;
		redirectStdout;
		run;
		waitForExitPollingEvery: (Delay forMilliseconds: millisDelay)
		doing: [ 
			command retrieveWhatIsAvailableOn: command stdoutStream andAddItTo: command retrievedStdout.
			cummulativeTime := cummulativeTime + 1.
			cummulativeTime * millisDelay > self timeout ifTrue: [ 
				command stopWaiting.
				command terminate. ]
		].
	command closeAndCleanStreams.
	cummulativeTime * millisDelay > self timeout ifTrue: [ OSSTimeout signal ].
	^ command retrievedStdout contents
	"^ LibC resultOfCommand: self binary pathString , args"
]

{ #category : #modes }
SrcML class >> run: argsStringOrCollection [
	^ self new
		raw: (self primRun: argsStringOrCollection);
		yourself
]

{ #category : #accessing }
SrcML class >> timeout [
	"Timeout in milliseconds"
	^ 20000
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
