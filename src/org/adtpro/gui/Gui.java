/*
 * ADTPro - Apple Disk Transfer ProDOS
 * Copyright (C) 2006 - 2016 by David Schmidt
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

package org.adtpro.gui;

import java.awt.BorderLayout;
import java.awt.Desktop;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;
import java.awt.Rectangle;
import java.awt.Toolkit;
import java.awt.Window;
import java.awt.event.*;
import java.io.File;
import java.io.FilenameFilter;
import java.io.IOException;
import java.net.InetAddress;
import java.net.URI;
import java.util.Arrays;
import java.util.Properties;

import javax.swing.*;

import org.adtpro.resources.Messages;
import org.adtpro.transport.ATransport;
import org.adtpro.transport.AudioTransport;
import org.adtpro.transport.SerialTransport;
import org.adtpro.transport.SerialIPTransport;
import org.adtpro.transport.UDPTransport;
import org.adtpro.utilities.Log;
import org.adtpro.utilities.StringUtilities;
import org.adtpro.ADTProperties;
import org.adtpro.CommsThread;

/**
 * The ADTPro graphical user interface class.
 * 
 * @author File Created By: David Schmidt &lt;david@attglobal.net&gt;
 */
public final class Gui extends JFrame implements ActionListener
{
	/**
   * 
   */
	private static final long serialVersionUID = 1L;

	Gui _parent;

	private CommsThread _commsThread;

	private String _workingDirectory = getWorkingDirectory();

	private JProgressBar progressBar;

	private JLabel labelMainProgress, labelSubProgress;

	public ADTProperties _properties = new ADTProperties(Messages.getString("PropertiesFileName"));

	boolean _isSerialAvailable = false;

	JMenu menuBootstrap;

	JMenuItem _dosAction2 = null;

	JMenuItem _sosAction = null;

	JMenuItem _speedibootAction = null;

	JMenuItem _vsdrivebootAction = null;

	JMenuItem _serialConfigBootstrapAction = null;

	JCheckBoxMenuItem _protoCompatMenuItem = null;

	JCheckBoxMenuItem _traceMenuItem = null;

	JRadioButton _serialButton = null;

	JRadioButton _ethernetButton = null;

	JRadioButton _audioButton = null;

	JRadioButton _disconnectButton = null;

	JRadioButton _previousButton = null;

	public Gui(java.lang.String[] args)
	{
		Log.getSingleton().setTrace(_properties.getProperty("TraceEnabled", "false").compareTo("true") == 0);
		Log.println(false, "Gui Constructor entry.");

		addWindowListener(new WindowCloseMonitor());
		setTitle(Messages.getString("Gui.Title") + " " + Messages.getString("Version.Number")); //$NON-NLS-1$ //$NON-NLS-2$
		try
		{
			setIconImage(Toolkit.getDefaultToolkit().getImage(getClass().getResource("/org/adtpro/resources/ADTPro.png")));
		}
		catch (Throwable ex)
		{
		}
		String tempDir = _properties.getProperty("WorkingDirectory", "disks"); //$NON-NLS-1$
		if (tempDir != null)
			setWorkingDirectory(tempDir);

		JMenuBar menuBar = new JMenuBar();
		JPanel mainPanel = new JPanel(new GridBagLayout());
		this.getContentPane().add(mainPanel, BorderLayout.CENTER);

		JMenu menuFile = new JMenu(Messages.getString("Gui.File")); //$NON-NLS-1$
		MenuAction serialConfigAction = new MenuAction(Messages.getString("Gui.SerialConfig")); //$NON-NLS-1$
		menuFile.add(serialConfigAction);
		//MenuAction audioConfigAction = new MenuAction(Messages.getString("Gui.AudioConfig")); //$NON-NLS-1$
		//menuFile.add(audioConfigAction);
		MenuAction cdAction = new MenuAction(Messages.getString("Gui.CD")); //$NON-NLS-1$
		menuFile.add(cdAction);
		_traceMenuItem = new JCheckBoxMenuItem(Messages.getString("Gui.Trace"));
		menuFile.add(_traceMenuItem);
		_traceMenuItem.addActionListener(this);
		// _protoCompatMenuItem = new JCheckBoxMenuItem(Messages.getString("Gui.ProtocolCompatability"));
		// menuFile.add(_protoCompatMenuItem);
		// _protoCompatMenuItem.addActionListener(this);
		MenuAction quitAction = new MenuAction(Messages.getString("Gui.Quit")); //$NON-NLS-1$
		menuFile.add(quitAction);
		menuBar.add(menuFile);
		menuBootstrap = new JMenu(Messages.getString("Gui.Bootstrap")); //$NON-NLS-1$
		JMenu menuBootstrapProDOS = new JMenu(Messages.getString("Gui.BootstrapProDOS")); //$NON-NLS-1$
		JMenu menuBootstrapDOS = new JMenu(Messages.getString("Gui.BootstrapDOS")); //$NON-NLS-1$
		MenuAction proDOSFastAction = new MenuAction(Messages.getString("Gui.BS.ProDOSFast")); //$NON-NLS-1$
		_speedibootAction = menuBootstrapProDOS.add(proDOSFastAction);
		_speedibootAction.setEnabled(true);
		MenuAction proDOSVSDriveAction = new MenuAction(Messages.getString("Gui.BS.ProDOSVSDrive")); //$NON-NLS-1$
		_vsdrivebootAction = menuBootstrapProDOS.add(proDOSVSDriveAction);
		_vsdrivebootAction.setEnabled(true);
		menuBootstrapProDOS.addSeparator();
		MenuAction proDOSAction = new MenuAction(Messages.getString("Gui.BS.ProDOS")); //$NON-NLS-1$
		menuBootstrapProDOS.add(proDOSAction);
		MenuAction dosAction = new MenuAction(Messages.getString("Gui.BS.DOS")); //$NON-NLS-1$
		menuBootstrapDOS.add(dosAction);
		MenuAction dosAction2 = new MenuAction(Messages.getString("Gui.BS.DOS2")); //$NON-NLS-1$
		_dosAction2 = menuBootstrapDOS.add(dosAction2);
		_dosAction2.setEnabled(true);
		MenuAction adtAction = new MenuAction(Messages.getString("Gui.BS.ADT")); //$NON-NLS-1$
		menuBootstrapDOS.add(adtAction);
		MenuAction adtProAction = new MenuAction(Messages.getString("Gui.BS.ADTPro")); //$NON-NLS-1$
		menuBootstrapProDOS.add(adtProAction);
		MenuAction adtProAudioAction = new MenuAction(Messages.getString("Gui.BS.ADTProAudio")); //$NON-NLS-1$
		menuBootstrapProDOS.add(adtProAudioAction);
		MenuAction adtProEthernetAction = new MenuAction(Messages.getString("Gui.BS.ADTProEthernet")); //$NON-NLS-1$
		menuBootstrapProDOS.add(adtProEthernetAction);
		menuBar.add(menuBootstrap);
		menuBootstrap.add(menuBootstrapProDOS);
		menuBootstrap.add(menuBootstrapDOS);
		MenuAction sosAction = new MenuAction(Messages.getString("Gui.BS.SOS")); //$NON-NLS-1$
		_sosAction = menuBootstrap.add(sosAction);
		MenuAction serialConfigBootstrapAction = new MenuAction(Messages.getString("Gui.SerialConfigBootstrap")); //$NON-NLS-1$
		_serialConfigBootstrapAction = menuBootstrapProDOS.add(serialConfigBootstrapAction);
		_serialConfigBootstrapAction.setEnabled(true);
		menuBootstrap.add(_serialConfigBootstrapAction);
		menuBootstrap.setEnabled(false);
		JMenu menuHelp = new JMenu(Messages.getString("Gui.Help")); //$NON-NLS-1$
		MenuAction helpAction = new MenuAction(Messages.getString("Gui.Website")); //$NON-NLS-1$
		menuHelp.add(helpAction);
		MenuAction aboutAction = new MenuAction(Messages.getString("Gui.About")); //$NON-NLS-1$
		menuHelp.add(aboutAction);
		menuBar.add(menuHelp);
		this.setJMenuBar(menuBar);

		// _protoCompatMenuItem.setSelected(_properties.getProperty("Client01xCompatibleProtocol", "false").compareTo("true") == 0); //$NON-NLS-1$ //$NON-NLS-2$
		_traceMenuItem.setSelected(_properties.getProperty("TraceEnabled", "false").compareTo("true") == 0); //$NON-NLS-1$ //$NON-NLS-2$
		// Log.getSingleton().setTrace(_traceMenuItem.isSelected());

		labelMainProgress = new JLabel(Messages.getString("Gui.Quiesced")); //$NON-NLS-1$
		labelSubProgress = new JLabel(Messages.getString("Gui.Disconnected")); //$NON-NLS-1$
		progressBar = new JProgressBar();
		progressBar.setString(""); //$NON-NLS-1$
		progressBar.setMaximum(280);
		progressBar.setValue(0);
		progressBar.setStringPainted(true);

		_serialButton = new JRadioButton(Messages.getString("Gui.SerialButton"), new ImageIcon(Toolkit.getDefaultToolkit().getImage(getClass().getResource("/org/adtpro/resources/serialDeselected.png"))));
		_serialButton.setHorizontalTextPosition(SwingConstants.CENTER);
		_serialButton.setVerticalTextPosition(SwingConstants.BOTTOM);
		_serialButton.setMargin(new Insets(0, 0, 0, 0));
		_serialButton.setSelectedIcon(new ImageIcon(Toolkit.getDefaultToolkit().getImage(getClass().getResource("/org/adtpro/resources/serialSelected.png"))));
		_serialButton.addActionListener(this);
		_ethernetButton = new JRadioButton(Messages.getString("Gui.EthernetButton"), new ImageIcon(Toolkit.getDefaultToolkit().getImage(getClass().getResource("/org/adtpro/resources/ethernetDeselected.png"))));
		_ethernetButton.setHorizontalTextPosition(SwingConstants.CENTER);
		_ethernetButton.setVerticalTextPosition(SwingConstants.BOTTOM);
		_ethernetButton.setMargin(new Insets(0, 0, 0, 0));
		_ethernetButton.setSelectedIcon(new ImageIcon(Toolkit.getDefaultToolkit().getImage(getClass().getResource("/org/adtpro/resources/ethernetSelected.png"))));
		_ethernetButton.addActionListener(this);
		_audioButton = new JRadioButton(Messages.getString("Gui.AudioButton"), new ImageIcon(Toolkit.getDefaultToolkit().getImage(getClass().getResource("/org/adtpro/resources/audioDeselected.png"))));
		_audioButton.setHorizontalTextPosition(SwingConstants.CENTER);
		_audioButton.setVerticalTextPosition(SwingConstants.BOTTOM);
		_audioButton.setMargin(new Insets(0, 0, 0, 0));
		_audioButton.setSelectedIcon(new ImageIcon(Toolkit.getDefaultToolkit().getImage(getClass().getResource("/org/adtpro/resources/audioSelected.png"))));
		_audioButton.addActionListener(this);
		_disconnectButton = new JRadioButton(Messages.getString("Gui.DisconnectButton"), new ImageIcon(Toolkit.getDefaultToolkit().getImage(getClass().getResource("/org/adtpro/resources/disconnectDeselected.png"))));
		_disconnectButton.setHorizontalTextPosition(SwingConstants.CENTER);
		_disconnectButton.setVerticalTextPosition(SwingConstants.BOTTOM);
		_disconnectButton.setMargin(new Insets(0, 0, 0, 0));
		_disconnectButton.setSelectedIcon(new ImageIcon(Toolkit.getDefaultToolkit().getImage(getClass().getResource("/org/adtpro/resources/disconnectSelected.png"))));
		_disconnectButton.addActionListener(this);
		ButtonGroup bg = new ButtonGroup();
		bg.add(_serialButton);
		bg.add(_ethernetButton);
		bg.add(_audioButton);
		bg.add(_disconnectButton);

		GridBagUtil.constrain(mainPanel, _serialButton, 1, 1, // X, Y
				// Coordinates
				1, 1, // Grid width, height
				GridBagConstraints.HORIZONTAL, // Fill value
				GridBagConstraints.WEST, // Anchor value
				0.0, 0.0, // Weight X, Y
				5, 5, 5, 0); // Top, left, bottom, right insets
		GridBagUtil.constrain(mainPanel, _ethernetButton, 2, 1, // X, Y
				// Coordinates
				1, 1, // Grid width, height
				GridBagConstraints.HORIZONTAL, // Fill value
				GridBagConstraints.WEST, // Anchor value
				0.0, 0.0, // Weight X, Y
				5, 10, 5, 0); // Top, left, bottom, right insets
		GridBagUtil.constrain(mainPanel, _audioButton, 3, 1, // X, Y
				// Coordinates
				1, 1, // Grid width, height
				GridBagConstraints.HORIZONTAL, // Fill value
				GridBagConstraints.WEST, // Anchor value
				0.0, 0.0, // Weight X, Y
				5, 10, 5, 0); // Top, left, bottom, right insets
		GridBagUtil.constrain(mainPanel, _disconnectButton, 4, 1, // X, Y
				// Coordinates
				1, 1, // Grid width, height
				GridBagConstraints.NONE, // Fill value
				GridBagConstraints.EAST, // Anchor value
				0.0, 0.0, // Weight X, Y
				5, 10, 5, 5); // Top, left, bottom, right insets
		GridBagUtil.constrain(mainPanel, labelMainProgress, 1, 3, // X, Y
				// Coordinates
				4, 1, // Grid width, height
				GridBagConstraints.HORIZONTAL, // Fill value
				GridBagConstraints.WEST, // Anchor value
				1.0, 0.0, // Weight X, Y
				0, 5, 5, 5); // Top, left, bottom, right insets
		GridBagUtil.constrain(mainPanel, progressBar, 1, 4, // X, Y Coordinates
				4, 1, // Grid width, height
				GridBagConstraints.HORIZONTAL, // Fill value
				GridBagConstraints.WEST, // Anchor value
				1.0, 0.0, // Weight X, Y
				0, 5, 5, 5); // Top, left, bottom, right insets
		GridBagUtil.constrain(mainPanel, labelSubProgress, 1, 5, // X, Y
				// Coordinates
				4, 1, // Grid width, height
				GridBagConstraints.HORIZONTAL, // Fill value
				GridBagConstraints.WEST, // Anchor value
				1.0, 0.0, // Weight X, Y
				0, 5, 5, 5); // Top, left, bottom, right insets
		_parent = this;
		this.pack();
		_previousButton = _disconnectButton;
		_disconnectButton.requestFocus();
		_disconnectButton.doClick();

		int coord = Integer.parseInt(_properties.getProperty("CoordH", "0"));
		if (coord > 0)
		{
			Rectangle r = new Rectangle(Integer.parseInt(_properties.getProperty("CoordX", "0")), Integer.parseInt(_properties.getProperty("CoordY", "0")), Integer.parseInt(_properties.getProperty("CoordW", "0")), Integer.parseInt(_properties.getProperty("CoordH", "0")));
			if (((r.height == 0) || (r.width == 0)) || // Anything was zero
					(!FrameUtils.fits(r))) // Dimensions put us outside current
			// view
			{
				Log.println(false, "Gui setting screen coordinates to defaults; properties file coords weren't good.");
				setBounds(FrameUtils.center(this.getSize()));
			}
			else
			{
				Log.println(false, "Gui setting screen coordinates from properties file values.");
				setBounds(r);
			}
		}
		else
		{
			Log.println(false, "Gui setting screen coordinates to defaults; properties file height was zero.");
			setBounds(FrameUtils.center(this.getSize()));
		}
		this.setVisible(true);
		SerialConfig.getSingleton(this);
		AudioConfig.getSingleton(this, _properties);
		Log.println(true, "OS: "+System.getProperty("os.name"));
		Log.println(true, "Java VM: "+System.getProperty("java.vm.info"));
		Log.println(true, "Java bit width: "+System.getProperty("sun.arch.data.model"));
		Log.println(true, "Invocation args.length: " + args.length);
		if (args.length > 0)
		{
			String arg0 = args[0];
			Log.println(true, "args [0] = " + arg0);
			if ((arg0.equalsIgnoreCase(Messages.getString("Gui.EthernetButton"))) || (arg0.equalsIgnoreCase("ethernet")))
			{
				_ethernetButton.doClick();
			}
			else if ((arg0.equalsIgnoreCase(Messages.getString("Gui.SerialButton"))) || (arg0.equalsIgnoreCase("serial")))
			{
				_serialButton.doClick();
			}
			else if ((arg0.equalsIgnoreCase(Messages.getString("Gui.AudioButton"))) || (arg0.equalsIgnoreCase("audio")))
			{
				_audioButton.doClick();
			}
			else if ((arg0.equalsIgnoreCase(Messages.getString("Gui.SerialIPButton"))) || (arg0.equalsIgnoreCase("localhost")))
			{
				Log.println(false, "Gui constructor starting the Serial-IP client.");
				try
				{
					boolean success = startComms(new SerialIPTransport(_properties.getProperty("SerialIPHost", "localhost"), _properties.getProperty("SerialIPPort", "1977")));
					if (success)
					{
						String msg = Messages.getString("Gui.ServingSerialIPTitle");
						msg = StringUtilities.replaceSubstring(msg, "%1", _properties.getProperty("SerialIPPort", "1977"));
						msg = StringUtilities.replaceSubstring(msg, "%2", _properties.getProperty("SerialIPHost", "localhost"));
						setTitle(msg);
						_properties.setProperty("SerialIPPort", _properties.getProperty("SerialIPPort", "1977"));
						_properties.setProperty("SerialIPHost", _properties.getProperty("SerialIPHost", "localhost"));
						Log.println(false, "Gui constructor started Serial-IP client.");
					}
				}
				catch (Exception e1)
				{
					Log.printStackTrace(e1);
					setTitle(Messages.getString("Gui.Title") + " " + Messages.getString("Version.Number")); //$NON-NLS-1$ //$NON-NLS-2$
					Log.println(false, "Gui constructor can't start the localhost client.");
				}
			}
		}
		Log.println(false, "Gui Constructor exit.");
	}

	public void actionPerformed(ActionEvent e)
	{
		Log.println(false, "Gui.actionPerformed() entry, responding to " + e.getActionCommand() + "; previous button is " + _previousButton.getText());
		// _serialButton clicked
		if ((e.getSource() == _serialButton) && (_previousButton != _serialButton))
		{
			if (_isSerialAvailable)
			{
				if (startComms(null)) // Can we successfully disconnect if something was already running?
				{
					if ((_properties.getProperty("CommPortSpeed") == null) || (_properties.getProperty("CommPort") == null))
					{
						serialConfigGui(0);
						if (SerialConfig.getSingleton(this).getExitStatus() == SerialConfig.OK)
						{
							_serialButton.doClick();
						}
						else
						{
							_disconnectButton.doClick();
						}
					}
					else
					{
						try
						{
							setSerialTitle();
							Log.println(false, "Gui.actionPerformed setting previous button to _serialButton.");
							JRadioButton localButton = _previousButton;
							_previousButton = _serialButton; // Remember last button state
							boolean success = startComms(new SerialTransport(this, _properties.getProperty("CommPort"), _properties.getProperty("CommPortSpeed"), _properties.getProperty("HardwareHandshaking", "false").compareTo("true") == 0));
							if (success == false)
							{
								localButton.doClick();
							}
						}
						catch (Exception e1)
						{
							Log.printStackTrace(e1);
							_disconnectButton.doClick();
						}
					}
				}
				else
				{
					_previousButton.doClick();
				}
			}
			else
			{
				JOptionPane.showMessageDialog(this, Messages.getString("Gui.NoSerialLibDialogText"), Messages.getString("Gui.NoSerialLibDialogTitle"), JOptionPane.OK_OPTION);
				_disconnectButton.doClick();
			}
		}
		else
		// _ethernetButton clicked
		if ((e.getSource() == _ethernetButton) && (_previousButton != _ethernetButton))
		{
			Log.println(false, "Gui.actionPerformed acting on the ethernet button.");
			try
			{
				boolean success = startComms(new UDPTransport(_properties.getProperty("UDPServerPort", "6502")));
				if (success)
				{
					String msg = Messages.getString("Gui.ServingEthernetTitle");
					msg = StringUtilities.replaceSubstring(msg, "%1", InetAddress.getLocalHost().getHostAddress());
					setTitle(msg);
					Log.println(false, "Gui.actionPerformed ethernet button connected.");
					_previousButton = _ethernetButton; // Remember last button state
				}
				else
				{
					_previousButton.doClick();
				}
			}
			catch (Exception e1)
			{
				Log.printStackTrace(e1);
				setTitle(Messages.getString("Gui.Title") + " " + Messages.getString("Version.Number")); //$NON-NLS-1$ //$NON-NLS-2$
				_disconnectButton.doClick();
				Log.println(false, "Gui.actionPerformed ethernet button can't connect.");
			}
		}
		else
		// _audioButton clicked
		if ((e.getSource() == _audioButton) && (_previousButton != _audioButton))
		{
			boolean success = startComms(new AudioTransport(_properties));
			if (success)
			{
				setTitle(Messages.getString("Gui.Title") + " " + Messages.getString("Version.Number")); //$NON-NLS-1$ //$NON-NLS-2$
				setTitle(Messages.getString("Gui.ServingAudioTitle"));
				_previousButton = _audioButton; // Remember last button state
			}
			else
			{
				_previousButton.doClick();
			}
		}
		else
		// _disconnectButton clicked
		if (e.getSource() == _disconnectButton)
		{
			if (_previousButton != _disconnectButton)
			{
				boolean success = startComms(null);
				if (success)
				{
					setTitle(Messages.getString("Gui.Title") + " " + Messages.getString("Version.Number")); //$NON-NLS-1$ //$NON-NLS-2$
					_previousButton = _disconnectButton;
					Log.println(false, "Gui.actionPerformed setting previous button to _disconnectButton.");
				}
				else
				{
					_previousButton.doClick();
				}
			}
		}
		else if (e.getActionCommand().equals(Messages.getString("Gui.Trace"))) //$NON-NLS-1$
		{
			Log.getSingleton().setTrace(_traceMenuItem.isSelected());
			saveProperties();
		}
		Log.println(false, "Gui.actionPerformed() exit.");
	}

	public String getWorkingDirectory()
	{
		File baseDirFile;
		if (_workingDirectory == null)
		{
			baseDirFile = new File("."); //$NON-NLS-1$
			_workingDirectory = baseDirFile.getAbsolutePath();
			_workingDirectory = _workingDirectory.substring(0, _workingDirectory.length() - 2);
		}
		if (!_workingDirectory.endsWith(File.separator))
		{
			_workingDirectory = _workingDirectory + File.separator;
		}
		Log.println(false, "Gui.getWorkingDirectory(): " + _workingDirectory);
		return _workingDirectory;
	}

	public void setSerialTitle()
	{
		String msg = Messages.getString("Gui.ServingSerialTitle");
		msg = StringUtilities.replaceSubstring(msg, "%1", _properties.getProperty("CommPort"));
		msg = StringUtilities.replaceSubstring(msg, "%2", _properties.getProperty("CommPortSpeed"));
		setTitle(msg);
	}

	public void setSerialSpeed(int speed)
	{
		if (speed == 0)
			speed = Integer.parseInt(_properties.getProperty("CommPortSpeed","115200"));
		_commsThread.setSpeed(speed);
		String oldSpeed = _properties.getProperty("CommPortSpeed","115200");
		_properties.setProperty("CommPortSpeed", new String("" + speed));
		setSerialTitle();
		_properties.setProperty("CommPortSpeed", oldSpeed);
	}

	public void serialConfigGui(int tab)
	{
		SerialConfig.getSingleton(this);
		SerialConfig.setProperties(_properties);
		SerialConfig.showSingleton(this, tab);
	}

	public void audioConfigGui()
	{
		AudioConfig.getSingleton(this, _properties);
		AudioConfig.showSingleton(this);
	}

	public byte setWorkingDirectory(String cwd)
	{
		byte rc = 0x06; // Unable to change directory message at Apple
		cwd = cwd.trim();
		File parentDir;
		File cwdDir = new File(cwd);
		Log.println(false, "Gui.setWorkingDirectory() incoming: " + cwd);
		if (cwdDir.isAbsolute())
			parentDir = null;
		else
			parentDir = new File(_workingDirectory);
		Log.println(false, "Gui.setWorkingDirectory() parentDir: "+parentDir);

		File baseDirFile = new File(parentDir, cwd);
		String tempWorkingDirectory = null;
		try
		{
			tempWorkingDirectory = baseDirFile.getCanonicalPath();
			baseDirFile = new File(tempWorkingDirectory);
			if (!baseDirFile.isDirectory())
			{
				tempWorkingDirectory = null;
			}
		}
		catch (IOException io)
		{
			tempWorkingDirectory = null;
			baseDirFile = new File(cwd);
			try
			{
				tempWorkingDirectory = baseDirFile.getCanonicalPath();
				if (!baseDirFile.isDirectory())
				{
					tempWorkingDirectory = null;
				}
			}
			catch (IOException io2)
			{
				// Log.println(true,"boom...");
			}
		}
		if (tempWorkingDirectory != null)
		{
			if (!_workingDirectory.endsWith(File.separator))
			{
				_workingDirectory = _workingDirectory + File.separator;
			}
			_workingDirectory = tempWorkingDirectory;
			Log.println(false, "Gui.setWorkingDirectory() saving: " + _workingDirectory);
			saveProperties();
			rc = 0x00;
		}
		else
			Log.println(false, "Gui.setWorkingDirectory() unable to make that change.");
		return rc;
	}

	public String[] getFiles(String filespec)
	{
		File baseDirFile;
		StringBuffer newFileSpecBuf = new StringBuffer();
		for (int i = 0; i < filespec.length();i++)
		{
			newFileSpecBuf.append(filespec.charAt(i));
		}
		String newFileSpec = newFileSpecBuf.toString();
		final String pattern = newFileSpec.replaceAll("\\*", ".*").replaceAll("\\?", ".");
		baseDirFile = new File(getWorkingDirectory());
		FilenameFilter filter = new FilenameFilter()
		{
			public boolean accept(File directory, String fileName)
			{
				return fileName.toUpperCase().matches(pattern.toUpperCase());
			}
		};
		String[] myFiles = baseDirFile.list(filter);
		return myFiles;
	}

	public String[] getFiles()
	{
		File baseDirFile;
		baseDirFile = new File(getWorkingDirectory());
		File[] files = baseDirFile.listFiles();
		String[] result = new String[files.length];
		for (int i = 0; i < files.length; i++)
		{
			result[i] = files[i].getName();
		}
		Arrays.sort(result);
		return result;
	}

	public void setSerialAvailable(boolean avail)
	{
		_isSerialAvailable = avail;
	}

	public void setProgressMaximum(int max)
	{
		clearProgress();
		progressBar.setMaximum(max);
		progressBar.setString("");
	}

	public void clearProgress()
	{
		setProgressValue(0);
		progressBar.setString("");
	}

	public void setProgressValue(int value)
	{
		progressBar.setValue(value);
	}

	public void setMainText(String text)
	{
		labelMainProgress.setText(text);
	}

	public void setSecondaryText(String text)
	{
		if (!text.equals(""))
		{
			labelSubProgress.setText(text);
			labelSubProgress.setForeground(labelMainProgress.getForeground());
		}
		else
		{
			/*
			 * If they want a blank label, we have to give it a little text and
			 * hide it by making it the same color as the background. Otherwise,
			 * things get re-laid out and compressed strangely.
			 */
			labelSubProgress.setText("I");
			labelSubProgress.setForeground(labelSubProgress.getBackground());
		}
	}

	class MenuAction extends AbstractAction
	{
		/**
     * 
     */
		private static final long serialVersionUID = 5031778497008160371L;

		public MenuAction(String text)
		{
			super(text, null);
		}

		public MenuAction(String text, Icon icon)
		{
			super(text, icon);
		}

		public void actionPerformed(ActionEvent e)
		{
			Object buttons[] = { Messages.getString("Gui.Ok"), Messages.getString("Gui.Cancel") };
			String message;
			Log.println(false, "Gui.MenuAction.actionPerformed() responding to " + e.getActionCommand());
			if (e.getActionCommand().equals(Messages.getString("Gui.Quit"))) //$NON-NLS-1$
			{
				saveProperties();
				setVisible(false);
				dispose();
				System.exit(0);
			}
			else if (e.getActionCommand().equals(Messages.getString("Gui.About"))) //$NON-NLS-1$
			{
				String aboutString = Messages.getString("Gui.AboutText");
				aboutString = StringUtilities.replaceSubstring(aboutString, "%1", Messages.getString("Version.Number"));
				JOptionPane.showMessageDialog(null, aboutString, Messages.getString("Gui.About"), JOptionPane.INFORMATION_MESSAGE);
			}
			else if (e.getActionCommand().equals(Messages.getString("Gui.Website"))) //$NON-NLS-1$
			{
				try
				{
					Desktop.getDesktop().browse(new URI("http://adtpro.com"));
				}
				catch (Exception ex)
				{
					ex.printStackTrace();
				}
			}
			else if (e.getActionCommand().equals(Messages.getString("Gui.CD"))) //$NON-NLS-1$
			{
				JFileChooser jc = new JFileChooser();
				jc.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
				jc.setCurrentDirectory(new File(getWorkingDirectory()));
				int rc = jc.showDialog(_parent, Messages.getString("Gui.CDSet"));
				if (rc == 0)
				{
					if (jc.getSelectedFile().isDirectory())
					{
						setWorkingDirectory(jc.getSelectedFile().toString());
						setSecondaryText(jc.getSelectedFile().toString());
						saveProperties();
					}
					else
					{
						String parent = jc.getSelectedFile().getParent();
						setWorkingDirectory(parent);
						setSecondaryText(parent);
						saveProperties();
					}
				}
			}
			else if ((e.getActionCommand().equals(Messages.getString("Gui.BS.DOS"))) || //$NON-NLS-1$
					(e.getActionCommand().equals(Messages.getString("Gui.BS.DOS2"))) || //$NON-NLS-1$
					(e.getActionCommand().equals(Messages.getString("Gui.BS.ProDOS"))) || //$NON-NLS-1$
					(e.getActionCommand().equals(Messages.getString("Gui.BS.ProDOSFast"))) || //$NON-NLS-1
					(e.getActionCommand().equals(Messages.getString("Gui.BS.ProDOSVSDrive"))) || //$NON-NLS-1
					(e.getActionCommand().equals(Messages.getString("Gui.BS.ADT"))) || //$NON-NLS-1$
					(e.getActionCommand().equals(Messages.getString("Gui.BS.ADTPro"))) || //$NON-NLS-1$
					(e.getActionCommand().equals(Messages.getString("Gui.BS.ADTProAudio"))) || //$NON-NLS-1$
					(e.getActionCommand().equals(Messages.getString("Gui.BS.ADTProEthernet")))) //$NON-NLS-1$
			{
				int size = _commsThread.requestSend(e.getActionCommand());
				int speed = 2400;
				int pacing = 250;
				try
				{
					speed = Integer.parseInt(_properties.getProperty("CommPortBootstrapSpeed"));
				}
				catch (NumberFormatException e2)
				{
					speed = 2400;
				}
				try
				{
					pacing = Integer.parseInt(_properties.getProperty("CommPortBootstrapPacing"));
				}
				catch (NumberFormatException e2)
				{
					pacing = 250;
				}
				Log.println(false, "Gui.actionPerformed getting instructions with speed = " + speed + " pacing = " + pacing);
				message = _commsThread.getInstructions(e.getActionCommand(), size, speed);
				/* Ask the user if she is sure */
				int ret = JOptionPane.showOptionDialog(_parent, message, Messages.getString("Gui.Name"), JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE, null, buttons, buttons[0]);
				if (ret == JOptionPane.YES_OPTION)
				{
					_commsThread.requestSend(e.getActionCommand(), true, pacing, speed);
				}
			}
			else if (e.getActionCommand().equals(Messages.getString("Gui.BS.SOS"))) //$NON-NLS-1$
			{
				int size = _commsThread.requestSend(e.getActionCommand());
				int speed = 115200;
				int pacing = 100;
				Log.println(false, "Gui.actionPerformed getting instructions with speed = " + speed + " pacing = " + pacing);
				message = _commsThread.getInstructions(e.getActionCommand(), size, speed);
				/* Ask the user if she is sure */
				int ret = JOptionPane.showOptionDialog(_parent, message, Messages.getString("Gui.Name"), JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE, null, buttons, buttons[0]);
				if (ret == JOptionPane.YES_OPTION)
				{
					_commsThread.requestSend(e.getActionCommand(), true, pacing, speed);
				}
			}
			else if (e.getActionCommand().equals(Messages.getString("Gui.AudioConfig")))
			{
				audioConfigGui();
				if (AudioConfig.getSingleton(_parent, _properties).getExitStatus() == AudioConfig.OK)
				{
					if ((_commsThread != null) && (_commsThread.transportType() == ATransport.TRANSPORT_TYPE_AUDIO))
					{
						_commsThread.setAudioParms();
					}
				}
			}
			else if (((e.getActionCommand().equals(Messages.getString("Gui.SerialConfig")))) || ((e.getActionCommand().equals(Messages.getString("Gui.SerialConfigBootstrap")))))
			{
				if ((e.getActionCommand().equals(Messages.getString("Gui.SerialConfigBootstrap"))))
				{
					serialConfigGui(1);
				}
				else
				{
					serialConfigGui(0);
				}
				if (SerialConfig.getSingleton(_parent).getExitStatus() == SerialConfig.OK)
				{
					if ((_commsThread != null) && (_commsThread.transportType() == ATransport.TRANSPORT_TYPE_SERIAL))
					{
						_commsThread.setParms(_properties.getProperty("CommPort"), Integer.parseInt(_properties.getProperty("CommPortSpeed")), _properties.getProperty("HardwareHandshaking", "false").compareTo("true") == 0);
						String msg = Messages.getString("Gui.ServingSerialTitle");
						msg = StringUtilities.replaceSubstring(msg, "%1", _properties.getProperty("CommPort"));
						msg = StringUtilities.replaceSubstring(msg, "%2", _properties.getProperty("CommPortSpeed"));
						setTitle(msg);
					}
				}
			}
			Log.println(false, "Gui.MenuAction.actionPerformed() exit.");
		}
	}

	public void requestSendFinished(String message)
	{
		JOptionPane.showMessageDialog(_parent, message, Messages.getString("Gui.BS.DoneTitle"), JOptionPane.INFORMATION_MESSAGE);
	}

	public boolean startComms(ATransport transport)
	{
		boolean success = true;
		Log.println(false, "Gui.startComms() entry.");
		if (_commsThread != null)
		{
			if (_commsThread.isBusy())
			{
				// Something is going on. Ask if we want to interrupt.
				Object[] options = { Messages.getString("Gui.Yes"), Messages.getString("Gui.No") };
				int n = JOptionPane.showOptionDialog(null, Messages.getString("Gui.Busy"), Messages.getString("Gui.BusyTitle"), JOptionPane.DEFAULT_OPTION, JOptionPane.WARNING_MESSAGE, null, options, options[0]);
				if (n != JOptionPane.YES_OPTION)
					success = false; // No == want to abort switch operation
			}
			/*
			 * If there was a comms thread existing before, get rid of it.
			 */
			if (success == true)
			{
				try
				{
					Log.println(false, "Gui.startComms() about clean up window...");
					cleanupWindow();
					Log.println(false, "Gui.startComms() about to interrupt existing comms thread...");
					_commsThread.interrupt();
					Log.println(false, "Gui.startComms() about to request stop of comms thread...");
					_commsThread.requestStop();
				}
				catch (Throwable throwable)
				{
					Log.printStackTrace(throwable);
				}
				menuBootstrap.setEnabled(false);
				_commsThread = null;
				Log.println(false, "Gui.startComms() done with old thread.");
			}
		}
		else
			Log.println(false, "Gui.startComms() didn't have an old thread to stop.");
		if ((transport != null) && (success == true))
		{
			/*
			 * They want a new thread (and associated transport).
			 */
			setMainText(Messages.getString("Gui.Quiesced")); //$NON-NLS-1$
			setSecondaryText(Messages.getString("Gui.Connected")); //$NON-NLS-1$
			clearProgress();
			_commsThread = new CommsThread(this, transport);
			_commsThread.start();
			// _commsThread.setProtocolCompatibility(_protoCompatMenuItem.isSelected());
			saveProperties();
			if (_commsThread.supportsBootstrap())
			{
				/*
				 * The types of things that support bootstrapping are Serial,
				 * Serial over IP, or Audio; Audio supports only a subset of things
				 * Serial does. Except for dosAction2... that one is Audio-only.
				 */
				menuBootstrap.setEnabled(true);
				_dosAction2.setEnabled(_commsThread.transportType() == ATransport.TRANSPORT_TYPE_AUDIO);
				_sosAction.setEnabled(_commsThread.transportType() != ATransport.TRANSPORT_TYPE_AUDIO);
				_speedibootAction.setEnabled(_commsThread.transportType() != ATransport.TRANSPORT_TYPE_AUDIO);
				_vsdrivebootAction.setEnabled(_commsThread.transportType() != ATransport.TRANSPORT_TYPE_AUDIO);
				_serialConfigBootstrapAction.setEnabled(_commsThread.transportType() != ATransport.TRANSPORT_TYPE_AUDIO);
			}
		}
		Log.println(false, "Gui.startComms() exit; returning " + success + ".");
		return success;
	}

	public void cancelCommsThread(String msgId)
	{
		// The comms thread complained the port was in use.
		_disconnectButton.doClick();
		Log.println(false, "Gui.cancelCommsThread() About to show dialog...");
		JOptionPane.showMessageDialog(this, Messages.getString(msgId));
		Log.println(false, "Gui.cancelCommsThread() Done showing dialog.");
		cleanupWindow();
		if ((msgId == "Gui.PortDoesNotExist") || (msgId == "Gui.PortInUse"))
		{
			serialConfigGui(0);
		}
	}

	public void cleanupWindow()
	{
		setMainText(Messages.getString("Gui.Quiesced")); //$NON-NLS-1$
		setSecondaryText(Messages.getString("Gui.Disconnected")); //$NON-NLS-1$
		menuBootstrap.setEnabled(false);
		clearProgress();
	}

	public void saveProperties()
	{
		/*
		 * if (_protoCompatMenuItem != null) { if
		 * (_protoCompatMenuItem.isSelected())
		 * _properties.setProperty("Client01xCompatibleProtocol", "true"); else
		 * _properties.setProperty("Client01xCompatibleProtocol", "false"); }
		 */
		if (_traceMenuItem != null)
		{
			if (_traceMenuItem.isSelected())
				_properties.setProperty("TraceEnabled", "true");
			else
				_properties.setProperty("TraceEnabled", "false");
		}
		_properties.setProperty("WorkingDirectory", getWorkingDirectory());
		Rectangle r = this.getBounds();
		if (r.height > 0)
		{
			_properties.setProperty("CoordX", "" + r.x);
			_properties.setProperty("CoordY", "" + r.y);
			_properties.setProperty("CoordH", "" + r.height);
			_properties.setProperty("CoordW", "" + r.width);
		}
		_properties.save();
	}

	public static class WindowCloseMonitor extends WindowAdapter
	{
		public void windowClosing(WindowEvent e)
		{
			Window w = e.getWindow();
			Gui parent = (Gui) e.getSource();
			parent.saveProperties();
			w.setVisible(false);
			w.dispose();
			System.exit(0);
		}
	}
}
