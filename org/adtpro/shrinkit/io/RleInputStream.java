package org.adtpro.shrinkit.io;

import java.io.IOException;
import java.io.InputStream;


/**
 * The RleInputStream handles the NuFX RLE data stream.
 * This data stream is byte oriented.  If a repeat occurs,
 * the data stream will contain the marker byte, byte to 
 * repeat, and the number of repeats (zero based; ie, $00=1,
 * $01=2, ... $ff=256).  The default marker is $DB.
 * 
 * @author robgreene@users.sourceforge.net
 */
public class RleInputStream extends InputStream {
	private InputStream bs;
	private int escapeChar;
	private int repeatedByte;
	private int numBytes = -1;
	
	/**
	 * Create an RLE input stream with the default marker byte.
	 */
	public RleInputStream(InputStream bs) {
		this(bs, 0xdb);
	}
	/**
	 * Create an RLE input stream with the specified marker byte.
	 */
	public RleInputStream(InputStream bs, int escapeChar) {
		this.bs = bs;
		this.escapeChar = escapeChar;
	}

	/**
	 * Read the next byte from the input stream.
	 */
	public int read() throws IOException {
		if (numBytes == -1) {
			int b = bs.read();
			if (b == escapeChar) {
				repeatedByte = bs.read();
				numBytes = bs.read();
			} else {
				return b;
			}
		}
		numBytes--;
		return repeatedByte;
	}

}
