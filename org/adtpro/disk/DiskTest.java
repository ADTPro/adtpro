package org.adtpro.disk;

import java.io.IOException;

import org.adtpro.utilities.UnsignedByte;

public class DiskTest
{

  /**
   * @param args
   */
  public static void main(String[] args)
  {
    try
    {
      byte[] fred;
      int i;
      Disk disk = new Disk("c:/src/ddx/src/mark.asm");
      if (disk.getImageOrder() == null)
        System.out.println("Disk is null!");
      /*
      System.out.println("Image order is: "+disk.getImageOrder());
      fred = disk.readSector(0,0);
      for (i = 0; i < fred.length; i++)
      {
        if (i%32 == 0)
          System.out.println("");
        if (i%256 == 0)
          System.out.println("");
        System.out.print(UnsignedByte.toString(fred[i])+" ");
      }
      fred = disk.readSector(0,1);
      for (i = 0; i < fred.length; i++)
      {
        if (i%32 == 0)
          System.out.println("");
        if (i%256 == 0)
          System.out.println("");
        System.out.print(UnsignedByte.toString(fred[i])+" ");
      }

      fred = disk.readBlock(0);
      for (i = 0; i < fred.length; i++)
      {
        if (i%32 == 0)
          System.out.println("");
        if (i%256 == 0)
          System.out.println("");
        System.out.print(UnsignedByte.toString(fred[i])+" ");
      }
      System.out.println("");
      disk.setImageOrder(new ProdosOrder(disk.getImageOrder().getDiskImageManager()));
      System.out.println("Image order is: "+disk.getImageOrder());
      System.out.println("Image has "+disk.getImageOrder().getBlocksOnDevice()+" blocks.");
      for (i = 0; i < fred.length; i++)
      {
        if (i%32 == 0)
          System.out.println("");
        if (i%256 == 0)
          System.out.println("");
        System.out.print(UnsignedByte.toString(fred[i])+" ");
      }
      System.out.println("");
      */
    }
    catch (IOException ex)
    {
      System.out.println(ex);
    }

  }

}
