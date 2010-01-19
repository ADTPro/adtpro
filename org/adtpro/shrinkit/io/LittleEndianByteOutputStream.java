package org.adtpro.shrinkit.io;

import java.io.IOException;
import java.io.OutputStream;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;

import org.adtpro.shrinkit.CRC16;


/**
 * An OutputStream with helper methods to write little endian numbers
 * and other Apple-specific tidbits.
 * 
 * @author robgreene@users.sourceforge.net
 */
public class LittleEndianByteOutputStream extends OutputStream implements ByteConstants {
	private OutputStream outputStream;
	private long bytesWritten = 0;
	private CRC16 crc = new CRC16();

	/**
	 * Construct a LittleEndianByteOutputStream from an OutputStream.
	 */
	public LittleEndianByteOutputStream(OutputStream outputStream) {
		this.outputStream = outputStream;
	}

	/**
	 * Write a next byte.
	 */
	public void write(int b) throws IOException {
		outputStream.write(b);
		crc.update(b);
	}

	/**
	 * Write the NuFile id to the LittleEndianByteOutputStream.
	 */
	public void writeNuFileId() throws IOException {
		write(NUFILE_ID);
	}
	/**
	 * Write the NuFX id to the LittleEndianByteOutputStream.
	 */
	public void writeNuFxId() throws IOException {
		write(NUFX_ID);
	}
	/**
	 * Write a "Word".
	 */
	public void writeWord(int w) throws IOException {
		write(w & 0xff);
		write(w >> 8);
	}
	/**
	 * Write a "Long".
	 */
	public void writeLong(long l) throws IOException {
		write((int)(l & 0xff));
		write((int)((l >> 8) & 0xff));
		write((int)((l >> 16) & 0xff));
		write((int)((l >> 24) & 0xff));
	}
	/**
	 * Write the Java Date object as a TimeRec.
	 * Note that years 2000-2039 are assumed to be 00-39 per the NuFX addendum
	 * at http://www.nulib.com/library/nufx-addendum.htm.
	 * @see http://www.nulib.com/library/nufx-addendum.htm
	 */
	public void writeDate(Date date) throws IOException {
		byte[] data = null;
		if (date == null) {
			data = TIMEREC_NULL;
		} else {
			data = new byte[TIMEREC_LENGTH];
			GregorianCalendar gc = new GregorianCalendar();
			gc.setTime(date);
			int year = gc.get(Calendar.YEAR);
			year -= (year < 2000) ? 1900 : 2000;
			data[TIMEREC_YEAR] = (byte)(year & 0xff);
			data[TIMEREC_MONTH] = (byte)(gc.get(Calendar.MONTH) + 1);
			data[TIMEREC_DAY] = (byte)gc.get(Calendar.DAY_OF_MONTH);
			data[TIMEREC_HOUR] = (byte)gc.get(Calendar.HOUR_OF_DAY);
			data[TIMEREC_MINUTE] = (byte)gc.get(Calendar.MINUTE);
			data[TIMEREC_SECOND] = (byte)gc.get(Calendar.SECOND);
			data[TIMEREC_WEEKDAY] = (byte)gc.get(Calendar.DAY_OF_WEEK);
		}
		write(data);
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
	 * Answer with the total number of bytes written.
	 */
	public long getTotalBytesWritten() {
		return bytesWritten;
	}
	
	/**
	 * Pass the flush request to the wrapped stream.
	 */
	public void flush() throws IOException {
		outputStream.flush();
	}
	/**
	 * Pass the close request to the wrapped stream.
	 */
	public void close() throws IOException {
		outputStream.close();
	}
}
