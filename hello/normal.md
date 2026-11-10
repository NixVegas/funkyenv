```console
$ r2 /nix/store/pa6rydwgjxxmmvdxap7qk9c85h8jbimy-hello-2.12.3/bin/hello
WARN: Relocs has not been applied. Please use `-e bin.relocs.apply=true` or `-e bin.cache=true` next time
 -- Change the registers of the child process in this way: 'dr eax=0x333'
[0x000029b0]> aaa
INFO: Analyze all flags starting with sym. and entry0 (aa)
INFO: Analyze imports (af@@@i)
INFO: Analyze entrypoint (af@ entry0)
INFO: Analyze symbols (af@@@s)
INFO: Running plugin pre-analysis hooks
INFO: Analyze all functions arguments/locals (afva@@F)
INFO: Analyze function calls (aac)
INFO: Analyze len bytes of instructions for references (aar)
INFO: Finding and parsing C++ vtables (avrr)
INFO: Analyzing methods (af @@ method.*)
INFO: Recovering local variables (afva@@@F)
INFO: Type matching analysis for all functions (aaft)
INFO: Propagate noreturn information (aanr)
INFO: Use -AA or aaaa to perform additional experimental analysis
[0x000029b0]> afl | sort
0x00002000    3     27 sym._init
0x00002030    1      6 sym.imp.free
0x00002040    1      6 sym.imp.__mempcpy_chk
0x00002050    1      6 sym.imp.abort
0x00002060    1      6 sym.imp.__errno_location
0x00002070    1      6 sym.imp.strncmp
0x00002080    1      6 sym.imp._exit
0x00002090    1      6 sym.imp.__fpending
0x000020a0    1      6 sym.imp.iconv
0x000020b0    1      6 sym.imp.ferror
0x000020c0    1      6 sym.imp.textdomain
0x000020d0    1      6 sym.imp.fclose
0x000020e0    1      6 sym.imp.bindtextdomain
0x000020f0    1      6 sym.imp.dcgettext
0x00002100    1      6 sym.imp.__ctype_get_mb_cur_max
0x00002110    1      6 sym.imp.strlen
0x00002120    1      6 sym.imp.__stack_chk_fail
0x00002130    1      6 sym.imp.getopt_long
0x00002140    1      6 sym.imp.mbrtowc
0x00002150    1      6 sym.imp.strchr
0x00002160    1      6 sym.imp.strrchr
0x00002170    1      6 sym.imp.__assert_fail
0x00002180    1      6 sym.imp.fputs
0x00002190    1      6 sym.imp.memset
0x000021a0    1      6 sym.imp.strnlen
0x000021b0    1      6 sym.imp.mbrtoc32
0x000021c0    1      6 sym.imp.fputc
0x000021d0    1      6 sym.imp.memchr
0x000021e0    1      6 sym.imp.memcmp
0x000021f0    1      6 sym.imp.calloc
0x00002200    1      6 sym.imp.strcmp
0x00002210    1      6 sym.imp.__memcpy_chk
0x00002220    1      6 sym.imp.memcpy
0x00002230    1      6 sym.imp.iswalnum
0x00002240    1      6 sym.imp.malloc
0x00002250    1      6 sym.imp.nl_langinfo
0x00002260    1      6 sym.imp.realloc
0x00002270    1      6 sym.imp.setlocale
0x00002280    1      6 sym.imp.__printf_chk
0x00002290    1      6 sym.imp.iconv_close
0x000022a0    1      6 sym.imp.iswspace
0x000022b0    1      6 sym.imp.error
0x000022c0    1      6 sym.imp.__wprintf_chk
0x000022d0    1      6 sym.imp.__cxa_atexit
0x000022e0    1      6 sym.imp.exit
0x000022f0    1      6 sym.imp.__fprintf_chk
0x00002300    1      6 sym.imp.strdup
0x00002310    1      6 sym.imp.mbsinit
0x00002320    1      6 sym.imp.iswprint
0x00002330    1      6 sym.imp.__ctype_b_loc
0x00002340    1      6 sym.imp.iconv_open
0x00002350    1      6 sym.imp.__sprintf_chk
0x00002360    1      6 sym.imp.__cxa_finalize
0x00002380    1      5 sym.rpl_mbsrtowcs.cold
0x00002385    1     31 sym.mbsstr_trimmed_wordbounded.cold
0x000023e7    1      5 sym.quotearg_buffer_restyled.cold
0x000023ec    1      5 sym.quotearg_n_options.cold
0x000023f1    1      9 sym.set_custom_quoting.cold
0x000023fa    1      5 sym.quotearg_n_style.cold
0x000023ff    1      5 sym.quotearg_n_style_mem.cold
0x00002404    1      5 sym.quotearg_n_style_colon.cold
0x00002409    1     31 sym.trim2.cold
0x00002466    1     31 sym.knuth_morris_pratt_multibyte.cold
0x000024c8    1     31 sym.mbsstr.cold
0x0000252a    1      5 sym.mem_cd_iconv.cold
0x0000252f    1      9 sym.freea.cold
0x00002538    1     31 sym.mbslen.cold
0x000025a0   24   1025 main
0x000029b0    1     37 entry0
0x000029e0    4     34 sym.deregister_tm_clones
0x00002a10    4     51 sym.register_tm_clones
0x00002a50    5     54 entry.fini0
0x00002a90    1      9 entry.init0
0x00002aa0    1     10 sym.close_stdout_set_file_name
0x00002ab0    1     10 sym.close_stdout_set_ignore_EPIPE
0x00002ac0   10    216 sym.close_stdout
0x00002ba0   36    529 sym.rpl_mbsrtowcs
0x00002dd0   10    145 sym.set_program_name
0x00002e70  140   2635 sym.mbsstr_trimmed_wordbounded
0x000038f0    4    195 sym.proper_name
0x000039c0   39    731 sym.proper_name_utf8
0x00003ce0    8    210 sym.gettext_quote
0x00003dc0  458   6480 sym.quotearg_buffer_restyled
0x000057e0   13    477 sym.quotearg_n_options
0x000059d0    1     73 sym.clone_quoting_options
0x00005a20    1     19 sym.get_quoting_style
0x00005a40    1     23 sym.set_quoting_style
0x00005a60    1     61 sym.set_char_quoting
0x00005aa0    1     25 sym.set_quoting_flags
0x00005ac0    3     55 sym.set_custom_quoting
0x00005b00    1    130 sym.quotearg_buffer
0x00005b90    3    247 sym.quotearg_alloc_mem
0x00005c90    1     10 sym.quotearg_alloc
0x00005ca0    9    175 sym.quotearg_free
0x00005d50    1     19 sym.quotearg_n
0x00005d70    1     12 sym.quotearg_n_mem
0x00005d80    1     10 sym.quotearg
0x00005d90    1     13 sym.quotearg_mem
0x00005da0    4    108 sym.quotearg_n_style
0x00005e10    4    104 sym.quotearg_n_style_mem
0x00005e80    1     12 sym.quotearg_style
0x00005e90    1     15 sym.quotearg_style_mem
0x00005ea0    3    148 sym.quotearg_char_mem
0x00005f40    1     16 sym.quotearg_char
0x00005f50    1     10 sym.quotearg_colon
0x00005f60    1     10 sym.quotearg_colon_mem
0x00005f70    4    143 sym.quotearg_n_style_colon
0x00006000    3    149 sym.quotearg_n_custom_mem
0x000060a0    1     12 sym.quotearg_n_custom
0x000060b0    1     16 sym.quotearg_custom
0x000060c0    1     19 sym.quotearg_custom_mem
0x000060e0    1     12 sym.quote_n_mem
0x000060f0    1     13 sym.quote_mem
0x00006100    1     12 sym.quote_n
0x00006110    1     10 sym.quote
0x00006120    1     51 sym.strnlen1
0x00006160   63   1022 sym.trim2
0x00006560   19   1323 sym.version_etc_arn
0x00006ad0    4     32 sym.version_etc_ar
0x00006af0    9    167 sym.version_etc_va
0x00006ba0    5    177 sym.version_etc
0x00006c60    1    170 sym.emit_bug_reporting_address
0x00006d10    3     23 sym.xmalloc
0x00006d30    3     23 sym.ximalloc
0x00006d50    1      5 sym.xcharalloc
0x00006d60    3     37 sym.xrealloc
0x00006d90    3     37 sym.xirealloc
0x00006dc0    3     27 sym.xreallocarray
0x00006de0    1      5 sym.xnrealloc
0x00006df0    3     27 sym.xireallocarray
0x00006e10    1     13 sym.xnmalloc
0x00006e20    1     13 sym.xinmalloc
0x00006e30    6    102 sym.x2nrealloc
0x00006ea0    1     10 sym.x2realloc
0x00006eb0   17    200 sym.xpalloc
0x00006f80    3     25 sym.xcalloc
0x00006fa0    1     10 sym.xzalloc
0x00006fb0    3     25 sym.xicalloc
0x00006fd0    1     10 sym.xizalloc
0x00006fe0    1     42 sym.xmemdup
0x00007010    1     42 sym.ximemdup
0x00007040    1     62 sym.ximemdup0
0x00007080    1     31 sym.xstrdup
0x000070a0    1     65 sym.xalloc_die
0x000070f0    4     55 sym.xmem_cd_iconv
0x00007130    4     55 sym.xstr_cd_iconv
0x00007170    4     55 sym.xstr_iconv
0x000071b0    9    151 sym.c_strcasecmp
0x00007260    8    108 sym.close_stream
0x000072e0    3     42 sym.locale_charset
0x00007310   10    180 sym.rpl_mbrtoc32
0x000073d0    7    140 sym.rpl_mbrtowc
0x00007480   33    457 sym.knuth_morris_pratt
0x00007670  137   2497 sym.knuth_morris_pratt_multibyte
0x00008070  217   4325 sym.mbsstr
0x000091d0    3     53 sym.rpl_reallocarray
0x00009210   28    671 sym.mem_cd_iconv
0x000094d0   22    504 sym.str_cd_iconv
0x000096e0   13    232 sym.str_iconv
0x000097e0   10    118 sym.hard_locale
0x00009870    6     65 sym.mmalloca
0x000098c0    4     33 sym.freea
0x000098f0   28    390 sym.mbslen
0x00009a60    1      5 sym.setlocale_null_r
0x00009a70    1      5 sym.setlocale_null
0x00009a80    1      7 sym.setlocale_null_unlocked
0x00009a90    9    178 sym.setlocale_null_r_unlocked
0x00009b50    1     18 sym.atexit
0x00009b64    1     13 sym._fini
[0x000029b0]> ^D
```
