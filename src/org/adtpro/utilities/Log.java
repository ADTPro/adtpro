/*
 * ADTPro - Apple Disk Transfer ProDOS
 * Copyright (C) 2007 - 2020 by David Schmidt
 * 1110325+david-schmidt@users.noreply.github.com
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

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.text.DateFormat;
import java.util.Date;
import org.adtpro.resources.Messages;

public class Log
{
  private static Log _theSingleton = null;

  private static String _traceFileName = null;

  private static boolean _trace = false;

  private static PrintStream _out = null;

  /**
   * Private constructor - use the <code>getSingleton</code> to instantiate.
   */
  private Log()
  {
    _out = System.out;
    // determine log file path
    String logDir = getLogDirectory();
    _traceFileName = logDir + Messages.getString("TraceFileName");
  }

  /**
   * Get a writable directory for the log file, falling back to user.home if needed.
   */
  private String getLogDirectory()
  {
    String logDir;
    String userDirPath = System.getProperty("user.dir");
    File userDir = new File(userDirPath);

    if (userDir.canWrite()) {
      try {
        logDir = userDir.getCanonicalPath();
      } catch (IOException e) {
        logDir = System.getProperty("user.home");
        println(false, "Log.getLogDirectory(): Failed to resolve user.dir, using user.home: " + logDir);
      }
    } else {
      logDir = System.getProperty("user.home");
      println(false, "Log.getLogDirectory(): Current directory is read-only, using user.home: " + logDir);
    }

    // Ensure trailing separator
    if (!logDir.endsWith(File.separator)) {
      logDir += File.separator;
    }
    return logDir;
  }

  public static void printStackTrace(Throwable e)
  {
    e.printStackTrace();
    if (_trace) e.printStackTrace(_out);
  }

  public static void println(boolean console, String logString)
  {
    if (console) System.out.println(logString);
    if (_trace)
    {
      DateFormat longTimestamp = 
        DateFormat.getDateTimeInstance(DateFormat.SHORT, DateFormat.MEDIUM);
      if ((logString != null) && (logString.length() > 0))
      {
        _out.print(longTimestamp.format(new Date())+" ");
        _out.println(logString);
      }
      else
        _out.println();
    }
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
      if (_out.getClass() == PrintStream.class)
      {
        _out.flush();
        _out.close();
        _out = System.out;
      }
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

  public boolean isLogging()
  {
    return _trace;
  }
}
