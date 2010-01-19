package org.adtpro.shrinkit.io;

import java.io.IOException;
import java.io.OutputStream;

/**
 * The RleOutputStream handles the NuFX RLE data stream.
 * This data stream is byte oriented.  If a repeat occurs,
 * the data stream will contain the marker byte, byte to 
 * repeat, and the number of repeats (zero based; ie, $00=1,
 * $01=2, ... $ff=256).  The default marker is $DB.
 * 
 * @author robgreene@users.sourceforge.net
 */
public class RleOutputStream extends OutputStream {
	private OutputStream os;
	private int escapeChar;
	private int repeatedByte;
	private int numBytes = -1;
	
	/**
	 * Create an RLE output stream with the default marker byte.
	 */
	public RleOutputStream(OutputStream bs) {
		this(bs, 0xdb);
	}
	/**
	 * Create an RLE output stream with the specified marker byte.
	 */
	public RleOutputStream(OutputStream os, int escapeChar) {
		this.os = os;
		this.escapeChar = escapeChar;
	}
	
	/**
	 * Write the next byte to the output stream.
	 */
	public void write(int b) throws IOException {
		if (numBytes == -1) {
			repeatedByte = b;
			numBytes++;
		} else if (repeatedByte == b) {
			numBytes++;
			if (numBytes > 255) {
				flush();
			}
		} else {
			flush();
			repeatedByte = b;
			numBytes++;
		}
	}
	
	/**
	 * Flush out any remaining data.
	 * If we only have 1 byte and it is <em>not</em> the repeated
	 * byte, we can just dump that byte.  Otherwise, we need to
	 * write out the escape character, the repeated byte, and
	 * the number of bytes. 
	 */
	public void flush() throws IOException {
		if (numBytes != -1) {
			if (numBytes == 0 && escapeChar != repeatedByte) {
				os.write(repeatedByte);
			} else {
				os.write(escapeChar);
				os.write(repeatedByte);
				os.write(numBytes);
			}
			numBytes = -1;
		}
	}
	
	/**
	 * Close out the data stream.  Makes sure the repeate buffer
	 * is flushed.
	 */
	public void close() throws IOException {
		flush();
		os.close();
	}
}
