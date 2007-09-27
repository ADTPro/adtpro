package org.adtpro.test;

import java.io.IOException;

import org.adtpro.disk.Disk;
import org.adtpro.utilities.Log;

public class TestNib
{

  /**
   * @param args
   */
  public static void main(String[] args)
  {
    Disk disk;
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
    }
    catch (IOException e)
    {
      e.printStackTrace();
    }
  }
}
