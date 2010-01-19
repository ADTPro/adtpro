package org.adtpro.shrinkit;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

import org.adtpro.shrinkit.io.LittleEndianByteInputStream;


/**
 * Basic reading of a NuFX archive.
 * 
 * @author robgreene@users.sourceforge.net
 */
public class NuFileArchive {
	private MasterHeaderBlock master;
	private List<HeaderBlock> headers;
	
	/**
	 * Read in the NuFile/NuFX/Shrinkit archive.
	 */
	public NuFileArchive(InputStream inputStream) throws IOException {
		LittleEndianByteInputStream bs = new LittleEndianByteInputStream(inputStream);
		master = new MasterHeaderBlock(bs);
		headers = new ArrayList<HeaderBlock>();
		for (int i=0; i<master.getTotalRecords(); i++) {
			HeaderBlock header = new HeaderBlock(bs);
			header.readThreads(bs);
			headers.add(header);
		}
	}

	public MasterHeaderBlock getMasterHeaderBlock() {
		return master;
	}
	public List<HeaderBlock> getHeaderBlocks() {
		return headers;
	}
}
