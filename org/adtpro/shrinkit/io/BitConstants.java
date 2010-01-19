package org.adtpro.shrinkit.io;

/**
 * This interface allows bit-related constants to be shared among
 * classes.
 *  
 * @author robgreene@users.sourceforge.net
 */
public interface BitConstants {
	/** 
	 * The low-tech way to compute a bit mask.  Allowing up to 16 bits at this time. 
	 */
    public static final int[] BIT_MASKS = new int[] { 
            0x0000, 0x0001, 0x0003, 0x0007, 0x000f, 
            0x001f, 0x003f, 0x007f, 0x00ff, 0x01ff, 
            0x03ff, 0x07ff, 0x0fff, 0x1fff, 0x3fff, 
            0x7fff, 0xffff 
        }; 
}
