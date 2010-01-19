package org.adtpro.shrinkit.io;

import java.io.IOException;
import java.io.OutputStream;
import java.util.HashMap;
import java.util.Map;

import org.adtpro.shrinkit.CRC16;


/**
 * This is the generic Shrinkit LZW compression algorithm.
 * It does not deal with the vagaries of the LZW/1 and LZW/2 data streams.
 *  
 * @author robgreene@users.sourceforge.net
 */
public class LzwOutputStream extends OutputStream {
	private BitOutputStream os;
	private Map<ByteArray,Integer> dictionary = new HashMap<ByteArray,Integer>();
	private int[] w = new int[0];
	private int nextCode = 0x101;
	
	/**
	 * This simple class can be used as a key into a Map.
	 *  
	 * @author robgreene@users.sourceforge.net
	 */
	private class ByteArray {
		/** Data being managed. */
		private int[] data;
		/** The computed hash code -- CRC-16 for lack of imagination. */
		private int hashCode;
		
		public ByteArray(int d) {
			this(new int[] { d });
		}
		public ByteArray(int[] data) {
			this.data = data;
			CRC16 crc = new CRC16();
			for (int b : data) crc.update(b);
			hashCode = (int)crc.getValue();
		}
		public boolean equals(Object obj) {
			ByteArray ba = (ByteArray)obj;
			if (data.length != ba.data.length) return false;
			for (int i=0; i<data.length; i++) {
				if (data[i] != ba.data[i]) return false;
			}
			return true;
		}
		public int hashCode() {
			return hashCode;
		}
	}
	
	public LzwOutputStream(BitOutputStream os) {
		this.os = os;
	}

	@Override
	public void write(int c) throws IOException {
		if (dictionary.isEmpty()) {
			for (int i=0; i<256; i++) dictionary.put(new ByteArray(i), i);
			dictionary.put(new ByteArray(0x100), null);	// just to mark its spot
		}
		c &= 0xff;
		int[] wc = new int[w.length + 1];
		if (w.length > 0) System.arraycopy(w, 0, wc, 0, w.length);
		wc[wc.length-1]= c;
		if (dictionary.containsKey(new ByteArray(wc))) {
			w = wc;
		} else {
			dictionary.put(new ByteArray(wc), nextCode++);
			os.write(dictionary.get(new ByteArray(w)));
			w = new int[] { c };
		}
		// Exclusive-OR the current bitmask against the new dictionary size -- if all bits are
		// on, we'll get 0.  (That is, all 9 bits on is 0x01ff exclusive or bit mask of 0x01ff 
		// yields 0x0000.)  This tells us we need to increase the number of bits we're writing
		// to the bit stream.
		if ((dictionary.size() ^ os.getBitMask()) == 0) {
			os.increaseRequestedNumberOfBits();
		}
	}

	@Override
	public void flush() throws IOException {
		os.write(dictionary.get(new ByteArray(w)));
	}
	
	@Override
	public void close() throws IOException {
		flush();
		os.flush();
		os.close();
	}
}
