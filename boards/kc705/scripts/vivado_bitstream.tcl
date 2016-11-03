set outdir build

open_checkpoint $outdir/post_route.dcp
write_bitstream -force $outdir/kc705-tmpl.bit
