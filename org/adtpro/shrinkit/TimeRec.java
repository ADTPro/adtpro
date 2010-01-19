package org.adtpro.shrinkit;

import java.io.IOException;
import java.io.InputStream;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;

/**
 * Apple IIgs Toolbox TimeRec object.
 *  
 * @author robgreene@users.sourceforge.net
 */
public class TimeRec {
	private static final int SECOND = 0;
	private static final int MINUTE = 1;
	private static final int HOUR = 2;
	private static final int YEAR = 3;
	private static final int DAY = 4;
	private static final int MONTH = 5;
	private static final int WEEKDAY = 7;
	private static final int LENGTH = 8;
	private byte[] data = null;
	
	/**
	 * Construct a TimeRec with the current date.
	 */
	public TimeRec() {
		this(new Date());
	}
	/**
	 * Construct a TimeRec with the specified date.  You may pass in a null for a null date (all 0x00's).
	 */
	public TimeRec(Date date) {
		setDate(date);
	}
	/**
	 * Construct a TimeRec from the given LENGTH byte array.
	 */
	public TimeRec(byte[] bytes, int offset) {
		if (bytes == null || bytes.length - offset < LENGTH) {
			throw new IllegalArgumentException("TimeRec requires a " + LENGTH + " byte array.");
		}
		//data = Arrays.copyOfRange(bytes, offset, LENGTH);
		data = new byte[LENGTH];
		System.arraycopy(bytes, offset, data, 0, LENGTH);
	}
	/**
	 * Construct a TimeRec from the InputStream.
	 */
	public TimeRec(InputStream inputStream) throws IOException {
		data = new byte[LENGTH];
		for (int i=0; i<LENGTH; i++) {
			data[i] = (byte)inputStream.read();
		}
	}

	/**
	 * Set the date.
	 */
	public void setDate(Date date) {
		data = new byte[LENGTH];
		if (date != null) {
			GregorianCalendar gc = new GregorianCalendar();
			gc.setTime(date);
			data[SECOND] = (byte)gc.get(Calendar.SECOND);
			data[MINUTE] = (byte)gc.get(Calendar.MINUTE);
			data[HOUR] = (byte)gc.get(Calendar.HOUR_OF_DAY);
			data[YEAR] = (byte)(gc.get(Calendar.YEAR) - 1900);
			data[DAY] = (byte)(gc.get(Calendar.DAY_OF_MONTH) - 1);
			data[MONTH] = (byte)gc.get(Calendar.MONTH);
			data[WEEKDAY] = (byte)gc.get(Calendar.DAY_OF_WEEK);
		}
	}

	/**
	 * Convert the TimeRec into a Java Date object.
	 * Note that years 1900-1939 are assumed to be 2000-2039 per the NuFX addendum
	 * at http://www.nulib.com/library/nufx-addendum.htm.
	 * @see http://www.nulib.com/library/nufx-addendum.htm
	 */
	public Date getDate() {
		int year = data[YEAR]+1900;
		if (year < 1940) year+= 100;
		GregorianCalendar gc = new GregorianCalendar(year, data[MONTH]+1, data[DAY], data[HOUR], data[MINUTE], data[SECOND]);
		return gc.getTime();
	}
	public byte[] getBytes() {
		return data;
	}
}
