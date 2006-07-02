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
   * Private constructor to prohibit instantiation without parameters
   */
  private ADTProperties()
  {
    // Prohibit no-parameter instantiation
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
