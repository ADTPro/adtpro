package org.adtpro.shrinkit;

import java.util.zip.Checksum;

/**
 * Crc16: Calculate 16-bit Cyclic Redundancy Check.
 * License: GPL, incorporated by reference.
 * 
 * @author John B. Matthews
 */
public class CRC16 implements Checksum {

	/** CCITT polynomial: x^16 + x^12 + x^5 + 1 -> 0x1021 (1000000100001) */
	private static final int poly = 0x1021;
	private static final int[] table = new int[256];
	private int value = 0;

	static { // initialize static lookup table
		for (int i = 0; i < 256; i++) {
			int crc = i << 8;
			for (int j = 0; j < 8; j++) {
				if ((crc & 0x8000) == 0x8000) {
					crc = (crc << 1) ^ poly;
				} else {
					crc = (crc << 1);
				}
			}
			table[i] = crc & 0xffff;
		}
	}

	/**
	 * Update 16-bit CRC.
	 * 
	 * @param crc starting CRC value
	 * @param bytes input byte array
	 * @param off start offset to data
	 * @param len number of bytes to process
	 * @return 16-bit unsigned CRC
	 */
	private int update(int crc, byte[] bytes, int off, int len) {
		for (int i = off; i < (off + len); i++) {
			int b = (bytes[i] & 0xff);
			crc = (table[((crc >> 8) & 0xff) ^ b] ^ (crc << 8)) & 0xffff;
		}
		return crc;
	}

	public static int[] getTable() {
		return table;
	}

	public long getValue() {
		return value;
	}

	public void reset() {
		value = 0;
	}

	/**
	 * Update 16-bit CRC.
	 * 
	 * @param b input byte
	 */
	public void update(int b) {
		byte[] ba = { (byte) (b & 0xff) };
		value = update(value, ba, 0, 1);
	}

	/**
	 * Update 16-bit CRC.
	 * 
	 * @param b input byte array
	 */
	public void update(byte[] b) {
		value = update(value, b, 0, b.length);
	}

	/**
	 * Update 16-bit CRC.
	 * 
	 * @param b input byte array
	 * @param off starting offset to data
	 * @param len number of bytes to process
	 */
	public void update(byte[] b, int off, int len) {
		value = update(value, b, off, len);
	}

}