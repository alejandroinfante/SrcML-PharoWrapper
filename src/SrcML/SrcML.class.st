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
	^ [
		file := (9999999999999999 atRandom asString , '.tmp') asFileReference.
		self assert: file exists not.
		aBlock value: file ] ensure: [ 
			file ifNotNil: [ file deleteIfAbsent: [  ] ] ]
]

{ #category : #'as yet unclassified' }
SrcML class >> extractFromCode: aString language: lang [
	| count result |
	"count := 1.
	[ result notNil and: [ count < 5 ] ] whileFalse: [ 
		count := count + 1.
		[ result := self prim_run_remote: aString lang: lang ]
			on: Error
			do: [ :err | nil ]]."
		
	^ self new
		raw: (self prim_run_remote: aString lang: lang);
		yourself
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
				command terminate.
				command queryExitStatus ]
		].
	command closeAndCleanStreams.
	cummulativeTime * millisDelay > self timeout ifTrue: [ OSSTimeout signal ].
	^ command retrievedStdout contents
	"^ LibC resultOfCommand: self binary pathString , args"
	
	"CONFIGURE STDIN! AND THEN MAKE PROCESSING PUT MANY METHODS IN THE SAME FILE"
]

{ #category : #modes }
SrcML class >> primRunSimple: input args: argsCollection [
	| command stdOutstream outStream inputThread outputThread |
	self assert: self binary exists.
	command := OSSUnixSubprocess new.
	outStream := command systemAccessor makeNonBlockingPipe.
	stdOutstream := (String new: 500) writeStream.
	command
		command: self binary pathString;
		arguments: argsCollection;
		redirectStdin;
		redirectStdoutTo: outStream;
		run.
	[inputThread := [ |inputStream|
		[ 
			inputStream := input readStream.
			[ inputStream atEnd ] whileFalse: [ 
				command stdinStream nextPutAll: (inputStream next: 512) ].
			command stdinStream close ] on: Error do: [ :e | ] ] fork.
	outputThread := [ [ 
			[ 
				[ outStream atEnd ] whileFalse: [ stdOutstream nextPutAll: (outStream next: 2000) ].
				(Delay forMilliseconds: 5) wait ] repeat ] on: Error do: [ :e | ] ] forkAt: 40.
	Processor yield.
	command waitForExitWithTimeout: 60 seconds. ] ensure: [ 
		[inputThread terminate.
		outputThread terminate.
		stdOutstream nextPutAll: outStream upToEndOfFile.] ensure: [ command closeAndCleanStreams ] ].
	^ stdOutstream contents
	"^ LibC resultOfCommand: self binary pathString , args"
	
	"CONFIGURE STDIN! AND THEN MAKE PROCESSING PUT MANY METHODS IN THE SAME FILE"
]

{ #category : #'as yet unclassified' }
SrcML class >> prim_run_remote: aString lang: lang [
	^ self primRunSimple: aString args: {'-l'. lang}
	"^ RemoteCommand
		binary: self binary
		args:
			{'-l'.
			lang}
		stdin: aString readStream"
]

{ #category : #modes }
SrcML class >> run: argsStringOrCollection [
	^ self new
		raw: (self primRun: argsStringOrCollection);
		yourself
]

{ #category : #modes }
SrcML class >> run: argsStringOrCollection src: sourceCode [
	^ self new
		raw: (self primRun: argsStringOrCollection src: sourceCode);
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
