package org.adtpro.shrinkit.io;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Arrays;
import java.util.Date;
import java.util.GregorianCalendar;

import org.adtpro.shrinkit.CRC16;


/**
 * A simple class to hide the source of byte data.
 * @author robgreene@users.sourceforge.net
 */
public class LittleEndianByteInputStream extends InputStream implements ByteConstants {
	private InputStream inputStream;
	private long bytesRead = 0;
	private CRC16 crc = new CRC16();

	/**
	 * Construct a LittleEndianByteInputStream from an InputStream.
	 */
	public LittleEndianByteInputStream(InputStream inputStream) {
		this.inputStream = inputStream;
	}
	/**
	 * Construct a LittleEndianByteInputStream from a byte array.
	 */
	public LittleEndianByteInputStream(byte[] data) {
		this.inputStream = new ByteArrayInputStream(data);
	}

	/**
	 * Get the next byte.
	 * Returns -1 if at end of input.
	 * Note that an unsigned byte needs to be returned in a larger container (ie, a short or int or long).
	 */
	public int read() throws IOException {
		int b = inputStream.read();
		if (b != -1) {
			crc.update(b);
			bytesRead++;
		}
		return b;
	}
	/**
	 * Get the next byte and fail if we are at EOF.
	 * Note that an unsigned byte needs to be returned in a larger container (ie, a short or int or long).
	 */
	public int readByte() throws IOException {
		int i = read();
		if (i == -1) throw new IOException("Expecting a byte but at EOF");
		return i;
	}
	/**
	 * Get the next set of bytes as an array.
	 * If EOF encountered, an IOException is thrown.
	 */
	public byte[] readBytes(int bytes) throws IOException {
		byte[] data = new byte[bytes];
		int read = inputStream.read(data);
		bytesRead+= read;
		if (read < bytes) {
			throw new IOException("Requested " + bytes + " bytes, but " + read + " read");
		}
		crc.update(data);
		return data;
	}

	/**
	 * Test that the NuFile id is embedded in the LittleEndianByteInputStream.
	 */
	public boolean checkNuFileId() throws IOException {
		byte[] data = readBytes(6);
		return Arrays.equals(data, NUFILE_ID);
	}
	/**
	 * Test that the NuFx id is embedded in the LittleEndianByteInputStream.
	 */
	public boolean checkNuFxId() throws IOException {
		byte[] data = readBytes(4);
		return Arrays.equals(data, NUFX_ID);
	}
	/**
	 * Read the two bytes in as a "Word" which needs to be stored as a Java int.
	 */
	public int readWord() throws IOException {
		return (readByte() | readByte() << 8) & 0xffff;
	}
	/**
	 * Read the two bytes in as a "Long" which needs to be stored as a Java long.
	 */
	public long readLong() throws IOException {
		long a = readByte();
		long b = readByte();
		long c = readByte();
		long d = readByte();
		return (long)(a | b<<8 | c<<16 | d<<24);
	}
	/**
	 * Read the TimeRec into a Java Date object.
	 * Note that years 00-39 are assumed to be 2000-2039 per the NuFX addendum
	 * at http://www.nulib.com/library/nufx-addendum.htm.
	 * @see http://www.nulib.com/library/nufx-addendum.htm
	 */
	public Date readDate() throws IOException {
		byte[] data = readBytes(TIMEREC_LENGTH);
		if (Arrays.equals(TIMEREC_NULL, data)) return null;
		int year = data[TIMEREC_YEAR]+1900;
		if (year < 1940) year+= 100;
		GregorianCalendar gc = new GregorianCalendar(year, data[TIMEREC_MONTH]-1, data[TIMEREC_DAY], 
				data[TIMEREC_HOUR], data[TIMEREC_MINUTE], data[TIMEREC_SECOND]);
		return gc.getTime();
	}
	
	/**
	 * Reset the CRC-16 to $0000.
	 */
	public void resetCrc() {
		crc.reset();
	}
	/**
	 * Get the current CRC-16 value.
	 */
	public long getCrcValue() {
		return crc.getValue();
	}
	
	/**
	 * Answer with the total number of bytes read.
	 */
	public long getTotalBytesRead() {
		return bytesRead;
	}
}
