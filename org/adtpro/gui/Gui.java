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
import java.awt.Insets;
import java.awt.Rectangle;
import java.awt.Toolkit;
import java.awt.Window;
import java.awt.event.*;
import java.io.File;
import java.io.IOException;
import java.net.InetAddress;

import javax.swing.*;

import org.adtpro.resources.Messages;
import org.adtpro.transport.ATransport;
import org.adtpro.transport.AudioTransport;
import org.adtpro.transport.SerialTransport;
import org.adtpro.transport.UDPTransport;
import org.adtpro.utilities.BareBonesBrowserLaunch;
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

  private CommsThread _commsThread;

  private String _workingDirectory = getWorkingDirectory();

  private JProgressBar progressBar;

  private JLabel labelMainProgress, labelSubProgress;

  private ADTProperties _properties = new ADTProperties(Messages.getString("PropertiesFileName"));

  JMenu menuBootstrap;

  JMenuItem _dosAction2 = null;

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
    {}
    String tempDir = _properties.getProperty("WorkingDirectory", null); //$NON-NLS-1$
    if (tempDir != null) setWorkingDirectory(tempDir);

    JMenuBar menuBar = new JMenuBar();
    JPanel mainPanel = new JPanel(new GridBagLayout());
    this.getContentPane().add(mainPanel, BorderLayout.CENTER);

    JMenu menuFile = new JMenu(Messages.getString("Gui.File")); //$NON-NLS-1$
    MenuAction serialConfigAction = new MenuAction(Messages.getString("Gui.SerialConfig")); //$NON-NLS-1$
    menuFile.add(serialConfigAction);
    MenuAction cdAction = new MenuAction(Messages.getString("Gui.CD")); //$NON-NLS-1$
    menuFile.add(cdAction);
    _traceMenuItem = new JCheckBoxMenuItem(Messages.getString("Gui.Trace"));
    menuFile.add(_traceMenuItem);
    _traceMenuItem.addActionListener(this);
    _protoCompatMenuItem = new JCheckBoxMenuItem(Messages.getString("Gui.ProtocolCompatability"));
    menuFile.add(_protoCompatMenuItem);
    _protoCompatMenuItem.addActionListener(this);
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
    MenuAction helpAction = new MenuAction(Messages.getString("Gui.Website")); //$NON-NLS-1$
    menuHelp.add(helpAction);
    MenuAction aboutAction = new MenuAction(Messages.getString("Gui.About")); //$NON-NLS-1$
    menuHelp.add(aboutAction);
    menuBar.add(menuHelp);
    this.setJMenuBar(menuBar);

    _protoCompatMenuItem
        .setSelected(_properties.getProperty("Client01xCompatibleProtocol", "false").compareTo("true") == 0); //$NON-NLS-1$ //$NON-NLS-2$
    _traceMenuItem.setSelected(_properties.getProperty("TraceEnabled", "false").compareTo("true") == 0); //$NON-NLS-1$ //$NON-NLS-2$
    // Log.getSingleton().setTrace(_traceMenuItem.isSelected());

    labelMainProgress = new JLabel(Messages.getString("Gui.Quiesced")); //$NON-NLS-1$
    labelSubProgress = new JLabel(Messages.getString("Gui.Disconnected")); //$NON-NLS-1$
    progressBar = new JProgressBar();
    progressBar.setString(""); //$NON-NLS-1$
    progressBar.setMaximum(280);
    progressBar.setValue(0);
    progressBar.setStringPainted(true);

    _serialButton = new JRadioButton("Serial", new ImageIcon(Toolkit.getDefaultToolkit().getImage(
        getClass().getResource("/org/adtpro/resources/serialDeselected.png"))));
    _serialButton.setHorizontalTextPosition(SwingConstants.CENTER);
    _serialButton.setVerticalTextPosition(SwingConstants.BOTTOM);
    _serialButton.setMargin(new Insets(0, 0, 0, 0));
    _serialButton.setSelectedIcon(new ImageIcon(Toolkit.getDefaultToolkit().getImage(
        getClass().getResource("/org/adtpro/resources/serialSelected.png"))));
    _serialButton.addActionListener(this);
    _ethernetButton = new JRadioButton("Ethernet", new ImageIcon(Toolkit.getDefaultToolkit().getImage(
        getClass().getResource("/org/adtpro/resources/ethernetDeselected.png"))));
    _ethernetButton.setHorizontalTextPosition(SwingConstants.CENTER);
    _ethernetButton.setVerticalTextPosition(SwingConstants.BOTTOM);
    _ethernetButton.setMargin(new Insets(0, 0, 0, 0));
    _ethernetButton.setSelectedIcon(new ImageIcon(Toolkit.getDefaultToolkit().getImage(
        getClass().getResource("/org/adtpro/resources/ethernetSelected.png"))));
    _ethernetButton.addActionListener(this);
    _audioButton = new JRadioButton("Audio", new ImageIcon(Toolkit.getDefaultToolkit().getImage(
        getClass().getResource("/org/adtpro/resources/audioDeselected.png"))));
    _audioButton.setHorizontalTextPosition(SwingConstants.CENTER);
    _audioButton.setVerticalTextPosition(SwingConstants.BOTTOM);
    _audioButton.setMargin(new Insets(0, 0, 0, 0));
    _audioButton.setSelectedIcon(new ImageIcon(Toolkit.getDefaultToolkit().getImage(
        getClass().getResource("/org/adtpro/resources/audioSelected.png"))));
    _audioButton.addActionListener(this);
    _disconnectButton = new JRadioButton("Disconnect", new ImageIcon(Toolkit.getDefaultToolkit().getImage(
        getClass().getResource("/org/adtpro/resources/disconnectDeselected.png"))));
    _disconnectButton.setHorizontalTextPosition(SwingConstants.CENTER);
    _disconnectButton.setVerticalTextPosition(SwingConstants.BOTTOM);
    _disconnectButton.setMargin(new Insets(0, 0, 0, 0));
    _disconnectButton.setSelectedIcon(new ImageIcon(Toolkit.getDefaultToolkit().getImage(
        getClass().getResource("/org/adtpro/resources/disconnectSelected.png"))));
    _disconnectButton.addActionListener(this);
    ButtonGroup bg = new ButtonGroup();
    bg.add(_serialButton);
    bg.add(_ethernetButton);
    bg.add(_audioButton);
    bg.add(_disconnectButton);

    GridBagUtil.constrain(mainPanel, _serialButton, 1, 1, // X, Y Coordinates
        1, 1, // Grid width, height
        GridBagConstraints.HORIZONTAL, // Fill value
        GridBagConstraints.WEST, // Anchor value
        0.0, 0.0, // Weight X, Y
        5, 5, 5, 0); // Top, left, bottom, right insets
    GridBagUtil.constrain(mainPanel, _ethernetButton, 2, 1, // X, Y Coordinates
        1, 1, // Grid width, height
        GridBagConstraints.HORIZONTAL, // Fill value
        GridBagConstraints.WEST, // Anchor value
        0.0, 0.0, // Weight X, Y
        5, 10, 5, 0); // Top, left, bottom, right insets
    GridBagUtil.constrain(mainPanel, _audioButton, 3, 1, // X, Y Coordinates
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
    _disconnectButton.requestFocus();
    _disconnectButton.doClick();
    _previousButton = _disconnectButton; // Remember last button state

    int coord = Integer.parseInt(_properties.getProperty("CoordH", "0"));
    if (coord > 0)
    {
      Rectangle r = new Rectangle(
          Integer.parseInt(_properties.getProperty("CoordX", "0")),
          Integer.parseInt(_properties.getProperty("CoordY", "0")),
          Integer.parseInt(_properties.getProperty("CoordW", "0")),
          Integer.parseInt(_properties.getProperty("CoordH", "0")));
      if (((r.height == 0) || (r.width == 0)) || // Anything was zero
          (!FrameUtils.fits(r))) // Dimensions put us outside current view
      {
        Log.println(false,"Gui setting screen coordinates to defaults; properties file coords weren't good.");
        setBounds(FrameUtils.center(this.getSize()));
      }
      else
      {
        Log.println(false,"Gui setting screen coordinates from properties file values.");
        setBounds(r);
      }
    }
    else
    {
      Log.println(false,"Gui setting screen coordinates to defaults; properties file height was zero.");
      setBounds(FrameUtils.center(this.getSize()));
    }
    this.show();
    SerialConfig.getSingleton();
    Log.println(false, "Gui Constructor exit.");
  }

  public void actionPerformed(ActionEvent e)
  {
    Log.println(false, "Gui.actionPerformed() entry, responding to " + e.getActionCommand());
    if ((e.getSource() == _serialButton) && (_previousButton != _serialButton))
    {
      _previousButton = _serialButton;
      if ((_properties.getProperty("CommPortSpeed") == null) ||
          (_properties.getProperty("CommPort") == null))
      {
        serialConfigGui();
        if (SerialConfig.getSingleton().getExitStatus() == SerialConfig.OK)
        {
          try
          {
            String msg = Messages.getString("Gui.ServingSerialTitle");
            msg = msg.replaceAll("%1",_properties.getProperty("CommPort"));
            msg = msg.replaceAll("%2",_properties.getProperty("CommPortSpeed"));
            setTitle(msg);
            startComms(new SerialTransport(SerialConfig.getPort(), SerialConfig.getSpeed(), SerialConfig.getHardware()));
          }
          catch (Exception e1)
          {
            Log.printStackTrace(e1);
            _disconnectButton.doClick();
          }
        }
        else
        {
          _disconnectButton.doClick();
          _previousButton = _disconnectButton;
        }
      }
      else
      {
        try
        {
          String msg = Messages.getString("Gui.ServingSerialTitle");
          msg = msg.replaceAll("%1",_properties.getProperty("CommPort"));
          msg = msg.replaceAll("%2",_properties.getProperty("CommPortSpeed"));
          setTitle(msg);
          startComms(new SerialTransport(_properties.getProperty("CommPort"), _properties.getProperty("CommPortSpeed"), _properties.getProperty("HardwareHandshaking", "false").compareTo("true") == 0));
        }
        catch (Exception e1)
        {
          Log.printStackTrace(e1);
          _disconnectButton.doClick();
        }
      }
    }
    else
      if ((e.getSource() == _ethernetButton) && (_previousButton != _ethernetButton))
      {
        _previousButton = _ethernetButton;
        try
        {
          String msg = Messages.getString("Gui.ServingEthernetTitle");
          msg = msg.replaceAll("%1",InetAddress.getLocalHost().getHostAddress());
          setTitle(msg);
          startComms(new UDPTransport("6502"));
        }
        catch (Exception e1)
        {
          Log.printStackTrace(e1);
          setTitle(Messages.getString("Gui.Title") + " " + Messages.getString("Version.Number")); //$NON-NLS-1$ //$NON-NLS-2$
          _disconnectButton.doClick();
        }
      }
      else
        if ((e.getSource() == _audioButton) && (_previousButton != _audioButton))
        {
          setTitle(Messages.getString("Gui.Title") + " " + Messages.getString("Version.Number")); //$NON-NLS-1$ //$NON-NLS-2$
          setTitle(Messages.getString("Gui.ServingAudioTitle"));
          _previousButton = _audioButton;
          startComms(new AudioTransport());
        }
        else
          if ((e.getSource() == _disconnectButton) && (_previousButton != _disconnectButton))
          {
            setTitle(Messages.getString("Gui.Title") + " " + Messages.getString("Version.Number")); //$NON-NLS-1$ //$NON-NLS-2$
            _previousButton = _disconnectButton;
            startComms(null);
          }
        else
          if (e.getActionCommand().equals(Messages.getString("Gui.ProtocolCompatability"))) //$NON-NLS-1$
          {
            if (_commsThread != null)
            {
              _commsThread.setProtocolCompatibility(_protoCompatMenuItem.isSelected());
            }
            saveProperties();
          }
          else
            if (e.getActionCommand().equals(Messages.getString("Gui.Trace"))) //$NON-NLS-1$
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
    return _workingDirectory;
  }

  public void serialConfigGui()
  {
    SerialConfig.getSingleton();
    SerialConfig.setProperties(_properties);
    SerialConfig.showSingleton(this);
  }

  public byte setWorkingDirectory(String cwd)
  {
    byte rc = 0x06; // Unable to change directory message at Apple
    cwd = cwd.trim();
    File parentDir;
    System.out.println("cwd: "+cwd);
    System.out.println("_workingDirectory: "+_workingDirectory);
    if (cwd.equals("/") || cwd.equals("\\")) parentDir = null;
    else
      parentDir = new File(_workingDirectory);
    if ((cwd.startsWith("/") || cwd.startsWith("\\"))) parentDir = null;
    System.out.println("parentDir: "+parentDir);

    File baseDirFile = new File(parentDir, cwd);
    System.out.println("baseDirFile: "+baseDirFile);
    String tempWorkingDirectory = null;
    try
    {
      tempWorkingDirectory = baseDirFile.getCanonicalPath();
      baseDirFile = new File(tempWorkingDirectory);
      System.out.println("baseDirFile2: "+baseDirFile);
      if (!baseDirFile.isDirectory())
      {
        tempWorkingDirectory = null;
      }
    }
    catch (IOException io)
    {
      System.out.println("io exception...");
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
      Log.println(false, "Gui.MenuAction.actionPerformed() responding to " + e.getActionCommand());
      if (e.getActionCommand().equals(Messages.getString("Gui.Quit"))) //$NON-NLS-1$
      {
        saveProperties();
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
          if (e.getActionCommand().equals(Messages.getString("Gui.Website"))) //$NON-NLS-1$
          {
            BareBonesBrowserLaunch.openURL("http://adtpro.sourceforge.net");
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
                  _commsThread.requestSend(e.getActionCommand(), true);
                }
              }
              else
                if ((e.getActionCommand().equals(Messages.getString("Gui.SerialConfig"))))
                {
                  serialConfigGui();
                  if (SerialConfig.getSingleton().getExitStatus() == SerialConfig.OK)
                  {
                    if ((_commsThread != null) && (_commsThread.transportType() == ATransport.TRANSPORT_TYPE_SERIAL))
                    {
                      _commsThread.setParms(_properties.getProperty("CommPort"),Integer.parseInt(_properties.getProperty("CommPortSpeed")),_properties.getProperty("HardwareHandshaking", "false").compareTo("true") == 0);
                      String msg = Messages.getString("Gui.ServingSerialTitle");
                      msg = msg.replaceAll("%1",_properties.getProperty("CommPort"));
                      msg = msg.replaceAll("%2",_properties.getProperty("CommPortSpeed"));
                      setTitle(msg);
                    }
                  }
                }
      Log.println(false, "Gui.MenuAction.actionPerformed() exit.");
    }
  }

  public void startComms(ATransport transport)
  {
    Log.println(false, "Gui.startComms() entry.");
    if (_commsThread != null)
    {
      try
      {
        Log.println(false, "Gui.startComms() about to interrupt existing comms thread...");
        _commsThread.interrupt();
        Log.println(false, "Gui.startComms() about to request stop of comms thread...");
        _commsThread.requestStop();
        Log.println(false, "Gui.startComms() about clean up after thread...");
        cleanupCommsThread();
      }
      catch (Throwable throwable)
      {
        Log.printStackTrace(throwable);
      }
      menuBootstrap.setEnabled(false);
      Log.println(false, "Gui.startComms() done with old thread.");
    }
    if (transport != null)
    {
      _commsThread = new CommsThread(this, transport);
      _commsThread.start();
      _commsThread.setProtocolCompatibility(_protoCompatMenuItem.isSelected());
      setMainText(Messages.getString("Gui.Quiesced")); //$NON-NLS-1$
      setSecondaryText(Messages.getString("Gui.Connected")); //$NON-NLS-1$
      clearProgress();
      saveProperties();
      if (_commsThread.supportsBootstrap())
      {
        menuBootstrap.setEnabled(true);
        _dosAction2.setEnabled(_commsThread.transportType() == ATransport.TRANSPORT_TYPE_AUDIO);
      }
    }
    else
      Log.println(false, "Gui.startComms() didn't find anything to do...");
    Log.println(false, "Gui.startComms() exit.");
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
    clearProgress();
  }

  public void saveProperties()
  {
    if (_protoCompatMenuItem != null)
    {
      if (_protoCompatMenuItem.isSelected()) _properties.setProperty("Client01xCompatibleProtocol", "true");
      else
        _properties.setProperty("Client01xCompatibleProtocol", "false");
    }
    if (_traceMenuItem != null)
    {
      if (_traceMenuItem.isSelected()) _properties.setProperty("TraceEnabled", "true");
      else
        _properties.setProperty("TraceEnabled", "false");
    }
    _properties.setProperty("WorkingDirectory", getWorkingDirectory());
    Rectangle r = this.getBounds();
    if (r.height > 0)
    {
      _properties.setProperty("CoordX", ""+r.x);
      _properties.setProperty("CoordY", ""+r.y);
      _properties.setProperty("CoordH", ""+r.height);
      _properties.setProperty("CoordW", ""+r.width);
    }
    _properties.save();
  }

  public static class WindowCloseMonitor extends WindowAdapter
  {
    public void windowClosing(WindowEvent e)
    {
      Window w = e.getWindow();
      Gui parent = (Gui)e.getSource();
      parent.saveProperties();
      w.setVisible(false);
      w.dispose();
      System.exit(0);
    }
  }
}
