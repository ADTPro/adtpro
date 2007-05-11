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
 * Manages the layout of the physical disk. This hides implementation details,
 * such as if the disk is in 2IMG order.
 * <p>
 * 
 * @author Rob Greene (RobGreene@users.sourceforge.net)
 */
public class ByteArrayImageLayout
{
  /**
   * This is the physical copy of the disk image which a particular
   * implementation of ImageOrder will interpret.
   */
  private byte[] diskImage;

  /**
   * Indicates if the disk image has changed.
   */
  private boolean changed;

  /**
   * Construct a ByteArrayImageLayout.
   */
  public ByteArrayImageLayout(byte[] diskImage)
  {
    setDiskImage(diskImage);
  }

  /**
   * Construct a ByteArrayImageLayout.
   */
  public ByteArrayImageLayout(byte[] diskImage, boolean changed)
  {
    setDiskImage(diskImage);
    this.changed = changed;
  }

  /**
   * Construct a ByteArrayImageLayout.
   */
  public ByteArrayImageLayout(int size)
  {
    diskImage = new byte[size];
    changed = true;
  }

  /**
   * Get the physical disk image.
   */
  public byte[] getDiskImage()
  {
    return diskImage;
  }

  /**
   * Set the physical disk image.
   */
  public void setDiskImage(byte[] diskImage)
  {
    this.diskImage = diskImage;
    changed = true;
  }

  /**
   * Answer with the physical size of this disk volume.
   */
  public int getPhysicalSize()
  {
    return (diskImage != null) ? diskImage.length : 0;
  }

  /**
   * Extract a portion of the disk image.
   */
  public byte[] readBytes(int start, int length)
  {
    if ((start + length) > diskImage.length)
      throw new IllegalArgumentException();
    byte[] buffer = new byte[length];
    System.arraycopy(diskImage, start, buffer, 0, length);
    return buffer;
  }

  /**
   * Write data to the disk image.
   */
  public void writeBytes(int start, byte[] bytes)
  {
    changed = true;
    System.arraycopy(bytes, 0, diskImage, start, bytes.length);
  }

  /**
   * Indicates if the disk has changed. Triggered when data is written and
   * cleared when data is saved.
   */
  public boolean hasChanged()
  {
    return changed;
  }

  /**
   * Set the changed indicator.
   */
  public void setChanged(boolean changed)
  {
    this.changed = changed;
  }
}
