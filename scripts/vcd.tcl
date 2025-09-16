set signal_list [list \
    top.m0.cpu.If_next_pc \
    top.m0.cpu.If_v \
    top.m0.cpu.IfId_pc \
    top.m0.cpu.IfId_v \
    top.m0.cpu.IdEx_pc \
    top.m0.cpu.IdEx_v \
    top.m0.cpu.ExMa_pc \
    top.m0.cpu.ExMa_v \
    top.m0.cpu.MaWb_pc \
    top.m0.cpu.MaWb_v \
]

gtkwave::addSignalsFromList $signal_list
