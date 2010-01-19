package org.adtpro.shrinkit;

/**
 * Define and decode the thread_format field.
 * @author robgreene@users.sourceforge.net
 */
public enum ThreadFormat {
	UNCOMPRESSED(0x0000), HUFFMAN_SQUEEZE(0x0001), DYNAMIC_LZW1(0x0002), DYNAMIC_LZW2(0x0003), 
	UNIX_12BIT_COMPRESS(0x0004), UNIX_16BIT_COMPRESS(0x0005);
	
	/** Associate the hex codes with the enum */
	private int threadFormat;
	
	private ThreadFormat(int threadFormat) {
		this.threadFormat = threadFormat;
	}
	
	public int getThreadFormat() {
		return threadFormat;
	}

	/**
	 * Find the ThreadFormat.
	 * @throws IllegalArgumentException if the thread_format is unknown
	 */
	public static ThreadFormat find(int threadFormat) {
		for (ThreadFormat f : values()) {
			if (threadFormat == f.getThreadFormat()) return f;
		}
		throw new IllegalArgumentException("Unknown thread_format of " + threadFormat);
	}
}
