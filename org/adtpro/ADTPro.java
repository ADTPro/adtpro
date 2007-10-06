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

import org.adtpro.gui.Gui;
import org.adtpro.resources.Messages;
import org.adtpro.utilities.Log;

/** The main class for launching the ADTPro client graphical user interface.
 * @author File Created By: David Schmidt &lt;david@attglobal.net&gt;
 */
public class ADTPro
{

  public static void main(java.lang.String[] args)
  {
    Log.getSingleton();
    Log.print(true,Messages.getString("Gui.Title")); //$NON-NLS-1$
    Log.println(true," " + Messages.getString("Version.Number")); //$NON-NLS-1$
    Log.println(true,""); //$NON-NLS-1$
    new Gui(args);
  }
}
