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

CALLS[register_class]="ASSURE_SUCCESS_PTR(dummy_class = class_create(dummy_module, dummy_name));ASSURE_SUCCESS(result = class_register(dummy_class))"
CALLS[unregister_class]="class_destroy(dummy_class);class_unregister(dummy_class)"
CALLS[register_chrdev]="ASSURE_SUCCESS(result = alloc_chrdev_region(dummy_dev, DUMMY_BASEMINOR, DUMMY_COUNT, dummy_name));\
ASSURE_SUCCESS(result = register_chrdev_region(*dummy_dev, DUMMY_COUNT, dummy_name))"
CALLS[unregister_chrdev]="unregister_chrdev_region(*dummy_dev, DUMMY_COUNT)"
CALLS[register_gadget]="ASSURE_SUCCESS(result = usb_gadget_register_driver(dummy_driver));ASSURE_SUCCESS(result = usb_gadget_probe_driver(dummy_driver, dummy_bind))"
CALLS[unregister_gadget]="result = usb_gadget_unregister_driver(dummy_driver)"

CALLS[err_register]="ASSURE_ERROR_PTR(dummy_class = class_create(dummy_module, dummy_name));ASSURE_ERROR(result = class_register(dummy_class));\
ASSURE_ERROR(result = alloc_chrdev_region(dummy_dev, DUMMY_BASEMINOR, DUMMY_COUNT, dummy_name));\
ASSURE_ERROR(result = register_chrdev_region(*dummy_dev, DUMMY_COUNT, dummy_name));\
ASSURE_ERROR(result = usb_gadget_register_driver(dummy_driver));ASSURE_ERROR(result = usb_gadget_probe_driver(dummy_driver, dummy_bind))"

#EDGES[1-1]=err_register
EDGES[1-2]=unregister_class
EDGES[1-3]=register_gadget
EDGES[1-5]=unregister_chrdev

EDGES[2-1]=register_class
#EDGES[2-2]=err_register
EDGES[2-4]=register_gadget
EDGES[2-6]=unregister_chrdev

EDGES[3-1]=unregister_gadget
#EDGES[3-3]=err_register

EDGES[4-2]=unregister_gadget
#EDGES[4-4]=err_register

EDGES[5-1]=register_chrdev
#EDGES[5-5]=err_register_gadget
EDGES[5-6]=unregister_class
EDGES[5-7]=register_gadget

EDGES[6-2]=register_chrdev
EDGES[6-5]=register_class
EDGES[6-6]=err_register
EDGES[6-8]=register_gadget

EDGES[7-5]=unregister_gadget
#EDGES[7-7]=err_register

EDGES[8-6]=unregister_gadget
#EDGES[8-8]=err_register

START=6
N_ERR_CALLS=6