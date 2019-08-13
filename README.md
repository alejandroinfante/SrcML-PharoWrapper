# SrcML-PharoWrapper
Simple wrapper of SrcML for Pharo

## Getting started

1. Download SrcML binaries from [SrcML](https://www.srcml.org/#download) website and extract them in your filesystem. 
1. Copy or create a symlink for the dynamic libraries inside the _srcml/lib_ folder to the folder of the Pharo image.
1. Copy or create a symlink for the SrcML binary in _srcml/bin/srcml_ to the folder of the image (working directory).
1. Install XMLParser and XPath from the Pharo catalog.
1. Run the tests of the package.

## How to use

There are two use modes of this wrapper.

### Extract and analyze a directory
Extract and analyze all the source files in a directory.
```
(SrcML extractFromDir: 'PATH/TO/SOURCE/DIRECTORY') xml
```

### Extract and analyze a String
Extract and analyze the source code stored in a String in Pharo. In this case it is mandatory to pass the target language to SourceML.
```
(SrcML extractFromCode: sourceCodeString language: 'C++') xml. "-> Extract the code using a C++ parser."
(SrcML extractJavaFromCode: sourceCodeString) xml. "-> Syntactic sugar for extracting the code using a Java parser"
```
