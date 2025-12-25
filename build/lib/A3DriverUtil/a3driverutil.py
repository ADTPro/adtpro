#!/usr/bin/python
#

# use unpack from struct and argv from sys
from struct import unpack,pack; import argparse;

parser = argparse.ArgumentParser(
    prog='A3Driverutil.py',
    formatter_class=argparse.RawDescriptionHelpFormatter,
    description='''\
Driverutil.py - A Python script to work with A3 drivers
 By Robert Justice

The primary function is to convert an o65 relocatable 6502 binary
file to A3 driver format. This is to allow driver development using
the ca65 assembler

Support to add, update the converted driver into a SOS.DRIVER file
and delete & list is also included.

Finally, has some extract functions to extract driver code to allow
disassembly. One of these will relocate the extracted Driver to 
0x2000 base address to minimise any confusion with zero page when
disassembling.

        https://github.com/rob_justice/A3Driverutil

 reuses some functions and ideas from Driv3rs.py, thank you
        https://github.com/thecompu/Driv3rs

''')

subparsers = parser.add_subparsers(help='Command Description',dest="command")

# Bin command
bin_parser = subparsers.add_parser(
    'bin', help='Convert o65 binary to A3 driver binary format, Comment + Code + RelocationTable')
bin_parser.add_argument(
    'o65file', action='store',
    help='Input o65 code file to be converted')
bin_parser.add_argument(
    'binfile', action='store',
    help='Binary output file')

# Sos command
sos_parser = subparsers.add_parser(
    'sos', help='Convert o65 binary and output as SOS.DRIVER format(for use with scp)')
sos_parser.add_argument(
    'o65file', action='store',
    help='Input o65 code file to be converted')
sos_parser.add_argument(
    'sosfile', action='store',
    help='SOS.DRIVER Binary output file')

# List command
add_parser = subparsers.add_parser(
    'list', help='List current drivers in a SOS.DRIVER file')
add_parser.add_argument(
    'sosfile', action='store',
    help='SOS.DRIVER file to list drivers in')
    
# Add command
add_parser = subparsers.add_parser(
    'add', help='Convert o65 binary and add as new driver to a existing SOS.DRIVER file')
add_parser.add_argument(
    'o65file', action='store',
    help='Input o65 code file to be converted')
add_parser.add_argument(
    'sosfile', action='store',
    help='SOS.DRIVER file to list the contained drivers')

# Update command
update_parser = subparsers.add_parser(
    'update', help='Convert o65 binary and update existing driver in a SOS.DRIVER file')
update_parser.add_argument(
    'o65file', action='store',
    help='Input o65 code file to be converted')
update_parser.add_argument(
    'sosfile', action='store',
    help='SOS.DRIVER file to be updated')

# Delete command
delete_parser = subparsers.add_parser(
    'delete', help='Delete a driver from an existing SOS.DRIVER file')
delete_parser.add_argument(
    'drivername', action='store',
    help='Name of driver to be deleted (include . eg: ".console"')
delete_parser.add_argument(
    'sosfile', action='store',
    help='SOS.DRIVER file to delete the driver from')
    
# Extract command
extract_parser = subparsers.add_parser(
    'extract', help='Extract a driver from an existing SOS.DRIVER file')
extract_parser.add_argument(
    'drivername', action='store',
    help='Name of driver to be extracted (include . eg: ".console"')
extract_parser.add_argument(
    'sosfile', action='store',
    help='SOS.DRIVER file to extract the driver from')

# Extract code and relocate to 0x2000 command
extract_parser = subparsers.add_parser(
    'extractcode', help='Extract a drivers code from an existing SOS.DRIVER file and relocate to 0x2000 to aid disassembly')
extract_parser.add_argument(
    'drivername', action='store',
    help='Name of driver to be extracted (include . eg: ".console"')
extract_parser.add_argument(
    'sosfile', action='store',
    help='SOS.DRIVER file to extract the driver from')

args = parser.parse_args()


# this function unpacks several read operations --
# text, binary, and single-byte. Each uses unpack from
# struct and attempts converts the resulting tuple into
# into either a string or integer, depending upon need.
def readUnpack(file,bytes, **options):
    if options.get("type") == 't':
        SOS = file.read(bytes)
        text_unpacked = unpack('%ss' % bytes, SOS)
        return ''.join(text_unpacked)

    if options.get("type") == 'b':
        SOS = file.read(bytes)
        offset_unpacked = unpack ('< H', SOS)
        return int('.'.join(str(x) for x in offset_unpacked))

    if options.get("type") == '1':
        SOS = file.read(bytes)
        offset_unpacked = unpack ('< B', SOS)
        return int(ord(SOS))

# this function reads a word from a string at the specified
# offset and returns an integer 
def readWord(data,startpos):
    return ord(data[startpos+1])*256+ord(data[startpos])

# this function reads a byte from a string at the specified
# offset and returns an integer
def readByte(data,startpos):
    return ord(data[startpos])

#
# this function reads in a o65 binary file of a driver and 
# converts to the same format as contained in the SOS.DRIVER
# file for drivers, Comment, Code, RelocateTable
#  input - filename of o65 file
#  returns - converted driver as a string
#
def convert_o65(file):        
    o65file = open(file, 'rb')
    
    #parse the o65 file
    byte = readUnpack(o65file,1,type = '1')        #non-C64 marker, 2 bytes
    byte = readUnpack(o65file,1,type = '1')
    o65 = readUnpack(o65file,3,type = 't')         # "o65" MAGIC number!
    if o65 == 'o65':    #valid file, lets keep going
        version = readUnpack(o65file,1,type = '1')  # version
        mode = readUnpack(o65file,2,type = 'b')     # mode word
        tbase = readUnpack(o65file,2,type = 'b')    # address to which text is assembled to originally
        tlen = readUnpack(o65file,2,type = 'b')     # length of text segment
        dbase = readUnpack(o65file,2,type = 'b')    # originating address for data segment
        dlen = readUnpack(o65file,2,type = 'b')     # length of data segment
        bbase = readUnpack(o65file,2,type = 'b')    # originating address for bss segment
        blen = readUnpack(o65file,2,type = 'b')     # length of bss segment
        zbase = readUnpack(o65file,2,type = 'b')    # originating address for zero segment
        zlen = readUnpack(o65file,2,type = 'b')     # length of zero segment
        stack = readUnpack(o65file,2,type = 'b')    # minimum needed stack size, 0= not known.
        
        #print ("mode: ",mode)
        #print ("tbase: ",tbase)
        #print ("tlen: ",tlen)
        #print ("dbase: ",dbase)
        #print ("dlen: ",dlen)

        if tlen == 0:
            print("No text segment found; ensure your driver defines .segment \"TEXT\"")
            exit(1)
        if dlen == 0:
            print("No data segment found; ensure your driver defines .segment \"DATA\"")
            exit(1)

        #skip over header options
        olen = readUnpack(o65file,1,type = '1') 
        while olen != 0 :  #0 marks end of options header
           otype = readUnpack(o65file,1,type = '1')
           option_bytes = readUnpack(o65file,olen-2,type = 't')
           olen = readUnpack(o65file,1,type = '1') 
        
        driver=''      #this will be the converted driver
        
        #add text segment
        driver += o65file.read(tlen)  #this is the comment part
        
        #trim off the comment 0xFFFF if there is a comment
        if readWord(driver,0) == 0xFFFF:
           driver = driver[2:]
        
        #add data segment length
        driver += pack('<H',dlen)     #this is the length of the code part
        
        #add data segment
        driver += o65file.read(dlen)  #this is the code part
        
        #skip Undefined references list number (should be 0) assuming size 16 bits for now
        byte = readUnpack(o65file,1,type = '1')
        byte = readUnpack(o65file,1,type = '1')
        
        #skip TEXT segment reloc table, this should be 0 indicating no entries
        byte = readUnpack(o65file,1,type = '1')
        
        #convert the relocation table from relative offset bytes to absolute addresses
        reloctable =[]
        
        offset_address = dbase-1     #offset starts at data seg orig minus 1
        offset = readUnpack(o65file,1,type = '1')
        #print ("start offset:",offset)
        
        while offset != 0:
            if offset == 255:    #next offset > 254, so add this and get next byte
                offset_address = offset_address + offset -1 #add 254
                offset = readUnpack(o65file,1,type = '1')
            else:
                typebyte = readUnpack(o65file,1,type = '1')
                if typebyte == 0x83:    #8=word offset and 3=data segment
                    offset_address = offset_address + offset
                    reloctable.append(offset_address)
                    offset = readUnpack(o65file,1,type = '1')
        
        #add the length of the relocation table
        driver += pack('<H',len(reloctable)*2)    #this is the length of the relocate part in bytes
        
        #add the relocation table
        for i in range(0,len(reloctable)):
            driver += pack('<H',reloctable[i])     #this is the relocation part
        o65file.close()
        
        return driver    #return the converted driver binary
    
    else:
        print 'not o65 input file'
        o65file.close()
        exit()
    
# 
# this function searchs through the driverfile data and returns
# a list of offsets for the drivers contained in the data
# each entry in the returned list is a dictionary containing:
#  'comment_start'
#  'code_start'
#  'reloc_start'
#
def parsedriverfile(filecontents): 
    filetype = filecontents[0:8]           #check for 'SOS DRVR' header
    if filetype != 'SOS DRVR':
        print "INVALID SOS.DRIVER file"
        exit()
    
    drivers_list = []
    offset = readWord(filecontents,8) + 8 + 2  #actual drivers start after this offset
    loop = True
    while loop :
        driver = {}
        rel_offset = readWord(filecontents,offset)  #comment length
        if rel_offset == 0xFFFF:   #we are at the end of the file
            end_mark = offset
            loop = False
        else :                     #else lets walk through and build the offsets 
            driver['comment_start'] = offset
            offset += rel_offset + 2
            drivers_list.append(driver)
            driver['code_start'] = offset
            rel_offset = readWord(filecontents,offset)     #code length
            offset += rel_offset + 2
            driver['reloc_start'] = offset
            rel_offset = readWord(filecontents,offset)     #reloc start
            offset += rel_offset + 2
    
    return [drivers_list,end_mark]

#       
# this function extracts the driver details from the dib
# and returns them in a dictionary
#
def parseDIB(filedata,offset,dib):
    driver_details={}
    driver_details['dib_num'] = dib
    driver_details['name_len'] = readByte(filedata,offset+6)
    driver_details['name'] = filedata[offset+7:offset+7+driver_details['name_len']]
    driver_details['status'] = readByte(filedata,offset+22)
    driver_details['slot'] = readByte(filedata,offset+23)
    driver_details['unit'] = readByte(filedata,offset+24)
    driver_details['devtype'] = readByte(filedata,offset+25)
    driver_details['subtype'] = readByte(filedata,offset+26)
    driver_details['manid'] = readWord(filedata,offset+30)
    driver_details['release'] = readWord(filedata,offset+32)
    return driver_details      

#
# this function extracts the name from the driver
# returns the name
#
def getDriverName(driver):
    offset = readWord(driver, 0)          #comment length
    name_length = readByte(driver,offset + 8)  #extract the name length from the driver code
                                               #code starts after the comment
    return driver[offset+9:offset+9+name_length]  #then grab the name


#
# this function finds the index in a list of the member that
# contains a dictionary key/value pair
#
def find(lst, key, value):
    for i, dic in enumerate(lst):
        if dic[key] == value:
            return i
    return -1



#   
# Main program
# lets select from the options
#

# raw driver format output as binary file
if args.command == 'bin':
    driver = convert_o65(args.o65file)
    bin_file = args.binfile
    outfile = open(bin_file,'wb')
    outfile.write(driver)   
    print 'File converted and written as raw binary file to:',bin_file
    outfile.close()

# Convert file and output as SOS.DRIVER format
# adds a dummy charset and keyboard header to keep scp happy
elif args.command == 'sos':  
    driver = convert_o65(args.o65file)

    #create SOS driver header
    header = 'SOS DRVR'
    header += pack('<H',0x0522)  #header length
    header += pack('>H',0x0400)  #Number of Disk /// drives installed (4)
    header += '??              ' #char set name, ?? indicates no char set included (16 chars long)
    
    for i in range(0,0x400):     #pad out the char set with spaces   
        header += ' '
    
    header += '??              ' #keyboard layout name (16 chars long)
    
    for i in range(0,0x100):     #pad out with spaces   
        header += ' '
    
    sos_file = args.sosfile
    outfile = open(sos_file,'wb')
    outfile.write(header + driver + pack('>H',0xFFFF))  #add the end marker   
    
    print 'File converted and written as SOS.DRIVER binary file to:',sos_file
    outfile.close()
   
#Convert and add to an existing SOS.DRIVER file
elif args.command == 'add':  
    driver = convert_o65(args.o65file)   #convert the driver code

    driver_name = getDriverName(driver)  #extract the driver name from the driver
    
    sos_file = args.sosfile              #read in the existing SOS.DRIVER file
    sosdriver = open(sos_file,'rb')
    sosdriverfile = sosdriver.read()     
    sosdriver.close()
    
    drivers_list = parsedriverfile(sosdriverfile)[0] #we just want the first item in the returned list
    driver_end = parsedriverfile(sosdriverfile)[1]   #this is the offset of the 0xFFFF end marker
    
    #lets check if it already exists in the SOS.DRIVER file
    driver_details = []
    
    for i in range(0,len(drivers_list)):
        offset = drivers_list[i]['code_start']
        driver_details.append(parseDIB(sosdriverfile,offset,0))  #we always use dib0
    
    i = find(driver_details,'name',driver_name.upper()) #find index of the driver to add, convert name to uppercase
    
    if i == -1:
        #not found, lets add
        trimmed_sosdriver = sosdriverfile[0:driver_end]  #trim of the 0xFFFF end marker
        newsosdriverfile = trimmed_sosdriver + driver + chr(0xFF) + chr(0xFF)
        
        sosdriver = open(sos_file,'wb')      #write it back out, overwriting the old one
        sosdriver.write(newsosdriverfile)      
        sosdriver.close()   
        
        print 'Driver: ' + driver_name + ' added to ' + sos_file
    
    else:
        #found, report error
        print 'Driver: ' + driver_name + ' elready exists in ' + sos_file + ', not added'


#List drivers in a SOS.DRIVER file
elif args.command == 'list':  
    sos_file = args.sosfile
    sosdriver = open(sos_file,'rb')
    filedata = sosdriver.read()   
    drivers_list = parsedriverfile(filedata)[0]  #we just want the first item in the returned list

    driver_details = []
    
    for i in range(0,len(drivers_list)):
        dib = 0
        offset = drivers_list[i]['code_start']
        driver_details.append(parseDIB(filedata,offset,dib))
        nextdib = readWord(filedata,offset+2) #next dib of this driver
        while nextdib != 0:
            dib += 1
            driver_details.append(parseDIB(filedata,offset+nextdib,dib))
            nextdib = readWord(filedata,offset+nextdib+2) #next dib of this driver
    
    print    'DriverName        Status     Slot   Unit   Manid  Release'     
    for i in range(0,len(driver_details)):
        #decode status byte
        if driver_details[i]['status'] & 0x80 == 0x80:
            status = 'active'
        else:
            status = 'inactive'
        #decode slot
        if driver_details[i]['slot'] == 0:
            slot = 'N/A'
        else:
            slot = driver_details[i]['slot']
        
        if driver_details[i]['dib_num'] == 0:  #don't indent the first DIB
            print '{:16}  {:10} {:3}     {:02X}     {:04X}   {:04X}'.format(driver_details[i]['name'], status, slot, driver_details[i]['unit'],driver_details[i]['manid'],driver_details[i]['release'])
        else:         #otherwise indent the rest, ie sub devices
            print '  {:16}{:10} {:3}     {:02X}     {:04X}   {:04X}'.format(driver_details[i]['name'], status, slot, driver_details[i]['unit'],driver_details[i]['manid'],driver_details[i]['release'])

    print '\n Total size: ',len(filedata)


#Convert and update an existing driver in a SOS.DRIVER file
elif args.command == 'update':  
    driver = convert_o65(args.o65file)   #convert the driver code
    
    driver_name = getDriverName(driver)  #extract the driver name from the driver    
    
    print 'Driver in o65 file: ',driver_name
    
    sos_file = args.sosfile              #read in the existing SOS.DRIVER file
    sosdriver = open(sos_file,'rb')
    sosdriverfile = sosdriver.read()
    sosdriver.close()
    
    drivers_list = parsedriverfile(sosdriverfile)[0]
    drivers_end = parsedriverfile(sosdriverfile)[1]
    
    driver_details = []
    
    for i in range(0,len(drivers_list)):
        offset = drivers_list[i]['code_start']
        driver_details.append(parseDIB(sosdriverfile,offset,0))  #we always use dib0
    
    i = find(driver_details,'name',driver_name.upper()) #find index of the driver to update, convert name to uppercase
    
    if i != -1:
        #found it
        print 'Driver found in SOS.DRIVER, updating..'
        #print drivers_list
        
        newsosdriverfile = sosdriverfile[0:drivers_list[i]['comment_start']]    #part up to target driver
        newsosdriverfile += driver  #add the updated driver
        
        if i < len(drivers_list)-1:  #check if its not the last one
           newsosdriverfile += sosdriverfile[drivers_list[i+1]['comment_start']:]  #add the rest after the target driver
        else:                        #otherwise we use the end marker
           newsosdriverfile += sosdriverfile[drivers_end:]  #add the rest after the target driver
        
        sosdriver = open(sos_file,'wb')        #write it back out
        sosdriver.write(newsosdriverfile)
        sosdriver.close()
        
        print 'Driver: ' + driver_name + ' updated!'
    
    else:
        #not found
        print 'Driver: ' + driver_name + ' not found in SOS.DRIVER file'


#Delete an existing driver in a SOS.DRIVER file
elif args.command == 'delete':  
    driver_name = args.drivername
    
    sos_file = args.sosfile              #read in the SOS.DRIVER file
    sosdriver = open(sos_file,'rb')
    sosdriverfile = sosdriver.read()
    sosdriver.close()
    
    drivers_list = parsedriverfile(sosdriverfile)[0]
    drivers_end = parsedriverfile(sosdriverfile)[1]
    
    driver_details = []
    
    for i in range(0,len(drivers_list)):
        offset = drivers_list[i]['code_start']
        driver_details.append(parseDIB(sosdriverfile,offset,0))  #we always use dib0
    
    i = find(driver_details,'name',driver_name.upper()) #find index of the driver to delete, convert name to uppercase
    
    if i != -1:
        #found it
        print 'Driver found in SOS.DRIVER, deleting..'
        
        newsosdriverfile = sosdriverfile[0:drivers_list[i]['comment_start']]    #part up to target driver
        
        if i < len(drivers_list)-1:  #check if its not the last one
           newsosdriverfile += sosdriverfile[drivers_list[i+1]['comment_start']:]  #add the rest after the target driver
        else:                        #otherwise we use the end marker
           newsosdriverfile += sosdriverfile[drivers_end:]  #add the rest after the target driver
        
        sosdriver = open(sos_file,'wb')        #write it back out
        sosdriver.write(newsosdriverfile)
        sosdriver.close()
        
        print 'Driver: ' + driver_name + ' deleted!'
    
    else:
        #not found
        print 'Driver: ' + driver_name + ' not found in SOS.DRIVER file'



#Extract a driver from a SOS.DRIVER file
elif args.command == 'extract':  
   driver_name = args.drivername
   
   sos_file = args.sosfile              #read in the SOS.DRIVER file
   sosdriver = open(sos_file,'rb')
   sosdriverfile = sosdriver.read()
   sosdriver.close()
   
   drivers_list = parsedriverfile(sosdriverfile)[0]  #parse the driver file to find the positions of the drivers
   drivers_end = parsedriverfile(sosdriverfile)[1]  #parse the driver file to find the end of the drivers

   driver_details = []                    #now grab the details from dib0 of each them ie to find the names
   for i in range(0,len(drivers_list)):
      offset = drivers_list[i]['code_start']
      driver_details.append(parseDIB(sosdriverfile,offset,0))  #we always use dib0

   i = find(driver_details,'name',driver_name.upper()) #find index of the driver to extract, convert name to uppercase
   
   if i != -1:
      #found it
      print 'Driver found in SOS.DRIVER, extracting..'
      
      if i < len(drivers_list)-1:   #check if its not the last one in sos.driver
         extracted_driver = sosdriverfile[drivers_list[i]['comment_start']:drivers_list[i+1]['comment_start']]
         
      else:      #must be the last one, so we use the offset of the 0xFFFF marker
         extracted_driver = sosdriverfile[drivers_list[i]['comment_start']:drivers_end]
      
      filename = driver_name[1:] + '.driver'  #chop off the ., and add .driver to the end
      driverfile = open(filename,'wb')        #write the new driver out
      driverfile.write(extracted_driver)
      driverfile.close()

      print 'Driver: ' + driver_name + ' extracted and written to file: ' + filename

   else:
      #not found
      print 'Driver: ' + driver_name + ' not found in SOS.DRIVER file'

#Extract a drivers code from a SOS.DRIVER file and relocate to 0x2000 to aid disassembly
# relocating to something other than 0x0000 helps to remove zero page ambiguities when
# disassembling the driver code
elif args.command == 'extractcode':  
   driver_name = args.drivername
   
   sos_file = args.sosfile              #read in the SOS.DRIVER file
   sosdriver = open(sos_file,'rb')
   sosdriverfile = sosdriver.read()
   sosdriver.close()
   
   drivers_list = parsedriverfile(sosdriverfile)[0]  #parse the driver file to find the positions of the drivers
   drivers_end = parsedriverfile(sosdriverfile)[1]  #parse the driver file to find the end of the drivers

   driver_details = []                    #now grab the details from dib0 of each them ie to find the names
   for i in range(0,len(drivers_list)):
      offset = drivers_list[i]['code_start']
      driver_details.append(parseDIB(sosdriverfile,offset,0))  #we always use dib0

   i = find(driver_details,'name',driver_name.upper()) #find index of the driver to extract, convert name to uppercase
   
   if i != -1:
      #found it
      print 'Driver found in SOS.DRIVER, extracting code..'
      
      #grab the code
      extracted_driver_code = sosdriverfile[drivers_list[i]['code_start']+2:drivers_list[i]['reloc_start']] #skip the code length(+2)

      #grab the relocate table
      if i < len(drivers_list)-1:   #check if its not the last one in sos.driver
         extracted_driver_reloc = sosdriverfile[drivers_list[i]['reloc_start']+2:drivers_list[i+1]['comment_start']] #skip the reloc length(+2)
      else:      #must be the last one, so we use the offset of the 0xFFFF marker
         extracted_driver_reloc = sosdriverfile[drivers_list[i]['reloc_start']+2:drivers_end]  #skip the reloc length(+2)
      #print  extracted_driver_reloc.encode('hex')
      
      #convert the reloc table from little endian addresses to list of integers 
      offset_table = []
      for i in range (0,len(extracted_driver_reloc),2):
         offset_table.append(readWord(extracted_driver_reloc,i))
            
      #now lets relocate the code to 0x2000
      #just updates the high byte of the addresses to 0x20
      j = 0
      for i in range(0,len(extracted_driver_code)):
          byte = readByte(extracted_driver_code,i)
          if i == offset_table[j]+1:   #looking at high byte
              extracted_driver_code = extracted_driver_code[:i] + chr(byte + 0x20) + extracted_driver_code[i+1:]   #add to the existing address high byte
              if j < (len(offset_table)-1):    
                 j += 1        

      filename = driver_name[1:] + '.driver_code_0x2000'  #chop off the ., and add .driver_code_0x2000 to the end
      driverfile = open(filename,'wb')        #write the new driver out
      driverfile.write(extracted_driver_code)
      driverfile.close()

      print 'Driver: ' + driver_name + ' extracted, relocated and written to file: ' + filename

   else:
      #not found
      print 'Driver: ' + driver_name + ' not found in SOS.DRIVER file'
