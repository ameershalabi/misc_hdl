**Miscellaneous HDL modules and functions**

This repository includes several designs that I created at some point for one reason or another. I am publishing those here in case they can be useful.
This repository includes three folders and few other designs at root.

### Designs at root

These are designs that were not sorted to a specific catagory.

| Block               | Description |
|:--------------------|:-------------|
| edge_detector       | A sequentiual block that detects the rising and falling edges of a signal|
| max_bin_tree        | A sequential maximum binary tree. Takes a vector of values and outputs the maximum value. Comparitors are arranged as a complete binary tree.|
| min_bin_tree        | A sequential minimum binary tree. Takes a vector of values and outputs the minimum value. Comparitors are arranged as a complete binary tree.|


### encoders
These are gate to gate implementation of several encoder sizes.

| Block               | Description |
|:--------------------|:-------------|
| OR_ARRAY_4x2_Enc    | An optimised 4-to-2 encoder made entirely of OR gates|
| OR_ARRAY_8x3_Enc    | An optimised 8-to-3 encoder made entirely of OR gates|
| OR_ARRAY_16x4_Enc   | An optimised 16-to-4 encoder made entirely of OR gates|
| OR_ARRAY_32x5_Enc   | An optimised 32-to-5 encoder made entirely of OR gates|


### hdl_comm
These are implementations of communication protocols.

| Block               | Description |
|:--------------------|:-------------|
| UART/uart_rx        | UART recieved module|
| UART/uart_tx        | UART transmitter module|
| SPI/spi_main        | SPI main module|
| SPI/spi_subnode     | SPI subnode module|

### rvh_blks
These are buffer implementations with simple ready/valid handshake protocol.

| Block               | Description |
|:--------------------|:-------------|
| rvh_FIFO    | First In First Out ready/valid handshake compliant module|
| rvh_LIFO    | Last In First Out ready/valid handshake compliant module|
| rvh_PISO   | Parallel In Serial Out ready/valid handshake compliant module|
| rvh_SIPO   | Serial In Parallel Out ready/valid handshake compliant module|