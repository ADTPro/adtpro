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

package org.adtpro.gui;

import java.awt.BorderLayout;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Toolkit;
import java.awt.Window;
import java.awt.event.*;
import java.io.File;
import java.io.IOException;

import javax.swing.*;

import org.adtpro.resources.Messages;
import org.adtpro.transport.ATransport;
import org.adtpro.transport.SerialTransport;
import org.adtpro.utilities.Log;
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

  private JLabel labelComPort;

  private JComboBox comboComPort;

  private JLabel labelSpeed;

  private JComboBox comboSpeed;

  private JButton buttonConnect = null;

  private CommsThread _commsThread;

  private String _workingDirectory = getWorkingDirectory();

  private JProgressBar progressBar;

  private JLabel labelMainProgress, labelSubProgress;

  private ADTProperties _properties = new ADTProperties(Messages.getString("PropertiesFileName"));

  JMenu menuBootstrap;

  JMenuItem _dosAction2 = null;
  JCheckBoxMenuItem _iicMenuItem = null;
  JCheckBoxMenuItem _protoCompatMenuItem = null;
  JCheckBoxMenuItem _traceMenuItem = null;
  
  public Gui(java.lang.String[] args)
  {
    Log.getSingleton().setTrace(_properties.getProperty("TraceEnabled", "false").compareTo("true") == 0);
    Log.println(false,"Gui Constructor entry.");
    addWindowListener(new WindowCloseMonitor());
    setTitle(Messages.getString("Gui.Title") + " " + Messages.getString("Version.Number")); //$NON-NLS-1$ //$NON-NLS-2$
    try
    {
      setIconImage(Toolkit.getDefaultToolkit().getImage(getClass().getResource("/org/adtpro/resources/ADTPro.png")));
    }
    catch (Throwable ex)
    {}
    String tempDir = _properties.getProperty("WorkingDirectory", null); //$NON-NLS-1$
    if (tempDir != null) setWorkingDirectory(tempDir);

    JMenuBar menuBar = new JMenuBar();
    JPanel mainPanel = new JPanel(new GridBagLayout());
    this.getContentPane().add(mainPanel, BorderLayout.CENTER);

    JMenu menuFile = new JMenu(Messages.getString("Gui.File")); //$NON-NLS-1$
    _traceMenuItem = new JCheckBoxMenuItem(Messages.getString("Gui.Trace"));
    menuFile.add(_traceMenuItem);
    _traceMenuItem.addActionListener(this);
    _iicMenuItem = new JCheckBoxMenuItem(Messages.getString("Gui.IIc"));
    menuFile.add(_iicMenuItem);
    _iicMenuItem.addActionListener(this);
    _protoCompatMenuItem = new JCheckBoxMenuItem(Messages.getString("Gui.ProtocolCompatability"));
    menuFile.add(_protoCompatMenuItem);
    _protoCompatMenuItem.addActionListener(this);

    MenuAction cdAction = new MenuAction(Messages.getString("Gui.CD")); //$NON-NLS-1$
    menuFile.add(cdAction);
    MenuAction quitAction = new MenuAction(Messages.getString("Gui.Quit")); //$NON-NLS-1$
    menuFile.add(quitAction);
    menuBar.add(menuFile);
    menuBootstrap = new JMenu(Messages.getString("Gui.Bootstrap")); //$NON-NLS-1$
    MenuAction dosAction = new MenuAction(Messages.getString("Gui.BS.DOS")); //$NON-NLS-1$
    menuBootstrap.add(dosAction);
    MenuAction dosAction2 = new MenuAction(Messages.getString("Gui.BS.DOS2")); //$NON-NLS-1$
    _dosAction2 = menuBootstrap.add(dosAction2);
    _dosAction2.setEnabled(true);
    MenuAction adtAction = new MenuAction(Messages.getString("Gui.BS.ADT")); //$NON-NLS-1$
    menuBootstrap.add(adtAction);
    MenuAction adtProAction = new MenuAction(Messages.getString("Gui.BS.ADTPro")); //$NON-NLS-1$
    menuBootstrap.add(adtProAction);
    MenuAction adtProAudioAction = new MenuAction(Messages.getString("Gui.BS.ADTProAudio")); //$NON-NLS-1$
    menuBootstrap.add(adtProAudioAction);
    MenuAction adtProEthernetAction = new MenuAction(Messages.getString("Gui.BS.ADTProEthernet")); //$NON-NLS-1$
    menuBootstrap.add(adtProEthernetAction);
    menuBar.add(menuBootstrap);
    menuBootstrap.setEnabled(false);
    JMenu menuHelp = new JMenu(Messages.getString("Gui.Help")); //$NON-NLS-1$
    MenuAction aboutAction = new MenuAction(Messages.getString("Gui.About")); //$NON-NLS-1$
    menuHelp.add(aboutAction);
    menuBar.add(menuHelp);
    this.setJMenuBar(menuBar);

    labelComPort = new JLabel(Messages.getString("Gui.Port"), SwingConstants.LEFT); //$NON-NLS-1$
    labelSpeed = new JLabel(Messages.getString("Gui.Speed"), SwingConstants.LEFT); //$NON-NLS-1$
    comboComPort = new JComboBox();
    try
    {
      Log.println(false,"Gui Constructor about to attempt to instantiate rxtx library.");
      Log.print(true, Messages.getString("Gui.RXTX")); //$NON-NLS-1$
      String[] portNames = SerialTransport.getPortNames();
      for (int i = 0; i < portNames.length; i++)
      {
        String nextName = portNames[i];
        if (nextName == null) continue;
        comboComPort.addItem(nextName);
      }
    }
    catch (Throwable t)
    {
      Log.println(true, Messages.getString("Gui.NoRXTX")); //$NON-NLS-1$
    }
    Log.println(false,"Gui Constructor completed instantiating rxtx library.");
    comboComPort.addItem(Messages.getString("Gui.Ethernet"));
    comboComPort.addItem(Messages.getString("Gui.Audio"));
    comboComPort.setSelectedItem(_properties.getProperty("CommPort", "COM1")); //$NON-NLS-1$ //$NON-NLS-2$

    comboSpeed = new JComboBox();
    comboSpeed.addItem("9600"); //$NON-NLS-1$
    comboSpeed.addItem("19200"); //$NON-NLS-1$
    comboSpeed.addItem("115200"); //$NON-NLS-1$

    comboSpeed.setSelectedItem(_properties.getProperty("CommPortSpeed", "115200")); //$NON-NLS-1$ //$NON-NLS-2$

    _iicMenuItem.setSelected(_properties.getProperty("HardwareHandshaking", "false").compareTo("true") == 0); //$NON-NLS-1$ //$NON-NLS-2$
    _protoCompatMenuItem.setSelected(_properties.getProperty("Client01xCompatibleProtocol", "false").compareTo("true") == 0); //$NON-NLS-1$ //$NON-NLS-2$
    _traceMenuItem.setSelected(_properties.getProperty("TraceEnabled", "false").compareTo("true") == 0); //$NON-NLS-1$ //$NON-NLS-2$
    //Log.getSingleton().setTrace(_traceMenuItem.isSelected());

    buttonConnect = new JButton(Messages.getString("Gui.Disconnect")); //$NON-NLS-1$
    buttonConnect.addActionListener(this);

    labelMainProgress = new JLabel(Messages.getString("Gui.Quiesced")); //$NON-NLS-1$
    labelSubProgress = new JLabel(Messages.getString("Gui.Disconnected")); //$NON-NLS-1$
    progressBar = new JProgressBar();
    progressBar.setString(""); //$NON-NLS-1$
    progressBar.setMaximum(280);
    progressBar.setValue(0);
    progressBar.setStringPainted(true);

    this.getRootPane().setDefaultButton(buttonConnect);

    GridBagUtil.constrain(mainPanel, labelComPort, 1, 1, // X, Y Coordinates
        1, 1, // Grid width, height
        GridBagConstraints.NONE, // Fill value
        GridBagConstraints.WEST, // Anchor value
        0.0, 0.0, // Weight X, Y
        5, 5, 0, 0); // Top, left, bottom, right insets
    GridBagUtil.constrain(mainPanel, comboComPort, 1, 2, // X, Y Coordinates
        1, 1, // Grid width, height
        GridBagConstraints.HORIZONTAL, // Fill value
        GridBagConstraints.WEST, // Anchor value
        0.0, 0.0, // Weight X, Y
        0, 5, 5, 5); // Top, left, bottom, right insets
    GridBagUtil.constrain(mainPanel, labelSpeed, 2, 1, // X, Y Coordinates
        1, 1, // Grid width, height
        GridBagConstraints.NONE, // Fill value
        GridBagConstraints.WEST, // Anchor value
        0.0, 0.0, // Weight X, Y
        5, 5, 0, 0); // Top, left, bottom, right insets
    GridBagUtil.constrain(mainPanel, comboSpeed, 2, 2, // X, Y Coordinates
        1, 1, // Grid width, height
        GridBagConstraints.HORIZONTAL, // Fill value
        GridBagConstraints.WEST, // Anchor value
        1.0, 0.0, // Weight X, Y
        0, 0, 5, 5); // Top, left, bottom, right insets
    GridBagUtil.constrain(mainPanel, buttonConnect, 3, 2, // X, Y Coordinates
        1, 1, // Grid width, height
        GridBagConstraints.HORIZONTAL, // Fill value
        GridBagConstraints.WEST, // Anchor value
        0.0, 0.0, // Weight X, Y
        0, 0, 5, 5); // Top, left, bottom, right insets
    GridBagUtil.constrain(mainPanel, labelMainProgress, 1, 3, // X, Y
        // Coordinates
        3, 1, // Grid width, height
        GridBagConstraints.HORIZONTAL, // Fill value
        GridBagConstraints.WEST, // Anchor value
        0.0, 0.0, // Weight X, Y
        0, 5, 5, 5); // Top, left, bottom, right insets
    GridBagUtil.constrain(mainPanel, progressBar, 1, 4, // X, Y Coordinates
        3, 1, // Grid width, height
        GridBagConstraints.HORIZONTAL, // Fill value
        GridBagConstraints.WEST, // Anchor value
        0.0, 0.0, // Weight X, Y
        0, 5, 5, 5); // Top, left, bottom, right insets
    GridBagUtil.constrain(mainPanel, labelSubProgress, 1, 5, // X, Y
        // Coordinates
        3, 1, // Grid width, height
        GridBagConstraints.HORIZONTAL, // Fill value
        GridBagConstraints.WEST, // Anchor value
        0.0, 0.0, // Weight X, Y
        0, 5, 5, 5); // Top, left, bottom, right insets

    _parent = this;
    this.pack();
    setBounds(FrameUtils.center(this.getSize()));
    buttonConnect.setText(Messages.getString("Gui.Connect")); //$NON-NLS-1$
    buttonConnect.requestFocus();
    this.show();
    Log.println(false,"Gui Constructor exit.");
  }

  public void actionPerformed(ActionEvent e)
  {
    Log.println(false,"Gui.actionPerformed() entry, responding to "+e.getActionCommand());
    if (e.getSource() == buttonConnect)
    {
      startComms();
    }
    else if (e.getActionCommand().equals(Messages.getString("Gui.IIc"))) //$NON-NLS-1$
    {
      if (_commsThread != null)
      {
        _commsThread.setHardwareHandshaking(_iicMenuItem.isSelected());
      }
      saveProperties();
    }
    else if (e.getActionCommand().equals(Messages.getString("Gui.ProtocolCompatability"))) //$NON-NLS-1$
    {
      if (_commsThread != null)
      {
        _commsThread.setProtocolCompatibility(_protoCompatMenuItem.isSelected());
      }
      saveProperties();
    }
    else if (e.getActionCommand().equals(Messages.getString("Gui.Trace"))) //$NON-NLS-1$
    {
      Log.getSingleton().setTrace(_traceMenuItem.isSelected());
      saveProperties();
    }
    Log.println(false,"Gui.actionPerformed() exit.");
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
    return _workingDirectory;
  }

  public byte setWorkingDirectory(String cwd)
  {
    byte rc = 0x06; // Unable to change directory message at Apple
    cwd = cwd.trim();
    File parentDir;
    if (cwd.equals("/") || cwd.equals("\\")) parentDir = null;
    else
      parentDir = new File(_workingDirectory);
    if ((cwd.startsWith("/") || cwd.startsWith("\\"))) parentDir = null;

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
      _workingDirectory = tempWorkingDirectory;
      saveProperties();
      rc = 0x00;
    }
    return rc;
  }

  public File[] getFiles()
  {
    File baseDirFile;
    baseDirFile = new File(getWorkingDirectory());
    return baseDirFile.listFiles();
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

  public void setWindowTitle(String text)
  {
    setTitle(text);
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
       * If they want a blank label, we have to give it a little text and hide
       * it by making it the same color as the background. Otherwise, things get
       * re-laid out and compressed strangely.
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
      Object buttons[] =
      { Messages.getString("Gui.Ok"), Messages.getString("Gui.Cancel") };
      String message;
      Log.println(false,"Gui.MenuAction.actionPerformed() responding to "+e.getActionCommand());
      if (e.getActionCommand().equals(Messages.getString("Gui.Quit"))) //$NON-NLS-1$
      {
        setVisible(false);
        dispose();
        System.exit(0);
      }
      else
        if (e.getActionCommand().equals(Messages.getString("Gui.About"))) //$NON-NLS-1$
        {
          JOptionPane.showMessageDialog(null, Messages.getString("Gui.AboutText"), Messages.getString("Gui.About"),
              JOptionPane.INFORMATION_MESSAGE);
        }
        else
          if (e.getActionCommand().equals(Messages.getString("Gui.CD"))) //$NON-NLS-1$
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
                setSecondaryText(Messages.getString("Gui.InvalidCD"));
            }
          }
          else
            if ((e.getActionCommand().equals(Messages.getString("Gui.BS.DOS"))) || //$NON-NLS-1$
                (e.getActionCommand().equals(Messages.getString("Gui.BS.DOS2"))) || //$NON-NLS-1$
                (e.getActionCommand().equals(Messages.getString("Gui.BS.ADT"))) || //$NON-NLS-1$
                (e.getActionCommand().equals(Messages.getString("Gui.BS.ADTPro"))) || //$NON-NLS-1$
                (e.getActionCommand().equals(Messages.getString("Gui.BS.ADTProAudio"))) || //$NON-NLS-1$
                (e.getActionCommand().equals(Messages.getString("Gui.BS.ADTProEthernet")))) //$NON-NLS-1$
            {
              int size = _commsThread.requestSend(e.getActionCommand(), false);
              message = _commsThread.getInstructions(e.getActionCommand(), size);
              /* Ask the user if she is sure */
              int ret = JOptionPane.showOptionDialog(_parent, message, Messages.getString("Gui.Name"),
                  JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE, null, buttons, buttons[0]);
              if (ret == JOptionPane.YES_OPTION)
              {
                _commsThread.requestSend(e.getActionCommand(),true);
              }
            }
      Log.println(false,"Gui.MenuAction.actionPerformed() exit.");
    }
  }

  public void startComms()
  {
    Log.println(false,"Gui.startComms() entry.");
    if (_commsThread != null)
    {
      try
      {
        Log.println(false,"Gui.startComms() about to interrupt existing comms thread...");
        _commsThread.interrupt();
        Log.println(false,"Gui.startComms() about to request stop of comms thread...");
        _commsThread.requestStop();
        Log.println(false,"Gui.startComms() about clean up after thread...");
        cleanupCommsThread();
      }
      catch (Throwable throwable)
      {
        Log.printStackTrace(throwable);
      }
      comboComPort.setEnabled(true);
      comboSpeed.setEnabled(true);
      menuBootstrap.setEnabled(false);
      setTitle(Messages.getString("Gui.Title") + " " + Messages.getString("Version.Number")); //$NON-NLS-1$ //$NON-NLS-2$
      Log.println(false,"Gui.startComms() done with old thread.");
    }
    else
    {
      _commsThread = new CommsThread(this, (String) comboComPort.getSelectedItem(), (String) comboSpeed.getSelectedItem());
      _commsThread.start();
      _commsThread.setHardwareHandshaking(_iicMenuItem.isSelected());
      _commsThread.setHardwareHandshaking(_iicMenuItem.isSelected());
      _commsThread.setProtocolCompatibility(_protoCompatMenuItem.isSelected());
      setMainText(Messages.getString("Gui.Quiesced")); //$NON-NLS-1$
      setSecondaryText(Messages.getString("Gui.Connected")); //$NON-NLS-1$
      buttonConnect.setText(Messages.getString("Gui.Disconnect")); //$NON-NLS-1$
      clearProgress();
      saveProperties();
      comboComPort.setEnabled(false);
      comboSpeed.setEnabled(false);
      if (_commsThread.supportsBootstrap())
      {
        menuBootstrap.setEnabled(true);
        _dosAction2.setEnabled(_commsThread.transportType() == ATransport.TRANSPORT_TYPE_AUDIO);
      }
    }
    Log.println(false,"Gui.startComms() exit.");
  }

  public void cancelCommsThread()
  {
    // The comms thread complained the port was in use.
    JOptionPane.showMessageDialog(this, Messages.getString("Gui.PortInUse"));
    menuBootstrap.setEnabled(false);
    cleanupCommsThread();
  }

  public void cleanupCommsThread()
  {
    _commsThread = null;
    setMainText(Messages.getString("Gui.Quiesced")); //$NON-NLS-1$
    setSecondaryText(Messages.getString("Gui.Disconnected")); //$NON-NLS-1$
    buttonConnect.setText(Messages.getString("Gui.Connect")); //$NON-NLS-1$
    clearProgress();
    comboComPort.setEnabled(true);
    comboSpeed.setEnabled(true);
  }

  public void saveProperties()
  {
    if (comboComPort != null) _properties.setProperty("CommPort", (String) comboComPort.getSelectedItem());
    if (comboSpeed != null) _properties.setProperty("CommPortSpeed", (String) comboSpeed.getSelectedItem());
    if (_iicMenuItem != null)
    {
      if (_iicMenuItem.isSelected())
        _properties.setProperty("HardwareHandshaking","true");
      else
        _properties.setProperty("HardwareHandshaking","false");
    }
    if (_protoCompatMenuItem != null)
    {
      if (_protoCompatMenuItem.isSelected())
        _properties.setProperty("Client01xCompatibleProtocol","true");
      else
        _properties.setProperty("Client01xCompatibleProtocol","false");
    }
    if (_traceMenuItem != null)
    {
      if (_traceMenuItem.isSelected())
        _properties.setProperty("TraceEnabled","true");
      else
        _properties.setProperty("TraceEnabled","false");
    }
    _properties.setProperty("WorkingDirectory", getWorkingDirectory());
    _properties.save();
  }

  public static class WindowCloseMonitor extends WindowAdapter
  {
    public void windowClosing(WindowEvent e)
    {
      Window w = e.getWindow();
      w.setVisible(false);
      w.dispose();
      System.exit(0);
    }
  }
}
