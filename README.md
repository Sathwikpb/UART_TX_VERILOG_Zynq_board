﻿#UART_Tx_verilog_Zynq_Board
```mermaid
  graph TD;
    A[Start: posedge clk] --> B{Current State?}

    %% IDLE State
    B -- idle --> C[Set tx = 1 HIGH]
    C --> D[Reset txData, bitIndex, shifttx, char_delay]
    D --> E{start == 1?}
    E -- Yes --> F[Load txData with start & stop bits]
    F --> G[Move to send State]
    E -- No --> B

    %% SEND State
    B -- send --> H[Set tx = txData bitIndex]
    H --> I[Move to check State]

    %% CHECK State
    B -- check --> J{bitIndex < 9?}
    J -- Yes --> K{bitDone == 1?}
    K -- Yes --> L[Increment bitIndex]
    L --> M[Move to send State]
    K -- No --> B
    J -- No --> N[Reset bitIndex]
    N --> O[Move to gap State]

    %% GAP State
    B -- gap --> P{char_delay < wait_count * 2?}
    P -- Yes --> Q[Increment char_delay]
    Q --> B
    P -- No --> R[Reset char_delay]
    R --> S{char_index < 13?}
    S -- Yes --> T[Increment char_index]
    T --> U[Load next character into txData]
    U --> V[Move to send State]
    S -- No --> W[Reset char_index]
    W --> X{start == 1?}
    X -- Yes --> Y[Move to send State]
    X -- No --> Z[Move to idle State]

    %% Default Case
    B -- default --> AA[Move to idle State]
