# BinaryEncoder
This is a Library for experimenting with binary encoding/compression algorithms.  It takes the binary content of input files, applies one or more transformation algorithms to it, and writes the output to a specified file.


# How to get Started
1. Clone the repo
1. You may need to install (`dart`)[https://dart.dev/]
1. You can run the app from the command line with `dart lib/main.dart`


# Functionality
There are three supported functions at the moment:
1. Encode - Take an input file, specify one or more Encoder algorithms, and create an encoded output file.
1. Decode - Take an encoded input file, run the reverse encoding algorithms on it, and (hopefully 🤞) end up with the original unencoded input file.
1. Generate - Create a file filled with randomly generated data of specified size.