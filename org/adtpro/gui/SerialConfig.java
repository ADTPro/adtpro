/*
 * ADTPro - Apple Disk Transfer ProDOS
 * Copyright (C) 2007 - 2015 by David Schmidt
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
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.KeyAdapter;
import java.awt.event.KeyEvent;

import javax.swing.JButton;
import javax.swing.JCheckBox;
import javax.swing.JComboBox;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JTabbedPane;
import javax.swing.SwingConstants;

import org.adtpro.resources.Messages;
import org.adtpro.transport.SerialTransport;
import org.adtpro.utilities.Log;
import org.adtpro.ADTProperties;

public class SerialConfig extends JDialog implements ActionListener
{
  /**
   * 
   */
  private static SerialConfig _theSingleton = null;

  JTabbedPane _tabbedPane = new JTabbedPane();

  private static final long serialVersionUID = 1L;

  private JLabel labelComPort;

  private JComboBox comboComPort;

  private JLabel labelSpeed;

  private JComboBox comboSpeed;

  private JLabel labelBootstrapPacing;

  private JComboBox comboBootstrapPacing;

  private JLabel labelBootstrapSpeed;

  private JComboBox comboBootstrapSpeed;

  private JCheckBox iicCheckBox;

  private org.adtpro.ADTProperties _properties = null;

  private int exitStatus = CANCEL;
  
  public JButton okButton = new JButton(Messages.getString("Gui.Ok"));
  public JButton cancelButton = new JButton(Messages.getString("Gui.Cancel"));
  public static Gui _parent;
  private KeyAdapter myKeyListener = new MyKeyAdapter();

  public static final int CANCEL = 0, OK = 1;

  /**
   * 
   * Private constructor - use the <code>getSingleton</code> to instantiate.
   * 
   */
  private SerialConfig()
  {
    this.setTitle(Messages.getString("Gui.SerialConfig"));
    JPanel buttonPanel = new JPanel(new GridBagLayout());
    okButton.addActionListener(this);
    cancelButton.addActionListener(this);

    GridBagUtil.constrain(buttonPanel, okButton, 1, 1, // X, Y Coordinates
        1, 1, // Grid width, height
        GridBagConstraints.NONE, // Fill value
        GridBagConstraints.WEST, // Anchor value
        0.0, 0.0, // Weight X, Y
        5, 5, 5, 5); // Top, left, bottom, right insets
    GridBagUtil.constrain(buttonPanel, cancelButton, 2, 1, // X, Y Coordinates
        1, 1, // Grid width, height
        GridBagConstraints.NONE, // Fill value
        GridBagConstraints.WEST, // Anchor value
        0.0, 0.0, // Weight X, Y
        5, 5, 5, 5); // Top, left, bottom, right insets
    JPanel configPanel = new JPanel();
    JPanel bootstrapPanel = new JPanel();
    configPanel.setLayout(new GridBagLayout());
    bootstrapPanel.setLayout(new GridBagLayout());
    this.getContentPane().setLayout(new BorderLayout());    
    this.getContentPane().add(_tabbedPane,BorderLayout.CENTER);
    this.getContentPane().add(buttonPanel,BorderLayout.SOUTH);
    Log.getSingleton();
    comboComPort = new JComboBox();
    enumeratePorts();
    comboSpeed = new JComboBox();
    comboSpeed.addItem("19200"); //$NON-NLS-1$
    comboSpeed.addItem("115200"); //$NON-NLS-1$

    comboBootstrapSpeed = new JComboBox();
    comboBootstrapSpeed.addItem("2400"); //$NON-NLS-1$
    comboBootstrapSpeed.addItem("9600"); //$NON-NLS-1$

    comboBootstrapPacing = new JComboBox();
    comboBootstrapPacing.addItem("15"); //$NON-NLS-1$
    comboBootstrapPacing.addItem("25"); //$NON-NLS-1$
    comboBootstrapPacing.addItem("50"); //$NON-NLS-1$
    comboBootstrapPacing.addItem("75"); //$NON-NLS-1$
    comboBootstrapPacing.addItem("100"); //$NON-NLS-1$
    comboBootstrapPacing.addItem("150"); //$NON-NLS-1$
    comboBootstrapPacing.addItem("250"); //$NON-NLS-1$
    comboBootstrapPacing.addItem("500"); //$NON-NLS-1$
    comboBootstrapPacing.addItem("1000"); //$NON-NLS-1$

    iicCheckBox = new JCheckBox(Messages.getString("Gui.IIc"));

    labelComPort = new JLabel(Messages.getString("Gui.Port"), SwingConstants.LEFT); //$NON-NLS-1$
    labelSpeed = new JLabel(Messages.getString("Gui.Speed"), SwingConstants.LEFT); //$NON-NLS-1$
    labelBootstrapSpeed = new JLabel(Messages.getString("Gui.BootstrapSpeed"), SwingConstants.LEFT); //$NON-NLS-1$
    labelBootstrapPacing = new JLabel(Messages.getString("Gui.BootstrapPacing"), SwingConstants.LEFT); //$NON-NLS-1$

    GridBagUtil.constrain(configPanel, labelComPort, 1, 1, // X, Y Coordinates
        1, 1, // Grid width, height
        GridBagConstraints.NONE, // Fill value
        GridBagConstraints.WEST, // Anchor value
        0.0, 0.0, // Weight X, Y
        5, 5, 0, 0); // Top, left, bottom, right insets
    GridBagUtil.constrain(configPanel, comboComPort, 1, 2, // X, Y Coordinates
        1, 1, // Grid width, height
        GridBagConstraints.HORIZONTAL, // Fill value
        GridBagConstraints.WEST, // Anchor value
        0.0, 0.0, // Weight X, Y
        0, 5, 5, 5); // Top, left, bottom, right insets
    GridBagUtil.constrain(configPanel, labelSpeed, 2, 1, // X, Y Coordinates
        1, 1, // Grid width, height
        GridBagConstraints.NONE, // Fill value
        GridBagConstraints.WEST, // Anchor value
        0.0, 0.0, // Weight X, Y
        5, 5, 0, 0); // Top, left, bottom, right insets
    GridBagUtil.constrain(configPanel, comboSpeed, 2, 2, // X, Y Coordinates
        1, 1, // Grid width, height
        GridBagConstraints.HORIZONTAL, // Fill value
        GridBagConstraints.WEST, // Anchor value
        1.0, 0.0, // Weight X, Y
        0, 5, 5, 5); // Top, left, bottom, right insets

    GridBagUtil.constrain(configPanel, iicCheckBox, 1, 3, // X, Y Coordinates
        2, 1, // Grid width, height
        GridBagConstraints.HORIZONTAL, // Fill value
        GridBagConstraints.WEST, // Anchor value
        1.0, 0.0, // Weight X, Y
        0, 0, 5, 5); // Top, left, bottom, right insets

    GridBagUtil.constrain(bootstrapPanel, labelBootstrapPacing, 1, 4, // X, Y Coordinates
        1, 1, // Grid width, height
        GridBagConstraints.NONE, // Fill value
        GridBagConstraints.WEST, // Anchor value
        0.0, 0.0, // Weight X, Y
        0, 5, 0, 5); // Top, left, bottom, right insets
    GridBagUtil.constrain(bootstrapPanel, comboBootstrapPacing, 1, 5, // X, Y Coordinates
        1, 1, // Grid width, height
        GridBagConstraints.HORIZONTAL, // Fill value
        GridBagConstraints.WEST, // Anchor value
        1.0, 0.0, // Weight X, Y
        0, 5, 5, 5); // Top, left, bottom, right insets
    GridBagUtil.constrain(bootstrapPanel, labelBootstrapSpeed, 2, 4, // X, Y Coordinates
        1, 1, // Grid width, height
        GridBagConstraints.NONE, // Fill value
        GridBagConstraints.WEST, // Anchor value
        0.0, 0.0, // Weight X, Y
        0, 5, 0, 5); // Top, left, bottom, right insets
    GridBagUtil.constrain(bootstrapPanel, comboBootstrapSpeed, 2, 5, // X, Y Coordinates
        1, 1, // Grid width, height
        GridBagConstraints.HORIZONTAL, // Fill value
        GridBagConstraints.WEST, // Anchor value
        1.0, 0.0, // Weight X, Y
        0, 5, 5, 5); // Top, left, bottom, right insets

    _tabbedPane.addTab(Messages.getString("Gui.ConfigSerialTab"), null, configPanel, Messages.getString("Gui.ConfigSerialTab.Help"));
    _tabbedPane.addTab(Messages.getString("Gui.ConfigBootstrapTab"), null, bootstrapPanel, Messages.getString("Gui.ConfigBootstrapTab.Help"));

    // Add key listeners
    _tabbedPane.addKeyListener(myKeyListener);
    comboSpeed.addKeyListener(myKeyListener);
    comboComPort.addKeyListener(myKeyListener);
    comboBootstrapPacing.addKeyListener(myKeyListener);
    comboBootstrapSpeed.addKeyListener(myKeyListener);
    cancelButton.addKeyListener(myKeyListener);
    okButton.addKeyListener(myKeyListener);
    iicCheckBox.addKeyListener(myKeyListener);

    this.pack();
    this.setBounds(FrameUtils.center(this.getSize()));
    okButton.requestFocus();
    getRootPane().setDefaultButton(okButton);

    Log.println(false,"SerialConfig Constructor exit.");
  }

  /**
   * Retrieve the single instance of this class.
   * 
   * @return Log
   */
  public static SerialConfig getSingleton(Gui parent)
  {
    _parent = parent;
    if (null == _theSingleton)
      SerialConfig.allocateSingleton(parent);
    return _theSingleton;
  }

  /**
   * getSingleton() is not synchronized, so we must check in this method to make
   * sure a concurrent getSingleton() didn't already allocate the Singleton
   * 
   * synchronized on a static method locks the class
   */
  private synchronized static void allocateSingleton(Gui parent)
  {
    if (null == _theSingleton) _theSingleton = new SerialConfig();
  }

  public static void setProperties(ADTProperties properties)
  {
    _theSingleton._properties = properties;
    _theSingleton.comboSpeed.setSelectedItem(properties.getProperty("CommPortSpeed", "115200")); //$NON-NLS-1$ //$NON-NLS-2$
    _theSingleton.iicCheckBox.setSelected(properties.getProperty("HardwareHandshaking", "false").compareTo("true") == 0); //$NON-NLS-1$ //$NON-NLS-2$
    _theSingleton.comboComPort.setSelectedItem(properties.getProperty("CommPort", "COM1")); //$NON-NLS-1$ //$NON-NLS-2$
    _theSingleton.comboBootstrapSpeed.setSelectedItem(properties.getProperty("CommPortBootstrapSpeed", "9600")); //$NON-NLS-1$ //$NON-NLS-2$
    _theSingleton.comboBootstrapPacing.setSelectedItem(properties.getProperty("CommPortBootstrapPacing", "250")); //$NON-NLS-1$ //$NON-NLS-2$
  }

  public static String getPort()
  {
    return (String)_theSingleton.comboComPort.getSelectedItem();
  }

  public static String getSpeed()
  {
    return (String)_theSingleton.comboSpeed.getSelectedItem();
  }

  public static boolean getHardware()
  {
    return (boolean)_theSingleton.iicCheckBox.isSelected();
  }

  public static void showSingleton(Gui parent, int tab)
  {
    Log.println(false,"SerialConfig.showSingleton() showing tab "+tab+".");
    _theSingleton.enumeratePorts();
    _theSingleton.setModal(true);
    _theSingleton.setBounds(FrameUtils.center(_theSingleton.getSize(),parent.getBounds()));
    _theSingleton._tabbedPane.setSelectedIndex(tab);
    _theSingleton.setVisible(true);
  }

  /* OK action: */
  /*
  {
    _commsThread.setHardwareHandshaking(_iicMenuItem.isSelected());
  */

  public void actionPerformed(ActionEvent e)
  {
    Log.println(false,"SerialConfig.actionPerformed() entry, responding to "+e.getActionCommand());
    if (e.getSource() == okButton)
    {
      String selectedPort = (String) comboComPort.getSelectedItem();
      if (selectedPort != null)
      {
        _properties.setProperty("CommPort", selectedPort);
      }
      else
      {
        // Hrm - can't find any serial stuff at all.
        JOptionPane.showMessageDialog(this, Messages.getString("Gui.NoRXTXDialogText"),
            Messages.getString("Gui.NoRXTXDialogTitle"), JOptionPane.OK_OPTION);
        _parent.setSerialAvailable(false);
      }
      _properties.setProperty("CommPortSpeed", (String) comboSpeed.getSelectedItem());
      _properties.setProperty("CommPortBootstrapPacing", (String) comboBootstrapPacing.getSelectedItem());
      _properties.setProperty("CommPortBootstrapSpeed", (String) comboBootstrapSpeed.getSelectedItem());
      if (iicCheckBox.isSelected())
        _properties.setProperty("HardwareHandshaking","true");
      else
        _properties.setProperty("HardwareHandshaking","false");
      _properties.save();
      _theSingleton.exitStatus = OK;
      this.setVisible(false);
    }
    else if (e.getSource() == cancelButton)
    {
      _theSingleton.comboSpeed.setSelectedItem(_properties.getProperty("CommPortSpeed", "115200")); //$NON-NLS-1$ //$NON-NLS-2$
      _theSingleton.iicCheckBox.setSelected(_properties.getProperty("HardwareHandshaking", "false").compareTo("true") == 0); //$NON-NLS-1$ //$NON-NLS-2$
      _theSingleton.comboComPort.setSelectedItem(_properties.getProperty("CommPort", "COM1")); //$NON-NLS-1$ //$NON-NLS-2$
      _theSingleton.exitStatus = CANCEL;
      this.setVisible(false);
    }
    Log.println(false,"SerialConfig.actionPerformed() exit.");
  }

  public void enumeratePorts()
  {
    Log.println(false,"SerialConfig.enumeratePorts() entry.");
    String previousSelection = (String) comboComPort.getSelectedItem();
    comboComPort.removeAllItems();
    try
    {
      Log.println(false, "SerialConfig.enumeratePorts() about to attempt to instantiate rxtx library.");
      String[] portNames = SerialTransport.getPortNames();
      for (int i = 0; i < portNames.length; i++)
      {
        String nextName = portNames[i];
        if (nextName == null) continue;
        if (!nextName.startsWith("LPT")) // Get rid of LPTx ports, since we're
                                         // not likely to run on parallel
                                         // hardware...
        comboComPort.addItem(nextName);
      }
      _parent.setSerialAvailable(true);
      if (previousSelection != null)
        comboComPort.setSelectedItem(previousSelection);
      Log.println(false, "SerialConfig.enumeratePorts() completed instantiating rxtx library.");
    }
    catch (Throwable t)
    {
      Log.println(true, Messages.getString("Gui.NoRXTX")); //$NON-NLS-1$
      Log.println(false, "SerialConfig Constructor could not instantiate the rxtx library.");
      _parent.setSerialAvailable(false);
    }

    Log.println(false,"SerialConfig.enumeratePorts() exit.");
  }

  public int getExitStatus()
  {
    return _theSingleton.exitStatus;
  }

  /*
   * MyKeyAdapter:  Listen for keyboard events 
   */
  class MyKeyAdapter extends KeyAdapter
  {
    public void keyPressed(KeyEvent evt)
    {
      /*
       * Check for escape key
       */
    	if (evt.getKeyCode() == KeyEvent.VK_ESCAPE)
      {
    	  cancelButton.doClick();
      }
    }
  }
}
