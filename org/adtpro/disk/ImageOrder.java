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
 * Manages the interface between the physical disk image order and the logical
 * operating system specific order. These management objects are intended to be
 * hidden by Disk itself, although the ImageOrder may be changed (overridden).
 * <p>
 * To implement this class, over-ride the block-oriented methods (readBlock,
 * writeBlock) or the track and sector-oriented methods (readSector,
 * writeSector). Ensure that isBlockDevice or isTrackAndSectorDevice is set
 * appropriately.
 * <p>
 * Note that a block is generally assumed to be an Apple ProDOS (or Apple
 * Pascal) formatted volume where a block is 512 bytes. The track and sector
 * device is generally a 140K 5.25" disk, although it may be an 800K 3.5" disk
 * with two 400K DOS volumes. In either case, the sector size will be 256 bytes.
 * <p>
 * At this time, the RDOS block of 256 bytes is managed by the RdosFormatDisk,
 * and the 1024 byte CP/M block is managed by the CpmFormatDisk (the CP/M sector
 * of 128 bytes is largely ignored).
 * <p>
 * Design note: The physical order could alternatively be implemented with a
 * BlockPhysicalOrder structure which includes ProdosOrder and a Track and
 * Sector adapter, as well as a TrackAndSectorPhysicalOrder which includes a
 * NibblePhysicalOrder and DosOrder as well as a Block adapter class. This way,
 * Disk contains two separate classes (block as well as a track/sector) to
 * manage the disk.
 * <p>
 * 
 * @author Rob Greene (RobGreene@users.sourceforge.net)
 */
public abstract class ImageOrder
{
  /**
   * This is the physical copy of the disk image which a particular
   * implementation of ImageOrder will interpret.
   */
  private ByteArrayImageLayout diskImageManager;

  /**
   * Construct a ImageOrder.
   */
  public ImageOrder(ByteArrayImageLayout diskImageManager)
  {
    setDiskImageManager(diskImageManager);
  }

  /**
   * Get the physical disk image.
   */
  public ByteArrayImageLayout getDiskImageManager()
  {
    return diskImageManager;
  }

  /**
   * Answer with the physical size of this disk volume.
   */
  public int getPhysicalSize()
  {
    return diskImageManager.getPhysicalSize();
  }

  /**
   * Set the physical disk image.
   */
  public void setDiskImageManager(ByteArrayImageLayout diskImageManager)
  {
    this.diskImageManager = diskImageManager;
  }

  /**
   * Extract a portion of the disk image.
   */
  public byte[] readBytes(int start, int length)
  {
    return diskImageManager.readBytes(start, length);
  }

  /**
   * Write data to the disk image.
   */
  public void writeBytes(int start, byte[] bytes)
  {
    diskImageManager.writeBytes(start, bytes);
  }

  /**
   * Answer with the number of blocks on this device.
   */
  public int getBlocksOnDevice()
  {
    return getPhysicalSize() / Disk.BLOCK_SIZE;
  }

  /**
   * Read the block from the disk image.
   */
  public abstract byte[] readBlock(int block);

  /**
   * Write the block to the disk image.
   */
  public abstract void writeBlock(int block, byte[] data);

  /**
   * Indicates that this device is block ordered.
   */
  public abstract boolean isBlockDevice();

  /**
   * Indicates that this device is track and sector ordered.
   */
  public abstract boolean isTrackAndSectorDevice();

  /**
   * Answer with the number of tracks on this device.
   */
  public int getTracksPerDisk()
  {
    return getPhysicalSize() / (getSectorsPerTrack() * Disk.SECTOR_SIZE);
  }

  /**
   * Answer with the number of sectors per track on this device.
   */
  public int getSectorsPerTrack()
  {
    if (isSizeApprox(Disk.APPLE_800KB_DISK) || isSizeApprox(Disk.APPLE_800KB_2IMG_DISK)) { return 32; }
    return 16;
  }

  /**
   * Retrieve the specified sector.
   */
  public abstract byte[] readSector(int track, int sector) throws IllegalArgumentException;

  /**
   * Write the specified sector.
   */
  public abstract void writeSector(int track, int sector, byte[] bytes) throws IllegalArgumentException;

  /**
   * Indicates if the physical disk is approximately this size. Currently
   * hardcoded to allow up to 10 extra bytes at the end of a disk image. Must be
   * at least the requested size!
   */
  public boolean isSizeApprox(int value)
  {
    return getPhysicalSize() >= value && getPhysicalSize() <= value + 10;
  }

  /**
   * Format the media. Formatting at the ImageOrder level deals with low-level
   * issues. A typical ordering just needs to have the image "wiped," and that
   * is the assumed implementation. However, specialized orders - such as a
   * nibbilized disk - need to lay down track and sector markers.
   */
  public void format()
  {
    int size = diskImageManager.getPhysicalSize();
    diskImageManager.setDiskImage(new byte[size]);
  }

  /**
   * Answer with the total number of sectors in a disk. This is used to size the
   * disk and compare sizes instead of using byte counts which can differ.
   */
  public int getSectorsPerDisk()
  {
    return getTracksPerDisk() * getSectorsPerTrack();
  }
}
