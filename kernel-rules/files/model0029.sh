#!/bin/bash
FILEC=$1
DIR=`dirname $0`
#echo $DIR
$DIR/grep-all.sh $FILEC ldv_main && $DIR/grep-any.sh $FILEC dma_pool_create dma_pool_alloc dma_pool_free dma_pool_destroy pci_pool_create pci_pool_alloc pci_pool_free pci_pool_destroy
