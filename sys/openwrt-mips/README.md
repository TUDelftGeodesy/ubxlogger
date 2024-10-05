# OpenWrt MIPS RTKLIB and RNXCMP executables

The following programs have been compiled for OpenWrt MIPS


|          | OpenWrt package | Cross-compiled | Remarks          | 
| -------- | --------------- | -------------- | ---------------- | 
| str2str  | ok              | ok             |                  | 
| convbin  | little endian   | ok             | Modified ublox.c | 
| crx2rnx  |                 | ok             |                  | 
| rnx2crx  |                 | ok             |                  | 

OpenWrt packages are installed with the OpenWrt package manager. Cross-compiled binaries are included as downloadable tar-ball with the Github releases. 

## str2str

RTKLIB str2str [(Takasu, 2022)][4] is available for OpenWrt as installable OpenWrt package [(Consalves, 2002][2] and as cross-compiled RTKLIB Demo 5 b34k [(rtklibexplorer, 2024)][3] binary in this folder by undersigned. The recommended version for UbxLogger is  `str2str`  installed by the OpenWrt package manager. 

## convbin 

RTKLIB convbin [(Takasu, 2022)][4] OpenWrt package [(Consalves, 2002][2] is NOT working on
OpenWrt-MIPS big endian systems. OpenWrt MIPS is a big endian system, 
whereas the data from the u-blox receiver is little endian, and the original 
convbin code is assuming it is run on systems with the same endianess.  

The `convbin` in this folder is a modified version of `convbin` from RTKLIB Demo 5 b34k 
[(rtklibexplorer, 2024)][3] that includes tests on endianess and if necessary 
swaps the bytes to obtain the correct machine representation. 
This version has been cross compiled for OpenWrt MIPS using a modified version of `ublox.c` c-code file. The modified file [ublox.c](src/ublox.c) and [patch file](src/ublox.patch)  can be found in the [src/](src/) directory.

**Important note**: only the decoding part for u-blox receivers has been modified. The encoding part has not been modified and the part dealing with setting on the receiver will definetely NOT work on big-endian system and could possibly destroy your current receiver configuration. Don't try this. The code for other receivers is left as-is, and may, or may not, work on big-endian systems.  

## crx2rnx and rnx2crx

RNXCMP crx2rnx and rnx2crx [(Hatanaka, 2008)][1] are working on OpenWrt. They are not available
as OpenWrt packages, but cross compiled versions for OpenWrt MIPS can be found in this folder.

## Applicable licenses

The executables are made available under their own license.

### RTKLIB

RTKLIB str2str and convbin are available under BSD 2-clause
license (http://opensource.org/licenses/BSD-2-Clause) and additional two
exclusive clauses, see [LICENSE_RTKLIB](LICENSE_RTKLIB.txt) for the full license.

The software was cross-compiled for OpenWrt-mips by undersigned, using 
source code from RTKLIB demo5 b34k (https://github.com/rtklibexplorer/RTKLIB/releases)
with a modified version of `ublox.c`. The modified version of `ublox.c` is available 
under the same BSD clauses and compatible with the Apache 2 license of UbxLogger.  

### RNXCMP

RNXCMP rnx2crx and crx2rnx are available under Geospatial Information 
Authority of Japan Website Terms of Use, 
https://www.gsi.go.jp/ENGLISH/page_e30286.html (except for provision 1-a),
see [LICENSE_RNXCMP](LICENSE_RNXCMP.txt) for the full text of the license. The reference
to the software is [Hatanaka, 2008][1]. 

The software was cross compiled for OpenWrt-mips by undersigned using 
the unmodified c-code from https://terras.gsi.go.jp/ja/crx2rnx/RNXCMP_4.1.0_src.tar.gz 


## Disclaimer

The cross compiling and code changes for OpenWrt-mips was done on a best effort basis by undersigned
and is offered “as-is”, without warranty, and disclaiming liability for damages 
resulting from using the cross compiled binaries or license infringements resulting
from the use of the software. 

## References

[1] Hatanaka, Y. (2008), A Compression Format and Tools for GNSS Observation
Data, Bulletin of the Geospatioal Information Authority of Japan, 55, 21-30.
(available at https://www.gsi.go.jp/ENGLISH/Bulletin55.html)

[2] Nuno Goncalves (2022), RTKLIB 2.4.3_b34 OpenWrt package, https://openwrt.org/packages/index/utilities---rtklib-suite. 

[3] rtklibexplorer (2024), RTKLIB Demo 5 (b34k), GitHub repository. (available at https://github.com/rtklibexplorer/RTKLIB).

[4] T.Takasu (2020), RTKLIB: An Open Source Program Package for GNSS Positioning, 
https://www.rtklib.com/.

[1]: <https://www.gsi.go.jp/ENGLISH/Bulletin55.html> "Hatanaka, Y. (2008), A Compression Format and Tools for GNSS Observation Data, Bulletin of the Geospatioal Information Authority of Japan, 55, 21-30."

[2]: <https://openwrt.org/packages/index/utilities---rtklib-suite> "Nuno Goncalves (2022), RTKLIB 2.4.3_b34 OpenWrt package." 

[3]: <https://github.com/rtklibexplorer/RTKLIB> "rtklibexplorer (2024), RTKLIB Demo 5 (b34k), GitHub repository."

[4]: <https://www.rtklib.com/> "T.Takasu (2020), RTKLIB: An Open Source Program Package for GNSS Positioning."

Hans van der Marel
Delft, 29 September 2024


