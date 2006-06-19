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
 * Supports disk images stored in DOS physical order.
 * <p>
 * 
 * @author Rob Greene (RobGreene@users.sourceforge.net)
 */
public class DosOrder extends ImageOrder
{
  // private TextBundle textBundle = StorageBundle.getInstance();
  /**
   * Construct a DosOrder.
   */
  public DosOrder(ByteArrayImageLayout diskImageManager)
  {
    super(diskImageManager);
  }

  /**
   * Indicates that this device is block ordered.
   */
  public boolean isBlockDevice()
  {
    return false;
  }

  /**
   * Indicates that this device is track and sector ordered.
   */
  public boolean isTrackAndSectorDevice()
  {
    return true;
  }

  /**
   * Retrieve the specified sector.
   */
  public byte[] readSector(int track, int sector) throws IllegalArgumentException
  {
    return readBytes(getOffset(track, sector), Disk.SECTOR_SIZE);
  }

  /**
   * Write the specified sector.
   */
  public void writeSector(int track, int sector, byte[] bytes) throws IllegalArgumentException
  {
    writeBytes(getOffset(track, sector), bytes);
  }

  /**
   * Compute the track and sector offset into the disk image. This takes into
   * account what type of format is being dealt with.
   */
  protected int getOffset(int track, int sector) throws IllegalArgumentException
  {
    if (!isSizeApprox(Disk.APPLE_140KB_DISK) && !isSizeApprox(Disk.APPLE_800KB_DISK)
        && !isSizeApprox(Disk.APPLE_800KB_2IMG_DISK) && track != 0 && sector != 0)
    { // HACK: Allows boot sector writing
    // throw new IllegalArgumentException(
    // textBundle.get("DosOrder.UnrecognizedFormatError")); //$NON-NLS-1$
    }
    int offset = (track * getSectorsPerTrack() + sector) * Disk.SECTOR_SIZE;
    if (offset > getPhysicalSize())
    {
      // throw new IllegalArgumentException(
      // textBundle.format("DosOrder.InvalidSizeError", //$NON-NLS-1$
      // track, sector));
    }
    return offset;
  }

  /**
   * Read the block from the disk image. Note: Defined in terms of reading
   * sectors.
   */
  public byte[] readBlock(int block)
  {
    int track = block / 8;
    int sectorIndex = block % 8;
    int[] sectorMapping1 =
    { 0, 13, 11, 9, 7, 5, 3, 1 };
    int[] sectorMapping2 =
    { 14, 12, 10, 8, 6, 4, 2, 15 };
    int sector1 = sectorMapping1[sectorIndex];
    int sector2 = sectorMapping2[sectorIndex];
    byte[] blockData = new byte[Disk.BLOCK_SIZE];
    System.arraycopy(readSector(track, sector1), 0, blockData, 0, Disk.SECTOR_SIZE);
    System.arraycopy(readSector(track, sector2), 0, blockData, Disk.SECTOR_SIZE, Disk.SECTOR_SIZE);
    return blockData;
  }

  /**
   * Write the block to the disk image. Note: Defined in terms of reading
   * sectors.
   */
  public void writeBlock(int block, byte[] data)
  {
    int track = block / 8;
    int sectorIndex = block % 8;
    int[] sectorMapping1 =
    { 0, 13, 11, 9, 7, 5, 3, 1 };
    int[] sectorMapping2 =
    { 14, 12, 10, 8, 6, 4, 2, 15 };
    int sector1 = sectorMapping1[sectorIndex];
    int sector2 = sectorMapping2[sectorIndex];
    byte[] sectorData = new byte[Disk.SECTOR_SIZE];
    System.arraycopy(data, 0, sectorData, 0, Disk.SECTOR_SIZE);
    writeSector(track, sector1, sectorData);
    System.arraycopy(data, Disk.SECTOR_SIZE, sectorData, 0, Disk.SECTOR_SIZE);
    writeSector(track, sector2, sectorData);
  }
}
