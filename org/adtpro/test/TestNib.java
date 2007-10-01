package org.adtpro.test;

import java.io.IOException;

import org.adtpro.disk.Disk;
import org.adtpro.utilities.Log;
import org.adtpro.utilities.UnsignedByte;

public class TestNib
{

  /**
   * @param args
   */
  public static void main(String[] args)
  {
    Disk disk;
    byte[] buffer;
    byte[] trackBuf;
    Log.getSingleton().setTrace(true);
    try
    {
      /*
       * Pull in the file named in the argument and assume it's a
       * nibble file.
       */
      disk = new Disk(args[0]);
      Log.println(true,"Physical size:"+disk.getPhysicalSize());
      byte diskImage[] = disk.getDiskImageManager().getDiskImage();
      Log.println(true,"Disk length:"+diskImage.length);
      {
        int state = 0;
        buffer = disk.getDiskImageManager().getDiskImage();
        int i;
        for (i = 0; i < buffer.length; i++)
        {
          if (state == 1)
          {
            // Still within an autosync run...
            // This may be too intrusive for some disks.
            if ((buffer[i] == UnsignedByte.loByte(0xd5) || (buffer[i] == UnsignedByte.loByte(0xde))) && 
                ((i + 1 < buffer.length) && buffer[i+1] == UnsignedByte.loByte(0xaa)))
            {
              state = 0;
            }
            else
              buffer[i] = 0x7f;
          }
          if ((i + 3 < buffer.length) &&
              (buffer[i] == UnsignedByte.loByte(0xff)) &&
              (buffer[i+1] == UnsignedByte.loByte(0xff)) &&
              (buffer[i+2] == UnsignedByte.loByte(0xff)) &&
              (buffer[i+3] == UnsignedByte.loByte(0xff)))
          {
              buffer[i] = 0x7f;
              buffer[i+1] = 0x7f;
              buffer[i+2] = 0x7f;
              buffer[i+3] = 0x7f;
              i+=3;
              state = 1;
          }
          else
          {
            /*
            {0xFC, 0xFF, 0xFF, 0xFF, 0xFF},
            {0xF9, 0xFE, 0xFF, 0xFF, 0xFF},
            {0xF3, 0xFC, 0xFF, 0xFF, 0xFF},
            {0xE7, 0xF9, 0xFE, 0xFF, 0xFF},
            {0xCF, 0xF3, 0xFC, 0xFF, 0xFF},
            {0x9F, 0xE7, 0xF9, 0xFE, 0xFF},
            */
            if ((i + 4 < buffer.length) &&
                ((buffer[i] == UnsignedByte.loByte(0xfe)) &&
                  (buffer[i+1] == UnsignedByte.loByte(0xff)) &&
                  (buffer[i+2] == UnsignedByte.loByte(0xff)) &&
                  (buffer[i+3] == UnsignedByte.loByte(0xff)) &&
                  (buffer[i+4] == UnsignedByte.loByte(0xff))) ||
                ((buffer[i] == UnsignedByte.loByte(0xfc)) &&
                  (buffer[i+1] == UnsignedByte.loByte(0xff)) &&
                  (buffer[i+2] == UnsignedByte.loByte(0xff)) &&
                  (buffer[i+3] == UnsignedByte.loByte(0xff)) &&
                  (buffer[i+4] == UnsignedByte.loByte(0xff))) ||
                ((buffer[i] == UnsignedByte.loByte(0xf9)) &&
                  (buffer[i+1] == UnsignedByte.loByte(0xfe)) &&
                  (buffer[i+2] == UnsignedByte.loByte(0xff)) &&
                  (buffer[i+3] == UnsignedByte.loByte(0xff)) &&
                  (buffer[i+4] == UnsignedByte.loByte(0xff))) ||
                ((buffer[i] == UnsignedByte.loByte(0xf3)) &&
                  (buffer[i+1] == UnsignedByte.loByte(0xfc)) &&
                  (buffer[i+2] == UnsignedByte.loByte(0xff)) &&
                  (buffer[i+3] == UnsignedByte.loByte(0xff)) &&
                  (buffer[i+4] == UnsignedByte.loByte(0xff))) ||
                ((buffer[i] == UnsignedByte.loByte(0xe7)) &&
                  (buffer[i+1] == UnsignedByte.loByte(0xf9)) &&
                  (buffer[i+2] == UnsignedByte.loByte(0xfe)) &&
                  (buffer[i+3] == UnsignedByte.loByte(0xff)) &&
                  (buffer[i+4] == UnsignedByte.loByte(0xff))) ||
                ((buffer[i] == UnsignedByte.loByte(0xcf)) &&
                  (buffer[i+1] == UnsignedByte.loByte(0xf3)) &&
                  (buffer[i+2] == UnsignedByte.loByte(0xfc)) &&
                  (buffer[i+3] == UnsignedByte.loByte(0xff)) &&
                  (buffer[i+4] == UnsignedByte.loByte(0xff))) ||
                ((buffer[i] == UnsignedByte.loByte(0x9f)) &&
                  (buffer[i+1] == UnsignedByte.loByte(0xe7)) &&
                  (buffer[i+2] == UnsignedByte.loByte(0xf9)) &&
                  (buffer[i+3] == UnsignedByte.loByte(0xfe)) &&
                  (buffer[i+4] == UnsignedByte.loByte(0xff))))
            {
              buffer[i] = 0x7f;
              buffer[i+1] = 0x7f;
              buffer[i+2] = 0x7f;
              buffer[i+3] = 0x7f;
              buffer[i+4] = 0x7f;
              i+=4;
              state = 1;
            }
          }
        }
        Log.println(true, "Rearranging disk image");
        /*
         * Rearrange gap 1 to the beginning of the track 
         */
        boolean wasCountingSyncs = false;
        int syncBytes = 0;
        int syncStart = 0;
        int bestSyncBytes = 0;
        int bestSyncStart = 0;
        trackBuf = new byte[6656*35];
        for (int j = 0; j < 35; j++)
        {
          syncBytes = 0;
          syncStart = 0;
          bestSyncBytes = 0;
          bestSyncStart = 0;
          int bufferOffset =  j * 6656;
          wasCountingSyncs = false;
          Log.println(true,"Dealing with track "+j);
          for (i = 0; i < 6656; i++)
          {
            if (buffer[bufferOffset + i] == UnsignedByte.loByte(0x7f))
            {
              // We found a sync byte.
              if (wasCountingSyncs)
              {
                // If we were already counting them, just increment.
                syncBytes ++;
              }
              else
              {
                syncBytes = 1;
                wasCountingSyncs = true;
                syncStart = bufferOffset + i;
                Log.println(true,"new syncStart: " + syncStart);
              }
            }
            else
            {
              // We stopped counting syncs.
              if (wasCountingSyncs)
              {
                Log.println(true,"Finished counting syncs; starts at:" + syncStart+" and runs for:"+syncBytes);
                if (syncBytes > bestSyncBytes)
                {
                  Log.println(true,"(Which is the best so far.)");
                  bestSyncBytes = syncBytes;
                  bestSyncStart = syncStart;
                }
              }
              wasCountingSyncs = false;
            }
          }
          if (syncBytes > bestSyncBytes)
          {
            bestSyncBytes = syncBytes;
            bestSyncStart = syncStart;
          }
        
          Log.println(true, "bestSyncStart: " + bestSyncStart);
          int bufferPointer = bufferOffset;
          // Found the best run of sync bytes.  Spin forward a bit and start there.
          if (bestSyncBytes > 26)
          {
            bufferPointer = bestSyncStart + 26;
            bestSyncStart += 26;
          }
          for (i = 0; i < 6656; i++)
          {
            if (bufferPointer + i >= 6656 + bufferOffset)
            {
              bufferPointer = bufferPointer - 6656;
            }
            // Log.println(false, "trackbuf["+(bufferOffset + i)+"]= buffer["+(bufferPointer + i) + "]");
            try
            {
              trackBuf[bufferOffset + i] = buffer[bufferPointer + i];
            }
            catch (Throwable t)
            {
              Log.println(true, "Oops! trackbuf["+(bufferOffset + i)+"]= buffer["+(bufferPointer + i) + "]");
            }
          }
        }
        /*
         * Dump out all tracks
         */
        for (int j = 0; j < 35; j++)
        {
          Log.print(false, "Dumping out disk:");
          for (i = 0; i < 6656; i++)
            Log.print(false, UnsignedByte.toString(trackBuf[j * 6656 + i])); //buffer[j*6656+i]));
          Log.println(false, "");
        }
      }
    }
    catch (IOException e)
    {
      e.printStackTrace();
    }
  }
}
