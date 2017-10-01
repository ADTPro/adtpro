/*
 * ADTPro - Apple Disk Transfer ProDOS
 * Copyright (C) 2013 by David Schmidt
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

import java.io.IOException;
import org.adtpro.gui.Gui;
import com.webcodepro.applecommander.storage.Disk;

public class VDiskPersister
{
	private Gui _parent;
	Disk _disk1 = null, _disk2 = null;

	private static VDiskPersister _theSingleton = null;

	/**
	 * Private constructor - use the <code>getSingleton</code> to instantiate.
	 */
	private VDiskPersister(Gui parent)
	{
		_parent = parent;
		refreshDisks(0);
	}

	private void refreshDisks(int whichDisks)
	{
		if ((whichDisks == 0) || (whichDisks == 1))
		{
			try
			{
				_disk1 = new Disk(_parent.getWorkingDirectory() + "Virtual.po"); //$NON-NLS-1$
			}
			catch (IOException e1)
			{
				Log.println(false, "Unable to find Virtual.po in current working directory; creating a new one.");
				try
				{
					com.webcodepro.applecommander.ui.ac.createProDisk(_parent.getWorkingDirectory() + "Virtual.po", "VIRTUAL", Disk.APPLE_800KB_DISK);
					_disk1 = new Disk(_parent.getWorkingDirectory() + "Virtual.po");
				}
				catch (IOException e)
				{
					e.printStackTrace();
				}
			}
		}
		if ((whichDisks == 0) || (whichDisks == 2))
		{
			try
			{
				_disk2 = new Disk(_parent.getWorkingDirectory() + "Virtual2.po"); //$NON-NLS-1$
			}
			catch (IOException e1)
			{
				Log.println(false, "Unable to find Virtual2.po in current working directory; creating a new one.");
				try
				{
					com.webcodepro.applecommander.ui.ac.createProDisk(_parent.getWorkingDirectory() + "Virtual2.po", "VIRTUAL", Disk.APPLE_800KB_DISK);
					_disk2 = new Disk(_parent.getWorkingDirectory() + "Virtual2.po"); //$NON-NLS-1$
				}
				catch (IOException e)
				{
					e.printStackTrace();
				}
			}
		}
	}

	public byte[] readBlock(int disk, int block) throws IOException
	{
		if (disk == 1)
		{
			return _disk1.readBlock(block);
		}
		else
		{
			return _disk2.readBlock(block);
		}
	}

	public void writeBlock(int disk, int block, byte[] buffer) throws IOException
	{
		if (disk == 1)
		{
			_disk1.writeBlock(block, buffer);
			_disk1.save();
		}
		else
		{
			_disk2.writeBlock(block, buffer);
			_disk2.save();
		}
	}

	/**
	 * Retrieve the single instance of this class.
	 */
	public static VDiskPersister getSingleton(Gui parent)
	{
		if (null == _theSingleton)
			VDiskPersister.allocateSingleton(parent);
		return _theSingleton;
	}

	/**
	 * getSingleton() is not synchronized, so we must check in this method to
	 * make sure a concurrent getSingleton() didn't already allocate the
	 * Singleton synchronized on a static method locks the class
	 */

	private synchronized static void allocateSingleton(Gui parent)
	{
		if (null == _theSingleton)
			_theSingleton = new VDiskPersister(parent);
	}

}