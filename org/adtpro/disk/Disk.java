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

import org.adtpro.utilities.Log;
import org.adtpro.utilities.StreamUtil;
import org.adtpro.utilities.UnsignedByte;

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
  public Disk(String filename, ImageOrder imageOrder)
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
    this(filename, false);
  }

  /**
   * Construct a Disk and load the specified file. Read in the entire contents
   * of the file.
   */
  public Disk(String filename, boolean forceProDosOrder) throws IOException
  {
    Log.println(false, "Disk contructor looking for file named " + filename + ".");
    this.filename = filename;
    File file = new File(filename);
    InputStream input = new FileInputStream(file);
    if (isCompressed())
    {
      Log.println(false, "Disk contructor found a compressed image.");
      input = new GZIPInputStream(input);
    }
    int diskSize = (int) file.length();
    ByteArrayOutputStream diskImageByteArray = new ByteArrayOutputStream(diskSize);
    StreamUtil.copy(input, diskImageByteArray);
    byte[] diskImage = diskImageByteArray.toByteArray();
    boolean is2img = false;
    /* Does it have the 2IMG header? */
    if ((diskImage[00] == 0x32) && (diskImage[01] == 0x49) && (diskImage[02] == 0x4D) && (diskImage[03]) == 0x47) is2img = true;
    int offset = UniversalDiskImageLayout.OFFSET;
    if (is2img == true || diskImage.length == APPLE_800KB_DISK + offset
        || diskImage.length == APPLE_5MB_HARDDISK + offset || diskImage.length == APPLE_10MB_HARDDISK + offset
        || diskImage.length == APPLE_20MB_HARDDISK + offset || diskImage.length == APPLE_32MB_HARDDISK + offset)
    {
      Log.println(false, "Disk contructor found a 2img header.");
      diskImageManager = new UniversalDiskImageLayout(diskImage);
    }
    else
    {
      Log.println(false, "Disk contructor found unadorned disk image data.");
      diskImageManager = new ByteArrayImageLayout(diskImage);
    }

    /*
     * First step: start physical disk orders and look for viable filesystems.
     */
    int rc = -1;
    imageOrder = new ProdosOrder(diskImageManager);
    if (!forceProDosOrder)
    {
      rc = testImageOrder();
      if (rc != 0)
      {
        Log.println(false, "Disk contructor didn't find formatted data in ProDOS order; trying DOS order.");
        imageOrder = new DosOrder(diskImageManager);
        rc = testImageOrder();
        if (rc != 0)
        {
          /*
           * Couldn't find anything recognizable. Second step: start testing
           * filenames.
           */
          if (isProdosOrder() || is2ImgOrder())
          {
            imageOrder = new ProdosOrder(diskImageManager);
            Log.println(false, "Disk constructor found a ProdosOrder image (by name).");
          }
          else
            if (isDosOrder())
            {
              imageOrder = new DosOrder(diskImageManager);
              Log.println(false, "Disk constructor found a DosOrder image (by name).");
            }
            else
              if (isNibbleOrder())
              {
                imageOrder = new NibbleOrder(diskImageManager);
                Log.println(false, "Disk constructor found a NibbleOrder image (by name).");
              }
              else
              {
                imageOrder = new ProdosOrder(diskImageManager);
                Log.println(false, "Disk constructor couldn't find much of anything; defaulting to ProdosOrder image.");
              }
        }
        else
          Log.println(false, "Disk constructor found a DosOrder image.");
      }
      else
        Log.println(false, "Disk constructor found a ProdosOrder image.");
    }
  }

  /**
   * Test the image order to see if we can recognize a filesystem. Returns: 0 on
   * recognition; -1 on failure.
   */
  public int testImageOrder()
  {
    int rc = -1;
    if ((isProdosFormat()) || (isDosFormat()) || (isCpmFormat()) || (isUniDosFormat()) || (isPascalFormat())
        || (isOzDosFormat())) rc = 0;
    return rc;
  }

  /**
   * Save a Disk image to its file.
   */
  public void save() throws IOException
  {
    File file = new File(getFilename());
    Log.println(false, "Disk.save() saving filename " + filename + " as order " + getImageOrder());
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
   * Test the disk format to see if this is a ProDOS formatted disk.
   */
  public boolean isProdosFormat()
  {
    Log.println(false, "Disk.isProdosFormat() testing for ProDOS format.");
    byte[] prodosVolumeDirectory = readBlock(2);
    int volDirEntryLength = UnsignedByte.intValue(prodosVolumeDirectory[23]);
    int volDirEntriesPerBlock = UnsignedByte.intValue(prodosVolumeDirectory[24]);
    boolean retval = ((prodosVolumeDirectory[0] == 0 && prodosVolumeDirectory[1] == 0)
        && ((prodosVolumeDirectory[4] & 0xf0) == 0xf0) && ((prodosVolumeDirectory[4] & 0x0f) != 0) && ((volDirEntryLength
        * volDirEntriesPerBlock <= 512)));

    Log.println(false, "Disk.isProdosFormat() returning " + retval + ".");
    return retval;
  }

  /**
   * Test the disk format to see if this is a DOS 3.3 formatted disk. This is a
   * little nasty - since 800KB and 140KB images have different characteristics.
   * This just tests 140KB images.
   */
  public boolean isDosFormat()
  {
    Log.println(false, "Disk.isDosFormat() testing for DOS format.");
    boolean retval = true;
    int foundGood = 0;
    if (!is140KbDisk()) return false;
    byte[] vtoc = readSector(17, 0);
    int catTrack = UnsignedByte.intValue(vtoc[0x01]);
    int catSect = UnsignedByte.intValue(vtoc[0x02]);
    int numTracks = UnsignedByte.intValue(vtoc[0x34]);
    int numSectors = UnsignedByte.intValue(vtoc[0x35]);
    if ((imageOrder.isSizeApprox(APPLE_140KB_DISK) || imageOrder.isSizeApprox(APPLE_140KB_NIBBLE_DISK))
        && vtoc[0x01] == 17 // expect catalog to start on track 17
        // can vary && vtoc[0x02] == 15 // expect catalog to start on sector 15
        // (140KB disk only!)
        && vtoc[0x27] == 122 // expect 122 tract/sector pairs per sector
        && vtoc[0x34] == 35 // expect 35 tracks per disk (140KB disk only!)
        && vtoc[0x35] == 16 && (catTrack < numTracks && catSect < numSectors)) foundGood++;

    int iterations = 0;
    byte[] sctBuf;
    while (catTrack != 0 && catSect != 0 && iterations < 32 /* max sectors */)
    {
      try
      {
        sctBuf = readSector(catTrack, catSect);
        int tmpTrack = UnsignedByte.intValue(sctBuf[1]);
        int tmpSect = UnsignedByte.intValue(sctBuf[2]) + 1;
        if (catTrack == tmpTrack && catSect == sctBuf[2] + 1)
        {
          foundGood++;
        }
        else
          if (catTrack == tmpTrack && catSect == tmpSect)
          {
            Log.println(false, "Disk.isDosFormat() detected a self-reference on catalog (" + tmpTrack + "," + tmpSect);
            break;
          }
        catTrack = UnsignedByte.intValue(sctBuf[1]);
        catSect = UnsignedByte.intValue(sctBuf[2]);
      }
      catch (IllegalArgumentException e)
      {
        foundGood = 0;
        iterations = 33;
        break;
      }
      iterations++;
    }
    if (iterations >= 32 /* max sectors */) retval = false;
    else
    {
      if (foundGood < 3) retval = false;
    }
    Log.println(false, "Disk.isDosFormat() returning " + retval + ".");
    return (retval);
  }

  /**
   * Test the disk format to see if this is a UniDOS formatted disk. UniDOS
   * creates two logical disks on an 800KB physical disk. The first logical disk
   * takes up the first 400KB and the second logical disk takes up the second
   * 400KB.
   */
  public boolean isUniDosFormat()
  {
    Log.println(false, "Disk.isUniDosFormat() testing for UniDOS format.");
    if (!is800KbDisk()) return false;
    byte[] vtoc1 = readSector(17, 0); // logical disk #1
    byte[] vtoc2 = readSector(67, 0); // logical disk #2
    boolean retval =
    // LOGICAL DISK #1
    vtoc1[0x01] == 17 // expect catalog to start on track 17
        && vtoc1[0x02] == 31 // expect catalog to start on sector 31
        && vtoc1[0x27] == 122 // expect 122 tract/sector pairs per sector
        && vtoc1[0x34] == 50 // expect 50 tracks per disk
        && vtoc1[0x35] == 32 // expect 32 sectors per disk
        && vtoc1[0x36] == 0 // bytes per sector (low byte)
        && vtoc1[0x37] == 1 // bytes per sector (high byte)
        // LOGICAL DISK #2
        && vtoc2[0x01] == 17 // expect catalog to start on track 17
        && vtoc2[0x02] == 31 // expect catalog to start on sector 31
        && vtoc2[0x27] == 122 // expect 122 tract/sector pairs per sector
        && vtoc2[0x34] == 50 // expect 50 tracks per disk
        && vtoc2[0x35] == 32 // expect 32 sectors per disk
        && vtoc2[0x36] == 0 // bytes per sector (low byte)
        && vtoc2[0x37] == 1; // bytes per sector (high byte)
    Log.println(false, "Disk.isUniDosFormat() returning " + retval + ".");
    return retval;
  }

  /**
   * Test the disk format to see if this is a OzDOS formatted disk. OzDOS
   * creates two logical disks on an 800KB physical disk. The first logical disk
   * takes the first half of each block and the second logical disk takes the
   * second half of each block.
   */
  public boolean isOzDosFormat()
  {
    Log.println(false, "Disk.isOzDosFormat() testing for OzDOS format.");
    if (!is800KbDisk()) return false;
    byte[] vtoc = readBlock(544); // contains BOTH VTOCs!
    boolean retval =
    // LOGICAL DISK #1
    vtoc[0x001] == 17 // expect catalog to start on track 17
        && vtoc[0x002] == 31 // expect catalog to start on sector 31
        && vtoc[0x027] == 122 // expect 122 tract/sector pairs per sector
        && vtoc[0x034] == 50 // expect 50 tracks per disk
        && vtoc[0x035] == 32 // expect 32 sectors per disk
        && vtoc[0x036] == 0 // bytes per sector (low byte)
        && vtoc[0x037] == 1 // bytes per sector (high byte)
        // LOGICAL DISK #2
        && vtoc[0x137] == 1 // bytes per sector (high byte)
        && vtoc[0x101] == 17 // expect catalog to start on track 17
        && vtoc[0x102] == 31 // expect catalog to start on sector 31
        && vtoc[0x127] == 122 // expect 122 tract/sector pairs per sector
        && vtoc[0x134] == 50 // expect 50 tracks per disk
        && vtoc[0x135] == 32 // expect 32 sectors per disk
        && vtoc[0x136] == 0 // bytes per sector (low byte)
        && vtoc[0x137] == 1; // bytes per sector (high byte)
    Log.println(false, "Disk.isOzDosFormat() returning " + retval + ".");
    return retval;
  }

  /**
   * Test the disk format to see if this is a Pascal formatted disk.
   */
  public boolean isPascalFormat()
  {
    Log.println(false, "Disk.isPascalFormat() testing for Pascal format.");
    if (!is140KbDisk()) return false;
    byte[] directory = readBlock(2);
    boolean retval = directory[0] == 0 && directory[1] == 0 && directory[2] == 6 && directory[3] == 0
        && directory[4] == 0 && directory[5] == 0;
    Log.println(false, "Disk.isPascalFormat() returning " + retval + ".");
    return retval;
  }

  /**
   * Test the disk format to see if this is a CP/M formatted disk. Check the
   * first 256 bytes of the CP/M directory for validity.
   */
  public boolean isCpmFormat()
  {
    Log.println(false, "Disk.isCpmFormat() testing for CPM format.");
    if (!is140KbDisk()) return false;
    byte[] directory = readSector(3, 0);
    int bytes[] = new int[256];
    for (int i = 0; i < directory.length; i++)
    {
      bytes[i] = UnsignedByte.intValue(directory[i]);
    }
    int offset = 0;
    int ENTRY_LENGTH = 0x20;
    while (offset < directory.length)
    {
      // Check if this is an empty directory entry (and ignore it)
      int e5count = 0;
      for (int i = 0; i < ENTRY_LENGTH; i++)
      {
        e5count += bytes[offset + i] == 0xe5 ? 1 : 0;
      }
      if (e5count != ENTRY_LENGTH)
      { // Not all bytes were 0xE5
        // Check user number. Should be 0-15 or 0xE5
        if (bytes[offset] > 15 && bytes[offset] != 0xe5) return false;
        // Validate filename has highbit off
        for (int i = 0; i < 8; i++)
        {
          if (bytes[offset + 1 + i] > 127) return false;
        }
        // Extent should be 0-31 (low = 0-31 and high = 0)
        if (bytes[offset + 0xc] > 31 || bytes[offset + 0xe] > 0) return false;
        // Number of used records cannot exceed 0x80
        if (bytes[offset + 0xf] > 0x80) return false;
      }
      // Next entry
      offset += ENTRY_LENGTH;
    }
    Log.println(false, "Disk.isCpmFormat() returning true.");
    return true;
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
  public void setImageOrder(ImageOrder imageOrder)
  {
    this.imageOrder = imageOrder;
  }

  protected static boolean sameSectorsPerDisk(ImageOrder sourceOrder, ImageOrder targetOrder)
  {
    return sourceOrder.getSectorsPerDisk() == targetOrder.getSectorsPerDisk();
  }

  /**
   * Change to a different ImageOrder. Remains in DOS 3.3 format but the
   * underlying order can chage.
   * 
   * @see ImageOrder
   */
  public void makeDosOrder()
  {
    DosOrder doso = new DosOrder(new ByteArrayImageLayout(Disk.APPLE_140KB_DISK));
    changeImageOrderByTrackAndSector(getImageOrder(), doso);
    setImageOrder(doso);
  }

  /**
   * Change to a different ImageOrder. Remains in ProDOS format but the
   * underlying order can chage.
   * 
   * @see ImageOrder
   */
  public void makeProdosOrder()
  {
    ProdosOrder pdo = new ProdosOrder(new ByteArrayImageLayout(Disk.APPLE_140KB_DISK));
    changeImageOrderByBlock(getImageOrder(), pdo);
    setImageOrder(pdo);
  }

  /**
   * Change ImageOrder from source order to target order by copying sector by
   * sector.
   */
  public static void changeImageOrderByTrackAndSector(ImageOrder sourceOrder, ImageOrder targetOrder)
  {
    if (!sameSectorsPerDisk(sourceOrder, targetOrder))
    {
      Log.println(false, "Disk.changeImageOrderByTrackAndSector() expected equal sized images.");
    }
    for (int track = 0; track < sourceOrder.getTracksPerDisk(); track++)
    {
      for (int sector = 0; sector < sourceOrder.getSectorsPerTrack(); sector++)
      {
        byte[] data = sourceOrder.readSector(track, sector);
        targetOrder.writeSector(track, sector, data);
      }
    }
  }

  /**
   * Change ImageOrder from source order to target order by copying block by
   * block.
   */
  public static void changeImageOrderByBlock(ImageOrder sourceOrder, ImageOrder targetOrder)
  {
    if (!sameBlocksPerDisk(sourceOrder, targetOrder))
    {
      Log.println(false, "Disk.changeImageOrderByBlock() expected equal sized images.");
    }
    for (int block = 0; block < sourceOrder.getBlocksOnDevice(); block++)
    {
      byte[] blockData = sourceOrder.readBlock(block);
      targetOrder.writeBlock(block, blockData);
    }
  }

  /**
   * Answers true if the two disks have the same number of blocks per disk.
   */
  protected static boolean sameBlocksPerDisk(ImageOrder sourceOrder, ImageOrder targetOrder)
  {
    return sourceOrder.getBlocksOnDevice() == targetOrder.getBlocksOnDevice();
  }

}
