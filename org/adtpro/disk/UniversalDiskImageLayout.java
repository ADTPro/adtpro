/*
 * AppleCommander - An Apple ][ image utility.
 * Copyright (C) 2003 by Robert Greene
 * robgreene at users.sourceforge.net
 *
 * This program is free software; you can redistribute it and/or modify it 
 * under the terms of the GNU General Public License as published by the 
 * Free Software Foundation; either version 2 of the License, or (at your 
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but 
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
 * for more details.
 *
 * You should have received a copy of the GNU General Public License along 
 * with this program; if not, write to the Free Software Foundation, Inc., 
 * 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */
package org.adtpro.disk;

/**
 * Manages the physical 2IMG disk.
 * @author Rob Greene (RobGreene@users.sourceforge.net)
 */
public class UniversalDiskImageLayout extends ByteArrayImageLayout {
	/**
	 * This is the 2IMG offset.
	 */
	public static final int OFFSET = 0x40;
	
	/**
	 * Construct a UniversalDiskImageLayout.
	 */
	public UniversalDiskImageLayout(byte[] diskImage) {
		super(diskImage);
	}

	/**
	 * Construct a UniversalDiskImageLayout.
	 */
	public UniversalDiskImageLayout(byte[] diskImage, boolean changed) {
		super(diskImage, changed);
	}

	/**
	 * Construct a UniversalDiskImageLayout.
	 */
	public UniversalDiskImageLayout(int size) {
		super(size + OFFSET);
	}

	/**
	 * Extract a portion of the disk image.
	 */
	public byte[] readBytes(int start, int length) {
		return super.readBytes(start + OFFSET, length);
	}
	
	/**
	 * Write data to the disk image.
	 */
	public void writeBytes(int start, byte[] bytes) {
		super.writeBytes(start + OFFSET, bytes);
	}

}
