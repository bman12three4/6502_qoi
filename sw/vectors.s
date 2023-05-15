; ---------------------------------------------------------------------------
; vectors.s
; ---------------------------------------------------------------------------
;
; Defines the interrupt vector table.

.import    _init
;.import    _nmi_int, _irq_int

.segment  "VECTORS"

.addr      _init       ; NMI vector
.addr      _init       ; Reset vector
.addr      _init       ; IRQ/BRK vector
