package org.adtpro.gui;

import java.awt.BorderLayout;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

import javax.swing.JButton;
import javax.swing.JCheckBox;
import javax.swing.JComboBox;
import javax.swing.JDialog;
import javax.swing.JLabel;
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
    try
    {
      Log.println(false, "SerialConfig Constructor about to attempt to instantiate rxtx library.");
      Log.print(true, Messages.getString("Gui.RXTX")); //$NON-NLS-1$
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
    }
    catch (Throwable t)
    {
      Log.println(true, Messages.getString("Gui.NoRXTX")); //$NON-NLS-1$
    }
    Log.println(false, "SerialConfig Constructor completed instantiating rxtx library.");

    comboSpeed = new JComboBox();
    comboSpeed.addItem("9600"); //$NON-NLS-1$
    comboSpeed.addItem("19200"); //$NON-NLS-1$
    comboSpeed.addItem("115200"); //$NON-NLS-1$

    comboBootstrapSpeed = new JComboBox();
    comboBootstrapSpeed.addItem("300"); //$NON-NLS-1$
    comboBootstrapSpeed.addItem("2400"); //$NON-NLS-1$
    comboBootstrapSpeed.addItem("9600"); //$NON-NLS-1$
    comboBootstrapSpeed.addItem("19200"); //$NON-NLS-1$

    comboBootstrapPacing = new JComboBox();
    comboBootstrapPacing.addItem("10"); //$NON-NLS-1$
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

    this.pack();
    this.setBounds(FrameUtils.center(this.getSize()));
    Log.println(false,"SerialConfig Constructor exit.");
  }

  /**
   * Retrieve the single instance of this class.
   * 
   * @return Log
   */
  public static SerialConfig getSingleton()
  {
    if (null == _theSingleton)
      SerialConfig.allocateSingleton();
    return _theSingleton;
  }

  /**
   * getSingleton() is not synchronized, so we must check in this method to make
   * sure a concurrent getSingleton() didn't already allocate the Singleton
   * 
   * synchronized on a static method locks the class
   */
  private synchronized static void allocateSingleton()
  {
    if (null == _theSingleton) _theSingleton = new SerialConfig();
  }

  public static void setProperties(ADTProperties properties)
  {
    _theSingleton._properties = properties;
    _theSingleton.comboSpeed.setSelectedItem(properties.getProperty("CommPortSpeed", "115200")); //$NON-NLS-1$ //$NON-NLS-2$
    _theSingleton.iicCheckBox.setSelected(properties.getProperty("HardwareHandshaking", "false").compareTo("true") == 0); //$NON-NLS-1$ //$NON-NLS-2$
    _theSingleton.comboComPort.setSelectedItem(properties.getProperty("CommPort", "COM1")); //$NON-NLS-1$ //$NON-NLS-2$
    _theSingleton.comboBootstrapSpeed.setSelectedItem(properties.getProperty("CommPortBootstrapSpeed", "300")); //$NON-NLS-1$ //$NON-NLS-2$
    _theSingleton.comboBootstrapPacing.setSelectedItem(properties.getProperty("CommPortBootstrapPacing", "500")); //$NON-NLS-1$ //$NON-NLS-2$
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
    _theSingleton.setModal(true);
    _theSingleton.setBounds(FrameUtils.center(_theSingleton.getSize(),parent.getBounds()));
    _theSingleton._tabbedPane.setSelectedIndex(tab);
    _theSingleton.show();
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
      _properties.setProperty("CommPort", (String) comboComPort.getSelectedItem());
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

  public int getExitStatus()
  {
    return _theSingleton.exitStatus;
  }
}
