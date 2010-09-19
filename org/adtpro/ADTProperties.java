/*
 * ADTPro - Apple Disk Transfer ProDOS
 * Copyright (C) 2006, 2007 by David Schmidt
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

package org.adtpro;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.Properties;

/**
 * 
 */
public class ADTProperties extends Properties
{
String _fileName = null;
  /**
   * 
   */
  private static final long serialVersionUID = 1L;

  /**
   * 
   */
  public ADTProperties(String fileName)
  {
    super();
    _fileName = fileName;
    load();
  }

  /**
   * Load up the properties
   *
   */
  private void load()
  {
    try
    {
      super.load(new FileInputStream(_fileName));
    }
    catch (Throwable ignored)
    {
      // We ignore a failure to load
    }
  }

  /**
   * Save the properties
   *
   */
  public void save()
  {
    try
    {
      super.store(new FileOutputStream(_fileName), _fileName);
    }
    catch (Throwable t)
    {
      System.out.println(t);
    }
  }

  /**
   * Set a property
   */
  public Object setProperty(String key, String value)
  {
    return super.setProperty(key,value);
  }

  /**
   * Get a property
   */
  public String getProperty(String key, String defaultValue)
  {
    return super.getProperty(key,defaultValue);
  }
 
}
