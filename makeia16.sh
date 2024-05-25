mkdir GCCIA16

unset CCOPTS_286
unset CCOPTS_REGULAR
unset CCOPTS_OPTIMIZED
unset EXTRA_FLAGS


export EXTRA_FLAGS="-D__COMPILER_GCCIA16"
export CCOPTS_OPTIMIZED="-march=i286 -mcmodel=medium -Ofast -fomit-frame-pointer -fgcse-sm -fgcse-las -fipa-pta -mregparmcall -flto -fwhole-program -funroll-loops"
export CCOPTS_REGULAR="-mcmodel=medium -Ofast -fomit-frame-pointer -fgcse-sm -fgcse-las -fipa-pta -mregparmcall -flto -fwhole-program -funroll-loops"
export CCOPTS_286_OLD="-march=i286 -mcmodel=medium -li86 -Os -fomit-frame-pointer -fgcse-sm -fgcse-las -fipa-pta -mregparmcall -flto -fwhole-program -funroll-loops"
# -flto causes crash
#  -fwhole-program  needs work
export CCOPTS_286_WORKS="-march=i286 -mcmodel=medium -li86 -Os -fomit-frame-pointer -fgcse-sm -fgcse-las -fipa-pta -mregparmcall -funroll-loops"
# currently smallest?
export CCOPTS_286="-march=i286 -mcmodel=medium -li86 -Os -fomit-frame-pointer -fgcse-sm -fgcse-las -fipa-pta -mregparmcall -fpack-struct=1"
export CCOPTS_286_LONG="-march=i286 -mcmodel=medium -li86 -Os -fcaller-saves -fcrossjumping -fcse-follow-jumps  -fcse-skip-blocks -fdelete-null-pointer-checks -fdevirtualize  -fdevirtualize-speculatively -fexpensive-optimizations  -fgcse  -fgcse-lm   -finline-functions -finline-small-functions -findirect-inlining -fipa-cp  -fipa-icf -fipa-ra  -fipa-sra   -fisolate-erroneous-paths-dereference -flra-remat -foptimize-sibling-calls -foptimize-strlen -fpartial-inlining -fpeephole2 -freorder-blocks-algorithm=stc -freorder-blocks-and-partition  -freorder-functions -frerun-cse-after-loop -fsched-interblock  -fsched-spec -fstrict-aliasing -fthread-jumps -ftree-builtin-call-dce -ftree-loop-vectorize -ftree-pre -ftree-slp-vectorize -ftree-switch-conversion  -ftree-tail-merge "




export GLOBOBJS="i_init.c"
export GLOBOBJS+="  i_quit.c"
export GLOBOBJS+="  i_main.c"
export GLOBOBJS+="  i_ibm.c"
export GLOBOBJS+="  i_sound.c"
export GLOBOBJS+="  tables.c"
export GLOBOBJS+="  f_finale.c"
export GLOBOBJS+="  d_init.c"
export GLOBOBJS+="  d_main.c"
export GLOBOBJS+="  d_net.c"
export GLOBOBJS+="  g_setup.c"
export GLOBOBJS+="  g_game.c"
export GLOBOBJS+="  m_menu.c"
export GLOBOBJS+="  m_misc.c"
export GLOBOBJS+="  am_map.c"
export GLOBOBJS+="  p_init.c"
export GLOBOBJS+="  p_ceilng.c"
export GLOBOBJS+="  p_doors.c"
export GLOBOBJS+="  p_enemy.c"
export GLOBOBJS+="  p_floor.c"
export GLOBOBJS+="  p_inter.c"
export GLOBOBJS+="  p_lights.c"
export GLOBOBJS+="  p_map.c"
export GLOBOBJS+="  p_maputl.c"
export GLOBOBJS+="  p_plats.c"
export GLOBOBJS+="  p_pspr.c"
export GLOBOBJS+="  p_setup.c"
export GLOBOBJS+="  p_sight.c"
export GLOBOBJS+="  p_spec.c"
export GLOBOBJS+="  p_switch.c"
export GLOBOBJS+="  p_mobj.c"
export GLOBOBJS+="  p_telept.c"
export GLOBOBJS+="  p_saveg.c"
export GLOBOBJS+="  p_tick.c"
export GLOBOBJS+="  p_user.c"
export GLOBOBJS+="  r_init.c"
export GLOBOBJS+="  r_setup.c"
export GLOBOBJS+="  r_bsp.c"
export GLOBOBJS+="  r_data.c"
export GLOBOBJS+="  r_draw.c"
export GLOBOBJS+="  r_main.c"
export GLOBOBJS+="  r_plane.c"
export GLOBOBJS+="  r_segs.c"
export GLOBOBJS+="  r_things.c"
export GLOBOBJS+="  w_init.c"
export GLOBOBJS+="  w_wad.c"
export GLOBOBJS+="  v_video.c"
export GLOBOBJS+="  z_init.c"
export GLOBOBJS+="  z_umb.c"
export GLOBOBJS+="  z_zone.c"
export GLOBOBJS+="  st_init.c"
export GLOBOBJS+="  st_setup.c"
export GLOBOBJS+="  st_stuff.c"
export GLOBOBJS+="  hu_setup.c"
export GLOBOBJS+="  hu_stuff.c"
export GLOBOBJS+="  hu_lib.c"
export GLOBOBJS+="  wi_stuff.c"
export GLOBOBJS+="  s_sound.c"
export GLOBOBJS+="  sounds.c"
export GLOBOBJS+="  dutils.c"
export GLOBOBJS+="  f_wipe.c"
export GLOBOBJS+="  info.c"
export GLOBOBJS+="  d_math.c"
export GLOBOBJS+="  dmx.c"

ia16-elf-gcc $GLOBOBJS $CCOPTS_286 $EXTRA_FLAGS -o GCCIA16/REALDOOM.EXE -Xlinker -Map=GCCIA16/output.map 
