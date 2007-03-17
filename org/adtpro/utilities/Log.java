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

package org.adtpro.utilities;

import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.PrintStream;

import org.adtpro.resources.Messages;

public class Log
{
  private static Log _theSingleton = null;

  private static String _traceFileName = Messages.getString("TraceFileName");

  private static boolean _trace = false;

  private static PrintStream _out = null;

  /**
   * 
   * Private constructor - use the <code>getSingleton</code> to instantiate.
   * 
   */
  private Log()
  {
    _out = System.out;
  }

  public static void printStackTrace(Throwable e)
  {
    e.printStackTrace();
    if (_trace) e.printStackTrace(_out);
  }

  public static void println(boolean console, String logString)
  {
    if (console) System.out.println(logString);
    if (_trace) _out.println(logString);
  }

  public static void print(boolean console, String logString)
  {
    if (console) System.out.print(logString);
    if (_trace) _out.print(logString);
  }

  /**
   * Retrieve the single instance of this class.
   * 
   * @return Log
   */
  public static Log getSingleton()
  {
    if (null == _theSingleton)
      Log.allocateSingleton();
    return _theSingleton;
  }

  public void setTrace(boolean trace)
  {
    _trace = trace;
    if (trace == true) // Trace turned on
    {
      if (_traceFileName != null)
      {
        try
        {
          _out.flush();
          _out = new PrintStream(new FileOutputStream(_traceFileName));
        }
        catch (FileNotFoundException io)
        {
          io.printStackTrace();
          _out = System.out;
        }
      }
    }
    else // Trace turned off
    {
      _out.flush();
      if (_out.getClass() == PrintStream.class)
        _out.close();
      _out = System.out;
    }
  }

  public void setTraceFile(String filename)
  {
    _traceFileName = filename;
  }

  /**
   * getSingleton() is not synchronized, so we must check in this method to make
   * sure a concurrent getSingleton() didn't already allocate the Singleton
   * 
   * synchronized on a static method locks the class
   */
  private synchronized static void allocateSingleton()
  {
    if (null == _theSingleton) _theSingleton = new Log();
  }

}