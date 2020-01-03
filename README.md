blake2
======

## Introduction ##

This is a Verilog implementation of the Blake2 hash function. The specific
function implemented is BLAKE2b as specified in
[the Blake2 paper](https://blake2.net/blake2.pdf). The implementation however more closely follows the description in
[RFC 7693 - The BLAKE2 Cryptographic Hash and Message Authentication Code (MAC)
](https://tools.ietf.org/html/rfc7693)


For more info about the different versions of Blake2, see the [Blake2
home page.](https://blake2.net).


## Implementation status ##
**Not done. Does Not Work. Do. Not. Use**


## Implementation details ##

### Keyed hashing ###
The core supports setting a key size for keyed hashing according to the
RFC. But it is up to the user to push a correctly padded key block as
first data block if using the keyed hash.


### Reference implementation
There is [a reference implementation from RFC 6793](src/ref/) as part of the
source.

## FPGA-results ##

### Altera FPGAs ###

To Be Written.


### Xilinx FPGAs ###

To Be Written.


## Credits ##


## Further reading ##
- https://en.wikipedia.org/wiki/BLAKE_%28hash_function%29
