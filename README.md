### Test Your Xilinx Access and FPGA

Once you have received an FPGA and installed the tools above (or gained access to the VDI), let us test your board and tool access.

 - From your PC or the VDI, download or clone the code in this Github repo.
    - [Nexys A7 Test Project]({{site.data.urls.github_org}}/lab00-test-nexys-a7)
 - Use the `.tcl` file `syn` subfolder to create a Vivado project with the provided Verilog source and `.xdc` contsraints file in the `src` folder.  To do this follow these steps:
    - Start Vivado.
    - Once it loads, choose `Tools..Run Tcl Script` and navigate to the `syn` subfolder and find the provided `.tcl` file. Choose it and click `OK`.  It should create a project for you in the `syn` folder and reference the sources in the `src` folder.
 - Before synthesizing from the raw source files, try to use the `Hardware Manager` to download a solution (pre-synthesized) `.bit` file.
   - The `bit` subfolder it contains a solution `.bit` file you can use to program the FPGA via Vivado, via the `Hardware Manager`.
   - Connect your FPGA via the USB cable.
   - Click `Open Hardware Manager` from the lower area of the left-hand Flow Navigator (it will be under `Generate Bitsream`).
   - When `Hardware Manager` opens, there should be an option to `Open Target` at the top. Select that and then choose `Auto Connect`. If you are asked to allow permission for any software to access various resources, say `Yes` or agree.  
   - The connection should succeed and under the Hardware pane near the upper left, you should find a hierarchy of `localhost`, `xilinx_...`, and then `xc7a100t...` which is our FPGA part.  Right click that `xc7at100` row and choose `Program Device`. In the `Bitstream file` area choose `...` to navigate and select the provided `.bit` file.  Download that bitstream and verify you see `FFFF0000` and a seqeunce of LEDS going in both directions.

 - Next, attempt to recreate your own version of the `.bit` file from original sources (Verilog design and constraints (`.xdc`) file) by **synthesizing, implementing, and generating the bit stream**.  See if you can achieve the same functionality with your `.bit` file.
   - Close `Hardware Manager` and double-click `Generate Bitstream`. This will synthesize, implement and produce a new bitstream in some subfolders under `syn`.  **It will take several moments. Be patient**
   - Once it completes successfully, walk through the steps again to open Hardware Manager, connect to and program the board using the new `.bit` file, and verify its behavior.