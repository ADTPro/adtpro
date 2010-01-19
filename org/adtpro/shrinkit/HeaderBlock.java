package org.adtpro.shrinkit;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import org.adtpro.shrinkit.io.LittleEndianByteInputStream;


/**
 * The Header Block contains information and content
 * about a single entry (be it a file or disk image).
 * <p>
 * Note that we need to support multiple versions of the NuFX
 * archive format.  Some details may be invalid, depending on
 * version, and those are documented in the getter methods.
 * 
 * @author robgreene@users.sourceforge.net
 * @see http://www.nulib.com/library/FTN.e08002.htm
 */
public class HeaderBlock {
	private int headerCrc;
	private int attribCount;
	private int versionNumber;
	private long totalThreads;
	private int fileSysId;
	private int fileSysInfo;
	private long access;
	private long fileType;
	private long extraType;
	private int storageType;
	private Date createWhen;
	private Date modWhen;
	private Date archiveWhen;
	private int optionSize;
	private byte[] optionListBytes;
	private byte[] attribBytes;
	private String filename;
	private String rawFilename;
	private List<ThreadRecord> threads = new ArrayList<ThreadRecord>();
	
	/**
	 * Create the Header Block.  This is done dynamically since
	 * the Header Block size varies significantly.
	 */
	public HeaderBlock(LittleEndianByteInputStream bs) throws IOException {
		bs.checkNuFxId();
		headerCrc = bs.readWord();
		attribCount = bs.readWord();
		versionNumber = bs.readWord();
		totalThreads = bs.readLong();
		fileSysId = bs.readWord();
		fileSysInfo = bs.readWord();
		access = bs.readLong();
		fileType = bs.readLong();
		extraType = bs.readLong();
		storageType = bs.readWord();
		createWhen = bs.readDate();
		modWhen = bs.readDate();
		archiveWhen = bs.readDate();
		// Read the mysterious option_list
		if (versionNumber >= 1) {
			optionSize = bs.readWord();
			if (optionSize > 0) {
				optionListBytes = bs.readBytes(optionSize-2);
			}
		}
		// Compute attribute bytes that exist and read (if needed)
		int sizeofAttrib = attribCount - 58;
		if (versionNumber >= 1) {
			if (optionSize == 0) sizeofAttrib -= 2;
			else sizeofAttrib -= optionSize;
		}
		if (sizeofAttrib > 0) {
			attribBytes = bs.readBytes(sizeofAttrib);
		}
		// Read the (defunct) filename
		int length = bs.readWord();
		if (length > 0) {
			rawFilename = new String(bs.readBytes(length));
		}
	}
	/**
	 * Read in all data threads.  All ThreadRecords are read and then
	 * each thread's data is read (per NuFX spec).
	 */
	public void readThreads(LittleEndianByteInputStream bs) throws IOException {
		for (long l=0; l<totalThreads; l++) threads.add(new ThreadRecord(bs));
		for (ThreadRecord r : threads) r.readThreadData(bs);
	}

	/**
	 * Locate the filename and return it.  It may have been given in the old
	 * location, in which case, it is in the String filename.  Otherwise it will
	 * be in the filename thread.  If it is in the thread, we shove it in the 
	 * filename variable just so we don't need to search for it later.  This 
	 * should not be a problem, because if we write the file, we'll write the
	 * more current version anyway.
	 */
	public String getFilename() {
		if (filename == null) {
			ThreadRecord r = findThreadRecord(ThreadKind.FILENAME);
			if (r != null) filename = r.getText();
			if (filename == null) filename = rawFilename;
		}
		return filename;
	}
	
	/**
	 * Get the data fork.
	 */
	public ThreadRecord getDataForkInputStream() throws IOException {
		return  findThreadRecord(ThreadKind.DATA_FORK);
	}

	/**
	 * Get the resource fork.
	 */
	public ThreadRecord getResourceForkInputStream() throws IOException {
		return findThreadRecord(ThreadKind.RESOURCE_FORK);
	}

	/**
	 * Locate a ThreadRecord by it's ThreadKind.
	 */
	protected ThreadRecord findThreadRecord(ThreadKind tk) {
		for (ThreadRecord r : threads) {
			if (r.getThreadKind() == tk) return r;
		}
		return null;
	}

	// GENERATED CODE
	
	public int getHeaderCrc() {
		return headerCrc;
	}
	public void setHeaderCrc(int headerCrc) {
		this.headerCrc = headerCrc;
	}
	public int getAttribCount() {
		return attribCount;
	}
	public void setAttribCount(int attribCount) {
		this.attribCount = attribCount;
	}
	public int getVersionNumber() {
		return versionNumber;
	}
	public void setVersionNumber(int versionNumber) {
		this.versionNumber = versionNumber;
	}
	public long getTotalThreads() {
		return totalThreads;
	}
	public void setTotalThreads(long totalThreads) {
		this.totalThreads = totalThreads;
	}
	public int getFileSysId() {
		return fileSysId;
	}
	public void setFileSysId(int fileSysId) {
		this.fileSysId = fileSysId;
	}
	public int getFileSysInfo() {
		return fileSysInfo;
	}
	public void setFileSysInfo(int fileSysInfo) {
		this.fileSysInfo = fileSysInfo;
	}
	public long getAccess() {
		return access;
	}
	public void setAccess(long access) {
		this.access = access;
	}
	public long getFileType() {
		return fileType;
	}
	public void setFileType(long fileType) {
		this.fileType = fileType;
	}
	public long getExtraType() {
		return extraType;
	}
	public void setExtraType(long extraType) {
		this.extraType = extraType;
	}
	public int getStorageType() {
		return storageType;
	}
	public void setStorageType(int storageType) {
		this.storageType = storageType;
	}
	public Date getCreateWhen() {
		return createWhen;
	}
	public void setCreateWhen(Date createWhen) {
		this.createWhen = createWhen;
	}
	public Date getModWhen() {
		return modWhen;
	}
	public void setModWhen(Date modWhen) {
		this.modWhen = modWhen;
	}
	public Date getArchiveWhen() {
		return archiveWhen;
	}
	public void setArchiveWhen(Date archiveWhen) {
		this.archiveWhen = archiveWhen;
	}
	public int getOptionSize() {
		return optionSize;
	}
	public void setOptionSize(int optionSize) {
		this.optionSize = optionSize;
	}
	public byte[] getOptionListBytes() {
		return optionListBytes;
	}
	public void setOptionListBytes(byte[] optionListBytes) {
		this.optionListBytes = optionListBytes;
	}
	public byte[] getAttribBytes() {
		return attribBytes;
	}
	public void setAttribBytes(byte[] attribBytes) {
		this.attribBytes = attribBytes;
	}
	public void setFilename(String filename) {
		this.filename = filename;
	}
	public String getRawFilename() {
		return rawFilename;
	}
	public List<ThreadRecord> getThreadRecords() {
		return threads;
	}
	public void setThreadRecords(List<ThreadRecord> threads) {
		this.threads = threads;
	}
}
