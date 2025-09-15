set signal_list [list \
    top.m0.cpu.IdEx_pc \
    top.m0.cpu.dbus_cmd_valid_o \
    top.m0.cpu.ExMa_pc \
    top.m0.cpu.dbus_cmd_ack_i \
    top.m0.cpu.ExMa_wait_cmd_ack \
]

gtkwave::addSignalsFromList $signal_list
