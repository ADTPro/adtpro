/*
 * ADTPro - Apple Disk Transfer ProDOS
 * Copyright (C) 2006 by David Schmidt
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
import java.awt.Window;
import java.awt.event.*;
import java.io.File;

import javax.swing.*;

import org.adtpro.transport.SerialTransport;
import org.adtpro.CommsThread;

/** The ADTPro graphical user interface class.
 * @author File Created By: David Schmidt &lt;david@attglobal.net&gt;
 */
public final class Gui extends JFrame implements ActionListener
{
  /**
   * 
   */
  private static final long serialVersionUID = 1L;

  Gui _parent;
  String[] portNames = SerialTransport.getPortNames();
  private JLabel labelComPort;
  private JComboBox comboComPort;
  private JLabel labelSpeed;
  private JComboBox comboSpeed;
  private JButton buttonConnect = null;
  private CommsThread commsThread;
  private SerialTransport transport;
  private String _workingDirectory = null;

  public Gui(java.lang.String[] args)
  {
    addWindowListener(new WindowCloseMonitor());
    setTitle("ADTPro Server");

    JMenuBar menuBar = new JMenuBar();
    JPanel mainPanel = new JPanel(new GridBagLayout());
    this.getContentPane().add(mainPanel, BorderLayout.CENTER);

    JMenu menuFile = new JMenu("File");
    MenuAction quitAction = new MenuAction("Quit");
    menuFile.add(quitAction);
    menuBar.add(menuFile);
    this.setJMenuBar(menuBar);

    labelComPort = new JLabel("Port", SwingConstants.LEFT);
    labelSpeed = new JLabel("Speed", SwingConstants.LEFT);
    comboComPort = new JComboBox();
    try
    {
      String[] portNames = SerialTransport.getPortNames();
      for (int i = 0; i < portNames.length; i++)
      {
        String nextName = portNames[i];
        if (nextName == null) continue;
        comboComPort.addItem(nextName);
      }
    }
    catch (Throwable t)
    {}
    comboSpeed = new JComboBox();
    comboSpeed.addItem("9600");
    comboSpeed.addItem("19200");
    comboSpeed.addItem("38400");
    comboSpeed.addItem("57600");
    comboSpeed.addItem("115200");
    comboSpeed.setSelectedItem("115200");
    buttonConnect = new JButton("Connect");
    buttonConnect.addActionListener(this);
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
        0.0, 0.0, // Weight X, Y
        0, 0, 5, 5); // Top, left, bottom, right insets
    GridBagUtil.constrain(mainPanel, buttonConnect, 3, 2, // X, Y Coordinates
        1, 1, // Grid width, height
        GridBagConstraints.HORIZONTAL, // Fill value
        GridBagConstraints.WEST, // Anchor value
        0.0, 0.0, // Weight X, Y
        0, 0, 5, 5); // Top, left, bottom, right insets

    _parent = this;
    this.pack();
    setBounds(FrameUtils.center(this.getSize()));
    this.show();
  }

  public void actionPerformed(ActionEvent e)
  {
      if (e.getSource() == buttonConnect)
      {
        startComms();
      }
  }
  
  public String getWorkingDirectory()
  {
    File baseDirFile;
    if (_workingDirectory == null)
    {
      baseDirFile = new File(".");
      _workingDirectory = baseDirFile.getAbsolutePath();
      _workingDirectory = _workingDirectory.substring(0, _workingDirectory.length() - 2);
    }
    return _workingDirectory;
  }

  public byte setWorkingDirectory(String cwd)  
  {
    byte rc = 0x48; // Unable to change directory message at Apple
    File baseDirFile = new File(cwd);
    String tempWorkingDirectory = baseDirFile.getAbsolutePath();
    //System.out.println("Absolute path of "+cwd+": ["+tempWorkingDirectory+"]");
    File[] dummy = new File(tempWorkingDirectory).listFiles();
    if (dummy != null)
    {
      _workingDirectory = tempWorkingDirectory;
      rc = 0x00;
    }
    else
    {
      tempWorkingDirectory = getWorkingDirectory() + cwd;
      baseDirFile = new File(tempWorkingDirectory);
      tempWorkingDirectory = baseDirFile.getAbsolutePath();
      dummy = new File(tempWorkingDirectory).listFiles();
      if (dummy != null)
      {
        _workingDirectory = tempWorkingDirectory;
        rc = 0x00;
      }
    }
    return rc;
  }

  public File[] getFiles()
  {
    File baseDirFile;
    baseDirFile = new File(getWorkingDirectory());
    return baseDirFile.listFiles();
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
      if (e.getActionCommand() == "Quit")
      {
        _parent.setVisible(false);
        _parent.dispose();
        System.exit(0);
      }
    }
  }

  public void startComms()
  {
    if (commsThread != null)
    {
      try
      {
        commsThread.requestStop();
        commsThread.interrupt();
      }
      catch (Throwable throwable)
      {
        System.out.println(throwable);
      }
    }
    commsThread = null;
    transport = null;
    {
      try
      {
        transport = new SerialTransport((String)comboComPort.getSelectedItem(),(String)comboSpeed.getSelectedItem());
      }
      catch (Throwable throwable)
      {
        System.out.println(throwable);
      }
      commsThread = new CommsThread(this, transport);
      commsThread.start();
    }
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
