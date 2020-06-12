// Abstract base class for a data Encoder.  All encoders expected to interface with this application should implement this base class interface and the associated fields/methods
abstract class Encoder {

	String encoderKey; // This key will be used to identify the encoder implementation in encoded files and should be globally unique per Encoder.  It should be exactly 8 characters long.
	String encoderDescription; // This will be used to describe the encoder in the command line interface.

	Stream<List<int>> encode(Stream<List<int>> input); // This function should take in a stream which will contain the data to be encoded, and it should return a stream which will contain the encoded data.

	Stream<List<int>> decode(Stream<List<int>> input); // This function should take in a stream which will contain the data to be decoded, and it should return a stream which will contain the decoded data.
    
}