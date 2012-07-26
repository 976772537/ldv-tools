# Include this file from gentests.sh

declare -a VERTICES
declare -A CALLS
declare -A EDGES

VERTICES[1]=:chrdev,class
VERTICES[2]=:chrdev
VERTICES[3]=:gadget,chrdev,class
VERTICES[4]=:gadget,chrdev
VERTICES[5]=:class
VERTICES[6]=:
VERTICES[7]=:gadget,class
VERTICES[8]=:gadget

CALLS[register_class]="register_class1;register_class2"
CALLS[unregister_class]="unregister_class1;unregister_class2"
CALLS[register_chrdev]="register_chrdev1;register_chrdev2"
CALLS[unregister_chrdev]="unregister_chrdev1;unregister_chrdev2"
CALLS[register_gadget]="register_gadget1;register_gadget2"
CALLS[unregister_gadget]="unregister_gadget1;unregister_gadget2"

EDGES[1-2]=unregister_class
EDGES[1-3]=register_gadget
EDGES[1-5]=unregister_chrdev

EDGES[2-1]=register_class
EDGES[2-4]=register_gadget
EDGES[2-6]=unregister_chrdev

EDGES[3-1]=unregister_gadget

EDGES[4-2]=unregister_gadget

EDGES[5-1]=register_chrdev
EDGES[5-6]=unregister_class
EDGES[5-7]=register_gadget

EDGES[6-2]=register_chrdev
EDGES[6-5]=register_class
EDGES[6-8]=register_gadget

EDGES[7-5]=unregister_gadget

EDGES[8-6]=unregister_gadget

START=6