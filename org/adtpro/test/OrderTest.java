package org.adtpro.test;

import java.io.IOException;

import org.adtpro.disk.Disk;
import org.adtpro.utilities.Log;

public class OrderTest
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
       * Pull in the file named in the argument and assume it's ProDOS
       * ordered (simulating a file reception).  Save the image back
       * out as a dos order image, and name it accordingly.
       * Information will be logged to the trace file about what is found.
       * Note: it is assumed that the file named is a 140k disk.
       */

      disk = new Disk(args[0],true);
      disk.makeDosOrder();
      disk.saveAs(disk.getFilename()+".do");
    }
    catch (IOException e)
    {
      e.printStackTrace();
    }
  }
}
