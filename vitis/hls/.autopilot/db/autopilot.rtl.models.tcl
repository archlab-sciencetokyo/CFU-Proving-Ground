set SynModuleInfo {
  {SRCNAME cfu_hls MODELNAME cfu_hls RTLNAME cfu_hls IS_TOP 1
    SUBMODULES {
      {MODELNAME cfu_hls_faddfsub_32ns_32ns_32_9_full_dsp_1 RTLNAME cfu_hls_faddfsub_32ns_32ns_32_9_full_dsp_1 BINDTYPE op TYPE fsub IMPL fulldsp LATENCY 8 ALLOW_PRAGMA 1}
      {MODELNAME cfu_hls_fadd_32ns_32ns_32_9_full_dsp_1 RTLNAME cfu_hls_fadd_32ns_32ns_32_9_full_dsp_1 BINDTYPE op TYPE fadd IMPL fulldsp LATENCY 8 ALLOW_PRAGMA 1}
      {MODELNAME cfu_hls_fmul_32ns_32ns_32_5_max_dsp_1 RTLNAME cfu_hls_fmul_32ns_32ns_32_5_max_dsp_1 BINDTYPE op TYPE fmul IMPL maxdsp LATENCY 4 ALLOW_PRAGMA 1}
      {MODELNAME cfu_hls_fcmp_32ns_32ns_1_3_no_dsp_1 RTLNAME cfu_hls_fcmp_32ns_32ns_1_3_no_dsp_1 BINDTYPE op TYPE fcmp IMPL auto LATENCY 2 ALLOW_PRAGMA 1}
    }
  }
}
