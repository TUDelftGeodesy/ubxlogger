The following programs have been compiled for OpenWrt MIPS


|          | OpenWrt package | Cross-compiled | Remarks          | 
| -------- | --------------- | -------------- | ---------------- | 
| str2str  | ok              | ok             |                  | 
| convbin  | little endian   | ok             | Modified ublox.c | 
| crx2rnx  |                 | ok             |                  | 
| rnx2crx  |                 | ok             |                  | 

## str2str

RTKLIB str2str is working on OpenWrt and available as package. We are using 
str2str installed by the package manager in the system directory. The version 
in this folder is more recent b34k (but haven't tested it). 

## convbin 

RTKLIB convbin that is distributed as package is NOT working on OpenWrt-MIPS 
big endian systems. This is because OpenWrt MIPS is a big endian system, 
whereas the data from the u-blox receiver is little endian, and the original 
convbin code is assuming it is run on systems with the same endianess.  

The convbin in this folder is a modified version of convbin that includes 
tests on endianess and if necessary swaps the bytes to obtain the correct 
machine representation. This version has been cross compiled for OpenWrt 
MIPS using a modified version of `ublox.c` c-code file. The modified 
file and path file can be found in the `src` directory/

## crx2rnx and rnx2crx

crx2rnx and rnx2crx are working on OpenWrt (but not available as packages)

Hans van der Marel
Delft, 29 September 2024


