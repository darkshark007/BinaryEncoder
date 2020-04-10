abstract class Encoder {

	String encoderKey;
	String encoderDescription;

	Stream<List<int>> encode(Stream<List<int>> input);

	Stream<List<int>> decode(Stream<List<int>> input);
    
}