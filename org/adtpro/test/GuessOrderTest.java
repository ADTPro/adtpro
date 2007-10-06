/*
 * ADTPro - Apple Disk Transfer ProDOS
 * Copyright (C) 2007 by David Schmidt
 * david__schmidt at users.sourceforge.net
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
