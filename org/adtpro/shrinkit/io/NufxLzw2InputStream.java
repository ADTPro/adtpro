package org.adtpro.shrinkit.io;

import java.io.IOException;
import java.io.InputStream;

import org.adtpro.shrinkit.CRC16;


/**
 * The <code>NufxLzw2InputStream</code> reads a data fork or
 * resource fork written in the NuFX LZW/2 format.
 * <p>
 * The layout of the LZW/2 data is as follows:
 * <table border="0">
 * <tr>
 *   <th colspan="3">"Fork" Header</th>
 * </tr><tr>
 *   <td>+0</td>
 *   <td>Byte</td>
 *   <td>Low-level volume number used to format 5.25" disks</td>
 * </tr><tr>
 *   <td>+1</td>
 *   <td>Byte</td>
 *   <td>RLE character used to decode this thread</td>
 * </tr><tr>
 *   <th colspan="3">Each subsequent 4K chunk of data</th>
 * </tr><tr>
 *   <td>+0</td>
 *   <td>Word</td>
 *   <td>Bits 0-12: Length after RLE compression<br/>
 *       Bit 15: LZW flag (set to 1 if LZW used)</td>
 * </tr><tr>
 *   <td>+2</td>
 *   <td>Word</td>
 *   <td>If LZW flag = 1, total bytes in chunk<br/>
 *       Else (flag = 0) start of data</td>
 * </tr>
 * <table>
 * <p>
 * The LZW/2 dictionary is only cleared when the table becomes full and is indicated
 * in the input stream by 0x100.  It is also cleared whenever a chunk that is not
 * LZW encoded is encountered.
 *  
 * @author robgreene@users.sourceforge.net
 */
public class NufxLzw2InputStream extends InputStream {
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
	/** This is the volume number for 5.25" disks. */
	private int volumeNumber = -1;
	/** This is the RLE character to use. */
	private int rleCharacter;
	/** Used to track the CRC of data we've extracted */
	private CRC16 dataCrc = new CRC16();
	
	/**
	 * Create the LZW/2 input stream.
	 */
	public NufxLzw2InputStream(LittleEndianByteInputStream dataStream) {
		this.dataStream = dataStream;
	}

	/**
	 * Read the next byte in the decompressed data stream.
	 */
	public int read() throws IOException {
		if (volumeNumber == -1) {				// read the data or resource fork header
			volumeNumber = dataStream.readByte();
			rleCharacter = dataStream.readByte();
			lzwStream = new LzwInputStream(new BitInputStream(dataStream, 9));
			rleStream = new RleInputStream(dataStream, rleCharacter);
			lzwRleStream = new RleInputStream(lzwStream);
		}
		if (bytesLeftInChunk == 0) {		// read the chunk header
			bytesLeftInChunk = 4096;		// NuFX always reads 4096 bytes
			lzwStream.clearData();			// Allow the LZW stream to do a little housekeeping
			int word = dataStream.readWord();
			int length = word & 0x7fff;
			int lzwFlag = word & 0x8000;
			if (lzwFlag == 0) {				// We clear dictionary whenever a non-LZW chunk is encountered
				lzwStream.clearDictionary();
			} else {
				dataStream.readWord();		// At this time, I just throw away the total bytes in this chunk...
			}
			int flag = (lzwFlag == 0 ? 0 : 1) + (length == 4096 ? 0 : 2);
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
	
	// GENERATED CODE

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
