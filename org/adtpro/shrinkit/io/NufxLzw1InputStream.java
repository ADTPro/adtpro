package org.adtpro.shrinkit.io;

import java.io.IOException;
import java.io.InputStream;

import org.adtpro.shrinkit.CRC16;


/**
 * The <code>NufxLzw1InputStream</code> reads a data fork or
 * resource fork written in the NuFX LZW/1 format.
 * <p>
 * The layout of the LZW/1 data is as follows:
 * <table border="0">
 * <tr>
 *   <th colspan="3">"Fork" Header</th>
 * </tr><tr>
 *   <td>+0</td>
 *   <td>Word</td>
 *   <td>CRC-16 of the uncompressed data within the thread</td>
 * </tr><tr>
 *   <td>+2</td>
 *   <td>Byte</td>
 *   <td>Low-level volume number use to format 5.25" disks</td>
 * </tr><tr>
 *   <td>+3</td>
 *   <td>Byte</td>
 *   <td>RLE character used to decode this thread</td>
 * </tr><tr>
 *   <th colspan="3">Each subsequent 4K chunk of data</th>
 * </tr><tr>
 *   <td>+0</td>
 *   <td>Word</td>
 *   <td>Length after RLE compression (if RLE is not used, length 
 *       will be 4096</td>
 * </tr><tr>
 *   <td>+2</td>
 *   <td>Byte</td>
 *   <td>A $01 indicates LZW applied to this chunk; $00 that LZW
 *       <b>was not</b> applied to this chunk</td>
 * </tr>
 * <table>
 * <p>
 * Note that the LZW string table is <em>cleared</em> after
 * every chunk.
 *  
 * @author robgreene@users.sourceforge.net
 */
public class NufxLzw1InputStream extends InputStream {
	/** This is the raw data stream with all markers and compressed data. */
	private LittleEndianByteInputStream dataStream;
	/** Used for an LZW-only <code>InputStream</code>. */
	private LzwInputStream lzwStream;
	/** Used for an RLE-only <code>InputStream</code>. */
	private RleInputStream rleStream;
	/** Used for an LZW+RLE <code>InputStream</code>. */
	private InputStream lzwRleStream;
	/** This is the generic decompression stream from which we read. */
	private InputStream decompressionStream;
	/** Counts the number of bytes in the 4096 byte chunk. */
	private int bytesLeftInChunk;
	/** This is the CRC-16 for the uncompressed fork. */
	private int givenCrc = -1;
	/** This is the volume number for 5.25" disks. */
	private int volumeNumber;
	/** This is the RLE character to use. */
	private int rleCharacter;
	/** Used to track the CRC of data we've extracted */
	private CRC16 dataCrc = new CRC16();
	
	/**
	 * Create the LZW/1 input stream.
	 */
	public NufxLzw1InputStream(LittleEndianByteInputStream dataStream) {
		this.dataStream = dataStream;
	}

	/**
	 * Read the next byte in the decompressed data stream.
	 */
	public int read() throws IOException {
		if (givenCrc == -1) {					// read the data or resource fork header
			givenCrc = dataStream.readWord();
			volumeNumber = dataStream.readByte();
			rleCharacter = dataStream.readByte();
			lzwStream = new LzwInputStream(new BitInputStream(dataStream, 9));
			rleStream = new RleInputStream(dataStream, rleCharacter);
			lzwRleStream = new RleInputStream(lzwStream);
		}
		if (bytesLeftInChunk == 0) {		// read the chunk header
			bytesLeftInChunk = 4096;		// NuFX always reads 4096 bytes
			lzwStream.clearDictionary();	// Always clear dictionary
			int length = dataStream.readWord();
			int lzwFlag = dataStream.readByte();
			int flag = lzwFlag + (length == 4096 ? 0 : 2);
			switch (flag) {
			case 0:		decompressionStream = dataStream;
						break;
			case 1:		decompressionStream = lzwStream;
						break;
			case 2:		decompressionStream = rleStream;
						break;
			case 3:		decompressionStream = lzwRleStream;
						break;
			default:	throw new IOException("Unknown type of decompression, flag = " + flag);
			}
		}
		// Now we can read a data byte
		int b = decompressionStream.read();
		bytesLeftInChunk--;
		dataCrc.update(b);
		return b;
	}
	
	/**
	 * Indicates if the computed CRC matches the CRC given in the data stream.
	 */
	public boolean isCrcValid() {
		return givenCrc == dataCrc.getValue();
	}
	
	// GENERATED CODE

	public int getGivenCrc() {
		return givenCrc;
	}
	public void setGivenCrc(int givenCrc) {
		this.givenCrc = givenCrc;
	}
	public int getVolumeNumber() {
		return volumeNumber;
	}
	public void setVolumeNumber(int volumeNumber) {
		this.volumeNumber = volumeNumber;
	}
	public int getRleCharacter() {
		return rleCharacter;
	}
	public void setRleCharacter(int rleCharacter) {
		this.rleCharacter = rleCharacter;
	}
	public long getDataCrc() {
		return dataCrc.getValue();
	}
}
