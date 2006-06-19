package org.adtpro.disk;

/*
 * Copyright (C) 2002 by Robert Greene
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

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.zip.GZIPInputStream;
import java.util.zip.GZIPOutputStream;

import org.adtpro.utilities.StreamUtil;

/**
 * Abstract representation of an Apple2 disk (floppy, 800k, hard disk).
 * <p>
 * Date created: Oct 3, 2002 10:59:47 PM
 * 
 * @author Rob Greene
 */
public class Disk
{
  /**
   * Specifies a filter to be used in determining filetypes which are supported.
   * This works from a file extension, so it may or may not apply to the
   * Macintosh.
   */

  public static final int BLOCK_SIZE = 512;

  public static final int SECTOR_SIZE = 256;

  public static final int PRODOS_BLOCKS_ON_140KB_DISK = 280;

  public static final int DOS33_SECTORS_ON_140KB_DISK = 560;

  public static final int APPLE_140KB_DISK = 143360;

  public static final int APPLE_140KB_NIBBLE_DISK = 232960;

  public static final int APPLE_800KB_DISK = 819200;

  public static final int APPLE_800KB_2IMG_DISK = APPLE_800KB_DISK + 0x40;

  public static final int APPLE_5MB_HARDDISK = 5242880;

  public static final int APPLE_10MB_HARDDISK = 10485760;

  public static final int APPLE_20MB_HARDDISK = 20971520;

  public static final int APPLE_32MB_HARDDISK = 33553920; // short one block!

  // private TextBundle textBundle = StorageBundle.getInstance();

  private String filename;

  private boolean newImage = false;

  private ByteArrayImageLayout diskImageManager;

  private ImageOrder imageOrder;

  /**
   * Constructor for a Disk - used only to generate FilenameFilter objects.
   */
  private Disk()
  {}

  /**
   * Construct a Disk with the given byte array.
   */
  protected Disk(String filename, ImageOrder imageOrder)
  {
    this.imageOrder = imageOrder;
    this.filename = filename;
    this.newImage = true;
  }

  /**
   * Construct a Disk and load the specified file. Read in the entire contents
   * of the file.
   */
  public Disk(String filename) throws IOException
  {
    this.filename = filename;
    File file = new File(filename);
    InputStream input = new FileInputStream(file);
    if (isCompressed())
    {
      input = new GZIPInputStream(input);
    }
    int diskSize = (int) file.length();
    ByteArrayOutputStream diskImageByteArray = new ByteArrayOutputStream(diskSize);
    StreamUtil.copy(input, diskImageByteArray);
    byte[] diskImage = diskImageByteArray.toByteArray();
    int offset = UniversalDiskImageLayout.OFFSET;
    if (diskImage.length == APPLE_800KB_DISK + offset || diskImage.length == APPLE_5MB_HARDDISK + offset
        || diskImage.length == APPLE_10MB_HARDDISK + offset || diskImage.length == APPLE_20MB_HARDDISK + offset
        || diskImage.length == APPLE_32MB_HARDDISK + offset)
    {
      diskImageManager = new UniversalDiskImageLayout(diskImage);
    }
    else
    {
      diskImageManager = new ByteArrayImageLayout(diskImage);
    }
    if (isProdosOrder())
    {
      imageOrder = new ProdosOrder(diskImageManager);
    }
    else
      if (isDosOrder())
      {
        imageOrder = new DosOrder(diskImageManager);
      }
      else
        if (isNibbleOrder())
        {
          imageOrder = new NibbleOrder(diskImageManager);
        }
  }

  /**
   * Save a Disk image to its file.
   */
  public void save() throws IOException
  {
    File file = new File(getFilename());
    if (!file.exists())
    {
      file.createNewFile();
    }
    OutputStream output = new FileOutputStream(file);
    if (isCompressed())
    {
      output = new GZIPOutputStream(output);
    }
    output.write(getDiskImageManager().getDiskImage());
    output.close();
    getDiskImageManager().setChanged(false);
    newImage = false;
  }

  /**
   * Save a Disk image as a new/different file.
   */
  public void saveAs(String filename) throws IOException
  {
    this.filename = filename;
    save();
  }

  /**
   * Returns the diskImage.
   * 
   * @return byte[]
   */
  public ByteArrayImageLayout getDiskImageManager()
  {
    if (imageOrder != null) { return imageOrder.getDiskImageManager(); }
    return diskImageManager;
  }

  /**
   * Returns the filename.
   * 
   * @return String
   */
  public String getFilename()
  {
    return filename;
  }

  /**
   * Sets the filename.
   */
  public void setFilename(String filename)
  {
    this.filename = filename;
  }

  /**
   * Indicate if this disk is GZIP compressed.
   */
  public boolean isCompressed()
  {
    return filename.toLowerCase().endsWith(".gz"); //$NON-NLS-1$
  }

  /**
   * Indicate if this disk is ProDOS ordered (beginning with block 0).
   */
  public boolean isProdosOrder()
  {
    return filename.toLowerCase().endsWith(".po") //$NON-NLS-1$
        || filename.toLowerCase().endsWith(".po.gz") //$NON-NLS-1$
        || is2ImgOrder() || filename.toLowerCase().endsWith(".hdv") //$NON-NLS-1$
        || getPhysicalSize() >= APPLE_800KB_2IMG_DISK;
  }

  /**
   * Indicate if this disk is DOS ordered (T0,S0 - T35,S15).
   */
  public boolean isDosOrder()
  {
    return filename.toLowerCase().endsWith(".do") //$NON-NLS-1$
        || filename.toLowerCase().endsWith(".do.gz") //$NON-NLS-1$
        || filename.toLowerCase().endsWith(".dsk") //$NON-NLS-1$
        || filename.toLowerCase().endsWith(".dsk.gz"); //$NON-NLS-1$
  }

  /**
   * Indicate if this disk is a 2IMG disk. This is ProDOS ordered, but with a
   * header on the disk.
   */
  public boolean is2ImgOrder()
  {
    return filename.toLowerCase().endsWith(".2img") //$NON-NLS-1$
        || filename.toLowerCase().endsWith(".2img.gz") //$NON-NLS-1$
        || filename.toLowerCase().endsWith(".2mg") //$NON-NLS-1$
        || filename.toLowerCase().endsWith(".2mg.gz"); //$NON-NLS-1$
  }

  /**
   * Indicate if this disk is a nibbilized disk..
   */
  public boolean isNibbleOrder()
  {
    return filename.toLowerCase().endsWith(".nib") //$NON-NLS-1$
        || filename.toLowerCase().endsWith(".nib.gz"); //$NON-NLS-1$
  }

  /**
   * Identify the size of this disk.
   */
  public int getPhysicalSize()
  {
    if (getDiskImageManager() != null) { return getDiskImageManager().getPhysicalSize(); }
    return getImageOrder().getPhysicalSize();
  }

  /**
   * Read the block from the disk image.
   */
  public byte[] readBlock(int block)
  {
    return imageOrder.readBlock(block);
  }

  /**
   * Write the block to the disk image.
   */
  public void writeBlock(int block, byte[] data)
  {
    imageOrder.writeBlock(block, data);
  }

  /**
   * Retrieve the specified sector.
   */
  public byte[] readSector(int track, int sector) throws IllegalArgumentException
  {
    return imageOrder.readSector(track, sector);
  }

  /**
   * Write the specified sector.
   */
  public void writeSector(int track, int sector, byte[] bytes) throws IllegalArgumentException
  {
    imageOrder.writeSector(track, sector, bytes);
  }

  /**
   * Answers true if this disk image is within the expected 140K disk size. Can
   * vary if a header has been applied or if this is a nibblized disk image.
   */
  protected boolean is140KbDisk()
  {
    return getPhysicalSize() >= APPLE_140KB_DISK && getPhysicalSize() <= APPLE_140KB_NIBBLE_DISK;
  }

  /**
   * Answers true if this disk image is within the expected 800K disk size. Can
   * vary if a 2IMG header has been applied.
   */
  protected boolean is800KbDisk()
  {
    return getPhysicalSize() >= APPLE_800KB_DISK && getPhysicalSize() <= APPLE_800KB_2IMG_DISK;
  }

  /**
   * Indicates if the disk has changed. Triggered when data is written and
   * cleared when data is saved.
   */
  public boolean hasChanged()
  {
    return getDiskImageManager().hasChanged();
  }

  /**
   * Indicates if the disk image is new. This can be used for Save As
   * processing.
   */
  public boolean isNewImage()
  {
    return newImage;
  }

  /**
   * Answer with the phyiscal ordering of the disk.
   */
  public ImageOrder getImageOrder()
  {
    return imageOrder;
  }

  /**
   * Set the physical ordering of the disk.
   */
  protected void setImageOrder(ImageOrder imageOrder)
  {
    this.imageOrder = imageOrder;
  }
}
