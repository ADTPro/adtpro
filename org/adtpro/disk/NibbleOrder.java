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

import java.util.Arrays;
import org.adtpro.utilities.UnsignedByte;

/**
 * Supports disk images stored in nibbilized DOS physical order.
 * <p>
 * 
 * @author Rob Greene (RobGreene@users.sourceforge.net)
 */
public class NibbleOrder extends DosOrder
{
  // private TextBundle textBundle = StorageBundle.getInstance();
  /**
   * This is the 6 and 2 write translate table, as given in Beneath Apple DOS,
   * pg 3-21.
   */
  private static int[] writeTranslateTable =
  {
  // $0 $1 $2 $3 $4 $5 $6 $7
      0x96, 0x97, 0x9a, 0x9b, 0x9d, 0x9e, 0x9f, 0xa6, // +$00
      0xa7, 0xab, 0xac, 0xad, 0xae, 0xaf, 0xb2, 0xb3, // +$08
      0xb4, 0xb5, 0xb6, 0xb7, 0xb9, 0xba, 0xbb, 0xbc, // +$10
      0xbd, 0xbe, 0xbf, 0xcb, 0xcd, 0xce, 0xcf, 0xd3, // +$18
      0xd6, 0xd7, 0xd9, 0xda, 0xdb, 0xdc, 0xdd, 0xde, // +$20
      0xdf, 0xe5, 0xe6, 0xe7, 0xe9, 0xea, 0xeb, 0xec, // +$28
      0xed, 0xee, 0xef, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, // +$30
      0xf7, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff // +$38
  };

  /**
   * This maps a DOS 3.3 sector to a physical sector. (readSector and
   * writeSector work off of the DOS 3.3 sector numbering.)
   */
  private static int[] sectorInterleave =
  { 0x0, 0xd, 0xb, 0x9, 0x7, 0x5, 0x3, 0x1, 0xe, 0xc, 0xa, 0x8, 0x6, 0x4, 0x2, 0xf };

  /**
   * The read translation table. Constructed from the write translate table.
   * Used to decode a disk byte into a value from 0x00 to 0x3f which is further
   * decoded...
   */
  public int[] readTranslateTable;

  /**
   * Construct a NibbleOrder.
   */
  public NibbleOrder(ByteArrayImageLayout diskImageManager)
  {
    super(diskImageManager);
    // Construct the read translation table:
    readTranslateTable = new int[256];
    for (int i = 0; i < writeTranslateTable.length; i++)
    {
      readTranslateTable[writeTranslateTable[i]] = i;
    }
  }

  /**
   * Read nibbilized track data.
   */
  protected byte[] readTrackData(int track)
  {
    int trackSize = getPhysicalSize() / getTracksPerDisk();
    return readBytes(track * trackSize, trackSize);
  }

  /**
   * Write nibbilized track data.
   */
  protected void writeTrackData(int track, byte[] trackData)
  {
    int trackSize = getPhysicalSize() / getTracksPerDisk();
    writeBytes(track * trackSize, trackData);
  }

  /**
   * Retrieve the specified sector. The primary source of information for this
   * process is directly from Beneath Apple DOS, chapter 3.
   */
  public byte[] readSector(int track, int dosSector) throws IllegalArgumentException
  {
    int sector = sectorInterleave[dosSector];
    // 1. read track
    byte[] trackData = readTrackData(track);
    // 2. locate address field for this track and sector
    int offset = 0;
    byte[] addressField = new byte[14];
    boolean found = false;
    int attempts = getSectorsPerTrack();
    while (!found && attempts >= 0)
    {
      int nextOffset = locateField(0xd5, 0xaa, 0x96, trackData, addressField, offset);
      attempts--;
      offset = nextOffset;
      int t = decodeOddEven(addressField, 5);
      int s = decodeOddEven(addressField, 7);
      found = (t == track && s == sector);
    }
    // if (!found) {
    // throw new IllegalArgumentException(textBundle
    // .format("NibbleOrder.InvalidPhysicalSectorError", sector, track, 1));
    // //$NON-NLS-1$
    // }
    // 3. read data field that immediately follows the address field
    byte[] dataField = new byte[349];
    locateField(0xd5, 0xaa, 0xad, trackData, dataField, offset);
    // 4. translate data field
    byte[] buffer = new byte[342];
    int checksum = 0;
    for (int i = 0; i < buffer.length; i++)
    {
      int b = UnsignedByte.intValue(dataField[i + 3]);
      checksum ^= readTranslateTable[b]; // XOR
      if (i < 86)
      {
        buffer[buffer.length - i - 1] = (byte) checksum;
      }
      else
      {
        buffer[i - 86] = (byte) checksum;
      }
    }
    checksum ^= readTranslateTable[UnsignedByte.intValue(dataField[345])];
    if (checksum != 0) return null; // BAD DATA
    // 5. decode data field
    byte[] sectorData = new byte[256];
    for (int i = 0; i < sectorData.length; i++)
    {
      int b1 = UnsignedByte.intValue(buffer[i]);
      int lowerBits = buffer.length - (i % 86) - 1;
      int b2 = UnsignedByte.intValue(buffer[lowerBits]);
      int shiftPairs = (i / 86) * 2;
      // shift b1 up by 2 bytes (contains bits 7-2)
      // align 2 bits in b2 appropriately, mask off anything but
      // bits 0 and 1 and then REVERSE THEM...
      int[] reverseValues =
      { 0x0, 0x2, 0x1, 0x3 };
      int b = (b1 << 2) | reverseValues[(b2 >> shiftPairs) & 0x03];
      sectorData[i] = (byte) b;
    }
    return sectorData;
  }

  /**
   * Locate a field on the track. These are identified by a 3 byte unique
   * signature. Because of the way in which disk bytes are captured, we need to
   * wrap around the track to ensure all sequences of bytes are accounted for.
   * <p>
   * This methid fills fieldData as well as returning the last position
   * referenced in the track buffer.
   */
  protected int locateField(int byte1, int byte2, int byte3, byte[] trackData, byte[] fieldData, int startingOffset)
  {
    int i = startingOffset; // logical position in track buffer (can wrap)
    int position = 0; // physical position in field buffer
    while (i < trackData.length + fieldData.length)
    {
      int offset = i % trackData.length; // physical posistion in track buffer
      int b = UnsignedByte.intValue(trackData[offset]);
      if (position == 0 && b == byte1)
      {
        fieldData[position++] = (byte) b;
      }
      else
        if (position == 1 && b == byte2)
        {
          fieldData[position++] = (byte) b;
        }
        else
          if (position == 2 && b == byte3)
          {
            fieldData[position++] = (byte) b;
          }
          else
            if (position >= 3 && position <= fieldData.length)
            {
              if (position < fieldData.length) fieldData[position++] = (byte) b;
              if (position == fieldData.length) break; // done!
            }
            else
            {
              position = 0;
            }
      i++;
    }
    return i % trackData.length;
  }

  /**
   * Decode odd-even bytes as stored on disk. The format will be in two bytes.
   * They are stored as such:
   * 
   * <pre>
   *      XX = 1d1d1d1d (odd data bits)
   *      YY = 1d1d1d1d (even data bits)
   * </pre>
   * 
   * XX is then shifted by a bit and ANDed with YY to get the databyte. See page
   * 3-12 in Beneath Apple DOS for more information.
   */
  protected int decodeOddEven(byte[] buffer, int offset)
  {
    int b1 = UnsignedByte.intValue(buffer[offset]);
    int b2 = UnsignedByte.intValue(buffer[offset + 1]);
    return (b1 << 1 | 0x01) & b2;
  }

  /**
   * Encode odd-even bytes to be stored on disk. See decodeOddEven for the
   * format.
   * 
   * @see #decodeOddEven
   */
  protected void encodeOddEven(byte[] buffer, int offset, int value)
  {
    buffer[offset] = (byte) ((value >> 1) | 0xaa);
    buffer[offset + 1] = (byte) (value | 0xaa);
  }

  /**
   * Write the specified sector.
   */
  public void writeSector(int track, int dosSector, byte[] sectorData) throws IllegalArgumentException
  {
    int sector = sectorInterleave[dosSector];
    // 1. read track
    byte[] trackData = readTrackData(track);
    // 2. locate address field for this track and sector
    int offset = 0;
    byte[] addressField = new byte[14];
    boolean found = false;
    while (!found && offset < trackData.length)
    {
      int nextOffset = locateField(0xd5, 0xaa, 0x96, trackData, addressField, offset);
      // if (nextOffset < offset) { // we wrapped!
      // throw new IllegalArgumentException(textBundle
      // .format("NibbleOrder.InvalidPhysicalSectorError", sector, track, 2));
      // //$NON-NLS-1$
      // }
      offset = nextOffset;
      int t = decodeOddEven(addressField, 5);
      int s = decodeOddEven(addressField, 7);
      found = (t == track && s == sector);
    }
    // if (!found) {
    // throw new IllegalArgumentException(textBundle
    // .format("NibbleOrder.InvalidPhysicalSectorError", sector, track, 2));
    // //$NON-NLS-1$
    // }

    // 3. PRENIBBLE: This is Java translated from assembly @ $B800
    // The Java routine was not working... :o(
    int[] bb00 = new int[0x100];
    int[] bc00 = new int[0x56];
    int x = 0;
    int y = 2;
    while (true)
    {
      y--;
      if (y < 0)
      {
        y += 256;
      }
      int a = UnsignedByte.intValue(sectorData[y]);
      bc00[x] <<= 1;
      bc00[x] |= a & 1;
      a >>= 1;
      bc00[x] <<= 1;
      bc00[x] |= a & 1;
      a >>= 1;
      bb00[y] = a;
      x++;
      if (x >= 0x56)
      {
        x = 0;
        if (y == 0) break; // done
      }
    }
    for (x = 0; x < 0x56; x++)
    {
      bc00[x] &= 0x3f;
    }

    // 4. Translated from portions of WRITE at $B82A:
    byte[] diskData = new byte[343];
    int pos = 0;
    for (y = 0x56; y > 0; y--)
    {
      if (y == 0x56)
      {
        diskData[pos++] = (byte) writeTranslateTable[bc00[y - 1]];
      }
      else
      {
        diskData[pos++] = (byte) writeTranslateTable[bc00[y] ^ bc00[y - 1]];
      }
    }
    diskData[pos++] = (byte) writeTranslateTable[bc00[0] ^ bb00[y]];
    for (y = 1; y < 256; y++)
    {
      diskData[pos++] = (byte) writeTranslateTable[bb00[y] ^ bb00[y - 1]];
    }
    diskData[pos++] = (byte) writeTranslateTable[bb00[255]];

    // 5. write to disk (data may wrap - hence the manual copy)
    byte[] dataFieldPrologue = new byte[3];
    offset = locateField(0xd5, 0xaa, 0xad, trackData, dataFieldPrologue, offset);
    for (int i = 0; i < diskData.length; i++)
    {
      pos = (offset + i) % trackData.length;
      trackData[pos] = diskData[i];
    }
    writeTrackData(track, trackData);
  }

  /**
   * Answer with the number of tracks on this device.
   */
  public int getTracksPerDisk()
  {
    return 35;
  }

  /**
   * Answer with the number of sectors per track on this device.
   */
  public int getSectorsPerTrack()
  {
    return 16;
  }

  /**
   * Answer with the number of blocks on this device. This cannot be computed
   * since the physical size relates to disk bytes (6+2 encoded) instead of a
   * full 8-bit byte.
   */
  public int getBlocksOnDevice()
  {
    return 280;
  }

  /**
   * Format the media. Formatting at the ImageOrder level deals with low-level
   * issues. A typical ordering just needs to have the image "wiped," and that
   * is the assumed implementation. However, specialized orders - such as a
   * nibbilized disk - need to lay down track and sector markers.
   */
  public void format()
  {
    // pre-fill entire disk with 0xff
    byte[] diskImage = new byte[232960]; // 6656 bytes per track
    Arrays.fill(diskImage, (byte) 0xff);
    getDiskImageManager().setDiskImage(diskImage);
    // create initial address and data fields
    byte[] addressField = new byte[14];
    byte[] dataField = new byte[349];
    Arrays.fill(dataField, (byte) 0x96); // decodes to zeros
    byte[] addressPrologue = new byte[]
    { (byte) 0xd5, (byte) 0xaa, (byte) 0x96 };
    byte[] dataPrologue = new byte[]
    { (byte) 0xd5, (byte) 0xaa, (byte) 0xad };
    byte[] epilogue = new byte[]
    { (byte) 0xde, (byte) 0xaa, (byte) 0xeb };
    System.arraycopy(addressPrologue, 0, addressField, 0, 3);
    System.arraycopy(epilogue, 0, addressField, 11, 3);
    System.arraycopy(dataPrologue, 0, dataField, 0, 3);
    System.arraycopy(epilogue, 0, dataField, 346, 3);
    // lay out track with address and data fields
    int addressSync = 43; // number of sync bytes before address field
    int dataSync = 10; // number of sync bytes before data field
    int volume = 254; // disk volume# is always 254
    for (int track = 0; track < getTracksPerDisk(); track++)
    {
      byte[] trackData = readTrackData(track);
      int offset = 0;
      for (int sector = 0; sector < getSectorsPerTrack(); sector++)
      {
        // fill in address field:
        encodeOddEven(addressField, 3, volume);
        encodeOddEven(addressField, 5, track);
        encodeOddEven(addressField, 7, sector);
        encodeOddEven(addressField, 9, volume ^ track ^ sector);
        // write out sector data:
        offset += addressSync;
        System.arraycopy(addressField, 0, trackData, offset, addressField.length);
        offset += addressField.length;
        offset += dataSync;
        System.arraycopy(dataField, 0, trackData, offset, dataField.length);
        offset += dataField.length;
      }
      writeTrackData(track, trackData);
    }
  }
}
