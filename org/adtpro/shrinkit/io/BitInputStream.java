package org.adtpro.shrinkit.io;

import java.io.IOException;
import java.io.InputStream;

/**
 * The BitInputStream allows varying bit sizes to be pulled out of the
 * wrapped InputStream.  This is useful for LZW type compression algorithms
 * where 9-12 bit codes are used instead of the 8-bit byte.
 * <p>
 * Warning: The <code>read(byte[])</code> and <code>read(byte[], int, int)</code>
 * methods of <code>InputStream</code> will not work appropriately with any
 * bit size &gt; 8 bits. 
 *  
 * @author robgreene@users.sourceforge.net
 */
public class BitInputStream extends InputStream implements BitConstants {
    /** Our source of data. */
    private InputStream is;
    /** The number of bits to read for a request.  This can be adjusted dynamically. */
    private int requestedNumberOfBits; 
    /** The current bit mask to use when returning a <code>read()</code> request. */ 
    private int bitMask; 
    /** The buffer containing our bits.  An int allows 32 bits which should cover up to a 24 bit read if my math is correct.  :-) */
    private int data = 0;
    /** Number of bits remaining in our buffer */
    private int bitsOfData = 0; 
    
    /**
     * Create a BitInputStream wrapping the given <code>InputStream</code>
     * and reading the number of bits specified.
     */
    public BitInputStream(InputStream is, int startingNumberOfBits) { 
        this.is = is; 
        setRequestedNumberOfBits(startingNumberOfBits); 
    } 
    
    /**
     * Set the number of bits to be read with each call to <code>read()</code>.
     */
    public void setRequestedNumberOfBits(int numberOfBits) { 
        this.requestedNumberOfBits = numberOfBits; 
        this.bitMask = BIT_MASKS[numberOfBits]; 
    } 
    
    /**
     * Increase the requested number of bits by one.
     * This is the general usage and prevents client from needing to track
     * the requested number of bits or from making various method calls.
     */
    public void increaseRequestedNumberOfBits() {
    	setRequestedNumberOfBits(requestedNumberOfBits + 1);
    }
    
    /**
     * Answer with the current bit mask for the current bit size.
     */
    public int getBitMask() {
    	return bitMask;
    }
    
    /**
     * Read a number of bits off of the wrapped InputStream.
     */
    public int read() throws IOException { 
        while (bitsOfData < requestedNumberOfBits) { 
            int b = is.read();
            if (b == -1) return b;
            if (bitsOfData > 0) { 
                b <<= bitsOfData;	// We're placing b on the high-bit side 
            } 
            data|= b; 
            bitsOfData+= 8; 
        } 
        int b = data & bitMask; 
        data >>= requestedNumberOfBits; 
        bitsOfData-= requestedNumberOfBits; 
        return b; 
    }
    
    /**
     * When shifting from buffer to buffer, the input stream also should be reset.
     * This allows the "left over" bits to be cleared.
     */
    public void clearRemainingBitsOfData() {
    	this.bitsOfData = 0;
    	this.data = 0;
    }
} 

