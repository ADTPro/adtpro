/*
 * ADTPro - Apple Disk Transfer ProDOS
 * Copyright (C) 2007 by David Schmidt
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

import javax.sound.sampled.AudioFormat;
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.DataLine;
import javax.sound.sampled.Mixer;
import javax.sound.sampled.TargetDataLine;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.SwingConstants;

import org.adtpro.resources.Messages;
import org.adtpro.transport.audio.CaptureThread;
import org.adtpro.utilities.Log;
import org.adtpro.ADTProperties;

public class AudioConfig extends JDialog implements ActionListener
{
  /**
   * 
   */
  private static AudioConfig _theSingleton = null;

  private static final long serialVersionUID = 1L;

  private JLabel labelAudioDevice;

  private JComboBox comboAudioDevice;
  
  private int exitStatus = CANCEL;

  int _audioDeviceIndices[];

  public JButton okButton = new JButton(Messages.getString("Gui.Ok"));
  public JButton cancelButton = new JButton(Messages.getString("Gui.Cancel"));

  private static org.adtpro.ADTProperties _properties = null;

  public static Gui _parent;

  public static final int CANCEL = 0, OK = 1;

  /**
   * 
   * Private constructor - use the <code>getSingleton</code> to instantiate.
   * 
   */
  private AudioConfig(ADTProperties properties)
  {
    _properties = properties;
    this.setTitle(Messages.getString("Gui.AudioConfig"));
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
    configPanel.setLayout(new GridBagLayout());
    this.getContentPane().setLayout(new BorderLayout());    
    this.getContentPane().add(configPanel,BorderLayout.NORTH);
    this.getContentPane().add(buttonPanel,BorderLayout.SOUTH);
    Log.getSingleton();
    comboAudioDevice = new JComboBox();
    comboAudioDevice.addItem(Messages.getString("Gui.DefaultAudioMixer"));
    Mixer.Info[] mixerInfo = AudioSystem.getMixerInfo();
    AudioFormat audioFormat = CaptureThread.getAudioFormat();
    String nextName = null;
    _audioDeviceIndices = new int[mixerInfo.length + 1];
    _audioDeviceIndices[0] = 0;
    int j = 1;
    for (int i = 0; i < mixerInfo.length; i++)
    {
      nextName = null;
      DataLine.Info dataLineInfo = new DataLine.Info(TargetDataLine.class, audioFormat);
      Mixer mixer = AudioSystem.getMixer(mixerInfo[i]);
      try
      {
        TargetDataLine targetDataLine = (TargetDataLine) mixer.getLine(dataLineInfo);
        nextName = mixerInfo[i].getName();
        if (!nextName.equals("")) /* Skip it if it's name is blank... */
        {
          comboAudioDevice.addItem(nextName);
          _audioDeviceIndices[j] = i;
          Log.println(false, "AudioConfig().ctor Added device "+nextName+" at index "+i+", mixer index "+j+".");
          j = j + 1;
        }
      }
      catch (Exception e)
      {
        /* Don't need to see stack traces for bad lines/mixers... */
        /*
        Log.println(true,"AudioConfig() ctor Encountered error on mixer "+mixerInfo[i].getName()+":");
        Log.printStackTrace(e);
        */
      }
    }
    Log.println(false, "AudioConfig().ctor completed.");
/*
    Log.println(true, Messages.getString("Gui.NoAudio")); //$NON-NLS-1$
    Log.println(false, "AudioConfig Constructor could not instantiate the rxtx library.");
*/
    labelAudioDevice = new JLabel(Messages.getString("Gui.AudioConfigMixer"), SwingConstants.LEFT); //$NON-NLS-1$

    GridBagUtil.constrain(configPanel, labelAudioDevice, 1, 1, // X, Y Coordinates
        1, 1, // Grid width, height
        GridBagConstraints.NONE, // Fill value
        GridBagConstraints.WEST, // Anchor value
        0.0, 0.0, // Weight X, Y
        5, 5, 0, 0); // Top, left, bottom, right insets
    GridBagUtil.constrain(configPanel, comboAudioDevice, 1, 2, // X, Y Coordinates
        1, 1, // Grid width, height
        GridBagConstraints.HORIZONTAL, // Fill value
        GridBagConstraints.WEST, // Anchor value
        0.0, 0.0, // Weight X, Y
        0, 5, 5, 5); // Top, left, bottom, right insets

    this.pack();
    this.setBounds(FrameUtils.center(this.getSize()));
    okButton.requestFocus();
    getRootPane().setDefaultButton(okButton);
    int mixerIndex = 0;
    try
    {
      mixerIndex = Integer.parseInt(_properties.getProperty("AudioPortIndex","0"));
      Log.println(false, "AudioConfig.ctor() Found a GUI mixer index of: "+mixerIndex);
      Log.println(false, "  which is a hardware index of: "+_audioDeviceIndices[mixerIndex]);
    }
    catch (NumberFormatException e)
    {
      /* Leaves mixerIndex at zero */
    }
    comboAudioDevice.setSelectedIndex(mixerIndex);
    Log.println(false,"AudioConfig Constructor exit.");
  }

  /**
   * Retrieve the single instance of this class.
   * 
   * @return Log
   */
  public static AudioConfig getSingleton(Gui parent, ADTProperties properties)
  {
    _parent = parent;
    _properties = properties;
    if (null == _theSingleton)
      AudioConfig.allocateSingleton(parent, properties);
    return _theSingleton;
  }

  /**
   * getSingleton() is not synchronized, so we must check in this method to make
   * sure a concurrent getSingleton() didn't already allocate the Singleton
   * 
   * synchronized on a static method locks the class
   */
  private synchronized static void allocateSingleton(Gui parent, ADTProperties properties)
  {
    if (null == _theSingleton) _theSingleton = new AudioConfig(properties);
  }

  public static String getPort()
  {
    return (String)_theSingleton.comboAudioDevice.getSelectedItem();
  }

  public static void showSingleton(Gui parent)
  {
    _theSingleton.setModal(true);
    _theSingleton.setBounds(FrameUtils.center(_theSingleton.getSize(),parent.getBounds()));
    _theSingleton.setVisible(true);
  }

  public void actionPerformed(ActionEvent e)
  {
    Log.println(false,"AudioConfig.actionPerformed() entry, responding to "+e.getActionCommand());
    if (e.getSource() == okButton)
    {
      Log.println(false, "  Selected index: "+(comboAudioDevice.getSelectedIndex()));
      if (comboAudioDevice.getSelectedIndex() > -1)
      {
        _properties.setProperty("AudioPortIndex", Integer.toString(comboAudioDevice.getSelectedIndex()));
        _properties.setProperty("AudioHardwareIndex", Integer.toString(_audioDeviceIndices[comboAudioDevice.getSelectedIndex()]));

        Log.println(false, "  Set property to: "+Integer.toString(comboAudioDevice.getSelectedIndex()));
      }
      else
      {
        _properties.setProperty("AudioPortIndex", "0");
        Log.println(false, "  Oops, set property to 0.");
      }
      _properties.save();
      _theSingleton.exitStatus = OK;
      this.setVisible(false);
    }
    else if (e.getSource() == cancelButton)
    {
      int priorSelection = Integer.parseInt(_properties.getProperty("AudioPortIndex", "0"));
      _theSingleton.comboAudioDevice.setSelectedIndex(priorSelection); //$NON-NLS-1$ //$NON-NLS-2$
      _theSingleton.exitStatus = CANCEL;
      this.setVisible(false);
    }
    Log.println(false,"AudioConfig.actionPerformed() exit.");
  }

  public int getExitStatus()
  {
    return _theSingleton.exitStatus;
  }
}
