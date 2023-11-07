/******************************************************************************
Design an AXI request generator.
The CPU programs a read or write transaction in the PIO proxy register
via APB interface
PIO proxy executes the transaction via AXI interface

Interface:
    input   clock;
    input   reset_n;

    // Standard APB slave interface

    // Standard AXI master interface
******************************************************************************/
