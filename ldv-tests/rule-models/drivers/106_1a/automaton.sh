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

CALLS[register_class]="dummy_class = class_create(dummy_module, dummy_name);result = class_register(dummy_class)"
CALLS[unregister_class]="class_destroy(dummy_class);class_unregister(dummy_class)"
CALLS[register_chrdev]="result = alloc_chrdev_region(dummy_dev, DUMMY_BASEMINOR, DUMMY_COUNT, dummy_name);
result = register_chrdev_region(dummy_dev, DUMMY_COUNT, dummy_name)"
CALLS[unregister_chrdev]="unregister_chrdev_region(dummy_dev, DUMMY_COUNT)"
CALLS[register_gadget]="result = usb_gadget_register_driver(dummy_driver);result = usb_gadget_probe_driver(dummy_driver, dummy_bind)"
CALLS[unregister_gadget]="result = usb_gadget_unregister_driver(dummy_driver)"

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