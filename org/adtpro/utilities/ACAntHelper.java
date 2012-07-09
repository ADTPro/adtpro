/*
 * ADTPro - Apple Disk Transfer ProDOS
 * Copyright (C) 2012 by David Schmidt
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

import java.io.IOException;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Task;

public class ACAntHelper extends Task
{

	public void execute() throws BuildException
	{
		/*
		 * Commands: p, cc65, n, k 
		 * p: <imagename> <filename> <type> [<address>]
		 * cc65: <imagename> <filename> <type> 
		 * n: <imagename> <volname> 
		 * k: <imagename> <filename>
		 * 
		 */
		if (_command.equals("p") || (_command.equals("cc65")))
		{
			try
			{
				if (_command.equals("p"))
					com.webcodepro.applecommander.ui.ac.putFile(_input, _imageName, _fileName, _type, _address);
				else
					com.webcodepro.applecommander.ui.ac.putCC65(_input, _imageName, _fileName, _type);
			}
			catch (Exception ex)
			{
				throw new BuildException(ex);
			}
		}
		else
		{
			if (_command.equals("n"))
			{
				try
				{
					com.webcodepro.applecommander.ui.ac.setDiskName(_imageName, _volName);
				}
				catch (IOException io)
				{
					throw new BuildException(io);
				}
			}
			else
			{
				if (_command.equals("k"))
				{
					try
					{
						com.webcodepro.applecommander.ui.ac.setFileLocked(_imageName, _fileName, true);
					}
					catch (IOException io)
					{
						throw new BuildException(io);
					}
				}
				else
				{
					throw new BuildException("Command \""+_command+"\" not implemented.");
				}
			}
		}

	}

	public void setCommand(String command)
	{
		_command = command;
	}

	public void setInput(String input)
	{
		_input = input;
	}

	public void setImageName(String imageName)
	{
		_imageName = imageName;
	}

	public void setFileName(String fileName)
	{
		_fileName = fileName;
	}

	public void setVolumeName(String volumeName)
	{
		_volName = volumeName;
	}

	public void setType(String type)
	{
		_type = type;
	}

	public void setAddress(String address)
	{
		_address = address;
	}

	String _input = null;

	String _command = null;

	String _imageName = null;

	String _fileName = null;

	String _volName = null;

	String _type = null;

	String _address = "0x2000";
}
