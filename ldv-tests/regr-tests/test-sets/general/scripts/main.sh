MODEL=$1
KERNELSRC="/root/mutilin/ldv-tools-test/kernels/linux-2.6.31.6"
GENPATH=./$MODEL-2.6.31.6
SCRIPTS=../../scripts
mkdir -p $GENPATH || exit 1
$SCRIPTS/process-kb.sh ~/LDV/ldv/toolset/experimenter_new/lib/kb/kb$MODEL.txt $GENPATH "test-$MODEL-2.6.31.6-verdict" $KERNELSRC || exit 1
$SCRIPTS/make-drivers.sh $GENPATH $KERNELSRC || exit 1
