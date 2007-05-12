package org.adtpro.test;

import java.io.IOException;

import org.adtpro.disk.Disk;
import org.adtpro.utilities.Log;

public class GuessOrderTest
{

  /**
   * @param args
   */
  public static void main(String[] args)
  {
    /*
     * Pull in the file named in the argument and guess it's contents.
     * Information will be logged to the trace file about what is found.
     */
    Log.getSingleton().setTrace(true);
    try
    {
      new Disk(args[0]);
    }
    catch (IOException e)
    {
      e.printStackTrace();
    }
  }
}
