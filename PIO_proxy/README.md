PIO Proxy Diagram (WIP)
![](./pio_proxy.drawio.svg)

APB FSM
```mermaid
flowchart TD
    classDef default text-align:center
    %%class idle,setup,access_toggle,access_wait,access_done cState

    idle[Idle]
    setup[Setup \n transmit_setup=1]
    access_toggle[Access_toggle \n handoff_enable_toggle=~handoff_enable_toggle]
    access_wait[Access_wait]
    access_done[Access_done \n APB_PREADY=1]

    idle --> |"APB_PSEL && !APB_PENABLE"| setup
    setup --> |APB_PENABLE| access_toggle
    access_toggle --> access_wait
    access_wait --> |handoff_ack_pulse| access_done
    access_done --> idle
```