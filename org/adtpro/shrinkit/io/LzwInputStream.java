package org.adtpro.shrinkit.io;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Queue;
import java.util.concurrent.ConcurrentLinkedQueue;

/**
 * This is the generic Shrinkit LZW decompression algorithm.
 * It does not deal with the vagaries of the LZW/1 and LZW/2 data streams.
 * It does, however, deal with dictionary clears (0x100) and the 
 * <code>BitInputStream</code> bit sizes.
 *  
 * @author robgreene@users.sourceforge.net
 */
public class LzwInputStream extends InputStream {
	private BitInputStream is;
	private List<int[]> dictionary;
	private Queue<Integer> outputBuffer = new ConcurrentLinkedQueue<Integer>();
	private boolean newBuffer = true;
	// See Wikipedia entry on LZW for variable naming
	private int k;
	private int[] w;
	private int[] entry;
	
	/**
	 * Create the <code>LzwInputStream</code> based on the given
	 * <code>BitInputStream</code>.
	 * @see BitInputStream
	 */
	public LzwInputStream(BitInputStream is) {
		this.is = is;
	}

	/**
	 * Answer with the next byte from the (now) decompressed input stream.
	 */
	public int read() throws IOException {
		if (outputBuffer.isEmpty()) {
			fillBuffer();
		}
		return outputBuffer.remove();
	}

	/**
	 * Fill the buffer up with some decompressed data.
	 * This may range from one byte to many bytes, depending on what is in the
	 * dictionary.
	 * @see http://en.wikipedia.org/wiki/Lzw for the general algorithm
	 */
	public void fillBuffer() throws IOException {
		if (dictionary == null) {
			is.setRequestedNumberOfBits(9);
			// Setup default dictionary for all bytes
			dictionary = new ArrayList<int[]>();
			for (short i=0; i<256; i++) dictionary.add(new int[] { i });
			dictionary.add(new int[] { 0x100 });	// 0x100 not used by NuFX
		}
		if (newBuffer) {
			// Setup for decompression;
			k = is.read();
			outputBuffer.add(k);
			if (k == -1) return; 
			w = new int[] { k };
			newBuffer = false;
		}
		// LZW decompression
		k = is.read();
		if (k == -1) {
			outputBuffer.add(k);
			return;
		}
		if (k == 0x100) {
			dictionary = null;
			is.setRequestedNumberOfBits(9);
			k = 0;
			w = null;
			entry = null;
			newBuffer = true;
			fillBuffer();	// Warning: recursive call
			return;
		}
		if (k < dictionary.size()) {
			entry = dictionary.get(k);
		} else if (k == dictionary.size()) {
			//entry = Arrays.copyOf(w, w.length+1);
			entry = new int[w.length+1];
			System.arraycopy(w, 0, entry, 0, w.length);
			entry[w.length] = w[0];
		} else {
			throw new IOException("Invalid code of <" + k + "> encountered");
		}
		for (int i : entry) outputBuffer.add(i);
		//int[] newEntry = Arrays.copyOf(w, w.length+1);
		int[] newEntry = new int[w.length+1];
		System.arraycopy(w, 0, newEntry, 0, w.length);
		newEntry[w.length] = entry[0];
		dictionary.add(newEntry);
		w = entry;
		// Exclusive-OR the current bitmask against the new dictionary size -- if all bits are
		// on, we'll get 0.  (That is, all 9 bits on is 0x01ff exclusive or bit mask of 0x01ff 
		// yields 0x0000.)  This tells us we need to increase the number of bits we're pulling
		// from the bit stream.
		if ((dictionary.size() ^ is.getBitMask()) == 0) {
			is.increaseRequestedNumberOfBits();
		}
	}
	
	/**
	 * Clear out the dictionary.  It will be rebuilt on the next call to
	 * <code>fillBuffer</code>.
	 */
	public void clearDictionary() {
		dictionary = null;
		is.setRequestedNumberOfBits(9);
		is.clearRemainingBitsOfData();
		outputBuffer.clear();
		k = 0;
		w = null;
		entry = null;
		newBuffer = true;
	}
	
	/**
	 * Provide necessary housekeeping to reset LZW stream between NuFX buffer changes.
	 * The dictionary is the only item that is not cleared -- that needs to be done
	 * explicitly since behavior between LZW/1 and LZW/2 differ. 
	 */
	public void clearData() {
		is.clearRemainingBitsOfData();
		outputBuffer.clear();
	}
}
