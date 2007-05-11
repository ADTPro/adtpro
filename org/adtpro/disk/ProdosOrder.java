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
 * Supports disk images stored in ProDOS physical order.
 * <p>
 * 
 * @author Rob Greene (RobGreene@users.sourceforge.net)
 */
public class ProdosOrder extends ImageOrder
{
  /**
   * This table contains the block offset for a particular DOS sector.
   */
  private static final int[] blockInterleave =
  { 0, 7, 6, 6, 5, 5, 4, 4, 3, 3, 2, 2, 1, 1, 0, 7 };

  /**
   * Defines the location within a block in which the DOS sector resides. (0 =
   * 0-255 and 1 = 256-511.)
   */
  private static final int[] blockOffsets =
  { 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1 };

  /**
   * Construct a ProdosOrder.
   */
  public ProdosOrder(ByteArrayImageLayout diskImageManager)
  {
    super(diskImageManager);
  }

  /**
   * Indicates that this device is block ordered.
   */
  public boolean isBlockDevice()
  {
    return true;
  }

  /**
   * Indicates that this device is track and sector ordered.
   */
  public boolean isTrackAndSectorDevice()
  {
    return false;
  }

  /**
   * Read the block from the disk image. Note: Defined in terms of reading
   * sectors.
   */
  public byte[] readBlock(int block)
  {
    return readBytes(block * Disk.BLOCK_SIZE, Disk.BLOCK_SIZE);
  }

  /**
   * Write the block to the disk image. Note: Defined in terms of reading
   * sectors.
   */
  public void writeBlock(int block, byte[] data)
  {
    writeBytes(block * Disk.BLOCK_SIZE, data);
  }

  /**
   * Retrieve the specified sector.
   */
  public byte[] readSector(int track, int sector) throws IllegalArgumentException
  {
    if (sector >= blockInterleave.length)
      throw new IllegalArgumentException();
    int block = track * 8 + blockInterleave[sector];
    byte[] blockData = readBlock(block);
    int offset = blockOffsets[sector];
    byte[] sectorData = new byte[Disk.SECTOR_SIZE];
    System.arraycopy(blockData, offset * Disk.SECTOR_SIZE, sectorData, 0, Disk.SECTOR_SIZE);
    return sectorData;
  }

  /**
   * Write the specified sector.
   */
  public void writeSector(int track, int sector, byte[] bytes) throws IllegalArgumentException
  {
    int block = track * 8 + blockInterleave[sector];
    byte[] blockData = readBlock(block);
    int offset = blockOffsets[sector];
    System.arraycopy(bytes, 0, blockData, offset * Disk.SECTOR_SIZE, bytes.length);
    writeBlock(block, blockData);
  }
}
