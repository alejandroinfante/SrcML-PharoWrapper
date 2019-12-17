Class {
	#name : #RemoteCommand,
	#superclass : #Object,
	#instVars : [
		'stdin',
		'binary',
		'args',
		'command',
		'inputThread',
		'commandThread',
		'waitSem'
	],
	#category : #SrcML
}

{ #category : #'as yet unclassified' }
RemoteCommand class >> binary: bin args: args [
	^ self new
		binary: bin;
		args: args;
		run
]

{ #category : #'as yet unclassified' }
RemoteCommand class >> binary: bin args: args stdin: stdin [
	^ self new
		binary: bin;
		args: args;
		stdin: stdin;
		run
]

{ #category : #accessing }
RemoteCommand >> args [
	^ args
]

{ #category : #accessing }
RemoteCommand >> args: anObject [
	args := anObject
]

{ #category : #accessing }
RemoteCommand >> binary [
	^ binary
]

{ #category : #accessing }
RemoteCommand >> binary: anObject [
	binary := anObject
]

{ #category : #accessing }
RemoteCommand >> command [
	^ command
]

{ #category : #running }
RemoteCommand >> createCommandThread [
	commandThread := [ | count |
		count := 1.
		[[ command pid notNil and: [ count < 5 ] ] whileFalse: [ 
			count := count + 1.
			command run ].
		command
			waitForExitPollingEvery: (Delay forMilliseconds: 5)
			doing: [ 
				command 
					retrieveWhatIsAvailableOn: command stdoutStream 
					andAddItTo: command retrievedStdout ].
		command 
			retrieveWhatIsAvailableOn: command stdoutStream 
			andAddItTo: command retrievedStdout] on: Error do: [ :err | ].
		waitSem signal ] fork
]

{ #category : #running }
RemoteCommand >> createInputThread [
	inputThread := [ 
		[ 
			[ stdin atEnd ] whileFalse:
				[ command stdinStream nextPutAll: (stdin next: 1024) ].
			command stdinStream close ] on: Error do: [ :e | ] ] fork
]

{ #category : #running }
RemoteCommand >> run [
	self assert: self binary exists.
	waitSem := Semaphore new.
	command := OSSUnixSubprocess new.
	command
		command: self binary pathString;
		arguments: args;
		redirectStdout;
		redirectStdin.
	[ self createCommandThread.
	(Delay forMilliseconds: 5) wait.
	self createInputThread.
	waitSem wait: (Duration milliSeconds: 20000) ]
		ensure: [ 
			commandThread terminate.
			inputThread terminate.
			command closeAndCleanStreams.
			command pid ifNotNil: [ command queryExitStatus ifNil: [ 
				command stopWaiting.
				[ command terminate ] on: Error do: [ :err | 
					"Do nothing." 
					"Weird border-case where process stops 
					just between query the exit and terminating it" ] ] ] ].
	command queryExitStatus == 0 ifFalse: [ Error signal: 'Command failed!!' ].
	^ command retrievedStdout contents
]

{ #category : #accessing }
RemoteCommand >> stdin [
	^ stdin
]

{ #category : #accessing }
RemoteCommand >> stdin: anObject [
	stdin := anObject
]
